const { v4: uuidv4 } = require('uuid');
const db = require('@/config/db');
const { getIo } = require('@/config/socket');
const cloudinary = require('@/config/cloudinary');


// ================== BUAT / AMBIL ROOM CHAT ==================
const getOrCreateRoom = async (req, res) => {
    try {
        const userId = req.user.id;
        const { sellerId, productId } = req.body;

        if (!sellerId || !productId) {
            return res.status(400).json({ message: 'sellerId dan productId wajib diisi' });
        }

        // Cek room sudah ada atau belum
        const [existing] = await db.query(
            'SELECT * FROM chat_rooms WHERE userId = ? AND sellerId = ? AND productId = ?',
            [userId, sellerId, productId]
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
            [id, userId, sellerId, productId]
        );

        return res.status(201).json({
            message: 'Room chat berhasil dibuat',
            data: { id, userId, sellerId, productId }
        });
    } catch (error) {
        return res.status(500).json({
            message: 'Gagal membuat room chat',
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

// ================== GET INBOX ==================
// Menampilkan semua room chat milik user yang sudah ada pesannya,
// diurutkan berdasarkan pesan terakhir (terbaru di atas).
// Setiap item berisi: info lawan bicara, info produk, pesan terakhir, jumlah unread.
const getInbox = async (req, res) => {
    try {
        const userId = req.user.id;

        const [rooms] = await db.query(
            `SELECT
                cr.id                       AS roomId,
                cr.productId,

                -- Info produk
                p.name                      AS productName,
                p.imageUrl                  AS productImageUrl,
                p.price                     AS productPrice,

                -- Lawan bicara: kalau user adalah buyer → tampilkan seller, sebaliknya tampilkan buyer
                CASE WHEN cr.userId = ? THEN cr.sellerId ELSE cr.userId END
                                            AS otherUserId,
                CASE WHEN cr.userId = ? THEN su.username ELSE bu.username END
                                            AS otherUsername,
                CASE WHEN cr.userId = ? THEN sp.photoUrl ELSE bp.photoUrl END
                                            AS otherPhotoUrl,

                -- Role kita dalam room ini
                CASE WHEN cr.userId = ? THEN 'buyer' ELSE 'seller' END
                                            AS myRole,

                -- Pesan terakhir
                lm.message                  AS lastMessage,
                lm.imageUrl                 AS lastMessageImageUrl,
                lm.type                     AS lastMessageType,
                lm.senderId                 AS lastMessageSenderId,
                lm.createdAt                AS lastMessageAt,

                -- Jumlah pesan belum dibaca (yang dikirim lawan bicara)
                COALESCE(unread.cnt, 0)     AS unreadCount

            FROM chat_rooms cr

            -- Join produk
            JOIN products p ON p.id = cr.productId

            -- Join user buyer
            JOIN users bu ON bu.id = cr.userId
            LEFT JOIN user_profiles bp ON bp.userId = bu.id

            -- Join user seller
            JOIN users su ON su.id = cr.sellerId
            LEFT JOIN user_profiles sp ON sp.userId = su.id

            -- Subquery: pesan terakhir di tiap room (MariaDB-compatible)
            LEFT JOIN chat_messages lm
                ON lm.id = (
                    SELECT id FROM chat_messages
                    WHERE roomId = cr.id
                    ORDER BY createdAt DESC
                    LIMIT 1
                )

            -- Subquery: hitung unread
            LEFT JOIN (
                SELECT roomId, COUNT(*) AS cnt
                FROM chat_messages
                WHERE senderId != ? AND isRead = 0
                GROUP BY roomId
            ) unread ON unread.roomId = cr.id

            WHERE
                (cr.userId = ? OR cr.sellerId = ?)
                AND lm.createdAt IS NOT NULL   -- hanya room yang sudah ada pesannya

            ORDER BY lm.createdAt DESC`,
            [
                userId, userId, userId, userId, // CASE WHEN x4
                userId,                         // unread subquery: senderId != ?
                userId, userId                  // WHERE: cr.userId = ? OR cr.sellerId = ?
            ]
        );

        return res.status(200).json({
            message: 'Inbox berhasil diambil',
            total: rooms.length,
            data: rooms
        });
    } catch (error) {
        console.error('getInbox error:', error);
        return res.status(500).json({
            message: 'Gagal mengambil inbox',
            error: error.message
        });
    }
};

module.exports = { getOrCreateRoom, getInbox, getMessages, sendMessage, uploadChatImage };