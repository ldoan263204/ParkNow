import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../core/constants/api_config.dart';
import '../../../core/services/authenticated_client.dart';
import '../../../features/authentication/models/user_model.dart';

/// Service quản lý user dành riêng cho Admin.
/// Tất cả request đều cần JWT (dùng AuthenticatedClient).
class UserAdminService {
  final String? _token;
  UserAdminService({String? token}) : _token = token;

  AuthenticatedClient get _client => AuthenticatedClient(token: _token);

  /// Lấy toàn bộ danh sách user
  Future<List<UserModel>> fetchAllUsers() async {
    final r = await _client.get(Uri.parse(ApiConfig.users));
    if (r.statusCode == 200) {
      final List<dynamic> body = jsonDecode(r.body);
      return body.map((e) => UserModel.fromJson(e)).toList();
    }
    throw Exception('Không thể tải danh sách người dùng');
  }

  /// Cập nhật thông tin user
  Future<UserModel> updateUser(int id, {
    required String fullName,
    required String phone,
    required String role,
  }) async {
    final r = await _client.put(
      Uri.parse('${ApiConfig.users}/$id'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'fullName': fullName, 'phone': phone, 'role': role}),
    );
    if (r.statusCode == 200) return UserModel.fromJson(jsonDecode(r.body));
    throw Exception('Cập nhật thất bại!');
  }

  /// Xóa / Khóa tài khoản
  Future<void> deleteUser(int id) async {
    final r = await _client.delete(Uri.parse('${ApiConfig.users}/$id'));
    if (r.statusCode != 204) throw Exception('Xóa tài khoản thất bại!');
  }

  /// Tạo tài khoản mới (dùng lại endpoint register công khai)
  Future<UserModel> createUser({
    required String email,
    required String password,
    required String fullName,
    required String phone,
    required String role,
  }) async {
    final r = await http.post(
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
    if (r.statusCode == 200) return UserModel.fromJson(jsonDecode(r.body));
    final err = jsonDecode(r.body);
    throw Exception(err['error'] ?? 'Tạo tài khoản thất bại!');
  }
}
