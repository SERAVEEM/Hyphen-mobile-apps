const pool = require('@/config/db');

// ========================= TAMBAH KE CART =========================
// POST /cart/addcart
const addToCart = async (req, res) => {
    try {
        const { productId, size, quantity } = req.body;
        const userId = req.user.id;

        if (!productId || !size || !quantity) {
            return res.status(400).json({ message: 'productId, size, dan quantity wajib diisi' });
        }
        if (quantity <= 0) {
            return res.status(400).json({ message: 'Quantity harus lebih dari 0' });
        }

        const [product] = await pool.query('SELECT * FROM products WHERE id = ?', [productId]);
        if (product.length === 0) {
            return res.status(404).json({ message: 'Product tidak ditemukan' });
        }

        const [selectedSize] = await pool.query(
            'SELECT * FROM product_sizes WHERE productId = ? AND size = ?',
            [productId, size.toUpperCase()]
        );
        if (selectedSize.length === 0) {
            return res.status(400).json({ message: 'Ukuran tidak tersedia' });
        }

        const stock = selectedSize[0].stock;

        const [existing] = await pool.query(
            'SELECT * FROM cart_items WHERE userId = ? AND productId = ? AND size = ?',
            [userId, productId, size.toUpperCase()]
        );

        if (existing.length > 0) {
            const newQty = existing[0].quantity + Number(quantity);
            if (newQty > stock) {
                return res.status(400).json({ message: `Stok tidak cukup. Tersedia: ${stock}` });
            }
            await pool.query(
                'UPDATE cart_items SET quantity = ?, totalPrice = ? WHERE id = ?',
                [newQty, product[0].price * newQty, existing[0].id]
            );
        } else {
            if (quantity > stock) {
                return res.status(400).json({ message: `Stok tidak cukup. Tersedia: ${stock}` });
            }
            await pool.query(
                'INSERT INTO cart_items (userId, productId, productName, size, price, quantity, totalPrice) VALUES (?, ?, ?, ?, ?, ?, ?)',
                [userId, productId, product[0].name, size.toUpperCase(), product[0].price, quantity, product[0].price * quantity]
            );
        }

        const [cart] = await pool.query('SELECT * FROM cart_items WHERE userId = ?', [userId]);

        return res.status(200).json({ message: 'Product berhasil ditambahkan ke cart', data: cart });
    } catch (error) {
        console.error('addToCart error:', error);
        return res.status(500).json({ message: 'Internal server error', error: error.message });
    }
};

// ========================= LIHAT CART =========================
// GET /cart/getcart
const getCart = async (req, res) => {
    try {
        const userId = req.user.id;

        const [cart] = await pool.query('SELECT * FROM cart_items WHERE userId = ?', [userId]);
        const grandTotal = cart.reduce((sum, item) => sum + Number(item.totalPrice), 0);

        return res.status(200).json({
            message: 'Berhasil ambil cart',
            total: cart.length,
            grandTotal,
            data: cart
        });
    } catch (error) {
        console.error('getCart error:', error);
        return res.status(500).json({ message: 'Internal server error', error: error.message });
    }
};

// ========================= HAPUS ITEM DARI CART =========================
// DELETE /cart/removefromcart/:productId/:size
const removeFromCart = async (req, res) => {
    try {
        const { productId, size } = req.params;
        const userId = req.user.id;

        const [item] = await pool.query(
            'SELECT id FROM cart_items WHERE userId = ? AND productId = ? AND size = ?',
            [userId, productId, size.toUpperCase()]
        );
        if (item.length === 0) {
            return res.status(404).json({ message: 'Item tidak ditemukan di cart' });
        }

        await pool.query('DELETE FROM cart_items WHERE id = ?', [item[0].id]);

        const [cart] = await pool.query('SELECT * FROM cart_items WHERE userId = ?', [userId]);

        return res.status(200).json({ message: 'Item berhasil dihapus dari cart', data: cart });
    } catch (error) {
        console.error('removeFromCart error:', error);
        return res.status(500).json({ message: 'Internal server error', error: error.message });
    }
};

// ========================= KOSONGKAN CART =========================
// DELETE /cart/clearcart
const clearCart = async (req, res) => {
    try {
        const userId = req.user.id;

        await pool.query('DELETE FROM cart_items WHERE userId = ?', [userId]);

        return res.status(200).json({ message: 'Cart berhasil dikosongkan' });
    } catch (error) {
        console.error('clearCart error:', error);
        return res.status(500).json({ message: 'Internal server error', error: error.message });
    }
};

module.exports = { addToCart, getCart, removeFromCart, clearCart };