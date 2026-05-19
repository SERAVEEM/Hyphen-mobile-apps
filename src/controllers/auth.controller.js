const { v4: uuidv4 } = require('uuid');
const bcrypt = require('bcrypt');
const jwt = require('jsonwebtoken');
const pool = require('@/config/db');
const { validateUser, generateOTP } = require('@/helpers/auth.helpers');
const { sendOTPEmail } = require('@/helpers/auth.helpers');

const SECRET_KEY = process.env.SECRET_KEY;
const REFRESH_SECRET_KEY = process.env.REFRESH_SECRET_KEY;


//========================= REGISTER =======================
// POST /auth/register
const register = async (req, res) => {
    try {
        const { username, email, password } = req.body;

        if (!username || !email || !password) {
            return res.status(400).json({ message: 'Semua field wajib diisi' });
        }

        const error = validateUser(username, email, password);
        if (error) return res.status(400).json({ message: error });

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

        await sendOTPEmail(
            email,
            otp,
            'Verifikasi Email Anda',
            `Halo ${username}, terima kasih sudah mendaftar. Gunakan kode OTP berikut untuk memverifikasi akun Anda.`
        );

        return res.status(201).json({
            message: 'Register berhasil. Silakan cek email Anda untuk kode OTP.',
            data: { userId: id, username, email, role: 'user', isVerified: false }
        });
    } catch (error) {
        console.error('register error:', error);
        return res.status(500).json({ message: 'Internal server error', error: error.message });
    }
};

//========================= VERIFY EMAIL =======================
// POST /auth/verify-email
const verifyEmail = async (req, res) => {
    try {
        const { email, otp } = req.body;

        if (!email || !otp) {
            return res.status(400).json({ message: 'Email dan OTP wajib diisi' });
        }

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

        return res.json({ message: 'Email berhasil diverifikasi' });
    } catch (error) {
        console.error('verifyEmail error:', error);
        return res.status(500).json({ message: 'Internal server error', error: error.message });
    }
};

//========================= RESEND OTP =======================
// POST /auth/resend-otp
const resendOTP = async (req, res) => {
    try {
        const { email } = req.body;

        if (!email) {
            return res.status(400).json({ message: 'Email wajib diisi' });
        }

        const [user] = await pool.query('SELECT id, username, isVerified FROM users WHERE email = ?', [email]);
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

        await sendOTPEmail(
            email,
            otp,
            'Kode OTP Baru',
            `Halo ${user[0].username}, berikut adalah kode OTP baru untuk verifikasi akun Anda.`
        );

        return res.status(200).json({ message: 'OTP berhasil dikirim ke email Anda.' });
    } catch (error) {
        console.error('resendOTP error:', error);
        return res.status(500).json({ message: 'Internal server error', error: error.message });
    }
};

//======================= LOGIN =======================
// POST /auth/login
const login = async (req, res) => {
    try {
        const { email, password } = req.body;

        if (!email || !password) {
            return res.status(400).json({ message: 'Email dan password wajib diisi' });
        }

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

        return res.status(200).json({
            message: 'Login berhasil',
            accessToken,
            refreshToken,
            data: { userId: user.id, username: user.username, email: user.email }
        });
    } catch (error) {
        console.error('login error:', error);
        return res.status(500).json({ message: 'Internal server error', error: error.message });
    }
};

//========================= LOGOUT =======================
// POST /auth/logout
const logout = async (req, res) => {
    try {
        const { refreshToken } = req.body;

        if (!refreshToken) {
            return res.status(400).json({ message: 'Refresh token wajib diisi' });
        }

        await pool.query('DELETE FROM refresh_tokens WHERE token = ?', [refreshToken]);

        return res.status(200).json({ message: 'Logout berhasil' });
    } catch (error) {
        console.error('logout error:', error);
        return res.status(500).json({ message: 'Internal server error', error: error.message });
    }
};

//==================== FORGOT PASSWORD ===================
// POST /auth/forgot-password
const forgotPassword = async (req, res) => {
    try {
        const { email } = req.body;

        if (!email) {
            return res.status(400).json({ message: 'Email wajib diisi' });
        }

        const [user] = await pool.query('SELECT id, username FROM users WHERE email = ?', [email]);
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

        await sendOTPEmail(
            email,
            otp,
            'Reset Password',
            `Halo ${user[0].username}, berikut adalah kode OTP untuk mereset password Anda.`
        );

        return res.status(200).json({ message: 'OTP berhasil dikirim ke email Anda.' });
    } catch (error) {
        console.error('forgotPassword error:', error);
        return res.status(500).json({ message: 'Internal server error', error: error.message });
    }
};

//========================= RESET PASSWORD =======================
// POST /auth/reset-password
const resetPassword = async (req, res) => {
    try {
        const { email, otp, newPassword } = req.body;

        if (!email || !otp || !newPassword) {
            return res.status(400).json({ message: 'Semua field wajib diisi' });
        }

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
        if (newPassword.length < 6) {
            return res.status(400).json({ message: 'Password baru minimal 6 karakter' });
        }

        const hashedPassword = await bcrypt.hash(newPassword, 10);
        await pool.query('UPDATE users SET password = ? WHERE email = ?', [hashedPassword, email]);
        await pool.query('DELETE FROM reset_tokens WHERE email = ?', [email]);

        return res.status(200).json({ message: 'Password berhasil diubah' });
    } catch (error) {
        console.error('resetPassword error:', error);
        return res.status(500).json({ message: 'Internal server error', error: error.message });
    }
};

//========================= REFRESH TOKEN =======================
// POST /auth/refresh-token
const refreshAccessToken = async (req, res) => {
    try {
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
            { id: user[0].id, username: user[0].username, email: user[0].email, role: user[0].role },
            SECRET_KEY,
            { expiresIn: '15m' }
        );

        return res.status(200).json({
            message: 'Access token berhasil diperbarui',
            accessToken: newAccessToken
        });
    } catch (error) {
        console.error('refreshAccessToken error:', error);
        return res.status(500).json({ message: 'Internal server error', error: error.message });
    }
};

module.exports = { register, verifyEmail, resendOTP, login, forgotPassword, resetPassword, refreshAccessToken, logout };