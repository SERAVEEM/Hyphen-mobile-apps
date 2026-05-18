const express = require('express');
const router = express.Router();

const {authMiddleware} = require('@/middleware/auth.middleware');
const { getWishlist, addWishlist, removeWishlist } = require('@/controllers/wishlist.controller');


//WISHLIST
router.get('/wishlist', authMiddleware, getWishlist);
router.post('/add-wishlist', authMiddleware, addWishlist);
router.delete('/remove-wishlist/:productId', authMiddleware, removeWishlist);

module.exports = router;    