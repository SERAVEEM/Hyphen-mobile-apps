const pool = require('@/config/db');
const { rajaongkirGet, rajaongkirPost } = require('@/helpers/shipping.helpers');

const SUPPORTED_COURIERS = ['jne', 'jnt', 'sicepat', 'anteraja', 'pos'];

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
const calculateShipping = async (req, res) => {
    try {
        const { originCityId, destinationCityId, weightGram, courier } = req.body;

        if (!originCityId || !destinationCityId || !weightGram) {
            return res.status(400).json({ message: 'originCityId, destinationCityId, dan weightGram wajib diisi' });
        }
        if (isNaN(weightGram) || Number(weightGram) < 1) {
            return res.status(400).json({ message: 'weightGram harus berupa angka positif (dalam gram)' });
        }

        if (courier && !SUPPORTED_COURIERS.includes(courier.toLowerCase())) {
            return res.status(400).json({
                message: 'Kurir tidak didukung',
                supported: SUPPORTED_COURIERS
            });
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
const updateShipmentStatus = async (req, res) => {
    try {
        const { shipmentId } = req.params;
        const { status } = req.body;

        const validStatuses = ['pending', 'processing', 'shipped', 'delivered', 'cancelled'];
        if (!status || !validStatuses.includes(status.toLowerCase())) {
            return res.status(400).json({ message: 'Status tidak valid', validStatuses });
        }

        const [shipment] = await pool.query('SELECT * FROM shipments WHERE id = ?', [shipmentId]);
        if (shipment.length === 0) {
            return res.status(404).json({ message: 'Shipment tidak ditemukan' });
        }

        const statusLower = status.toLowerCase();
        await pool.query('UPDATE shipments SET status = ? WHERE id = ?', [statusLower, shipmentId]);

        if (statusLower === 'delivered') {
            await pool.query("UPDATE orders SET status = 'delivered' WHERE id = ?", [shipment[0].orderId]);
        } else if (statusLower === 'cancelled') {
            await pool.query("UPDATE orders SET status = 'cancelled' WHERE id = ?", [shipment[0].orderId]);
        }

        const [updated] = await pool.query('SELECT * FROM shipments WHERE id = ?', [shipmentId]);

        return res.status(200).json({ message: 'Status pengiriman berhasil diperbarui', data: updated[0] });
    } catch (error) {
        console.error('updateShipmentStatus error:', error);
        return res.status(500).json({ message: 'Internal server error', error: error.message });
    }
};

module.exports = { getCities, calculateShipping, getMyShipments, getAllShipments, updateShipmentStatus };