# ✅ ParkNow – Danh sách chức năng đã hoàn thành

> **Dự án:** ParkNow – Hệ thống quản lý bãi đỗ xe thông minh  
> **Phiên bản:** v1.0.0  
> **Stack:** Flutter (Frontend) · Spring Boot + MySQL (Backend)  
> **Cập nhật:** 31/05/2026

---

## 📁 Tổng quan kiến trúc hệ thống

```
ParkNow-FullStack/
├── dh52201042_parknow/          # Flutter Mobile App
│   └── lib/
│       ├── core/                # Cấu hình, theme, tiện ích
│       ├── features/            # Feature-First + MVVM
│       │   ├── authentication/  # Đăng nhập, đăng ký
│       │   ├── parking_map/     # Bản đồ, đặt chỗ (Khách hàng)
│       │   ├── staff_scanner/   # Ca trực, vi phạm (Nhân viên)
│       │   └── admin_dashboard/ # Tổng quan, duyệt bãi xe (Admin)
│       └── shared_widgets/      # Widget dùng chung
└── back-end-parknow/            # Spring Boot REST API
    └── src/main/java/.../
        ├── model/               # JPA Entities → MySQL
        ├── repository/          # Spring Data JPA
        ├── service/             # Business Logic
        └── controller/          # REST Controllers
```

---

## 🔐 1. Xác thực & Phân quyền

### Frontend Flutter

| Màn hình | File | Chức năng |
|---|---|---|
| Chào mừng | `welcome_view.dart` | Onboarding gradient, điều hướng Đăng ký / Đăng nhập |
| Đăng ký | `register_view.dart` | Form: Họ tên, Email, SĐT, Mật khẩu, Vai trò |
| Đăng nhập | `login_view.dart` | Form Email + Mật khẩu, hiện/ẩn mật khẩu |
| Phân quyền | `login_view.dart` | Tự điều hướng: CUSTOMER → Bản đồ · STAFF → Ca trực · ADMIN → Dashboard |

- **ViewModel:** `AuthViewModel` — `isLoading`, `errorMessage`, `user`, `login()`, `register()`, `logout()`
- **Service:** `AuthService` — gọi `POST /api/users/login` và `POST /api/users/register`
- **Model:** `UserModel` — `id`, `email`, `fullName`, `phone`, `role`, `avatarUrl`

### Backend Spring Boot — `UserController`

| Endpoint | Method | Mô tả |
|---|---|---|
| `/api/users/register` | `POST` | Đăng ký tài khoản mới |
| `/api/users/login` | `POST` | Xác thực, trả về UserModel |
| `/api/users` | `GET` | Danh sách tất cả người dùng |
| `/api/users/{id}` | `GET / PUT / DELETE` | CRUD thông tin người dùng |

- **Entity:** `User` — `id`, `email`, `password`, `fullName`, `phone`, `role`

---

## 🗺️ 2. Bản đồ & Đặt chỗ (Khách hàng)

### 2.1. Màn hình Bản đồ — `parking_map_view.dart`

- ✅ Bản đồ **OpenStreetMap** (miễn phí) qua `flutter_map`
- ✅ Ghim marker từng bãi xe: màu xanh (còn chỗ) / đỏ (hết chỗ) + badge số chỗ trống
- ✅ **Bấm ghim** → `ModalBottomSheet` với: tên, địa chỉ, chỗ trống, giá/giờ, thanh lấp đầy, nút Đặt ngay
- ✅ Thanh tìm kiếm nổi, avatar người dùng
- ✅ `DraggableBottomSheet` danh sách bãi xe (kéo lên/xuống)
- ✅ 3 tab lọc: Gần tôi · Giá thấp nhất · Còn nhiều chỗ

### 2.2. Màn hình Chi tiết & Đặt chỗ — `lot_detail_view.dart`

- ✅ `SliverAppBar` gradient + thông tin nhanh (chỗ, giá, sao, khoảng cách)
- ✅ Biểu đồ phân phối đánh giá sao
- ✅ Chọn ngày (7 ngày tới), giờ bắt đầu (0–23h), thời lượng đỗ
- ✅ Nhập biển số xe, chọn loại phương tiện (Ô tô / Xe máy)
- ✅ Bảng chi phí tự tính: Phí gửi + Phí DV (5%) + Thuế (8%) = Tổng
- ✅ Nút **Đặt chỗ** bám đáy — gọi `BookingService.createBooking()`

- **ViewModel:** `ParkingMapViewModel` — `loadParkingLots()`, `parkingLots`, `isLoading`
- **Services:** `ParkingMapService`, `BookingService`
- **Models:** `ParkingLot`, `BookingModel`

### 2.3. Backend Spring Boot

**`ParkingLotController`**

| Endpoint | Method | Mô tả |
|---|---|---|
| `/api/parking-lots` | `GET` | Bãi xe đã duyệt (CUSTOMER) |
| `/api/parking-lots/all` | `GET` | Tất cả bãi xe (ADMIN) |
| `/api/parking-lots/status/{status}` | `GET` | Lọc theo `pending/approved/rejected` |
| `/api/parking-lots/{id}` | `GET / PUT / DELETE` | CRUD bãi xe |
| `/api/parking-lots/{id}/approve` | `PUT` | Admin phê duyệt |
| `/api/parking-lots/{id}/reject` | `PUT` | Admin từ chối kèm lý do |

- **Entity:** `ParkingLot` — `id`, `ownerId`, `name`, `address`, `latitude`, `longitude`, `totalSlots`, `availableSlots`, `pricePerHour`, `status`, `rejectionReason`

**`BookingController`**

| Endpoint | Method | Mô tả |
|---|---|---|
| `/api/bookings` | `GET / POST` | Danh sách / Tạo đặt chỗ mới |
| `/api/bookings/user/{userId}` | `GET` | Lịch sử đặt chỗ của user |
| `/api/bookings/lot/{lotId}` | `GET` | Đặt chỗ theo bãi |
| `/api/bookings/status/{status}` | `GET` | Lọc theo trạng thái |
| `/api/bookings/{id}/cancel` | `PUT` | Hủy đặt chỗ |
| `/api/bookings/{id}/complete` | `PUT` | Hoàn thành (xe ra) |

**Logic `BookingService`:**
- Kiểm tra `availableSlots > 0` trước khi tạo
- Tính phí tự động: `parkingFee = price × hours`, `serviceFee = 5%`, `tax = 8%`
- Tự giảm/tăng `availableSlots` khi tạo / hủy / hoàn thành

- **Entity:** `Booking` — `id`, `userId`, `parkingLotId`, `vehiclePlate`, `vehicleType`, `startTime`, `endTime`, `totalCost`, `parkingFee`, `serviceFee`, `tax`, `status (pending/confirmed/completed/cancelled)`, `createdAt`

---

## 👷 3. Ca trực & Nghiệp vụ (Nhân viên)

### 3.1. Màn hình Trang chủ Nhân viên — `staff_home_view.dart`

- ✅ `BottomNavigationBar` 3 tab: Trang chủ · Vi phạm · Hồ sơ
- ✅ Biểu đồ nửa vòng tròn (Half-Donut `CustomPaint`) tỷ lệ chỗ trống
- ✅ 2 nút hành động: **Khách vào** (`recordEntry()`) · **Khách ra** (`recordExit()`)
- ✅ Thống kê ca: Lượt vào · Lượt ra · Doanh thu
- ✅ Nút Bắt đầu ca (`startShift()`) khi chưa có ca hoạt động

### 3.2. Màn hình Hồ sơ Nhân viên — `staff_profile_view.dart`

- ✅ Avatar, tên, email nhân viên
- ✅ Đồng hồ đếm thời gian ca (HH:MM:SS)
- ✅ Grid 4 ô: Lượt vào · Lượt ra · Tiền mặt · Trực tuyến
- ✅ Nút Kết thúc ca (`endShift()`)
- ✅ Lịch sử ca trực dạng `ExpansionTile`

### 3.3. Màn hình Vi phạm — `violation_list_view.dart`

- ✅ Tab lọc: Tất cả · Chưa xử lý · Đã xử lý
- ✅ Danh sách vi phạm (biển số, lý do, ngày, badge trạng thái)
- ✅ FAB → `ModalBottomSheet` tạo vi phạm mới: biển số, loại vi phạm (4 loại), nút chụp ảnh
- ✅ Gọi `createViolation()` gửi lên API

- **ViewModel:** `StaffViewModel` — đầy đủ actions: `loadActiveShift`, `startShift`, `endShift`, `recordEntry`, `recordExit`, `loadShiftHistory`, `loadViolations`, `createViolation`, `resolveViolation`
- **Models:** `ShiftModel`, `ViolationModel`

### 3.4. Backend Spring Boot

**`ShiftController`**

| Endpoint | Method | Mô tả |
|---|---|---|
| `/api/shifts/staff/{staffId}/active` | `GET` | Ca đang hoạt động |
| `/api/shifts/staff/{staffId}` | `GET` | Lịch sử ca trực |
| `/api/shifts/start` | `POST` | Bắt đầu ca trực mới |
| `/api/shifts/{id}/end` | `PUT` | Kết thúc ca |
| `/api/shifts/{id}/entry` | `PUT` | Ghi nhận xe vào (cộng doanh thu) |
| `/api/shifts/{id}/exit` | `PUT` | Ghi nhận xe ra |

- **Entity:** `Shift` — `id`, `staffId`, `parkingLotId`, `startTime`, `endTime`, `totalIn`, `totalOut`, `cashRevenue`, `onlineRevenue`, `status (active/completed)`

**`ViolationController`**

| Endpoint | Method | Mô tả |
|---|---|---|
| `/api/violations` | `GET / POST` | Danh sách / Tạo vi phạm |
| `/api/violations/lot/{lotId}` | `GET` | Vi phạm theo bãi xe |
| `/api/violations/status/{status}` | `GET` | Lọc `pending/resolved` |
| `/api/violations/staff/{staffId}` | `GET` | Vi phạm do nhân viên báo cáo |
| `/api/violations/{id}/resolve` | `PUT` | Đánh dấu đã xử lý |
| `/api/violations/{id}` | `DELETE` | Xóa vi phạm |

- **Entity:** `Violation` — `id`, `parkingLotId`, `reportedBy`, `vehiclePlate`, `reason (wrong_spot/expired/no_ticket/other)`, `imageUrl`, `status (pending/resolved)`, `createdAt`

---

## 🛡️ 4. Bảng điều khiển (Admin) — `admin_dashboard_view.dart`

- ✅ SideNav dọc: Tổng quan · Quản lý bãi đỗ · Đăng xuất
- ✅ **Tab Tổng quan:** 4 thẻ KPI + biểu đồ đường doanh thu 7 ngày + danh sách bãi chờ duyệt
- ✅ **Tab Quản lý bãi đỗ:** tìm kiếm, lọc 4 trạng thái, thanh lấp đầy, nút Phê duyệt / Từ chối / Sửa

---

## 🔧 5. Kiến trúc kỹ thuật

| Hạng mục | Chi tiết |
|---|---|
| **Flutter pattern** | Feature-First + MVVM |
| **State management** | `ChangeNotifier` + `ListenableBuilder` |
| **HTTP** | `package:http` |
| **Bản đồ** | `flutter_map ^7.0.2` + `latlong2 ^0.9.1` (OpenStreetMap) |
| **Theme** | `AppColors` tập trung + `AppTheme.lightTheme` |
| **Backend** | Spring Boot 3.x, Maven, Spring Data JPA, Lombok |
| **Database** | MySQL (5 bảng: users, parking_lots, bookings, shifts, violations) |
| **CORS** | `@CrossOrigin(origins = "*")` toàn bộ controller |

---

## 📊 6. Tổng kết

| Hạng mục | Số lượng |
|---|---|
| Màn hình Flutter | 9 (welcome, login, register, map, lot_detail, staff_home, staff_profile, violation_list, admin_dashboard) |
| ViewModel | 3 (Auth, ParkingMap, Staff) |
| Service Flutter | 4 (Auth, ParkingMap, Booking, Staff) |
| REST API endpoint | 32+ (5 Controllers) |
| JPA Entity / DB Table | 5 |
| Model Dart | 5 |

---

## ⚠️ 7. Chưa hoàn thành / Cần bổ sung

| Chức năng | Ghi chú |
|---|---|
| Quét mã QR check-in/out | Cần thêm `mobile_scanner` |
| Chỉ đường đến bãi xe | Cần OSRM API hoặc `flutter_map_routing` |
| Runtime location permission | Cần `permission_handler` |
| Push notification | Cần Firebase Cloud Messaging |
| Xác thực JWT | Backend trả plain object, chưa có token |
| Unit test | Chưa có test cho ViewModel / Service |
| Upload ảnh vi phạm | UI có nút chụp ảnh, logic chưa kết nối |
| Quản lý user (Admin UI) | Chưa có màn hình danh sách user phía Admin |
