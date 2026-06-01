import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/vnd_formatter.dart';
import '../../../features/authentication/models/user_model.dart';
import '../../../features/authentication/views/welcome_view.dart';
import '../../../features/parking_map/models/parking_lot_model.dart';
import '../../../features/parking_map/services/parking_map_service.dart';
import '../viewmodels/staff_viewmodel.dart';
import '../models/shift_model.dart';
import 'qr_scanner_view.dart';
import 'staff_profile_view.dart';
import 'violation_list_view.dart';
import '../../../core/services/notification_service.dart';

class StaffHomeView extends StatefulWidget {
  final UserModel user;
  const StaffHomeView({super.key, required this.user});
  @override
  State<StaffHomeView> createState() => _StaffHomeViewState();
}

class _StaffHomeViewState extends State<StaffHomeView> {
  late final StaffViewModel _vm;
  int _currentIndex = 0;
  Timer? _clockTimer;
  Timer? _bookingPollingTimer;
  final Set<int> _notifiedBookingIds = {};
  bool _isFirstPoll = true;

  // Danh sách thông báo in-app
  final List<_InAppNotif> _notifList = [];

  @override
  void initState() {
    super.initState();
    _vm = StaffViewModel(token: widget.user.token, staffId: widget.user.id);
    _vm.loadActiveShift(widget.user.id);
    _vm.addListener(() { if (mounted) setState(() {}); });
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
    _startBookingPolling();
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    _bookingPollingTimer?.cancel();
    _vm.dispose();
    super.dispose();
  }

  void _startBookingPolling() {
    _bookingPollingTimer?.cancel();
    _bookingPollingTimer = Timer.periodic(const Duration(seconds: 8), (timer) async {
      final shift = _vm.activeShift;
      if (shift == null || !mounted) {
        _isFirstPoll = true;
        _notifiedBookingIds.clear();
        return;
      }
      try {
        final bookings = await _vm.service.getBookingsByLot(shift.parkingLotId);
        if (bookings.isEmpty) return;
        if (_isFirstPoll) {
          for (final b in bookings) {
            final id = b['id'] as int?;
            if (id != null) _notifiedBookingIds.add(id);
          }
          _isFirstPoll = false;
          return;
        }
        final newBookings = bookings.where((b) {
          final id = b['id'] as int?;
          final status = b['status'] as String?;
          return id != null && (status == 'confirmed' || status == 'pending') && !_notifiedBookingIds.contains(id);
        }).toList();

        for (final b in newBookings) {
          final id = b['id'] as int;
          _notifiedBookingIds.add(id);
          final paymentMethod = b['paymentMethod'] as String? ?? 'cash';
          final isPaid = b['paymentStatus'] == 'paid';
          final methodText = paymentMethod == 'cash' ? 'tiền mặt' : (paymentMethod == 'momo' ? 'Momo' : 'thẻ');
          final statusText = isPaid ? 'Đã thanh toán online qua $methodText ✓' : 'Thanh toán bằng $methodText tại quầy 💳';
          final notif = _InAppNotif(
            title: 'Khách đặt chỗ mới! 🚗',
            body: 'Vé #$id tại bãi của bạn. $statusText.',
            time: DateTime.now(),
          );
          setState(() => _notifList.insert(0, notif));
          if (mounted) {
            NotificationService.instance.simulateIncomingNotification(context, notif.title, notif.body);
          }
        }
      } catch (_) {}
    });
  }

  void _handleLogout() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const WelcomeView()),
      (route) => false,
    );
  }

  // ── Mở ModalBottomSheet Thông báo ────────────────────────────────────────
  void _showNotificationsSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.55,
        maxChildSize: 0.85,
        minChildSize: 0.3,
        builder: (ctx, controller) => Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Thông báo', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                  if (_notifList.isNotEmpty)
                    TextButton(
                      onPressed: () => setState(() => _notifList.clear()),
                      child: const Text('Xoá tất cả', style: TextStyle(color: AppColors.error, fontSize: 13)),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Expanded(
                child: _notifList.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.notifications_off_outlined, size: 56, color: Colors.grey.shade300),
                            const SizedBox(height: 12),
                            const Text('Chưa có thông báo nào', style: TextStyle(color: AppColors.textSecondary)),
                          ],
                        ),
                      )
                    : ListView.separated(
                        controller: controller,
                        itemCount: _notifList.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (_, i) {
                          final n = _notifList[i];
                          return ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                            leading: Container(
                              width: 42, height: 42,
                              decoration: BoxDecoration(
                                color: AppColors.staffTeal.withAlpha(25),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.notifications_active_rounded, color: AppColors.staffTeal, size: 22),
                            ),
                            title: Text(n.title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                            subtitle: Text(n.body, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                            trailing: Text(
                              '${n.time.hour.toString().padLeft(2, '0')}:${n.time.minute.toString().padLeft(2, '0')}',
                              style: const TextStyle(fontSize: 11, color: AppColors.textLight),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Dialog chọn bãi đỗ bắt đầu ca ───────────────────────────────────────
  Future<void> _showStartShiftDialog() async {
    List<ParkingLot> lots = [];
    try {
      lots = await ParkingMapService().fetchParkingLots();
      lots = lots.where((l) => l.status == 'approved').toList();
    } catch (_) { lots = []; }
    if (!mounted) return;
    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      isScrollControlled: true,
      builder: (_) => _StartShiftSheet(lots: lots, isLoading: false, onStartShift: (int lotId) async {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đang bắt đầu ca trực... ⏳'), duration: Duration(seconds: 1)),
        );
        try {
          await _vm.startShift(widget.user.id, lotId);
          if (_vm.error.isNotEmpty) {
            if (mounted) ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Lỗi bắt đầu ca: ${_vm.error}'), backgroundColor: AppColors.error),
            );
          } else {
            if (mounted) ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Bắt đầu ca trực thành công! 🚀'), backgroundColor: AppColors.success),
            );
          }
        } catch (e) {
          if (mounted) ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Lỗi: $e'), backgroundColor: AppColors.error),
          );
        }
      }),
    );
  }

  void _handleScanWithAction(String? action) {
    if (_vm.activeShift == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Vui lòng bắt đầu ca trực trước khi quét xe ${action == 'ENTRY' ? 'VÀO' : action == 'EXIT' ? 'RA' : 'vào/ra'}!'),
        backgroundColor: AppColors.error,
      ));
      return;
    }
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => QrScannerView(user: widget.user, vm: _vm, allowedAction: action),
    ));
  }

  void _showManualCheckInDialog() {
    if (_vm.activeShift == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Vui lòng bắt đầu ca trực trước khi làm check-in!'),
        backgroundColor: AppColors.error,
      ));
      return;
    }

    final plateController = TextEditingController();
    String vehicleType = 'car'; // Mặc định: car

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.login_rounded, color: AppColors.staffTeal),
              SizedBox(width: 8),
              Text('Khách vào thủ công', style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Nhập thông tin phương tiện để check-in trực tiếp:',
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: plateController,
                textCapitalization: TextCapitalization.characters,
                decoration: InputDecoration(
                  labelText: 'Biển số xe',
                  hintText: 'Ví dụ: 59G1-12345',
                  prefixIcon: const Icon(Icons.directions_car_rounded),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 16),
              const Text('Loại phương tiện:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: ChoiceChip(
                      label: const Center(child: Text('Ô tô')),
                      selected: vehicleType == 'car',
                      onSelected: (selected) {
                        if (selected) setStateDialog(() => vehicleType = 'car');
                      },
                      selectedColor: AppColors.staffTeal.withAlpha(40),
                      labelStyle: TextStyle(
                        color: vehicleType == 'car' ? AppColors.staffTeal : AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ChoiceChip(
                      label: const Center(child: Text('Xe máy')),
                      selected: vehicleType == 'motorbike',
                      onSelected: (selected) {
                        if (selected) setStateDialog(() => vehicleType = 'motorbike');
                      },
                      selectedColor: AppColors.staffTeal.withAlpha(40),
                      labelStyle: TextStyle(
                        color: vehicleType == 'motorbike' ? AppColors.staffTeal : AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: () async {
                final plate = plateController.text.trim();
                if (plate.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Vui lòng nhập biển số xe!'), backgroundColor: AppColors.error),
                  );
                  return;
                }
                Navigator.pop(ctx);
                
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Đang ghi nhận xe vào... ⏳'), duration: Duration(seconds: 1)),
                );

                await _vm.checkInManual(plate, vehicleType, widget.user.id);

                if (mounted) {
                  if (_vm.error.isNotEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Lỗi: ${_vm.error}'), backgroundColor: AppColors.error),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Ghi nhận xe vào thành công! 🚀'), backgroundColor: AppColors.success),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.staffTeal,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Xác nhận vào'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _currentIndex == 0
          ? _buildOperationsHome()
          : _currentIndex == 1
              ? ViolationListView(user: widget.user, vm: _vm)
              : StaffProfileView(user: widget.user, vm: _vm, onLogout: _handleLogout),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
        selectedItemColor: AppColors.staffTeal,
        unselectedItemColor: AppColors.textSecondary,
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        elevation: 8,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: 'Trang chủ'),
          BottomNavigationBarItem(icon: Icon(Icons.report_problem_rounded), label: 'Vi phạm'),
          BottomNavigationBarItem(icon: Icon(Icons.person_rounded), label: 'Hồ sơ'),
        ],
      ),
    );
  }

  Widget _buildOperationsHome() {
    final shift = _vm.activeShift;
    final totalSlots = _vm.activeLotTotalSlots;
    final available = _vm.activeLotAvailableSlots;
    final ratio = totalSlots > 0 ? available / totalSlots : 1.0;
    final hasNotif = _notifList.isNotEmpty;

    return Container(
      decoration: const BoxDecoration(gradient: AppColors.staffGradient),
      child: SafeArea(
        child: Column(
          children: [
            // ── Header ─────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          shift != null ? _vm.activeLotName : 'Hệ thống ParkNow',
                          style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900),
                          maxLines: 1, overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(children: [
                          Container(
                            width: 8, height: 8,
                            margin: const EdgeInsets.only(right: 6),
                            decoration: BoxDecoration(
                              color: shift != null ? Colors.greenAccent : Colors.white38,
                              shape: BoxShape.circle,
                            ),
                          ),
                          Text(
                            shift != null ? 'Ca trực đang hoạt động' : 'Chưa bắt đầu ca',
                            style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500),
                          ),
                        ]),
                      ],
                    ),
                  ),
                  // Nút chuông thông báo
                  IconButton(
                    onPressed: _showNotificationsSheet,
                    icon: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        const Icon(Icons.notifications_rounded, color: Colors.white, size: 26),
                        if (hasNotif)
                          Positioned(
                            right: -2,
                            top: -2,
                            child: Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: AppColors.staffOrange,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ── Thẻ nội dung chính ──────────────────────────────────────
            Expanded(
              child: Container(
                margin: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(20),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    )
                  ],
                ),
                child: shift == null 
                    ? _buildOfflinePlaceholder() 
                    : _buildActiveShiftDashboard(available, totalSlots, ratio, shift),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Giao diện khi chưa bắt đầu ca trực
  Widget _buildOfflinePlaceholder() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.staffTeal.withAlpha(15),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.work_off_rounded,
              color: AppColors.staffTeal,
              size: 72,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Bạn đang ngoại tuyến',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 10),
          const Text(
            'Chọn bãi đỗ xe được phân công và bấm nút dưới đây để bắt đầu nhận ca trực, soát vé và quản lý vi phạm.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondary, fontSize: 14, height: 1.5),
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton.icon(
              onPressed: _showStartShiftDialog,
              icon: const Icon(Icons.play_arrow_rounded, size: 22),
              label: const Text('Bắt đầu ca trực', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.staffTeal,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 4,
                shadowColor: AppColors.staffTeal.withAlpha(100),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Giao diện dashboard khi đang trong ca trực
  Widget _buildActiveShiftDashboard(int available, int totalSlots, double ratio, ShiftModel shift) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // 1. Biểu đồ chỗ trống
          Container(
            height: 140,
            width: double.infinity,
            alignment: Alignment.bottomCenter,
            child: Stack(
              alignment: Alignment.bottomCenter,
              children: [
                Positioned.fill(
                  child: CustomPaint(
                    painter: _HalfDonutPainter(ratio),
                  ),
                ),
                Positioned(
                  bottom: 24,
                  left: 0,
                  right: 0,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '$available',
                        style: TextStyle(
                          fontSize: 38,
                          fontWeight: FontWeight.w900,
                          color: available > 0 ? AppColors.staffTeal : AppColors.error,
                          height: 1.0,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '/$totalSlots còn trống',
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // 2. Thống kê nhanh trong ca (Lượt vào, Lượt ra, Doanh thu)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade100),
            ),
            child: Row(
              children: [
                _statMini('Khách vào', '${shift.totalIn}', AppColors.staffTeal),
                Container(width: 1, height: 30, color: Colors.grey.shade300),
                _statMini('Khách ra', '${shift.totalOut}', AppColors.staffOrange),
                Container(width: 1, height: 30, color: Colors.grey.shade300),
                _statMini('Doanh thu ca', shift.totalRevenue.toVndCompact(), AppColors.primaryBlue),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // 3. Thao tác chính
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Thao tác ca trực',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
            ),
          ),
          const SizedBox(height: 10),



          // Nút Quét mã QR chính
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: () => _handleScanWithAction(null),
              icon: const Icon(Icons.qr_code_scanner_rounded, size: 20),
              label: const Text('Quét mã QR (Vào / Ra)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.staffTeal,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 2,
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Row 2 nút Khách Vào / Ra thủ công
          Row(
            children: [
              _actionButton(
                'Khách vào',
                Icons.login_rounded,
                const LinearGradient(
                  colors: [Color(0xFF00B4DB), Color(0xFF0083B0)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                _showManualCheckInDialog,
              ),
              const SizedBox(width: 12),
              _actionButton(
                'Khách ra',
                Icons.logout_rounded,
                const LinearGradient(
                  colors: [Color(0xFFF857A6), Color(0xFFFF5858)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                () => _handleScanWithAction('EXIT'),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // 4. Nút đóng ca trực
          SizedBox(
            width: double.infinity,
            child: TextButton.icon(
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Kết thúc ca trực?'),
                    content: const Text('Hệ thống sẽ tổng kết doanh thu và lượt xe trong ca trực của bạn.'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        style: TextButton.styleFrom(foregroundColor: AppColors.error),
                        child: const Text('Kết thúc'),
                      ),
                    ],
                  ),
                );
                if (confirm == true) {
                  await _vm.endShift();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Đã kết thúc ca trực thành công!'), backgroundColor: AppColors.success),
                    );
                  }
                }
              },
              icon: const Icon(Icons.power_settings_new_rounded, color: AppColors.error, size: 18),
              label: const Text('Kết thúc ca trực này', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.bold, fontSize: 14)),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                backgroundColor: AppColors.error.withAlpha(15),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionButton(String label, IconData icon, LinearGradient gradient, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 60,
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: gradient.colors.last.withAlpha(60),
                blurRadius: 10,
                offset: const Offset(0, 4),
              )
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statMini(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(color: color.withAlpha(20), borderRadius: BorderRadius.circular(12)),
        child: Column(
          children: [
            Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: color)),
            const SizedBox(height: 2),
            Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }
}

// ── Model thông báo in-app ─────────────────────────────────────────────────
class _InAppNotif {
  final String title, body;
  final DateTime time;
  _InAppNotif({required this.title, required this.body, required this.time});
}

// ── Sheet chọn bãi đỗ ─────────────────────────────────────────────────────
class _StartShiftSheet extends StatelessWidget {
  final List<ParkingLot> lots;
  final bool isLoading;
  final void Function(int lotId) onStartShift;
  const _StartShiftSheet({required this.lots, required this.isLoading, required this.onStartShift});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 16),
          const Text('Chọn bãi đỗ để bắt đầu ca', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          const Text('Chọn bãi đỗ xe bạn được phân công hôm nay.', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          const SizedBox(height: 16),
          if (isLoading)
            const Center(child: CircularProgressIndicator())
          else if (lots.isEmpty)
            const Center(child: Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Column(children: [
                Icon(Icons.business_outlined, size: 48, color: AppColors.textLight),
                SizedBox(height: 8),
                Text('Không có bãi đỗ xe nào khả dụng', style: TextStyle(color: AppColors.textSecondary)),
              ]),
            ))
          else
            ConstrainedBox(
              constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.45),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: lots.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (_, i) {
                  final lot = lots[i];
                  return GestureDetector(
                    onTap: () => onStartShift(lot.id),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.divider),
                      ),
                      child: Row(children: [
                        Container(
                          width: 44, height: 44,
                          decoration: BoxDecoration(color: AppColors.staffTeal.withAlpha(25), borderRadius: BorderRadius.circular(12)),
                          child: const Icon(Icons.local_parking, color: AppColors.staffTeal, size: 22),
                        ),
                        const SizedBox(width: 12),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(lot.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                          Text(lot.address, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary), maxLines: 1, overflow: TextOverflow.ellipsis),
                        ])),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(color: AppColors.staffTeal.withAlpha(20), borderRadius: BorderRadius.circular(8)),
                          child: Text('${lot.availableSlots} chỗ', style: const TextStyle(color: AppColors.staffTeal, fontSize: 12, fontWeight: FontWeight.w700)),
                        ),
                      ]),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

// ── Half-Donut Painter ─────────────────────────────────────────────────────
class _HalfDonutPainter extends CustomPainter {
  final double percent;
  _HalfDonutPainter(this.percent);

  @override
  void paint(Canvas canvas, Size size) {
    // Tâm nằm sát đáy (trừ đi khoảng cách nhỏ để không bị cắt xén ở các góc bo)
    final center = Offset(size.width / 2, size.height - 12);
    const radius = 82.0;
    const sw = 15.0;

    final paintBg = Paint()
      ..color = AppColors.divider.withAlpha(90)
      ..style = PaintingStyle.stroke
      ..strokeWidth = sw
      ..strokeCap = StrokeCap.round;

    final paintFg = Paint()
      ..color = percent > 0.3 ? AppColors.staffTeal : AppColors.error
      ..style = PaintingStyle.stroke
      ..strokeWidth = sw
      ..strokeCap = StrokeCap.round;

    // Vẽ cung nền bán nguyệt (từ góc pi đến 2*pi)
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      pi,
      pi,
      false,
      paintBg,
    );

    // Vẽ cung tiến trình
    if (percent > 0) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        pi,
        pi * percent.clamp(0.0, 1.0),
        false,
        paintFg,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _HalfDonutPainter oldDelegate) => oldDelegate.percent != percent;
}
