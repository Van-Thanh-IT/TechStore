```markdown
# 🔌 RESTful API SPECIFICATION & DOCUMENTATION

Tài liệu này quy định chuẩn thiết kế API RESTful, định dạng Request/Response, quy chuẩn xử lý lỗi, phân trang và danh sách các Endpoints cốt lõi của hệ thống **TechStore**.

---

## 1. QUY CHUẨN THIẾT KẾ RESTful API

* **Base URL:** `https://api.techstore.com/api/v1` (hoặc `http://localhost:8080/api/v1` tại môi trường Local).
* **Format:** Bắt buộc gửi và nhận dữ liệu bằng `application/json; charset=UTF-8`.
* **Authentication:** Sử dụng **Bearer JWT Token** đặt trong Header:
  ```text
  Authorization: Bearer <access_token>

```

---

## 2. DẠNG PHẢN HỒI CHUẨN (STANDARD RESPONSE ENVELOPE)

Tất cả các API trong hệ thống đều trả về cấu trúc thống nhất giúp Frontend parse dữ liệu dễ dàng.

### 2.1. Phản hồi Thành công (Success Response - HTTP 200/201)

```json
{
  "code": 200,
  "message": "Thao tác thành công",
  "data": { ... },
  "timestamp": "2026-08-11T22:30:00Z"
}

```

### 2.2. Phản hồi Phân trang (Paginated Response)

```json
{
  "code": 200,
  "message": "Lấy danh sách thành công",
  "data": {
    "content": [ ... ],
    "page": 0,
    "size": 10,
    "total_elements": 45,
    "total_pages": 5,
    "is_last": false
  },
  "timestamp": "2026-08-11T22:30:00Z"
}

```

### 2.3. Phản hồi Lỗi (Error Response - HTTP 4xx/5xx)

```json
{
  "code": 400,
  "error_code": "ERR_VOUCHER_EXPIRED",
  "message": "Mã giảm giá đã hết hạn sử dụng",
  "errors": [
    {
      "field": "code",
      "message": "Voucher HOANGHA2026 đã hết hạn từ ngày 10/08/2026"
    }
  ],
  "timestamp": "2026-08-11T22:30:00Z"
}

```

---

## 3. BẢNG MÃ LỖI NGHIỆP VỤ (BUSINESS ERROR CODES)

| Error Code | HTTP Status | Description |
| --- | --- | --- |
| `ERR_AUTH_EXPIRED` | 401 | Token JWT đã hết hạn |
| `ERR_FORBIDDEN` | 403 | Không có quyền truy cập resource này |
| `ERR_RESOURCE_NOT_FOUND` | 404 | Khái niệm/Dữ liệu không tồn tại |
| `ERR_OUT_OF_STOCK` | 400 | Tồn kho sản phẩm/variant không đủ |
| `ERR_VOUCHER_INVALID` | 400 | Mã voucher không đúng hoặc không thỏa điều kiện đơn giá |
| `ERR_FLASH_SALE_LIMIT` | 409 | Người dùng đã mua vượt quá giới hạn Flash Sale |

---

## 4. DANH SÁCH ENDPOINTS CỐT LÕI (CORE ENDPOINTS)

### 4.1. Authentication (`/auth`)

* `POST /auth/register`: Đăng ký tài khoản người dùng mới.
* `POST /auth/login`: Đăng nhập lấy `accessToken` và `refreshToken`.
* `POST /auth/refresh-token`: Cấp mới Access Token khi hết hạn.
* `POST /auth/logout`: Đăng xuất (Đưa Token vào Redis Blacklist).

### 4.2. Products & Catalog (`/products`, `/categories`)

* `GET /products`: Lấy danh sách sản phẩm (Filter theo brand, category, giá, sắp xếp).
* `GET /products/{slug}`: Lấy chi tiết sản phẩm, biến thể (SKU) và thuộc tính EAV.
* `GET /categories`: Lấy cây danh mục sản phẩm.

### 4.3. Flash Sale (`/flash-sale`)

* `GET /flash-sale/active`: Lấy đợt Flash Sale đang diễn ra kèm danh sách SKU.
* `POST /flash-sale/buy`: Bấm mua nhanh Flash Sale (Tích hợp Redis Atomic Counter).
* **Header:** `Authorization: Bearer <token>`
* **Body:**
```json
{
  "flash_sale_item_id": 102,
  "quantity": 1
}

```

### 4.4. Vouchers & Promotion (`/vouchers`)

* `GET /vouchers/my-wallet`: Lấy danh sách Ví Voucher cá nhân (`is_public = FALSE`). *(Yêu cầu Login)*
* `POST /vouchers/apply`: Kiểm tra và áp dụng mã giảm giá tại Checkout.
* **Body:**
```json
{
  "code": "SUMMER2026",
  "order_amount": 15000000,
  "customer_phone": "0987654321"
}

```

### 4.5. Cart & Orders (`/cart`, `/orders`)

* `GET /cart`: Lấy giỏ hàng hiện tại (hỗ trợ cả Session Guest & User Token).
* `POST /cart/items`: Thêm/Cập nhật sản phẩm vào giỏ hàng.
* `POST /orders/checkout`: Đặt hàng (Checkout).
* **Body:**
```json
{
  "voucher_id": 5,
  "customer_name": "Nguyễn Văn Thành",
  "customer_phone": "0987654321",
  "customer_email": "thanhnv@gmail.com",
  "shipping_address": "Số 123 Đường Xuân Thủy",
  "shipping_ward": "Dịch Vọng Hậu",
  "shipping_district": "Cầu Giấy",
  "shipping_city": "Hà Nội",
  "shipping_ward_code": "20101",
  "shipping_district_code": "1442",
  "shipping_city_code": "201",
  "is_vat_required": true,
  "company_name": "CÔNG TY TNHH TECHSTORE",
  "tax_code": "0101234567",
  "company_address": "Số 123 Đường Xuân Thủy, Cầu Giấy, Hà Nội",
  "company_email": "ketoan@techstore.com",
  "payment_method": "VNPAY",
  "items": [
    { "variant_id": 501, "quantity": 1 }
  ]
}

```

* `GET /orders/my-orders`: Xem lịch sử đơn hàng của User.
* `PUT /orders/{code}/cancel`: Hủy đơn hàng (Khi đơn ở trạng thái `PENDING`).

### 4.6. Live Chat & AI Support (`/chat`)

* `POST /chat/rooms`: Khởi tạo phòng chat mới cho Guest/User.
* `GET /chat/rooms/{roomId}/messages`: Tải lịch sử tin nhắn phòng chat.
* `WS /ws/chat`: Endpoint WebSocket (STOMP) phục vụ gửi/nhận tin nhắn Real-time.

```

```