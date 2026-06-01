/// Cấu hình API endpoint cho ứng dụng ParkNow
class ApiConfig {
  ApiConfig._();

  // Địa chỉ base URL của Backend Spring Boot
  // 10.0.2.2 = localhost khi chạy trên Android Emulator
  static const String baseUrl = 'http://192.168.1.5:8080/api';

  // Các endpoint API
  static const String users = '$baseUrl/users';
  static const String login = '$baseUrl/users/login';
  static const String register = '$baseUrl/users/register';
  static const String parkingLots = '$baseUrl/parking-lots';
  static const String parkingLotsAll = '$baseUrl/parking-lots/all';
  static const String bookings = '$baseUrl/bookings';
  static const String shifts = '$baseUrl/shifts';
  static const String violations = '$baseUrl/violations';
  static const String dashboard = '$baseUrl/dashboard';
}
