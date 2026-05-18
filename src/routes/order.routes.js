const express = require('express');
const router = express.Router();
const { createOrder, createOrderFromCart, getAllOrders, getOrderById, getMyOrders, cancelOrder } = require('@/controllers/order.controller');
const { authMiddleware } = require('@/middleware/auth.middleware');
const { roleMiddleware } = require('@/middleware/role.middleware');

router.post('/create-order', authMiddleware, createOrder);
router.post('/create-order-from-cart', authMiddleware, createOrderFromCart);
router.get('/all-orders', authMiddleware, roleMiddleware, getAllOrders);
router.get('/orders/:id', authMiddleware, getOrderById);
router.get('/my-orders', authMiddleware, getMyOrders);
router.post('/cancel-order', authMiddleware, cancelOrder);

module.exports = router;
