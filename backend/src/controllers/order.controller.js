const { v4: uuidv4 } = require('uuid');
const pool = require('@/config/db');
const { getOrderDetail } = require('@/helpers/order.helpers');

// ================== CREATE ORDER =====================
const createOrder = async (req, res) => {
    try {
        const { productId } = req.body;
        const buyerID = req.user.id;

        if (!productId) {
            return res.status(400).json({ message: 'productId wajib diisi' });
        }

        const [product] = await pool.query(
            'SELECT * FROM products WHERE id = ? AND status = "approved"',
            [productId]
        );
        if (product.length === 0) {
            return res.status(404).json({ message: 'Product tidak ditemukan' });
        }

        if (product[0].sellerID === buyerID) {
            return res.status(403).json({ message: 'Tidak bisa membeli produk sendiri' });
        }

        const [sizeRow] = await pool.query(
            'SELECT * FROM product_sizes WHERE productId = ? AND stock > 0 LIMIT 1',
            [productId]
        );
        if (sizeRow.length === 0) {
            return res.status(400).json({ message: 'Stok produk sudah habis' });
        }

        const size = sizeRow[0].size;

        await pool.query(
            'UPDATE product_sizes SET stock = 0 WHERE productId = ? AND size = ?',
            [productId, size]
        );

        const orderId = uuidv4();
        await pool.query(
            'INSERT INTO orders (id, buyerID, productId, size, price, status) VALUES (?, ?, ?, ?, ?, "pending")',
            [orderId, buyerID, productId, size, product[0].price]
        );

        return res.status(201).json({
            message: 'Order berhasil dibuat',
            data: {
                orderId,
                productId,
                productName: product[0].name,
                size,
                price: product[0].price
            }
        });
    } catch (error) {
        console.error('createOrder error:', error);
        return res.status(500).json({ message: 'Internal server error', error: error.message });
    }
};

// ================== CREATE ORDER DARI CART ==================
const createOrderFromCart = async (req, res) => {
    try {
        const buyerID = req.user.id;

        const [cart] = await pool.query('SELECT * FROM cart_items WHERE userId = ?', [buyerID]);
        if (cart.length === 0) {
            return res.status(400).json({ message: 'Cart kosong' });
        }

        const newOrders = [];
        const errors = [];

        for (const item of cart) {
            const [product] = await pool.query(
                'SELECT * FROM products WHERE id = ? AND status = "approved"',
                [item.productId]
            );
            if (product.length === 0) {
                // FIX 1: pesan error lebih informatif dengan menyebut productId
                errors.push(`Produk dengan id ${item.productId} tidak ditemukan atau belum disetujui`);
                continue;
            }

            // FIX 2: cek seller tidak bisa beli produk sendiri lewat cart
            if (product[0].sellerID === buyerID) {
                errors.push(`Tidak bisa membeli produk sendiri: ${product[0].name}`);
                continue;
            }

            const [selectedSize] = await pool.query(
                'SELECT * FROM product_sizes WHERE productId = ? AND size = ? AND stock > 0',
                [item.productId, item.size.toUpperCase()]
            );
            if (selectedSize.length === 0) {
                errors.push(`Stok ${product[0].name} ukuran ${item.size} sudah habis`);
                continue;
            }

            const orderId = uuidv4();

            // FIX 3: hapus duplikat value 'pending' — 6 kolom harus 6 value
            await pool.query(
                'INSERT INTO orders (id, buyerID, productId, size, price, status) VALUES (?, ?, ?, ?, ?, "pending")',
                [orderId, buyerID, item.productId, item.size.toUpperCase(), product[0].price]
            );

            await pool.query(
                'UPDATE product_sizes SET stock = 0 WHERE productId = ? AND size = ?',
                [item.productId, item.size.toUpperCase()]
            );

            const detail = await getOrderDetail(orderId);
            newOrders.push(detail);
        }

        // FIX 4: hanya hapus cart jika minimal 1 order berhasil dibuat
        if (newOrders.length > 0) {
            await pool.query('DELETE FROM cart_items WHERE userId = ?', [buyerID]);
        }

        // FIX 5: kembalikan 400 jika tidak ada satu pun order berhasil
        if (newOrders.length === 0) {
            return res.status(400).json({
                message: 'Semua item gagal diproses, cart tidak dihapus',
                errors
            });
        }

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
const getOrderById = async (req, res) => {
    try {
        const { id } = req.params;

        // FIX 6: kolom buyerID, bukan userId
        const [order] = await pool.query('SELECT buyerID FROM orders WHERE id = ?', [id]);
        if (order.length === 0) {
            return res.status(404).json({ message: 'Order tidak ditemukan' });
        }
        if (order[0].buyerID !== req.user.id && req.user.role !== 'admin') {
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
const getMyOrders = async (req, res) => {
    try {
        const buyerID = req.user.id;

        const [orders] = await pool.query(
            'SELECT id FROM orders WHERE buyerID = ? ORDER BY orderDate DESC',
            [buyerID]
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
const cancelOrder = async (req, res) => {
    try {
        const { orderId } = req.params;
        const buyerID = req.user.id;

        // FIX 8: kolom buyerID, bukan userId
        const [order] = await pool.query('SELECT * FROM orders WHERE id = ?', [orderId]);
        if (order.length === 0) {
            return res.status(404).json({ message: 'Order tidak ditemukan' });
        }
        if (order[0].buyerID !== buyerID) {
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
            'UPDATE product_sizes SET stock = 1 WHERE productId = ? AND size = ?',
            [order[0].productId, order[0].size]
        );

        await pool.query('UPDATE orders SET status = "cancelled" WHERE id = ?', [orderId]);

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