const express = require('express');
const router = express.Router();

const { authMiddleware } = require('@/middleware/auth.middleware');
const { requireProfile } = require('@/middleware/profile.middleware');
const {upload} = require('@/middleware/image.up.middleware');
const { getProfile, createProfile, updateProfile, updatePhotoProfile, changePassword, deleteUser } = require('@/controllers/user.controller');

router.get('/profile', authMiddleware, getProfile);
router.post('/create', authMiddleware, createProfile);
router.put('/update', authMiddleware, requireProfile, updateProfile);
router.put('/profile/photo', authMiddleware, requireProfile, upload.single('photo'), updatePhotoProfile);
router.put('/change-password', authMiddleware, changePassword);
router.delete('/delete', authMiddleware, deleteUser);

module.exports = router;