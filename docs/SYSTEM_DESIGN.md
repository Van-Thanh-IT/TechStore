```markdown
# 🏗️ SYSTEM DESIGN & ARCHITECTURE DOCUMENTATION

Tài liệu này mô tả chi tiết kiến trúc tổng quan, các chiến lược thiết kế hệ thống, tối ưu hiệu năng và giải pháp xử lý bài toán chịu tải cao (High Concurrency) cho dự án **TechStore**.

---

## 1. TỔNG QUAN KIẾN TRÚC HỆ THỐNG (HIGH-LEVEL ARCHITECTURE)

Hệ thống được thiết kế theo mô hình **Monolithic Modular (Module-based Architecture)** hiện đại, sẵn sàng tách thành Microservices khi quy mô mở rộng.

```text
                               ┌─────────────────────────┐
                               │        React Client     │
                               └────────────┬────────────┘
                                            │ HTTP / WebSocket
                                            ▼
                               ┌─────────────────────────┐
                               │   Nginx Reverse Proxy   │
                               └────────────┬────────────┘
                                            │
                                            ▼
                               ┌─────────────────────────┐
                               │   Spring Boot Service   │
                               │  (REST API + Security)  │
                               └──────┬─────┬──────┬─────┘
                                      │     │      │
             ┌────────────────────────┘     │      └────────────────────────┐
             ▼                              ▼                               ▼
┌─────────────────────────┐   ┌─────────────────────────┐   ┌─────────────────────────┐
│     MySQL               │   │       Redis Cache       │   │    External Services    │
│  (ACID Data Store)      │   │  (Lock / Cache / Rate)  │   │ (Goship, VNPay, AI API) │
└─────────────────────────┘   └─────────────────────────┘   └─────────────────────────┘

```

---

## 2. LÝ DO LỰA CHỌN CÔNG NGHỆ (TECHNOLOGY RATIONALE)

* **Spring Boot (Java 21):** Đảm bảo tính ổn định, hỗ trợ Type-safe tốt, xử lý giao dịch (Transactions) chặt chẽ và có hệ sinh thái Spring Security/JPA rất mạnh cho ứng dụng doanh nghiệp.
* **MySQL 8.0** Đáp ứng tiêu chuẩn ACID khắt khe cho quản lý đơn hàng, kho hàng và dòng tiền thanh toán.
* **Redis 7.0:** Bộ nhớ In-Memory đóng vai trò lớp đệm chịu tải cho Flash Sale, Rate Limiting, Token Blacklist và Caching dữ liệu đọc nhiều.
* **Spring WebSocket (STOMP):** Duy trì kết nối hai chiều thời gian thực giữa Client và Admin/AI Chatbot.

---

## 3. CHIẾN LƯỢC CACHING VỚI REDIS (CACHING STRATEGY)

Để giảm áp lực I/O Disk xuống Database chính, hệ thống áp dụng chiến lược **Cache-Aside Pattern**:

```text
[Client] ──1. Request──► [Spring Boot]
                             │
                             ├──2. Check Redis ──(Hit)──► Trả kết quả ngay (< 2ms)
                             │
                             └──(Miss)──► Query DB ──► Save to Redis ──► Trả kết quả

```

### Các nhóm dữ liệu được Cache:

1. **Dữ liệu Đọc Nhiều (Read-Heavy Data):** Danh mục (`categories`), Thương hiệu (`brands`), Thông tin cấu hình hệ thống.
* *TTL (Time To Live):* 24 giờ (Evict/Invalidate khi Admin bấm Cập nhật).


2. **Chi tiết Sản phẩm HOT:**
* *TTL:* 1 giờ.


3. **JWT Blacklist & Session:**
* Lưu các Token đã vô hiệu hóa khi User bấm "Đăng xuất" cho đến khi Token hết hạn hoàn toàn.



---

## 4. GIẢI PHÁP XỬ LÝ HIGH CONCURRENCY FOR FLASH SALE

Bài toán: **1,000+ lượt request bấm "Mua ngay" trong 1 giây nhưng chỉ có 50 sản phẩm trong kho.**

### Giải pháp 2 lớp (Two-tier Protection):

#### Lớp 1: Chặn tải tại Redis (In-Memory Atomic Counter)

* Khi chiến dịch Flash Sale bắt đầu, số lượng tồn kho của `flash_sale_item_id` được nạp sẵn lên Redis (`SET flash_sale_stock:101 50`).
* Khi khách bấm mua, Spring Boot thực hiện giảm tồn kho trực tiếp trên Redis bằng lệnh Atomic:
```lua
-- Redis Lua Script giúp check và decrease nguyên tử
if redis.call('exists', KEYS[1]) == 1 then
    local stock = tonumber(redis.call('get', KEYS[1]))
    if stock > 0 then
        redis.call('decrby', KEYS[1], 1)
        return 1 -- Thành công
    end
end
return 0 -- Hết hàng

```


* Nếu Redis trả về `0` (Hết hàng), API ngắt ngay lập tức và trả lỗi về Frontend mà **không gọi xuống Database**.

#### Lớp 2: Bảo vệ CSDL MySQL bằng Ràng buộc DDL (Data Integrity)

* Bảng `flash_sale_orders` chứa `UNIQUE KEY (flash_sale_item_id, user_id)` để đảm bảo mỗi User chỉ mua thành công 1 lần.
* Bảng `flash_sale_items` áp dụng kiểm tra tồn kho khi Update:
```sql
UPDATE flash_sale_items 
SET sold_quantity = sold_quantity + 1 
WHERE id = :itemId AND sold_quantity < quantity;

```



---

## 5. TÍCH HỢP AI CHATBOT & LIVE CHAT HYBRID

Hệ thống xử lý tin nhắn qua 2 tầng linh hoạt:

1. **Bot / AI Mode:**
* Mặc định khi mở phòng chat, request được đẩy tới module AI Service (tích hợp Gemini/OpenAI API).
* Dữ liệu trả về dưới dạng JSON (`metadata`) chứa các Card sản phẩm, Nút hành động hoặc văn bản Markdown.


2. **Human Agent Switch Mode:**
* Khi khách yêu cầu gặp người thật hoặc AI không xử lý được, trạng thái phòng chuyển `chat_rooms.status = 'SUPPORTING'`.
* Hệ thống bắn event qua WebSocket thông báo tới Dashboard CSKH để Nhân viên tiếp nhận.



---

## 6. KHẢ NĂNG MỞ RỘNG (SCALABILITY & SECURITY)

* **Stateless API:** Backend thiết kế hoàn toàn Stateless, xác thực bằng JWT, giúp việc Scale-out (tăng số lượng Container Backend) đằng sau Nginx Load Balancer dễ dàng.
* **Rate Limiting:** Sử dụng Redis Bucket Algorithm để chặn IP/User cố tình spam request (Tối đa 60 requests/phút cho public API).
* **Data Security:** Mọi thông tin nhạy cảm (mật khẩu) mã hóa bằng BCrypt. Dữ liệu địa chỉ, hóa đơn VAT lưu dạng Snapshot trong bảng `orders` để tránh sai lệch dữ liệu khi thông tin Master bị sửa đổi.

```

```