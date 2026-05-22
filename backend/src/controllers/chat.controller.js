const { v4: uuidv4 } = require('uuid');
const db = require('@/config/db');
const { getIo } = require('@/config/socket');
const cloudinary = require('@/config/cloudinary');


// ================== BUAT / AMBIL ROOM CHAT ==================
const getOrCreateRoom = async (req, res) => {
    try {
        const buyerId = req.user.id;
        const { sellerId, productId } = req.body;

        if (!sellerId || !productId) {
            return res.status(400).json({ message: 'sellerId dan productId wajib diisi' });
        }

        // Cek room sudah ada atau belum
        const [existing] = await db.query(
            'SELECT * FROM chat_rooms WHERE buyerId = ? AND sellerId = ? AND productId = ?',
            [buyerId, sellerId, productId]
        );

        if (existing.length > 0) {
            return res.status(200).json({
                message: 'Room chat ditemukan',
                data: existing[0]
            });
        }

        // Buat room baru
        const id = uuidv4();
        await db.query(
            'INSERT INTO chat_rooms (id, userId, sellerId, productId) VALUES (?, ?, ?, ?)',
            [id, buyerId, sellerId, productId]
        );

        return res.status(201).json({
            message: 'Room chat berhasil dibuat',
            data: { id, buyerId, sellerId, productId }
        });
    } catch (error) {
        return res.status(500).json({
            message: 'Gagal membuat room chat',
            error: error.message
        });
    }
};

// ================== GET SEMUA ROOM MILIK USER ==================
const getMyRooms = async (req, res) => {
    try {
        const userId = req.user.id;

        const [rooms] = await db.query(
            `SELECT cr.*, 
                (SELECT cm.message FROM chat_messages cm 
                 WHERE cm.roomId = cr.id 
                 ORDER BY cm.createdAt DESC LIMIT 1) as lastMessage,
                (SELECT cm.createdAt FROM chat_messages cm 
                 WHERE cm.roomId = cr.id 
                 ORDER BY cm.createdAt DESC LIMIT 1) as lastMessageAt,
                (SELECT COUNT(*) FROM chat_messages cm 
                 WHERE cm.roomId = cr.id AND cm.isRead = 0 AND cm.senderId != ?) as unreadCount
             FROM chat_rooms cr
             WHERE cr.userId = ? OR cr.sellerId = ?
             ORDER BY lastMessageAt DESC`,
            [userId, userId, userId]
        );

        return res.status(200).json({
            message: 'Daftar room chat',
            total: rooms.length,
            data: rooms
        });
    } catch (error) {
        return res.status(500).json({
            message: 'Gagal mengambil room chat',
            error: error.message
        });
    }
};

// ================== GET MESSAGES DI ROOM ==================
const getMessages = async (req, res) => {
    try {
        const { roomId } = req.params;
        const userId = req.user.id;

        // Validasi user adalah member room
        const [room] = await db.query(
            'SELECT * FROM chat_rooms WHERE id = ? AND (userId = ? OR sellerId = ?)',
            [roomId, userId, userId]
        );

        if (room.length === 0) {
            return res.status(403).json({ message: 'Akses tidak diizinkan' });
        }

        // Ambil semua pesan
        const [messages] = await db.query(
            'SELECT * FROM chat_messages WHERE roomId = ? ORDER BY createdAt ASC',
            [roomId]
        );

        // Tandai pesan sebagai sudah dibaca
        await db.query(
            'UPDATE chat_messages SET isRead = 1 WHERE roomId = ? AND senderId != ? AND isRead = 0',
            [roomId, userId]
        );

        return res.status(200).json({
            message: 'Pesan berhasil diambil',
            total: messages.length,
            data: messages
        });
    } catch (error) {
        return res.status(500).json({
            message: 'Gagal mengambil pesan',
            error: error.message
        });
    }
};

// ================== KIRIM PESAN (REST fallback) ==================
const sendMessage = async (req, res) => {
    try {
        const { roomId } = req.params;
        const { message, imageUrl } = req.body;
        const senderId = req.user.id;

        if (!message && !imageUrl) {
            return res.status(400).json({ message: 'Pesan atau gambar wajib diisi' });
        }

        // Validasi user adalah member room
        const [room] = await db.query(
            'SELECT * FROM chat_rooms WHERE id = ? AND (userId = ? OR sellerId = ?)',
            [roomId, senderId, senderId]
        );

        if (room.length === 0) {
            return res.status(403).json({ message: 'Akses tidak diizinkan' });
        }

        const id = uuidv4();
        const type = imageUrl ? 'image' : 'text';

        await db.query(
            'INSERT INTO chat_messages (id, roomId, senderId, message, imageUrl, type) VALUES (?, ?, ?, ?, ?, ?)',
            [id, roomId, senderId, message ?? null, imageUrl ?? null, type]
        );

        const newMessage = {
            id, roomId, senderId, message, imageUrl, type,
            isRead: false,
            createdAt: new Date().toISOString()
        };

        const io = getIo();
        io.to(roomId).emit('new_message', newMessage);

        return res.status(201).json({
            message: 'Pesan berhasil dikirim',
            data: newMessage
        });
    } catch (error) {
        return res.status(500).json({
            message: 'Gagal mengirim pesan',
            error: error.message
        });
    }
};


// ================== KIRIM FOTO IMAGE ==================
const uploadChatImage = async (req, res) => {
    try {
        if (!req.file) {
            return res.status(400).json({ message: 'File gambar wajib diupload' });
        }

        const result = await new Promise((resolve, reject) => {
            cloudinary.uploader.upload_stream(
                { folder: 'chat_images', resource_type: 'image' },
                (error, result) => {
                    if (error) reject(error);
                    else resolve(result);
                }
            ).end(req.file.buffer);
        });

        return res.status(200).json({
            message: 'Gambar berhasil diupload',
            imageUrl: result.secure_url
        });
    } catch (error) {
        return res.status(500).json({
            message: 'Gagal upload gambar',
            error: error.message
        });
    }
};

module.exports = { getOrCreateRoom, getMyRooms, getMessages, sendMessage, uploadChatImage };