# 🔬 PARKNOW – BÁO CÁO KIỂM TRA CHẤT LƯỢNG TOÀN DỰ ÁN
> **Senior QA / Technical Lead Audit** · 01/06/2026 · 19:15 (GMT+7)  
> Phạm vi: Toàn bộ mã nguồn tại `d:\ParkNow-FullStack`

---

## 1. 🟢 CÁC CHỨC NĂNG ĐÃ HOÀN THIỆN 100%

### 🔐 Authentication & JWT
| Chức năng | Bằng chứng File | Ghi chú |
|---|---|---|
| Đăng ký / Đăng nhập | `UserController.java` ← `AuthService.dart` ← `LoginView.dart` | BCrypt hash, JWT 24h đầy đủ |
| JWT tự động gắn vào request | `AuthenticatedClient.dart` | Tất cả authenticated request đều qua BaseClient |
| Điều hướng theo Role | `LoginView.dart` | CUSTOMER→Map, STAFF→StaffHome, ADMIN→Dashboard |
| Đăng xuất trên 3 màn hình | `StaffProfileView.dart`, `AdminDashboardView.dart`, `parking_map_view.dart` | Xóa session, về WelcomeView |

### 🗺️ Bản đồ & Đặt chỗ
| Chức năng | Bằng chứng File | Ghi chú |
|---|---|---|
| Hiển thị bản đồ OSM | `parking_map_view.dart` | FlutterMap + TileLayer hoạt động |
| Marker bãi xe có màu trạng thái | `parking_map_view.dart:322-346` | Xanh = còn chỗ, Đỏ = hết chỗ |
| Tìm kiếm & Nominatim Geocoding | `parking_map_view.dart:73-99` | Bay camera đến địa điểm tìm kiếm |
| Chỉ đường OSRM | `parking_map_view.dart:122-158` | Vẽ Polyline từ GPS→bãi xe |
| GPS định vị + cập nhật marker | `parking_map_view.dart:403-414` | Sau fix: setState cập nhật đúng |
| Chi tiết bãi xe | `lot_detail_view.dart` | Date/Hour/Duration selector hoàn chỉnh |
| Tính phí tự động (Client) | `lot_detail_view.dart:26-31` | parkingFee + 5% service + 8% tax |
| Tính phí tự động (Server) | `BookingService.java:53-63` | Đồng bộ với logic Flutter |
| Thanh toán giả lập | `payment_view.dart` | MoMo/Card/Cash, spinner loading, success dialog |
| Vé đỗ xe của tôi | `my_bookings_view.dart` | Tab hoạt động/lịch sử, load từ API |
| Sinh mã QR check-in/out | `my_bookings_view.dart:238-245` | PARKNOW:ENTRY/EXIT:bookingId đúng logic |

### 👷 Staff Scanner
| Chức năng | Bằng chứng File | Ghi chú |
|---|---|---|
| Dashboard ca trực (Half-donut) | `staff_home_view.dart:167-186` | CustomPainter, hiển thị stats thực từ VM |
| Bắt đầu / Kết thúc ca | `staff_home_view.dart + StaffViewModel.dart` | API `/shifts/start` và `/shifts/{id}/end` |
| Quét QR Check-in | `qr_scanner_view.dart:75-88` | mobile_scanner, parse PARKNOW:ENTRY, gọi API |
| Quét QR Check-out | `qr_scanner_view.dart:87-101` | Gọi `/bookings/{id}/complete` + giải phóng slot |
| QR Code nhân viên | `staff_profile_view.dart:128-219` | `qr_flutter` sinh QR từ staffCode |
| Báo cáo vi phạm + upload ảnh | `violation_list_view.dart:86-101` | Multipart upload tới `/violations/upload` |
| Lịch sử ca trực | `staff_profile_view.dart:270-298` | Load từ API, lọc `status=completed` |

### 🛡️ Admin
| Chức năng | Bằng chứng File | Ghi chú |
|---|---|---|
| Sidebar navigation 3 mục | `admin_dashboard_view.dart:70-128` | Dashboard/Bãi đỗ/Users |
| Phê duyệt / Từ chối bãi đỗ | `admin_dashboard_view.dart:197-198` | Gọi `approveParkingLot` / `rejectParkingLot` |
| CRUD User đầy đủ | `user_management_view.dart + UserAdminService.dart` | Tạo, sửa, xóa người dùng |
| Hiển thị StaffCode | `user_management_view.dart` | Chip màu nổi bật với mã STAFF_XXX |
| Tự sinh StaffCode | `UserService.java:58-66` | Format STAFF_001...không trùng lặp |

### ⚙️ Hạ tầng
| Chức năng | Bằng chứng File | Ghi chú |
|---|---|---|
| Spring Security JWT | `SecurityConfig.java + JwtAuthFilter.java` | Stateless, BCrypt, filter chain đúng |
| Bản địa hóa Tiếng Việt | `main.dart:19-28` | GlobalMaterialLocalizations + locale vi_VN |
| Thông báo đẩy in-app | `notification_service.dart` | Overlay Banner, slide animation, auto-dismiss |

---

## 2. 🟡 CÁC CHỨC NĂNG ĐANG LÀM DỞ HOẶC CÓ VẤN ĐỀ

### 🟡 VẤN ĐỀ 1: Nút "Khách vào / Khách ra" trong Staff Home là HARDCODE
**File:** `staff_home_view.dart`, dòng 87
```dart
// 🚨 PHÍ HARDCODE! Lẽ ra phải hỏi phí hoặc lấy từ ca trực
if (shift != null) _vm.recordEntry(10000, 'cash');
```
**Bản chất:** Nút "Khách vào" bấm trực tiếp ghi nhận phí xe là 10.000đ cố định, không hỏi biển số, không lấy thông tin từ booking. Đây là fallback để test thủ công nhưng không thể dùng thực tế. Nút QR Scan mới xử lý đúng.

---

### 🟡 VẤN ĐỀ 2: Số chỗ trống trong Half-donut Chart bị HARDCODE
**File:** `staff_home_view.dart`, dòng 55-56
```dart
final available = 45; // 🚨 HARDCODE!
final total = 100;    // 🚨 HARDCODE!
```
**Bản chất:** Vòng biểu đồ bán nguyệt (half-donut) luôn hiển thị 45/100 chỗ trống, không lấy từ `activeShift.parkingLotId` để truy vấn `ParkingLot.availableSlots`.

---

### 🟡 VẤN ĐỀ 3: StaffService KHÔNG gắn JWT Token vào request
**File:** `staff_service.dart` — toàn bộ file
```dart
// Sử dụng http.get/post thông thường, KHÔNG dùng AuthenticatedClient
final r = await http.get(Uri.parse('${ApiConfig.shifts}/staff/$staffId/active'));
```
**Bản chất:** Tất cả request trong `StaffService` dùng `http.get/put/post` thuần túy, không truyền JWT token. Điều này ngẫu nhiên hoạt động vì `SecurityConfig.java` chỉ cần **bất kỳ authenticated request** — nhưng nếu Backend tăng cường bảo vệ các endpoint `/api/shifts/*` và `/api/violations/*`, toàn bộ chức năng Staff sẽ vỡ ngay lập tức với lỗi 403 Forbidden.

---

### 🟡 VẤN ĐỀ 4: KPI "Doanh thu hôm nay" và "Đặt chỗ hiện có" trong Admin là HARDCODE
**File:** `admin_dashboard_view.dart`, dòng 139-140
```dart
SizedBox(width: 200, child: StatCard(title: 'Doanh thu hôm nay', value: '2.4M đ',...)),
SizedBox(width: 200, child: StatCard(title: 'Đặt chỗ hiện có',   value: '48',...)),
```
**Bản chất:** Các thẻ KPI quan trọng nhất của màn hình Admin ("Doanh thu hôm nay", "Đặt chỗ hiện có") là giá trị gắn cứng. Hệ thống hiện không có API endpoint nào tổng hợp dữ liệu dashboard (`/api/dashboard/stats`).

---

### 🟡 VẤN ĐỀ 5: Biểu đồ doanh thu 7 ngày trong Admin là GIƯỜNG CỬA
**File:** `admin_dashboard_view.dart`, dòng 249
```dart
final points = [0.3, 0.5, 0.4, 0.7, 0.6, 0.8, 0.75]; // 🚨 HARDCODE!
```
**Bản chất:** `_LineChartPainter` vẽ biểu đồ từ một mảng dữ liệu hardcode, không gọi bất kỳ API nào để lấy doanh thu thực tế theo ngày.

---

### 🟡 VẤN ĐỀ 6: parkingLotId cố định = 1 khi bắt đầu ca trực
**File:** `staff_home_view.dart`, dòng 128
```dart
onPressed: () => _vm.startShift(widget.user.id, 1), // 🚨 lotId = 1 hardcode!
```
**Bản chất:** Nhân viên bắt đầu ca trực luôn bị gán vào bãi đỗ có ID = 1. Cần có màn hình cho nhân viên chọn bãi đỗ mà họ được phân công trước khi bắt đầu ca.

---

### 🟡 VẤN ĐỀ 7: PaymentView không truyền phương thức thanh toán đã chọn lên Backend
**File:** `payment_view.dart`, dòng 40
```dart
// _selectedMethod ('momo'/'card'/'cash') được lựa chọn trên UI
// nhưng không truyền vào createBooking hoặc bất kỳ field nào
final created = await BookingService(token: widget.token).createBooking(widget.booking);
```
**Bản chất:** UI cho phép chọn phương thức thanh toán nhưng thông tin này bị bỏ qua hoàn toàn, không lưu vào DB. Backend không có trường `paymentMethod` trong model `Booking`.

---

### 🟡 VẤN ĐỀ 8: Tên bãi đỗ trong Vé đỗ xe hiển thị ID thay vì Tên thật
**File:** `my_bookings_view.dart`, dòng 191
```dart
_detailRow(Icons.local_parking_rounded, 'Bãi xe', 'Bãi đỗ xe số ${booking.parkingLotId}'),
```
**Bản chất:** Hiển thị "Bãi đỗ xe số 2" thay vì "Bãi đỗ xe ABC - 123 Nguyễn Văn A". Cần thêm một API call để resolve `parkingLotId → ParkingLot.name`.

---

### 🟡 VẤN ĐỀ 9: Upload ảnh vi phạm URL hardcode IP emulator trong Backend
**File:** `ViolationController.java`, dòng 87
```java
String url = "http://10.0.2.2:8080/uploads/violations/" + fileName; // 🚨 URL emulator!
```
**Bản chất:** URL ảnh trả về cho client hardcode địa chỉ `10.0.2.2` (IP emulator Android). URL này sẽ không hoạt động trên thiết bị thật hoặc môi trường production.

---

## 3. 🔴 CÁC CHỨC NĂNG CÒN THIẾU HOÀN TOÀN

### 🔴 THIẾU 1: Không có API Dashboard / Analytics
- Backend **không có** endpoint `/api/dashboard/*` để tổng hợp: doanh thu theo ngày, tổng booking theo status, vi phạm theo tháng.
- AdminDashboard phải dùng dữ liệu hardcode thay thế (đã nêu ở Mục 2).

### 🔴 THIẾU 2: Không có màn hình chọn Bãi đỗ khi bắt đầu ca (Staff)
- Nhân viên hiện bị gán cứng vào `parkingLotId = 1`.
- Cần màn hình "Chọn bãi đỗ để bắt đầu ca" trước khi gọi `startShift`.

### 🔴 THIẾU 3: Không có chức năng Hủy vé (Cancel Booking) cho Khách hàng
- Backend đã có `PUT /api/bookings/{id}/cancel` nhưng **MyBookingsView không có nút Hủy vé**.
- `BookingService.dart` đã có `cancelBooking()` nhưng không có UI gọi đến.

### 🔴 THIẾU 4: Không có chức năng Thêm Bãi đỗ xe mới (Admin)
- Admin chỉ có thể **duyệt/từ chối** bãi đỗ hiện có, **không thể tự tạo bãi đỗ mới** từ dashboard.
- Backend đã có `POST /api/parking-lots` nhưng Frontend không có form UI.

### 🔴 THIẾU 5: Không có chức năng Sửa bãi đỗ xe (Admin)
- Nút **"Sửa"** trong `admin_dashboard_view.dart` dòng 233:
```dart
OutlinedButton(onPressed: () {}, child: const Text('Sửa', style: TextStyle(fontSize: 12))),
```
- `onPressed: () {}` là empty callback — nút này **không làm gì cả**.

### 🔴 THIẾU 6: Không có hỗ trợ Real Device (thiết bị thật)
- `ApiConfig.baseUrl = 'http://10.0.2.2:8080/api'` — đây là IP đặc biệt chỉ dùng được trên **Android Emulator**.
- Khi test trên **điện thoại thật** qua WiFi cùng mạng, cần đổi thành IP máy tính thật (VD: `192.168.x.x`).
- Không có cơ chế cấu hình động (switch dev/prod environment).

### 🔴 THIẾU 7: Không có tính năng Thông báo real-time (WebSocket/SSE)
- Thông báo đẩy hiện tại là **giả lập thuần client-side** (chỉ hiện banner khi người dùng bấm nút trên chính thiết bị đó).
- Không có WebSocket hay Server-Sent Events để Admin/Staff nhận thông báo thời gian thực khi có booking mới, vi phạm mới, hay bãi chờ duyệt.

---

## 4. 🐞 CẢNH BÁO LỖI TIỀM ẨN

### 🐞 BUG 1: `user.id!` force-unwrap có thể gây crash — CRITICAL
**File:** `my_bookings_view.dart`, dòng 40
```dart
final list = await _bookingService.fetchBookingsByUser(widget.user.id!);
```
**Bản chất:** `UserModel.id` được khai báo kiểu `int` (non-nullable), nhưng `fromJson` có `json['id'] ?? 0` — nếu server trả về `null` cho `id`, giá trị sẽ là `0` (hợp lệ, không crash). Tuy nhiên, toán tử `!` ở đây là thừa và sai ngữ nghĩa vì `id` đã là `int` rồi.
> **Mức độ:** Medium — Lỗi compile/logic nhỏ, không crash nhưng gây nhầm lẫn cho developer.

---

### 🐞 BUG 2: `StaffViewModel` không có UserModel/Token — JWT không gửi
**File:** `staff_viewmodel.dart` dòng 7 / `staff_service.dart` toàn file
```dart
class StaffViewModel extends ChangeNotifier {
  final StaffService _service = StaffService(); // Không truyền token!
```
```dart
class StaffService {
  // Không có field token, không dùng AuthenticatedClient
  final r = await http.get(...); // Gọi thẳng http không có Authorization header
```
**Bản chất:** Tất cả request của Staff Module **không có JWT token** trong header. Điều này hoạt động hiện tại vì Spring Security chưa cấu hình strict cho `/api/shifts`, nhưng là rủi ro bảo mật và kỹ thuật rất cao.
> **Mức độ:** HIGH — Khi cần tăng cường bảo mật, toàn bộ Staff feature sẽ vỡ.

---

### 🐞 BUG 3: Không kiểm tra trạng thái booking trước khi check-in — Logic Bug
**File:** `BookingService.java`, dòng 88-96
```java
public Booking checkInBooking(Long id) {
    return bookingRepository.findById(id).map(booking -> {
        if ("checked_in".equals(booking.getStatus())) {
            throw new RuntimeException("Đặt chỗ này đã được check-in rồi!");
        }
        // 🚨 Không kiểm tra status = 'cancelled' hoặc 'completed'!
        booking.setStatus("checked_in");
```
**Bản chất:** Backend cho phép check-in một booking đã bị `cancelled` hoặc đã `completed`. Nhân viên có thể vô tình quét lại vé cũ đã hủy và hệ thống vẫn chấp nhận.
> **Mức độ:** HIGH — Lỗi nghiệp vụ nghiêm trọng, có thể gây dữ liệu sai lệch.

---

### 🐞 BUG 4: `AuthenticatedClient` không đóng inner client gây Memory Leak
**File:** `authenticated_client.dart`, dòng 15
```dart
AuthenticatedClient({this.token}) : _inner = http.Client();
```
**Bản chất:** Mỗi lần gọi `BookingService(token: ...).createBooking(...)` tạo ra một instance `AuthenticatedClient` mới với một `http.Client()` mới. Sau khi request xong, nếu widget bị dispose, `_inner` client không được đóng → **memory leak**. `AuthenticatedClient` nên là singleton hoặc phải được `close()` tường minh sau khi dùng.
> **Mức độ:** Medium — App chạy lâu có thể bị lag, đặc biệt khi user refresh nhiều lần.

---

### 🐞 BUG 5: Đồng hồ ca trực không tự cập nhật — UI Bug
**File:** `staff_profile_view.dart`, dòng 376-380
```dart
String _formatDuration(DateTime? start) {
    if (start == null) return '00:00:00';
    final d = DateTime.now().difference(start);
    return '${d.inHours.toString()...}';
}
```
**Bản chất:** `_formatDuration` tính toán đúng nhưng **không có Timer để tự động rebuild widget**. Giờ trôi qua bao nhiêu, hiển thị vẫn đứng im vì không có `setState` hay `Stream` trigger re-render mỗi giây. Cần thêm `Timer.periodic(Duration(seconds: 1), ...)`.
> **Mức độ:** Medium — Tính năng "đồng hồ đang chạy" hoàn toàn không hoạt động.

---

### 🐞 BUG 6: `Bãi đỗ ParkNow` tên bãi trên Staff Home bị hardcode
**File:** `staff_home_view.dart`, dòng 63
```dart
const Text('Bãi đỗ ParkNow', style: TextStyle(...))
```
**Bản chất:** Tên bãi đỗ xe trên màn hình chính nhân viên luôn là "Bãi đỗ ParkNow" thay vì tên thực của bãi mà ca trực đang được gán vào (`activeShift.parkingLotId`).
> **Mức độ:** Low — UI sai dữ liệu, gây nhầm lẫn.

---

### 🐞 BUG 7: `BookingRepository` cần endpoint `findByUserId` — cần xác minh
**File:** `BookingRepository.java` (cần kiểm tra)  
`BookingService.java:32` gọi `bookingRepository.findByUserId(userId)` — cần đảm bảo `BookingRepository` interface đã khai báo method này (Spring Data JPA tự sinh từ tên method).
> **Mức độ:** Low nếu interface đúng, HIGH nếu thiếu và gây NoSuchMethodError ở runtime.

---

## 📊 BẢNG ĐIỂM TỔNG KẾT

| Hạng mục | Điểm (tối đa 10) | Nhận xét |
|:---|:---:|:---|
| **Authentication & Security** | 8.5/10 | JWT tốt nhưng Staff module thiếu token |
| **Customer Map & Booking** | 8.0/10 | Chức năng cốt lõi OK, thiếu cancel booking |
| **Staff Scanner & QR** | 7.0/10 | QR đúng, nhưng hardcode nhiều, timer vỡ |
| **Admin Dashboard** | 5.5/10 | KPI hardcode, nút Sửa trống, thiếu thêm bãi |
| **Backend API** | 8.0/10 | Logic kinh doanh tốt, thiếu dashboard stats |
| **Độ đồng bộ F/E vs B/E** | 7.5/10 | Model khớp, nhưng token Staff bị bỏ sót |
| **Chất lượng code** | 7.0/10 | Memory leak, đồng hồ không chạy, URL hardcode |

### 🎯 Ưu tiên sửa lỗi đề xuất
1. 🔴 **Sửa ngay:** BUG 3 — Check-in booking đã hủy/hoàn thành (lỗi nghiệp vụ)
2. 🔴 **Sửa ngay:** BUG 2 — Truyền JWT token vào StaffService
3. 🟡 **Cần làm:** BUG 5 — Thêm Timer cho đồng hồ ca trực
4. 🟡 **Cần làm:** VẤN ĐỀ 1 & 6 — Xóa hardcode bãi xe & phí 10.000đ
5. 🟡 **Cần làm:** VẤN ĐỀ 5 — Implement nút "Sửa" bãi đỗ xe Admin
6. 🔵 **Tối ưu:** BUG 4 — Sửa memory leak trong AuthenticatedClient

---
*Báo cáo được lập bởi AI Technical Auditor · 01/06/2026 · 19:15 GMT+7*
