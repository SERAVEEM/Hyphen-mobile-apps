const express = require('express');
const router = express.Router();

const {getProvinces, getCities, calculateShipping, getMyShipments,getAllShipments, updateShipmentStatus,} = require('@/controllers/shipping.controller');
const { authMiddleware } = require('@/middleware/auth.middleware');

router.get('/provinces', getProvinces); //?=<province_id> opsional untuk detail provinsi
router.get('/cities', getCities); //?province_id=<province_id>&id=<city_id>
router.post('/cost', calculateShipping);
router.get('/my-shipments', authMiddleware, getMyShipments);
router.get('/shipments', authMiddleware, getAllShipments);
router.patch('/:id/status', authMiddleware, updateShipmentStatus);

module.exports = router;