let io;

const init = (httpServer) => {
    const { Server } = require('socket.io');

    const allowedOrigins = [
        process.env.FRONTEND_URL || 'http://localhost:8080',
        'http://127.0.0.1:5500',
        'http://localhost:5500',
        'null'
    ];

    io = new Server(httpServer, {
        cors: {
            origin: process.env.NODE_ENV === 'production'
                ? process.env.FRONTEND_URL
                : allowedOrigins,
            methods: ['GET', 'POST']
        }
    });
    return io;
};

const getIo = () => {
    if (!io) throw new Error('Socket.io belum diinisialisasi');
    return io;
};

module.exports = { init, getIo };