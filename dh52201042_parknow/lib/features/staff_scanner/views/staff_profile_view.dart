import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/utils/vnd_formatter.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../core/theme/app_colors.dart';
import '../../../features/authentication/models/user_model.dart';
import '../models/shift_model.dart';
import '../viewmodels/staff_viewmodel.dart';

/// Màn hình hồ sơ nhân viên — hiển thị thông tin cá nhân,
/// mã QR từ staffCode, thống kê ca trực và nút đăng xuất.
class StaffProfileView extends StatefulWidget {
  final UserModel user;
  final StaffViewModel vm;
  final VoidCallback onLogout;
  const StaffProfileView({super.key, required this.user, required this.vm, required this.onLogout});
  @override
  State<StaffProfileView> createState() => _StaffProfileViewState();
}

class _StaffProfileViewState extends State<StaffProfileView> with SingleTickerProviderStateMixin {
  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;
  Timer? _clockTimer;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _fadeCtrl.forward();
    widget.vm.loadShiftHistory(widget.user.id);
    // Đồng hồ đếm thời gian ca trực — cập nhật mỗi giây
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    _fadeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final shift = widget.vm.activeShift;
    return FadeTransition(
      opacity: _fadeAnim,
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(children: [
            // ── Hồ sơ cá nhân ────────────────────────────────────
            _buildProfileCard(),
            const SizedBox(height: 20),

            // ── Mã QR nhân viên ───────────────────────────────────
            if (widget.user.staffCode != null) ...[
              _buildQrCard(),
              const SizedBox(height: 20),
            ],

            // ── Ca đang hoạt động ─────────────────────────────────
            if (shift != null) ...[
              _buildActiveShiftCard(shift),
              const SizedBox(height: 20),
            ],

            // ── Lịch sử ca trực ──────────────────────────────────
            _buildShiftHistoryCard(),
            const SizedBox(height: 20),

            // ── Nút Đăng xuất ─────────────────────────────────────
            _buildLogoutButton(),
            const SizedBox(height: 20),
          ]),
        ),
      ),
    );
  }

  // ── Profile Card ──────────────────────────────────────────────
  Widget _buildProfileCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1ABFBF), Color(0xFF0D9488)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: AppColors.staffTeal.withAlpha(80), blurRadius: 20, offset: const Offset(0, 8))],
      ),
      child: Column(children: [
        // Avatar
        CircleAvatar(
          radius: 40,
          backgroundColor: Colors.white.withAlpha(50),
          child: Text(
            widget.user.fullName.isNotEmpty ? widget.user.fullName[0].toUpperCase() : 'S',
            style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w800),
          ),
        ),
        const SizedBox(height: 12),
        Text(widget.user.fullName,
          style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800)),
        const SizedBox(height: 4),
        // Role badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(color: Colors.white.withAlpha(40), borderRadius: BorderRadius.circular(20)),
          child: const Text('👷 Nhân viên bãi đỗ xe', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
        ),
        const SizedBox(height: 16),
        // Info rows
        _infoRow(Icons.email_outlined,  widget.user.email),
        if (widget.user.phone.isNotEmpty) ...[
          const SizedBox(height: 8),
          _infoRow(Icons.phone_outlined, widget.user.phone),
        ],
        const SizedBox(height: 8),
        _infoRow(Icons.fingerprint, 'ID: #${widget.user.id}'),
      ]),
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Row(mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(icon, color: Colors.white70, size: 16),
      const SizedBox(width: 8),
      Text(text, style: const TextStyle(color: Colors.white, fontSize: 13)),
    ]);
  }

  // ── QR Code Card ──────────────────────────────────────────────
  Widget _buildQrCard() {
    final staffCode = widget.user.staffCode!;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(12), blurRadius: 16)],
      ),
      child: Column(children: [
        Row(children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: AppColors.staffTeal.withAlpha(25), borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.qr_code_2_rounded, color: AppColors.staffTeal, size: 20),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Mã QR Nhân viên', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
              Text('Dùng để Admin xác minh danh tính', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
            ]),
          ),
          // Nút copy staffCode
          GestureDetector(
            onTap: () {
              Clipboard.setData(ClipboardData(text: staffCode));
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text('Đã sao chép: $staffCode'),
                backgroundColor: AppColors.staffTeal,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                duration: const Duration(seconds: 2),
              ));
            },
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.copy_rounded, color: AppColors.textSecondary, size: 18),
            ),
          ),
        ]),
        const SizedBox(height: 20),
        // QR Code Widget
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.divider, width: 1.5),
          ),
          child: QrImageView(
            data: staffCode,
            version: QrVersions.auto,
            size: 180,
            backgroundColor: Colors.white,
            eyeStyle: const QrEyeStyle(
              eyeShape: QrEyeShape.square,
              color: Color(0xFF0D9488),
            ),
            dataModuleStyle: const QrDataModuleStyle(
              dataModuleShape: QrDataModuleShape.square,
              color: Color(0xFF1A1A2E),
            ),
          ),
        ),
        const SizedBox(height: 16),
        // StaffCode text bên dưới QR
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.staffTeal.withAlpha(20),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            staffCode,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: AppColors.staffTeal,
              letterSpacing: 3,
              fontFamily: 'monospace',
            ),
          ),
        ),
        const SizedBox(height: 8),
        const Text('Xuất trình mã này để xác minh danh tính nhân viên',
          style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
          textAlign: TextAlign.center),
      ]),
    );
  }

  // ── Ca đang hoạt động ─────────────────────────────────────────
  Widget _buildActiveShiftCard(ShiftModel shift) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(12), blurRadius: 12)],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(width: 8, height: 8, decoration: const BoxDecoration(color: AppColors.success, shape: BoxShape.circle)),
          const SizedBox(width: 8),
          const Text('Ca đang hoạt động', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        ]),
        const SizedBox(height: 16),
        Center(child: Text(
          _formatDuration(shift.startTime),
          style: const TextStyle(fontSize: 42, fontWeight: FontWeight.w900, color: AppColors.staffTeal, fontFamily: 'monospace'),
        )),
        const SizedBox(height: 16),
        GridView.count(
          crossAxisCount: 2, shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: 1.7,
          children: [
            _gridStat('Lượt vào', '${shift.totalIn}', AppColors.staffTeal),
            _gridStat('Lượt ra', '${shift.totalOut}', AppColors.staffOrange),
            _gridStat('Tiền mặt', shift.cashRevenue.toVnd(), AppColors.primaryBlue),
            _gridStat('Online', shift.onlineRevenue.toVnd(), AppColors.primaryPurple),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(width: double.infinity, child: ElevatedButton.icon(
          onPressed: () => widget.vm.endShift(),
          icon: const Icon(Icons.stop_circle_rounded),
          label: const Text('Kết thúc ca', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.staffOrange,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
        )),
      ]),
    );
  }

  // ── Lịch sử ca trực ──────────────────────────────────────────
  Widget _buildShiftHistoryCard() {
    final history = widget.vm.shiftHistory.where((s) => s.status == 'completed').take(10).toList();
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(12), blurRadius: 12)],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.history_rounded, color: AppColors.textSecondary, size: 20),
          const SizedBox(width: 8),
          const Text('Lịch sử ca trực', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          const Spacer(),
          Text('${history.length} ca', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
        ]),
        const SizedBox(height: 12),
        if (history.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Center(child: Text('Chưa có ca trực nào hoàn thành', style: TextStyle(color: AppColors.textSecondary))),
          )
        else
          ...history.map((s) => _shiftHistoryTile(s)),
      ]),
    );
  }

  Widget _shiftHistoryTile(ShiftModel shift) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(children: [
        Container(
          width: 40, height: 40,
          decoration: BoxDecoration(color: AppColors.staffTeal.withAlpha(25), borderRadius: BorderRadius.circular(10)),
          child: const Icon(Icons.access_time_rounded, color: AppColors.staffTeal, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(
            shift.startTime != null ? '${shift.startTime!.day}/${shift.startTime!.month}/${shift.startTime!.year}' : 'N/A',
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
          ),
          Text('${shift.totalIn + shift.totalOut} lượt xe', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
        ])),
        Text(
          shift.totalRevenue.toVnd(),
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.staffTeal),
        ),
      ]),
    );
  }

  // ── Logout Button ─────────────────────────────────────────────
  Widget _buildLogoutButton() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () {
          showDialog(
            context: context,
            builder: (_) => AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: const Text('Xác nhận đăng xuất', style: TextStyle(fontWeight: FontWeight.w800)),
              content: const Text('Bạn có chắc muốn đăng xuất khỏi tài khoản nhân viên không?'),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
                ElevatedButton(
                  onPressed: () { Navigator.pop(context); widget.onLogout(); },
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.error, foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                  child: const Text('Đăng xuất', style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ],
            ),
          );
        },
        icon: const Icon(Icons.logout_rounded, color: AppColors.error),
        label: const Text('Đăng xuất', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.w700, fontSize: 15)),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: AppColors.error, width: 1.5),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
    );
  }

  Widget _gridStat(String label, String value, Color color) {
    return Container(
      decoration: BoxDecoration(color: color.withAlpha(20), borderRadius: BorderRadius.circular(14)),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: color)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
      ]),
    );
  }

  String _formatDuration(DateTime? start) {
    if (start == null) return '00:00:00';
    final d = DateTime.now().difference(start);
    return '${d.inHours.toString().padLeft(2, '0')}:${(d.inMinutes % 60).toString().padLeft(2, '0')}:${(d.inSeconds % 60).toString().padLeft(2, '0')}';
  }
}
