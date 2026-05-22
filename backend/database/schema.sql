-- ============================================================
-- SCHEMA SQL - MHSBe2 (E-Commerce Backend)
-- Database: MySQL
-- Catatan: checkout_controller wajib UPDATE orders.addressId = ?
--          setelah insert shipment (addressId nullable saat order dibuat,
--          diisi saat proses checkout)
-- ============================================================
CREATE DATABASE IF NOT EXISTS hypen_db CHARACTER
SET
    utf8mb4 COLLATE utf8mb4_unicode_ci;

USE hypen_db;

-- ============================================================
-- 1. USERS
-- ============================================================
CREATE TABLE
    users (
        id VARCHAR(36) NOT NULL PRIMARY KEY,
        username VARCHAR(100) NOT NULL,
        email VARCHAR(150) NOT NULL UNIQUE,
        password VARCHAR(255) NULL, -- NULL karena Google login tidak punya password
        role ENUM ('user', 'admin', 'seller') NOT NULL DEFAULT 'user',
        isVerified TINYINT (1) NOT NULL DEFAULT 0,
        googleId VARCHAR(255) NULL,
        authProvider ENUM ('local', 'google') NOT NULL DEFAULT 'local',
        createdAt DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
        updatedAt DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
    );

-- ============================================================
-- 2. USER PROFILES (relasi 1-1 ke users)
-- ============================================================
CREATE TABLE
    user_profiles (
        id INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
        userId VARCHAR(36) NOT NULL UNIQUE,
        fullname VARCHAR(100) NOT NULL,
        phone VARCHAR(15),
        dateOfBirth DATE,
        location TEXT,
        photoUrl VARCHAR(255),
        createdAt DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
        updatedAt DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
        FOREIGN KEY (userId) REFERENCES users (id) ON DELETE CASCADE
    );

-- ============================================================
-- 3. EMAIL VERIFICATIONS (OTP register)
-- ============================================================
CREATE TABLE
    email_verifications (
        id INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
        email VARCHAR(150) NOT NULL,
        otp VARCHAR(10) NOT NULL,
        otpExpiry BIGINT NOT NULL,
        createdAt DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
        INDEX idx_email (email)
    );

-- ============================================================
-- 4. RESET TOKENS (OTP forgot-password)
-- ============================================================
CREATE TABLE
    reset_tokens (
        id INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
        email VARCHAR(150) NOT NULL,
        otp VARCHAR(10) NOT NULL,
        otpExpiry BIGINT NOT NULL,
        createdAt DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
        INDEX idx_email (email)
    );

-- ============================================================
-- 5. REFRESH TOKENS
-- ============================================================
CREATE TABLE
    refresh_tokens (
        id INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
        userId VARCHAR(36) NOT NULL,
        token TEXT NOT NULL,
        expiry BIGINT NOT NULL,
        createdAt DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (userId) REFERENCES users (id) ON DELETE CASCADE,
        INDEX idx_userId (userId)
    );

-- ============================================================
-- 6. PRODUCTS
-- ============================================================
CREATE TABLE
    products (
        id VARCHAR(36) NOT NULL PRIMARY KEY,
        sellerID VARCHAR(36) NOT NULL,
        name VARCHAR(200) NOT NULL,
        description TEXT NOT NULL,
        price DECIMAL(15, 2) NOT NULL,
        category VARCHAR(100) NOT NULL,
        weight INT NOT NULL,
        originCityId VARCHAR(20) NOT NULL,
        originCityLabel VARCHAR(200) NOT NULL,
        imageUrl VARCHAR(500) NULL,
        status ENUM ('pending', 'approved', 'rejected') NOT NULL DEFAULT 'pending',
        item_condition ENUM ('like_new', 'good', 'fair') NOT NULL,
        defects TEXT NULL,
        rejectedReason TEXT NULL,
        createdAt DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
        updatedAt DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
        FOREIGN KEY (sellerID) REFERENCES users (id) ON DELETE CASCADE,
        INDEX idx_category (category),
        INDEX idx_sellerID (sellerID),
        INDEX idx_status (status)
    );

-- ============================================================
-- 7. PRODUCT SIZES (relasi 1-N ke products)
-- ============================================================
CREATE TABLE
    product_sizes (
        id INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
        productId VARCHAR(36) NOT NULL,
        size VARCHAR(10) NOT NULL,
        stock TINYINT (1) NOT NULL DEFAULT 1, -- 1 = tersedia, 0 = habis
        FOREIGN KEY (productId) REFERENCES products (id) ON DELETE CASCADE,
        UNIQUE KEY uq_product_size (productId, size),
        INDEX idx_productId (productId)
    );

-- ============================================================
-- 8. ADDRESSES
-- ============================================================
CREATE TABLE
    addresses (
        id VARCHAR(36) NOT NULL PRIMARY KEY,
        userId VARCHAR(36) NOT NULL,
        label VARCHAR(100) NOT NULL,
        recipientName VARCHAR(150) NOT NULL,
        phone VARCHAR(20) NOT NULL,
        address TEXT NOT NULL,
        postalCode VARCHAR(10) NOT NULL,
        destinationCityId VARCHAR(20) NOT NULL,
        destinationCityLabel VARCHAR(200) NULL,
        isDefault TINYINT (1) NOT NULL DEFAULT 0,
        createdAt DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
        updatedAt DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
        FOREIGN KEY (userId) REFERENCES users (id) ON DELETE CASCADE,
        INDEX idx_userId (userId)
    );

-- ============================================================
-- 9. CART ITEMS
-- FIX 4: quantity TINYINT(1) DEFAULT 1 — barang bekas max 1 per item
-- FIX 5: hapus kolom productName (redundant, bisa JOIN ke products)
-- ============================================================
CREATE TABLE
    cart_items (
        id INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
        userId VARCHAR(36) NOT NULL,
        productId VARCHAR(36) NOT NULL,
        size VARCHAR(10) NOT NULL,
        price DECIMAL(15, 2) NOT NULL,
        quantity TINYINT (1) NOT NULL DEFAULT 1,
        totalPrice DECIMAL(15, 2) NOT NULL,
        createdAt DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
        updatedAt DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
        FOREIGN KEY (userId) REFERENCES users (id) ON DELETE CASCADE,
        FOREIGN KEY (productId) REFERENCES products (id) ON DELETE CASCADE,
        UNIQUE KEY uq_user_product_size (userId, productId, size),
        INDEX idx_userId (userId)
    );

-- ============================================================
-- 10. WISHLIST
-- ============================================================
CREATE TABLE
    wishlist (
        id INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
        userId VARCHAR(36) NOT NULL,
        productId VARCHAR(36) NOT NULL,
        createdAt DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (userId) REFERENCES users (id) ON DELETE CASCADE,
        FOREIGN KEY (productId) REFERENCES products (id) ON DELETE CASCADE,
        UNIQUE KEY uq_user_product (userId, productId),
        INDEX idx_userId (userId)
    );

-- ============================================================
-- 11. ORDERS
-- ============================================================
CREATE TABLE
    orders (
        id VARCHAR(36) NOT NULL PRIMARY KEY,
        userId VARCHAR(36) NOT NULL,
        productId VARCHAR(36) NOT NULL,
        size VARCHAR(10) NOT NULL,
        price DECIMAL(15, 2) NOT NULL,
        addressId VARCHAR(36) NULL, -- diisi saat checkout via UPDATE orders SET addressId
        status ENUM (
            'pending',
            'waiting_payment',
            'waiting_confirmation',
            'paid',
            'pending_cod',
            'shipped',
            'delivered',
            'cancelled'
        ) NOT NULL DEFAULT 'pending',
        orderDate DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
        updatedAt DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
        FOREIGN KEY (userId) REFERENCES users (id) ON DELETE CASCADE,
        FOREIGN KEY (productId) REFERENCES products (id) ON DELETE RESTRICT,
        FOREIGN KEY (addressId) REFERENCES addresses (id) ON DELETE SET NULL,
        INDEX idx_userId (userId),
        INDEX idx_status (status),
        INDEX idx_productId (productId)
    );

-- ============================================================
-- 12. SHIPMENTS
-- ============================================================
CREATE TABLE
    shipments (
        id VARCHAR(36) NOT NULL PRIMARY KEY,
        orderId VARCHAR(36) NOT NULL UNIQUE,
        userId VARCHAR(36) NOT NULL,
        addressId VARCHAR(36) NOT NULL,
        courierCode VARCHAR(50) NOT NULL,
        service VARCHAR(50) NOT NULL,
        courierName VARCHAR(100) NULL,
        estimatedDays VARCHAR(50) NULL,
        shippingCost DECIMAL(15, 2) NOT NULL DEFAULT 0,
        notes TEXT NULL,
        trackingNumber VARCHAR(100) NULL,
        status ENUM (
            'pending',
            'processing',
            'shipped',
            'delivered',
            'cancelled'
        ) NOT NULL DEFAULT 'pending',
        createdAt DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
        updatedAt DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
        FOREIGN KEY (orderId) REFERENCES orders (id) ON DELETE CASCADE,
        FOREIGN KEY (userId) REFERENCES users (id) ON DELETE CASCADE,
        FOREIGN KEY (addressId) REFERENCES addresses (id) ON DELETE RESTRICT,
        INDEX idx_orderId (orderId),
        INDEX idx_userId (userId)
    );

-- ================================================
-- TABEL PAYMENTS (tanpa orderId langsung)
-- ================================================
CREATE TABLE
    payments (
        id VARCHAR(36) NOT NULL PRIMARY KEY,
        userId VARCHAR(36) NOT NULL,
        amount DECIMAL(15, 2) NOT NULL,
        paymentMethod VARCHAR(50) NOT NULL,
        status ENUM ('pending', 'paid', 'cancelled', 'expired') NOT NULL DEFAULT 'pending', -- 'failed' dihapus: tidak dipakai di controller, gunakan 'cancelled' untuk tolak/deny
        midtransOrderId VARCHAR(100) NULL UNIQUE,
        snapToken TEXT NULL,
        snapUrl TEXT NULL,
        expiredAt DATETIME NULL,
        createdAt DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
        updatedAt DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
        FOREIGN KEY (userId) REFERENCES users (id) ON DELETE CASCADE,
        INDEX idx_userId (userId),
        INDEX idx_status (status),
        INDEX idx_midtransOrderId (midtransOrderId)
    );

-- ================================================
-- TABEL PAYMENT_ORDERS (pivot: 1 payment → banyak order)
-- ================================================
CREATE TABLE
    payment_orders (
        paymentId VARCHAR(36) NOT NULL,
        orderId VARCHAR(36) NOT NULL,
        PRIMARY KEY (paymentId, orderId),
        FOREIGN KEY (paymentId) REFERENCES payments (id) ON DELETE CASCADE,
        FOREIGN KEY (orderId) REFERENCES orders (id) ON DELETE CASCADE,
        INDEX idx_paymentId (paymentId),
        INDEX idx_orderId (orderId)
    );

-- ============================================================
-- 14. CHAT ROOMS
-- ============================================================
CREATE TABLE
    chat_rooms (
        id VARCHAR(36) NOT NULL PRIMARY KEY,
        userId VARCHAR(36) NOT NULL,
        sellerId VARCHAR(36) NOT NULL,
        productId VARCHAR(36) NOT NULL,
        createdAt DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (userId) REFERENCES users (id) ON DELETE CASCADE,
        FOREIGN KEY (sellerId) REFERENCES users (id) ON DELETE CASCADE,
        FOREIGN KEY (productId) REFERENCES products (id) ON DELETE CASCADE,
        UNIQUE KEY uq_room (userId, sellerId, productId),
        INDEX idx_userId (userId),
        INDEX idx_sellerId (sellerId)
    );

-- ============================================================
-- 15. CHAT MESSAGES
-- ============================================================
CREATE TABLE
    chat_messages (
        id VARCHAR(36) NOT NULL PRIMARY KEY,
        roomId VARCHAR(36) NOT NULL,
        senderId VARCHAR(36) NOT NULL,
        message TEXT NULL,
        imageUrl VARCHAR(500) NULL,
        type ENUM ('text', 'image') NOT NULL DEFAULT 'text',
        isRead TINYINT (1) NOT NULL DEFAULT 0,
        createdAt DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (roomId) REFERENCES chat_rooms (id) ON DELETE CASCADE,
        FOREIGN KEY (senderId) REFERENCES users (id) ON DELETE CASCADE,
        INDEX idx_roomId (roomId),
        INDEX idx_senderId (senderId),
        INDEX idx_isRead (isRead)
    );

-- ============================================================
-- SEED: DEFAULT ADMIN
-- password: Admin@123 (bcrypt, cost 10)
-- Ganti password setelah pertama login!
-- ============================================================
INSERT INTO
    users (id, username, email, password, role, isVerified)
VALUES
    (
        UUID (),
        'admin123',
        'admin123@gmail.com',
        '$2b$10$ES5ZneS9ScXuIMv.UTCV2uqggEfkQJhrhprZHn63dXXmwvQRQYSym',
        'admin',
        1
    );