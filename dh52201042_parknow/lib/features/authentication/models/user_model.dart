/// Model người dùng ParkNow (sau khi tích hợp JWT)
class UserModel {
  final int id;
  final String email;
  final String fullName;
  final String phone;
  final String role; // CUSTOMER, STAFF, ADMIN
  final String? avatarUrl;

  /// JWT access token nhận từ Backend sau khi login/register.
  /// Dùng để gửi kèm trong header Authorization của mọi request.
  final String? token;

  /// Mã nhân viên — chỉ có ở tài khoản STAFF, null với CUSTOMER/ADMIN.
  /// Format: STAFF_001, STAFF_002, ...
  final String? staffCode;

  UserModel({
    required this.id,
    required this.email,
    required this.fullName,
    required this.phone,
    required this.role,
    this.avatarUrl,
    this.token,
    this.staffCode,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id:        json['id'] ?? 0,
      email:     json['email'] ?? '',
      fullName:  json['fullName'] ?? '',
      phone:     json['phone'] ?? '',
      role:      json['role'] ?? 'CUSTOMER',
      avatarUrl: json['avatarUrl'],
      token:     json['token'],          // JWT token từ AuthResponse
      staffCode: json['staffCode'],      // Mã nhân viên (chỉ STAFF)
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'email':     email,
      'fullName':  fullName,
      'phone':     phone,
      'role':      role,
      'avatarUrl': avatarUrl,
      if (staffCode != null) 'staffCode': staffCode,
    };
  }

  /// Kiểm tra user có phải là nhân viên hay không
  bool get isStaff => role.toUpperCase() == 'STAFF';
  bool get isAdmin => role.toUpperCase() == 'ADMIN';
  bool get isCustomer => role.toUpperCase() == 'CUSTOMER';
}
