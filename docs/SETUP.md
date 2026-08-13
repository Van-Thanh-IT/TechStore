```markdown
# 🛠️ LOCAL ENVIRONMENT SETUP GUIDE

Tài liệu này hướng dẫn chi tiết các bước thiết lập môi trường phát triển (Local Development) cho dự án **TechStore** phía Backend (Spring Boot) và Frontend (React/Next.js).

---

## 1. YÊU CẦU PHẦN MỀM (PREREQUISITES)

Trước khi bắt đầu, hãy đảm bảo máy tính của bạn đã cài đặt các công cụ sau:

| Công cụ / Software | Phiên bản Khuyên dùng | Mục đích Sử dụng |
| :--- | :--- | :--- |
| **JDK (Java Development Kit)** | OpenJDK 21 LTS trở lên | Môi trường chạy Spring Boot |
| **Node.js & npm** | Node.js 18.x LTS / 20.x LTS | Môi trường chạy React  |
| **MySQL** | MySQL 8.0+  | Cơ sở dữ liệu quan hệ chính |
| **Redis** | Redis 7.0+ | Bộ nhớ Cache & Lock phân tán |
| **Docker Desktop** | Phiên bản mới nhất | Chạy nhanh các Service phụ trợ |
| **Git** | 2.x+ | Quản lý mã nguồn |

---

## 2. PHƯƠNG THỨC 1: CẠY BẰNG DOCKER COMPOSE (KHUYÊN DÙNG)

Đây là cách nhanh nhất để khởi chạy toàn bộ hệ thống (App + Database + Redis) chỉ với một câu lệnh.

### Bước 1: Clone Repository
```bash
git clone https://github.com/Van-Thanh-IT/TechStore.git
cd TechStore

```

### Bước 2: Khởi tạo biến môi trường `.env`

Tạo file `.env` tại thư mục gốc của dự án (copy từ `.env.example`):

```bash
cp .env.example .env

```

### Bước 3: Khởi chạy Containers

```bash
docker-compose up -d --build

```

### Bước 4: Kiểm tra trạng thái các Services

```bash
docker-compose ps

```

---

## 3. PHƯƠNG THỨC 2: CÀI ĐẶT THỦ CÔNG (MANUAL LOCAL RUN)

Phù hợp khi bạn cần Debug sâu code Backend/Frontend trong IDE (IntelliJ IDEA / VS Code).

### 3.1. Khởi tạo Cơ sở Dữ liệu & Redis

1. Mở MySQL Client (Navicat, DBeaver, Workbench) và tạo Database:
```sql
CREATE DATABASE TechStore CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

```


2. Thực thi Script DDL khởi tạo bảng tại [`docs/DATABASE_DESIGN.md`](https://www.google.com/search?q=./DATABASE_DESIGN.md) hoặc chạy Script SQL trong thư mục `src/main/resources/schema.sql`.
3. Bật dịch vụ Redis Server trên máy Local (Mặc định Port `6379`).

### 3.2. Cấu hình & Chạy Backend (Spring Boot)

1. Mở dự án trong **IntelliJ IDEA** (mở thư mục chứa file `pom.xml` hoặc `build.gradle`).
2. Mở file `src/main/resources/application-dev.yml` và chỉnh sửa thông số kết nối DB/Redis:
```yaml
spring:
  datasource:
    url: jdbc:mysql://localhost:3306/TechStore?useSSL=false&serverTimezone=UTC
    username: root
    password: your_local_password
  data:
    redis:
      host: localhost
      port: 6379

```


3. Run file chính `TechStoreApplication.java` hoặc chạy câu lệnh Maven từ terminal:
```bash
./mvnw spring-boot:run -Dspring-boot.run.profiles=dev

```


*Backend API sẽ khởi chạy tại: `http://localhost:8080/api/v1*`

### 3.3. Cấu hình & Chạy Frontend (React/Next.js)

1. Truy cập vào thư mục frontend:
```bash
cd frontend

```


2. Cài đặt các thư viện phụ thuộc (Node Modules):
```bash
npm install

```


3. Tạo file `.env.local` cấu hình đường dẫn API:
```env
NEXT_PUBLIC_API_BASE_URL=http://localhost:8080/api/v1
NEXT_PUBLIC_WS_URL=http://localhost:8080/ws

```


4. Khởi chạy Development Server:
```bash
npm run dev

```


*Frontend ứng dụng sẽ khởi chạy tại: `http://localhost:3000*`

---

## 4. XÁC NHẬN CÀI ĐẶT THÀNH CÔNG (VERIFICATION)

Sau khi khởi chạy hoàn tất, bạn có thể kiểm tra các địa chỉ sau:

* 🌐 **Trang chủ Khách hàng:** `http://localhost:3000`
* 🛠️ **Swagger UI (Tài liệu API tương tác):** `http://localhost:8080/swagger-ui.html`
* 💓 **Health Check Endpoint:** `http://localhost:8080/actuator/health` (Trả về `{"status": "UP"}`)

---

## 5. CÁC SỰ CỐ THƯỜNG GẶP (TROUBLESHOOTING)

* **Lỗi `Port 8080 / 3306 already in use`:**
* Nguyên nhân: Port đã bị chiếm bởi một ứng dụng khác.
* Xử lý: Tắt ứng dụng đang dùng port đó hoặc đổi port cấu hình trong file `application.yml` / `docker-compose.yml`.


* **Lỗi `Access denied for user 'root'` khi kết nối DB:**
* Xử lý: Kiểm tra lại `username`/`password` trong file `.env` hoặc `application-dev.yml` xem đã khớp với cấu hình MySQL trên máy chưa.


* **Lỗi CORS (`Cross-Origin Request Blocked`):**
* Xử lý: Đảm bảo Spring Security CORS đã allow origin `http://localhost:3000`.



```

```