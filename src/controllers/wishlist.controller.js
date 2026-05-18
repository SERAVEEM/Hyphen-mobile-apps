const { users } = require('@/data/users.data');
const { products } = require('@/data/product.data');

// ========================= TAMBAH WISHLIST =========================
// POST /wishlist/add
const addWishlist = (req, res) => {
    const { productId } = req.body;
    const user = users.find((u) => u.id === req.user.id);

    if (!user) {
        return res.status(404).json({ message: 'User tidak ditemukan' });
    }

    const product = products.find(p => p.id === (productId));
    if (!product) {
        return res.status(404).json({ message: 'Product tidak ditemukan' });
    }

    if (user.wishlist.includes(productId)) {
        return res.status(400).json({ message: 'Product sudah ada di wishlist' });
    }

    user.wishlist.push(productId);
    res.status(200).json({ message: 'Product berhasil ditambahkan ke wishlist' });
};


// ========================= LIHAT WISHLIST =========================
// GET /wishlist/getwishlist
const getWishlist = (req, res) => {
    const user = users.find((u) => u.id === req.user.id);
    if (!user) {
        return res.status(404).json({ message: 'User tidak ditemukan' });
    }

    const wishlistProducts = user.wishlist.map(id =>
        products.find(p => p.id === id)
    ).filter(Boolean);

    return res.status(200).json({
        message: 'Berhasil ambil wishlist',
        total: wishlistProducts.length,
        data: wishlistProducts
    });
};
// ===================== HAPUS WISHLIST =========================
// DELETE /wishlist/remove/:productId
const removeWishlist = (req, res) => {
    const { productId } = req.params;
    const user = users.find((u) => u.id === req.user.id);

    if (!user) {
        return res.status(404).json({ message: 'User tidak ditemukan' });
    }

    if (!user.wishlist.includes(productId)) {
        return res.status(404).json({ message: 'Product tidak ada di wishlist' });
    }

    user.wishlist = user.wishlist.filter((id) => id !== productId);

    return res.status(200).json({ message: 'Product berhasil dihapus dari wishlist' });
};

module.exports = { addWishlist, getWishlist, removeWishlist };