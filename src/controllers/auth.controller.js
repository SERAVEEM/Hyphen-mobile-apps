const { v4: uuidv4 } = require('uuid');
const bcrypt = require('bcrypt');
const jwt = require('jsonwebtoken');
const pool = require('@/config/db');
const { validateUser, generateOTP } = require('@/helpers/auth.helpers');

const SECRET_KEY = process.env.SECRET_KEY;
const REFRESH_SECRET_KEY = process.env.REFRESH_SECRET_KEY;

//========================= REGISTER =======================
// POST /auth/register
const register = async (req, res) => {
    const { username, email, password } = req.body;

    if (!username || !email || !password) {
        return res.status(400).json({ message: 'Semua field wajib diisi' });
    }

    const error = validateUser(username, email, password);
    if (error) {
        return res.status(400).json({ message: error });
    }

    const [existing] = await pool.query('SELECT id FROM users WHERE email = ?', [email]);
    if (existing.length > 0) {
        return res.status(400).json({ message: 'Email sudah terdaftar' });
    }

    const hashedPassword = await bcrypt.hash(password, 10);
    const id = uuidv4();

    await pool.query(
        'INSERT INTO users (id, username, email, password, role, isVerified) VALUES (?, ?, ?, ?, ?, ?)',
        [id, username, email, hashedPassword, 'user', 0]
    );

    const otp = generateOTP();
    const otpExpiry = Date.now() + 10 * 60 * 1000;

    await pool.query('DELETE FROM email_verifications WHERE email = ?', [email]);
    await pool.query(
        'INSERT INTO email_verifications (email, otp, otpExpiry) VALUES (?, ?, ?)',
        [email, otp, otpExpiry]
    );

    console.log(`OTP register ${email}: ${otp}`);

    res.status(201).json({
        message: 'Register berhasil',
        data: { id, username, email, role: 'user', isVerified: false }
    });
};

//========================= VERIFY EMAIL =======================
// POST /auth/verify-email
const verifyEmail = async (req, res) => {
    const { email, otp } = req.body;

    const [rows] = await pool.query(
        'SELECT * FROM email_verifications WHERE email = ? AND otp = ?',
        [email, otp]
    );

    if (rows.length === 0) {
        return res.status(400).json({ message: 'OTP salah' });
    }

    if (Date.now() > rows[0].otpExpiry) {
        return res.status(400).json({ message: 'OTP expired' });
    }

    const [user] = await pool.query('SELECT id FROM users WHERE email = ?', [email]);
    if (user.length === 0) {
        return res.status(400).json({ message: 'User tidak ditemukan' });
    }

    await pool.query('UPDATE users SET isVerified = 1 WHERE email = ?', [email]);
    await pool.query('DELETE FROM email_verifications WHERE email = ?', [email]);

    res.json({ message: 'Email berhasil diverifikasi' });
};

// ========================= RESEND OTP =========================
// POST /auth/resend-otp
const resendOTP = async (req, res) => {
    const { email } = req.body;

    const [user] = await pool.query('SELECT id, isVerified FROM users WHERE email = ?', [email]);
    if (user.length === 0) {
        return res.status(400).json({ message: 'Email tidak ditemukan' });
    }

    if (user[0].isVerified) {
        return res.status(400).json({ message: 'Email sudah diverifikasi' });
    }

    const otp = generateOTP();
    const otpExpiry = Date.now() + 10 * 60 * 1000;

    await pool.query('DELETE FROM email_verifications WHERE email = ?', [email]);
    await pool.query(
        'INSERT INTO email_verifications (email, otp, otpExpiry) VALUES (?, ?, ?)',
        [email, otp, otpExpiry]
    );

    console.log(`OTP baru untuk ${email}: ${otp}`);

    res.status(200).json({
        message: 'OTP berhasil dikirim',
        data: { email, otp }
    });
};

//======================= LOGIN =======================
// POST /auth/login
const login = async (req, res) => {
    const { email, password } = req.body;

    const [rows] = await pool.query('SELECT * FROM users WHERE email = ?', [email]);
    if (rows.length === 0) {
        return res.status(400).json({ message: 'Email tidak ditemukan' });
    }

    const user = rows[0];

    if (!user.isVerified) {
        return res.status(400).json({ message: 'Email belum diverifikasi' });
    }

    const isMatch = await bcrypt.compare(password, user.password);
    if (!isMatch) {
        return res.status(400).json({ message: 'Password salah' });
    }

    const payload = {
        id: user.id,
        username: user.username,
        email: user.email,
        role: user.role === 'admin' ? 'admin' : 'user'
    };

    const accessToken = jwt.sign(payload, SECRET_KEY, { expiresIn: '15m' });
    const refreshToken = jwt.sign({ id: user.id }, REFRESH_SECRET_KEY, { expiresIn: '7d' });
    const expiry = Date.now() + 7 * 24 * 60 * 60 * 1000;

    await pool.query('DELETE FROM refresh_tokens WHERE userId = ?', [user.id]);
    await pool.query(
        'INSERT INTO refresh_tokens (userId, token, expiry) VALUES (?, ?, ?)',
        [user.id, refreshToken, expiry]
    );

    res.status(200).json({
        message: 'Login berhasil',
        accessToken,
        refreshToken,
        data: { id: user.id, username: user.username, email: user.email }
    });
};

//========================= LOGOUT =======================
// POST /auth/logout
const logout = async (req, res) => {
    const { refreshToken } = req.body;

    await pool.query('DELETE FROM refresh_tokens WHERE token = ?', [refreshToken]);

    res.status(200).json({ message: 'Logout berhasil' });
};

//==================== FORGOT PASSWORD ===================
// POST /auth/forgot-password
const forgotPassword = async (req, res) => {
    const { email } = req.body;

    const [user] = await pool.query('SELECT id FROM users WHERE email = ?', [email]);
    if (user.length === 0) {
        return res.status(400).json({ message: 'Email tidak ditemukan' });
    }

    const otp = generateOTP();
    const otpExpiry = Date.now() + 10 * 60 * 1000;

    await pool.query('DELETE FROM reset_tokens WHERE email = ?', [email]);
    await pool.query(
        'INSERT INTO reset_tokens (email, otp, otpExpiry) VALUES (?, ?, ?)',
        [email, otp, otpExpiry]
    );

    console.log(`OTP untuk ${email}: ${otp} (berlaku sampai ${new Date(otpExpiry).toLocaleTimeString()})`);

    res.status(200).json({
        message: 'OTP berhasil dikirim',
        data: { email, otp }
    });
};

//=========================RESET PASSWORD=======================
// POST /auth/reset-password
const resetPassword = async (req, res) => {
    const { email, otp, newPassword } = req.body;

    const [rows] = await pool.query(
        'SELECT * FROM reset_tokens WHERE email = ? AND otp = ?',
        [email, otp]
    );

    if (rows.length === 0) {
        return res.status(400).json({ message: 'OTP tidak valid' });
    }

    if (Date.now() > rows[0].otpExpiry) {
        return res.status(400).json({ message: 'OTP telah expired' });
    }

    const [user] = await pool.query('SELECT id FROM users WHERE email = ?', [email]);
    if (user.length === 0) {
        return res.status(400).json({ message: 'Email tidak ditemukan' });
    }

    const hashedPassword = await bcrypt.hash(newPassword, 10);
    await pool.query('UPDATE users SET password = ? WHERE email = ?', [hashedPassword, email]);
    await pool.query('DELETE FROM reset_tokens WHERE email = ?', [email]);

    res.status(200).json({ message: 'Password berhasil diubah' });
};

//========================= REFRESH TOKEN =======================
// POST /auth/refresh-token
const refreshAccessToken = async (req, res) => {
    const { refreshToken } = req.body;

    if (!refreshToken) {
        return res.status(400).json({ message: 'Refresh token tidak ada' });
    }

    const [rows] = await pool.query('SELECT * FROM refresh_tokens WHERE token = ?', [refreshToken]);
    if (rows.length === 0) {
        return res.status(403).json({ message: 'Refresh token tidak valid atau sudah logout' });
    }

    if (Date.now() > rows[0].expiry) {
        await pool.query('DELETE FROM refresh_tokens WHERE token = ?', [refreshToken]);
        return res.status(403).json({ message: 'Refresh token sudah expired, silakan login ulang' });
    }

    let decoded;
    try {
        decoded = jwt.verify(refreshToken, REFRESH_SECRET_KEY);
    } catch (err) {
        await pool.query('DELETE FROM refresh_tokens WHERE token = ?', [refreshToken]);
        return res.status(403).json({ message: 'Refresh token tidak valid' });
    }

    const [user] = await pool.query('SELECT * FROM users WHERE id = ?', [decoded.id]);
    if (user.length === 0) {
        return res.status(403).json({ message: 'User tidak ditemukan' });
    }

    const newAccessToken = jwt.sign(
        { id: user[0].id, username: user[0].username, email: user[0].email, role: user[0].role === 'admin' ? 'admin' : 'user' },
        SECRET_KEY,
        { expiresIn: '15m' }
    );

    res.status(200).json({
        message: 'Access token berhasil diperbarui',
        accessToken: newAccessToken
    });
};

module.exports = { register, verifyEmail, resendOTP, login, forgotPassword, resetPassword, refreshAccessToken, logout };