-- =============================================================================
-- 00_init_all_data.sql
-- KỊCH BẢN TỔNG HỢP: KHỞI TẠO BẢNG VÀ NẠP TOÀN BỘ DATA MẪU CHO CÁC SERVICES
-- Database: inventory_db (PostgreSQL)
-- Chạy toàn bộ file này để reset môi trường test về trạng thái chuẩn ban đầu.
-- =============================================================================

BEGIN;

-- -----------------------------------------------------------------------------
-- BƯỚC 1: TẠO BẢNG VÀ INDEX (NẾU CHƯA CÓ)
-- -----------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS product (
    id BIGSERIAL PRIMARY KEY,
    product_name VARCHAR(255) NOT NULL,
    quantity INTEGER NOT NULL DEFAULT 0,
    price NUMERIC(38, 2) NOT NULL DEFAULT 0.00
);

CREATE INDEX IF NOT EXISTS idx_product_name ON product(product_name);

CREATE TABLE IF NOT EXISTS orders (
    id BIGSERIAL PRIMARY KEY,
    product_id BIGINT,
    quantity INTEGER,
    status VARCHAR(50),
    total_price NUMERIC(38, 2) DEFAULT 0.00
);

CREATE INDEX IF NOT EXISTS idx_orders_product_id ON orders(product_id);
CREATE INDEX IF NOT EXISTS idx_orders_status ON orders(status);

-- -----------------------------------------------------------------------------
-- BƯỚC 2: XÓA DỮ LIỆU CŨ VÀ RESET IDENTITY SEQUENCE
-- -----------------------------------------------------------------------------
TRUNCATE TABLE orders, product RESTART IDENTITY CASCADE;

-- -----------------------------------------------------------------------------
-- BƯỚC 3: NẠP DỮ LIỆU BẢNG PRODUCT (INVENTORY SERVICE)
-- Phân loại rõ ràng cho từng kịch bản test:
--   + ID 1, 2, 3: Đầy đủ tồn kho -> Test Case Thành Công (Success)
--   + ID 4: Cận biên 5 chiếc -> Test Case Cận biên Mua 5 (Thành công) vs Mua 6 (Thất bại)
--   + ID 5: Chỉ còn đúng 1 chiếc duy nhất -> Test Case Mua chiếc cuối cùng
--   + ID 6, 7: Hết hàng sẵn (quantity = 0) -> Test Case Thất bại (Out of stock)
--   + ID 8: Khuyến mãi giá 0đ -> Test Case Đặc biệt (Zero-price product)
--   + (Lưu ý: ID 9999 không tồn tại) -> Test Case Thất bại (Product Not Found)
-- -----------------------------------------------------------------------------
INSERT INTO product (id, product_name, quantity, price) OVERRIDING SYSTEM VALUE VALUES
(1, 'iPhone 15 Pro 128GB', 100, 25000000.00),
(2, 'Samsung Galaxy S24 Ultra 256GB', 50, 28000000.00),
(3, 'Chuột không dây Logitech M331 Silent', 500, 350000.00),
(4, 'MacBook Pro M3 Max 16 inch (Limited Edition)', 5, 85000000.00),
(5, 'Tai nghe chống ồn Sony WH-1000XM5 (Only 1 Left)', 1, 7990000.00),
(6, 'Bàn phím cơ Keychron K2 Pro (Hết hàng)', 0, 1850000.00),
(7, 'Máy chơi game PlayStation 5 Slim (Hết hàng)', 0, 13500000.00),
(8, 'Quà tặng Áo thun Tech Demo (0 VND)', 100, 0.00);

SELECT setval(pg_get_serial_sequence('product', 'id'), COALESCE(MAX(id), 1)) FROM product;

-- -----------------------------------------------------------------------------
-- BƯỚC 4: NẠP DỮ LIỆU LỊCH SỬ ĐƠN HÀNG (ORDER SERVICE)
-- Phản ánh cả đơn thành công và đơn bị hủy trước đó trong hệ thống
-- -----------------------------------------------------------------------------
INSERT INTO orders (id, product_id, quantity, status, total_price) OVERRIDING SYSTEM VALUE VALUES
(1, 1, 2, 'COMPLETED', 50000000.00),
(2, 2, 1, 'COMPLETED', 28000000.00),
(3, 3, 10, 'COMPLETED', 3500000.00),
(4, 8, 2, 'COMPLETED', 0.00),
(5, 6, 1, 'CANCELLED', 0.00),
(6, 4, 10, 'CANCELLED', 0.00),
(7, 9999, 1, 'CANCELLED', 0.00);

SELECT setval(pg_get_serial_sequence('orders', 'id'), COALESCE(MAX(id), 1)) FROM orders;

COMMIT;

-- -----------------------------------------------------------------------------
-- KIỂM TRA LẠI DỮ LIỆU ĐÃ NẠP
-- -----------------------------------------------------------------------------
SELECT 'product' AS table_name, count(*) AS total_records FROM product
UNION ALL
SELECT 'orders' AS table_name, count(*) AS total_records FROM orders;
