const { v4: uuidv4 } = require('uuid');
const { users } = require('@/data/users.data');
const { orders } = require('@/data/order.data');
const { payments } = require('@/data/payment.data');
const { products } = require('@/data/product.data');
const midtransClient = require('midtrans-client');

const snap = new midtransClient.Snap({
    isProduction: process.env.MIDTRANS_IS_PRODUCTION === 'true',
    serverKey: process.env.MIDTRANS_SERVER_KEY,
});

// ========================= CREATE PAYMENT =========================
const createPayment = async (req, res) => {
    const { orderId, paymentMethod } = req.body;
    const userId = req.user.id;

    if (!orderId || !paymentMethod) {
        return res.status(400).json({ message: 'Semua field harus diisi' });
    }

    const user = users.find((u) => u.id === userId);
    if (!user) return res.status(404).json({ message: 'User tidak ditemukan' });

    const order = orders.find((o) => o.id === orderId);
    if (!order) return res.status(404).json({ message: 'Order tidak ditemukan' });

    if (['cancelled', 'waiting_confirmation', 'paid', 'pending_cod'].includes(order.status)) {
        return res.status(400).json({ message: 'Order sudah dibayar atau dibatalkan' });
    }

    const alreadyPaid = payments.find(p => p.orderId === orderId && p.status !== 'cancelled');
    if (alreadyPaid) {
        return res.status(400).json({ message: 'Order sudah memiliki pembayaran aktif' });
    }

    const product = products.find((p) => p.id === order.productId);

    // Buat transaksi Midtrans
    const parameter = {
        transaction_details: {
            order_id: `PAY-${Date.now()}`,
            gross_amount: order.totalPrice,
        },
        customer_details: {
            first_name: user.username,
            email: user.email,
        },
        item_details: [{
            id: order.productId,
            price: order.totalPrice / order.quantity,
            quantity: order.quantity,
            name: product?.name ?? 'Produk',
        }],
        expiry: {
            unit: 'hours',
            duration: 24, // ← batas bayar 24 jam
        },
    };

    const midtransResponse = await snap.createTransaction(parameter);

    const newPayment = {
        id: uuidv4(),
        orderId,
        userId,
        amount: order.totalPrice,
        paymentMethod: paymentMethod.toLowerCase(),
        status: 'pending',
        snapToken: midtransResponse.token,       // ← untuk frontend
        snapUrl: midtransResponse.redirect_url, // ← link pembayaran
        createdAt: new Date().toISOString(),
        expiredAt: new Date(Date.now() + 24 * 60 * 60 * 1000).toISOString(),
    };

    order.status = 'waiting_payment';
    payments.push(newPayment);
    if (!user.payments) user.payments = [];
    user.payments.push(newPayment);

    return res.status(201).json({
        message: 'Pembayaran berhasil dibuat',
        snapUrl: midtransResponse.redirect_url, // ← buka ini untuk bayar
        snapToken: midtransResponse.token,
        data: newPayment,
    });
};

// Helper filter metode pembayaran
const getPaymentMethods = (method) => {
    switch (method.toLowerCase()) {
        case 'qris':
            return ['qris'];

        case 'transfer':
            return ['bank_transfer'];

        case 'gopay':
            return ['gopay'];

        case 'shopeepay':
            return ['shopeepay'];

        default:
            return [
                'qris',
                'gopay',
                'bank_transfer',
                'shopeepay'
            ];
    }
};

// ========================= WEBHOOK MIDTRANS =========================
// POST /payment/webhook — dipanggil otomatis oleh Midtrans saat status berubah
const handleWebhook = async (req, res) => {
    const { order_id, transaction_status, fraud_status } = req.body;

    // Ambil orderId dari order_id midtrans (format: PAY-<orderId>-<timestamp>)
    const orderId = order_id.split('-').slice(1, 6).join('-');

    const payment = payments.find(p => p.orderId === orderId);
    const order = orders.find(o => o.id === orderId);

    if (!payment || !order) {
        return res.status(404).json({ message: 'Payment tidak ditemukan' });
    }

    if (transaction_status === 'settlement' ||
        (transaction_status === 'capture' && fraud_status === 'accept')) {
        payment.status = 'paid';
        order.status = 'paid';
    } else if (transaction_status === 'expire') {
        payment.status = 'expired';
        order.status = 'cancelled';
    } else if (transaction_status === 'cancel' || transaction_status === 'deny') {
        payment.status = 'cancelled';
        order.status = 'cancelled';
    }

    return res.status(200).json({ message: 'Webhook berhasil diproses' });
};

// ========================= RIWAYAT PEMBAYARAN (USER) =========================
const getPayments = (req, res) => {
    const user = users.find((u) => u.id === req.user.id);
    if (!user) return res.status(404).json({ message: 'User tidak ditemukan' });

    return res.status(200).json({
        message: 'Riwayat pembayaran',
        total: user.payments ? user.payments.length : 0,
        data: user.payments ?? [],
    });
};

// ========================= SEMUA PEMBAYARAN (ADMIN) =========================
const getAllPayments = (req, res) => {
    return res.status(200).json({
        message: 'Semua data pembayaran',
        total: payments.length,
        data: payments,
    });
};

// ========================= DETAIL PEMBAYARAN =========================
const getPaymentById = (req, res) => {
    const { id } = req.params;

    if (req.user.role === 'admin') {
        const payment = payments.find((p) => p.id === id);
        if (!payment) return res.status(404).json({ message: 'Pembayaran tidak ditemukan' });
        return res.status(200).json({ message: 'Pembayaran ditemukan', data: payment });
    }

    const user = users.find((u) => u.id === req.user.id);
    if (!user) return res.status(404).json({ message: 'User tidak ditemukan' });

    const payment = user.payments?.find((p) => p.id === id);
    if (!payment) return res.status(404).json({ message: 'Pembayaran tidak ditemukan' });

    return res.status(200).json({ message: 'Pembayaran ditemukan', data: payment });
};

// ========================= CANCEL PAYMENT =========================
const cancelPayment = (req, res) => {
    const { paymentId } = req.body;
    const userId = req.user.id;

    if (!paymentId) return res.status(400).json({ message: 'paymentId wajib diisi' });

    const user = users.find((u) => u.id === userId);
    if (!user) return res.status(404).json({ message: 'User tidak ditemukan' });

    const payment = user.payments?.find((p) => p.id === paymentId);
    if (!payment) return res.status(404).json({ message: 'Pembayaran tidak ditemukan' });

    if (['cancelled', 'refunded', 'paid'].includes(payment.status)) {
        return res.status(400).json({ message: `Pembayaran sudah ${payment.status}` });
    }

    const order = orders.find((o) => o.id === payment.orderId);
    const product = products.find((p) => p.id === order?.productId);

    payment.status = 'cancelled';
    if (order) order.status = 'cancelled';

    // Kembalikan stok
    if (product && order) {
        const selectedSize = product.sizes.find(
            (s) => s.size.toLowerCase() === order.size.toLowerCase()
        );
        if (selectedSize) selectedSize.stock += order.quantity;
    }

    return res.status(200).json({
        message: 'Pembayaran berhasil dibatalkan',
        data: payment,
    });
};

module.exports = { createPayment, getPayments, getPaymentById, getAllPayments, cancelPayment, handleWebhook };