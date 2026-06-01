import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import '../../../core/theme/app_colors.dart';
import '../../../core/constants/api_config.dart';
import '../../../features/authentication/models/user_model.dart';
import '../../../features/authentication/views/welcome_view.dart';
import '../../../features/parking_map/services/parking_map_service.dart';
import '../../../features/parking_map/models/parking_lot_model.dart';
import '../../../shared_widgets/app_widgets.dart';
import 'user_management_view.dart';

class AdminDashboardView extends StatefulWidget {
  final UserModel user;
  const AdminDashboardView({super.key, required this.user});
  @override
  State<AdminDashboardView> createState() => _AdminDashboardViewState();
}

class _AdminDashboardViewState extends State<AdminDashboardView> {
  final ParkingMapService _service = ParkingMapService();
  List<ParkingLot> _allLots = [];
  int _selectedNav = 0;
  String _filterStatus = 'all';
  bool _isLoading = true;

  // Dashboard KPI từ API thực tế
  Map<String, dynamic> _stats = {};
  List<Map<String, dynamic>> _revenueChart = [];
  bool _isStatsLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
    _loadStats();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      _allLots = await _service.fetchAllParkingLots();
    } catch (_) {}
    setState(() => _isLoading = false);
  }

  Future<void> _loadStats() async {
    setState(() => _isStatsLoading = true);
    try {
      final statsRes = await http.get(Uri.parse('${ApiConfig.dashboard}/stats'));
      final chartRes = await http.get(Uri.parse('${ApiConfig.dashboard}/revenue-chart'));
      if (statsRes.statusCode == 200) _stats = jsonDecode(statsRes.body);
      if (chartRes.statusCode == 200) {
        _revenueChart = List<Map<String, dynamic>>.from(jsonDecode(chartRes.body));
      }
    } catch (_) {}
    setState(() => _isStatsLoading = false);
  }

  List<ParkingLot> get _filteredLots {
    if (_filterStatus == 'all') return _allLots;
    return _allLots.where((l) => l.status == _filterStatus).toList();
  }

  String _formatRevenue(dynamic value) {
    if (value == null) return '0đ';
    final num = double.tryParse(value.toString()) ?? 0;
    if (num >= 1000000) return '${(num / 1000000).toStringAsFixed(1)}M đ';
    if (num >= 1000) return '${(num / 1000).toStringAsFixed(0)}K đ';
    return '${num.toStringAsFixed(0)}đ';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(children: [
        _buildSideNav(),
        Expanded(child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _selectedNav == 0
                ? _buildDashboard()
                : _selectedNav == 1
                    ? _buildLotManagement()
                    : UserManagementView(adminUser: widget.user)),
      ]),
    );
  }

  void _handleLogout() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const WelcomeView()),
      (route) => false,
    );
  }

  Widget _buildSideNav() {
    return Container(
      width: 80,
      color: AppColors.surfaceDark,
      child: SafeArea(child: Column(children: [
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(gradient: AppColors.primaryGradient, borderRadius: BorderRadius.circular(14)),
          child: const Icon(Icons.local_parking, color: Colors.white, size: 24),
        ),
        const SizedBox(height: 12),
        Tooltip(
          message: '${widget.user.fullName}\n${widget.user.email}',
          child: CircleAvatar(
            radius: 20,
            backgroundColor: Colors.white.withAlpha(51),
            child: Text(
              widget.user.fullName.isNotEmpty ? widget.user.fullName[0].toUpperCase() : 'A',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16),
            ),
          ),
        ),
        const SizedBox(height: 24),
        _navItem(0, Icons.dashboard_rounded, 'Tổng quan'),
        _navItem(1, Icons.business_rounded, 'Bãi đỗ'),
        _navItem(2, Icons.people_rounded, 'Users'),
        const Spacer(),
        GestureDetector(
          onTap: _handleLogout,
          child: Container(
            width: 60, padding: const EdgeInsets.symmetric(vertical: 12), margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(color: AppColors.error.withAlpha(40), borderRadius: BorderRadius.circular(14)),
            child: const Column(children: [
              Icon(Icons.logout_rounded, color: AppColors.error, size: 24),
              SizedBox(height: 4),
              Text('Đăng xuất', style: TextStyle(color: AppColors.error, fontSize: 9, fontWeight: FontWeight.w700)),
            ]),
          ),
        ),
        const SizedBox(height: 20),
      ])),
    );
  }

  Widget _navItem(int index, IconData icon, String label) {
    final sel = _selectedNav == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedNav = index),
      child: Container(
        width: 60, padding: const EdgeInsets.symmetric(vertical: 12), margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: sel ? AppColors.primaryBlue.withAlpha(51) : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(children: [
          Icon(icon, color: sel ? AppColors.primaryBlue : Colors.white54, size: 24),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(color: sel ? AppColors.primaryBlue : Colors.white54, fontSize: 10, fontWeight: FontWeight.w600)),
        ]),
      ),
    );
  }

  // ── Dashboard chính ─────────────────────────────────────────────────────────
  Widget _buildDashboard() {
    final revenue = _formatRevenue(_stats['todayRevenue']);
    final activeBookings = _stats['activeBookings']?.toString() ?? '—';
    final pendingViolations = _stats['pendingViolations']?.toString() ?? '—';
    final totalLots = _allLots.length.toString();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Xin chào, ${widget.user.fullName}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
        const SizedBox(height: 4),
        Row(children: [
          const Text('Tổng quan hệ thống hôm nay', style: TextStyle(color: AppColors.textSecondary)),
          const Spacer(),
          IconButton(
            onPressed: () { _loadData(); _loadStats(); },
            icon: const Icon(Icons.refresh_rounded, color: AppColors.textSecondary),
            tooltip: 'Làm mới',
          ),
        ]),
        const SizedBox(height: 24),
        // 4 Stat cards — dữ liệu thực từ API
        _isStatsLoading
            ? const Center(child: CircularProgressIndicator())
            : Wrap(spacing: 16, runSpacing: 16, children: [
                SizedBox(width: 200, child: StatCard(title: 'Tổng bãi đỗ', value: totalLots, icon: Icons.business, color: AppColors.primaryBlue, changePercent: 0)),
                SizedBox(width: 200, child: StatCard(title: 'Doanh thu hôm nay', value: revenue, icon: Icons.attach_money, color: AppColors.success, changePercent: 0)),
                SizedBox(width: 200, child: StatCard(title: 'Đặt chỗ đang hoạt động', value: activeBookings, icon: Icons.event_seat, color: AppColors.warning, changePercent: 0)),
                SizedBox(width: 200, child: StatCard(title: 'Vi phạm chờ xử lý', value: pendingViolations, icon: Icons.report_problem, color: AppColors.error, changePercent: 0)),
              ]),
        const SizedBox(height: 24),
        // Biểu đồ doanh thu 7 ngày (dữ liệu thực)
        Container(
          height: 220, padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [BoxShadow(color: Colors.black.withAlpha(8), blurRadius: 10)],
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Doanh thu 7 ngày qua', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            Expanded(
              child: _revenueChart.isEmpty
                  ? const Center(child: Text('Chưa có dữ liệu doanh thu', style: TextStyle(color: AppColors.textSecondary)))
                  : CustomPaint(
                      size: Size.infinite,
                      painter: _LineChartPainter(_revenueChart),
                    ),
            ),
          ]),
        ),
        const SizedBox(height: 24),
        const Text('Bãi đỗ chờ phê duyệt', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),
        ..._allLots.where((l) => l.status == 'pending').map(_buildPendingLotCard),
      ]),
    );
  }

  // ── Quản lý bãi đỗ ─────────────────────────────────────────────────────────
  Widget _buildLotManagement() {
    return Column(children: [
      Container(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const Text('Quản lý bãi đỗ xe', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
            const Spacer(),
            // Nút Thêm bãi đỗ mới
            ElevatedButton.icon(
              onPressed: () => _showLotDialog(null),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Thêm bãi mới', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
            ),
          ]),
          const SizedBox(height: 16),
          TextField(
            decoration: InputDecoration(
              hintText: 'Tìm kiếm bãi đỗ...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 12),
          Row(children: ['all', 'pending', 'approved', 'rejected'].map((s) {
            final labels = {'all': 'Tất cả', 'pending': 'Chờ duyệt', 'approved': 'Đã duyệt', 'rejected': 'Từ chối'};
            final sel = _filterStatus == s;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: () => setState(() => _filterStatus = s),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    gradient: sel ? AppColors.primaryGradient : null,
                    color: sel ? null : AppColors.background,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(labels[s]!, style: TextStyle(color: sel ? Colors.white : AppColors.textSecondary, fontWeight: FontWeight.w600, fontSize: 13)),
                ),
              ),
            );
          }).toList()),
        ]),
      ),
      Expanded(
        child: ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          itemCount: _filteredLots.length,
          itemBuilder: (_, i) => _buildLotManagementCard(_filteredLots[i]),
        ),
      ),
    ]);
  }

  // ── Dialog Thêm / Sửa bãi đỗ ───────────────────────────────────────────────
  void _showLotDialog(ParkingLot? lot) {
    final nameCtrl = TextEditingController(text: lot?.name ?? '');
    final addressCtrl = TextEditingController(text: lot?.address ?? '');
    final latCtrl = TextEditingController(text: lot?.latitude.toString() ?? '');
    final lngCtrl = TextEditingController(text: lot?.longitude.toString() ?? '');
    final slotsCtrl = TextEditingController(text: lot?.totalSlots.toString() ?? '');
    final priceCtrl = TextEditingController(text: lot?.pricePerHour.toString() ?? '');
    bool isLoading = false;

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, dialogSetState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Text(lot == null ? '➕ Thêm bãi đỗ xe mới' : '✏️ Sửa thông tin bãi đỗ',
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
          content: SizedBox(
            width: 480,
            child: SingleChildScrollView(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                _dialogField(nameCtrl, 'Tên bãi đỗ xe', Icons.business),
                const SizedBox(height: 12),
                _dialogField(addressCtrl, 'Địa chỉ', Icons.location_on),
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(child: _dialogField(latCtrl, 'Vĩ độ (Lat)', Icons.my_location,
                      type: TextInputType.number)),
                  const SizedBox(width: 12),
                  Expanded(child: _dialogField(lngCtrl, 'Kinh độ (Lng)', Icons.my_location,
                      type: TextInputType.number)),
                ]),
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(child: _dialogField(slotsCtrl, 'Tổng chỗ đỗ', Icons.event_seat,
                      type: TextInputType.number)),
                  const SizedBox(width: 12),
                  Expanded(child: _dialogField(priceCtrl, 'Giá/giờ (đ)', Icons.attach_money,
                      type: TextInputType.number)),
                ]),
              ]),
            ),
          ),
          actions: [
            TextButton(
              onPressed: isLoading ? null : () => Navigator.pop(ctx),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: isLoading
                  ? null
                  : () async {
                      dialogSetState(() => isLoading = true);
                      try {
                        final body = {
                          'name': nameCtrl.text.trim(),
                          'address': addressCtrl.text.trim(),
                          'latitude': double.tryParse(latCtrl.text) ?? 0,
                          'longitude': double.tryParse(lngCtrl.text) ?? 0,
                          'totalSlots': int.tryParse(slotsCtrl.text) ?? 0,
                          'availableSlots': lot != null ? lot.availableSlots : (int.tryParse(slotsCtrl.text) ?? 0),
                          'pricePerHour': double.tryParse(priceCtrl.text) ?? 0,
                          'status': lot != null ? lot.status : 'pending',
                        };

                        http.Response res;
                        if (lot == null) {
                          res = await http.post(
                            Uri.parse(ApiConfig.parkingLots),
                            headers: {
                              'Content-Type': 'application/json',
                              if (widget.user.token != null) 'Authorization': 'Bearer ${widget.user.token}',
                            },
                            body: jsonEncode(body),
                          );
                        } else {
                          res = await http.put(
                            Uri.parse('${ApiConfig.parkingLots}/${lot.id}'),
                            headers: {
                              'Content-Type': 'application/json',
                              if (widget.user.token != null) 'Authorization': 'Bearer ${widget.user.token}',
                            },
                            body: jsonEncode(body),
                          );
                        }

                        if (res.statusCode == 200 && mounted) {
                          Navigator.pop(ctx);
                          _loadData();
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text(lot == null ? 'Đã thêm bãi đỗ mới!' : 'Đã cập nhật thông tin bãi đỗ!'),
                            backgroundColor: AppColors.success,
                            behavior: SnackBarBehavior.floating,
                          ));
                        } else if (mounted) {
                          final err = jsonDecode(res.body)['error'] ?? 'Thất bại!';
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text('Lỗi: $err'),
                            backgroundColor: AppColors.error,
                          ));
                        }
                      } catch (e) {
                        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi kết nối: $e')));
                      } finally {
                        dialogSetState(() => isLoading = false);
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBlue, foregroundColor: Colors.white,
              ),
              child: isLoading
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : Text(lot == null ? 'Thêm bãi đỗ' : 'Lưu thay đổi', style: const TextStyle(fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _dialogField(TextEditingController ctrl, String hint, IconData icon,
      {TextInputType type = TextInputType.text}) {
    return TextField(
      controller: ctrl,
      keyboardType: type,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, size: 18),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      ),
    );
  }

  Widget _buildPendingLotCard(ParkingLot lot) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withAlpha(8), blurRadius: 8)]),
      child: Row(children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(lot.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
          Text(lot.address, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
        ])),
        IconButton(
          onPressed: () async { await _service.approveParkingLot(lot.id); _loadData(); },
          icon: const Icon(Icons.check_circle, color: AppColors.success, size: 32),
          tooltip: 'Phê duyệt',
        ),
        IconButton(
          onPressed: () async { await _service.rejectParkingLot(lot.id, 'Không đủ điều kiện'); _loadData(); },
          icon: const Icon(Icons.cancel, color: AppColors.error, size: 32),
          tooltip: 'Từ chối',
        ),
      ]),
    );
  }

  Widget _buildLotManagementCard(ParkingLot lot) {
    Widget statusTag;
    if (lot.status == 'approved') {
      statusTag = StatusTag.approved();
    } else if (lot.status == 'rejected') {
      statusTag = StatusTag.rejected();
    } else {
      statusTag = StatusTag.pending();
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withAlpha(8), blurRadius: 8)]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Text(lot.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16))),
          statusTag,
        ]),
        const SizedBox(height: 6),
        Text(lot.address, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: lot.occupancyPercent,
                backgroundColor: AppColors.divider,
                valueColor: AlwaysStoppedAnimation(lot.occupancyPercent > 0.8 ? AppColors.error : AppColors.success),
                minHeight: 6,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text('${lot.availableSlots}/${lot.totalSlots} trống', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          if (lot.status == 'pending') ...[
            _actionBtn('Phê duyệt', AppColors.success, () async { await _service.approveParkingLot(lot.id); _loadData(); }),
            const SizedBox(width: 8),
            _actionBtn('Từ chối', AppColors.error, () async { await _service.rejectParkingLot(lot.id, 'Không đạt'); _loadData(); }),
          ],
          const Spacer(),
          // Nút Sửa (đã có logic thực)
          OutlinedButton.icon(
            onPressed: () => _showLotDialog(lot),
            icon: const Icon(Icons.edit_rounded, size: 15),
            label: const Text('Sửa', style: TextStyle(fontSize: 12)),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primaryBlue,
              side: const BorderSide(color: AppColors.primaryBlue),
            ),
          ),
        ]),
      ]),
    );
  }

  Widget _actionBtn(String label, Color color, VoidCallback onTap) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
      ),
      child: Text(label),
    );
  }
}

// ── Biểu đồ đường doanh thu (dữ liệu thực tế từ API) ────────────────────────
class _LineChartPainter extends CustomPainter {
  final List<Map<String, dynamic>> data;
  _LineChartPainter(this.data);

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    // Tính giá trị max để normalize
    final values = data.map((d) {
      final v = d['revenue'];
      return double.tryParse(v?.toString() ?? '0') ?? 0.0;
    }).toList();
    final maxVal = values.reduce((a, b) => a > b ? a : b);
    if (maxVal <= 0) return;

    final paint = Paint()
      ..color = AppColors.primaryBlue
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();
    for (int i = 0; i < values.length; i++) {
      final x = i * size.width / (values.length - 1);
      final y = size.height - (values[i] / maxVal * size.height * 0.9);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
      // Vẽ dot tại mỗi điểm
      canvas.drawCircle(Offset(x, y), 4, Paint()..color = AppColors.primaryBlue);
    }
    canvas.drawPath(path, paint);

    // Fill gradient dưới đường
    final fillPath = Path.from(path)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [AppColors.primaryBlue.withAlpha(51), AppColors.primaryBlue.withAlpha(0)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawPath(fillPath, fillPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
