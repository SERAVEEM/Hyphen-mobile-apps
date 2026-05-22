const bcrypt = require('bcrypt');
const pool = require('@/config/db');
const cloudinary = require('@/config/cloudinary');

// ========================= GET PROFILE =========================
// GET /user/profile
const getProfile = async (req, res) => {
    try {
        const [rows] = await pool.query(
            `SELECT u.id, u.username, u.email, u.role, u.isVerified, u.createdAt,
                    p.fullname, p.phone, p.dateOfBirth, p.location, p.photoUrl,
                    CASE WHEN p.id IS NOT NULL THEN true ELSE false END AS hasProfile
             FROM users u
             LEFT JOIN user_profiles p ON p.userId = u.id
             WHERE u.id = ?`,
            [req.user.id]
        );
        if (rows.length === 0) {
            return res.status(404).json({ message: 'User tidak ditemukan' });
        }

        return res.status(200).json({ message: 'Berhasil ambil profile', data: rows[0] });
    } catch (error) {
        console.error('getProfile error:', error);
        return res.status(500).json({ message: 'Internal server error' });
    }
};

// ========================= CREATE PROFILE =========================
// POST /user/profile
const createProfile = async (req, res) => {
    try {
        const { fullname, phone, dateOfBirth, location } = req.body;
        const userId = req.user.id;

        if (!fullname) {
            return res.status(400).json({ message: 'Nama lengkap wajib diisi' });
        }
        if (phone && !/^[0-9]{10,13}$/.test(phone)) {
            return res.status(400).json({ message: 'Format nomor telepon tidak valid' });
        }
        if (dateOfBirth && isNaN(new Date(dateOfBirth))) {
            return res.status(400).json({ message: 'Format tanggal tidak valid' });
        }

        const [existing] = await pool.query(
            'SELECT id FROM user_profiles WHERE userId = ?',
            [userId]
        );
        if (existing.length > 0) {
            return res.status(400).json({ message: 'Profil sudah ada, gunakan endpoint update' });
        }

        await pool.query(
            'INSERT INTO user_profiles (userId, fullname, phone, dateOfBirth, location) VALUES (?, ?, ?, ?, ?)',
            [userId, fullname, phone || null, dateOfBirth || null, location || null]
        );

        return res.status(201).json({
            message: 'Profil berhasil dibuat',
            data: { fullname, phone, dateOfBirth, location }
        });
    } catch (error) {
        console.error('createProfile error:', error);
        return res.status(500).json({ message: 'Internal server error' });
    }
};

// ========================= UPDATE PROFILE =========================
// PUT /user/profile
// Update sekaligus: user_profiles (fullname, phone, dateOfBirth, location) + users (username, email)
const updateProfile = async (req, res) => {
    try {
        const { fullname, phone, dateOfBirth, location, username, email } = req.body;
        const userId = req.user.id;

        if (phone && !/^[0-9]{10,13}$/.test(phone)) {
            return res.status(400).json({ message: 'Format nomor telepon tidak valid' });
        }
        if (dateOfBirth && isNaN(new Date(dateOfBirth))) {
            return res.status(400).json({ message: 'Format tanggal tidak valid' });
        }
        if (email && !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email)) {
            return res.status(400).json({ message: 'Format email tidak valid' });
        }

        // Cek profil ada
        const [existing] = await pool.query(
            'SELECT id FROM user_profiles WHERE userId = ?',
            [userId]
        );
        if (existing.length === 0) {
            return res.status(404).json({ message: 'Profil belum dibuat, gunakan endpoint create' });
        }

        // Cek email tidak dipakai user lain
        if (email) {
            const [emailTaken] = await pool.query(
                'SELECT id FROM users WHERE email = ? AND id != ?',
                [email.trim(), userId]
            );
            if (emailTaken.length > 0) {
                return res.status(400).json({ message: 'Email sudah digunakan user lain' });
            }
        }

        // Update tabel users
        await pool.query(
            'UPDATE users SET username = COALESCE(?, username), email = COALESCE(?, email) WHERE id = ?',
            [username || null, email?.trim() || null, userId]
        );

        // Update tabel user_profiles
        await pool.query(
            `UPDATE user_profiles SET
                fullname    = COALESCE(?, fullname),
                phone       = COALESCE(?, phone),
                dateOfBirth = COALESCE(?, dateOfBirth),
                location    = COALESCE(?, location)
             WHERE userId = ?`,
            [fullname || null, phone || null, dateOfBirth || null, location || null, userId]
        );

        // Ambil data terbaru
        const [updated] = await pool.query(
            `SELECT u.id, u.username, u.email, u.role, u.isVerified, u.createdAt,
                    p.fullname, p.phone, p.dateOfBirth, p.location, p.photoUrl
             FROM users u
             LEFT JOIN user_profiles p ON p.userId = u.id
             WHERE u.id = ?`,
            [userId]
        );

        return res.status(200).json({ message: 'Profil berhasil diupdate', data: updated[0] });
    } catch (error) {
        console.error('updateProfile error:', error);
        return res.status(500).json({ message: 'Internal server error' });
    }
};

// ========================= UPLOAD PHOTO PROFILE =========================
// PUT /user/profile/photo
const updatePhotoProfile = async (req, res) => {
    try {
        const userId = req.user.id;

        if (!req.file) {
            return res.status(400).json({ message: 'Foto wajib diupload' });
        }

        const [existing] = await pool.query(
            'SELECT id, photoUrl FROM user_profiles WHERE userId = ?',
            [userId]
        );
        if (existing.length === 0) {
            return res.status(404).json({ message: 'Profil belum dibuat' });
        }

        // Hapus foto lama di Cloudinary kalau ada
        if (existing[0].photoUrl) {
            const urlParts = existing[0].photoUrl.split('/');
            const publicId = `profile_photos/${urlParts[urlParts.length - 1].split('.')[0]}`;
            await cloudinary.uploader.destroy(publicId);
        }

        // Hapus foto lama di Cloudinary kalau ada
        if (existing[0].photoUrl) {
            const urlParts = existing[0].photoUrl.split('/');
            const publicId = `profile_photos/${urlParts[urlParts.length - 1].split('.')[0]}`;
            await cloudinary.uploader.destroy(publicId);
        }

        // Upload buffer ke Cloudinary (memoryStorage)
        const photoUrl = await new Promise((resolve, reject) => {
            const stream = cloudinary.uploader.upload_stream(
                { folder: 'profile_photos', transformation: [{ width: 500, height: 500, crop: 'fill' }] },
                (error, result) => {
                    if (error) reject(error);
                    else resolve(result.secure_url);
                }
            );
            stream.end(req.file.buffer);
        });

        await pool.query(
            'UPDATE user_profiles SET photoUrl = ? WHERE userId = ?',
            [photoUrl, userId]
        );

        return res.status(200).json({ message: 'Foto profil berhasil diupdate', data: { photoUrl } });
    } catch (error) {
        console.error('updatePhotoProfile error:', error);
        return res.status(500).json({ message: 'Internal server error' });
    }
};

// ========================= CHANGE PASSWORD =========================
// PUT /user/change-password
const changePassword = async (req, res) => {
    try {
        const { oldPassword, newPassword } = req.body;

        if (!oldPassword || !newPassword) {
            return res.status(400).json({ message: 'Password lama dan baru wajib diisi' });
        }
        if (newPassword.length < 6) {
            return res.status(400).json({ message: 'Password baru harus minimal 6 karakter' });
        }
        if (oldPassword === newPassword) {
            return res.status(400).json({ message: 'Password baru tidak boleh sama dengan password lama' });
        }

        const [rows] = await pool.query('SELECT password FROM users WHERE id = ?', [req.user.id]);
        if (rows.length === 0) {
            return res.status(404).json({ message: 'User tidak ditemukan' });
        }

        const isMatch = await bcrypt.compare(oldPassword, rows[0].password);
        if (!isMatch) {
            return res.status(400).json({ message: 'Password lama salah' });
        }

        const hashedPassword = await bcrypt.hash(newPassword, 10);
        await pool.query('UPDATE users SET password = ? WHERE id = ?', [hashedPassword, req.user.id]);

        return res.status(200).json({ message: 'Password berhasil diubah' });
    } catch (error) {
        console.error('changePassword error:', error);
        return res.status(500).json({ message: 'Internal server error' });
    }
};

// ========================= DELETE USER =========================
// DELETE /user/delete
const deleteUser = async (req, res) => {
    try {
        const { password } = req.body;

        if (!password) {
            return res.status(400).json({ message: 'Password wajib diisi untuk menghapus akun' });
        }

        const [user] = await pool.query('SELECT id, password FROM users WHERE id = ?', [req.user.id]);
        if (user.length === 0) {
            return res.status(404).json({ message: 'User tidak ditemukan' });
        }

        const isMatch = await bcrypt.compare(password, user[0].password);
        if (!isMatch) {
            return res.status(400).json({ message: 'Password salah' });
        }

        await pool.query('DELETE FROM users WHERE id = ?', [req.user.id]);

        return res.status(200).json({ message: 'Akun berhasil dihapus' });
    } catch (error) {
        console.error('deleteUser error:', error);
        return res.status(500).json({ message: 'Internal server error' });
    }
};

module.exports = { getProfile, createProfile, updateProfile, updatePhotoProfile, changePassword, deleteUser };