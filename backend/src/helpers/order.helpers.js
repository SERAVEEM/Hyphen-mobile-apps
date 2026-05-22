const pool = require('@/config/db');

const getOrderDetail = async (orderId) => {
    const [rows] = await pool.query(`
        SELECT 
            o.id              AS orderId,
            o.status          AS orderStatus,
            o.size,
            o.price,
            o.addressId,
            o.orderDate,
            o.updatedAt,

            u.id              AS userId,
            u.username,
            u.email,

            p.id              AS productId,
            p.name            AS productName,
            p.description     AS productDescription,
            p.price           AS productPrice,
            p.category        AS productCategory,
            p.imageUrl        AS productImage,
            p.weight          AS productWeight,
            p.item_condition  AS productCondition,
            p.defects         AS productDefects,
            p.originCityLabel AS productOriginCity
        FROM orders o
        JOIN users u    ON o.userId   = u.id
        JOIN products p ON o.productId = p.id
        WHERE o.id = ?
    `, [orderId]);

    if (rows.length === 0) return null;

    const row = rows[0];

    return {
        orderId: row.orderId,
        orderStatus: row.orderStatus,
        orderDate: row.orderDate,
        updatedAt: row.updatedAt,
        size: row.size,
        price: row.price,
        addressId: row.addressId || null,
        buyer: {
            buyerId: row.buyerId,
            username: row.username,
            email: row.email,
        },
        product: {
            productId: row.productId,
            productName: row.productName,
            productDescription: row.productDescription,
            productPrice: row.productPrice,
            productCategory: row.productCategory,
            productImage: row.productImage,
            productWeight: row.productWeight,
            productCondition: row.productCondition,
            productDefects: row.productDefects || null,
            productOriginCity: row.productOriginCity,
        }
    };
};

module.exports = { getOrderDetail };