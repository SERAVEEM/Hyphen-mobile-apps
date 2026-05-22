const express = require('express');
const router = express.Router();
const { addToCart, getCart, removeFromCart, clearCart } = require('@/controllers/cart.controller');
const { authMiddleware } = require('@/middleware/auth.middleware');

router.get('/getcart', authMiddleware, getCart);
router.post('/addcart', authMiddleware, addToCart);
router.delete('/removefromcart/:productId', authMiddleware, removeFromCart);
router.delete('/clearcart', authMiddleware, clearCart);

module.exports = router;