```markdown
# 🧪 TESTING STRATEGY & BENCHMARK SPECIFICATION

Tài liệu này quy định chiến lược kiểm thử toàn diện, cấu trúc Test Cases, hướng dẫn chạy Unit/Integration Test và Kịch bản Test Tải (Load/Performance Testing) chịu tải cao cho hệ thống **TechStore**.

---

## 1. STRATEGY & TEST PYRAMID (MÔ HÌNH KIỂM THỬ)

Hệ thống tuân thủ mô hình Kim tự tháp Kiểm thử (Test Pyramid) với tỷ lệ bao phủ (Test Coverage) target $\ge 80\%$:

```text
               / \
              /   \     E2E / UI Tests ( Cypress / Playwright ) ~ 10%
             /-----\
            /       \   Integration Tests ( SpringBootTest / Testcontainers ) ~ 30%
           /---------\
          /           \ Unit Tests ( JUnit 5 / Mockito / AssertJ ) ~ 60%
         /-------------\

```

---

## 2. UNIT & INTEGRATION TESTING

### 2.1. Công nghệ Sử dụng

* **Unit Test:** JUnit 5, Mockito, AssertJ.
* **Integration Test:** `@SpringBootTest`, `@AutoConfigureMockMvc`, **Testcontainers** (khởi chạy Postgres/MySQL & Redis thật trong Docker để test DB/Cache mà không cần dùng In-memory H2).

### 2.2. Lệnh Chạy Test (CLI)

```bash
# 1. Chạy toàn bộ Unit Test
./mvnw test

# 2. Chạy Integration Test cụ thể
./mvnw test -Dtest=OrderIntegrationTest

# 3. Xuất Báo cáo Bao phủ Code (JaCoCo Coverage Report)
./mvnw clean test jacoco:report
# Xem báo cáo tại: target/site/jacoco/index.html

```

---

## 3. SAMPLE TEST CASES (CÁC KỊCH BẢN KIỂM THỬ CỐT LÕI)

### 3.1. Test Case: Áp dụng Voucher Khuyến mãi (`VoucherServiceTest`)

```java
@ExtendWith(MockitoExtension.class)
class VoucherServiceTest {

    @Mock
    private VoucherRepository voucherRepository;

    @InjectMocks
    private VoucherService voucherService;

    @Test
    @DisplayName("Nên ném ngoại lệ khi áp dụng Voucher đã hết hạn")
    void applyVoucher_Expired_ShouldThrowException() {
        // Given (Giả lập dữ liệu)
        Voucher expiredVoucher = Voucher.builder()
                .code("EXPIRED100K")
                .startDate(LocalDateTime.now().minusDays(10))
                .endDate(LocalDateTime.now().minusDays(1)) // Đã hết hạn ngày hôm qua
                .build();

        when(voucherRepository.findByCode("EXPIRED100K")).thenReturn(Optional.of(expiredVoucher));

        // When & Then (Kiểm tra ngoại lệ)
        BusinessException exception = assertThrows(BusinessException.class, () -> {
            voucherService.applyVoucher("EXPIRED100K", new BigDecimal("500000"), "0987654321");
        });

        assertThat(exception.getErrorCode()).isEqualTo("ERR_VOUCHER_EXPIRED");
    }
}

```

### 3.2. Test Case: Chống Mua Trùng / Race Condition Flash Sale

```java
@SpringBootTest
@Testcontainers
class FlashSaleConcurrencyTest {

    @Autowired
    private FlashSaleService flashSaleService;

    @Test
    @DisplayName("Xử lý 10 Concurrent Requests từ 1 User - Chỉ duy nhất 1 Request thành công")
    void buyFlashSale_ConcurrentRequestsFromSameUser_OnlyOneSucceeds() throws InterruptedException {
        int numberOfThreads = 10;
        ExecutorService executorService = Executors.newFixedThreadPool(numberOfThreads);
        CountDownLatch latch = new CountDownLatch(numberOfThreads);
        AtomicInteger successCount = new AtomicInteger(0);

        Long flashSaleItemId = 102L;
        Long userId = 99L;

        for (int i = 0; i < numberOfThreads; i++) {
            executorService.execute(() -> {
                try {
                    flashSaleService.processFlashSalePurchase(flashSaleItemId, userId);
                    successCount.incrementAndGet();
                } catch (Exception ignored) {
                    // Các request bị từ chối do vi phạm UNIQUE KEY hoặc Redis Atomic Lock
                } finally {
                    latch.countDown();
                }
            });
        }

        latch.await();
        assertThat(successCount.get()).isEqualTo(1); // Chỉ đúng 1 đơn được tạo
    }
}

```

---

## 4. KỊCH BẢN TEST TẢI & HIỆU NĂNG (LOAD / PERFORMANCE TESTING)

Sử dụng công cụ **k6 (Grafana)** hoặc **Apache JMeter** để giả lập traffic khủng vào đợt Flash Sale.

### 4.1. Kịch bản Test (Test Scenario Specification)

* **API Kiểm thử:** `POST /api/v1/flash-sale/buy`
* **Mục tiêu (Target Metrics):**
* **Virtual Users (VUs):** $1,000$ người dùng đồng thời.
* **Throughput Target:** $\ge 1,000$ RPS (Requests Per Second).
* **Response Time (P95):** $< 200\text{ms}$.
* **Error Rate:** $< 0.1\%$ (Không xảy ra lỗi crash 500 hoặc bán lố tồn kho - Overselling).



### 4.2. Script k6 Test Tải (`tests/performance/flash_sale_load.js`)

```javascript
import http from 'k6/http';
import { check, sleep } from 'k6';

export const options = {
  stages: [
    { duration: '10s', target: 200 },  // Ramp-up lên 200 user trong 10s
    { duration: '30s', target: 1000 }, // Tăng vọt lên 1,000 user trong 30s (Đỉnh điểm Flash Sale)
    { duration: '10s', target: 0 },    // Ramp-down về 0
  ],
  thresholds: {
    http_req_duration: ['p(95)<200'],  // 95% request phải phản hồi dưới 200ms
    http_req_failed: ['rate<0.01'],    // Tỷ lệ lỗi HTTP < 1%
  },
};

export default function () {
  const url = 'http://localhost:8080/api/v1/flash-sale/buy';
  const payload = JSON.stringify({
    flash_sale_item_id: 102,
    quantity: 1,
  });

  const params = {
    headers: {
      'Content-Type': 'application/json',
      'Authorization': `Bearer ${__ENV.JWT_TOKEN}`,
    },
  };

  const res = http.post(url, payload, params);

  check(res, {
    'Status code is 200 or 400 (Handled Business Error)': (r) => r.status === 200 || r.status === 400,
    'Response time < 200ms': (r) => r.timings.duration < 200,
  });

  sleep(0.1); // Giả lập khoảng nghỉ giữa các lượt click
}

```

### 4.3. Lệnh Chạy k6 Test Tải

```bash
k6 run -e JWT_TOKEN="your_test_access_token" tests/performance/flash_sale_load.js

```

```

```

## 5. KỊCH BẢN TEST TẢI VỚI APACHE JMETER

Apache JMeter được sử dụng để kiểm thử khả năng chịu tải của các API quan trọng (Checkout, Flash Sale, Áp dụng Voucher) dưới áp lực hàng ngàn request đồng thời.

---

### 5.1. Cấu hình Kịch bản Test Tải (JMeter Test Plan Architecture)

1. **Test Plan Name:** `TechStore_FlashSale_LoadTest.jmx`
2. **Thread Group Configuration (Giả lập $1,000$ Khách hàng):**
   * **Number of Threads (users):** `1000`
   * **Ramp-up period (seconds):** `10` (Trong 10 giây sẽ đẩy đủ 1,000 user)
   * **Loop Count:** `1` (Hoặc chọn `Infinite` kèm Duration 60s để test ngâm)

---

### 5.2. Cấu trúc HTTP Request & Sampler trong JMeter

#### **Step 1: HTTP Header Manager**
Thêm các Header bắt buộc cho API RESTful:
* `Content-Type`: `application/json`
* `Authorization`: `Bearer ${__CSV_JWT_TOKEN}` *(Lấy từ file CSV)*

#### **Step 2: CSV Data Set Config (Giả lập Dữ liệu Đa người dùng)**
Để giả lập 1,000 User khác nhau bấm mua Flash Sale (tránh vi phạm Unique Key mua trùng):
* **Filename:** `users_tokens.csv`
* **Variable Names:** `USER_ID,CSV_JWT_TOKEN`
* **Recycle on EOF:** `True`

#### **Step 3: HTTP Request Sampler (POST /api/v1/flash-sale/buy)**
* **Protocol:** `http` / `https`
* **Server Name or IP:** `localhost` (hoặc IP VPS Staging)
* **Port:** `8080`
* **Method:** `POST`
* **Path:** `/api/v1/flash-sale/buy`
* **Body Data:**
  ```json
  {
    "flash_sale_item_id": 102,
    "user_id": ${USER_ID},
    "quantity": 1
  }