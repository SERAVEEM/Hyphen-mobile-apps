const express = require('express');
const router = express.Router();

const {getCities, calculateShipping, getMyShipments,getAllShipments, updateShipmentStatus,} = require('@/controllers/shipping.controller');
const { authMiddleware } = require('@/middleware/auth.middleware');

router.get('/cities', getCities);
router.post('/cost', calculateShipping);
router.get('/my-shipments', authMiddleware, getMyShipments);
router.get('/shipments', authMiddleware, getAllShipments);
router.patch('/:shipmentId/status', authMiddleware, updateShipmentStatus);

module.exports = router;