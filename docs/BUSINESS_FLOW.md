```markdown
# 🔄 BUSINESS FLOW & SEQUENCE DIAGRAMS

Tài liệu này mô tả chi tiết các luồng xử lý nghiệp vụ chính trong hệ thống **TechStore** bằng sơ đồ tuần tự (Sequence Diagram) và quy trình xử lý phía Backend.

---

## 1. LUỒNG ĐẶT HÀNG & TRỪ TỒN KHO (ORDER & STOCK RESERVATION)

Áp dụng cho cả khách hàng đã đăng nhập (**Member**) và khách mua nhanh (**Guest**).

```mermaid
sequenceDiagram
    autonumber
    actor Client as Khách hàng (FE)
    participant API as Spring Boot Controller
    participant Service as Order Service
    participant DB as Database (MySQL/Postgres)
    participant Ship as Goship API

    Client->>API: POST /api/v1/orders (Thông tin giỏ hàng + Địa chỉ + VAT)
    API->>Service: Execute createOrder()
    
    Service->>DB: Check tồn kho trong `inventory`
    alt Tồn kho < Số lượng mua
        Service-->>Client: Trả lỗi "Sản phẩm đã hết hàng"
    else Tồn kho đủ
        Service->>Ship: Gọi API tính chính xác phí ship
        Ship-->>Service: Trả về phí ship & mã vận đơn tạm
        Service->>DB: Lưu bản ghi `orders` & `order_items` (Snapshot)
        Service->>DB: Trừ tồn kho thực tế trong `inventory`
        
        opt Nếu dùng Voucher
            Service->>DB: Cập nhật `used_count` hoặc `user_vouchers.status = USED`
        end
        
        Service-->>Client: Trả về Order Code & Thông tin thanh toán
    end

```

---

## 2. LUỒNG MUA HÀNG FLASH SALE CHỊU TẢI CAO (HIGH-CONCURRENCY FLASH SALE)

Sử dụng **Redis Lua Script** để kiểm tra và trừ lượt Atomic trên RAM trước khi chạm xuống CSDL.

```mermaid
sequenceDiagram
    autonumber
    actor Client as Khách hàng
    participant API as Spring Boot Controller
    participant Redis as Redis Cache
    participant Queue as Async Order Task
    participant DB as Database (MySQL/Postgres)

    Client->>API: POST /api/v1/flash-sale/buy (flash_sale_item_id, user_id)
    
    API->>Redis: Execute Lua Script (Check & Decrby Stock)
    alt Stock <= 0 (Hết hàng trên Redis)
        Redis-->>API: Return 0
        API-->>Client: Trả lỗi "Rất tiếc, sản phẩm Flash Sale đã hết!"
    else Stock > 0 (Trừ lượt thành công)
        Redis-->>API: Return 1
        API->>Queue: Đẩy Request vào Hàng đợi xử lý ngầm
        API-->>Client: Trả về "Đang xử lý đơn hàng Flash Sale..."
        
        Queue->>DB: INSERT INTO `flash_sale_orders` (Check UNIQUE KEY user_id + item_id)
        alt Bị trùng lặp User (Gõ tool mua 2 lần)
            DB-->>Queue: Rollback / Exception
            Queue->>Redis: Hoàn lại stock (INCRBY +1)
        else Mua hợp lệ
            Queue->>DB: Tạo `orders` & Tăng `sold_quantity` trong `flash_sale_items`
        end
    end

```

---

## 3. LUỒNG ÁP DỤNG MÃ GIẢM GIÁ (PUBLIC VS PRIVATE VOUCHER)

Phân định rõ ràng cách xử lý mã Public (nhập tay) và mã Private (Ví Voucher).

```mermaid
sequenceDiagram
    autonumber
    actor Client as Khách hàng
    participant API as Voucher Controller
    participant DB as Database

    Client->>API: POST /api/v1/vouchers/apply (code, orderAmount, phone)
    API->>DB: Query mã trong bảng `vouchers` WHERE code = :code
    
    alt Code không tồn tại hoặc hết hạn
        DB-->>API: Null / Expired
        API-->>Client: Báo lỗi "Mã giảm giá không hợp lệ"
    else Code hợp lệ
        alt is_public = TRUE (Mã công khai)
            API->>DB: Check số lần SĐT đã dùng trong `orders`
            alt SĐT đã dùng >= limit_per_customer
                API-->>Client: Báo lỗi "Số điện thoại này đã áp dụng mã"
            else Hợp lệ
                API-->>Client: Trả về số tiền được giảm (`discount_amount`)
            end
        else is_public = FALSE (Mã cá nhân)
            alt Guest chưa Login
                API-->>Client: Yêu cầu đăng nhập để sử dụng mã này
            else Member đã Login
                API->>DB: Check `user_vouchers` WHERE user_id AND status = 'UNUSED'
                alt Không tìm thấy trong ví
                    API-->>Client: Báo lỗi "Voucher không thuộc tài khoản của bạn"
                else Tìm thấy
                    API-->>Client: Trả về số tiền được giảm
                end
            end
        end
    end

```

---

## 4. LUỒNG LIVE CHAT TƯ VẤN (HYBRID AI CHATBOT & HUMAN AGENT)

Chuyển đổi linh hoạt giữa Trợ lý AI và Nhân viên CSKH thực tế qua WebSocket.

```mermaid
sequenceDiagram
    autonumber
    actor Client as Khách hàng
    participant WS as WebSocket Server
    participant AI as AI Engine (Gemini API)
    participant Admin as Staff CSKH Dashboard

    Client->>WS: Gửi tin nhắn "Tư vấn cho tôi iPhone giá tầm 15tr"
    
    alt Room Status = 'WAITING' (Đang chat với Bot)
        WS->>AI: Call Gemini API (với context sản phẩm)
        AI-->>WS: Trả về Text + JSON Metadata (Cards sản phẩm)
        WS-->>Client: Hiển thị tin nhắn dạng Card Carousel (sender_type = 'BOT')
    end

    Client->>WS: Bấm nút "Gặp nhân viên tư vấn"
    WS->>WS: Đổi status phòng -> 'SUPPORTING'
    WS->>Admin: Push Event "Phòng chat #102 cần hỗ trợ" (Broadcast CSKH)
    
    Admin->>WS: Nhân viên A bấm "Tiếp nhận"
    Admin->>WS: Gửi tin nhắn "Em chào anh, em có thể hỗ trợ gì ạ?"
    WS-->>Client: Render tin nhắn từ Nhân viên (sender_type = 'STAFF')

```

```

```