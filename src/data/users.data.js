// src/data/users.data.js — ganti isinya
const bcrypt = require('bcrypt');
const pool = require('@/config/db');
const { v4: uuidv4 } = require('uuid');

const initAdmin = async () => {
    const [existing] = await pool.query("SELECT id FROM users WHERE role = 'admin' LIMIT 1");
    if (existing.length > 0) return;

    const hashedPassword = await bcrypt.hash(process.env.ADMIN_PASSWORD, 10);
    await pool.query(
        'INSERT INTO users (id, username, email, password, role, isVerified) VALUES (?, ?, ?, ?, ?, ?)',
        [uuidv4(), 'admin123', 'admin123@gmail.com', hashedPassword, 'admin', 1]
    );
    console.log('✅ Admin berhasil dibuat');
};

module.exports = { initAdmin };