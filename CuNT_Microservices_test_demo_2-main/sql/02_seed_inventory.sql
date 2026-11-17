-- =============================================================================
-- 02_seed_inventory.sql
-- Dữ liệu mẫu bảng product cho Inventory Service
-- Thiết kế đầy đủ các kịch bản test Thành Công & Thất Bại
-- =============================================================================

-- Xóa dữ liệu cũ và reset sequence id về 1
TRUNCATE TABLE product RESTART IDENTITY CASCADE;

-- Chèn dữ liệu theo các kịch bản test
INSERT INTO product (id, product_name, quantity, price) OVERRIDING SYSTEM VALUE VALUES
-- -----------------------------------------------------------------------------
-- [KỊCH BẢN 1: THÀNH CÔNG - HÀNG TỒN KHO DỒI DÀO]
-- Dùng để test các request đặt hàng số lượng thông thường hoặc số lượng lớn.
-- Kỳ vọng: Inventory trừ kho thành công, Order chuyển trạng thái COMPLETED, tính đúng tổng tiền.
-- -----------------------------------------------------------------------------
(1, 'iPhone 15 Pro 128GB', 100, 25000000.00),
(2, 'Samsung Galaxy S24 Ultra 256GB', 50, 28000000.00),
(3, 'Chuột không dây Logitech M331 Silent', 500, 350000.00),

-- -----------------------------------------------------------------------------
-- [KỊCH BẢN 2: CẬN BIÊN (EDGE CASES) - SỐ LƯỢNG GIỚI HẠN]
-- ID 4: Có đúng 5 chiếc.
--   + Test thành công: Mua đúng 5 chiếc -> Kho về 0, Order COMPLETED.
--   + Test thất bại: Mua 6 chiếc -> Báo lỗi "Insufficient stock", Order CANCELLED.
-- ID 5: Có đúng 1 chiếc duy nhất.
--   + Test thành công: Mua 1 chiếc -> Kho về 0.
--   + Người thứ 2 mua tiếp 1 chiếc -> Sẽ thất bại vì kho đã hết.
-- -----------------------------------------------------------------------------
(4, 'MacBook Pro M3 Max 16 inch (Limited Edition)', 5, 85000000.00),
(5, 'Tai nghe chống ồn Sony WH-1000XM5 (Only 1 Left)', 1, 7990000.00),

-- -----------------------------------------------------------------------------
-- [KỊCH BẢN 3: THẤT BẠI - SẢN PHẨM ĐÃ HẾT HÀNG (OUT OF STOCK)]
-- Tồn kho = 0. Bất kỳ request đặt hàng nào (quantity >= 1) đều phải thất bại.
-- Kỳ vọng: OrderService trả về CANCELLED với message "Insufficient stock. Available: 0".
-- -----------------------------------------------------------------------------
(6, 'Bàn phím cơ Keychron K2 Pro (Hết hàng)', 0, 1850000.00),
(7, 'Máy chơi game PlayStation 5 Slim (Hết hàng)', 0, 13500000.00),

-- -----------------------------------------------------------------------------
-- [KỊCH BẢN 4: ĐẶC BIỆT - SẢN PHẨM KHUYẾN MÃI 0 ĐỒNG]
-- Giá = 0.00. Test tính toán totalPrice và xử lý trừ kho sản phẩm 0đ.
-- Kỳ vọng: Order COMPLETED với totalPrice = 0.00.
-- -----------------------------------------------------------------------------
(8, 'Quà tặng Áo thun Tech Demo (0 VND)', 100, 0.00);

-- Cập nhật sequence identity để các lần insert tiếp theo tự tăng từ ID 9
SELECT setval(pg_get_serial_sequence('product', 'id'), COALESCE(MAX(id), 1)) FROM product;
