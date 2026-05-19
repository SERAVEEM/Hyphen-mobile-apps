const express = require('express');
const router = express.Router();
const {getPayments, getPaymentById, getAllPayments, cancelPayment, handleWebhook } = require('@/controllers/payment.controller');
const { authMiddleware } = require('@/middleware/auth.middleware');
const { roleMiddleware } = require('@/middleware/role.middleware');

router.get('/my-payments', authMiddleware, getPayments);
router.get('/payments/:paymentId', authMiddleware, getPaymentById);
router.post('/cancel/:paymentId', authMiddleware, cancelPayment);
router.post('/webhook', handleWebhook);

router.get('/config', (req, res) => {
    res.json({ 
        clientKey: process.env.MIDTRANS_CLIENT_KEY,
        isProduction: process.env.MIDTRANS_IS_PRODUCTION === 'true'
    });
});

//ini buat admin
router.get('/all-payments', authMiddleware, roleMiddleware, getAllPayments)

module.exports = router;