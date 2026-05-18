const { users } = require('@/data/users.data');
const { products } = require('@/data/product.data');

// ========================= TAMBAH KE CART =========================
const addToCart = (req, res) => {
    const { productId, size, quantity } = req.body;
    const user = users.find((u) => u.id === req.user.id);

    if (!user) {
        return res.status(404).json({ message: 'User tidak ditemukan' });
    }
    if (!productId || !size || !quantity) {
        return res.status(400).json({ message: 'productId, size, dan quantity wajib diisi' });
    }

    const product = products.find((p) => p.id === productId);
    if (!product) {
        return res.status(404).json({ message: 'Product tidak ditemukan' });
    }

    // cek size tersedia
    const selectedSize = product.sizes.find(
        (s) => s.size.toLowerCase() === size.toLowerCase()
    );
    if (!selectedSize) {
        return res.status(400).json({ message: 'Ukuran tidak tersedia' });
    }

    if (quantity <= 0) {
        return res.status(400).json({ message: 'Quantity harus lebih dari 0' });
    }
    if (quantity > selectedSize.stock) {
        return res.status(400).json({ message: `Stok tidak cukup. Tersedia: ${selectedSize.stock}` });
    }

    // cek apakah produk + size sudah ada di cart
    const existingItem = user.cart.find(
        (item) => item.productId === productId && item.size === size.toUpperCase()
    );

    if (existingItem) {
        // kalau sudah ada, tambah quantity
        const newQty = existingItem.quantity + quantity;
        if (newQty > selectedSize.stock) {
            return res.status(400).json({ message: `Stok tidak cukup. Tersedia: ${selectedSize.stock}` });
        }
        existingItem.quantity = newQty;
        existingItem.totalPrice = product.price * newQty;
    } else {
        // kalau belum ada, tambah item baru
        user.cart.push({
            productId,
            productName: product.name,
            size: size.toUpperCase(),
            price: product.price,
            quantity,
            totalPrice: product.price * quantity
        });
    }

    return res.status(200).json({
        message: 'Product berhasil ditambahkan ke cart',
        data: user.cart
    });
};


// ========================= LIHAT CART =========================
const getCart = (req, res) => {
    const user = users.find((u) => u.id === req.user.id);
    if (!user) {
        return res.status(404).json({ message: 'User tidak ditemukan' });
    }

    const grandTotal = user.cart.reduce((sum, item) => sum + item.totalPrice, 0);

    return res.status(200).json({
        message: 'Berhasil ambil cart',
        total: user.cart.length,
        grandTotal,
        data: user.cart
    });
};

// ========================= HAPUS ITEM DARI CART =========================
const removeFromCart = (req, res) => {
    const { productId, size } = req.body;
    const user = users.find((u) => u.id === req.user.id);

    if (!user) {
        return res.status(404).json({ message: 'User tidak ditemukan' });
    }
    if (!productId || !size) {
        return res.status(400).json({ message: 'productId dan size wajib diisi' });
    }

    const itemIndex = user.cart.findIndex(
        (item) => item.productId === productId && item.size === size.toUpperCase()
    );
    if (itemIndex === -1) {
        return res.status(404).json({ message: 'Item tidak ditemukan di cart' });
    }

    user.cart.splice(itemIndex, 1);

    return res.status(200).json({
        message: 'Item berhasil dihapus dari cart',
        data: user.cart
    });
};


// ========================= KOSONGKAN CART =========================
const clearCart = (req, res) => {
    const user = users.find((u) => u.id === req.user.id);
    if (!user) {
        return res.status(404).json({ message: 'User tidak ditemukan' });
    }

    user.cart = [];

    return res.status(200).json({ message: 'Cart berhasil dikosongkan' });
};


module.exports = { addToCart, getCart, removeFromCart, clearCart }; 