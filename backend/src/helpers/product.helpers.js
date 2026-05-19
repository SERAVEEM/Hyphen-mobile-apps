const VALID_SIZES = ['S', 'M', 'L', 'XL', 'XXL'];
const validateSizes = (sizes) => {
    if (!sizes || !Array.isArray(sizes) || sizes.length === 0) {
        return 'sizes wajib diisi dan berupa array (contoh: [{"size":"S","stock":10}])';
    }

    for (const item of sizes) {
        if (!item.size || !VALID_SIZES.includes(item.size.toUpperCase())) {
            return `Size tidak valid. Pilihan: ${VALID_SIZES.join(', ')}`;
        }
        if (item.stock === undefined || isNaN(item.stock) || item.stock < 0) {
            return `Stock untuk size ${item.size} harus berupa angka non-negatif`;
        }
    }

    return null;
};
const formatProduct = (product, sizes = []) => ({
    productId: product.id,
    sellerID: product.sellerID,
    productName: product.name,
    productDesc: product.description,
    productPrice: product.price,
    productCategory: product.category,
    productWeight: product.weight,
    originCityId: product.originCityId,
    originCityLabel: product.originCityLabel,
    productImage: product.imageUrl,
    createdAt: product.createdAt,
    updatedAt: product.updatedAt,
    sizes,
});
module.exports = { validateSizes, formatProduct };