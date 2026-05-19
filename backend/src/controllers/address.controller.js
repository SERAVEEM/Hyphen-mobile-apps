const { v4: uuidv4 } = require('uuid');
const pool = require('@/config/db');
const { validatePhone, validatePostalCode } = require('@/helpers/address.helpers');

// ========================= ADD ALAMAT =========================
// POST /address/add
const addAddress = async (req, res) => {
    try {
        const { label, recipientName, phone, address, postalCode, isDefault, destinationCityId, destinationCityLabel } = req.body;
        const userId = req.user.id;

        if (!label || !recipientName || !phone || !address || !postalCode || !destinationCityId) {
            return res.status(400).json({ message: 'Semua field harus diisi' });
        }
        if (!validatePhone(phone)) {
            return res.status(400).json({ message: 'Format nomor telepon tidak valid' });
        }
        if (!validatePostalCode(postalCode)) {
            return res.status(400).json({ message: 'Kode pos harus 5 digit angka' });
        }

        const [existing] = await pool.query('SELECT id FROM addresses WHERE userId = ?', [userId]);
        const shouldSetDefault = isDefault || existing.length === 0;

        if (shouldSetDefault) {
            await pool.query('UPDATE addresses SET isDefault = 0 WHERE userId = ?', [userId]);
        }

        const id = uuidv4();
        await pool.query(
            'INSERT INTO addresses (id, userId, label, recipientName, phone, address, postalCode, destinationCityId, destinationCityLabel, isDefault) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
            [id, userId, label, recipientName, phone, address, postalCode, destinationCityId, destinationCityLabel ?? null, shouldSetDefault ? 1 : 0]
        );

        const [newAddress] = await pool.query('SELECT * FROM addresses WHERE id = ?', [id]);

        return res.status(201).json({ message: 'Alamat berhasil ditambahkan', data: newAddress[0] });
    } catch (error) {
        console.error('addAddress error:', error);
        return res.status(500).json({ message: 'Internal server error', error: error.message });
    }
};

// ========================= DELETE ALAMAT =========================
// DELETE /address/delete/:addressId
const deleteAddress = async (req, res) => {
    try {
        const { addressId } = req.params;
        const userId = req.user.id;

        const [address] = await pool.query(
            'SELECT * FROM addresses WHERE id = ? AND userId = ?',
            [addressId, userId]
        );
        if (address.length === 0) {
            return res.status(404).json({ message: 'Alamat tidak ditemukan' });
        }

        await pool.query('DELETE FROM addresses WHERE id = ?', [addressId]);

        // Kalau yang dihapus default, set alamat pertama yang tersisa sebagai default
        if (address[0].isDefault) {
            const [remaining] = await pool.query(
                'SELECT id FROM addresses WHERE userId = ? LIMIT 1', [userId]
            );
            if (remaining.length > 0) {
                await pool.query('UPDATE addresses SET isDefault = 1 WHERE id = ?', [remaining[0].id]);
            }
        }

        const [addresses] = await pool.query('SELECT * FROM addresses WHERE userId = ?', [userId]);

        return res.status(200).json({ message: 'Alamat berhasil dihapus', data: addresses });
    } catch (error) {
        console.error('deleteAddress error:', error);
        return res.status(500).json({ message: 'Internal server error', error: error.message });
    }
};

// ========================= GET ALL ADDRESSES =========================
// GET /address/addresses
const getAllAddresses = async (req, res) => {
    try {
        const [addresses] = await pool.query(
            'SELECT * FROM addresses WHERE userId = ?', [req.user.id]
        );

        return res.status(200).json({ message: 'Berhasil mengambil semua alamat', data: addresses });
    } catch (error) {
        console.error('getAllAddresses error:', error);
        return res.status(500).json({ message: 'Internal server error', error: error.message });
    }
};

// ========================= GET ADDRESS DETAIL =========================
// GET /address/detail/:addressId
const getAddressDetail = async (req, res) => {
    try {
        const { addressId } = req.params;
        const userId = req.user.id;

        const [address] = await pool.query(
            'SELECT * FROM addresses WHERE id = ? AND userId = ?',
            [addressId, userId]
        );
        if (address.length === 0) {
            return res.status(404).json({ message: 'Alamat tidak ditemukan' });
        }

        return res.status(200).json({ message: 'Berhasil mengambil detail alamat', data: address[0] });
    } catch (error) {
        console.error('getAddressDetail error:', error);
        return res.status(500).json({ message: 'Internal server error', error: error.message });
    }
};

// ========================= SET DEFAULT ALAMAT =========================
// PUT /address/setDefault/:addressId
const setDefaultAddress = async (req, res) => {
    try {
        const { addressId } = req.params;
        const userId = req.user.id;

        const [address] = await pool.query(
            'SELECT id FROM addresses WHERE id = ? AND userId = ?',
            [addressId, userId]
        );
        if (address.length === 0) {
            return res.status(404).json({ message: 'Alamat tidak ditemukan' });
        }

        await pool.query('UPDATE addresses SET isDefault = 0 WHERE userId = ?', [userId]);
        await pool.query('UPDATE addresses SET isDefault = 1 WHERE id = ?', [addressId]);

        const [addresses] = await pool.query('SELECT * FROM addresses WHERE userId = ?', [userId]);

        return res.status(200).json({ message: 'Alamat berhasil diatur sebagai default', data: addresses });
    } catch (error) {
        console.error('setDefaultAddress error:', error);
        return res.status(500).json({ message: 'Internal server error', error: error.message });
    }
};

// ========================= UPDATE ALAMAT =========================
// PUT /address/update/:addressId
const updateAddress = async (req, res) => {
    try {
        const { addressId } = req.params;
        const { label, recipientName, phone, address, postalCode, destinationCityId, destinationCityLabel } = req.body;
        const userId = req.user.id;

        const [existing] = await pool.query(
            'SELECT id FROM addresses WHERE id = ? AND userId = ?',
            [addressId, userId]
        );
        if (existing.length === 0) {
            return res.status(404).json({ message: 'Alamat tidak ditemukan' });
        }

        if (phone && !validatePhone(phone)) {
            return res.status(400).json({ message: 'Format nomor telepon tidak valid' });
        }
        if (postalCode && !validatePostalCode(postalCode)) {
            return res.status(400).json({ message: 'Kode pos harus 5 digit angka' });
        }

        await pool.query(
            `UPDATE addresses SET
                label = COALESCE(?, label),
                recipientName = COALESCE(?, recipientName),
                phone = COALESCE(?, phone),
                address = COALESCE(?, address),
                postalCode = COALESCE(?, postalCode),
                destinationCityId = COALESCE(?, destinationCityId),
                destinationCityLabel = COALESCE(?, destinationCityLabel)
            WHERE id = ?`,
            [label || null, recipientName || null, phone || null, address || null,
            postalCode || null, destinationCityId || null, destinationCityLabel || null, addressId]
        );

        const [updated] = await pool.query('SELECT * FROM addresses WHERE id = ?', [addressId]);

        return res.status(200).json({ message: 'Alamat berhasil diperbarui', data: updated[0] });
    } catch (error) {
        console.error('updateAddress error:', error);
        return res.status(500).json({ message: 'Internal server error', error: error.message });
    }
};

module.exports = { addAddress, deleteAddress, getAllAddresses, setDefaultAddress, updateAddress, getAddressDetail };