const { v4: uuidv4 } = require('uuid');
const { users } = require('@/data/users.data');
const { orders } = require('@/data/order.data');
const { products } = require('@/data/product.data');
const { shipments } = require('@/data/shipping.data');
const { rajaongkirGet, rajaongkirPost } = require('@/helpers/shipping.helpers');

// ================== KURIR YANG DIDUKUNG ==================
const SUPPORTED_COURIERS = [
    'jne', 'sicepat', 'ide', 'sap', 'jnt', 'ninja',
    'tiki', 'lion', 'anteraja', 'pos', 'ncs', 'rex',
    'rpx', 'sentral', 'star', 'wahana', 'dse'
];

// ================== CARI PROVINSI / KOTA / KECAMATAN ==================
// GET /shipping/provinces?search=<nama>
// GET /shipping/cities?search=<nama>
// Kedua endpoint pakai fungsi yang sama karena RajaOngkir Komerce
// menggunakan satu endpoint untuk semua level wilayah
const getProvinces = async (req, res) => {
    try {
        const { search } = req.query;
        if (!search) {
            return res.status(400).json({
                message: 'Parameter search wajib diisi. Contoh: ?search=jawa barat'
            });
        }

        const data = await rajaongkirGet('/destination/domestic-destination', { search });
        return res.status(200).json({
            message: 'Data destinasi berhasil diambil',
            data,
        });
    } catch (error) {
        return res.status(500).json({
            message: 'Gagal mengambil data provinsi',
            error: error.message,
        });
    }
};

const getCities = async (req, res) => {
    try {
        const { search } = req.query;
        if (!search) {
            return res.status(400).json({
                message: 'Parameter search wajib diisi. Contoh: ?search=jakarta selatan'
            });
        }

        const data = await rajaongkirGet('/destination/domestic-destination', { search });
        return res.status(200).json({
            message: 'Daftar kota berhasil diambil',
            data,
        });
    } catch (error) {
        return res.status(500).json({
            message: 'Gagal mengambil data kota',
            error: error.message
        });
    }
};

// ================== HITUNG ONGKIR ==================
//POST /shipping/cost
const calculateShipping = async (req, res) => {
    try {
        const { originCityId, destinationCityId, weightGram, courier } = req.body;

        if (!originCityId || !destinationCityId || !weightGram) {
            return res.status(400).json({
                message: 'originCityId, destinationCityId, dan weightGram wajib diisi',
            });
        }

        if (isNaN(weightGram) || Number(weightGram) < 1) {
            return res.status(400).json({
                message: 'weightGram harus berupa angka positif (dalam gram)',
            });
        }
        const courierParam = courier
            ? courier.toLowerCase()
            : SUPPORTED_COURIERS.join(':');

        const data = await rajaongkirPost('/calculate/domestic-cost', {
            origin: originCityId,
            destination: destinationCityId,
            weight: Number(weightGram),
            courier: courierParam,
            price: 'lowest',
        });

        const results = Array.isArray(data) ? data : [data];
        results.sort((a, b) => a.cost - b.cost); // urutkan dari termurah

        return res.status(200).json({
            message: 'Kalkulasi ongkir berhasil',
            weightGram: Number(weightGram),
            data: results,
        });
    } catch (error) {
        return res.status(500).json({
            message: 'Gagal menghitung ongkir',
            error: error.message,
        });
    }
};

// ================== RIWAYAT PENGIRIMAN USER ==================
// GET /shipping/my-shipments
const getMyShipments = (req, res) => {
    const userId = req.user.id;
    const userShipments = shipments.filter(s => s.userId === userId);

    return res.status(200).json({
        message: 'Daftar pengiriman berhasil diambil',
        total: userShipments.length,
        data: userShipments,
    });
};

// ================== SEMUA PENGIRIMAN (ADMIN) ==================
// GET /shipping/shipments
const getAllShipments = (req, res) => {
    return res.status(200).json({
        message: 'Semua data pengiriman berhasil diambil',
        total: shipments.length,
        data: shipments,
    });
};

// ================== UPDATE STATUS PENGIRIMAN (ADMIN) ==================
// PATCH /shipping/:id/status
const updateShipmentStatus = (req, res) => {
    const { id } = req.params;
    const { status, message } = req.body;

    const validStatuses = ['PENDING', 'PICKED_UP', 'IN_TRANSIT', 'DELIVERED', 'CANCELLED'];
    if (!status || !validStatuses.includes(status.toUpperCase())) {
        return res.status(400).json({
            message: 'Status tidak valid',
            validStatuses,
        });
    }

    const shipment = shipments.find(s => s.id === id);
    if (!shipment) {
        return res.status(404).json({ message: 'Shipment tidak ditemukan' });
    }

    const statusUpper = status.toUpperCase();
    shipment.status = statusUpper;
    shipment.updatedAt = new Date().toISOString();
    shipment.statusHistory.push({
        status: statusUpper,
        message: message ?? `Status diperbarui ke ${statusUpper}`,
        timestamp: new Date().toISOString(),
    });

    if (statusUpper === 'DELIVERED') {
        const order = orders.find(o => o.id === shipment.orderId);
        if (order) order.status = 'delivered';
    }

    if (statusUpper === 'CANCELLED') {
        const order = orders.find(o => o.id === shipment.orderId);
        if (order) order.status = 'cancelled';
    }

    return res.status(200).json({
        message: 'Status pengiriman berhasil diperbarui',
        data: shipment,
    });
};

module.exports = {
    getProvinces,
    getCities,
    calculateShipping,
    getMyShipments,
    getAllShipments,
    updateShipmentStatus,
};