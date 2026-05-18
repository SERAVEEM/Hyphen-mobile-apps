const express = require('express')
const router = express.Router();
const {addAddress, deleteAddress, updateAddress, getAllAddresses, setDefaultAddress, getAddressDetail} = require('@/controllers/address.controller')
const { authMiddleware } = require('@/middleware/auth.middleware');

router.post('/add', authMiddleware, addAddress);
router.delete('/delete/:addressId', authMiddleware, deleteAddress);
router.put('/update/:addressId', authMiddleware, updateAddress);
router.get('/addresses', authMiddleware, getAllAddresses);
router.put('/setDefault/:addressId', authMiddleware, setDefaultAddress);
router.get('/detail/:addressId', authMiddleware, getAddressDetail);

module.exports = router;