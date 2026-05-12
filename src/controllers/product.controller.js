const {products} = require('@/data/product.data');
const {v4: uuidv4} = require('uuid');
const { validateSizes } = require('@/helpers/product.helpers');





//========================= CREATE PRODUCT =========================
const createProduct = (req, res) => {
    const { name, description, price, sizes, category } = req.body;
    const sellerID =  req.user.id;
    const isAdmin = req.user.role === 'admin';

    
    if (!name || !description || !price || !sizes || !category) {
        return res.status(400).json({
            message: 'Semua field wajib diisi'
        });
    }
    if (typeof price !== 'number') {
        return res.status(400).json({
            message: 'Price harus berupa angka'
        });
    }
    const sizeValidationError = validateSizes(req.body.sizes);
    if (sizeValidationError) {
        return res.status(400).json({
            message: sizeValidationError
        });
    }
    const newProduct = {
        id: uuidv4(),
        sellerID,
        name,
        description,
        price,
        category,
        sizes: sizes.map(s=> ({ 
            size: s.size.toUpperCase(), 
            stock: Number(s.stock) })),
        
    };

    products.push(newProduct);

    res.status(201).json({
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
    if(sizes) {
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

    if(!product) {
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
    const { id, name, description, price, sizes, category } = req.body;
    const productIndex = products.findIndex(p => p.id === id);

    if (productIndex === -1) {
        return res.status(404).json({
            message: 'Product tidak ditemukan'
        });
    }

    //UPDATE
    products[productIndex] = {
        ...products[productIndex],
        name: name || products[productIndex].name,
        description: description || products[productIndex].description,
        price: price !== undefined ? price : products[productIndex].price,
        sizes: sizes || products[productIndex].sizes,
        category: category || products[productIndex].category
    };

    res.status(200).json({
        message: 'Product berhasil diperbarui',
        data: products[productIndex]
    });
}

// ========================= DELETE PRODUCT =========================
const deleteProduct = (req, res) => {
    const { id } = req.body;
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