const express = require('express')
const router = express.Router();
const {addAddress, deleteAddress, updateAddress, getAllAddresses, setDefaultAddress} = require('@/controllers/address.controller')
const { authMiddleware } = require('@/middleware/auth.middleware');

router.post('/add-address', authMiddleware, addAddress);
router.delete('/delete-address/:addressId', authMiddleware, deleteAddress);
router.put('/update-address/:addressId', authMiddleware, updateAddress);
router.get('/all-addresses', authMiddleware, getAllAddresses);
router.put('/set-default-address/:addressId', authMiddleware, setDefaultAddress);

module.exports = router;