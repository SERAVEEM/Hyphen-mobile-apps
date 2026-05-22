const { v4: uuidv4 } = require('uuid');
const pool = require('@/config/db');
const { formatProduct } = require('@/helpers/product.helpers');
const cloudinary = require('@/config/cloudinary');

const VALID_CONDITIONS = ['like_new', 'good', 'fair'];
const VALID_SIZES = ['XS', 'S', 'M', 'L', 'XL', 'XXL'];

// Helper: parse & validasi sizes dari string "M,L,XL"
const parseSizes = (raw) => {
    const sizeList = raw.split(',').map(s => s.trim().toUpperCase()).filter(Boolean);

    if (sizeList.length === 0) {
        return { error: 'Sizes tidak boleh kosong' };
    }

    const seen = new Set();
    for (const size of sizeList) {
        if (!VALID_SIZES.includes(size)) {
            return { error: `Size tidak valid: "${size}". Pilihan: ${VALID_SIZES.join(', ')}` };
        }
        if (seen.has(size)) {
            return { error: `Size ${size} duplikat` };
        }
        seen.add(size);
    }

    return { sizeList };
};

// ========================= CREATE PRODUCT =========================
// POST /product/create
// form-data: name, description, price, sizes (M,L,XL), category, originCityLabel, originCityId, weight, item_condition, defects, image
const createProduct = async (req, res) => {
    try {
        const {
            name, description, price,
            sizes: rawSizes,
            category, originCityLabel, originCityId, weight,
            item_condition, defects
        } = req.body;
        const sellerID = req.user.id;

        if (!name || !description || !price || !rawSizes || !category || !originCityLabel || !originCityId || !weight) {
            return res.status(400).json({ message: 'Semua field wajib diisi' });
        }

        if (!item_condition || !VALID_CONDITIONS.includes(item_condition)) {
            return res.status(400).json({ message: 'Kondisi barang wajib diisi (like_new / good / fair)' });
        }

        if (isNaN(price) || Number(price) <= 0) {
            return res.status(400).json({ message: 'Price harus berupa angka positif' });
        }

        const { sizeList, error: sizeError } = parseSizes(rawSizes);
        if (sizeError) return res.status(400).json({ message: sizeError });

        let imageUrl = null;
        if (req.file) {
            const result = await new Promise((resolve, reject) => {
                cloudinary.uploader.upload_stream(
                    { folder: 'product_images', resource_type: 'image' },
                    (error, result) => {
                        if (error) reject(error);
                        else resolve(result);
                    }
                ).end(req.file.buffer);
            });
            imageUrl = result.secure_url;
        }

        const id = uuidv4();

        await pool.query(
            'INSERT INTO products (id, sellerID, name, description, price, category, weight, originCityId, originCityLabel, imageUrl, item_condition, defects) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
            [id, sellerID, name, description, Number(price), category, Number(weight), originCityId, originCityLabel, imageUrl, item_condition, defects || null]
        );

        // batch insert sizes, stok otomatis 1 (barang bekas)
        const sizeValues = sizeList.map(size => [id, size, 1]);
        await pool.query('INSERT INTO product_sizes (productId, size, stock) VALUES ?', [sizeValues]);

        const [product] = await pool.query('SELECT * FROM products WHERE id = ?', [id]);
        const [sizes_] = await pool.query('SELECT size, stock FROM product_sizes WHERE productId = ?', [id]);

        return res.status(201).json({
            message: 'Product berhasil dibuat, menunggu persetujuan admin',
            data: formatProduct(product[0], sizes_)
        });
    } catch (error) {
        console.error('createProduct error:', error);
        return res.status(500).json({ message: 'Internal server error', error: error.message });
    }
};

// ========================= GET ALL PRODUCTS =========================
// GET /product/products?name=&category=&sizes=
const getAllProducts = async (req, res) => {
    try {
        const { name, category, sizes } = req.query;

        let query = `
            SELECT p.*, GROUP_CONCAT(ps.size) as availableSizes
            FROM products p
            LEFT JOIN product_sizes ps ON p.id = ps.productId AND ps.stock > 0
            WHERE p.status = 'approved'
        `;
        const params = [];

        if (name) {
            query += ' AND p.name LIKE ?';
            params.push(`%${name}%`);
        }
        if (category) {
            query += ' AND p.category LIKE ?';
            params.push(`%${category}%`);
        }
        if (sizes) {
            query += ' AND ps.size = ?';
            params.push(sizes.toUpperCase());
        }

        query += ' GROUP BY p.id';

        const [products] = await pool.query(query, params);

        const productIds = products.map(p => p.id);
        let sizesMap = {};
        if (productIds.length > 0) {
            const [allSizes] = await pool.query(
                'SELECT productId, size, stock FROM product_sizes WHERE productId IN (?)',
                [productIds]
            );
            allSizes.forEach(s => {
                if (!sizesMap[s.productId]) sizesMap[s.productId] = [];
                sizesMap[s.productId].push({ size: s.size, stock: s.stock });
            });
        }

        const result = products.map(p => formatProduct(p, sizesMap[p.id] || []));

        return res.status(200).json({
            message: 'Berhasil ambil semua product',
            total: result.length,
            data: result
        });
    } catch (error) {
        console.error('getAllProducts error:', error);
        return res.status(500).json({ message: 'Internal server error', error: error.message });
    }
};

// ========================= GET PRODUCT BY ID =========================
const getProductById = async (req, res) => {
    try {
        const { productId } = req.params;

        const [product] = await pool.query('SELECT * FROM products WHERE id = ?', [productId]);
        if (product.length === 0) {
            return res.status(404).json({ message: 'Product tidak ditemukan' });
        }

        const [sizes] = await pool.query('SELECT size, stock FROM product_sizes WHERE productId = ?', [productId]);

        return res.status(200).json({
            message: 'Berhasil ambil product',
            data: formatProduct(product[0], sizes)
        });
    } catch (error) {
        console.error('getProductById error:', error);
        return res.status(500).json({ message: 'Internal server error', error: error.message });
    }
};

// ========================= UPDATE PRODUCT =========================
const updateProduct = async (req, res) => {
    try {
        const { productId } = req.params;
        const { name, description, price, sizes: rawSizes, category, weight, originCityId, originCityLabel, item_condition, defects } = req.body;

        const [product] = await pool.query('SELECT * FROM products WHERE id = ?', [productId]);
        if (product.length === 0) {
            return res.status(404).json({ message: 'Product tidak ditemukan' });
        }
        if (product[0].sellerID !== req.user.id && req.user.role !== 'admin') {
            return res.status(403).json({ message: 'Anda tidak memiliki akses untuk mengubah produk ini' });
        }

        if (item_condition && !VALID_CONDITIONS.includes(item_condition)) {
            return res.status(400).json({ message: 'Kondisi barang tidak valid (like_new / good / fair)' });
        }

        await pool.query(
            `UPDATE products
            SET
                name = COALESCE(?, name),
                description = COALESCE(?, description),
                price = COALESCE(?, price),
                category = COALESCE(?, category),
                weight = COALESCE(?, weight),
                originCityId = COALESCE(?, originCityId),
                originCityLabel = COALESCE(?, originCityLabel),
                item_condition = COALESCE(?, item_condition),
                defects = COALESCE(?, defects),
                status = 'pending',
                rejectedReason = NULL
            WHERE id = ?`,
            [
                name || null, description || null,
                price ? Number(price) : null,
                category || null,
                weight ? Number(weight) : null,
                originCityId || null, originCityLabel || null,
                item_condition || null, defects || null,
                productId
            ]
        );

        if (rawSizes) {
            const { sizeList, error: sizeError } = parseSizes(rawSizes);
            if (sizeError) return res.status(400).json({ message: sizeError });

            await pool.query('DELETE FROM product_sizes WHERE productId = ?', [productId]);
            const sizeValues = sizeList.map(size => [productId, size, 1]);
            await pool.query('INSERT INTO product_sizes (productId, size, stock) VALUES ?', [sizeValues]);
        }

        const [updated] = await pool.query('SELECT * FROM products WHERE id = ?', [productId]);
        const [updatedSizes] = await pool.query('SELECT size, stock FROM product_sizes WHERE productId = ?', [productId]);

        return res.status(200).json({
            message: 'Product berhasil diperbarui',
            data: formatProduct(updated[0], updatedSizes)
        });
    } catch (error) {
        console.error('updateProduct error:', error);
        return res.status(500).json({ message: 'Internal server error', error: error.message });
    }
};

// ========================= DELETE PRODUCT =========================
const deleteProduct = async (req, res) => {
    try {
        const { productId } = req.params;

        const [product] = await pool.query('SELECT id, sellerID FROM products WHERE id = ?', [productId]);
        if (product.length === 0) {
            return res.status(404).json({ message: 'Product tidak ditemukan' });
        }
        if (product[0].sellerID !== req.user.id && req.user.role !== 'admin') {
            return res.status(403).json({ message: 'Anda tidak memiliki akses untuk menghapus produk ini' });
        }

        await pool.query('DELETE FROM products WHERE id = ?', [productId]);

        return res.status(200).json({ message: 'Product berhasil dihapus' });
    } catch (error) {
        console.error('deleteProduct error:', error);
        return res.status(500).json({ message: 'Internal server error', error: error.message });
    }
};

// ========================= ORDER PRODUCT =========================
const orderProduct = async (req, res) => {
    try {
        const { productId } = req.params;
        const buyerID = req.user.id;

        const [product] = await pool.query(
            'SELECT * FROM products WHERE id = ? AND status = "approved"',
            [productId]
        );
        if (product.length === 0) {
            return res.status(404).json({ message: 'Product tidak ditemukan atau belum disetujui' });
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
                productId: productId,
                productName: product[0].name,
                size,
                price: product[0].price
            }
        });
    } catch (error) {
        console.error('orderProduct error:', error);
        return res.status(500).json({ message: 'Internal server error', error: error.message });
    }
};

// ========================= ADMIN APPROVAL =========================

// GET /admin/products/pending
const getPendingProducts = async (req, res) => {
    try {
        const [products] = await pool.query(
            'SELECT * FROM products WHERE status = "pending" ORDER BY createdAt ASC'
        );

        const productIds = products.map(p => p.id);
        let sizesMap = {};
        if (productIds.length > 0) {
            const [allSizes] = await pool.query(
                'SELECT productId, size, stock FROM product_sizes WHERE productId IN (?)',
                [productIds]
            );
            allSizes.forEach(s => {
                if (!sizesMap[s.productId]) sizesMap[s.productId] = [];
                sizesMap[s.productId].push({ size: s.size, stock: s.stock });
            });
        }

        return res.status(200).json({
            message: 'Produk menunggu persetujuan',
            total: products.length,
            data: products.map(p => formatProduct(p, sizesMap[p.id] || []))
        });
    } catch (error) {
        console.error('getPendingProducts error:', error);
        return res.status(500).json({ message: 'Internal server error' });
    }
};

// PUT /admin/products/:id/approve
const approveProduct = async (req, res) => {
    try {
        const { productId } = req.params;

        const [product] = await pool.query('SELECT * FROM products WHERE id = ?', [productId]);
        if (product.length === 0) return res.status(404).json({ message: 'Produk tidak ditemukan' });
        if (product[0].status === 'approved') return res.status(400).json({ message: 'Produk sudah diapprove' });

        await pool.query(
            'UPDATE products SET status = "approved", rejectedReason = NULL WHERE id = ?',
            [productId]
        );

        return res.status(200).json({ message: 'Produk berhasil diapprove' });
    } catch (error) {
        console.error('approveProduct error:', error);
        return res.status(500).json({ message: 'Internal server error' });
    }
};

// PUT /admin/products/:id/reject
const rejectProduct = async (req, res) => {
    try {
        const { productId } = req.params;
        const { reason } = req.body;

        if (!reason) return res.status(400).json({ message: 'Alasan penolakan wajib diisi' });

        const [product] = await pool.query('SELECT * FROM products WHERE id = ?', [productId]);
        if (product.length === 0) return res.status(404).json({ message: 'Produk tidak ditemukan' });

        await pool.query(
            'UPDATE products SET status = "rejected", rejectedReason = ? WHERE id = ?',
            [reason, productId]
        );

        return res.status(200).json({ message: 'Produk berhasil direject', reason });
    } catch (error) {
        console.error('rejectProduct error:', error);
        return res.status(500).json({ message: 'Internal server error' });
    }
};

module.exports = {
    createProduct,
    getAllProducts,
    getProductById,
    updateProduct,
    deleteProduct,
    orderProduct,
    getPendingProducts,
    approveProduct,
    rejectProduct
};