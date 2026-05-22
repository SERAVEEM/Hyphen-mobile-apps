const pool = require('@/config/db');

// ========================= TAMBAH WISHLIST =========================
// POST /wishlist/add
const addWishlist = async (req, res) => {
    try {
        const { productId } = req.body;
        const userId = req.user.id;

        if (!productId) {
            return res.status(400).json({ message: 'productId wajib diisi' });
        }

        const [product] = await pool.query('SELECT id FROM products WHERE id = ?', [productId]);
        if (product.length === 0) {
            return res.status(404).json({ message: 'Product tidak ditemukan' });
        }

        const [existing] = await pool.query(
            'SELECT id FROM wishlist WHERE userId = ? AND productId = ?',
            [userId, productId]
        );
        if (existing.length > 0) {
            return res.status(400).json({ message: 'Product sudah ada di wishlist' });
        }

        await pool.query(
            'INSERT INTO wishlist (userId, productId) VALUES (?, ?)',
            [userId, productId]
        );

        return res.status(200).json({ message: 'Product berhasil ditambahkan ke wishlist' });
    } catch (error) {
        console.error('addWishlist error:', error);
        return res.status(500).json({ message: 'Internal server error', error: error.message });
    }
};

// ========================= LIHAT WISHLIST =========================
// GET /wishlist/getwishlist
const getWishlist = async (req, res) => {
    try {
        const userId = req.user.id;

        const [wishlistProducts] = await pool.query(
            `SELECT p.*, ps.size, ps.stock
             FROM wishlist w
             JOIN products p ON w.productId = p.id
             LEFT JOIN product_sizes ps ON p.id = ps.productId
             WHERE w.userId = ?`,
            [userId]
        );

        // Group sizes per product
        const productMap = {};
        for (const row of wishlistProducts) {
            if (!productMap[row.id]) {
                const { size, stock, ...productData } = row;
                productMap[row.id] = { ...productData, sizes: [] };
            }
            if (row.size) {
                productMap[row.id].sizes.push({ size: row.size, stock: row.stock });
            }
        }

        const result = Object.values(productMap);

        return res.status(200).json({
            message: 'Berhasil ambil wishlist',
            total: result.length,
            data: result
        });
    } catch (error) {
        console.error('getWishlist error:', error);
        return res.status(500).json({ message: 'Internal server error', error: error.message });
    }
};

// ========================= HAPUS WISHLIST =========================
// DELETE /wishlist/remove/:productId
const removeWishlist = async (req, res) => {
    try {
        const { productId } = req.params;
        const userId = req.user.id;

        const [existing] = await pool.query(
            'SELECT id FROM wishlist WHERE userId = ? AND productId = ?',
            [userId, productId]
        );
        if (existing.length === 0) {
            return res.status(404).json({ message: 'Product tidak ada di wishlist' });
        }

        await pool.query('DELETE FROM wishlist WHERE userId = ? AND productId = ?', [userId, productId]);

        return res.status(200).json({ message: 'Product berhasil dihapus dari wishlist' });
    } catch (error) {
        console.error('removeWishlist error:', error);
        return res.status(500).json({ message: 'Internal server error', error: error.message });
    }
};

module.exports = { addWishlist, getWishlist, removeWishlist };