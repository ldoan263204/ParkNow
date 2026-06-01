import 'package:flutter/material.dart';

/// Bảng màu chủ đạo của ứng dụng ParkNow
/// Customer/Admin: Gradient Xanh dương → Tím nhạt
/// Staff: Gradient Xanh ngọc → Cam
class AppColors {
  AppColors._();

  // ============================================
  // CUSTOMER / ADMIN — Blue to Purple gradient
  // ============================================
  static const Color primaryBlue = Color(0xFF4A6CF7);
  static const Color primaryPurple = Color(0xFF9B59B6);
  static const Color lightBlue = Color(0xFF6C8FF8);
  static const Color deepBlue = Color(0xFF2C3E8C);
  static const Color softPurple = Color(0xFFBB8FCE);

  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primaryBlue, primaryPurple],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient headerGradient = LinearGradient(
    colors: [Color(0xFF4A6CF7), Color(0xFF7C4DFF)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  // ============================================
  // STAFF — Teal to Orange gradient
  // ============================================
  static const Color staffTeal = Color(0xFF26A69A);
  static const Color staffOrange = Color(0xFFFF7043);
  static const Color staffTealLight = Color(0xFF4DB6AC);
  static const Color staffOrangeLight = Color(0xFFFF8A65);

  static const LinearGradient staffGradient = LinearGradient(
    colors: [staffTeal, staffOrange],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ============================================
  // NEUTRAL — Backgrounds & Text
  // ============================================
  static const Color background = Color(0xFFF5F7FA);
  static const Color cardBackground = Color(0xFFFFFFFF);
  static const Color surfaceDark = Color(0xFF1E1E2E);
  static const Color textPrimary = Color(0xFF2D3436);
  static const Color textSecondary = Color(0xFF636E72);
  static const Color textLight = Color(0xFFB2BEC3);
  static const Color divider = Color(0xFFE0E0E0);

  // ============================================
  // STATUS COLORS
  // ============================================
  static const Color success = Color(0xFF27AE60);
  static const Color warning = Color(0xFFF39C12);
  static const Color error = Color(0xFFE74C3C);
  static const Color info = Color(0xFF3498DB);

  // Tag colors
  static const Color tagPending = Color(0xFFFFF3E0);
  static const Color tagPendingText = Color(0xFFE65100);
  static const Color tagApproved = Color(0xFFE8F5E9);
  static const Color tagApprovedText = Color(0xFF2E7D32);
  static const Color tagRejected = Color(0xFFFFEBEE);
  static const Color tagRejectedText = Color(0xFFC62828);
}
