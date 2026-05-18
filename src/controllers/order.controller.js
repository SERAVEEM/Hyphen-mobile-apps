const { users } = require('@/data/users.data');
const { products } = require('@/data/product.data');
const { orders } = require('@/data/order.data');
const { v4: uuidv4 } = require('uuid');
const { shippingData } = require('@/data/shipping.data');



// ================== ORDER PRODUCT =====================
const createOrder = (req, res) => {
    const userId = req.user.id;
    const { productId, quantity, size } = req.body;

    if (!productId || !quantity || !size) {
        return res.status(404).json({ message: 'field harus diisi' });
    }


    const user = users.find((u) => u.id === req.user.id);

    if (!user) {
        return res.status(404).json({ message: 'User tidak ditemukan' });
    }

    const product = products.find((p) => p.id === productId);
    if (!product) {
        return res.status(404).json({ message: 'Product tidak tersedia' });
    }


    const selectedSize = product.sizes.find(
        (s) => s.size.toLowerCase() === size.toLowerCase());

    if (!selectedSize) {
        return res.status(400).json({ message: 'Ukuran tidak tersedia' });
    }
    if (quantity <= 0) {
        return res.status(400).json({ message: 'Quantity harus lebih dari 0' });
    }
    if (quantity > selectedSize.stock) {
        return res.status(400).json({ message: 'Stok tidak cukup' });
    }

    const order = {
        id: uuidv4(),
        userId: user.id,
        productId: productId,
        quantity: quantity,
        totalPrice: product.price * quantity,
        size: size,
        status: 'pending',
        orderDate: new Date()
    };
    selectedSize.stock -= quantity;
    user.orders.push(order);
    orders.push(order);

    res.status(201).json({
        message: 'Order berhasil dibuat',
        data: order
    });
};

// ================== BUAT ORDER DARI CART ==================
const createOrderFromCart = (req, res) => {
    const userId = req.user.id;
    const user   = users.find(u => u.id === userId);
    if (!user) return res.status(404).json({ message: 'User tidak ditemukan' });

    // Cek cart kosong
    if (!user.cart || user.cart.length === 0) {
        return res.status(400).json({ message: 'Cart kosong' });
    }

    const newOrders = [];
    const errors    = [];

    // Buat order untuk setiap item di cart
    for (const item of user.cart) {
        const product = products.find(p => p.id === item.productId);
        if (!product) {
            errors.push(`Produk ${item.productId} tidak ditemukan`);
            continue;
        }

        const selectedSize = product.sizes.find(
            s => s.size.toUpperCase() === item.size.toUpperCase()
        );

        if (!selectedSize) {
            errors.push(`Ukuran ${item.size} tidak tersedia untuk produk ${product.name}`);
            continue;
        }

        if (selectedSize.stock < item.quantity) {
            errors.push(`Stok ${product.name} ukuran ${item.size} tidak cukup`);
            continue;
        }

        // Kurangi stok
        selectedSize.stock -= item.quantity;

        const newOrder = {
            id:         uuidv4(),
            userId,
            productId:  item.productId,
            quantity:   item.quantity,
            size:       item.size.toUpperCase(),
            totalPrice: product.price * item.quantity,
            status:     'pending',
            orderDate:  new Date().toISOString(),
        };

        orders.push(newOrder);
        user.orders.push(newOrder);
        newOrders.push(newOrder);
    }

    // Kosongkan cart setelah order dibuat
    user.cart = [];

    return res.status(201).json({
        message: `${newOrders.length} order berhasil dibuat`,
        errors:  errors.length > 0 ? errors : undefined,
        total:   newOrders.length,
        data:    newOrders,
    });
};

// ========================= GET ALL ORDERS (RIWAYAT ORDER) =========================
const getAllOrders = (req, res) => {

    res.status(200).json({
        message: 'Riwayat order',
        total: orders.length,
        data: orders
    });
};


// ========================= GET DETAIL ORDER BY ID =========================
const getOrderById = (req, res) => {
    const { id } = req.params;
    const userId = req.user.id;
    const order = orders.find((o) => o.id === id);
    if (!order) {
        return res.status(404).json({ message: 'Order tidak ditemukan' });
    }
    if (order.userId !== req.user.id && req.user.role !== 'admin') {
        return res.status(403).json({ message: 'Akses tidak diizinkan' });
    }
    res.status(200).json({
        message: 'Berhasil ambil order',
        data: order
    });
};


// ========================= RIWAYAT ORDERAN USER =========================
const getMyOrders = (req, res) => {
    const userId = req.user.id;
    const user = users.find((u) => u.id === req.user.id);
    if (!user) {
        return res.status(404).json({ message: 'User tidak ditemukan' });
    }

    const myOrders = orders.filter((order) => order.userId === user.id);

    if (myOrders.length === 0) {
        return res.status(404).json({ message: 'Belum ada order' });
    }

    res.status(200).json({
        message: 'Berhasil ambil order',
        data: myOrders
    });
};

// ========================= CANCEL ORDER ==============================
const cancelOrder = (req, res) => {
    const { orderId } = req.body;
    const userId = req.user.id;

    if (!orderId) {
        return res.status(400).json({ message: 'orderId wajib diisi' });
    }

    const user = users.find((u) => u.id === userId);
    if (!user) {
        return res.status(404).json({ message: 'User tidak ditemukan' });
    }

    const order = orders.find((o) => o.id === orderId);
    if (!order) {
        return res.status(404).json({ message: 'Order tidak ditemukan' });
    }
    if (order.userId !== userId) {
        return res.status(403).json({ message: 'Akses tidak diizinkan' });
    }
    if (order.status !== 'pending') {
        return res.status(400).json({ message: `Order tidak bisa dibatalkan, status saat ini: ${order.status}` });
    }

    //Kembalikan stok produk kalau batal
    const { products } = require('@/data/product.data');
    const product = products.find((p) => p.id === order.productId);
    if (product) {
        const selectedSize = product.sizes.find(
            (s) => s.size.toLowerCase() === order.size.toLowerCase()
        );
        if (selectedSize) {
            selectedSize.stock += order.quantity;
        }
    }

    order.status = 'cancelled';

    return res.status(200).json({
        message: 'Order berhasil dibatalkan',
        data: order
    });
};

module.exports = { createOrder, createOrderFromCart, getAllOrders, getOrderById, getMyOrders, cancelOrder };