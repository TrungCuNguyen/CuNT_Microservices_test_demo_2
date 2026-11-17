-- =============================================================================
-- 01_schema.sql
-- Định nghĩa cấu trúc bảng (DDL) cho microservices: Inventory Service & Order Service
-- Database: inventory_db (PostgreSQL)
-- =============================================================================

-- 1. Tạo bảng product (Inventory Service)
CREATE TABLE IF NOT EXISTS product (
    id BIGSERIAL PRIMARY KEY,
    product_name VARCHAR(255) NOT NULL,
    quantity INTEGER NOT NULL DEFAULT 0,
    price NUMERIC(38, 2) NOT NULL DEFAULT 0.00
);

-- Index hỗ trợ tìm kiếm nhanh theo tên sản phẩm
CREATE INDEX IF NOT EXISTS idx_product_name ON product(product_name);

-- 2. Tạo bảng orders (Order Service)
CREATE TABLE IF NOT EXISTS orders (
    id BIGSERIAL PRIMARY KEY,
    product_id BIGINT,
    quantity INTEGER,
    status VARCHAR(50),
    total_price NUMERIC(38, 2) DEFAULT 0.00
);

-- Index hỗ trợ tra cứu đơn hàng theo product_id và trạng thái
CREATE INDEX IF NOT EXISTS idx_orders_product_id ON orders(product_id);
CREATE INDEX IF NOT EXISTS idx_orders_status ON orders(status);
