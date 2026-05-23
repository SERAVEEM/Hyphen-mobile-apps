const { v4: uuidv4 } = require('uuid');
const pool = require('@/config/db');
const { rajaongkirPost } = require('@/helpers/shipping.helpers');
const midtransClient = require('midtrans-client');

// ================== KONFIGURASI ==================
const SUPPORTED_COURIERS = [
    'jne', 'sicepat', 'ide', 'sap', 'jnt', 'ninja',
    'tiki', 'lion', 'anteraja', 'pos', 'ncs', 'rex',
    'rpx', 'sentral', 'star', 'wahana', 'dse'
];

const snap = new midtransClient.Snap({
    isProduction: process.env.MIDTRANS_IS_PRODUCTION === 'true',
    serverKey: process.env.MIDTRANS_SERVER_KEY,
});

// ================== CHECKOUT (single order & cart) ==================
// Body:
//   Single : { orderId: "xxx", addressId, courierCode, service, notes }
//   Cart   : { orderIds: ["xxx","yyy"], addressId, courierCode, service, notes }
const checkout = async (req, res) => {
    try {
        const { orderId, orderIds, addressId, courierCode, service, notes } = req.body;
        const userId = req.user.id;

        // ===== NORMALISASI INPUT → selalu array =====
        const ids = orderId ? [orderId] : orderIds;

        if (!ids || !Array.isArray(ids) || ids.length === 0) {
            return res.status(400).json({ message: 'orderId atau orderIds wajib diisi' });
        }
        if (!addressId || !courierCode || !service) {
            return res.status(400).json({ message: 'addressId, courierCode, dan service wajib diisi' });
        }
        if (!SUPPORTED_COURIERS.includes(courierCode.toLowerCase())) {
            return res.status(400).json({
                message: `Kurir '${courierCode}' tidak didukung`,
                supportedCouriers: SUPPORTED_COURIERS
            });
        }

        // ===== VALIDASI ALAMAT =====
        const [addressRows] = await pool.query(
            'SELECT * FROM addresses WHERE id = ? AND userId = ?',
            [addressId, userId]
        );
        if (addressRows.length === 0) {
            return res.status(404).json({ message: 'Alamat tidak ditemukan' });
        }
        const address = addressRows[0];
        if (!address.destinationCityId) {
            return res.status(400).json({ message: 'Alamat belum memiliki destinationCityId' });
        }

        // ===== VALIDASI SEMUA ORDER =====
        // FIX: o.userId (bukan o.buyerID), tidak ada o.quantity & o.totalPrice di schema
        // Barang bekas: quantity selalu 1, totalPrice = price
        const placeholders = ids.map(() => '?').join(',');
        const [orderRows] = await pool.query(
            `SELECT o.*, p.name AS productName, p.originCityId, p.weight, p.price AS productPrice
             FROM orders o
             JOIN products p ON o.productId = p.id
             WHERE o.id IN (${placeholders}) AND o.userId = ?`,
            [...ids, userId]
        );

        if (orderRows.length !== ids.length) {
            return res.status(404).json({ message: 'Beberapa order tidak ditemukan atau bukan milik kamu' });
        }

        const invalidOrders = orderRows.filter(o =>
            ['cancelled', 'shipped', 'paid', 'waiting_payment'].includes(o.status)
        );
        if (invalidOrders.length > 0) {
            return res.status(400).json({
                message: 'Beberapa order tidak bisa dicheckout',
                invalidOrders: invalidOrders.map(o => ({ id: o.id, status: o.status }))
            });
        }

        const missingData = orderRows.filter(o => !o.originCityId || !o.weight);
        if (missingData.length > 0) {
            return res.status(400).json({
                message: 'Beberapa produk belum memiliki originCityId atau weight',
                products: missingData.map(o => o.productId)
            });
        }

        // ===== CEK DUPLIKAT SHIPMENT & PAYMENT =====
        const [existingShipments] = await pool.query(
            `SELECT orderId FROM shipments WHERE orderId IN (${placeholders})`,
            ids
        );
        if (existingShipments.length > 0) {
            return res.status(400).json({
                message: 'Beberapa order sudah memiliki pengiriman',
                orderIds: existingShipments.map(s => s.orderId)
            });
        }

        const [existingPayments] = await pool.query(
            `SELECT po.orderId FROM payment_orders po
             JOIN payments p ON po.paymentId = p.id
             WHERE po.orderId IN (${placeholders}) AND p.status != 'cancelled'`,
            ids
        );
        if (existingPayments.length > 0) {
            return res.status(400).json({
                message: 'Beberapa order sudah memiliki pembayaran aktif',
                orderIds: existingPayments.map(p => p.orderId)
            });
        }

        // ===== HITUNG ONGKIR (grouping by originCityId) =====
        const originGroups = {};
        for (const order of orderRows) {
            const key = order.originCityId;
            if (!originGroups[key]) originGroups[key] = [];
            originGroups[key].push(order);
        }

        let totalShippingCost = 0;
        const shipmentDetails = [];
        const serviceUpper = service.toUpperCase();

        for (const [originCityId, groupOrders] of Object.entries(originGroups)) {
            const totalWeight = Math.max(
                groupOrders.reduce((sum, o) => sum + o.weight, 0),
                1000
            );

            const courierResults = await rajaongkirPost('/calculate/domestic-cost', {
                origin: originCityId,
                destination: address.destinationCityId,
                weight: totalWeight,
                courier: courierCode.toLowerCase(),
                price: 'lowest',
            });

            const results = Array.isArray(courierResults) ? courierResults : [courierResults];
            const selectedCost = results.find(r => r.service?.toUpperCase() === serviceUpper);

            if (!selectedCost) {
                return res.status(400).json({
                    message: `Service '${service}' tidak tersedia untuk kurir ${courierCode}`,
                    availableServices: results.map(r => r.service)
                });
            }

            totalShippingCost += selectedCost.cost;
            shipmentDetails.push({
                originCityId,
                orders: groupOrders,
                shippingCost: selectedCost.cost,
                etd: selectedCost.etd || '-',
                courierName: selectedCost.name,
            });
        }

        // ===== HITUNG TOTAL =====
        // FIX: gunakan o.price (bukan o.totalPrice), quantity selalu 1
        const totalProductPrice = orderRows.reduce((sum, o) => sum + Number(o.price), 0);
        const grandTotal = totalProductPrice + totalShippingCost;

        // ===== BUAT SHIPMENT PER ORDER =====
        const createdShipments = [];
        for (const group of shipmentDetails) {
            for (const order of group.orders) {
                const shipmentId = uuidv4();
                await pool.query(
                    `INSERT INTO shipments
                    (id, userId, orderId, addressId, courierCode, service, courierName, estimatedDays, shippingCost, notes, status)
                    VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
                    [
                        shipmentId, userId, order.id, addressId,
                        courierCode.toLowerCase(), serviceUpper,
                        group.courierName, group.etd, group.shippingCost,
                        notes ?? null, 'pending'
                    ]
                );
                createdShipments.push({ shipmentId, orderId: order.id });
            }
        }

        // ===== BUAT PAYMENT MIDTRANS =====
        const [userRows] = await pool.query('SELECT username, email FROM users WHERE id = ?', [userId]);
        const user = userRows[0];

        const midtransOrderId = `PAY-${Date.now()}`;
        const item_details = [
            ...orderRows.map(o => ({
                id: o.productId,
                price: Math.round(Number(o.price)),
                quantity: 1,
                name: o.productName ?? 'Produk',
            })),
            ...shipmentDetails.map((g, i) => ({
                id: `SHIPPING-${i + 1}`,
                price: g.shippingCost,
                quantity: 1,
                name: `Ongkir ${g.courierName} - ${serviceUpper}`,
            }))
        ];

        const midtransParam = {
            transaction_details: {
                order_id: midtransOrderId,
                gross_amount: grandTotal,
            },
            customer_details: {
                first_name: user.username,
                email: user.email,
            },
            item_details,
            expiry: { unit: 'hours', duration: 24 },
            enabled_payments: [
                'credit_card', 'bca_va', 'bni_va', 'bri_va',
                'permata_va', 'mandiri_bill', 'gopay',
                'shopeepay', 'qris', 'indomaret', 'alfamart'
            ]
        };

        const midtransResponse = await snap.createTransaction(midtransParam);

        // ===== SIMPAN PAYMENT =====
        const paymentId = uuidv4();
        const expiredAt = new Date(Date.now() + 24 * 60 * 60 * 1000);

        await pool.query(
            `INSERT INTO payments
            (id, userId, amount, paymentMethod, status, midtransOrderId, snapToken, snapUrl, expiredAt)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)`,
            [
                paymentId, userId, grandTotal,
                'midtrans', 'pending', midtransOrderId,
                midtransResponse.token, midtransResponse.redirect_url, expiredAt
            ]
        );

        // ===== SIMPAN RELASI PAYMENT → ORDERS =====
        for (const id of ids) {
            await pool.query(
                'INSERT INTO payment_orders (paymentId, orderId) VALUES (?, ?)',
                [paymentId, id]
            );
        }

        // ===== UPDATE STATUS SEMUA ORDER =====
        await pool.query(
            `UPDATE orders SET status = 'waiting_payment' WHERE id IN (${placeholders})`,
            ids
        );

        // ===== RESPONSE =====
        return res.status(201).json({
            message: 'Checkout berhasil! Silakan selesaikan pembayaran.',
            snapUrl: midtransResponse.redirect_url,
            snapToken: midtransResponse.token,
            data: {
                totalOrders: orderRows.length,
                totalProductPrice,
                totalShippingCost,
                grandTotal,
                expiredAt,
                shipments: createdShipments,
                payment: {
                    id: paymentId,
                    midtransOrderId,
                    snapUrl: midtransResponse.redirect_url,
                }
            }
        });

    } catch (error) {
        console.error('checkout error:', error);
        return res.status(500).json({ message: 'Checkout gagal', error: error.message });
    }
};

module.exports = { checkout };