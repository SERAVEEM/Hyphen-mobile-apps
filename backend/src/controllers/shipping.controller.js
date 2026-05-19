const pool = require('@/config/db');
const { rajaongkirGet, rajaongkirPost } = require('@/helpers/shipping.helpers');

// ========================= CARI PROVINSI =========================
// GET /shipping/provinces?search=<nama>
const getProvinces = async (req, res) => {
    try {
        const { search } = req.query;
        if (!search) {
            return res.status(400).json({ message: 'Parameter search wajib diisi. Contoh: ?search=jawa barat' });
        }

        const data = await rajaongkirGet('/destination/domestic-destination', { search });

        return res.status(200).json({ message: 'Data destinasi berhasil diambil', data });
    } catch (error) {
        console.error('getProvinces error:', error);
        return res.status(500).json({ message: 'Gagal mengambil data provinsi', error: error.message });
    }
};

// ========================= CARI KOTA =========================
// GET /shipping/cities?search=<nama>
const getCities = async (req, res) => {
    try {
        const { search } = req.query;
        if (!search) {
            return res.status(400).json({ message: 'Parameter search wajib diisi. Contoh: ?search=jakarta selatan' });
        }

        const data = await rajaongkirGet('/destination/domestic-destination', {
            search,
            limit: req.query.limit || 10,
            offset: req.query.offset || 0
        });

        return res.status(200).json({ message: 'Daftar kota berhasil diambil', data });
    } catch (error) {
        console.error('getCities error:', error);
        return res.status(500).json({ message: 'Gagal mengambil data kota', error: error.message });
    }
};

// ========================= HITUNG ONGKIR =========================
// POST /shipping/cost
const calculateShipping = async (req, res) => {
    try {
        const { originCityId, destinationCityId, weightGram, courier } = req.body;

        if (!originCityId || !destinationCityId || !weightGram) {
            return res.status(400).json({ message: 'originCityId, destinationCityId, dan weightGram wajib diisi' });
        }
        if (isNaN(weightGram) || Number(weightGram) < 1) {
            return res.status(400).json({ message: 'weightGram harus berupa angka positif (dalam gram)' });
        }

        const courierParam = courier ? courier.toLowerCase() : SUPPORTED_COURIERS.join(':');

        const data = await rajaongkirPost('/calculate/domestic-cost', {
            origin: originCityId,
            destination: destinationCityId,
            weight: Number(weightGram),
            courier: courierParam,
            price: 'lowest',
        });

        const results = Array.isArray(data) ? data : [data];
        results.sort((a, b) => a.cost - b.cost);

        return res.status(200).json({
            message: 'Kalkulasi ongkir berhasil',
            weightGram: Number(weightGram),
            data: results,
        });
    } catch (error) {
        console.error('calculateShipping error:', error);
        return res.status(500).json({ message: 'Gagal menghitung ongkir', error: error.message });
    }
};

// ========================= MY SHIPMENTS =========================
// GET /shipping/my-shipments
const getMyShipments = async (req, res) => {
    try {
        const userId = req.user.id;

        const [shipments] = await pool.query(
            'SELECT * FROM shipments WHERE userId = ? ORDER BY createdAt DESC',
            [userId]
        );

        return res.status(200).json({
            message: 'Daftar pengiriman berhasil diambil',
            total: shipments.length,
            data: shipments,
        });
    } catch (error) {
        console.error('getMyShipments error:', error);
        return res.status(500).json({ message: 'Internal server error', error: error.message });
    }
};

// ========================= ALL SHIPMENTS (ADMIN) =========================
// GET /shipping/all-shipments
const getAllShipments = async (req, res) => {
    try {
        const [shipments] = await pool.query('SELECT * FROM shipments ORDER BY createdAt DESC');

        return res.status(200).json({
            message: 'Semua data pengiriman berhasil diambil',
            total: shipments.length,
            data: shipments,
        });
    } catch (error) {
        console.error('getAllShipments error:', error);
        return res.status(500).json({ message: 'Internal server error', error: error.message });
    }
};

// ========================= UPDATE STATUS SHIPMENT (ADMIN) =========================
// PATCH /shipping/:id/status
const updateShipmentStatus = async (req, res) => {
    try {
        const { id } = req.params;
        const { status } = req.body;

        const validStatuses = ['pending', 'processing', 'shipped', 'delivered', 'cancelled'];
        if (!status || !validStatuses.includes(status.toLowerCase())) {
            return res.status(400).json({ message: 'Status tidak valid', validStatuses });
        }

        const [shipment] = await pool.query('SELECT * FROM shipments WHERE id = ?', [id]);
        if (shipment.length === 0) {
            return res.status(404).json({ message: 'Shipment tidak ditemukan' });
        }

        const statusLower = status.toLowerCase();
        await pool.query('UPDATE shipments SET status = ? WHERE id = ?', [statusLower, id]);

        if (statusLower === 'delivered') {
            await pool.query("UPDATE orders SET status = 'delivered' WHERE id = ?", [shipment[0].orderId]);
        } else if (statusLower === 'cancelled') {
            await pool.query("UPDATE orders SET status = 'cancelled' WHERE id = ?", [shipment[0].orderId]);
        }

        const [updated] = await pool.query('SELECT * FROM shipments WHERE id = ?', [id]);

        return res.status(200).json({ message: 'Status pengiriman berhasil diperbarui', data: updated[0] });
    } catch (error) {
        console.error('updateShipmentStatus error:', error);
        return res.status(500).json({ message: 'Internal server error', error: error.message });
    }
};

module.exports = { getProvinces, getCities, calculateShipping, getMyShipments, getAllShipments, updateShipmentStatus };