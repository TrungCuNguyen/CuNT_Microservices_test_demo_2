# Hướng Dẫn Test Microservices (Test Cases Matrix)

Tài liệu này cung cấp danh sách đầy đủ các kịch bản test (Test Cases) cho hệ thống Microservices (`api-gateway`, `inventory-service`, `order-service`), bao gồm cả trường hợp **Thành Công (Success)** và **Thất Bại (Failure)**.

---

## 1. Cấu Trúc Các File SQL Đã Tạo

Thư mục `sql/` bao gồm:
1. **`00_init_all_data.sql`**: Script tổng hợp tất cả trong một (Tạo bảng + Truncate + Nạp toàn bộ dữ liệu mẫu + Reset sequence). **Khuyên dùng file này để reset môi trường về trạng thái ban đầu**.
2. **`01_schema.sql`**: Script DDL tạo bảng `product` và `orders`.
3. **`02_seed_inventory.sql`**: Dữ liệu sản phẩm mẫu cho `inventory-service`.
4. **`03_seed_orders.sql`**: Dữ liệu lịch sử đơn hàng mẫu cho `order-service`.

### Cách nạp lại dữ liệu bằng lệnh psql (Command Line):
```powershell
$env:PGPASSWORD = "123456@"; psql -U postgres -h 127.0.0.1 -d inventory_db -f "sql/00_init_all_data.sql"
```

---

## 2. Bảng Dữ Liệu Sản Phẩm Mẫu (Product Seed Data)

| ID | Tên sản phẩm | Tồn kho (Quantity) | Đơn giá (Price) | Mục đích kịch bản Test |
| :---: | :--- | :---: | :---: | :--- |
| **1** | iPhone 15 Pro 128GB | 100 | 25,000,000 | Test đặt hàng thành công số lượng thường |
| **2** | Samsung Galaxy S24 Ultra 256GB | 50 | 28,000,000 | Test đặt hàng thành công số lượng nhiều |
| **3** | Chuột không dây Logitech M331 | 500 | 350,000 | Test đặt hàng phụ kiện số lượng lớn (50 cái) |
| **4** | MacBook Pro M3 Max 16 inch | 5 | 85,000,000 | **Cận biên**: Mua đúng 5 cái (Thành công) vs Mua 6 cái (Thất bại) |
| **5** | Tai nghe chống ồn Sony WH-1000XM5 | 1 | 7,990,000 | **Chiếc cuối cùng**: Mua 1 chiếc thành công, người sau mua sẽ hết hàng |
| **6** | Bàn phím cơ Keychron K2 Pro | 0 | 1,850,000 | **Thất bại**: Sản phẩm đã hết hàng sẵn (Out of stock) |
| **7** | Máy chơi game PlayStation 5 Slim | 0 | 13,500,000 | **Thất bại**: Sản phẩm hết hàng |
| **8** | Quà tặng Áo thun Tech Demo | 100 | 0.00 | **Đặc biệt**: Sản phẩm 0 đồng (Khuyến mãi) |
| **9999** | *(Không tồn tại)* | - | - | **Thất bại**: Mã sản phẩm không tồn tại (Not Found) |

---

## 3. Ma Trận Kịch Bản Test (Test Cases Matrix)

> **Lưu ý Cổng Service**:
> - API Gateway: `http://localhost:8088` (Khuyên dùng khi test toàn hệ thống)
> - Inventory Service trực tiếp: `http://localhost:8082`
> - Order Service trực tiếp: `http://localhost:8081`

---

### TC-01: Đặt hàng thành công với sản phẩm dồi dào tồn kho
- **Service**: Order Service (qua Gateway)
- **Method**: `POST`
- **URL**: `http://localhost:8088/api/orders` (hoặc `http://localhost:8081/api/orders`)
- **Request Body**:
  ```json
  {
    "productId": 1,
    "quantity": 2
  }
  ```
- **Kết quả mong đợi**:
  - HTTP Status: `201 CREATED`
  - Response Body:
    ```json
    {
      "productId": 1,
      "quantity": 2,
      "status": "COMPLETED",
      "totalPrice": 50000000.00,
      "message": "Order completed successfully"
    }
    ```
  - **Database**: Tồn kho `product` id = 1 giảm từ `100` xuống `98`. Bảng `orders` có thêm record mới `COMPLETED`.

---

### TC-02: [Thất bại] Đặt hàng khi sản phẩm đã hết hàng sẵn (Out of Stock)
- **Service**: Order Service (qua Gateway)
- **Method**: `POST`
- **URL**: `http://localhost:8088/api/orders`
- **Request Body**:
  ```json
  {
    "productId": 6,
    "quantity": 1
  }
  ```
- **Kết quả mong đợi**:
  - HTTP Status: `201 CREATED` (Hệ thống lưu lại log order bị hủy)
  - Response Body:
    ```json
    {
      "productId": 6,
      "quantity": 1,
      "status": "CANCELLED",
      "totalPrice": 0.00,
      "message": "Insufficient stock. Available: 0, Requested: 1"
    }
    ```
  - **Database**: Tồn kho `product` id = 6 vẫn giữ nguyên `0`. Đơn hàng được lưu với trạng thái `CANCELLED`.

---

### TC-03: [Thất bại] Đặt hàng vượt quá số lượng tồn kho (Insufficient Stock)
- **Service**: Order Service (qua Gateway)
- **Method**: `POST`
- **URL**: `http://localhost:8088/api/orders`
- **Request Body** (Sản phẩm ID 4 chỉ có 5 chiếc, yêu cầu 10 chiếc):
  ```json
  {
    "productId": 4,
    "quantity": 10
  }
  ```
- **Kết quả mong đợi**:
  - HTTP Status: `201 CREATED`
  - Response Body:
    ```json
    {
      "productId": 4,
      "quantity": 10,
      "status": "CANCELLED",
      "totalPrice": 0.00,
      "message": "Insufficient stock. Available: 5, Requested: 10"
    }
    ```
  - **Database**: Tồn kho `product` id = 4 vẫn là `5`. Bảng `orders` lưu record với trạng thái `CANCELLED`.

---

### TC-04: [Cận biên - Thành công] Mua hết sạch số lượng còn lại trong kho
- **Service**: Order Service (qua Gateway)
- **Method**: `POST`
- **URL**: `http://localhost:8088/api/orders`
- **Request Body** (Sản phẩm ID 4 có đúng 5 chiếc, mua hết cả 5):
  ```json
  {
    "productId": 4,
    "quantity": 5
  }
  ```
- **Kết quả mong đợi**:
  - HTTP Status: `201 CREATED`
  - Response Body:
    ```json
    {
      "productId": 4,
      "quantity": 5,
      "status": "COMPLETED",
      "totalPrice": 425000000.00,
      "message": "Order completed successfully"
    }
    ```
  - **Database**: Tồn kho `product` id = 4 giảm về đúng `0`.

---

### TC-05: [Thất bại] Đặt hàng với sản phẩm không tồn tại (Product Not Found)
- **Service**: Order Service (qua Gateway)
- **Method**: `POST`
- **URL**: `http://localhost:8088/api/orders`
- **Request Body**:
  ```json
  {
    "productId": 9999,
    "quantity": 1
  }
  ```
- **Kết quả mong đợi**:
  - HTTP Status: `201 CREATED`
  - Response Body:
    ```json
    {
      "productId": 9999,
      "quantity": 1,
      "status": "CANCELLED",
      "totalPrice": 0.00,
      "message": "Product not found with id: 9999"
    }
    ```
  - **Database**: Bảng `orders` lưu đơn hàng với `status = 'CANCELLED'`.

---

### TC-06: [Thất bại] Dữ liệu đầu vào không hợp lệ (Validation Bad Request)
- **Service**: Order Service (qua Gateway)
- **Method**: `POST`
- **URL**: `http://localhost:8088/api/orders`
- **Request Body** (Số lượng âm hoặc bằng 0):
  ```json
  {
    "productId": 1,
    "quantity": -2
  }
  ```
- **Kết quả mong đợi**:
  - HTTP Status: `400 BAD REQUEST`
  - Response Body: `ProductId and valid positive quantity are required`

---

### TC-07: Test trực tiếp Inventory Service - Lấy chi tiết sản phẩm
- **Method**: `GET`
- **URL**: `http://localhost:8088/api/inventory/1` (hoặc `http://localhost:8082/api/inventory/1`)
- **Kết quả mong đợi**:
  - HTTP Status: `200 OK`
  - Response Body:
    ```json
    {
      "id": 1,
      "productName": "iPhone 15 Pro 128GB",
      "quantity": 100,
      "price": 25000000.00
    }
    ```

---

### TC-08: Test trực tiếp Inventory Service - Tìm sản phẩm không tồn tại
- **Method**: `GET`
- **URL**: `http://localhost:8088/api/inventory/9999`
- **Kết quả mong đợi**:
  - HTTP Status: `404 NOT FOUND`
  - Response Body: `"Product not found with id: 9999"`

---

### TC-09: Test trực tiếp Inventory Service - Trừ kho thất bại
- **Method**: `PUT`
- **URL**: `http://localhost:8088/api/inventory/6/deduct?quantity=1`
- **Kết quả mong đợi**:
  - HTTP Status: `400 BAD REQUEST`
  - Response Body: `"Insufficient stock for product id: 6"`

---

### TC-10: Test Order Service - Lấy danh sách lịch sử đơn hàng
- **Method**: `GET`
- **URL**: `http://localhost:8088/api/orders`
- **Kết quả mong đợi**:
  - HTTP Status: `200 OK`
  - Danh sách trả về bao gồm các đơn hàng mẫu với cả 2 trạng thái `COMPLETED` và `CANCELLED`.
