```markdown
# ⚠️ ERROR HANDLING & EXCEPTION SPECIFICATION

Tài liệu này quy định chiến lược xử lý ngoại lệ (Exception Handling) tập trung, cấu trúc Response Lỗi tiêu chuẩn và Danh mục Mã lỗi Nghiệp vụ (Business Error Codes) toàn hệ thống **TechStore**.

---

## 1. TỔNG QUAN CHIẾN LƯỢC XỬ LÝ LỖI

Hệ thống áp dụng cơ chế **Global Exception Handling** trong Spring Boot sử dụng `@RestControllerAdvice` và `@ExceptionHandler` để bắt tất cả các ngoại lệ từ tầng Controller, Service đến Repository.

### Nguyên tắc thiết kế:
* **Không để lộ Exception StackTrace:** Mọi lỗi hệ thống (như SQL Syntax, NullPointerException) đều được bọc lại bằng mã lỗi thân thiện để bảo mật thông tin nội bộ.
* **Đồng nhất Cấu trúc JSON Lỗi:** Mọi API lỗi đều trả về cùng một format định dạng, giúp Frontend hiển thị Toast/Alert dễ dàng.
* **HTTP Status Code chuẩn:** Kết hợp giữa mã HTTP Status chuẩn (400, 401, 403, 404, 409, 500) và mã Error Code nghiệp vụ riêng biệt.

---

## 2. CẤU TRÚC PHẢN HỒI LỖI CHUẨN (ERROR PAYLOAD FORMAT)

### 2.1. Cấu trúc Lỗi Chung (General Error)
```json
{
  "code": 400,
  "error_code": "ERR_VOUCHER_EXPIRED",
  "message": "Mã giảm giá đã hết hạn sử dụng",
  "errors": null,
  "timestamp": "2026-08-11T22:45:00Z"
}

```

### 2.2. Cấu trúc Lỗi Validation Dữ liệu Đầu vào (HTTP 400 Bad Request)

Trả về khi Spring Validation (`@Valid`, `@NotNull`, `@Min`...) phát hiện dữ liệu Request Body/Query không hợp lệ:

```json
{
  "code": 400,
  "error_code": "ERR_INVALID_INPUT",
  "message": "Dữ liệu gửi lên không đúng định dạng",
  "errors": [
    {
      "field": "customer_phone",
      "message": "Số điện thoại không đúng định dạng 10 chữ số"
    },
    {
      "field": "items[0].quantity",
      "message": "Số lượng mua phải lớn hơn 0"
    }
  ],
  "timestamp": "2026-08-11T22:45:00Z"
}

```

---

## 3. DANH MỤC MÃ LỖI NGHIỆP VỤ (BUSINESS ERROR DICTIONARY)

### 3.1. Hệ thống & Xác thực Auth (`ERR_AUTH_*`, `ERR_SYS_*`)

| Error Code | HTTP Status | Message Mặc Định | Mô Tả & Bối Cảnh |
| --- | --- | --- | --- |
| `ERR_SYS_INTERNAL` | 500 | Lỗi hệ thống nội bộ, vui lòng thử lại sau | Lỗi không xác định hoặc Uncaught Exception |
| `ERR_INVALID_INPUT` | 400 | Dữ liệu không hợp lệ | Lỗi Validation từ Frontend |
| `ERR_AUTH_UNAUTHORIZED` | 401 | Yêu cầu xác thực tài khoản | Chưa gửi Token hoặc Token không hợp lệ |
| `ERR_AUTH_EXPIRED` | 401 | Phiên đăng nhập đã hết hạn | Token JWT đã quá hạn |
| `ERR_AUTH_FORBIDDEN` | 403 | Bạn không có quyền thực hiện thao tác này | Tài khoản không có Role/Permission phù hợp |

### 3.2. Khuyến mãi & Voucher (`ERR_VOUCHER_*`)

| Error Code | HTTP Status | Message Mặc Định | Mô Tả & Bối Cảnh |
| --- | --- | --- | --- |
| `ERR_VOUCHER_NOT_FOUND` | 404 | Mã giảm giá không tồn tại | Khách nhập sai code |
| `ERR_VOUCHER_EXPIRED` | 400 | Mã giảm giá đã hết hạn | Thời gian hiện tại ngoài start/end date |
| `ERR_VOUCHER_OUT_OF_LIMIT` | 400 | Mã giảm giá đã hết lượt sử dụng | `used_count >= usage_limit` |
| `ERR_VOUCHER_MIN_AMOUNT` | 400 | Giá trị đơn hàng chưa đủ điều kiện áp dụng | Đơn hàng nhỏ hơn `min_order_value` |
| `ERR_VOUCHER_CUSTOMER_LIMIT` | 400 | Bạn đã sử dụng hết lượt mã giảm giá này | SĐT/User đã dùng quá `limit_per_customer` |
| `ERR_VOUCHER_NOT_OWNED` | 403 | Mã giảm giá không nằm trong ví của bạn | Voucher cá nhân (`is_public = FALSE`) không khớp `user_id` |

### 3.3. Flash Sale & Tồn Kho (`ERR_FLASH_*`, `ERR_STOCK_*`)

| Error Code | HTTP Status | Message Mặc Định | Mô Tả & Bối Cảnh |
| --- | --- | --- | --- |
| `ERR_STOCK_OUT` | 400 | Sản phẩm đã hết hàng trong kho | Tồn kho `inventory` = 0 |
| `ERR_FLASH_SOLD_OUT` | 400 | Rất tiếc, sản phẩm Flash Sale đã hết lượt mua | Redis Atomic Counter = 0 |
| `ERR_FLASH_USER_LIMIT` | 409 | Bạn đã mua tối đa số lượng Flash Sale cho phép | Vi phạm `UNIQUE KEY` trong `flash_sale_orders` |
| `ERR_FLASH_NOT_ACTIVE` | 400 | Chương trình Flash Sale chưa bắt đầu hoặc đã kết thúc | Khung giờ không hợp lệ |

### 3.4. Đơn hàng & Giao dịch (`ERR_ORDER_*`, `ERR_PAYMENT_*`)

| Error Code | HTTP Status | Message Mặc Định | Mô Tả & Bối Cảnh |
| --- | --- | --- | --- |
| `ERR_ORDER_NOT_FOUND` | 404 | Không tìm thấy thông tin đơn hàng | Mã đơn hàng không có trong DB |
| `ERR_ORDER_CANNOT_CANCEL` | 400 | Đơn hàng đã đóng gói hoặc đang vận chuyển, không thể hủy | Hủy đơn khi `order_status != PENDING` |
| `ERR_PAYMENT_FAILED` | 400 | Giao dịch thanh toán không thành công | Cổng VNPay/MoMo trả về lỗi thất bại |

---

## 4. CODE MINH HỌA XỬ LÝ TRONG SPRING BOOT

### Custom Exception Class

```java
@Getter
public class BusinessException extends RuntimeException {
    private final String errorCode;
    private final HttpStatus httpStatus;

    public BusinessException(String errorCode, String message, HttpStatus httpStatus) {
        super(message);
        this.errorCode = errorCode;
        this.httpStatus = httpStatus;
    }
}

```

### Global Controller Advice

```java
@RestControllerAdvice
@Slf4j
public class GlobalExceptionHandler {

    // 1. Bắt lỗi Nghiệp vụ Custom
    @ExceptionHandler(BusinessException.class)
    public ResponseEntity<ErrorResponse> handleBusinessException(BusinessException ex) {
        ErrorResponse response = ErrorResponse.builder()
                .code(ex.getHttpStatus().value())
                .errorCode(ex.getErrorCode())
                .message(ex.getMessage())
                .timestamp(Instant.now())
                .build();
        return new ResponseEntity<>(response, ex.getHttpStatus());
    }

    // 2. Bắt lỗi Validation Body (@Valid)
    @ExceptionHandler(MethodArgumentNotValidException.class)
    public ResponseEntity<ErrorResponse> handleValidationException(MethodArgumentNotValidException ex) {
        List<ErrorDetail> details = ex.getBindingResult().getFieldErrors().stream()
                .map(error -> new ErrorDetail(error.getField(), error.getDefaultMessage()))
                .collect(Collectors.toList());

        ErrorResponse response = ErrorResponse.builder()
                .code(HttpStatus.BAD_REQUEST.value())
                .errorCode("ERR_INVALID_INPUT")
                .message("Dữ liệu không hợp lệ")
                .errors(details)
                .timestamp(Instant.now())
                .build();
        return ResponseEntity.badRequest().body(response);
    }
}

```

```

```