import 'package:intl/intl.dart';

/// Tiện ích định dạng tiền tệ Việt Nam chuẩn.
/// Ví dụ: 45200 → "45.200 đ"
class VndFormatter {
  VndFormatter._();

  static final _formatter = NumberFormat('#,###', 'vi_VN');

  /// Định dạng số thành chuỗi tiền VND có dấu chấm phân cách nghìn.
  /// [amount] có thể là int, double, BigDecimal,...
  static String format(num amount) {
    return '${_formatter.format(amount.round())} đ';
  }

  /// Định dạng ngắn gọn dùng cho biểu đồ / cards nhỏ:
  /// ≥ 1.000.000 → "1,0M đ" | ≥ 1.000 → "10K đ" | còn lại → "500 đ"
  static String compact(num amount) {
    if (amount >= 1000000) return '${(amount / 1000000).toStringAsFixed(1)}M đ';
    if (amount >= 1000) return '${(amount / 1000).toStringAsFixed(0)}K đ';
    return '${amount.round()} đ';
  }
}

/// Extension method tiện lợi để gọi trực tiếp trên num.
extension VndExtension on num {
  /// Định dạng chuẩn: 45200 → "45.200 đ"
  String toVnd() => VndFormatter.format(this);

  /// Định dạng ngắn: 1500000 → "1,5M đ"
  String toVndCompact() => VndFormatter.compact(this);
}
