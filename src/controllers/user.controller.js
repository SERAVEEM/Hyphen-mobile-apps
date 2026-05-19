const bcrypt = require('bcrypt');
const pool = require('@/config/db');

// ========================= GET PROFILE =========================
// GET /user/profile
const getProfile = async (req, res) => {
    try {
        const [rows] = await pool.query(
            'SELECT id, username, email, role, isVerified, createdAt FROM users WHERE id = ?',
            [req.user.id]
        );
        if (rows.length === 0) {
            return res.status(404).json({ message: 'User tidak ditemukan' });
        }

        return res.status(200).json({ message: 'Berhasil ambil profile', data: rows[0] });
    } catch (error) {
        console.error('getProfile error:', error);
        return res.status(500).json({ message: 'Internal server error', error: error.message });
    }
};

// ========================= UPDATE PROFILE =========================
// PUT /user/update
const updateUser = async (req, res) => {
    try {
        const { username, email } = req.body;

        const [user] = await pool.query('SELECT id FROM users WHERE id = ?', [req.user.id]);
        if (user.length === 0) {
            return res.status(404).json({ message: 'User tidak ditemukan' });
        }

        if (email) {
            const [existing] = await pool.query(
                'SELECT id FROM users WHERE email = ? AND id != ?',
                [email.trim(), req.user.id]
            );
            if (existing.length > 0) {
                return res.status(400).json({ message: 'Email sudah digunakan user lain' });
            }
        }

        await pool.query(
            'UPDATE users SET username = COALESCE(?, username), email = COALESCE(?, email) WHERE id = ?',
            [username || null, email?.trim() || null, req.user.id]
        );

        const [updated] = await pool.query(
            'SELECT id, username, email, role, isVerified, createdAt FROM users WHERE id = ?',
            [req.user.id]
        );

        return res.status(200).json({ message: 'User berhasil diupdate', data: updated[0] });
    } catch (error) {
        console.error('updateUser error:', error);
        return res.status(500).json({ message: 'Internal server error', error: error.message });
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

        const [rows] = await pool.query('SELECT password FROM users WHERE id = ?', [req.user.id]);
        if (rows.length === 0) {
            return res.status(404).json({ message: 'User tidak ditemukan' });
        }

        const isMatch = await bcrypt.compare(oldPassword, rows[0].password);
        if (!isMatch) {
            return res.status(400).json({ message: 'Password lama salah' });
        }
        if (newPassword.length < 6) {
            return res.status(400).json({ message: 'Password baru harus minimal 6 karakter' });
        }

        const hashedPassword = await bcrypt.hash(newPassword, 10);
        await pool.query('UPDATE users SET password = ? WHERE id = ?', [hashedPassword, req.user.id]);

        return res.status(200).json({ message: 'Password berhasil diubah' });
    } catch (error) {
        console.error('changePassword error:', error);
        return res.status(500).json({ message: 'Internal server error', error: error.message });
    }
};

// ========================= DELETE USER =========================
// DELETE /user/delete
const deleteUser = async (req, res) => {
    try {
        const [user] = await pool.query('SELECT id FROM users WHERE id = ?', [req.user.id]);
        if (user.length === 0) {
            return res.status(404).json({ message: 'User tidak ditemukan' });
        }

        await pool.query('DELETE FROM users WHERE id = ?', [req.user.id]);

        return res.status(200).json({ message: 'User berhasil dihapus' });
    } catch (error) {
        console.error('deleteUser error:', error);
        return res.status(500).json({ message: 'Internal server error', error: error.message });
    }
};

module.exports = { getProfile, updateUser, changePassword, deleteUser };