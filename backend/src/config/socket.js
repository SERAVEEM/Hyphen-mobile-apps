let io;

const init = (httpServer) => {
    const { Server } = require('socket.io');
    io = new Server(httpServer, {
        cors: {
            origin: '*',
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