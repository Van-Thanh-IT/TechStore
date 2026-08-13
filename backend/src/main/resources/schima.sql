-- ============================================================================
-- KHỞI TẠO CƠ SỞ DỮ LIỆU TECHSTORE
-- ============================================================================
CREATE DATABASE IF NOT EXISTS TechStore 
CHARACTER SET utf8mb4 
COLLATE utf8mb4_unicode_ci;

USE TechStore;

SET FOREIGN_KEY_CHECKS = 0;

-- ============================================================================
-- 1. HỆ THỐNG PHÂN QUYỀN RBAC & XÁC THỰC (ROLES, PERMISSIONS, USERS)
-- ============================================================================

CREATE TABLE roles (
    id INT AUTO_INCREMENT PRIMARY KEY,
    code VARCHAR(50) NOT NULL UNIQUE COMMENT 'ADMIN, STAFF, WAREHOUSE, USER',
    name VARCHAR(100) NOT NULL,
    description VARCHAR(255),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE permissions (
    id INT AUTO_INCREMENT PRIMARY KEY,
    code VARCHAR(100) NOT NULL UNIQUE COMMENT 'Ví dụ: order.update, warehouse.scan_imei',
    name VARCHAR(100) NOT NULL,
    module VARCHAR(50) NOT NULL COMMENT 'Phân nhóm: ORDER, WAREHOUSE, PRODUCT...',
    description VARCHAR(255)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE role_permissions (
    role_id INT NOT NULL,
    permission_id INT NOT NULL,
    PRIMARY KEY (role_id, permission_id),
    FOREIGN KEY (role_id) REFERENCES roles(id) ON DELETE CASCADE,
    FOREIGN KEY (permission_id) REFERENCES permissions(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE users (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    role_id INT NOT NULL,
    email VARCHAR(150) UNIQUE DEFAULT NULL,
    phone VARCHAR(20) UNIQUE DEFAULT NULL,
    password VARCHAR(255) DEFAULT NULL COMMENT 'NULL nếu tạo tài khoản hoàn toàn qua Social Login',
    full_name VARCHAR(100) NOT NULL,
    avatar_url VARCHAR(255) DEFAULT NULL,
    status ENUM('active', 'inactive', 'banned') DEFAULT 'active',
    provider ENUM('LOCAL', 'GOOGLE', 'FACEBOOK') DEFAULT 'LOCAL',
    provider_id VARCHAR(255) DEFAULT NULL COMMENT 'Lưu Google ID / FB ID / Apple Sub',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    FOREIGN KEY (role_id) REFERENCES roles(id),
    INDEX idx_provider_lookup (provider, provider_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE password_resets (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    user_id BIGINT NOT NULL,
    email VARCHAR(150) NOT NULL,
    otp_code VARCHAR(6) NOT NULL COMMENT 'Mã OTP 6 chữ số',
    failed_attempts INT DEFAULT 0 COMMENT 'Số lần nhập sai (Tối đa 5 lần)',
    is_used BOOLEAN DEFAULT FALSE COMMENT 'Trạng thái đã sử dụng hay chưa',
    expires_at DATETIME NOT NULL COMMENT 'Thời gian hết hạn OTP',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    INDEX idx_email_otp (email, otp_code),
    INDEX idx_user_expires (user_id, expires_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Sổ địa chỉ người dùng (Đã bổ sung Mã Hành Chính Phục Vụ Goship/GHN)
CREATE TABLE user_addresses (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    user_id BIGINT NOT NULL,
    recipient_name VARCHAR(100) NOT NULL,
    phone VARCHAR(20) NOT NULL,
    address_line VARCHAR(255) NOT NULL COMMENT 'Số nhà, tên đường',
    ward_name VARCHAR(100) NOT NULL,
    district_name VARCHAR(100) NOT NULL,
    city_name VARCHAR(100) NOT NULL,
    ward_code VARCHAR(50) DEFAULT NULL COMMENT 'Mã Phường cho Goship',
    district_id INT DEFAULT NULL COMMENT 'Mã Quận/Huyện cho Goship',
    province_id INT DEFAULT NULL COMMENT 'Mã Tỉnh/Thành cho Goship',
    is_default BOOLEAN DEFAULT FALSE,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================================
-- 2. SẢN PHẨM, DANH MỤC & THUỘC TÍNH ĐỘNG (EAV FOR ELECTRONICS)
-- ============================================================================

CREATE TABLE brands (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL UNIQUE,
    slug VARCHAR(100) NOT NULL UNIQUE,
    logo_url VARCHAR(255)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE categories (
    id INT AUTO_INCREMENT PRIMARY KEY,
    parent_id INT DEFAULT NULL,
    name VARCHAR(100) NOT NULL,
    slug VARCHAR(100) NOT NULL UNIQUE,
    FOREIGN KEY (parent_id) REFERENCES categories(id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE attributes (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL COMMENT 'Ví dụ: RAM, Bộ nhớ trong, Chipset',
    code VARCHAR(50) NOT NULL UNIQUE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE products (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    brand_id INT NOT NULL,
    category_id INT NOT NULL,
    name VARCHAR(255) NOT NULL,
    slug VARCHAR(255) NOT NULL UNIQUE,
    thumbnail_url VARCHAR(255) DEFAULT NULL,
    description TEXT,
    warranty_months INT DEFAULT 12,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (brand_id) REFERENCES brands(id),
    FOREIGN KEY (category_id) REFERENCES categories(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE product_variants (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    product_id BIGINT NOT NULL,
    sku VARCHAR(100) NOT NULL UNIQUE,
    variant_name VARCHAR(255) NOT NULL,
    version_name VARCHAR(100) DEFAULT NULL,
    color_name VARCHAR(100) DEFAULT NULL,
    cost_price DECIMAL(15, 2) NOT NULL,
    selling_price DECIMAL(15, 2) NOT NULL,
    promotional_price DECIMAL(15, 2) DEFAULT NULL,
    is_active BOOLEAN DEFAULT TRUE,
    FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE product_variant_images (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    variant_id BIGINT NOT NULL,
    image_url VARCHAR(255) NOT NULL,
    display_order INT DEFAULT 0,
    is_thumbnail BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (variant_id) REFERENCES product_variants(id) ON DELETE CASCADE,
    INDEX idx_variant_thumbnail (variant_id, is_thumbnail)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE variant_attribute_values (
    variant_id BIGINT NOT NULL,
    attribute_id INT NOT NULL,
    attribute_value VARCHAR(255) NOT NULL,
    PRIMARY KEY (variant_id, attribute_id),
    FOREIGN KEY (variant_id) REFERENCES product_variants(id) ON DELETE CASCADE,
    FOREIGN KEY (attribute_id) REFERENCES attributes(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================================
-- 3. CHƯƠNG TRÌNH KHUYẾN MÃI (VOUCHERS & FLASH SALE)
-- ============================================================================

CREATE TABLE vouchers (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(150) NOT NULL,
    code VARCHAR(50) NOT NULL UNIQUE,
    discount_type ENUM('percentage', 'fixed_amount') NOT NULL,
    discount_value DECIMAL(15, 2) NOT NULL,
    max_discount_value DECIMAL(15, 2) DEFAULT NULL,
    min_order_value DECIMAL(15, 2) DEFAULT 0.00,
    
    is_public BOOLEAN DEFAULT TRUE COMMENT 'TRUE: Public; FALSE: Ví cá nhân',
    limit_per_customer INT DEFAULT 1,
    usage_limit INT DEFAULT 100,
    used_count INT DEFAULT 0,
    
    start_date DATETIME NOT NULL,
    end_date DATETIME NOT NULL,
    deleted_at DATETIME DEFAULT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    INDEX idx_code_active (code, start_date, end_date),
    INDEX idx_deleted_at (deleted_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE user_vouchers (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    user_id BIGINT NOT NULL,
    voucher_id INT NOT NULL,
    order_id BIGINT DEFAULT NULL COMMENT 'Đơn hàng đã áp dụng',
    status ENUM('UNUSED', 'USED', 'EXPIRED') DEFAULT 'UNUSED',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    used_at DATETIME DEFAULT NULL,
    
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (voucher_id) REFERENCES vouchers(id) ON DELETE CASCADE,
    INDEX idx_user_status (user_id, status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE flash_sales (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(150) NOT NULL,
    start_time DATETIME NOT NULL,
    end_time DATETIME NOT NULL,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    INDEX idx_time_active (start_time, end_time, is_active)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE flash_sale_items (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    flash_sale_id INT NOT NULL,
    variant_id BIGINT NOT NULL,
    flash_price DECIMAL(15, 2) NOT NULL,
    quantity INT NOT NULL,
    sold_quantity INT DEFAULT 0,
    limit_per_user INT DEFAULT 1,
    
    FOREIGN KEY (flash_sale_id) REFERENCES flash_sales(id) ON DELETE CASCADE,
    FOREIGN KEY (variant_id) REFERENCES product_variants(id),
    UNIQUE KEY uk_sale_variant (flash_sale_id, variant_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================================
-- 4. GIỎ HÀNG, ĐƠN HÀNG & BẢO HÀNH ĐIỆN TỬ
-- ============================================================================

CREATE TABLE carts (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    user_id BIGINT DEFAULT NULL UNIQUE,
    session_id VARCHAR(255) DEFAULT NULL UNIQUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    INDEX idx_user_cart (user_id),
    INDEX idx_session_cart (session_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE cart_items (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    cart_id BIGINT NOT NULL,
    variant_id BIGINT NOT NULL,
    quantity INT NOT NULL DEFAULT 1,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    FOREIGN KEY (cart_id) REFERENCES carts(id) ON DELETE CASCADE,
    FOREIGN KEY (variant_id) REFERENCES product_variants(id) ON DELETE CASCADE,
    UNIQUE KEY uk_cart_variant (cart_id, variant_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE orders (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    code VARCHAR(50) NOT NULL UNIQUE,
    user_id BIGINT DEFAULT NULL,
    voucher_id INT DEFAULT NULL,
    
    -- SNAPSHOT NGƯỜI NHẬN
    customer_name VARCHAR(100) NOT NULL,
    customer_phone VARCHAR(20) NOT NULL,
    customer_email VARCHAR(150) DEFAULT NULL,
    shipping_address VARCHAR(255) NOT NULL,
    shipping_ward VARCHAR(100) NOT NULL,
    shipping_district VARCHAR(100) NOT NULL,
    shipping_city VARCHAR(100) NOT NULL,
    shipping_ward_code VARCHAR(50) DEFAULT NULL,
    shipping_district_code VARCHAR(50) DEFAULT NULL,
    shipping_city_code VARCHAR(50) DEFAULT NULL,
    
    -- SNAPSHOT VAT
    is_vat_required BOOLEAN DEFAULT FALSE,
    company_name VARCHAR(255) DEFAULT NULL,
    tax_code VARCHAR(50) DEFAULT NULL,
    company_address VARCHAR(255) DEFAULT NULL,
    company_email VARCHAR(150) DEFAULT NULL,
    
    -- TIỀN TỆ & PHÍ SHIP
    total_amount DECIMAL(15, 2) NOT NULL,
    discount_amount DECIMAL(15, 2) DEFAULT 0.00,
    shipping_fee DECIMAL(15, 2) DEFAULT 0.00,
    final_amount DECIMAL(15, 2) NOT NULL,
    
    -- GOSHIP
    goship_shipment_id VARCHAR(50) DEFAULT NULL,
    shipping_carrier VARCHAR(50) DEFAULT NULL,
    tracking_number VARCHAR(100) DEFAULT NULL,
    
    -- TRẠNG THÁI
    order_status ENUM('PENDING', 'CONFIRMED', 'PACKING', 'SHIPPING', 'DELIVERED', 'CANCELLED') DEFAULT 'PENDING',
    cancel_reason VARCHAR(255) DEFAULT NULL,
    note TEXT DEFAULT NULL,
    
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE SET NULL,
    FOREIGN KEY (voucher_id) REFERENCES vouchers(id) ON DELETE SET NULL,
    
    INDEX idx_orders_code (code),
    INDEX idx_orders_user (user_id, created_at),
    INDEX idx_orders_status (order_status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Khóa ngoại bổ sung cho user_vouchers trỏ về orders
ALTER TABLE user_vouchers 
ADD CONSTRAINT fk_user_vouchers_order 
FOREIGN KEY (order_id) REFERENCES orders(id) ON DELETE SET NULL;

CREATE TABLE order_items (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    order_id BIGINT NOT NULL,
    variant_id BIGINT NOT NULL,
    price DECIMAL(15, 2) NOT NULL,
    quantity INT NOT NULL,
    FOREIGN KEY (order_id) REFERENCES orders(id) ON DELETE CASCADE,
    FOREIGN KEY (variant_id) REFERENCES product_variants(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE payments (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    order_id BIGINT NOT NULL,
    payment_method VARCHAR(50) NOT NULL,
    provider_transaction_id VARCHAR(100) DEFAULT NULL,
    amount DECIMAL(15, 2) NOT NULL,
    status ENUM('pending', 'success', 'failed', 'refunded') DEFAULT 'pending',
    payment_url TEXT DEFAULT NULL,
    gateway_response JSON DEFAULT NULL,
    paid_at DATETIME DEFAULT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    FOREIGN KEY (order_id) REFERENCES orders(id) ON DELETE CASCADE,
    INDEX idx_order_payment (order_id, status),
    INDEX idx_provider_trans (provider_transaction_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE flash_sale_orders (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    flash_sale_item_id BIGINT NOT NULL,
    user_id BIGINT NOT NULL,
    order_id BIGINT NOT NULL,
    quantity INT NOT NULL DEFAULT 1,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (flash_sale_item_id) REFERENCES flash_sale_items(id),
    FOREIGN KEY (user_id) REFERENCES users(id),
    FOREIGN KEY (order_id) REFERENCES orders(id) ON DELETE CASCADE,
    UNIQUE KEY uk_user_flash_item (flash_sale_item_id, user_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================================
-- 5. KHO HÀNG & QUẢN LÝ ĐỊNH DANH SERIAL/IMEI
-- ============================================================================

CREATE TABLE warehouses (
    id INT AUTO_INCREMENT PRIMARY KEY,
    code VARCHAR(50) NOT NULL UNIQUE,
    name VARCHAR(150) NOT NULL,
    address VARCHAR(255) NOT NULL,
    phone VARCHAR(20),
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE inventory (
    warehouse_id INT NOT NULL,
    variant_id BIGINT NOT NULL,
    quantity INT DEFAULT 0,
    min_stock_alert INT DEFAULT 5,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    PRIMARY KEY (warehouse_id, variant_id),
    FOREIGN KEY (warehouse_id) REFERENCES warehouses(id),
    FOREIGN KEY (variant_id) REFERENCES product_variants(id),
    INDEX idx_variant_stock (variant_id, quantity)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE inventory_transactions (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    code VARCHAR(50) NOT NULL UNIQUE,
    type ENUM('IMPORT', 'EXPORT', 'TRANSFER') NOT NULL,
    from_warehouse_id INT DEFAULT NULL,
    to_warehouse_id INT DEFAULT NULL,
    order_id BIGINT DEFAULT NULL,
    created_by BIGINT NOT NULL,
    note TEXT,
    status ENUM('pending', 'completed', 'cancelled') DEFAULT 'pending',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    FOREIGN KEY (from_warehouse_id) REFERENCES warehouses(id),
    FOREIGN KEY (to_warehouse_id) REFERENCES warehouses(id),
    FOREIGN KEY (order_id) REFERENCES orders(id) ON DELETE SET NULL,
    FOREIGN KEY (created_by) REFERENCES users(id),
    INDEX idx_type_status (type, status),
    INDEX idx_created_at (created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE inventory_transaction_items (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    transaction_id BIGINT NOT NULL,
    variant_id BIGINT NOT NULL,
    quantity INT NOT NULL CHECK (quantity > 0),
    unit_cost DECIMAL(15, 2) DEFAULT 0,
    
    FOREIGN KEY (transaction_id) REFERENCES inventory_transactions(id) ON DELETE CASCADE,
    FOREIGN KEY (variant_id) REFERENCES product_variants(id),
    INDEX idx_transaction_variant (transaction_id, variant_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE serial_numbers (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    variant_id BIGINT NOT NULL,
    warehouse_id INT NOT NULL,
    serial_imei VARCHAR(100) NOT NULL UNIQUE,
    status ENUM('in_stock', 'reserved', 'sold', 'defective_returned') DEFAULT 'in_stock',
    imported_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    sold_at DATETIME DEFAULT NULL,
    
    FOREIGN KEY (variant_id) REFERENCES product_variants(id),
    FOREIGN KEY (warehouse_id) REFERENCES warehouses(id),
    INDEX idx_warehouse_status (warehouse_id, status),
    INDEX idx_variant_status (variant_id, status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE inventory_transaction_serials (
    transaction_item_id BIGINT NOT NULL,
    serial_id BIGINT NOT NULL,
    PRIMARY KEY (transaction_item_id, serial_id),
    FOREIGN KEY (transaction_item_id) REFERENCES inventory_transaction_items(id) ON DELETE CASCADE,
    FOREIGN KEY (serial_id) REFERENCES serial_numbers(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE warranties (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    serial_id BIGINT DEFAULT NULL UNIQUE COMMENT 'NULL nếu sản phẩm không có IMEI (Phụ kiện)',
    order_id BIGINT NOT NULL,
    customer_phone VARCHAR(20) NOT NULL,
    start_date DATETIME NOT NULL,
    end_date DATETIME NOT NULL,
    status ENUM('active', 'expired', 'voided') DEFAULT 'active',
    
    FOREIGN KEY (serial_id) REFERENCES serial_numbers(id),
    FOREIGN KEY (order_id) REFERENCES orders(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================================
-- 6. ĐÁNH GIÁ SẢN PHẨM (REVIEWS)
-- ============================================================================

CREATE TABLE reviews (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    user_id BIGINT NOT NULL,
    product_id BIGINT NOT NULL,
    order_id BIGINT DEFAULT NULL,
    rating TINYINT NOT NULL CHECK (rating BETWEEN 1 AND 5),
    comment TEXT,
    is_approved BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    FOREIGN KEY (user_id) REFERENCES users(id),
    FOREIGN KEY (product_id) REFERENCES products(id),
    FOREIGN KEY (order_id) REFERENCES orders(id) ON DELETE SET NULL,
    INDEX idx_product_rating (product_id, rating),
    INDEX idx_user_product (user_id, product_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE review_images (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    review_id BIGINT NOT NULL,
    image_url VARCHAR(255) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (review_id) REFERENCES reviews(id) ON DELETE CASCADE,
    INDEX idx_review_id (review_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================================
-- 7. HỆ THỐNG LIVE CHAT & TƯ VẤN KHÁCH HÀNG (LIVE CHAT / CSKH)
-- ============================================================================

CREATE TABLE chat_rooms (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    user_id BIGINT DEFAULT NULL COMMENT 'NULL nếu là Guest chat tư vấn',
    guest_session_id VARCHAR(255) DEFAULT NULL COMMENT 'Cookie/Session ID của Guest',
    
    staff_id BIGINT DEFAULT NULL COMMENT 'Nhân viên CSKH đang phụ trách hỗ trợ',
    status ENUM('WAITING', 'SUPPORTING', 'CLOSED') DEFAULT 'WAITING' COMMENT 'WAITING: Chờ nhân viên, SUPPORTING: Đang chat, CLOSED: Đã đóng',
    
    last_message_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE SET NULL,
    FOREIGN KEY (staff_id) REFERENCES users(id) ON DELETE SET NULL,
    
    INDEX idx_user_room (user_id),
    INDEX idx_guest_session (guest_session_id),
    INDEX idx_room_status (status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE chat_messages (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    room_id BIGINT NOT NULL,
    sender_id BIGINT DEFAULT NULL COMMENT 'ID người gửi (NULL nếu là Guest)',
    sender_type ENUM('USER', 'GUEST', 'STAFF', 'BOT') NOT NULL COMMENT 'Phân loại người gửi',
    
    message_type ENUM('TEXT', 'IMAGE', 'PRODUCT_LINK') DEFAULT 'TEXT' COMMENT 'Loại tin nhắn',
    content TEXT NOT NULL COMMENT 'Nội dung tin nhắn hoặc Đường dẫn ảnh',
    
    is_read BOOLEAN DEFAULT FALSE COMMENT 'Trạng thái đã đọc tin nhắn',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (room_id) REFERENCES chat_rooms(id) ON DELETE CASCADE,
    FOREIGN KEY (sender_id) REFERENCES users(id) ON DELETE SET NULL,
    
    INDEX idx_room_created (room_id, created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

SET FOREIGN_KEY_CHECKS = 1;