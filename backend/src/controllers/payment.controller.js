const pool = require('@/config/db');
const midtransClient = require('midtrans-client');

const snap = new midtransClient.Snap({
    isProduction: process.env.MIDTRANS_IS_PRODUCTION === 'true',
    serverKey: process.env.MIDTRANS_SERVER_KEY,
});

// ========================= WEBHOOK MIDTRANS =========================
const handleWebhook = async (req, res) => {
    try {
        const { order_id, transaction_status, fraud_status } = req.body;

        if (!order_id || !transaction_status) {
            return res.status(400).json({ message: 'order_id dan transaction_status wajib ada' });
        }

        const [paymentRows] = await pool.query(
            'SELECT * FROM payments WHERE midtransOrderId = ?', [order_id]
        );
        if (paymentRows.length === 0) {
            // Tetap return 200 supaya Midtrans tidak retry terus
            return res.status(200).json({ message: 'Payment tidak ditemukan, diabaikan' });
        }
        const payment = paymentRows[0];

        const [orderRows] = await pool.query('SELECT * FROM orders WHERE id = ?', [payment.orderId]);
        if (orderRows.length === 0) {
            return res.status(200).json({ message: 'Order tidak ditemukan, diabaikan' });
        }

        // Kalau sudah paid, jangan diproses ulang
        if (payment.status === 'paid') {
            return res.status(200).json({ message: 'Payment sudah diproses sebelumnya' });
        }

        let paymentStatus, orderStatus;

        if (
            transaction_status === 'settlement' ||
            (transaction_status === 'capture' && fraud_status === 'accept')
        ) {
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

        // Kembalikan stok kalau cancelled/expired
        if (['cancelled', 'expired'].includes(paymentStatus)) {
            const order = orderRows[0];
            await pool.query(
                'UPDATE product_sizes SET stock = stock + ? WHERE productId = ? AND size = ?',
                [order.quantity, order.productId, order.size]
            );
        }

        return res.status(200).json({ message: 'Webhook berhasil diproses' });
    } catch (error) {
        console.error('handleWebhook error:', error);
        // Tetap return 200 supaya Midtrans tidak retry terus
        return res.status(200).json({ message: 'Webhook diterima', error: error.message });
    }
};

// ========================= RIWAYAT PEMBAYARAN (USER) =========================
const getPayments = async (req, res) => {
    try {
        const [payments] = await pool.query(
            'SELECT * FROM payments WHERE userId = ? ORDER BY createdAt DESC',
            [req.user.id]
        );

        return res.status(200).json({
            message: 'Riwayat pembayaran',
            total: payments.length,
            data: payments,
        });
    } catch (error) {
        console.error('getPayments error:', error);
        return res.status(500).json({ message: 'Internal server error', error: error.message });
    }
};

// ========================= SEMUA PEMBAYARAN (ADMIN) =========================
const getAllPayments = async (req, res) => {
    try {
        const [payments] = await pool.query('SELECT * FROM payments ORDER BY createdAt DESC');

        return res.status(200).json({
            message: 'Semua data pembayaran',
            total: payments.length,
            data: payments,
        });
    } catch (error) {
        console.error('getAllPayments error:', error);
        return res.status(500).json({ message: 'Internal server error', error: error.message });
    }
};

// ========================= DETAIL PEMBAYARAN =========================
const getPaymentById = async (req, res) => {
    try {
        const { id } = req.params;

        if (req.user.role === 'admin') {
            const [payment] = await pool.query('SELECT * FROM payments WHERE id = ?', [id]);
            if (payment.length === 0) {
                return res.status(404).json({ message: 'Pembayaran tidak ditemukan' });
            }
            return res.status(200).json({ message: 'Pembayaran ditemukan', data: payment[0] });
        }

        const [payment] = await pool.query(
            'SELECT * FROM payments WHERE id = ? AND userId = ?',
            [id, req.user.id]
        );
        if (payment.length === 0) {
            return res.status(404).json({ message: 'Pembayaran tidak ditemukan' });
        }

        return res.status(200).json({ message: 'Pembayaran ditemukan', data: payment[0] });
    } catch (error) {
        console.error('getPaymentById error:', error);
        return res.status(500).json({ message: 'Internal server error', error: error.message });
    }
};

// ========================= CANCEL PAYMENT =========================
const cancelPayment = async (req, res) => {
    try {
        const { paymentId } = req.params;
        const userId = req.user.id;

        const [paymentRows] = await pool.query(
            'SELECT * FROM payments WHERE id = ? AND userId = ?',
            [paymentId, userId]
        );
        if (paymentRows.length === 0) {
            return res.status(404).json({ message: 'Pembayaran tidak ditemukan' });
        }
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
    } catch (error) {
        console.error('cancelPayment error:', error);
        return res.status(500).json({ message: 'Internal server error', error: error.message });
    }
};

module.exports = { getPayments, getPaymentById, getAllPayments, cancelPayment, handleWebhook };