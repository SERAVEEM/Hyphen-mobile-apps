const express = require('express');
const router = express.Router();
const { createOrder, createOrderFromCart, getAllOrders, getOrderById, getMyOrders, cancelOrder } = require('@/controllers/order.controller');
const { authMiddleware } = require('@/middleware/auth.middleware');
const { roleMiddleware } = require('@/middleware/role.middleware');

router.post('/create', authMiddleware, createOrder);
router.post('/create/from-cart', authMiddleware, createOrderFromCart);
router.get('/orders', authMiddleware, roleMiddleware, getAllOrders);
router.get('/orders/:orderId', authMiddleware, getOrderById);
router.get('/my-orders', authMiddleware, getMyOrders);
router.post('/cancel/:orderId', authMiddleware, cancelOrder);

module.exports = router;
