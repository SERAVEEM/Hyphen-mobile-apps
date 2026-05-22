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

// ================== CHECKOUT ==================
const checkout = async (req, res) => {
    try {
        const { orderId, addressId, courierCode, service, notes } = req.body;
        const userId = req.user.id;

        // ===== VALIDASI INPUT =====
        if (!orderId || !addressId || !courierCode || !service) {
            return res.status(400).json({
                message: 'orderId, addressId, courierCode, dan service wajib diisi'
            });
        }

        if (!SUPPORTED_COURIERS.includes(courierCode.toLowerCase())) {
            return res.status(400).json({
                message: `Kurir '${courierCode}' tidak didukung`,
                supportedCouriers: SUPPORTED_COURIERS
            });
        }

        // ===== VALIDASI ORDER =====
        const [orderRows] = await pool.query(
            'SELECT * FROM orders WHERE id = ? AND userId = ?',
            [orderId, userId]
        );
        if (orderRows.length === 0) {
            return res.status(404).json({ message: 'Order tidak ditemukan' });
        }
        const order = orderRows[0];
        if (['cancelled', 'shipped', 'paid', 'waiting_payment'].includes(order.status)) {
            return res.status(400).json({
                message: `Order tidak bisa dicheckout, status saat ini: ${order.status}`
            });
        }

        // ===== VALIDASI PRODUK =====
        const [productRows] = await pool.query('SELECT * FROM products WHERE id = ?', [order.productId]);
        if (productRows.length === 0) {
            return res.status(404).json({ message: 'Produk tidak ditemukan' });
        }
        const product = productRows[0];
        if (!product.originCityId) {
            return res.status(400).json({ message: 'Produk belum memiliki kota asal pengiriman' });
        }
        if (!product.weight) {
            return res.status(400).json({ message: 'Produk belum memiliki berat' });
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

        // ===== CEK DUPLIKAT SHIPMENT & PAYMENT =====
        const [existingShipment] = await pool.query(
            'SELECT id FROM shipments WHERE orderId = ?',
            [orderId]
        );
        if (existingShipment.length > 0) {
            return res.status(400).json({ message: 'Order ini sudah memiliki pengiriman' });
        }

        const [existingPayment] = await pool.query(
            "SELECT id FROM payments WHERE orderId = ? AND status != 'cancelled'",
            [orderId]
        );
        if (existingPayment.length > 0) {
            return res.status(400).json({ message: 'Order ini sudah memiliki pembayaran aktif' });
        }

        // ===== HITUNG & VERIFIKASI ONGKIR =====
        const weightGram = Math.max(product.weight * order.quantity, 1000);

        const courierResults = await rajaongkirPost('/calculate/domestic-cost', {
            origin: product.originCityId,
            destination: address.destinationCityId,
            weight: weightGram,
            courier: courierCode.toLowerCase(),
            price: 'lowest',
        });

        const results = Array.isArray(courierResults) ? courierResults : [courierResults];
        const serviceUpper = service.toUpperCase();
        const selectedCost = results.find(r => r.service?.toUpperCase() === serviceUpper);

        if (!selectedCost) {
            return res.status(400).json({
                message: `Service '${service}' tidak tersedia untuk kurir ${courierCode}`,
                availableServices: results.map(r => r.service)
            });
        }

        const shippingCost = selectedCost.cost;
        const etd = selectedCost.etd || '-';
        const totalAmount = Number(order.totalPrice) + shippingCost;

        // ===== BUAT SHIPMENT =====
        const shipmentId = uuidv4();

        await pool.query(
            `INSERT INTO shipments 
            (id, userId, orderId, addressId, courierCode, service, courierName, estimatedDays, shippingCost, notes, status)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
            [
                shipmentId, userId, orderId, addressId,
                courierCode.toLowerCase(), serviceUpper,
                selectedCost.name, etd, shippingCost,
                notes ?? null, 'pending'
            ]
        );

        // ===== BUAT PAYMENT MIDTRANS =====
        const [userRows] = await pool.query('SELECT username, email FROM users WHERE id = ?', [userId]);
        const user = userRows[0];

        const midtransOrderId = `PAY-${Date.now()}`;
        const midtransParam = {
            transaction_details: {
                order_id: midtransOrderId,
                gross_amount: totalAmount,
            },
            customer_details: {
                first_name: user.username,
                email: user.email,
            },
            item_details: [
                {
                    id: order.productId,
                    price: Math.round(Number(order.totalPrice) / order.quantity),
                    quantity: order.quantity,
                    name: product.name ?? 'Produk',
                },
                {
                    id: 'SHIPPING',
                    price: shippingCost,
                    quantity: 1,
                    name: `Ongkir ${selectedCost.name} - ${serviceUpper}`,
                }
            ],
            expiry: {
                unit: 'hours',
                duration: 24,
            },
            enabled_payments: [
                'credit_card', 'bca_va', 'bni_va', 'bri_va',
                'permata_va', 'mandiri_bill', 'gopay',
                'shopeepay', 'qris', 'indomaret', 'alfamart'
            ]
        };

        const midtransResponse = await snap.createTransaction(midtransParam);

        const paymentId = uuidv4();
        const expiredAt = new Date(Date.now() + 24 * 60 * 60 * 1000);

        await pool.query(
            `INSERT INTO payments 
            (id, orderId, userId, amount, paymentMethod, status, midtransOrderId, snapToken, snapUrl, expiredAt)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
            [
                paymentId, orderId, userId, totalAmount,
                'midtrans', 'pending', midtransOrderId,
                midtransResponse.token, midtransResponse.redirect_url, expiredAt
            ]
        );

        // ===== UPDATE STATUS ORDER =====
        await pool.query("UPDATE orders SET status = 'waiting_payment' WHERE id = ?", [orderId]);

        // ===== RESPONSE =====
        return res.status(201).json({
            message: 'Checkout berhasil! Silakan selesaikan pembayaran.',
            snapUrl: midtransResponse.redirect_url,
            snapToken: midtransResponse.token,
            data: {
                order: {
                    id: order.id,
                    status: 'waiting_payment',
                    totalPrice: order.totalPrice,
                },
                shipment: {
                    id: shipmentId,
                    courierName: selectedCost.name,
                    service: serviceUpper,
                    etd,
                    shippingCost,
                },
                payment: {
                    id: paymentId,
                    productPrice: order.totalPrice,
                    shippingCost,
                    totalAmount,
                    expiredAt,
                    snapUrl: midtransResponse.redirect_url,
                }
            }
        });

    } catch (error) {
        return res.status(500).json({
            message: 'Checkout gagal',
            error: error.message
        });
    }
};

module.exports = { checkout };