```markdown
# 🎨 UI/UX DESIGN SYSTEM & GUIDELINES

Tài liệu này quy định hệ thống thiết kế giao diện (Design System), Bảng màu chuẩn, Quy chuẩn Typography, Breakpoints Responsive và Hướng dẫn Trải nghiệm Người dùng (UX Guidelines) cho ứng dụng **TechStore**.

---

## 1. BẢNG MÀU CHUẨN (COLOR PALETTE)

Hệ thống sử dụng bảng màu thương hiệu mang phong cách hiện đại, tối giản và tạo cảm giác tin cậy cho mảng Bán lẻ Điện tử & Công nghệ.

| Nhóm Màu | Tên Màu | Mã Hex | Ứng Dụng Thực Tế |
| :--- | :--- | :--- | :--- |
| **Primary** | Tech Blue | `#0056B3` | Header, Nút hành động chính (Primary CTA), Link active |
| **Secondary** | Dark Slate | `#1E293B` | Sidebar Admin, Text tiêu đề (Headings), Footer |
| **Accent / Highlight** | Flash Orange | `#FF6B00` | Badge Flash Sale, Nút "Mua ngay", Giá khuyến mãi |
| **Success** | Emerald Green | `#10B981` | Thông báo thành công, Trạng thái đơn "Đã giao" |
| **Warning** | Amber Yellow | `#F59E0B` | Trạng thái đơn "Đăng xử lý", Cảnh báo tồn kho thấp |
| **Danger / Error** | Crimson Red | `#EF4444` | Thông báo lỗi, Nút "Hủy đơn", Badge hết hàng |
| **Background / Surface** | Cool Gray | `#F8FAFC` | Nền trang web (Body background), Card background |

---

## 2. FONTS & TYPOGRAPHY

* **Font Family Chính:** `Inter`, `-apple-system`, `BlinkMacSystemFont`, `Segoe UI`, `Roboto`, `sans-serif`.
* **Quy chuẩn Font Size & Weight:**

| Cấp Độ | Kích Thước (Font Size) | Line Height | Font Weight | Scope Sử Dụng |
| :--- | :--- | :--- | :--- | :--- |
| **Display / Hero** | `32px` (`2rem`) | `1.2` | Bold (`700`) | Banner Hero, Tiêu đề đợt Flash Sale |
| **Heading 1 (H1)** | `24px` (`1.5rem`) | `1.3` | SemiBold (`600`) | Tên sản phẩm chi tiết, Title trang |
| **Heading 2 (H2)** | `20px` (`1.25rem`) | `1.4` | SemiBold (`600`) | Tiêu đề Section (Sản phẩm nổi bật, Review) |
| **Body Large** | `16px` (`1rem`) | `1.5` | Regular (`400`) | Giá tiền sản phẩm, Mô tả nổi bật |
| **Body Normal** | `14px` (`0.875rem`) | `1.5` | Regular (`400`) | Văn bản nội dung, Thông số kỹ thuật |
| **Caption / Small** | `12px` (`0.75rem`) | `1.4` | Medium (`500`) | Badge trạng thái, Timestamp tin nhắn chat |

---

## 3. RESPONSIVE BREAKPOINTS

Thiết kế ưu tiên mô hình **Mobile-First Responsive**:

* **Mobile (SM):** `< 640px` (Giao diện 1 cột, Bottom Navigation Bar cho Mobile App/Web).
* **Tablet (MD):** `640px - 1023px` (Lưới sản phẩm 2-3 cột, Drawer Menu cho Sidebar).
* **Desktop (LG):** `1024px - 1279px` (Lưới sản phẩm 4 cột, Mega Menu hiển thị đầy đủ).
* **Large Desktop (XL):** `≥ 1280px` (Container max-width `1200px` căn giữa màn hình, Lưới 5 cột).

---

## 4. QUY CHUẨN TRẢI NGHIỆM NGƯỜI DÙNG (UX GUIDELINES)

### 4.1. Quy chuẩn Checkout Stepper (Đặt hàng 3 bước)
Tách rõ quá trình thanh toán thành 3 bước minh bạch giúp hạ thấp tỷ lệ bỏ giỏ hàng (Cart Abandonment):
1. **Bước 1 (Giỏ hàng):** Xem danh sách SP, Chọn/Nhập Mã giảm giá (Public/Ví).
2. **Bước 2 (Giao hàng & VAT):** Nhập/Chọn địa chỉ nhận hàng, Tùy chọn tích xuất Hóa đơn Công ty (VAT).
3. **Bước 3 (Thanh toán):** Chọn Phương thức (COD, VNPay, MoMo) & Xác nhận tạo đơn.

### 4.2. Quy chuẩn Khung Live Chat / AI Support Widget
* Flash Widget nằm cố định tại góc dưới bên phải màn hình (`bottom: 24px`, `right: 24px`).
* Bán kính góc bo (Border Radius): `16px` tạo cảm giác thân thiện.
* Phân biệt bong bóng tin nhắn:
  * **User / Guest:** Nằm bên tay phải, Nền màu `Tech Blue` (`#0056B3`), Chữ màu trắng.
  * **AI Bot / CSKH:** Nằm bên tay trái, Nền màu xám nhẹ (`#F1F5F9`), Chữ màu đen, có Icon Robot / Badge CSKH.

### 4.3. Feedback & Loading States (Tương tác Tức thì)
* **Skeleton Loading:** Sử dụng Skeleton Screen dạng màu xám nhấp nháy cho Lưới sản phẩm trong lúc đợi API trả về (thay vì Spinner xoay vòng).
* **Optimistic UI Update:** Khi bấm "Thêm vào giỏ hàng", icon Giỏ hàng lập tức nhảy số lượng `+1` trước khi API ghi xuống Redis/Database hoàn tất.
* **Toast Notification:** Hiển thị thông báo Toast ở góc trên bên phải màn hình, tự động ẩn sau `3 giây`.

```