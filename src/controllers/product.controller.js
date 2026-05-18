const { products } = require('@/data/product.data');
const { v4: uuidv4 } = require('uuid');
const { validateSizes } = require('@/helpers/product.helpers');
const cloudinary = require('@/config/cloudinary');





//========================= CREATE PRODUCT =========================
const createProduct = async (req, res) => {  // ← tambah async
    const { name, description, price, sizes, category,
        originCityLabel,
        originCityId,
        weight
    } = req.body;
    const sellerID = req.user.id;

    if (!name || !description || !price || !sizes || !category || !originCityLabel || !originCityId || !weight) {
        return res.status(400).json({ message: 'Semua field wajib diisi' });
    }

    if (isNaN(price) || Number(price) <= 0) {
        return res.status(400).json({ message: 'Price harus berupa angka positif' });
    }

    const sizeValidationError = validateSizes(JSON.parse(sizes)); // ← parse karena form-data
    if (sizeValidationError) {
        return res.status(400).json({ message: sizeValidationError });
    }

    // Upload gambar ke Cloudinary jika ada
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

    const newProduct = {
        id: uuidv4(),
        sellerID,
        name,
        description,
        price: Number(price), // ← parse karena form-data
        category,
        sizes: JSON.parse(sizes).map(s => ({ // ← parse karena form-data
            size: s.size.toUpperCase(),
            stock: Number(s.stock)
        })),
        weight: Number(weight),
        originCityId,
        originCityLabel,
        imageUrl,       // ← URL gambar dari Cloudinary
    };

    products.push(newProduct);

    return res.status(201).json({
        message: 'Product berhasil dibuat',
        data: newProduct
    });
};


// ========================= GET ALL PRODUCTS (SEACRH) =========================
const getAllProducts = (req, res) => {
    const { name, category, sizes } = req.query;
    let result = products;
    if (name) {
        result = result.filter(p => p.name.toLowerCase().includes(name.toLowerCase()));
    }
    if (category) {
        result = result.filter(p => p.category.toLowerCase().includes(category.toLowerCase()));
    }
    if (sizes) {
        result = result.filter(p => p.sizes.some(s => s.size === sizes.toUpperCase()));
    }

    res.status(200).json({
        message: 'Berhasil ambil semua product',
        total: result.length,
        data: result
    });
}


// ========================= CHECK DETAIL PRODUCT BY ID =========================
const getProductById = (req, res) => {
    const { id } = req.params;
    const product = products.find(p => p.id === id);

    if (!product) {
        return res.status(404).json({
            message: 'Product tidak ditemukan'
        });
    }
    res.status(200).json({
        message: 'Berhasil ambil product',
        data: product
    });
}


// ========================= UPDATE PRODUCT =========================
const updateProduct = (req, res) => {
    const { id } = req.params;
    const {
        name, description, price, sizes, category,
        originCityId,
        originCityLabel,
        weight
    } = req.body;

    const productIndex = products.findIndex(p => p.id === id);
    if (productIndex === -1) {
        return res.status(404).json({ message: 'Product tidak ditemukan' });
    }

    // Validasi seller hanya bisa update produknya sendiri
    if (products[productIndex].sellerID !== req.user.id && req.user.role !== 'admin') {
        return res.status(403).json({ message: 'Anda tidak memiliki akses untuk mengubah produk ini' });
    }

    products[productIndex] = {
        ...products[productIndex],
        ...(name && { name }),
        ...(description && { description }),
        ...(price !== undefined && { price }),
        ...(sizes && { sizes }),
        ...(category && { category }),
        ...(weight && { weight: Number(weight) }),
        ...(originCityId && { originCityId }),       // ← tambah
        ...(originCityLabel && { originCityLabel }), // ← tambah
    };

    return res.status(200).json({
        message: 'Product berhasil diperbarui',
        data: products[productIndex]
    });
};

// ========================= DELETE PRODUCT =========================
const deleteProduct = (req, res) => {
    const { id } = req.params;
    const productIndex = products.findIndex(p => p.id === id);
    if (productIndex === -1) {
        return res.status(404).json({
            message: 'Product tidak ditemukan'
        });
    }
    products.splice(productIndex, 1);
    res.status(200).json({
        message: 'Product berhasil dihapus'
    });
}

module.exports = { createProduct, getAllProducts, getProductById, updateProduct, deleteProduct };