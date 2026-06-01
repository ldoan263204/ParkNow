import 'dart:convert';
import '../../../core/constants/api_config.dart';
import '../../../core/services/authenticated_client.dart';
import '../models/shift_model.dart';
import '../models/violation_model.dart';

/// Service gọi API cho Nhân viên (Staff).
/// Tất cả request đều đính kèm JWT Token qua [AuthenticatedClient].
class StaffService {
  final String? _token;

  StaffService({String? token}) : _token = token;

  AuthenticatedClient get _client => AuthenticatedClient(token: _token);

  Future<ShiftModel?> getActiveShift(int staffId) async {
    final client = _client;
    try {
      final r = await client.get(Uri.parse('${ApiConfig.shifts}/staff/$staffId/active'));
      if (r.statusCode == 200) return ShiftModel.fromJson(jsonDecode(r.body));
      return null;
    } catch (_) {
      return null;
    } finally {
      client.close();
    }
  }

  Future<ShiftModel> startShift(int staffId, int parkingLotId) async {
    final client = _client;
    try {
      final r = await client.post(
        Uri.parse('${ApiConfig.shifts}/start'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'staffId': staffId, 'parkingLotId': parkingLotId}),
      );
      if (r.statusCode == 200) return ShiftModel.fromJson(jsonDecode(r.body));
      throw Exception('Không thể bắt đầu ca trực!');
    } finally {
      client.close();
    }
  }

  Future<ShiftModel> endShift(int shiftId) async {
    final client = _client;
    try {
      final r = await client.put(Uri.parse('${ApiConfig.shifts}/$shiftId/end'));
      if (r.statusCode == 200) return ShiftModel.fromJson(jsonDecode(r.body));
      throw Exception('Không thể kết thúc ca trực!');
    } finally {
      client.close();
    }
  }

  Future<ShiftModel> recordEntry(int shiftId, double amount, String paymentType) async {
    final client = _client;
    try {
      final r = await client.put(
        Uri.parse('${ApiConfig.shifts}/$shiftId/entry'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'amount': amount.toString(), 'paymentType': paymentType}),
      );
      if (r.statusCode == 200) return ShiftModel.fromJson(jsonDecode(r.body));
      throw Exception('Ghi nhận xe vào thất bại!');
    } finally {
      client.close();
    }
  }

  Future<ShiftModel> recordExit(int shiftId) async {
    final client = _client;
    try {
      final r = await client.put(Uri.parse('${ApiConfig.shifts}/$shiftId/exit'));
      if (r.statusCode == 200) return ShiftModel.fromJson(jsonDecode(r.body));
      throw Exception('Ghi nhận xe ra thất bại!');
    } finally {
      client.close();
    }
  }

  Future<List<ShiftModel>> getShiftHistory(int staffId) async {
    final client = _client;
    try {
      final r = await client.get(Uri.parse('${ApiConfig.shifts}/staff/$staffId'));
      if (r.statusCode == 200) {
        List<dynamic> body = jsonDecode(r.body);
        return body.map((e) => ShiftModel.fromJson(e)).toList();
      }
      throw Exception('Không thể tải lịch sử ca trực!');
    } finally {
      client.close();
    }
  }

  // Lấy vi phạm theo nhân viên (staff) — trả về list rỗng nếu lỗi thay vì throw
  Future<List<ViolationModel>> getViolations({int? staffId}) async {
    final client = _client;
    try {
      final uri = staffId != null
          ? Uri.parse('${ApiConfig.violations}/staff/$staffId')
          : Uri.parse(ApiConfig.violations);
      final r = await client.get(uri);
      if (r.statusCode == 200) {
        List<dynamic> body = jsonDecode(r.body);
        return body.map((e) => ViolationModel.fromJson(e)).toList();
      }
      return []; // Trả về rỗng thay vì throw để tránh crash UI
    } catch (_) {
      return [];
    } finally {
      client.close();
    }
  }

  Future<ViolationModel> createViolation(ViolationModel v) async {
    final client = _client;
    try {
      final r = await client.post(
        Uri.parse(ApiConfig.violations),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(v.toJson()),
      );
      if (r.statusCode == 200 || r.statusCode == 201) {
        return ViolationModel.fromJson(jsonDecode(r.body));
      }
      throw Exception('Tạo báo cáo thất bại (HTTP ${r.statusCode}): ${r.body}');
    } finally {
      client.close();
    }
  }

  Future<ViolationModel> resolveViolation(int id) async {
    final client = _client;
    try {
      final r = await client.put(Uri.parse('${ApiConfig.violations}/$id/resolve'));
      if (r.statusCode == 200) return ViolationModel.fromJson(jsonDecode(r.body));
      throw Exception('Xử lý vi phạm thất bại!');
    } finally {
      client.close();
    }
  }

  // ── Booking APIs phục vụ quét mã QR ─────────────────────────────────────────
  Future<Map<String, dynamic>> getBooking(int bookingId) async {
    final client = _client;
    try {
      final r = await client.get(Uri.parse('${ApiConfig.bookings}/$bookingId'));
      if (r.statusCode == 200) return jsonDecode(r.body);
      throw Exception('Không tìm thấy vé đỗ xe #$bookingId!');
    } finally {
      client.close();
    }
  }

  Future<void> checkInBooking(int bookingId) async {
    final client = _client;
    try {
      final r = await client.put(Uri.parse('${ApiConfig.bookings}/$bookingId/check-in'));
      if (r.statusCode != 200) {
        final msg = jsonDecode(r.body)['error'] ?? 'Không thể check-in vé đỗ xe!';
        throw Exception(msg);
      }
    } finally {
      client.close();
    }
  }

  Future<void> completeBooking(int bookingId) async {
    final client = _client;
    try {
      final r = await client.put(Uri.parse('${ApiConfig.bookings}/$bookingId/complete'));
      if (r.statusCode != 200) {
        final msg = jsonDecode(r.body)['error'] ?? 'Không thể check-out vé đỗ xe!';
        throw Exception(msg);
      }
    } finally {
      client.close();
    }
  }

  Future<List<Map<String, dynamic>>> getBookingsByLot(int lotId) async {
    final client = _client;
    try {
      final r = await client.get(Uri.parse('${ApiConfig.bookings}/lot/$lotId'));
      if (r.statusCode == 200) {
        List<dynamic> body = jsonDecode(r.body);
        return body.map((e) => e as Map<String, dynamic>).toList();
      }
      return [];
    } catch (_) {
      return [];
    } finally {
      client.close();
    }
  }

  // ── Lấy thông tin bãi đỗ (để hiển thị tên thật trong Dashboard nhân viên) ──
  Future<Map<String, dynamic>?> getParkingLot(int lotId) async {
    final client = _client;
    try {
      final r = await client.get(Uri.parse('${ApiConfig.parkingLots}/$lotId'));
      if (r.statusCode == 200) return jsonDecode(r.body);
      return null;
    } catch (_) {
      return null;
    } finally {
      client.close();
    }
  }

  // Tạo booking thủ công cho khách vãng lai
  Future<Map<String, dynamic>> createManualBooking(Map<String, dynamic> data) async {
    final client = _client;
    try {
      final r = await client.post(
        Uri.parse(ApiConfig.bookings),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(data),
      );
      if (r.statusCode == 200) {
        return jsonDecode(r.body);
      }
      final msg = jsonDecode(r.body)['error'] ?? 'Tạo đặt chỗ thất bại!';
      throw Exception(msg);
    } finally {
      client.close();
    }
  }
}
