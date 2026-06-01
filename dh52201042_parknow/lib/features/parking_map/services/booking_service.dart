import 'dart:convert';
import '../../../core/constants/api_config.dart';
import '../../../core/services/authenticated_client.dart';
import '../models/booking_model.dart';

/// Service đặt chỗ — sử dụng AuthenticatedClient để tự động
/// gắn JWT Token vào header Authorization của mọi request.
class BookingService {
  final String? _token;

  BookingService({String? token}) : _token = token;

  AuthenticatedClient get _client => AuthenticatedClient(token: _token);

  // Tạo đặt chỗ mới
  Future<BookingModel> createBooking(BookingModel booking) async {
    try {
      final response = await _client.post(
        Uri.parse(ApiConfig.bookings),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(booking.toJson()),
      );

      if (response.statusCode == 200) {
        return BookingModel.fromJson(jsonDecode(response.body));
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['error'] ?? 'Đặt chỗ thất bại!');
      }
    } catch (e) {
      throw Exception('Lỗi kết nối: $e');
    }
  }

  // Lấy danh sách booking theo userId
  Future<List<BookingModel>> fetchBookingsByUser(int userId) async {
    try {
      final response = await _client.get(
        Uri.parse('${ApiConfig.bookings}/user/$userId'),
      );

      if (response.statusCode == 200) {
        List<dynamic> body = jsonDecode(response.body);
        return body.map((item) => BookingModel.fromJson(item)).toList();
      } else {
        throw Exception('Không thể tải danh sách đặt chỗ.');
      }
    } catch (e) {
      throw Exception('Lỗi kết nối: $e');
    }
  }

  // Lấy tất cả booking (Admin)
  Future<List<BookingModel>> fetchAllBookings() async {
    try {
      final response = await _client.get(Uri.parse(ApiConfig.bookings));

      if (response.statusCode == 200) {
        List<dynamic> body = jsonDecode(response.body);
        return body.map((item) => BookingModel.fromJson(item)).toList();
      } else {
        throw Exception('Không thể tải danh sách đặt chỗ.');
      }
    } catch (e) {
      throw Exception('Lỗi kết nối: $e');
    }
  }

  // Hủy đặt chỗ
  Future<BookingModel> cancelBooking(int id) async {
    final response = await _client.put(
      Uri.parse('${ApiConfig.bookings}/$id/cancel'),
    );
    if (response.statusCode == 200) {
      return BookingModel.fromJson(jsonDecode(response.body));
    }
    throw Exception('Hủy đặt chỗ thất bại!');
  }

  // Lấy danh sách vị trí đỗ đang bận của bãi đỗ xe
  Future<List<String>> fetchActiveSlots(int lotId) async {
    try {
      final response = await _client.get(
        Uri.parse('${ApiConfig.bookings}/lot/$lotId/active'),
      );

      if (response.statusCode == 200) {
        List<dynamic> body = jsonDecode(response.body);
        return body.map((item) => item.toString()).toList();
      } else {
        throw Exception('Không thể tải danh sách vị trí bận.');
      }
    } catch (e) {
      throw Exception('Lỗi kết nối: $e');
    }
  }
}
