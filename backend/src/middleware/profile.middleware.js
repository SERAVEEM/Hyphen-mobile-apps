const pool = require('@/config/db');

// Middleware untuk memastikan user sudah mengisi profil
// Gunakan di route yang membutuhkan data profil lengkap (checkout, dll)
const requireProfile = async (req, res, next) => {
    try {
        const [profile] = await pool.query(
            'SELECT id FROM user_profiles WHERE userId = ?',
            [req.user.id]
        );

        if (profile.length === 0) {
            return res.status(403).json({
                message: 'Lengkapi profil Anda terlebih dahulu',
                redirectTo: '/profile/create'
            });
        }

        next();
    } catch (error) {
        console.error('requireProfile error:', error);
        return res.status(500).json({ message: 'Internal server error' });
    }
};

module.exports = { requireProfile };