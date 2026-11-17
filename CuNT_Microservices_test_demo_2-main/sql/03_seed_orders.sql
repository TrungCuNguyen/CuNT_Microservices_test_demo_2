-- =============================================================================
-- 03_seed_orders.sql
-- Dữ liệu lịch sử đơn hàng mẫu bảng orders cho Order Service
-- Mô phỏng cả các đơn hàng thành công và các đơn hàng thất bại
-- =============================================================================

-- Xóa dữ liệu đơn hàng cũ và reset sequence id về 1
TRUNCATE TABLE orders RESTART IDENTITY CASCADE;

-- Chèn dữ liệu lịch sử đơn hàng
INSERT INTO orders (id, product_id, quantity, status, total_price) OVERRIDING SYSTEM VALUE VALUES
-- -----------------------------------------------------------------------------
-- [ĐƠN HÀNG THÀNH CÔNG - STATUS: COMPLETED]
-- Đã qua xác thực tồn kho, trừ kho thành công và tính đúng tổng tiền.
-- -----------------------------------------------------------------------------
(1, 1, 2, 'COMPLETED', 50000000.00), -- Mua 2 chiếc iPhone 15 Pro (2 x 25tr = 50tr)
(2, 2, 1, 'COMPLETED', 28000000.00), -- Mua 1 chiếc Samsung Galaxy S24 Ultra (28tr)
(3, 3, 10, 'COMPLETED', 3500000.00), -- Mua 10 chuột không dây Logitech (10 x 350k = 3.5tr)
(4, 8, 2, 'COMPLETED', 0.00),        -- Mua 2 áo thun quà tặng 0đ (tổng tiền 0đ)

-- -----------------------------------------------------------------------------
-- [ĐƠN HÀNG THẤT BẠI - STATUS: CANCELLED]
-- Mô phỏng các trường hợp tạo đơn thất bại được ghi nhận trong lịch sử.
-- -----------------------------------------------------------------------------
-- 1. Thất bại vì sản phẩm đã hết hàng (Product 6: Keychron K2 tồn kho = 0)
(5, 6, 1, 'CANCELLED', 0.00),

-- 2. Thất bại vì yêu cầu vượt quá tồn kho (Product 4: MacBook chỉ còn 5 chiếc, yêu cầu 10 chiếc)
(6, 4, 10, 'CANCELLED', 0.00),

-- 3. Thất bại vì sản phẩm không tồn tại trong hệ thống (Product 9999)
(7, 9999, 1, 'CANCELLED', 0.00);

-- Cập nhật sequence identity để đơn hàng tạo mới tiếp theo tự tăng từ ID 8
SELECT setval(pg_get_serial_sequence('orders', 'id'), COALESCE(MAX(id), 1)) FROM orders;
