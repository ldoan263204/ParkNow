# 📋 BÁO CÁO TỔNG KẾT DỰ ÁN PARKNOW FULL-STACK

> **Kiểm tra thực tế từ ổ đĩa** · 01/06/2026 · 03:01 (GMT+7)
> Dự án: `d:\ParkNow-FullStack`

---

## 1. TỔNG QUAN SỐ LIỆU

| Hạng mục | Số lượng |
|:---|:---:|
| File Dart (Flutter frontend) | **31 file** |
| File Java (Spring Boot backend) | **24 file** |
| REST API Endpoints | **32+** |
| Bảng Database (MySQL cloud) | **5 bảng** |
| Feature modules Flutter | **4 modules** |
| Thư viện Flutter (dependencies) | **9 packages** |
| Tài khoản test đã tạo | **2 tài khoản** |

---

## 2. CẤU TRÚC THƯ MỤC ĐẦY ĐỦ

```
ParkNow-FullStack/
├── dh52201042_parknow/                     ← Flutter App
│   ├── pubspec.yaml
│   ├── android/app/src/main/AndroidManifest.xml
│   └── lib/
│       ├── main.dart
│       ├── core/
│       │   ├── constants/api_config.dart
│       │   ├── services/
│       │   │   ├── authenticated_client.dart   ← JWT auto-attach
│       │   │   └── location_service.dart       ← GPS permission (MỚI)
│       │   └── theme/
│       │       ├── app_colors.dart
│       │       └── app_theme.dart
│       ├── shared_widgets/app_widgets.dart
│       └── features/
│           ├── authentication/              ← ✅ HOÀN THÀNH
│           │   ├── models/user_model.dart
│           │   ├── services/auth_service.dart
│           │   ├── viewmodels/auth_viewmodel.dart
│           │   └── views/
│           │       ├── welcome_view.dart
│           │       ├── login_view.dart
│           │       └── register_view.dart
│           ├── parking_map/                 ← ✅ HOÀN THÀNH
│           │   ├── models/
│           │   │   ├── parking_lot_model.dart
│           │   │   └── booking_model.dart
│           │   ├── services/
│           │   │   ├── parking_map_service.dart
│           │   │   └── booking_service.dart
│           │   ├── viewmodels/parking_map_viewmodel.dart
│           │   └── views/
│           │       ├── parking_map_view.dart   ← Smart Search + GPS (MỚI)
│           │       └── lot_detail_view.dart
│           ├── staff_scanner/               ← ✅ HOÀN THÀNH
│           │   ├── models/
│           │   │   ├── shift_model.dart
│           │   │   └── violation_model.dart
│           │   ├── services/staff_service.dart
│           │   ├── viewmodels/staff_viewmodel.dart
│           │   └── views/
│           │       ├── staff_home_view.dart      ← QR button (MỚI)
│           │       ├── staff_profile_view.dart   ← Full profile + Logout (MỚI)
│           │       ├── violation_list_view.dart  ← Image upload (MỚI)
│           │       └── qr_scanner_view.dart      ← QR Scanner (MỚI)
│           └── admin_dashboard/             ← ✅ HOÀN THÀNH
│               ├── services/
│               │   └── user_admin_service.dart   ← CRUD users (MỚI)
│               └── views/
│                   ├── admin_dashboard_view.dart ← Logout + Avatar (MỚI)
│                   └── user_management_view.dart ← Full CRUD UI (MỚI)
│
└── back-end-parknow/                        ← Spring Boot API
    └── src/main/java/.../
        ├── Dh52201042ParknowBackendApplication.java
        ├── controller/   (5 files)
        ├── model/        (5 files)
        ├── repository/   (5 files)
        ├── service/      (5 files)
        └── security/     (3 files)
```

---

## 3. CHI TIẾT TỪNG MODULE ĐÃ HOÀN THÀNH

### 🔐 Module 1: Authentication (6 file)

| File | Chức năng |
|:---|:---|
| `welcome_view.dart` | Màn hình onboarding gradient, 2 nút Đăng nhập / Đăng ký |
| `login_view.dart` | Form đăng nhập, điều hướng theo `role` (CUSTOMER / STAFF / ADMIN) |
| `register_view.dart` | Form đăng ký với dropdown chọn Role |
| `auth_viewmodel.dart` | State: `login()`, `register()`, `logout()` + `isLoading`, `errorMessage` |
| `auth_service.dart` | Gọi API `/api/users/login` và `/register`, parse JWT response |
| `user_model.dart` | Model với field `token` để lưu JWT sau đăng nhập |

**Luồng đăng nhập:**

```
WelcomeView → LoginView → AuthViewModel.login() → AuthService
→ POST /api/users/login → nhận JWT → điều hướng theo role:
   CUSTOMER → CustomerMapView
   STAFF    → StaffHomeView
   ADMIN    → AdminDashboardView
```

---

### 🗺️ Module 2: Parking Map — Customer (9 file)

| File | Chức năng |
|:---|:---|
| `parking_map_view.dart` | Bản đồ OSM, markers, Smart Search, GPS Locate-Me FAB, Profile Sheet |
| `lot_detail_view.dart` | Chi tiết bãi xe, date/time picker, tính phí, nút đặt chỗ |
| `parking_map_viewmodel.dart` | Load và quản lý state danh sách bãi xe |
| `parking_map_service.dart` | `fetchAllParkingLots()`, `approveParkingLot()`, `rejectParkingLot()` |
| `booking_service.dart` | `createBooking()`, `cancelBooking()` — dùng `AuthenticatedClient` (JWT) |
| `parking_lot_model.dart` | Model với computed: `occupancyPercent`, `hasAvailableSlots` |
| `booking_model.dart` | Model đặt chỗ, `toJson()` / `fromJson()` |
| `location_service.dart` | `requestPermission()`, `getCurrentLocation()` → trả `LatLng` |
| `authenticated_client.dart` | HTTP wrapper tự động gắn `Authorization: Bearer <token>` |

**Tính năng nổi bật:**
- 🔍 **Smart Search**: Gõ từ khóa → lọc realtime + Nominatim Geocoding flyTo
- 📍 **GPS Button**: FAB góc phải → xin quyền → lấy vị trí → `move()` bản đồ
- 👤 **Profile Sheet**: Bấm Avatar → BottomSheet hiện thông tin + Đăng xuất
- 🏷️ **3 Tab sắp xếp**: Gần tôi / Giá thấp / Còn nhiều chỗ

---

### 👷 Module 3: Staff Scanner — Nhân viên (8 file)

| File | Chức năng |
|:---|:---|
| `staff_home_view.dart` | Dashboard: Half-donut chart, nút Vào/Ra, **nút QR Scanner** |
| `staff_profile_view.dart` | Hồ sơ đầy đủ, đồng hồ ca, grid stats, **nút Đăng xuất** |
| `violation_list_view.dart` | 3-tab danh sách, form báo cáo, **chụp ảnh + upload** |
| `qr_scanner_view.dart` | **QR scanner chuyên nghiệp**: khung quét, scan line animate, flash/flip |
| `staff_viewmodel.dart` | Quản lý state shift + violation, `service` getter exposed |
| `staff_service.dart` | API: shift start/end/entry/exit/history, violation CRUD |
| `shift_model.dart` | Model ca trực với `totalRevenue`, `cashRevenue`, `onlineRevenue` |
| `violation_model.dart` | Model vi phạm với `imageUrl`, `reasonText` computed |

**QR Code format:** `PARKNOW:ENTRY:<bookingId>` hoặc `PARKNOW:EXIT:<bookingId>`

**Luồng upload ảnh vi phạm:**
```
Bấm FAB → BottomSheet → Chọn Camera / Gallery
→ image_picker → preview ảnh inline → POST multipart /api/violations/upload
→ nhận imageUrl → gửi kèm báo cáo
```

---

### 🛡️ Module 4: Admin Dashboard (3 file)

| File | Chức năng |
|:---|:---|
| `admin_dashboard_view.dart` | Side nav (Avatar + Logout đỏ), KPI cards, line chart, phê duyệt bãi |
| `user_management_view.dart` | Danh sách users + CRUD: tìm kiếm, lọc role, thêm/sửa/xóa |
| `user_admin_service.dart` | `fetchAllUsers()`, `updateUser()`, `deleteUser()`, `createUser()` |

**User Management features:**
- 📊 Stat pills: Tổng / KH / NV / Admin
- 🔍 Search realtime + Role filter chips
- ✏️ Dialog Thêm (email + mật khẩu) / Sửa (tên + phone + role)
- 🗑️ Dialog xác nhận Xóa với safeguard
- 🔒 Tài khoản Admin đang đăng nhập được bảo vệ (không thể tự xóa)
- 🔄 Pull-to-refresh

---

### ⚙️ Backend Spring Boot (24 file Java)

#### Security Layer (3 file)

| File | Chức năng |
|:---|:---|
| `JwtUtil.java` | Tạo/xác thực JWT (JJWT 0.12.x) — `generateToken()`, `extractEmail()` |
| `JwtAuthFilter.java` | `OncePerRequestFilter` — đọc Bearer token từ mọi request |
| `SecurityConfig.java` | Stateless, CSRF off, permit `/login`, `/register`, `/parking-lots` |

#### REST API Endpoints đầy đủ

| Resource | Endpoints |
|:---|:---|
| **Users** | `POST /register` · `POST /login` · `GET /` · `GET /{id}` · `PUT /{id}` · `DELETE /{id}` |
| **Parking Lots** | `GET /` · `GET /all` · `POST /` · `PUT /{id}` · `PUT /{id}/approve` · `PUT /{id}/reject` |
| **Bookings** | `POST /` · `GET /user/{userId}` · `PUT /{id}/cancel` · `PUT /{id}/complete` |
| **Shifts** | `POST /start` · `PUT /{id}/end` · `PUT /{id}/entry` · `PUT /{id}/exit` · `GET /staff/{id}` · `GET /staff/{id}/active` |
| **Violations** | `POST /` · `GET /` · `PUT /{id}/resolve` · `GET /lot/{lotId}` · `GET /staff/{staffId}` |

---

## 4. DEPENDENCIES & CẤU HÌNH

### Flutter `pubspec.yaml`

```yaml
dependencies:
  http: ^1.6.0                # HTTP client
  flutter_map: ^7.0.2         # Bản đồ OpenStreetMap (miễn phí 100%)
  latlong2: ^0.9.1            # Tọa độ LatLng
  intl: ^0.20.0               # Format tiền / ngày giờ
  mobile_scanner: ^7.0.1      # Quét QR code (Phase 2)
  permission_handler: ^11.4.0 # Runtime GPS permission (Phase 2)
  geolocator: ^13.0.4         # Lấy vị trí GPS (Phase 2)
  image_picker: ^1.1.2        # Camera / Gallery upload (Phase 2)

dev_dependencies:
  mockito: ^5.4.5             # Unit test mocking (Phase 3)
  build_runner: ^2.4.15       # Code generation cho mockito
```

### Android Permissions (`AndroidManifest.xml`)

```
INTERNET
ACCESS_FINE_LOCATION · ACCESS_COARSE_LOCATION · ACCESS_BACKGROUND_LOCATION
CAMERA · FLASHLIGHT
READ_MEDIA_IMAGES · READ_EXTERNAL_STORAGE (maxSdkVersion=32)
```

### Backend `application.properties`

| Config | Giá trị |
|:---|:---|
| Server port | `8080` |
| Database | MySQL trên **Aiven Cloud** (SSL required) |
| JWT Secret | Configured (HS256) |
| JWT Expiration | **24 giờ** |
| DDL Auto | `update` |
| JDK | 18.0.2.1 |

---

## 5. TÀI KHOẢN TEST (BCrypt hashed)

| Role | Email | Mật khẩu |
|:---|:---|:---|
| 🚗 CUSTOMER | `customer@test.com` | `password` |
| 👷 STAFF | `staff@test.com` | `password` |

> **Lưu ý:** Mọi tài khoản tạo trước khi tích hợp JWT (BCrypt) đều không thể đăng nhập. Chỉ dùng 2 tài khoản trên để test.

---

## 6. TIẾN ĐỘ BACKLOG

### ✅ Đã hoàn thành

| Phần | Hạng mục | Trạng thái |
|:---|:---|:---:|
| **Phần 1 – UI/UX Core** | Smart Search (filter + Geocoding) | ✅ |
| | GPS Locate-Me Button (FAB bản đồ) | ✅ |
| | Customer Profile BottomSheet + Đăng xuất | ✅ |
| | Staff Profile đầy đủ + Đăng xuất | ✅ |
| | Admin Side Nav Avatar + Logout đỏ | ✅ |
| **Phần 2 – Hardware & Map** | QR Scanner check-in/out (Staff) | ✅ |
| | Runtime Location Permission | ✅ |
| | Upload ảnh vi phạm (Camera + multipart) | ✅ |
| **Phần 3 – Admin & System** | User Management CRUD Screen | ✅ |
| | UserAdminService (fetch/create/update/delete) | ✅ |

### ⏳ Còn cần hoàn thiện

| # | Hạng mục | Ưu tiên | Ghi chú |
|:---|:---|:---:|:---|
| 1 | **Wire Admin User Tab vào SideNav** | 🔴 Cao | Chưa thêm `_navItem(2, ...)` + `_selectedNav == 2` trong `admin_dashboard_view.dart` |
| 2 | **Backend: Upload endpoint** | 🔴 Cao | Cần `POST /api/violations/upload` nhận multipart |
| 3 | **Chỉ đường OSRM** | 🟡 Trung | Vẽ Polyline từ GPS người dùng → bãi xe |
| 4 | **Push Notification (FCM)** | 🟠 Thấp | Chưa cài Firebase |
| 5 | **Unit Tests (mockito)** | 🟠 Thấp | Dependencies đã thêm, chưa viết test files |

---

## 7. VIỆC CẦN LÀM NGAY (Quick Fixes)

### Fix 1 — Wire Admin User Management vào SideNav

**File:** `admin_dashboard_view.dart`

```dart
// 1. Thêm import:
import 'user_management_view.dart';

// 2. Thêm nav item (trong _buildSideNav):
_navItem(2, Icons.people_rounded, 'Users'),

// 3. Cập nhật body (dòng ~51):
// TRƯỚC:
Expanded(child: _selectedNav == 0 ? _buildDashboard() : _buildLotManagement())

// SAU:
Expanded(child: _selectedNav == 0
  ? _buildDashboard()
  : _selectedNav == 1
      ? _buildLotManagement()
      : UserManagementView(adminUser: widget.user))
```

### Fix 2 — Backend Upload Endpoint

**File:** `ViolationController.java`

```java
@PostMapping("/upload")
@CrossOrigin(origins = "*")
public ResponseEntity<Map<String, String>> uploadImage(
    @RequestParam("file") MultipartFile file) throws IOException {
    String uploadDir = "uploads/violations/";
    new File(uploadDir).mkdirs();
    String fileName = System.currentTimeMillis() + "_" + file.getOriginalFilename();
    Path filePath = Paths.get(uploadDir + fileName);
    Files.copy(file.getInputStream(), filePath, StandardCopyOption.REPLACE_EXISTING);
    String url = "/uploads/violations/" + fileName;
    return ResponseEntity.ok(Map.of("url", url));
}
```

---

## 8. SƠ ĐỒ KIẾN TRÚC HỆ THỐNG

```
┌─────────────────────────────────────────────────────────────┐
│                    FLUTTER APP (MVVM)                        │
│                                                             │
│  View ──→ ViewModel ──→ Service ──→ AuthenticatedClient     │
│                                           ↕ JWT Bearer      │
│                                                             │
│  ┌──────────┐ ┌─────────────┐ ┌──────┐ ┌───────────────┐  │
│  │   Auth   │ │ ParkingMap  │ │Staff │ │ AdminDashboard │  │
│  │ 6 files  │ │   9 files   │ │8 fls │ │    3 files    │  │
│  └──────────┘ └─────────────┘ └──────┘ └───────────────┘  │
└─────────────────────────┬───────────────────────────────────┘
                          │ HTTP/REST (port 8080)
                          ▼
┌─────────────────────────────────────────────────────────────┐
│              SPRING BOOT BACKEND (3-Tier Architecture)       │
│                                                             │
│  Controller (5) → Service (5) → Repository (5) → Entity(5) │
│                                                             │
│  ┌──────────────────────────────────────────────────────┐  │
│  │  JwtAuthFilter → JwtUtil → SecurityConfig (Stateless)│  │
│  └──────────────────────────────────────────────────────┘  │
└─────────────────────────┬───────────────────────────────────┘
                          │ JDBC / Hibernate ORM
                          ▼
┌─────────────────────────────────────────────────────────────┐
│           MySQL Cloud — Aiven (SSL, port 23446)              │
│                                                             │
│  users · parking_lots · bookings · shifts · violations      │
└─────────────────────────────────────────────────────────────┘
```

---

*Báo cáo được tạo tự động từ scan ổ đĩa thực tế — 01/06/2026, 03:01 (GMT+7)*
