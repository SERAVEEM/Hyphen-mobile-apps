const express = require('express');
const router = express.Router();
const { createProduct, getAllProducts, getProductById, updateProduct, deleteProduct } = require('@/controllers/product.controller');
const { authMiddleware } = require('@/middleware/auth.middleware');
const { roleMiddleware } = require('@/middleware/role.middleware');
const upload = require('@/middleware/image.up.middleware');

//buat admin
router.post('/create', authMiddleware, upload.single('image'), createProduct);
router.put('/update/:id', authMiddleware, updateProduct);
router.delete('/delete/:id', authMiddleware, deleteProduct);

//ini buat public/user
router.get('/products', getAllProducts);
router.get('/:id', getProductById);



module.exports = router;