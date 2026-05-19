const nodemailer = require('nodemailer');

// ─── Nodemailer transporter ─────────────────────────────────────────────────
const transporter = nodemailer.createTransport({
    host: process.env.SMTP_HOST,
    port: Number(process.env.SMTP_PORT) || 587,
    secure: process.env.SMTP_SECURE === 'true',
    auth: {
        user: process.env.SMTP_USER,
        pass: process.env.SMTP_PASS,
    },
});

//======================= FUNCTION =========================
function idGenerator() {
    const prefix = 'user';
    const digitTarget = 4;
    const randomNumber = Math.floor(Math.random() * Math.pow(10, digitTarget))
        .toString()
        .padStart(digitTarget, '0');
    return `${prefix}${randomNumber}`;
}

function generateOTP() {
    return Math.floor(100000 + Math.random() * 900000).toString();
}

function validateUser(username, email, password) {
    const usernameRegex = /^(?=.*\d)[A-Za-z\d]{8,}$/;
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    const passwordRegex = /^(?=.*[A-Za-z])(?=.*\d)[A-Za-z\d]{6,}$/;

    if (username.length < 8) return 'Username minimal 8 karakter';
    if (!usernameRegex.test(username)) return 'Username harus mengandung minimal 1 angka';
    if (!emailRegex.test(email)) return 'Email tidak valid';
    if (password.length < 6) return 'Password minimal 6 karakter';
    if (!passwordRegex.test(password)) return 'Password harus mengandung minimal 1 huruf dan 1 angka';
    return null;
}

const sendOTPEmail = async (to, otp, subject, intro) => {
    await transporter.sendMail({
        from: `"${process.env.SMTP_FROM_NAME || 'No Reply'}" <${process.env.SMTP_USER}>`,
        to,
        subject,
        text: `${intro}\n\nKode OTP Anda: ${otp}\n\nKode ini berlaku selama 10 menit. Jangan bagikan kode ini ke siapapun.`,
    });
};

module.exports = { idGenerator, validateUser, generateOTP, sendOTPEmail };