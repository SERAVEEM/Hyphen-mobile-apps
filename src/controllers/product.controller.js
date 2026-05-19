const { v4: uuidv4 } = require('uuid');
const pool = require('@/config/db');
const { validateSizes } = require('@/helpers/product.helpers');
const { formatProduct } = require('@/helpers/product.helpers');
const cloudinary = require('@/config/cloudinary');

// ========================= CREATE PRODUCT =========================
// POST /product/create
const createProduct = async (req, res) => {
    try {
        const {
            name, description, price,
            sizes: rawSizes,
            category, originCityLabel, originCityId, weight
        } = req.body;
        const sellerID = req.user.id;

        if (!name || !description || !price || !rawSizes || !category || !originCityLabel || !originCityId || !weight) {
            return res.status(400).json({ message: 'Semua field wajib diisi' });
        }
        if (isNaN(price) || Number(price) <= 0) {
            return res.status(400).json({ message: 'Price harus berupa angka positif' });
        }

        const parsedSizes = JSON.parse(rawSizes);
        const sizeValidationError = validateSizes(parsedSizes);
        if (sizeValidationError) {
            return res.status(400).json({ message: sizeValidationError });
        }

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
            'INSERT INTO products (id, sellerID, name, description, price, category, weight, originCityId, originCityLabel, imageUrl) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
            [id, sellerID, name, description, Number(price), category, Number(weight), originCityId, originCityLabel, imageUrl]
        );

        for (const s of parsedSizes) {
            await pool.query(
                'INSERT INTO product_sizes (productId, size, stock) VALUES (?, ?, ?)',
                [id, s.size.toUpperCase(), Number(s.stock)]
            );
        }

        const [product] = await pool.query('SELECT * FROM products WHERE id = ?', [id]);
        const [sizes_] = await pool.query('SELECT size, stock FROM product_sizes WHERE productId = ?', [id]);

        return res.status(201).json({
            message: 'Product berhasil dibuat',
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
            LEFT JOIN product_sizes ps ON p.id = ps.productId
            WHERE 1=1
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
// GET /product/:id
const getProductById = async (req, res) => {
    try {
        const { id } = req.params;

        const [product] = await pool.query('SELECT * FROM products WHERE id = ?', [id]);
        if (product.length === 0) {
            return res.status(404).json({ message: 'Product tidak ditemukan' });
        }

        const [sizes] = await pool.query('SELECT size, stock FROM product_sizes WHERE productId = ?', [id]);

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
// PUT /product/update/:id
const updateProduct = async (req, res) => {
    try {
        const { id } = req.params;
        const { name, description, price, sizes, category, originCityId, originCityLabel, weight } = req.body;

        const [product] = await pool.query('SELECT * FROM products WHERE id = ?', [id]);
        if (product.length === 0) {
            return res.status(404).json({ message: 'Product tidak ditemukan' });
        }
        if (product[0].sellerID !== req.user.id && req.user.role !== 'admin') {
            return res.status(403).json({ message: 'Anda tidak memiliki akses untuk mengubah produk ini' });
        }

        await pool.query(
            `UPDATE products SET
                name = COALESCE(?, name),
                description = COALESCE(?, description),
                price = COALESCE(?, price),
                category = COALESCE(?, category),
                weight = COALESCE(?, weight),
                originCityId = COALESCE(?, originCityId),
                originCityLabel = COALESCE(?, originCityLabel)
            WHERE id = ?`,
            [name || null, description || null, price ? Number(price) : null,
             category || null, weight ? Number(weight) : null,
             originCityId || null, originCityLabel || null, id]
        );

        if (sizes) {
            const parsedSizes = JSON.parse(sizes);
            const sizeValidationError = validateSizes(parsedSizes);
            if (sizeValidationError) {
                return res.status(400).json({ message: sizeValidationError });
            }
            await pool.query('DELETE FROM product_sizes WHERE productId = ?', [id]);
            for (const s of parsedSizes) {
                await pool.query(
                    'INSERT INTO product_sizes (productId, size, stock) VALUES (?, ?, ?)',
                    [id, s.size.toUpperCase(), Number(s.stock)]
                );
            }
        }

        const [updated] = await pool.query('SELECT * FROM products WHERE id = ?', [id]);
        const [updatedSizes] = await pool.query('SELECT size, stock FROM product_sizes WHERE productId = ?', [id]);

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
// DELETE /product/delete/:id
const deleteProduct = async (req, res) => {
    try {
        const { id } = req.params;

        const [product] = await pool.query('SELECT id, sellerID FROM products WHERE id = ?', [id]);
        if (product.length === 0) {
            return res.status(404).json({ message: 'Product tidak ditemukan' });
        }
        if (product[0].sellerID !== req.user.id && req.user.role !== 'admin') {
            return res.status(403).json({ message: 'Anda tidak memiliki akses untuk menghapus produk ini' });
        }

        await pool.query('DELETE FROM products WHERE id = ?', [id]);

        return res.status(200).json({ message: 'Product berhasil dihapus' });
    } catch (error) {
        console.error('deleteProduct error:', error);
        return res.status(500).json({ message: 'Internal server error', error: error.message });
    }
};

module.exports = { createProduct, getAllProducts, getProductById, updateProduct, deleteProduct };