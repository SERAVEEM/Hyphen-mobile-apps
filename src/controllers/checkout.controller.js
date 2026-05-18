const { v4: uuidv4 } = require('uuid');
const { users } = require('@/data/users.data');
const { orders } = require('@/data/order.data');
const { products } = require('@/data/product.data');
const { shipments } = require('@/data/shipping.data');
const { payments } = require('@/data/payment.data');
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
// POST /checkout
// Body: { orderId, addressId, courierCode, service, notes? }
// Flow: validasi → verifikasi ongkir → buat shipment → buat payment Midtrans → return snapUrl
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
        const order = orders.find(o => o.id === orderId && o.userId === userId);
        if (!order) {
            return res.status(404).json({ message: 'Order tidak ditemukan' });
        }
        if (['cancelled', 'shipped', 'paid', 'waiting_payment'].includes(order.status)) {
            return res.status(400).json({
                message: `Order tidak bisa dicheckout, status saat ini: ${order.status}`
            });
        }

        // ===== VALIDASI PRODUK =====
        const product = products.find(p => p.id === order.productId);
        if (!product) {
            return res.status(404).json({ message: 'Produk tidak ditemukan' });
        }
        if (!product.originCityId) {
            return res.status(400).json({ message: 'Produk belum memiliki kota asal pengiriman' });
        }
        if (!product.weight) {
            return res.status(400).json({ message: 'Produk belum memiliki berat' });
        }

        // ===== VALIDASI ALAMAT =====
        const user = users.find(u => u.id === userId);
        const address = user?.addresses?.find(a => a.id === addressId);
        if (!address) {
            return res.status(404).json({ message: 'Alamat tidak ditemukan' });
        }
        if (!address.destinationCityId) {
            return res.status(400).json({ message: 'Alamat belum memiliki destinationCityId' });
        }

        // ===== CEK DUPLIKAT SHIPMENT & PAYMENT =====
        const alreadyShipped = shipments.find(s => s.orderId === orderId);
        if (alreadyShipped) {
            return res.status(400).json({ message: 'Order ini sudah memiliki pengiriman' });
        }

        const alreadyPaid = payments.find(p => p.orderId === orderId && p.status !== 'cancelled');
        if (alreadyPaid) {
            return res.status(400).json({ message: 'Order ini sudah memiliki pembayaran aktif' });
        }

        // ===== HITUNG & VERIFIKASI ONGKIR =====
        const originCityId = product.originCityId;
        const destinationCityId = address.destinationCityId;
        const weightGram = Math.max(product.weight * order.quantity, 1000); // minimum 1kg

        const courierResults = await rajaongkirPost('/calculate/domestic-cost', {
            origin: originCityId,
            destination: destinationCityId,
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
        const totalAmount = order.totalPrice + shippingCost; // harga produk + ongkir

        // ===== BUAT SHIPMENT =====
        const newShipment = {
            id: uuidv4(),
            userId,
            orderId,
            addressId,
            originCityId,
            originCityLabel: product.originCityLabel ?? null,
            destinationCityId,
            destinationCityLabel: address.destinationCityLabel ?? null,
            courierCode: courierCode.toLowerCase(),
            courierName: selectedCost.name,
            service: serviceUpper,
            description: selectedCost.description,
            weightGram,
            shippingCost,
            etd,
            notes: notes ?? null,
            status: 'PENDING',
            statusHistory: [{
                status: 'PENDING',
                message: 'Pesanan menunggu konfirmasi pengiriman',
                timestamp: new Date().toISOString(),
            }],
            createdAt: new Date().toISOString(),
            updatedAt: new Date().toISOString(),
        };

        shipments.push(newShipment);

        // ===== BUAT PAYMENT MIDTRANS =====
        const midtransParam = {
            transaction_details: {
                order_id: `PAY-${Date.now()}`,
                gross_amount: totalAmount,
            },
            customer_details: {
                first_name: user.username,
                email: user.email,
            },
            item_details: [
                {
                    id: order.productId,
                    price: Math.round(order.totalPrice / order.quantity),
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
                duration: 24, // batas bayar 24 jam
            },
            enabled_payments: [
                'credit_card', 'bca_va', 'bni_va', 'bri_va',
                'permata_va', 'mandiri_bill', 'gopay',
                'shopeepay', 'qris', 'indomaret', 'alfamart'
            ]
        };

        const midtransResponse = await snap.createTransaction(midtransParam);

        const newPayment = {
            id: uuidv4(),
            orderId,
            userId,
            shipmentId: newShipment.id,
            productPrice: order.totalPrice,
            shippingCost,
            amount: totalAmount,
            status: 'pending',
            snapToken: midtransResponse.token,
            snapUrl: midtransResponse.redirect_url,
            createdAt: new Date().toISOString(),
            expiredAt: new Date(Date.now() + 24 * 60 * 60 * 1000).toISOString(),
        };

        // Update status order
        order.status = 'waiting_payment';

        // Simpan payment
        payments.push(newPayment);
        if (!user.payments) user.payments = [];
        user.payments.push(newPayment);

        // ===== RESPONSE =====
        return res.status(201).json({
            message: 'Checkout berhasil! Silakan selesaikan pembayaran.',
            snapUrl: midtransResponse.redirect_url,  // buka untuk bayar
            snapToken: midtransResponse.token,          // untuk Snap.js popup
            data: {
                order: {
                    id: order.id,
                    status: order.status,
                    totalPrice: order.totalPrice,
                },
                shipment: {
                    id: newShipment.id,
                    courierName: newShipment.courierName,
                    service: newShipment.service,
                    etd: newShipment.etd,
                    shippingCost: newShipment.shippingCost,
                },
                payment: {
                    id: newPayment.id,
                    productPrice: newPayment.productPrice,
                    shippingCost: newPayment.shippingCost,
                    totalAmount: newPayment.amount,
                    expiredAt: newPayment.expiredAt,
                    snapUrl: newPayment.snapUrl,
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