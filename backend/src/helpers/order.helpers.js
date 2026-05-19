const { v4: uuidv4 } = require('uuid');
const pool = require('@/config/db');

const getOrderDetail = async (orderId) => {
    const [rows] = await pool.query(`
        SELECT 
            o.id            AS orderId,
            o.status        AS orderStatus,
            o.quantity,
            o.size,
            o.totalPrice,
            o.orderDate,
            o.updatedAt,

            u.id            AS userId,
            u.username,
            u.email,

            p.id            AS productId,
            p.name          AS productName,
            p.description   AS productDescription,
            p.price         AS productPrice,
            p.category      AS productCategory,
            p.imageUrl      AS productImage,
            p.weight        AS productWeight,
            p.originCityLabel AS productOriginCity
        FROM orders o
        JOIN users u    ON o.userId    = u.id
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
        quantity: row.quantity,
        size: row.size,
        totalPrice: row.totalPrice,
        user: {
            userId: row.userId,
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
            productOriginCity: row.productOriginCity,
        }
    };
};

module.exports = { getOrderDetail };