const express = require('express');
const router = express.Router();
const { createOrder, createOrderFromCart, getAllOrders, getOrderById, getMyOrders, cancelOrder } = require('@/controllers/order.controller');
const { authMiddleware } = require('@/middleware/auth.middleware');
const { roleMiddleware } = require('@/middleware/role.middleware');
const {requireProfile} = require('@/middleware/profile.middleware');


router.post('/create', authMiddleware, requireProfile, createOrder);
router.post('/create/from-cart', authMiddleware, requireProfile, createOrderFromCart);
router.get('/orders', authMiddleware, roleMiddleware, getAllOrders);
router.get('/orders/:orderId', authMiddleware, getOrderById);
router.get('/my-orders', authMiddleware, requireProfile, getMyOrders);
router.post('/cancel/:orderId', authMiddleware, requireProfile, cancelOrder);

module.exports = router;
