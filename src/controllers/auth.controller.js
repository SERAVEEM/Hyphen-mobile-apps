const { users, initAdmin } = require('@/data/users.data');
const { orders } = require('@/data/order.data');
const { idGenerator, validateUser, generateOTP } = require('@/helpers/auth.helpers');

let id = 1;
let emailVerifications = [];
let resetTokens = [];
let refreshTokens = [];
const bcrypt = require('bcrypt');
const { addresses } = require('../data/address.data');


//========================= REGISTER =======================
//POST /auth/register
const register = async (req, res) => {
    const { username, email, password } = req.body;

    if (!username || !email || !password) {
        return res.status(400).json({
            message: 'Semua field wajib diisi'
        });
    }
    const userTerdaftar = users.find(user => user.email === email);

    if (userTerdaftar) {
        return res.status(400).json({
            message: 'Email sudah terdaftar'
        });
    }

    const error = validateUser(username, email, password);
    if (error) {
        return res.status(400).json({
            message: error
        });
    }
    const hashedPassword = await bcrypt.hash(password, 10);

    const newUser = {
        id: idGenerator(),
        username,
        email,
        password: hashedPassword,
        role: 'user',
        isVerified: false,
        wishlist: [],
        cart: [],
        orders: [],
        payments: [],
        addresses: [],
    };

    users.push(newUser);

    const otp = generateOTP();
    const otpExpiry = Date.now() + 10 * 60 * 1000;

    emailVerifications.push({ email, otp, otpExpiry });
    console.log(`OTP register ${email}: ${otp}`);

    res.status(201).json({
        message: 'Register berhasil',
        data: newUser
    });
};

//========================= VERIFY EMAIL =======================
// POST /auth/verify-email
const verifyEmail = (req, res) => {
    const { email, otp } = req.body;

    const data = emailVerifications.find(
        v => v.email === email && v.otp === otp
    );

    if (!data) {
        return res.status(400).json({
            message: 'OTP salah'
        });
    }

    if (Date.now() > data.otpExpiry) {
        return res.status(400).json({
            message: 'OTP expired'
        });
    }

    const user = users.find(u => u.email === email);
    if (!user) {
        return res.status(400).json({
            message: 'User tidak ditemukan'
        });
    }

    user.isVerified = true;
    emailVerifications = emailVerifications.filter(v => v.email !== email);

    res.json({
        message: 'Email berhasil diverifikasi'
    });
};

// ========================= RESEND OTP =========================
// POST /auth/resend-otp
const resendOTP = (req, res) => {
    const { email } = req.body;
    const user = users.find((u) => u.email === email);

    if (!user) {
        return res.status(400).json({ message: 'Email tidak ditemukan' });
    }

    if (user.isVerified) {
        return res.status(400).json({ message: 'Email sudah diverifikasi' });
    }

    emailVerifications = emailVerifications.filter((v) => v.email !== email);

    const otp = generateOTP();
    const otpExpiry = Date.now() + 10 * 60 * 1000;
    emailVerifications.push({ email, otp, otpExpiry });

    console.log(`OTP baru untuk ${email}: ${otp}`);

    res.status(200).json({
        message: 'OTP berhasil dikirim',
        data: { email, otp },
    });
};


//======================= LOGIN =======================
// POST /auth/login
const login = async (req, res) => {
    const { email, password } = req.body;
    const jwt = require('jsonwebtoken');
    const SECRET_KEY = process.env.SECRET_KEY;
    const REFRESH_SECRET_KEY = process.env.REFRESH_SECRET_KEY;
    const user = users.find(user => user.email === email);

    if (!user) {
        return res.status(400).json({
            message: 'Email tidak ditemukan'
        });
    }
    if (!user.isVerified) {
        return res.status(400).json({
            message: 'Email belum diverifikasi'
        });
    }


    const isMatch = await bcrypt.compare(password, user.password);

    if (!isMatch) {
        return res.status(400).json({
            message: 'Password salah'
        });
    }
    const payload = {
        id: user.id,
        username: user.username,
        email: user.email,
        role: user.role === 'admin' ? 'admin' : 'user'
    };

    const accessToken = jwt.sign(payload, SECRET_KEY, { expiresIn: '15m' });

    const refreshToken = jwt.sign(
        { id: user.id },
        REFRESH_SECRET_KEY,
        { expiresIn: '7d' },
    );

    refreshTokens = refreshTokens.filter(rt => rt.userId !== user.id);
    refreshTokens.push({
        userId: user.id,
        token: refreshToken,
        expiry: Date.now() + 7 * 24 * 60 * 60 * 1000
    });


    res.status(200).json({
        message: 'Login berhasil',
        accessToken,
        refreshToken,
        data: {
            id: user.id,
            username: user.username,
            email: user.email
        }
    });
};



//========================= LOGOUT =======================
// POST /auth/logout
const logout = (req, res) => {
    const { refreshToken } = req.body;

    const token = refreshTokens.find(rt => rt.token === refreshToken);
    if (token) {
        refreshTokens = refreshTokens.filter(rt => rt.token !== refreshToken);
    }

    res.status(200).json({
        message: 'Logout berhasil'
    });
};

//==================== FORGOT PASSWORD ===================
// POST /auth/forgot-password
const forgotPassword = (req, res) => {
    const { email } = req.body;
    const user = users.find(user => user.email === email);
    if (!user) {
        return res.status(400).json({
            message: 'Email tidak ditemukan'
        });
    }

    const otp = generateOTP();
    const otpExpiry = Date.now() + 10 * 60 * 1000;

    resetTokens = resetTokens.filter(token => token.email !== email);
    resetTokens.push({ email, otp, otpExpiry });
    console.log(`OTP untuk ${email}: ${otp} (berlaku sampai ${new Date(otpExpiry).toLocaleTimeString()})`);
    res.status(200).json({
        message: 'OTP berhasil dikirim',
        data: {
            email,
            otp
        }
    });

};


//=========================RESET PASSWORD=======================
// POST /auth/reset-password
const resetPassword = async (req, res) => {
    const { email, otp, newPassword } = req.body;
    const tokenData = resetTokens.find(token => token.email === email && token.otp === otp);

    if (!tokenData) {
        return res.status(400).json({
            message: 'OTP tidak valid'
        });
    }
    if (Date.now() > tokenData.otpExpiry) {
        return res.status(400).json({
            message: 'OTP telah expired'
        });
    }

    const user = users.find(user => user.email === email);
    if (!user) {
        return res.status(400).json({
            message: 'Email tidak ditemukan'
        });
    }

    const hashedPassword = await bcrypt.hash(newPassword, 10);
    user.password = hashedPassword;

    resetTokens = resetTokens.filter(token => token.email !== email);
    res.status(200).json({
        message: 'Password berhasil diubah',
        data: user
    });
};

//========================= REFRESH TOKEN =======================
// POST /auth/refresh-token
const refreshAccessToken = (req, res) => {
    const { refreshToken } = req.body;
    const jwt = require('jsonwebtoken');
    const SECRET_KEY = process.env.SECRET_KEY;
    const REFRESH_SECRET_KEY = process.env.REFRESH_SECRET_KEY;

    if (!refreshToken) {
        return res.status(400).json({ message: 'Refresh token tidak ada' });
    }

    const stored = refreshTokens.find(rt => rt.token === refreshToken);
    if (!stored) {
        return res.status(403).json({ message: 'Refresh token tidak valid atau sudah logout' });
    }

    if (Date.now() > stored.expiry) {
        refreshTokens = refreshTokens.filter(rt => rt.token !== refreshToken);
        return res.status(403).json({ message: 'Refresh token sudah expired, silakan login ulang' });
    }

    let decoded;
    try {
        decoded = jwt.verify(refreshToken, REFRESH_SECRET_KEY);
    } catch (err) {
        refreshTokens = refreshTokens.filter(rt => rt.token !== refreshToken);
        return res.status(403).json({ message: 'Refresh token tidak valid' });
    }

    const user = users.find(u => u.id === decoded.id);
    if (!user) {
        return res.status(403).json({ message: 'User tidak ditemukan' });
    }

    const newAccessToken = jwt.sign(
        { id: user.id, username: user.username, email: user.email, role: user.role === 'admin' ? 'admin' : 'user' },
        SECRET_KEY,
        { expiresIn: '15m' }
    );

    res.status(200).json({
        message: 'Access token berhasil diperbarui',
        accessToken: newAccessToken
    });
};



module.exports = { register, verifyEmail, resendOTP, login, forgotPassword, resetPassword, refreshAccessToken, logout };