# CHƯƠNG 3. GIỚI THIỆU VỀ DỰ ÁN CÁ NHÂN

## 3.1. Lý do chọn làm dự án
Dự án cá nhân được phát triển dưới dạng một giải pháp quản lý toàn diện mang tên **ParkNow - Hệ thống quản lý bãi đỗ xe thông minh**. Đây là ứng dụng tích hợp đa vai trò (Khách hàng, Nhân viên, Quản trị viên) nhằm giải quyết nhu cầu tìm kiếm, đặt chỗ đỗ xe trực quan và tối ưu hóa quy trình quản lý vận hành bãi xe trong thực tế đô thị hiện nay. Việc lựa chọn đề tài này xuất phát từ các lý do sau:
*   **Tính thực tiễn cao:** Tình trạng thiếu bãi đỗ xe và ùn tắc tại các thành phố lớn đòi hỏi một giải pháp đặt chỗ trước (Booking), định vị bãi xe trống thời gian thực, quản lý ca trực của nhân viên và báo cáo các hành vi vi phạm nhanh chóng.
*   **Phù hợp với kiến trúc Full-Stack hiện đại:** Kết hợp ứng dụng di động **Flutter** ở phía người dùng với hệ thống backend **Spring Boot** cùng cơ sở dữ liệu **MySQL**, giúp người phát triển nắm bắt được toàn bộ vòng đời phát triển phần mềm (Full-Stack).
*   **Rèn luyện khả năng tích hợp và kiến trúc mã nguồn sạch:** Ứng dụng tích hợp bản đồ số thông qua thư viện `google_maps_flutter`, xử lý giao tiếp mạng qua HTTP Rest API, đồng thời tổ chức mã nguồn Flutter chặt chẽ theo mô hình modular **Feature-First** kết hợp **MVVM (Model-View-ViewModel)** giúp tách biệt rõ ràng giữa giao diện hiển thị, trạng thái và nghiệp vụ kết nối.

---

## 3.2. Giới thiệu về ứng dụng sẽ phát triển của dự án
Tên ứng dụng di động trong mã nguồn là `dh52201042_parknow`, khẩu hiệu **Smart Parking Management System** (Hệ thống quản lý bãi đỗ xe thông minh), phiên bản **v1.0.0+1**. 

Hệ thống được thiết kế theo hướng đa vai trò người dùng (Multi-role), trong đó mỗi nhóm người dùng sẽ tương tác với các giao diện và chức năng chuyên biệt:

| Vai trò | Màn hình / Chức năng tiêu biểu | Ý nghĩa hoạt động |
| :--- | :--- | :--- |
| **Khách hàng** *(CUSTOMER)* | `welcome_view.dart`<br>`login_view.dart`<br>`register_view.dart`<br>`parking_map_view.dart`<br>`lot_detail_view.dart` | Đăng ký, đăng nhập tài khoản. Tìm kiếm bãi đỗ xe trống trực quan trên bản đồ Google Maps, xem chi tiết bãi đỗ (sức chứa, giá vé) và thực hiện đặt chỗ đỗ xe trước (Booking) cho xe máy hoặc ô tô. |
| **Nhân viên** *(STAFF)* | `staff_home_view.dart`<br>`staff_profile_view.dart`<br>`violation_list_view.dart` | Bắt đầu/kết thúc ca trực tại bãi đỗ xe được phân công. Ghi nhận xe vào/ra bãi, tính toán chi phí đỗ thực tế, thu tiền khách hàng và lập biên bản báo cáo các trường hợp xe vi phạm quy định đỗ xe. |
| **Quản trị viên** *(ADMIN)* | `admin_dashboard_view.dart` | Theo dõi tổng quan hoạt động của hệ thống (doanh thu ngày, tổng số bãi đỗ, số ca trực đang hoạt động, số vụ vi phạm). Quản lý, phê duyệt hoặc từ chối yêu cầu tham gia hệ thống của các bãi đỗ xe mới. |

---

## 3.3. Phân tích cấu trúc thư mục và luồng xử lý chính

### 3.3.1. Cấu trúc thư mục mã nguồn
Cả hai thành phần Frontend (Flutter) và Backend (Spring Boot) của dự án đều được tổ chức phân cấp rõ ràng theo chuẩn công nghiệp:

#### 1. Cấu trúc thư mục Frontend Flutter (`lib`)
Flutter sử dụng cách tiếp cận theo **Tính năng (Feature-First)** để nhóm các file có liên quan lại với nhau, giúp dễ mở rộng quy mô dự án:

| Thư mục / File | Vai trò trong dự án |
| :--- | :--- |
| **`core/constants/api_config.dart`** | Lưu định nghĩa Base URL và toàn bộ các endpoint gọi API đến Spring Boot Backend. |
| **`core/theme/`** | Khai báo bảng màu hệ thống (`app_colors.dart`) và thiết lập kiểu dáng giao diện (`app_theme.dart`). |
| **`features/authentication/`** | Tính năng xác thực tài khoản, bao gồm `user_model.dart`, dịch vụ kết nối `auth_service.dart`, quản lý trạng thái đăng nhập `auth_viewmodel.dart` và giao diện (`login_view.dart`, `register_view.dart`, `welcome_view.dart`). |
| **`features/parking_map/`** | Tính năng dành cho khách hàng tìm bãi và đặt chỗ, chứa model bãi đỗ xe (`parking_lot_model.dart`), model đơn đặt (`booking_model.dart`), các dịch vụ nghiệp vụ liên quan cùng màn hình bản đồ (`parking_map_view.dart`) và chi tiết đặt chỗ (`lot_detail_view.dart`). |
| **`features/staff_scanner/`** | Tính năng quản lý ca trực và ghi nhận xe của nhân viên. Gồm model ca trực (`shift_model.dart`), model biên bản vi phạm (`violation_model.dart`), dịch vụ nghiệp vụ `staff_service.dart`, ViewModel điều phối trạng thái và các view làm việc. |
| **`features/admin_dashboard/`** | Tính năng quản lý của Admin gồm giao diện bảng điều khiển trung tâm (`admin_dashboard_view.dart`) để duyệt bãi xe và theo dõi thống kê doanh thu. |
| **`shared_widgets/app_widgets.dart`** | Nơi định nghĩa các thành phần giao diện dùng chung như thẻ thống kê (`StatCard`), thẻ trạng thái (`StatusTag`), nút bấm tùy chỉnh để tránh viết trùng lặp code. |
| **`main.dart`** | Điểm khởi đầu ứng dụng, thiết lập cấu hình chạy ban đầu, nạp theme và xác định màn hình hiển thị đầu tiên (`WelcomeView`). |

#### 2. Cấu trúc thư mục Backend Spring Boot (`src/main/java/.../dh52201042_parknow_backend`)
Backend Spring Boot được chia theo mô hình 4 tầng (Layered Architecture):
*   **`model`**: Chứa các thực thể (Entities) Hibernate tương ứng với các bảng cơ sở dữ liệu MySQL (`User`, `ParkingLot`, `Booking`, `Shift`, `Violation`).
*   **`repository`**: Tầng giao tiếp cơ sở dữ liệu kế thừa Spring Data JPA để thực hiện các câu lệnh truy vấn dữ liệu.
*   **`service`**: Tầng chứa toàn bộ logic nghiệp vụ (Business Logic) của hệ thống.
*   **`controller`**: Tầng tiếp nhận các yêu cầu HTTP Request từ ứng dụng Flutter, xử lý và trả về dữ liệu JSON phù hợp.

---

### 3.3.2. Mã nguồn cấu hình và điểm khởi động chính của ứng dụng

#### 1. File cấu hình API endpoints (`lib/core/constants/api_config.dart`)
```dart
/// Cấu hình API endpoint cho ứng dụng ParkNow
class ApiConfig {
  ApiConfig._();

  // Địa chỉ base URL của Backend Spring Boot
  // 10.0.2.2 = localhost khi chạy trên Android Emulator
  static const String baseUrl = 'http://10.0.2.2:8080/api';

  // Các endpoint API
  static const String users = '$baseUrl/users';
  static const String login = '$baseUrl/users/login';
  static const String register = '$baseUrl/users/register';
  static const String parkingLots = '$baseUrl/parking-lots';
  static const String parkingLotsAll = '$baseUrl/parking-lots/all';
  static const String bookings = '$baseUrl/bookings';
  static const String shifts = '$baseUrl/shifts';
  static const String violations = '$baseUrl/violations';
}
```

#### 2. Điểm khởi động ứng dụng di động (`lib/main.dart`)
```dart
import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'features/authentication/views/welcome_view.dart';

void main() {
  runApp(const ParkNowApp());
}

class ParkNowApp extends StatelessWidget {
  const ParkNowApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ParkNow',
      theme: AppTheme.lightTheme,
      debugShowCheckedModeBanner: false,
      home: const WelcomeView(), // Bắt đầu từ màn hình chào mừng
    );
  }
}
```

#### 3. Dịch vụ gọi API xác thực (`lib/features/authentication/services/auth_service.dart`)
```dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../core/constants/api_config.dart';
import '../models/user_model.dart';

class AuthService {
  // Đăng nhập tài khoản
  Future<UserModel> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.login),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      if (response.statusCode == 200) {
        return UserModel.fromJson(jsonDecode(response.body));
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['error'] ?? 'Đăng nhập thất bại!');
      }
    } catch (e) {
      throw Exception('Lỗi kết nối: $e');
    }
  }

  // Đăng ký tài khoản mới
  Future<UserModel> register({
    required String email,
    required String password,
    required String fullName,
    required String phone,
    required String role,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.register),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
          'fullName': fullName,
          'phone': phone,
          'role': role,
        }),
      );

      if (response.statusCode == 200) {
        return UserModel.fromJson(jsonDecode(response.body));
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['error'] ?? 'Đăng ký thất bại!');
      }
    } catch (e) {
      throw Exception('Lỗi kết nối: $e');
    }
  }
}
```

---

### 3.3.3. Luồng xử lý tổng quát của hệ thống
```mermaid
sequenceDiagram
    actor User as Người dùng (App)
    participant VM as ViewModel (Flutter)
    participant Service as Service (Flutter)
    participant Backend as Controller/Service (Spring Boot)
    database DB as MySQL Database

    User->>VM: Thực hiện hành động (Ví dụ: Bấm đăng nhập/Đặt chỗ)
    Note over VM: Đặt trạng thái isLoading = true<br/>Gọi notifyListeners() để cập nhật UI loading
    VM->>Service: Gọi hàm nghiệp vụ tương ứng
    Service->>Backend: Gửi HTTP Request (JSON) qua mạng
    Backend->>DB: Truy vấn/Cập nhật dữ liệu
    DB-->>Backend: Kết quả truy vấn thành công
    Backend-->>Service: Trả về HTTP Response (JSON & Status Code)
    Service-->>VM: Trả về đối tượng Model đã được parse từ JSON
    Note over VM: Lưu trữ dữ liệu mới nhận được<br/>Đặt trạng thái isLoading = false<br/>Gọi notifyListeners()
    VM-->>User: Vẽ lại giao diện UI hiển thị thông tin mới
```

1.  **Khởi động & Điều phối vai trò:** 
    Khi khởi động, người dùng tiến hành Đăng nhập thông qua `WelcomeView` -> `LoginView`. Khi có phản hồi thành công từ `AuthService`, `AuthViewModel` sẽ kiểm tra thuộc tính `role` của người dùng. Hệ thống tự động chuyển hướng người dùng đến luồng xử lý tương ứng:
    *   **`CUSTOMER`** chuyển sang màn hình bản đồ tìm bãi đỗ `ParkingMapView`.
    *   **`STAFF`** chuyển sang màn hình quản lý ca trực `StaffHomeView`.
    *   **`ADMIN`** chuyển sang màn hình bảng điều khiển trung tâm `AdminDashboardView`.
2.  **Yêu cầu và phản hồi trạng thái thông qua MVVM:**
    Mỗi khi người dùng tương tác trên màn hình (như đặt chỗ đỗ xe hoặc tạo báo cáo vi phạm), View sẽ gọi các phương thức tương ứng của ViewModel. ViewModel đặt trạng thái đang tải (`isLoading = true`), phát tín hiệu vẽ lại giao diện (như hiển thị vòng xoay tiến trình), sau đó gọi Service kết nối đến Spring Boot Backend.
3.  **Xử lý phía Backend & Phản hồi:**
    Spring Boot tiếp nhận yêu cầu thông qua các Rest Controller, gọi Service xử lý nghiệp vụ, lưu trữ hoặc cập nhật dữ liệu xuống MySQL Database (qua JPA Repository). Kết quả được mã hóa dưới dạng JSON và gửi trả về ứng dụng Flutter. 
4.  **Cập nhật dữ liệu hiển thị:**
    Flutter Service tiếp nhận dữ liệu JSON, ánh xạ thành các đối tượng Model Dart và chuyển lại cho ViewModel. ViewModel lưu dữ liệu, đặt lại `isLoading = false` và gọi `notifyListeners()`. Toàn bộ các widget đang lắng nghe ViewModel đó sẽ tự động vẽ lại giao diện bằng dữ liệu mới nhất.

---

## 3.4. Các chức năng chính của hệ thống

1.  **Đăng nhập, Đăng ký và Phân quyền:**
    Cung cấp giao diện đăng nhập và đăng ký tài khoản với đầy đủ thông tin (Họ tên, Email, Số điện thoại, Vai trò). Hệ thống thực hiện kiểm tra quyền truy cập của người dùng ở cả phía ứng dụng di động và phía Backend API.
2.  **Bản đồ tương tác & Đặt chỗ đỗ xe (Khách hàng):**
    *   Tích hợp Google Maps hiển thị vị trí các bãi đỗ xe lân cận.
    *   Khách hàng có thể nhấn vào các điểm ghim (Markers) để hiển thị nhanh thông tin bãi đỗ xe hoặc bấm vào chi tiết để xem giá vé, sức chứa trống hiện tại.
    *   Hỗ trợ tạo đơn đặt chỗ đỗ xe (Booking) bằng cách chọn loại phương tiện (xe hơi/xe máy), chọn thời gian bắt đầu và thời gian kết thúc dự kiến đỗ xe.
3.  **Quản lý ca trực & Ghi nhận xe vào/ra (Nhân viên):**
    *   Nhân viên có thể bắt đầu hoặc kết thúc ca trực của mình tại bãi đỗ xe được phân công.
    *   **Ghi nhận xe vào:** Nhập số tiền thu hoặc ghi nhận loại thanh toán để hệ thống mở rào cản và giảm số chỗ trống hiện có của bãi xe đi 1 đơn vị.
    *   **Ghi nhận xe ra:** Ghi nhận thời điểm xe rời bãi để kết thúc ca trực, tự động giải phóng vị trí đỗ (tăng số chỗ trống của bãi xe lên 1) và cộng doanh thu vào ca làm việc hiện tại của nhân viên.
4.  **Báo cáo vi phạm (Nhân viên):**
    *   Nhân viên có thể lập biên bản báo cáo các trường hợp đỗ xe sai vị trí, đỗ quá thời gian đăng ký hoặc đỗ xe không phép.
    *   Lưu trữ danh sách vi phạm cùng trạng thái xử lý để Admin/Nhân viên tiện theo dõi, xử phạt hoặc giải quyết tranh chấp.
5.  **Bảng điều khiển & Phê duyệt bãi đỗ (Admin):**
    *   Bảng điều khiển trực quan hiển thị số liệu doanh thu hôm nay, tổng bãi xe, số lượt đặt chỗ hiện có và các vi phạm cần xử lý.
    *   Biểu đồ doanh thu 7 ngày gần nhất hiển thị trực quan thông qua Custom Painter vẽ đường.
    *   Cho phép phê duyệt nhanh (`approve`) hoặc từ chối kèm lý do (`reject`) đối với các bãi đỗ xe mới gửi đơn đăng ký tham gia hệ thống.

---

## 3.5. Định hướng hoàn thiện
*   **Hoàn thiện quét mã QR:** Phát triển chức năng tạo mã QR cho mỗi đơn đặt chỗ (Booking) của khách hàng. Nhân viên bãi xe chỉ cần quét mã QR để ghi nhận xe vào/ra nhanh chóng thay vì nhập tay thông tin.
*   **Dẫn đường thời gian thực:** Tích hợp Google Direction API để cung cấp tính năng chỉ đường chi tiết từ vị trí hiện tại của người dùng đến bãi đỗ xe đã đặt.
*   **Tối ưu bảo mật cấu hình:** Loại bỏ hoàn toàn địa chỉ IP Base URL dạng tĩnh cứng trong mã nguồn, thay bằng việc sử dụng biến môi trường (qua gói `flutter_dotenv`) nhằm tăng cường tính bảo mật.
*   **Tích hợp thông báo đẩy (Push Notifications):** Sử dụng Firebase Cloud Messaging để gửi cảnh báo tự động cho khách hàng khi sắp hết giờ đỗ xe đã đặt hoặc khi có nhân viên báo cáo hành vi vi phạm.
*   **Kiểm thử chất lượng:** Bổ sung các ca kiểm thử đơn vị (Unit Tests) cho các ViewModel và Service để nâng cao tính ổn định và tránh lỗi phát sinh khi nâng cấp hệ thống.
