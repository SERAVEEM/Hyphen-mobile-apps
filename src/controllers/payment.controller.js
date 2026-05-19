const { v4: uuidv4 } = require('uuid');
const pool = require('@/config/db');
const midtransClient = require('midtrans-client');

const snap = new midtransClient.Snap({
    isProduction: process.env.MIDTRANS_IS_PRODUCTION === 'true',
    serverKey: process.env.MIDTRANS_SERVER_KEY,
});

// ========================= CREATE PAYMENT =========================
// POST /payment/create-payment
const createPayment = async (req, res) => {
    const { orderId, paymentMethod } = req.body;
    const userId = req.user.id;

    if (!orderId || !paymentMethod) {
        return res.status(400).json({ message: 'Semua field harus diisi' });
    }

    const [orderRows] = await pool.query('SELECT * FROM orders WHERE id = ? AND userId = ?', [orderId, userId]);
    if (orderRows.length === 0) return res.status(404).json({ message: 'Order tidak ditemukan' });
    const order = orderRows[0];

    if (['cancelled', 'waiting_confirmation', 'paid', 'pending_cod'].includes(order.status)) {
        return res.status(400).json({ message: 'Order sudah dibayar atau dibatalkan' });
    }

    const [existingPayment] = await pool.query(
        "SELECT id FROM payments WHERE orderId = ? AND status != 'cancelled'",
        [orderId]
    );
    if (existingPayment.length > 0) {
        return res.status(400).json({ message: 'Order sudah memiliki pembayaran aktif' });
    }

    const [productRows] = await pool.query('SELECT * FROM products WHERE id = ?', [order.productId]);
    const product = productRows[0];

    const [userRows] = await pool.query('SELECT username, email FROM users WHERE id = ?', [userId]);
    const user = userRows[0];

    const midtransOrderId = `PAY-${orderId}-${Date.now()}`;
    const parameter = {
        transaction_details: {
            order_id: midtransOrderId,
            gross_amount: order.totalPrice,
        },
        customer_details: {
            first_name: user.username,
            email: user.email,
        },
        item_details: [{
            id: order.productId,
            price: Math.round(Number(order.totalPrice) / order.quantity),
            quantity: order.quantity,
            name: product?.name ?? 'Produk',
        }],
        expiry: {
            unit: 'hours',
            duration: 24,
        },
    };

    const midtransResponse = await snap.createTransaction(parameter);

    const paymentId = uuidv4();
    const expiredAt = new Date(Date.now() + 24 * 60 * 60 * 1000);

    await pool.query(
        `INSERT INTO payments (id, orderId, userId, amount, paymentMethod, status, midtransOrderId, snapToken, snapUrl, expiredAt)
         VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
        [paymentId, orderId, userId, order.totalPrice, paymentMethod.toLowerCase(),
         'pending', midtransOrderId, midtransResponse.token, midtransResponse.redirect_url, expiredAt]
    );

    await pool.query("UPDATE orders SET status = 'waiting_payment' WHERE id = ?", [orderId]);

    const [newPayment] = await pool.query('SELECT * FROM payments WHERE id = ?', [paymentId]);

    return res.status(201).json({
        message: 'Pembayaran berhasil dibuat',
        snapUrl: midtransResponse.redirect_url,
        snapToken: midtransResponse.token,
        data: newPayment[0],
    });
};

// ========================= WEBHOOK MIDTRANS =========================
// POST /payment/webhook
const handleWebhook = async (req, res) => {
    const { order_id, transaction_status, fraud_status } = req.body;

    const [paymentRows] = await pool.query('SELECT * FROM payments WHERE midtransOrderId = ?', [order_id]);
    if (paymentRows.length === 0) {
        return res.status(404).json({ message: 'Payment tidak ditemukan' });
    }
    const payment = paymentRows[0];

    const [orderRows] = await pool.query('SELECT * FROM orders WHERE id = ?', [payment.orderId]);
    if (orderRows.length === 0) {
        return res.status(404).json({ message: 'Order tidak ditemukan' });
    }

    let paymentStatus, orderStatus;

    if (transaction_status === 'settlement' ||
        (transaction_status === 'capture' && fraud_status === 'accept')) {
        paymentStatus = 'paid';
        orderStatus = 'paid';
    } else if (transaction_status === 'expire') {
        paymentStatus = 'expired';
        orderStatus = 'cancelled';
    } else if (transaction_status === 'cancel' || transaction_status === 'deny') {
        paymentStatus = 'cancelled';
        orderStatus = 'cancelled';
    } else {
        return res.status(200).json({ message: 'Status tidak memerlukan update' });
    }

    await pool.query('UPDATE payments SET status = ? WHERE id = ?', [paymentStatus, payment.id]);
    await pool.query('UPDATE orders SET status = ? WHERE id = ?', [orderStatus, payment.orderId]);

    return res.status(200).json({ message: 'Webhook berhasil diproses' });
};

// ========================= RIWAYAT PEMBAYARAN (USER) =========================
// GET /payment/my-payments
const getPayments = async (req, res) => {
    const [payments] = await pool.query(
        'SELECT * FROM payments WHERE userId = ? ORDER BY createdAt DESC',
        [req.user.id]
    );

    return res.status(200).json({
        message: 'Riwayat pembayaran',
        total: payments.length,
        data: payments,
    });
};

// ========================= SEMUA PEMBAYARAN (ADMIN) =========================
// GET /payment/payments
const getAllPayments = async (req, res) => {
    const [payments] = await pool.query('SELECT * FROM payments ORDER BY createdAt DESC');

    return res.status(200).json({
        message: 'Semua data pembayaran',
        total: payments.length,
        data: payments,
    });
};

// ========================= DETAIL PEMBAYARAN =========================
// GET /payment/payments/:id
const getPaymentById = async (req, res) => {
    const { id } = req.params;

    if (req.user.role === 'admin') {
        const [payment] = await pool.query('SELECT * FROM payments WHERE id = ?', [id]);
        if (payment.length === 0) return res.status(404).json({ message: 'Pembayaran tidak ditemukan' });
        return res.status(200).json({ message: 'Pembayaran ditemukan', data: payment[0] });
    }

    const [payment] = await pool.query(
        'SELECT * FROM payments WHERE id = ? AND userId = ?',
        [id, req.user.id]
    );
    if (payment.length === 0) return res.status(404).json({ message: 'Pembayaran tidak ditemukan' });

    return res.status(200).json({ message: 'Pembayaran ditemukan', data: payment[0] });
};

// ========================= CANCEL PAYMENT =========================
// POST /payment/cancel-payment/:paymentId
const cancelPayment = async (req, res) => {
    const { paymentId } = req.params;
    const userId = req.user.id;

    const [paymentRows] = await pool.query(
        'SELECT * FROM payments WHERE id = ? AND userId = ?',
        [paymentId, userId]
    );
    if (paymentRows.length === 0) return res.status(404).json({ message: 'Pembayaran tidak ditemukan' });
    const payment = paymentRows[0];

    if (['cancelled', 'refunded', 'paid'].includes(payment.status)) {
        return res.status(400).json({ message: `Pembayaran sudah ${payment.status}` });
    }

    const [orderRows] = await pool.query('SELECT * FROM orders WHERE id = ?', [payment.orderId]);
    const order = orderRows[0];

    await pool.query('UPDATE payments SET status = ? WHERE id = ?', ['cancelled', paymentId]);
    await pool.query('UPDATE orders SET status = ? WHERE id = ?', ['cancelled', payment.orderId]);

    // Kembalikan stok
    if (order) {
        await pool.query(
            'UPDATE product_sizes SET stock = stock + ? WHERE productId = ? AND size = ?',
            [order.quantity, order.productId, order.size]
        );
    }

    const [updated] = await pool.query('SELECT * FROM payments WHERE id = ?', [paymentId]);

    return res.status(200).json({
        message: 'Pembayaran berhasil dibatalkan',
        data: updated[0],
    });
};

module.exports = { createPayment, getPayments, getPaymentById, getAllPayments, cancelPayment, handleWebhook };