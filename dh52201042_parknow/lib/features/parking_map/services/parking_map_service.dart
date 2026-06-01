import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../core/constants/api_config.dart';
import '../models/parking_lot_model.dart';

import '../../../features/staff_scanner/models/violation_model.dart';

class ParkingMapService {
  // Lấy danh sách bãi xe đã được phê duyệt (dành cho Customer)
  Future<List<ParkingLot>> fetchParkingLots() async {
    try {
      final response = await http.get(Uri.parse(ApiConfig.parkingLots));

      if (response.statusCode == 200) {
        List<dynamic> body = jsonDecode(response.body);
        return body.map((item) => ParkingLot.fromJson(item)).toList();
      } else {
        throw Exception('Không thể tải danh sách bãi xe từ hệ thống.');
      }
    } catch (e) {
      throw Exception('Lỗi kết nối cơ sở dữ liệu: $e');
    }
  }

  // Lấy tất cả bãi xe (dành cho Admin)
  Future<List<ParkingLot>> fetchAllParkingLots() async {
    try {
      final response = await http.get(Uri.parse(ApiConfig.parkingLotsAll));

      if (response.statusCode == 200) {
        List<dynamic> body = jsonDecode(response.body);
        return body.map((item) => ParkingLot.fromJson(item)).toList();
      } else {
        throw Exception('Không thể tải danh sách bãi xe.');
      }
    } catch (e) {
      throw Exception('Lỗi kết nối: $e');
    }
  }

  // Lấy chi tiết một bãi xe
  Future<ParkingLot> fetchParkingLotById(int id) async {
    try {
      final response = await http.get(Uri.parse('${ApiConfig.parkingLots}/$id'));

      if (response.statusCode == 200) {
        return ParkingLot.fromJson(jsonDecode(response.body));
      } else {
        throw Exception('Không tìm thấy bãi xe.');
      }
    } catch (e) {
      throw Exception('Lỗi kết nối: $e');
    }
  }

  // Admin phê duyệt bãi xe
  Future<ParkingLot> approveParkingLot(int id) async {
    final response = await http.put(
      Uri.parse('${ApiConfig.parkingLots}/$id/approve'),
    );
    if (response.statusCode == 200) {
      return ParkingLot.fromJson(jsonDecode(response.body));
    }
    throw Exception('Phê duyệt thất bại!');
  }

  // Admin từ chối bãi xe
  Future<ParkingLot> rejectParkingLot(int id, String reason) async {
    final response = await http.put(
      Uri.parse('${ApiConfig.parkingLots}/$id/reject'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'reason': reason}),
    );
    if (response.statusCode == 200) {
      return ParkingLot.fromJson(jsonDecode(response.body));
    }
    throw Exception('Từ chối thất bại!');
  }

  // Lấy danh sách vi phạm của khách hàng (Customer)
  Future<List<ViolationModel>> fetchCustomerViolations(int customerId) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/violations/customer/$customerId'),
      );
      if (response.statusCode == 200) {
        List<dynamic> body = jsonDecode(response.body);
        return body.map((item) => ViolationModel.fromJson(item)).toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  // Thanh toán vi phạm
  Future<bool> resolveViolation(int violationId) async {
    try {
      final response = await http.put(
        Uri.parse('${ApiConfig.baseUrl}/violations/$violationId/resolve'),
      );
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}