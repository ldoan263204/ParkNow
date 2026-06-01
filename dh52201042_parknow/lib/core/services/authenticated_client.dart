import 'dart:async';
import 'package:http/http.dart' as http;

/// HTTP Client có khả năng tự động gắn JWT Token vào header Authorization.
///
/// Sử dụng:
/// ```dart
/// final client = AuthenticatedClient(token: user.token);
/// final response = await client.get(Uri.parse(ApiConfig.bookings));
/// // Nhớ close sau khi dùng để tránh memory leak!
/// client.close();
/// ```
/// Nếu token null (người dùng chưa đăng nhập), request gửi bình thường không có header.
class AuthenticatedClient extends http.BaseClient {
  final String? token;
  final http.Client _inner;

  AuthenticatedClient({this.token}) : _inner = http.Client();

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    if (token != null && token!.isNotEmpty) {
      request.headers['Authorization'] = 'Bearer $token';
    }
    return _inner.send(request);
  }

  @override
  void close() {
    _inner.close();
    super.close();
  }
}

/// Helper: thực thi một async closure với một AuthenticatedClient rồi tự đóng.
/// Tránh memory leak khi tạo nhiều instance liên tiếp.
///
/// Ví dụ:
/// ```dart
/// final result = await withAuthClient(token, (client) => client.get(uri));
/// ```
Future<T> withAuthClient<T>(
  String? token,
  Future<T> Function(AuthenticatedClient client) action,
) async {
  final client = AuthenticatedClient(token: token);
  try {
    return await action(client);
  } finally {
    client.close();
  }
}
