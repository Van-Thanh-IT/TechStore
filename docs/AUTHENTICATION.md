```markdown
# 🔐 AUTHENTICATION & AUTHORIZATION SPECIFICATION

Tài liệu này mô tả chi tiết cơ chế Xác thực (Authentication), Phân quyền (Authorization), Luồng xử lý JSON Web Token (JWT) và Ma trận Phân quyền theo Vai trò (RBAC) cho hệ thống **TechStore**.

---

## 1. TỔNG QUAN KIẾN TRÚC BẢO MẬT

Hệ thống bảo mật sử dụng **Spring Security** kết hợp **JWT Stateless Architecture**:
* **Access Token:** Hạn ngắn (15 phút), chứa Claims phân quyền (`role`, `user_id`), dùng để gửi kèm trong mỗi HTTP Request.
* **Refresh Token:** Hạn dài (7 ngày), lưu an toàn trong Database / HTTP-Only Cookie, dùng để xin cấp mới Access Token khi hết hạn.
* **Token Revocation (Blacklist):** Lưu trên **Redis** để vô hiệu hóa ngay lập tức Access Token khi người dùng bấm "Đăng xuất" hoặc bị Khóa tài khoản.

---

## 2. LUỒNG XÁC THỰC JWT (JWT AUTHENTICATION FLOW)

### 2.1. Luồng Đăng nhập (Login Flow)

```text
[Client] ──────1. POST /api/v1/auth/login ──────► [Spring Security]
                                                         │
                                               2. Authenticate User
                                                         │
[Client] ◄───3. Return {accessToken, refreshToken} ──────┘

```

### 2.2. Luồng Cấp lại Token khi hết hạn (Sliding Expiration / Refresh Token Flow)

```text
[Client] ──1. Request API với Expired AccessToken ──► [Spring Boot Filter]
                                                              │
[Client] ◄──────2. Return HTTP 401 Unauthorized ──────────────┘
   │
   ├──3. POST /api/v1/auth/refresh-token (kèm RefreshToken) ──► [Auth Service]
                                                                      │
                                                           4. Validate RefreshToken
                                                                      │
[Client] ◄────────5. Return NEW AccessToken ──────────────────────────┘

```

### 2.3. Luồng Đăng xuất & Vô hiệu hóa Token (Logout & Blacklist Flow)

When người dùng bấm Đăng xuất:

1. Client gửi `POST /api/v1/auth/logout` kèm Access Token hiện tại.
2. Spring Boot lấy thời gian còn lại (TTL) của Token và ghi Key vào Redis:
`SETEX jwt_blacklist:<jti_or_token> <remaining_ttl> "revoked"`
3. Mọi request tiếp theo sử dụng Token này đều bị **JwtFilter** chặn ngay từ tầng lọc của Spring Security.

---

## 3. MA TRẬN PHÂN QUYỀN VAI TRÒ (RBAC MATRIX)

Hệ thống chia làm 5 vai trò chính:

* `ADMIN`: Quản trị viên toàn quyền hệ thống.
* `STAFF`: Nhân viên bán hàng & Chăm sóc khách hàng (CSKH/Live Chat).
* `WAREHOUSE`: Nhân viên Kho (Quản lý nhập/xuất kho, quét mã IMEI/Serial).
* `USER`: Thành viên đã Đăng ký & Xác thực.
* `GUEST`: Khách vãng lai chưa đăng nhập.

| Chức năng / Resource | GUEST | USER | WAREHOUSE | STAFF | ADMIN |
| --- | --- | --- | --- | --- | --- |
| Xem Sản phẩm, Danh mục, Flash Sale | ✅ | ✅ | ✅ | ✅ | ✅ |
| Đặt hàng nhanh (Guest Checkout) | ✅ | ✅ | ❌ | ❌ | ❌ |
| Xem Ví Voucher, Lịch sử Đơn cá nhân | ❌ | ✅ | ❌ | ❌ | ❌ |
| Chat với AI Bot / CSKH | ✅ | ✅ | ❌ | ✅ | ✅ |
| Quản lý Đơn hàng (Duyệt, Đổi trạng thái) | ❌ | ❌ | ❌ | ✅ | ✅ |
| Nhập / Xuất kho, Scan IMEI/Serial | ❌ | ❌ | ✅ | ❌ | ✅ |
| Quản lý Flash Sale & Voucher Master | ❌ | ❌ | ❌ | ❌ | ✅ |
| Cấu hình Phân quyền (Roles/Permissions) | ❌ | ❌ | ❌ | ❌ | ✅ |

---

## 4. CẤU TRÚC PAYLOAD JWT (JWT TOKEN STRUCTURE)

### Header

```json
{
  "alg": "HS256",
  "typ": "JWT"
}

```

### Payload (Claims)

```json
{
  "sub": "thanhnv@gmail.com",
  "user_id": 102,
  "role": "ROLE_USER",
  "full_name": "Nguyễn Văn Thành",
  "iss": "TechStoreAPI",
  "iat": 1786392000,
  "exp": 1786392900
}

```

---

## 5. BẢO MẬT & BẢO VỆ DỮ LIỆU (SECURITY BEST PRACTICES)

1. **Mã hóa Mật khẩu:** Mật khẩu lưu trong CSDL bắt buộc dùng thuật toán **BCrypt** với Salting ngẫu nhiên (`PasswordEncoder`).
2. **Cấu hình CORS:** Chỉ cho phép các Domain được tin tưởng (Ví dụ: `https://techstore.com` hoặc `http://localhost:3000`) gọi API.
3. **Bảo vệ CSRF:** Vì API thiết kế hoàn toàn Stateless (không dùng Session lưu trên Server), cấu hình `http.csrf(AbstractHttpConfigurer::disable)` trong Spring Security.
4. **Giới hạn Thử lại OTP (`password_resets`):** Khóa chức năng lấy lại mật khẩu nếu nhập sai quá 5 lần liên tiếp.

```

```