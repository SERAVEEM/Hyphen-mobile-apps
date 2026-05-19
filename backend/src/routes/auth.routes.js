const express = require('express');
const router = express.Router();
const {register,verifyEmail, resendOTP, login, forgotPassword, resetPassword, refreshAccessToken, logout} = require('@/controllers/auth.controller')
const { authMiddleware } = require('@/middleware/auth.middleware');
const { roleMiddleware } = require('@/middleware/role.middleware');

router.post('/register', register);
router.post('/verify-email', verifyEmail);
router.post('/resend-otp', resendOTP);
router.post('/login', login);
router.post('/forgot-password', forgotPassword);
router.post('/reset-password', resetPassword);
router.post('/refresh-token', refreshAccessToken);
router.post('/logout', authMiddleware, logout);

module.exports = router;

