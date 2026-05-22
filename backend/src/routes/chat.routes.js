const {getIo} = require('@/config/socket');
const express = require('express');
const router  = express.Router();
const { getOrCreateRoom, getMyRooms, getMessages, sendMessage, uploadChatImage } = require('@/controllers/chat.controller');
const { authMiddleware } = require('@/middleware/auth.middleware');
const {upload}  = require('@/middleware/image.up.middleware');


router.post('/room', authMiddleware, getOrCreateRoom);
router.get('/rooms', authMiddleware, getMyRooms);
router.get('/:roomId/messages', authMiddleware, getMessages);
router.post('/:roomId/send', authMiddleware, sendMessage);
router.post('/upload', authMiddleware, upload.single('image'), uploadChatImage);

module.exports = router;    