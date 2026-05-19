-- ============================================================
-- SCHEMA SQL - MHSBe2 (E-Commerce Backend)
-- Database: MySQL
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
        id VARCHAR(36) NOT NULL PRIMARY KEY, -- UUID
        username VARCHAR(100) NOT NULL,
        email VARCHAR(150) NOT NULL UNIQUE,
        password VARCHAR(255) NOT NULL, -- bcrypt hash
        role ENUM ('user', 'admin', 'seller') NOT NULL DEFAULT 'user',
        isVerified TINYINT (1) NOT NULL DEFAULT 0,
        createdAt DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
        updatedAt DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
    );

-- ============================================================
-- 2. EMAIL VERIFICATIONS (OTP register)
-- ============================================================
CREATE TABLE
    email_verifications (
        id INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
        email VARCHAR(150) NOT NULL,
        otp VARCHAR(10) NOT NULL,
        otpExpiry BIGINT NOT NULL, -- Unix timestamp (ms)
        createdAt DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
        INDEX idx_email (email)
    );

-- ============================================================
-- 3. RESET TOKENS (OTP forgot-password)
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
-- 4. REFRESH TOKENS
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
-- 5. PRODUCTS
-- ============================================================
CREATE TABLE
    products (
        id VARCHAR(36) NOT NULL PRIMARY KEY, -- UUID
        sellerID VARCHAR(36) NOT NULL,
        name VARCHAR(200) NOT NULL,
        description TEXT NOT NULL,
        price DECIMAL(15, 2) NOT NULL,
        category VARCHAR(100) NOT NULL,
        weight INT NOT NULL, -- gram
        originCityId VARCHAR(20) NOT NULL,
        originCityLabel VARCHAR(200) NOT NULL,
        imageUrl VARCHAR(500) NULL, -- Cloudinary URL
        createdAt DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
        updatedAt DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
        FOREIGN KEY (sellerID) REFERENCES users (id) ON DELETE CASCADE,
        INDEX idx_category (category),
        INDEX idx_sellerID (sellerID)
    );

-- ============================================================
-- 6. PRODUCT SIZES (relasi 1-N ke products)
-- ============================================================
CREATE TABLE
    product_sizes (
        id INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
        productId VARCHAR(36) NOT NULL,
        size VARCHAR(10) NOT NULL, -- S, M, L, XL, dst.
        stock INT NOT NULL DEFAULT 0,
        FOREIGN KEY (productId) REFERENCES products (id) ON DELETE CASCADE,
        UNIQUE KEY uq_product_size (productId, size),
        INDEX idx_productId (productId)
    );

-- ============================================================
-- 7. ADDRESSES
-- ============================================================
CREATE TABLE
    addresses (
        id VARCHAR(36) NOT NULL PRIMARY KEY, -- UUID
        userId VARCHAR(36) NOT NULL,
        label VARCHAR(100) NOT NULL, -- misal "Rumah", "Kantor"
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
-- 8. CART ITEMS
-- ============================================================
CREATE TABLE
    cart_items (
        id INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
        userId VARCHAR(36) NOT NULL,
        productId VARCHAR(36) NOT NULL,
        productName VARCHAR(200) NOT NULL,
        size VARCHAR(10) NOT NULL,
        price DECIMAL(15, 2) NOT NULL,
        quantity INT NOT NULL DEFAULT 1,
        totalPrice DECIMAL(15, 2) NOT NULL,
        createdAt DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
        updatedAt DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
        FOREIGN KEY (userId) REFERENCES users (id) ON DELETE CASCADE,
        FOREIGN KEY (productId) REFERENCES products (id) ON DELETE CASCADE,
        UNIQUE KEY uq_user_product_size (userId, productId, size),
        INDEX idx_userId (userId)
    );

-- ============================================================
-- 9. WISHLIST
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
-- 10. ORDERS
-- ============================================================
CREATE TABLE
    orders (
        id VARCHAR(36) NOT NULL PRIMARY KEY, -- UUID
        userId VARCHAR(36) NOT NULL,
        productId VARCHAR(36) NOT NULL,
        quantity INT NOT NULL,
        size VARCHAR(10) NOT NULL,
        totalPrice DECIMAL(15, 2) NOT NULL,
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
        INDEX idx_userId (userId),
        INDEX idx_status (status)
    );

-- ============================================================
-- 11. SHIPMENTS
-- ============================================================
CREATE TABLE
    shipments (
        id VARCHAR(36) NOT NULL PRIMARY KEY, -- UUID
        orderId VARCHAR(36) NOT NULL UNIQUE,
        userId VARCHAR(36) NOT NULL,
        addressId VARCHAR(36) NOT NULL,
        courierCode VARCHAR(50) NOT NULL, -- jne, sicepat, dll.
        service VARCHAR(50) NOT NULL, -- REG, YES, OKE, dll.
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

-- ============================================================
-- 12. PAYMENTS
-- ============================================================
CREATE TABLE
    payments (
        id VARCHAR(36) NOT NULL PRIMARY KEY, -- UUID
        orderId VARCHAR(36) NOT NULL,
        userId VARCHAR(36) NOT NULL,
        amount DECIMAL(15, 2) NOT NULL,
        paymentMethod VARCHAR(50) NOT NULL, -- transfer, cod, dll.
        status ENUM (
            'pending',
            'paid',
            'failed',
            'cancelled',
            'expired'
        ) NOT NULL DEFAULT 'pending',
        midtransOrderId VARCHAR(100) NULL UNIQUE, -- PAY-{orderId}-{timestamp}
        snapToken TEXT NULL,
        snapUrl TEXT NULL,
        createdAt DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
        expiredAt DATETIME NULL,
        updatedAt DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
        FOREIGN KEY (orderId) REFERENCES orders (id) ON DELETE CASCADE,
        FOREIGN KEY (userId) REFERENCES users (id) ON DELETE CASCADE,
        INDEX idx_orderId (orderId),
        INDEX idx_userId (userId),
        INDEX idx_status (status)
    );

-- ============================================================
-- 13. CHAT ROOMS
-- ============================================================
CREATE TABLE
    chat_rooms (
        id VARCHAR(36) NOT NULL PRIMARY KEY, -- UUID
        buyerId VARCHAR(36) NOT NULL,
        sellerId VARCHAR(36) NOT NULL,
        productId VARCHAR(36) NOT NULL,
        createdAt DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (buyerId) REFERENCES users (id) ON DELETE CASCADE,
        FOREIGN KEY (sellerId) REFERENCES users (id) ON DELETE CASCADE,
        FOREIGN KEY (productId) REFERENCES products (id) ON DELETE CASCADE,
        UNIQUE KEY uq_room (buyerId, sellerId, productId),
        INDEX idx_buyerId (buyerId),
        INDEX idx_sellerId (sellerId)
    );

-- ============================================================
-- 14. CHAT MESSAGES
-- ============================================================
CREATE TABLE
    chat_messages (
        id VARCHAR(36) NOT NULL PRIMARY KEY, -- UUID
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