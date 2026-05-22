const express = require('express');
const router = express.Router();

const {authMiddleware} = require('@/middleware/auth.middleware');
const { getWishlist, addWishlist, removeWishlist } = require('@/controllers/wishlist.controller');


//WISHLIST
router.get('/getwishlist', authMiddleware, getWishlist);
router.post('/add', authMiddleware, addWishlist);
router.delete('/remove/:productId', authMiddleware, removeWishlist);

module.exports = router;    