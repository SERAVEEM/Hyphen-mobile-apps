const express  = require('express');
const router   = express.Router();
const { checkout } = require('@/controllers/checkout.controller');
const { authMiddleware } = require('@/middleware/auth.middleware');
const { requireProfile } = require('@/middleware/profile.middleware');

router.post('/checkout', authMiddleware, requireProfile, checkout);

module.exports = router;