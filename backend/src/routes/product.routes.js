const express = require('express');
const router = express.Router();
const { createProduct, getAllProducts, getProductById, updateProduct, deleteProduct, getPendingProducts, approveProduct, rejectProduct} = require('@/controllers/product.controller');
const { authMiddleware } = require('@/middleware/auth.middleware');
const { roleMiddleware } = require('@/middleware/role.middleware');
const {upload} = require('@/middleware/image.up.middleware');


router.post('/create', authMiddleware, upload.single('image'), createProduct);
router.put('/update/:productId', authMiddleware, updateProduct);
router.delete('/delete/:productId', authMiddleware, deleteProduct);
//buat admin
router.get('/pending', authMiddleware, roleMiddleware, getPendingProducts);
router.put('/:productId/approve', authMiddleware, roleMiddleware, approveProduct);
router.put('/:productId/reject', authMiddleware, roleMiddleware, rejectProduct);

//ini buat public/user
router.get('/products', getAllProducts);
router.get('/:productId', getProductById);

module.exports = router;