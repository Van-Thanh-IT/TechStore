# 🚀 TECHSTORE - HỆ THỐNG THƯƠNG MẠI ĐIỆN TỬ BÁN LẺ ĐIỆN TỬ & CÔNG NGHỆ

> **TechStore** là hệ thống E-commerce hiện đại chuyên phục vụ kinh doanh thiết bị điện tử, tích hợp các giải pháp công nghệ nâng cao như xử lý Flash Sale chịu tải cao, Ví Voucher thành viên, Tích hợp đơn vị vận chuyển Goship, Xuất hóa đơn GTGT (VAT) và Chatbot AI tư vấn sản phẩm real-time.

---
## 1. CÔNG NGHỆ SỬ DỤNG (TECH STACK) & CÔNG CỤ

### Backend
* **Java**: Version 21 LTS (Tối ưu hiệu năng, hỗ trợ Virtual Threads & Pattern Matching)
* **Spring Boot**: Version 4.0.7 (Yêu cầu nền tảng Java 17+, tích hợp sẵn Jakarta EE 10)
* **Spring Security**: Version 6.x (Xử lý phân quyền RBAC/ABAC, bộ lọc bảo mật JWT Stateless)
* **Spring Data JPA**: Version 3.x (Quản lý và tương tác với ORM Hibernate 6.x)
* **MapStruct**: Version 1.5.x (Công cụ Mapping dữ liệu giữa Entity và DTO ở compile-time với hiệu năng cao)
* **Lombok**: Hỗ trợ giảm thiểu boilerplate code (Getter, Setter, Builder pattern)

### Database & Caching
* **MySQL**: Version 8.0 LTS (Hệ quản trị cơ sở dữ liệu quan hệ chính)
* **Redis**: Version 7.x (Lưu trữ Caching, Blacklist Token JWT, Session và Rate Limiting)

### Frontend
* **React**: Version 18.x / 19.x (Thư viện UI chính)
* **Vite**: Version 5.x (Build tool & Bundler tốc độ cao)
* **TypeScript**: Version 5.x (Kiểm soát kiểu dữ liệu tĩnh)
* **TanStack Query (React Query)**: Version 5.x (Quản lý Async State, Server State Caching & Optimistic Updates)
* **Zustand**: Version 4.x / 5.x (Quản lý Client State toàn cục nhẹ, tối ưu re-render)
* **Tailwind CSS**: Version 3.x / 4.x (Utility-first CSS framework)
* **React Router DOM**: Version 6.x / 7.x (Điều hướng SPA, hỗ trợ Data APIs & Lazy Loading)
* **Axios**: Version 1.x (HTTP Client cấu hình tập trung Interceptors)

### Tools & Development Environment
* **IDE**: IntelliJ IDEA (Backend), VS Code / WebStorm (Frontend)
* **API Testing & Documentation**: Swagger / OpenAPI 3.0, Postman
* **Build Tools**: Apache Maven (Backend), npm / pnpm (Frontend)
* **Version Control & CI/CD**: Git, GitHub / GitLab, Docker & Docker Compose

---

## ✨ TÍNH NĂNG NỔI BẬT

* **Chương trình Khuyến mãi Nâng cao:** 
  * Mã giảm giá công khai (`is_public = TRUE`) nhập tay tại Checkout cho cả Guest và Member.
  * Ví Voucher cá nhân (`is_public = FALSE`) tích hợp trang Trung tâm Voucher (`member/voucher`).
* **Flash Sale Khung Giờ Vàng:**
  * Chống Race Condition và Over-selling bằng Redis Atomic Counter & Ràng buộc CSDL (`UNIQUE KEY`).
* **Đơn hàng & Giao nhận Linh hoạt:**
  * Hỗ trợ mua nhanh dành cho Guest (Không cần Login) & Member đã xác thực.
  * Snapshot địa chỉ giao hàng, Xuất hóa đơn GTGT (VAT), Đồng bộ mã vận đơn Goship.
* **Hệ thống Live Chat & AI Support (Hybrid):**
  * Tự động phản hồi bằng AI Chatbot (Trả về Text, Card sản phẩm JSON) $\rightarrow$ Hỗ trợ chuyển tiếp cho Nhân viên CSKH khi cần.
* **Quản lý Kho & Bảo hành Điện tử:**
  * Định danh chính xác từng máy theo số **IMEI/Serial Number**, tự động kích hoạt Bảo hành điện tử sau khi xuất kho.

---

## 2. BACKEND ARCHITECTURE (SPRING BOOT)

### 2.1 Cấu trúc thư mục

```text
src/main/java/com/example/techstore/
├── config/                  # Cấu hình hệ thống (CORS, Security, JWT, Redis, Swagger, OpenAPI)
├── controller/              # Tiếp nhận request HTTP, validate sơ bộ, kiểm tra quyền và trả về API Response
├── dto/                     # Data Transfer Object
│   ├── request/             # Data DTO gửi lên từ Client
│   └── response/            # Data DTO trả về cho Client
├── entity/                  # JPA Entities (Mapping trực tiếp với bảng trong Database)
├── enum/                    # Định nghĩa tập hợp hằng số (OrderStatus, RoleType, PaymentMethod...)
├── exception/               # Global Exception Handler (@ControllerAdvice) và Custom Exceptions
├── mapper/                  # MapStruct Mappers (Biến đổi Entity <-> DTO)
├── repository/              # Tầng giao tiếp Database (Spring Data JPA / Native Query)
├── service/                 # Tầng xử lý logic nghiệp vụ (Business Logic Layer)
│   ├── impl/                # Implementation chi tiết của các Service Interface
│   └── ...                  # Interfaces của Service
├── util/                    # Utility classes (JWT Provider, Password Encoder, DateUtils...)
├── validator/               # Custom Annotation Validators (VD: @ValidPhoneNumber, @UniqueEmail)
└── TechstoreApplication.java# Entry point khởi chạy ứng dụng Spring Boot

src/main/resources/
├── static/                  # Lưu trữ tài nguyên tĩnh public
├── templates/               # HTML Templates (Dùng cho Thymeleaf gửi Email OTP, Hóa đơn)
├── i18n/                    # Đa ngôn ngữ cho các thông báo lỗi (messages.properties)
└── application.yaml         # Cấu hình môi trường (Database, Redis, JWT Secret, Mail Server)
```

### 2.2 Dòng chạy nghiệp vụ (Backend Data Flow)

```text
Client Request ──> [ Config (Security/JWT) ] ──> [ Controller ] ──> [ Validator ]
                                                                        │
 Client Response <── [ Global Exception ] <── [ Service (Logic) ] <─────┘
                            │                       │
                            ▼                       ▼
                     [ Mapper / DTO ] ──> [ Repository ] ──> [ Database / Redis ]
```

1. **Security & Authentication**: Request đi qua chuỗi bộ lọc `config/` (JwtAuthenticationFilter) để xác thực tính hợp lệ của Token/Header và thiết lập `SecurityContext`.
2. **Request Reception**: Request đi vào `controller/`. Tại đây, dữ liệu dạng JSON được binding vào `dto/request/`.
3. **Data Validation**: Các Annotation kiểm tra dữ liệu (`@Valid`, custom `@validator/`) tiến hành validation. Nếu không hợp lệ, `exception/` sẽ chặn lại và trả về lỗi `400 Bad Request`.
4. **Business Logic Execution**: `controller/` chuyển DTO sạch sang `service/`. Tầng Service điều phối nghiệp vụ, xử lý giao dịch (`@Transactional`), tính toán dữ liệu.
5. **Data Mapping & Persistence**: `service/` sử dụng `mapper/` để chuyển DTO thành `entity/`, sau đó gọi `repository/` để đọc/ghi xuống Database/Redis.
6. **Response Transformation**: Kết quả từ `entity/` được `mapper/` chuyển ngược thành `dto/response/` và gửi về `controller/` để đóng gói thành HTTP Response chuẩn (`ApiResponse<T>`).

---

## 3. FRONTEND ARCHITECTURE (REACT - FEATURE-BASED)

### 3.1 Cấu trúc thư mục

```text
src/
├── assets/                  # Images, SVGs, Fonts, Icons tĩnh toàn hệ thống
├── components/              # UI Components tái sử dụng chung
│   ├── ui/                  # Component thô (Button, Input, Modal, Table...) - Tích hợp Tailwind
│   └── common/              # Component hệ thống (Header, Footer, LoadingSpinner, Boundary Error, 404, 403)
├── configs/                 # Cấu hình kỹ thuật nền tảng
│   ├── axios.ts              # Axios instance, Interceptors (Refresh Token, Auto-attach Header, Error Handling)
│   └── queryClient.ts       # React Query Client configuration (staleTime, gcTime, retry policy)
├── constants/               # Hằng số hệ thống (API_ENDPOINTS, ROLES, STORAGE_KEYS)
├── layouts/                 # Master Layouts (AdminLayout, AuthLayout, CustomerLayout)
├── pages/                   # Root Pages (Chỉ bọc Layout và render Feature Container)
├── routes/                  # Định tuyến ứng dụng
│   ├── AppRoutes.tsx        # Router Map chính (Cấu hình React Lazy / Code Splitting)
│   └── ProtectedRoute.tsx   # Guard component kiểm tra Authentication & Authorization
├── store/                   # Global Client-state Management (Zustand Stores: authStore, themeStore)
├── types/                   # TypeScript definitions dùng chung (Pagination, BaseApiResponse, User)
├── utils/                   # Helper functions (formatCurrency, formatDate, storageHelpers)
│
├── features/                # TẬP TRUNG NGHIỆP VỤ (Feature-Driven Architecture)
│   ├── auth/                # Phân hệ Xác thực & Phân quyền
│   │   ├── components/      # UI components nội bộ của Auth (LoginForm, RegisterForm, OtpInput)
│   │   ├── hooks/           # Custom Hooks (useLogin, useRegister, useProfile - React Query)
│   │   ├── services/        # API Callers (authApi.ts - thuần túy giao tiếp Axios)
│   │   ├── pages/           # Screens chính của feature (LoginPage.tsx, RegisterPage.tsx)
│   │   ├── types/           # Type definitions riêng cho Auth (LoginPayload, AuthResponse)
│   │   └── index.ts         # Public API của feature (Export Pages, Hooks cần thiết ra ngoài)
│   │
│   └── order/               # Phân hệ Quản lý Đơn hàng (Cấu trúc tương tự auth)
│       ├── components/
│       ├── hooks/
│       ├── services/
│       ├── pages/
│       ├── types/
│       └── index.ts
│
├── App.tsx                  # Root Component bọc Providers (QueryClientProvider, RouterProvider, Toast)
└── main.tsx                 # Entry point của ứng dụng React (Vite render)
```

### 3.2 Dòng chạy nghiệp vụ (Frontend Data Flow)

```text
[ User Action on Page/UI Component ]
                 │
                 ▼
     [ Feature Custom Hook ] (React Query / Async Management)
                 │
                 ▼
       [ Feature Service ] (Axios Instance with Interceptors)
                 │
                 ▼
       [ Spring Boot API ]
                 │
  (Response)     ▼
      [ Type Safety Check ] ──> [ Synchronize State ] ──> [ UI Re-render ]
                                       │
                                       ▼ (Global Data)
                                [ Zustand Store ]
```

1. **User Interaction**: Người dùng tương tác trên UI trong `features/{feature}/pages` hoặc `components`.
2. **State/Action Dispatch**: Event handler gọi custom hook tương ứng từ `features/{feature}/hooks` (sử dụng React Query `useQuery` hoặc `useMutation`).
3. **API Request**: Hook kích hoạt service function từ `features/{feature}/services`, gọi Axios instance đã qua cấu hình `configs/axios.ts`.
4. **Interceptors Execution**: Axios tự động đính kèm JWT Bearer Token từ Zustand store vào Header và gửi request lên Backend.
5. **Data Synchronization**: Khi Backend phản hồi, React Query tự động cache dữ liệu, ép kiểu theo `types/`, và cập nhật UI. 
6. **Global State Propagation**: Nếu dữ liệu ảnh hưởng toàn ứng dụng (ví dụ: Thông tin User, Token), Hook sẽ đồng bộ dữ liệu vào Zustand store (`store/`).
