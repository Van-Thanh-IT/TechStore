```markdown
# 🌐 ENVIRONMENT VARIABLES SPECIFICATION

Tài liệu này quản lý danh sách toàn bộ các biến môi trường (Environment Variables) được sử dụng trong hệ thống **TechStore** phía Backend (Spring Boot) và Frontend (React/Next.js).

---

## 1. FILE MẪU `.env.example` (GỐC DỰ ÁN)

Tạo file `.env` tại thư mục gốc dự án dựa trên template mẫu dưới đây:

```env
# ============================================================================
# 1. CORE APPLICATION CONFIGURATION
# ============================================================================
APP_NAME=TechStore
APP_ENV=development
APP_PORT=8080
APP_BASE_URL=http://localhost:8080

# ============================================================================
# 2. DATABASE CONFIGURATION (MYSQL / POSTGRESQL)
# ============================================================================
DB_HOST=localhost
DB_PORT=3306
DB_NAME=TechStore
DB_USERNAME=root
DB_PASSWORD=root_password
DB_POOL_MAX_SIZE=20

# ============================================================================
# 3. REDIS CACHE CONFIGURATION
# ============================================================================
REDIS_HOST=localhost
REDIS_PORT=6379
REDIS_PASSWORD=
REDIS_TIMEOUT=2000

# ============================================================================
# 4. SECURITY & JWT CONFIGURATION
# ============================================================================
# Chuỗi Secret Key mã hóa HS256 (Tối thiểu 256 bits / 32 ký tự)
JWT_SECRET=dGhpcy1pcy1hLXNlY3JldC1rZXktZm9yLXRlY2hzdG9yZS12YWxpdGF0aW9u
JWT_ACCESS_EXPIRATION=900000        # 15 phút (tính bằng milliseconds)
JWT_REFRESH_EXPIRATION=604800000    # 7 ngày (tính bằng milliseconds)

# ============================================================================
# 5. THIRD-PARTY API INTEGRATIONS
# ============================================================================
# Đơn vị vận chuyển Goship
GOSHIP_API_URL=[https://sandbox.goship.io/api/v2](https://sandbox.goship.io/api/v2)
GOSHIP_API_TOKEN=your_goship_bearer_token

# Cổng thanh toán VNPay (Sandbox)
VNPAY_TMN_CODE=YOUR_VNPAY_TMN_CODE
VNPAY_HASH_SECRET=YOUR_VNPAY_HASH_SECRET
VNPAY_PAY_URL=[https://sandbox.vnpayment.vn/paymentv2/vpcpay.html](https://sandbox.vnpayment.vn/paymentv2/vpcpay.html)
VNPAY_RETURN_URL=http://localhost:3000/checkout/vnpay-callback

# AI Engine (Google Gemini API)
GEMINI_API_KEY=AIzaSyYourGeminiApiKeyHere

# ============================================================================
# 6. FRONTEND ENVIRONMENT CONFIGURATION (Next.js)
# ============================================================================
VITE_PUBLIC_API_BASE_URL=http://localhost:8080/api/v1
VITE_PUBLIC_WS_URL=http://localhost:8080/ws

```

---

## 2. BẢNG MÔ TẢ CHI TIẾT CÁC BIẾN MÔI TRƯỜNG

| Tên Biến | Bắt Buộc | Giá Trị Mặc Định | Mô Tả & Bối Cảnh Sử Dụng |
| --- | --- | --- | --- |
| `APP_ENV` | Có | `development` | Môi trường hoạt động (`development`, `staging`, `production`). |
| `DB_HOST` | Có | `localhost` | Địa chỉ IP/Hostname CSDL. Trong Docker dùng `db`. |
| `DB_NAME` | Có | `TechStore` | Tên Database chính. |
| `REDIS_HOST` | Có | `localhost` | Địa chỉ IP/Hostname Redis Server. Trong Docker dùng `redis`. |
| `JWT_SECRET` | **Có** | *N/A* | Key bí mật mã hóa JWT. **Cấm commit key thật lên GitHub**. |
| `JWT_ACCESS_EXPIRATION` | Có | `900000` | Thời gian sống của Access Token (15 phút). |
| `GOSHIP_API_TOKEN` | Không | *N/A* | Bearer Token kết nối API Goship tính phí ship & tạo đơn. |
| `VNPAY_HASH_SECRET` | Không | *N/A* | Chữ ký checksum bảo mật thanh toán VNPay. |
| `GEMINI_API_KEY` | Không | *N/A* | API Key kết nối Google Gemini cho AI Chatbot. |

---

## 3. LƯU Ý BẢO MẬT (SECURITY RULES)

1. **Không commit file `.env` thực tế:** File `.env` phải luôn nằm trong danh sách `.gitignore`. Chỉ commit file `.env.example` chứa thông số mẫu.
2. **Khóa mã hóa JWT trên Production:** Trên môi trường Production, biến `JWT_SECRET` bắt buộc phải là một chuỗi ngẫu nhiên dài tối thiểu 64 ký tự và được inject thông qua Environment Variables của VPS / Docker Secret / CI-CD Pipeline.