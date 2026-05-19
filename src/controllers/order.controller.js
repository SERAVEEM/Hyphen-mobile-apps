const { v4: uuidv4 } = require('uuid');
const pool = require('@/config/db');

// ================== ORDER PRODUCT =====================
// POST /order/create-order
const createOrder = async (req, res) => {
    const userId = req.user.id;
    const { productId, quantity, size } = req.body;

    if (!productId || !quantity || !size) {
        return res.status(400).json({ message: 'field harus diisi' });
    }
    if (quantity <= 0) {
        return res.status(400).json({ message: 'Quantity harus lebih dari 0' });
    }

    const [product] = await pool.query('SELECT * FROM products WHERE id = ?', [productId]);
    if (product.length === 0) {
        return res.status(404).json({ message: 'Product tidak tersedia' });
    }

    const [selectedSize] = await pool.query(
        'SELECT * FROM product_sizes WHERE productId = ? AND size = ?',
        [productId, size.toUpperCase()]
    );
    if (selectedSize.length === 0) {
        return res.status(400).json({ message: 'Ukuran tidak tersedia' });
    }
    if (quantity > selectedSize[0].stock) {
        return res.status(400).json({ message: 'Stok tidak cukup' });
    }

    const id = uuidv4();
    const totalPrice = product[0].price * quantity;

    await pool.query(
        'INSERT INTO orders (id, userId, productId, quantity, size, totalPrice, status) VALUES (?, ?, ?, ?, ?, ?, ?)',
        [id, userId, productId, quantity, size.toUpperCase(), totalPrice, 'pending']
    );

    await pool.query(
        'UPDATE product_sizes SET stock = stock - ? WHERE productId = ? AND size = ?',
        [quantity, productId, size.toUpperCase()]
    );

    const [order] = await pool.query('SELECT * FROM orders WHERE id = ?', [id]);

    res.status(201).json({
        message: 'Order berhasil dibuat',
        data: order[0]
    });
};

// ================== BUAT ORDER DARI CART ==================
// POST /order/create/from-cart
const createOrderFromCart = async (req, res) => {
    const userId = req.user.id;

    const [cart] = await pool.query('SELECT * FROM cart_items WHERE userId = ?', [userId]);
    if (cart.length === 0) {
        return res.status(400).json({ message: 'Cart kosong' });
    }

    const newOrders = [];
    const errors = [];

    for (const item of cart) {
        const [product] = await pool.query('SELECT * FROM products WHERE id = ?', [item.productId]);
        if (product.length === 0) {
            errors.push(`Produk ${item.productId} tidak ditemukan`);
            continue;
        }

        const [selectedSize] = await pool.query(
            'SELECT * FROM product_sizes WHERE productId = ? AND size = ?',
            [item.productId, item.size.toUpperCase()]
        );
        if (selectedSize.length === 0) {
            errors.push(`Ukuran ${item.size} tidak tersedia untuk produk ${product[0].name}`);
            continue;
        }
        if (selectedSize[0].stock < item.quantity) {
            errors.push(`Stok ${product[0].name} ukuran ${item.size} tidak cukup`);
            continue;
        }

        const id = uuidv4();
        const totalPrice = product[0].price * item.quantity;

        await pool.query(
            'INSERT INTO orders (id, userId, productId, quantity, size, totalPrice, status) VALUES (?, ?, ?, ?, ?, ?, ?)',
            [id, userId, item.productId, item.quantity, item.size.toUpperCase(), totalPrice, 'pending']
        );

        await pool.query(
            'UPDATE product_sizes SET stock = stock - ? WHERE productId = ? AND size = ?',
            [item.quantity, item.productId, item.size.toUpperCase()]
        );

        const [order] = await pool.query('SELECT * FROM orders WHERE id = ?', [id]);
        newOrders.push(order[0]);
    }

    // Kosongkan cart setelah order dibuat
    await pool.query('DELETE FROM cart_items WHERE userId = ?', [userId]);

    return res.status(201).json({
        message: `${newOrders.length} order berhasil dibuat`,
        errors: errors.length > 0 ? errors : undefined,
        total: newOrders.length,
        data: newOrders
    });
};

// ========================= GET ALL ORDERS =========================
// GET /order/orders
const getAllOrders = async (req, res) => {
    const [orders] = await pool.query('SELECT * FROM orders ORDER BY orderDate DESC');

    res.status(200).json({
        message: 'Riwayat order',
        total: orders.length,
        data: orders
    });
};

// ========================= GET DETAIL ORDER BY ID =========================
// GET /order/orders/:id
const getOrderById = async (req, res) => {
    const { id } = req.params;

    const [order] = await pool.query('SELECT * FROM orders WHERE id = ?', [id]);
    if (order.length === 0) {
        return res.status(404).json({ message: 'Order tidak ditemukan' });
    }
    if (order[0].userId !== req.user.id && req.user.role !== 'admin') {
        return res.status(403).json({ message: 'Akses tidak diizinkan' });
    }

    res.status(200).json({
        message: 'Berhasil ambil order',
        data: order[0]
    });
};

// ========================= RIWAYAT ORDERAN USER =========================
// GET /order/my-orders
const getMyOrders = async (req, res) => {
    const userId = req.user.id;

    const [orders] = await pool.query(
        'SELECT * FROM orders WHERE userId = ? ORDER BY orderDate DESC',
        [userId]
    );

    if (orders.length === 0) {
        return res.status(404).json({ message: 'Belum ada order' });
    }

    res.status(200).json({
        message: 'Berhasil ambil order',
        data: orders
    });
};

// ========================= CANCEL ORDER ==============================
// POST /order/cancel/:orderId
const cancelOrder = async (req, res) => {
    const { orderId } = req.params;
    const userId = req.user.id;

    const [order] = await pool.query('SELECT * FROM orders WHERE id = ?', [orderId]);
    if (order.length === 0) {
        return res.status(404).json({ message: 'Order tidak ditemukan' });
    }
    if (order[0].userId !== userId) {
        return res.status(403).json({ message: 'Akses tidak diizinkan' });
    }
    if (order[0].status !== 'pending') {
        return res.status(400).json({ message: `Order tidak bisa dibatalkan, status saat ini: ${order[0].status}` });
    }

    // Kembalikan stok produk
    await pool.query(
        'UPDATE product_sizes SET stock = stock + ? WHERE productId = ? AND size = ?',
        [order[0].quantity, order[0].productId, order[0].size]
    );

    await pool.query('UPDATE orders SET status = ? WHERE id = ?', ['cancelled', orderId]);

    const [updated] = await pool.query('SELECT * FROM orders WHERE id = ?', [orderId]);

    return res.status(200).json({
        message: 'Order berhasil dibatalkan',
        data: updated[0]
    });
};

module.exports = { createOrder, createOrderFromCart, getAllOrders, getOrderById, getMyOrders, cancelOrder };