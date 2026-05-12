const { users } = require('@/data/users.data');
const { v4: uuidv4 } = require('uuid');
const { validatePhone, validatePostalCode } = require('@/helpers/address.helpers');


// ============= ADD ALAMAT ==================
const addAddress = (req, res) => {
    const {label, recipientName, phone, address, city, province, postalCode, isDefault} = req.body;
    const userId = req.user.id;
    if (!label || !recipientName || !phone || !address || !city || !province || !postalCode) {
        return res.status(400).json({ message: 'Semua field harus diisi' });
    }
    const user = users.find((u) => u.id === userId);
    if (!user) {
        return res.status(404).json({ message: 'User tidak ditemukan' });
    }
    if(!validatePhone(phone)){
        return res.status(400).json({ message: 'Format nomor telepon tidak valid' });
    }
    if(!validatePostalCode(postalCode)){
        return res.status(400).json({ message: 'Kode pos harus 5 digit angka' });
    }

    const shouldSetDefault = isDefault || user.addresses.length === 0; // Set default jika ini adalah alamat pertama
    if(shouldSetDefault){
        user.addresses.forEach(addr => addr.isDefault = false); // Set semua alamat lain menjadi non-default
    }
    const newAddress = {
        id: uuidv4(),
        label, /*RUMAH, KOS, KANTOR,DLL*/ 
        recipientName,
        phone,
        address,
        city,
        province,
        postalCode,
        isDefault: shouldSetDefault
    };
    user.addresses.push(newAddress);
    return res.status(201).json({
        message: 'Alamat berhasil ditambahkan',
        data: newAddress
    });
   
};

// ================== DELETE ALAMAT ==================
const deleteAddress = (req, res) => {
    const { addressId } = req.params;
    const userId = req.user.id;
    if(!addressId){
        return res.status(400).json({ message: 'Id alamat harus disertakan' });
    }
    const user = users.find((u) => u.id === userId);
    if (!user) {
        return res.status(404).json({ message: 'User tidak ditemukan' });
    }
    const addressIndex = user.addresses.findIndex((a) => a.id === addressId);
    if (addressIndex === -1) {
        return res.status(404).json({ message: 'Alamat tidak ditemukan' });
    }
    user.addresses.splice(addressIndex, 1);
    if(user.addresses.length > 0 && !user.addresses.some(addr => addr.isDefault)){
        user.addresses[0].isDefault = true; // Set alamat pertama sebagai default jika tidak ada yang default
    }
    res.status(200).json({
        message: 'Alamat berhasil dihapus',
        data : user.addresses
    });
};

// ================== LIHAT DAFTAR ALAMAT ==================
const getAllAddresses = (req, res) => {
    const user = users.find((u) => u.id === req.user.id);
    if (!user) {
        return res.status(404).json({ message: 'User tidak ditemukan' });
    }
    res.status(200).json({
        message: 'Berhasil mengambil semua alamat',
        data: user.addresses
    });
};


// ================== SET DEFAULT ALAMAT ==================
const setDefaultAddress = (req, res) => {
    const { addressId } = req.params;
    const userId = req.user.id;
    if(!addressId){
        return res.status(400).json({ message: 'Id alamat harus disertakan' });
    }
    const user = users.find((u) => u.id === userId);
    if (!user) {
        return res.status(404).json({ message: 'User tidak ditemukan' });
    }
    const address = user.addresses.find((a) => a.id === addressId);
    if (!address) {
        return res.status(404).json({ message: 'Alamat tidak ditemukan' });
    }
    user.addresses.forEach(addr => addr.isDefault = false);
    address.isDefault = true;
    res.status(200).json({
        message: 'Alamat berhasil diatur sebagai default',
        data: user.addresses
    });
};


// ============= UPDATE ALAMAT ==============
const updateAddress = (req, res) => {
    const { addressId } = req.params;
    const { label, recipientName, phone, address, city, province, postalCode } = req.body;
    const userId = req.user.id;

    const user = users.find((u) => u.id === userId);
    if (!user) {
        return res.status(404).json({ message: 'User tidak ditemukan' });
    }

    const addressIndex = user.addresses.findIndex((a) => a.id === addressId);
    if (addressIndex === -1) {
        return res.status(404).json({ message: 'Alamat tidak ditemukan' });
    }

    user.addresses[addressIndex] = { ...user.addresses[addressIndex], label, recipientName, phone, address, city, province, postalCode };

    res.status(200).json({
        message: 'Alamat berhasil diperbarui',
        data: user.addresses
    });
};

module.exports = { addAddress, deleteAddress, getAllAddresses, setDefaultAddress, updateAddress };
