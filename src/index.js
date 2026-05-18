require('dotenv').config();
require('module-alias/register');
const { initAdmin } = require('@/data/users.data');
const socketConfig = require('@/config/socket');
initAdmin();

const express = require('express');
const http = require('http');
const { Server } = require('socket.io');
const { v4: uuidv4 } = require('uuid');
const db = require('@/config/db');
const swaggerUi = require('swagger-ui-express');
const swaggerDocument = require('../swagger.json');

const authRoutes = require('@/routes/auth.routes');
const userRoutes = require('@/routes/user.routes');
const productRoutes = require('@/routes/product.routes');
const wishlistRoutes = require('@/routes/wishlist.routes');
const cartRoutes = require('@/routes/cart.routes');
const orderRoutes = require('@/routes/order.routes');
const paymentRoutes = require('@/routes/payment.routes');
const addressRoutes = require('@/routes/address.routes');
const shippingRoutes = require('@/routes/shipping.routes');
const checkoutRoutes = require('@/routes/checkout.routes');
const chatRoutes = require('@/routes/chat.routes');

const app = express();
const server = http.createServer(app); // ← http server dari express
const io = new Server(server, {
  cors: {
    origin: '*',
    methods: ['GET', 'POST']
  }
});
socketConfig.setIo(io);

io.on('connection', (socket) => {
  console.log('✅ User connected:', socket.id);

  // Join room
  socket.on('join_room', (roomId) => {
    socket.join(roomId);
    console.log(`User ${socket.id} joined room ${roomId}`);
  });

  // Kirim pesan
  socket.on('send_message', async (data) => {
    const { roomId, senderId, message, imageUrl } = data;
    try {
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

      // Broadcast ke semua user di room
      io.to(roomId).emit('new_message', newMessage);

    } catch (error) {
      socket.emit('error', { message: 'Gagal mengirim pesan' });
    }
  });

  // Typing indicator
  socket.on('typing', (data) => {
    socket.to(data.roomId).emit('user_typing', {
      userId: data.userId,
      username: data.username
    });
  });

  socket.on('stop_typing', (data) => {
    socket.to(data.roomId).emit('user_stop_typing', {
      userId: data.userId
    });
  });

  // Tandai pesan sudah dibaca
  socket.on('read_messages', async (data) => {
    const { roomId, userId } = data;
    await db.query(
      'UPDATE chat_messages SET isRead = 1 WHERE roomId = ? AND senderId != ? AND isRead = 0',
      [roomId, userId]
    );
    socket.to(roomId).emit('messages_read', { roomId, userId });
  });

  socket.on('disconnect', () => {
    console.log('❌ User disconnected:', socket.id);
  });
});

// Swagger
app.use('/api-docs', swaggerUi.serve, swaggerUi.setup(swaggerDocument));

// Middleware
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Routes
app.get('/', (req, res) => {
  res.json({ message: 'API is running' });
});

app.use('/api/v1/auth', authRoutes);
app.use('/api/v1/user', userRoutes);
app.use('/api/v1/product', productRoutes);
app.use('/api/v1/wishlist', wishlistRoutes);
app.use('/api/v1/cart', cartRoutes);
app.use('/api/v1/order', orderRoutes);
app.use('/api/v1/payment', paymentRoutes);
app.use('/api/v1/address', addressRoutes);
app.use('/api/v1/shipping', shippingRoutes);
app.use('/api/v1/checkout', checkoutRoutes);
app.use('/api/v1/chat', chatRoutes);

// Global error handler
app.use((err, req, res, next) => {
  console.error(err.stack);
  res.status(500).json({ message: 'Internal Server Error' });
});


const PORT = process.env.PORT || 3000;
server.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
});