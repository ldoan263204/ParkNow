import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:qr_flutter/qr_flutter.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/constants/api_config.dart';
import '../../../core/utils/vnd_formatter.dart';
import '../../../features/authentication/models/user_model.dart';
import '../models/booking_model.dart';
import '../services/booking_service.dart';

class MyBookingsView extends StatefulWidget {
  final UserModel user;
  const MyBookingsView({super.key, required this.user});

  @override
  State<MyBookingsView> createState() => _MyBookingsViewState();
}

class _MyBookingsViewState extends State<MyBookingsView> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late BookingService _bookingService;
  List<BookingModel> _bookings = [];
  bool _isLoading = true;

  /// Cache tên bãi đỗ: lotId → lotName
  final Map<int, String> _lotNameCache = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _bookingService = BookingService(token: widget.user.token);
    _loadBookings();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadBookings() async {
    setState(() => _isLoading = true);
    try {
      final list = await _bookingService.fetchBookingsByUser(widget.user.id);
      setState(() => _bookings = list);
      // Resolve tên bãi đỗ cho tất cả booking
      final uniqueLotIds = _bookings.map((b) => b.parkingLotId).toSet();
      for (final lotId in uniqueLotIds) {
        if (!_lotNameCache.containsKey(lotId)) {
          _fetchLotName(lotId);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi tải danh sách: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// Lấy tên bãi đỗ từ API và cập nhật cache
  Future<void> _fetchLotName(int lotId) async {
    try {
      final r = await http.get(Uri.parse('${ApiConfig.parkingLots}/$lotId'));
      if (r.statusCode == 200) {
        final data = jsonDecode(r.body);
        if (mounted) {
          setState(() => _lotNameCache[lotId] = data['name'] ?? 'Bãi đỗ #$lotId');
        }
      }
    } catch (_) {}
  }

  /// Hủy vé đỗ xe
  Future<void> _cancelBooking(BookingModel booking) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Xác nhận hủy vé', style: TextStyle(fontWeight: FontWeight.w800)),
        content: Text('Bạn có chắc muốn hủy vé đỗ xe tại ${_lotNameCache[booking.parkingLotId] ?? 'bãi xe này'} không?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Không')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error, foregroundColor: Colors.white),
            child: const Text('Hủy vé', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await _bookingService.cancelBooking(booking.id!);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã hủy vé thành công!'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
      _loadBookings();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi hủy vé: $e'), backgroundColor: AppColors.error),
      );
    }
  }

  List<BookingModel> get _activeBookings => _bookings
      .where((b) => b.status == 'pending' || b.status == 'confirmed' || b.status == 'checked_in')
      .toList();

  List<BookingModel> get _historyBookings => _bookings
      .where((b) => b.status == 'completed' || b.status == 'cancelled')
      .toList();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Vé đỗ xe của tôi', style: TextStyle(fontWeight: FontWeight.w800)),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0.5,
        actions: [
          IconButton(icon: const Icon(Icons.refresh_rounded), onPressed: _loadBookings),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primaryBlue,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primaryBlue,
          indicatorWeight: 3,
          tabs: const [
            Tab(text: 'Vé hoạt động'),
            Tab(text: 'Lịch sử'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(AppColors.primaryBlue)))
          : TabBarView(
              controller: _tabController,
              children: [
                _buildBookingList(_activeBookings, isActive: true),
                _buildBookingList(_historyBookings, isActive: false),
              ],
            ),
    );
  }

  Widget _buildBookingList(List<BookingModel> list, {required bool isActive}) {
    if (list.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isActive ? Icons.confirmation_number_outlined : Icons.history_rounded,
              size: 64, color: AppColors.textLight,
            ),
            const SizedBox(height: 16),
            Text(
              isActive ? 'Không có vé nào đang hoạt động' : 'Chưa có lịch sử đặt vé',
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 15, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadBookings,
      color: AppColors.primaryBlue,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        itemCount: list.length,
        itemBuilder: (context, index) => _buildBookingCard(list[index], isActive),
      ),
    );
  }

  Widget _buildBookingCard(BookingModel booking, bool isActive) {
    final statusColor = _getStatusColor(booking.status);
    final statusLabel = _getStatusLabel(booking.status);
    final format = DateFormat('HH:mm dd/MM/yyyy');
    final lotName = _lotNameCache[booking.parkingLotId] ?? 'Đang tải...';
    final canCancel = isActive && booking.status != 'checked_in';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(5), blurRadius: 10, offset: const Offset(0, 4))],
        border: Border.all(color: AppColors.divider),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header card
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: AppColors.background,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Mã vé: #${booking.id}',
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: AppColors.textPrimary)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withAlpha(25),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(statusLabel,
                        style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
            // Body card
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Tên bãi đỗ thực tế (từ API)
                  _detailRow(Icons.local_parking_rounded, 'Bãi xe', lotName),
                  const SizedBox(height: 8),
                  _detailRow(Icons.access_time_rounded, 'Bắt đầu', format.format(booking.startTime)),
                  const SizedBox(height: 8),
                  _detailRow(Icons.watch_later_outlined, 'Kết thúc', format.format(booking.endTime)),
                  const SizedBox(height: 8),
                  _detailRow(Icons.directions_car_rounded, 'Xe & Biển số',
                      '${booking.vehicleType == 'car' ? 'Ô tô' : 'Xe máy'} - ${booking.vehiclePlate}'),
                  if (booking.paymentMethod != null) ...[ 
                    const SizedBox(height: 8),
                    _detailRow(Icons.payment_rounded, 'Thanh toán', _getPaymentMethodLabel(booking.paymentMethod)),
                  ],
                  if (booking.totalCost != null) ...[
                    const Divider(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          booking.paymentStatus == 'paid' ? 'Đã thanh toán ✓' : 'Chờ thanh toán tại quầy',
                          style: TextStyle(
                            color: booking.paymentStatus == 'paid' ? AppColors.success : AppColors.warning,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          booking.totalCost!.toVnd(),
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.primaryBlue),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            // Các nút hành động
            if (isActive)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Row(
                  children: [
                    // Nút xem QR
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _showQRDialog(booking),
                        icon: const Icon(Icons.qr_code_rounded, size: 18),
                        label: const Text('Xem mã QR', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryBlue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 11),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                      ),
                    ),
                    if (canCancel) ...[
                      const SizedBox(width: 10),
                      // Nút hủy vé
                      OutlinedButton.icon(
                        onPressed: () => _cancelBooking(booking),
                        icon: const Icon(Icons.cancel_outlined, size: 18),
                        label: const Text('Hủy vé', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.error,
                          side: const BorderSide(color: AppColors.error),
                          padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showQRDialog(BookingModel booking) {
    showDialog(
      context: context,
      builder: (context) => DefaultTabController(
        length: 2,
        child: Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Mã QR vé đỗ xe',
                      style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: AppColors.textPrimary),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TabBar(
                  labelColor: AppColors.primaryBlue,
                  unselectedLabelColor: AppColors.textSecondary,
                  indicatorColor: AppColors.primaryBlue,
                  indicatorWeight: 3,
                  indicatorSize: TabBarIndicatorSize.tab,
                  labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  tabs: const [
                    Tab(text: 'MÃ VÀO (ENTRY)', icon: Icon(Icons.login_rounded, size: 18)),
                    Tab(text: 'MÃ RA (EXIT)', icon: Icon(Icons.logout_rounded, size: 18)),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 250,
                  child: TabBarView(
                    children: [
                      // Tab 1: Entry
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.background,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppColors.divider),
                            ),
                            child: QrImageView(
                              data: 'PARKNOW:ENTRY:${booking.id}',
                              version: QrVersions.auto,
                              size: 150.0,
                            ),
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            'Đưa mã này cho nhân viên quét khi xe VÀO bãi.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: AppColors.textSecondary, fontSize: 12, height: 1.4),
                          ),
                        ],
                      ),
                      // Tab 2: Exit
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppColors.background,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: AppColors.divider),
                                ),
                                child: QrImageView(
                                  data: 'PARKNOW:EXIT:${booking.id}',
                                  version: QrVersions.auto,
                                  size: 150.0,
                                ),
                              ),
                              const SizedBox(height: 10),
                              const Text(
                                'Đưa mã này cho nhân viên quét khi xe RA khỏi bãi.',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: AppColors.textSecondary, fontSize: 12, height: 1.4),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Text('Vé đỗ xe #${booking.id}',
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppColors.textSecondary, size: 16),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
        const Spacer(),
        Flexible(
          child: Text(value,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.textPrimary),
              textAlign: TextAlign.right),
        ),
      ],
    );
  }

  String _getPaymentMethodLabel(String? method) {
    switch (method) {
      case 'momo': return 'Ví MoMo';
      case 'card': return 'Thẻ ATM/Visa';
      case 'cash': return 'Tiền mặt tại quầy';
      default: return method ?? 'Không rõ';
    }
  }

  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'pending': return Colors.orange;
      case 'confirmed': return AppColors.primaryBlue;
      case 'checked_in': return AppColors.staffTeal;
      case 'completed': return AppColors.success;
      case 'cancelled': return AppColors.error;
      default: return AppColors.textSecondary;
    }
  }

  String _getStatusLabel(String? status) {
    switch (status?.toLowerCase()) {
      case 'pending': return 'Chờ thanh toán';
      case 'confirmed': return 'Đã thanh toán';
      case 'checked_in': return 'Đang đỗ xe';
      case 'completed': return 'Đã hoàn thành';
      case 'cancelled': return 'Đã hủy';
      default: return 'Không rõ';
    }
  }
}
