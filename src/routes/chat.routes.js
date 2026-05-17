const {getIo} = require('@/config/socket');
const express = require('express');
const router  = express.Router();
const { getOrCreateRoom, getMyRooms, getMessages, sendMessage } = require('@/controllers/chat.controller');
const { authMiddleware } = require('@/middleware/auth.middleware');


router.post('/room', authMiddleware, getOrCreateRoom);
router.get('/rooms', authMiddleware, getMyRooms);
router.get('/:roomId/messages', authMiddleware, getMessages);
router.post('/:roomId/send', authMiddleware, sendMessage);

module.exports = router;