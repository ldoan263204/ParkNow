# 📊 ParkNow – Báo cáo Kiểm tra Hiện trạng Dự án

> **Kiểm tra thực tế từ ổ đĩa** — 31/05/2026, 22:07 (GMT+7)  
> Tất cả file được đếm trực tiếp, không phải ước lượng.

---

## 🏗️ Cấu trúc thư mục hoàn chỉnh

```
ParkNow-FullStack/
├── dh52201042_parknow/           # Flutter App (27 file .dart)
│   └── lib/
│       ├── main.dart
│       ├── core/
│       │   ├── constants/api_config.dart
│       │   ├── services/authenticated_client.dart  ← MỚI (JWT)
│       │   ├── theme/app_colors.dart
│       │   └── theme/app_theme.dart
│       ├── shared_widgets/app_widgets.dart
│       └── features/
│           ├── authentication/   ← ✅ HOÀN THÀNH
│           ├── parking_map/      ← ✅ HOÀN THÀNH
│           ├── staff_scanner/    ← ✅ HOÀN THÀNH
│           └── admin_dashboard/  ← ✅ HOÀN THÀNH (1 file view)
│
└── back-end-parknow/             # Spring Boot API (24 file .java)
    └── src/main/java/.../
        ├── controller/   (5 files)
        ├── model/        (5 files)
        ├── repository/   (5 files)
        ├── service/      (5 files)
        └── security/     (3 files)  ← MỚI (JWT)
```

---

## ✅ Flutter Frontend — 27 file hoàn thành

### 🔐 Authentication (3 Views + VM + Service + Model)
| File | Chức năng |
|---|---|
| `views/welcome_view.dart` | Màn hình onboarding, gradient, 2 nút |
| `views/login_view.dart` | Form đăng nhập, điều hướng theo role |
| `views/register_view.dart` | Form đăng ký với chọn role |
| `viewmodels/auth_viewmodel.dart` | Quản lý state login/register/logout |
| `services/auth_service.dart` | Gọi API đăng nhập/đăng ký |
| `models/user_model.dart` | Model user **có field `token` (JWT)** |

### 🗺️ Parking Map – Customer (2 Views + VM + Service + 2 Models)
| File | Chức năng |
|---|---|
| `views/parking_map_view.dart` | Bản đồ OSM, marker, bottom sheet, 3-tab list |
| `views/lot_detail_view.dart` | Chi tiết bãi xe, chọn ngày/giờ, tính phí, đặt chỗ |
| `viewmodels/parking_map_viewmodel.dart` | Load danh sách bãi xe từ API |
| `services/parking_map_service.dart` | Gọi GET/PUT parking lots API |
| `services/booking_service.dart` | Tạo/hủy booking **có AuthenticatedClient (JWT)** |
| `models/parking_lot_model.dart` | Model bãi xe với computed props |
| `models/booking_model.dart` | Model đặt chỗ, toJson/fromJson |

### 👷 Staff Scanner – Nhân viên (3 Views + VM + Service + 2 Models)
| File | Chức năng |
|---|---|
| `views/staff_home_view.dart` | Dashboard: Half-donut chart, Vào/Ra, stats |
| `views/staff_profile_view.dart` | Hồ sơ, đồng hồ ca, grid stats, kết thúc ca |
| `views/violation_list_view.dart` | Danh sách vi phạm, 3 tab, FAB tạo mới |
| `viewmodels/staff_viewmodel.dart` | Quản lý shift + violation state |
| `services/staff_service.dart` | Gọi toàn bộ Shift/Violation API |
| `models/shift_model.dart` | Model ca trực với totalRevenue |
| `models/violation_model.dart` | Model vi phạm với reasonText |

### 🛡️ Admin Dashboard (1 View)
| File | Chức năng |
|---|---|
| `views/admin_dashboard_view.dart` | Side nav, KPI cards, biểu đồ đường, quản lý bãi xe |

### ⚙️ Core
| File | Chức năng |
|---|---|
| `core/constants/api_config.dart` | Tất cả endpoint tập trung |
| `core/services/authenticated_client.dart` | **HTTP Client tự động gắn JWT Bearer token** |
| `core/theme/app_colors.dart` | Bảng màu toàn app |
| `core/theme/app_theme.dart` | Theme Material |
| `shared_widgets/app_widgets.dart` | PrimaryButton, AppTextField, StatCard, StatusTag... |

---

## ✅ Spring Boot Backend — 24 file hoàn thành

### 🔐 Security (3 file MỚI)
| File | Chức năng |
|---|---|
| `security/JwtUtil.java` | Tạo và xác thực JWT (JJWT 0.12.x) |
| `security/JwtAuthFilter.java` | OncePerRequestFilter — đọc Bearer token |
| `security/SecurityConfig.java` | Stateless, CSRF disabled, phân quyền endpoint |

### 📦 Controllers (5 file)
| File | Endpoints |
|---|---|
| `UserController.java` | register (**trả JWT**), login (**trả JWT**), CRUD users |
| `ParkingLotController.java` | CRUD, approve, reject, filter by status |
| `BookingController.java` | create (tính phí auto), cancel, complete, filter |
| `ShiftController.java` | start, end, entry, exit, history |
| `ViolationController.java` | create, resolve, filter by status/lot/staff |

### 📦 Models / Entities (5 file)
`User`, `ParkingLot`, `Booking`, `Shift`, `Violation`

### 📦 Repositories (5 file)
Spring Data JPA với custom queries cho từng entity.

### 📦 Services (5 file)
`UserService` (BCrypt), `ParkingLotService`, `BookingService` (tính phí tự động), `ShiftService`, `ViolationService`

---

## 🔑 Tài khoản test đã tạo (sẵn sàng dùng)

| Role | Email | Mật khẩu |
|---|---|---|
| **CUSTOMER** | `customer@test.com` | `password` |
| **STAFF** | `staff@test.com` | `password` |

> Mật khẩu được mã hóa BCrypt, login trả về JWT token 24h.

---

## ⚠️ Còn thiếu / Chưa triển khai

| # | Tính năng | Mức độ ưu tiên |
|---|---|---|
| 1 | **QR Scanner check-in/out** (Staff) — cần `mobile_scanner` | 🔴 Cao |
| 2 | **Runtime Location Permission** — cần `permission_handler` | 🔴 Cao |
| 3 | **Chỉ đường (Routing)** — OSRM API hoặc `flutter_map_routing` | 🟡 Trung bình |
| 4 | **Upload ảnh vi phạm** — camera + multipart upload | 🟡 Trung bình |
| 5 | **Admin: Quản lý User UI** — màn hình danh sách + CRUD | 🟡 Trung bình |
| 6 | **Push Notification** — Firebase Cloud Messaging | 🟠 Thấp |
| 7 | **Unit Tests** — ViewModel + Service tests | 🟠 Thấp |

---

## 📊 Tổng kết số liệu

| Hạng mục | Số lượng |
|---|---|
| File Dart (.dart) | **27 file** |
| File Java (.java) | **24 file** |
| REST API Endpoints | **32+** (5 Controllers) |
| Database Tables | **5** (users, parking_lots, bookings, shifts, violations) |
| Feature modules (Flutter) | **4** (auth, parking_map, staff_scanner, admin_dashboard) |
| Security layer | **JWT + BCrypt** ✅ |
| Bản đồ | **OpenStreetMap** (miễn phí, không cần API Key) ✅ |
| Database | **MySQL trên Aiven Cloud** ✅ |
