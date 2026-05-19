const { v4: uuidv4 } = require('uuid');
const pool = require('@/config/db');

const { getOrderDetail } = require('@/helpers/order.helpers');
// ================== CREATE ORDER =====================
// POST /order/create-order
// Body: { productId, quantity, size }
const createOrder = async (req, res) => {
    try {
        const userId = req.user.id;
        const { productId, quantity, size } = req.body;

        if (!productId || !quantity || !size) {
            return res.status(400).json({ message: 'productId, quantity, dan size wajib diisi' });
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
            return res.status(400).json({ message: `Ukuran ${size.toUpperCase()} tidak tersedia` });
        }
        if (quantity > selectedSize[0].stock) {
            return res.status(400).json({
                message: 'Stok tidak cukup',
                stockTersedia: selectedSize[0].stock
            });
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

        const detail = await getOrderDetail(id);

        return res.status(201).json({
            message: 'Order berhasil dibuat',
            data: detail
        });
    } catch (error) {
        console.error('createOrder error:', error);
        return res.status(500).json({ message: 'Internal server error', error: error.message });
    }
};

// ================== CREATE ORDER DARI CART ==================
// POST /order/create/from-cart
const createOrderFromCart = async (req, res) => {
    try {
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
                errors.push(`Produk ${item.productName} tidak ditemukan`);
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
                errors.push(`Stok ${product[0].name} ukuran ${item.size} tidak cukup (tersedia: ${selectedSize[0].stock})`);
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

            const detail = await getOrderDetail(id);
            newOrders.push(detail);
        }

        await pool.query('DELETE FROM cart_items WHERE userId = ?', [userId]);

        return res.status(201).json({
            message: `${newOrders.length} order berhasil dibuat${errors.length > 0 ? `, ${errors.length} gagal` : ''}`,
            total: newOrders.length,
            errors: errors.length > 0 ? errors : undefined,
            data: newOrders
        });
    } catch (error) {
        console.error('createOrderFromCart error:', error);
        return res.status(500).json({ message: 'Internal server error', error: error.message });
    }
};

// ========================= GET ALL ORDERS (ADMIN) =========================
// GET /order/orders
const getAllOrders = async (req, res) => {
    try {
        const [orders] = await pool.query('SELECT id FROM orders ORDER BY orderDate DESC');

        const detailList = await Promise.all(orders.map(o => getOrderDetail(o.id)));

        return res.status(200).json({
            message: 'Semua data order',
            total: detailList.length,
            data: detailList
        });
    } catch (error) {
        console.error('getAllOrders error:', error);
        return res.status(500).json({ message: 'Internal server error', error: error.message });
    }
};

// ========================= GET ORDER BY ID =========================
// GET /order/orders/:id
const getOrderById = async (req, res) => {
    try {
        const { id } = req.params;

        const [order] = await pool.query('SELECT userId FROM orders WHERE id = ?', [id]);
        if (order.length === 0) {
            return res.status(404).json({ message: 'Order tidak ditemukan' });
        }
        if (order[0].userId !== req.user.id && req.user.role !== 'admin') {
            return res.status(403).json({ message: 'Akses tidak diizinkan' });
        }

        const detail = await getOrderDetail(id);

        return res.status(200).json({
            message: 'Detail order',
            data: detail
        });
    } catch (error) {
        console.error('getOrderById error:', error);
        return res.status(500).json({ message: 'Internal server error', error: error.message });
    }
};

// ========================= MY ORDERS =========================
// GET /order/my-orders
const getMyOrders = async (req, res) => {
    try {
        const userId = req.user.id;

        const [orders] = await pool.query(
            'SELECT id FROM orders WHERE userId = ? ORDER BY orderDate DESC',
            [userId]
        );

        if (orders.length === 0) {
            return res.status(200).json({ message: 'Belum ada order', total: 0, data: [] });
        }

        const detailList = await Promise.all(orders.map(o => getOrderDetail(o.id)));

        return res.status(200).json({
            message: 'Riwayat order saya',
            total: detailList.length,
            data: detailList
        });
    } catch (error) {
        console.error('getMyOrders error:', error);
        return res.status(500).json({ message: 'Internal server error', error: error.message });
    }
};

// ========================= CANCEL ORDER =========================
// POST /order/cancel/:orderId
const cancelOrder = async (req, res) => {
    try {
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
            return res.status(400).json({
                message: 'Order tidak bisa dibatalkan',
                orderStatus: order[0].status,
                info: 'Hanya order dengan status "pending" yang bisa dibatalkan'
            });
        }

        await pool.query(
            'UPDATE product_sizes SET stock = stock + ? WHERE productId = ? AND size = ?',
            [order[0].quantity, order[0].productId, order[0].size]
        );

        await pool.query('UPDATE orders SET status = ? WHERE id = ?', ['cancelled', orderId]);

        const detail = await getOrderDetail(orderId);

        return res.status(200).json({
            message: 'Order berhasil dibatalkan',
            data: detail
        });
    } catch (error) {
        console.error('cancelOrder error:', error);
        return res.status(500).json({ message: 'Internal server error', error: error.message });
    }
};

module.exports = { createOrder, createOrderFromCart, getAllOrders, getOrderById, getMyOrders, cancelOrder };