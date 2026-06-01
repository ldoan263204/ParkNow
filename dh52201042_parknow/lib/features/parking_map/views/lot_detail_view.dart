import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/utils/vnd_formatter.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/services/location_service.dart';
import '../../../shared_widgets/app_widgets.dart';
import '../models/parking_lot_model.dart';
import '../models/booking_model.dart';
import '../services/booking_service.dart';
import 'payment_view.dart';

class LotDetailView extends StatefulWidget {
  final ParkingLot lot;
  final int userId;
  final String? token; // JWT token để gọi API đặt chỗ
  final LatLng? userLocation;
  const LotDetailView({super.key, required this.lot, required this.userId, this.token, this.userLocation});

  @override
  State<LotDetailView> createState() => _LotDetailViewState();
}

class _LotDetailViewState extends State<LotDetailView> {
  late DateTime _selectedDate;
  late int _selectedHour;
  int _durationHours = 2;
  String _vehicleType = 'car';
  final _plateController = TextEditingController();
  bool _isBooking = false;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    if (now.hour >= 23) {
      _selectedDate = now.add(const Duration(days: 1));
      _selectedHour = 0;
    } else {
      _selectedDate = now;
      _selectedHour = now.hour + 1;
    }
  }

  // State quản lý vị trí đỗ (Slot Picker)
  String? _selectedSlot;
  List<String> _occupiedSlots = [];
  bool _isLoadingSlots = false;

  double get _parkingFee => widget.lot.pricePerHour * _durationHours;
  double get _serviceFee => _parkingFee * 0.05;
  double get _tax => _parkingFee * 0.08;
  double get _total => _parkingFee + _serviceFee + _tax;

  void _handleBooking() {
    if (_plateController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vui lòng nhập biển số xe!')));
      return;
    }
    if (_selectedSlot == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vui lòng chọn vị trí đỗ xe mong muốn!')));
      return;
    }
    final start = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day, _selectedHour);
    if (start.isBefore(DateTime.now())) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Thời gian đặt xe không thể ở quá khứ hoặc trùng thời gian thực! Vui lòng chọn lại giờ bắt đầu.')));
      return;
    }
    final end = start.add(Duration(hours: _durationHours));
    final booking = BookingModel(
      userId: widget.userId,
      parkingLotId: widget.lot.id,
      vehiclePlate: _plateController.text.trim(),
      vehicleType: _vehicleType,
      startTime: start,
      endTime: end,
      slotNumber: _selectedSlot,
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PaymentView(
          lot: widget.lot,
          userId: widget.userId,
          token: widget.token,
          booking: booking,
          totalAmount: _total,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Cover ảnh + thông tin nhanh
          SliverAppBar(expandedHeight: 260, pinned: true, flexibleSpace: FlexibleSpaceBar(
            background: Container(
              decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
              child: SafeArea(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                const SizedBox(height: 40),
                const Icon(Icons.local_parking_rounded, size: 60, color: Colors.white),
                const SizedBox(height: 12),
                Text(widget.lot.name, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800), textAlign: TextAlign.center),
                const SizedBox(height: 6),
                Text(widget.lot.address, style: const TextStyle(color: Colors.white70, fontSize: 13), textAlign: TextAlign.center),
                const SizedBox(height: 16),
                // Thẻ thông tin nhanh
                Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
                  _infoChip(Icons.event_seat, '${widget.lot.availableSlots} chỗ'),
                  _infoChip(Icons.payments_rounded, '${widget.lot.pricePerHour.toVnd()}/h'),
                  _infoChip(Icons.star, '4.8'),
                  _infoChip(Icons.location_on, _getDistanceText()),
                ]),
              ])),
            ),
          )),
          // Nội dung booking
          SliverToBoxAdapter(child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              // Biểu đồ đánh giá
              _buildRatingChart(),
              const SizedBox(height: 24),
              // Chọn ngày & giờ
              const Text('Chọn thời gian', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: 12),
              _buildDateSelector(),
              const SizedBox(height: 12),
              _buildHourSelector(),
              const SizedBox(height: 12),
              _buildDurationSelector(),
              const SizedBox(height: 24),
              // Chọn phương tiện
              const Text('Phương tiện', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: 12),
              AppTextField(hint: 'Biển số xe (VD: 51A-123.45)', icon: Icons.confirmation_number_outlined, controller: _plateController),
              const SizedBox(height: 12),
              Row(children: [
                _vehicleChip('car', 'Ô tô', Icons.directions_car),
                const SizedBox(width: 12),
                _vehicleChip('motorbike', 'Xe máy', Icons.two_wheeler),
              ]),
              const SizedBox(height: 24),
              const Text('Vị trí đỗ xe', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: 12),
              _buildSelectedSlotSection(),
              const SizedBox(height: 24),
              // Tóm tắt chi phí
              _buildCostSummary(),
              const SizedBox(height: 100),
            ]),
          )),
        ],
      ),
      // Nút đặt chỗ bám đáy
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black.withAlpha(13), blurRadius: 10, offset: const Offset(0, -4))]),
        child: PrimaryButton(text: 'Tiếp tục thanh toán • ${_total.toVnd()}', onPressed: _handleBooking, isLoading: _isBooking, icon: Icons.payment_rounded),
      ),
    );
  }

  Widget _infoChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(color: Colors.white.withAlpha(51), borderRadius: BorderRadius.circular(12)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, color: Colors.white, size: 16),
        const SizedBox(width: 4),
        Text(text, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
      ]),
    );
  }

  Widget _buildRatingChart() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withAlpha(8), blurRadius: 8)]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Đánh giá', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),
        ...List.generate(5, (i) {
          final star = 5 - i;
          final pct = [0.6, 0.25, 0.1, 0.03, 0.02][i];
          return Padding(padding: const EdgeInsets.symmetric(vertical: 3), child: Row(children: [
            Text('$star', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            const Icon(Icons.star, size: 14, color: AppColors.warning),
            const SizedBox(width: 8),
            Expanded(child: ClipRRect(borderRadius: BorderRadius.circular(4), child: LinearProgressIndicator(value: pct, backgroundColor: AppColors.divider, valueColor: const AlwaysStoppedAnimation(AppColors.warning), minHeight: 8))),
            const SizedBox(width: 8),
            Text('${(pct * 100).toInt()}%', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          ]));
        }),
      ]),
    );
  }

  bool _isHourValid(int hour) {
    final now = DateTime.now();
    if (_selectedDate.year == now.year &&
        _selectedDate.month == now.month &&
        _selectedDate.day == now.day) {
      return hour > now.hour;
    }
    return true;
  }

  Widget _buildDateSelector() {
    return SizedBox(height: 70, child: ListView.builder(scrollDirection: Axis.horizontal, itemCount: 7, itemBuilder: (_, i) {
      final date = DateTime.now().add(Duration(days: i));
      final sel = _selectedDate.day == date.day;
      final days = ['CN', 'T2', 'T3', 'T4', 'T5', 'T6', 'T7'];
      return GestureDetector(
        onTap: () {
          setState(() {
            _selectedDate = date;
            // Nếu đổi về ngày hôm nay và giờ đang chọn không hợp lệ, reset về giờ tiếp theo
            if (_selectedDate.year == DateTime.now().year &&
                _selectedDate.month == DateTime.now().month &&
                _selectedDate.day == DateTime.now().day) {
              if (!_isHourValid(_selectedHour)) {
                _selectedHour = DateTime.now().hour + 1;
                if (_selectedHour > 23) {
                  _selectedDate = DateTime.now().add(const Duration(days: 1));
                  _selectedHour = 0;
                }
              }
            }
          });
        },
        child: Container(
          width: 56, margin: const EdgeInsets.only(right: 8),
          decoration: BoxDecoration(gradient: sel ? AppColors.primaryGradient : null, color: sel ? null : AppColors.background, borderRadius: BorderRadius.circular(14)),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Text(days[date.weekday % 7], style: TextStyle(color: sel ? Colors.white : AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text('${date.day}', style: TextStyle(color: sel ? Colors.white : AppColors.textPrimary, fontSize: 20, fontWeight: FontWeight.w800)),
          ]),
        ),
      );
    }));
  }

  Widget _buildHourSelector() {
    return SizedBox(height: 44, child: ListView.builder(scrollDirection: Axis.horizontal, itemCount: 24, itemBuilder: (_, i) {
      final isValid = _isHourValid(i);
      final sel = _selectedHour == i;
      return GestureDetector(
        onTap: isValid ? () => setState(() => _selectedHour = i) : null,
        child: Container(
          width: 64, margin: const EdgeInsets.only(right: 8), alignment: Alignment.center,
          decoration: BoxDecoration(
            gradient: sel && isValid ? AppColors.primaryGradient : null,
            color: sel && isValid 
                ? null 
                : (isValid ? AppColors.background : AppColors.background.withAlpha(100)),
            borderRadius: BorderRadius.circular(10),
            border: isValid ? null : Border.all(color: AppColors.divider.withAlpha(100)),
          ),
          child: Text(
            '${i.toString().padLeft(2, '0')}:00',
            style: TextStyle(
              color: sel && isValid
                  ? Colors.white
                  : (isValid ? AppColors.textSecondary : AppColors.textLight),
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ),
      );
    }));
  }

  Widget _buildDurationSelector() {
    return Row(children: [
      const Text('Thời lượng: ', style: TextStyle(fontWeight: FontWeight.w600)),
      IconButton(icon: const Icon(Icons.remove_circle_outline), onPressed: () { if (_durationHours > 1) setState(() => _durationHours--); }),
      Text('$_durationHours giờ', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.primaryBlue)),
      IconButton(icon: const Icon(Icons.add_circle_outline), onPressed: () => setState(() => _durationHours++)),
    ]);
  }

  Widget _vehicleChip(String value, String label, IconData icon) {
    final sel = _vehicleType == value;
    return Expanded(child: GestureDetector(
      onTap: () => setState(() => _vehicleType = value),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(color: sel ? AppColors.primaryBlue.withAlpha(25) : AppColors.background, borderRadius: BorderRadius.circular(12), border: Border.all(color: sel ? AppColors.primaryBlue : AppColors.divider, width: sel ? 2 : 1)),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, color: sel ? AppColors.primaryBlue : AppColors.textSecondary),
          const SizedBox(width: 8),
          Text(label, style: TextStyle(fontWeight: sel ? FontWeight.w700 : FontWeight.w500, color: sel ? AppColors.primaryBlue : AppColors.textSecondary)),
        ]),
      ),
    ));
  }

  Widget _buildCostSummary() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(16)),
      child: Column(children: [
        _costRow('Phí gửi xe', _parkingFee.toVnd()),
        _costRow('Phí dịch vụ (5%)', _serviceFee.toVnd()),
        _costRow('Thuế (8%)', _tax.toVnd()),
        const Divider(),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          const Text('Tổng cộng', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
          Text(_total.toVnd(), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.primaryBlue)),
        ]),
      ]),
    );
  }

  Widget _costRow(String label, String value) {
    return Padding(padding: const EdgeInsets.symmetric(vertical: 4), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label, style: const TextStyle(color: AppColors.textSecondary)),
      Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
    ]));
  }

  String _getDistanceText() {
    final userPos = widget.userLocation ?? const LatLng(10.779785, 106.699019);
    final lotPos = LatLng(widget.lot.latitude, widget.lot.longitude);
    final distanceInMeters = LocationService.distanceBetween(userPos, lotPos);
    final distanceInKm = distanceInMeters / 1000;
    if (distanceInKm < 0.1) {
      return '${distanceInMeters.toInt()} m';
    }
    return '${distanceInKm.toStringAsFixed(1)} km';
  }

  // Helper UI cho Slot Picker
  Widget _buildSelectedSlotSection() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider),
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(5), blurRadius: 8)],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primaryBlue.withAlpha(20),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.grid_view_rounded, color: AppColors.primaryBlue, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Vị trí đỗ mong muốn',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 2),
                Text(
                  _selectedSlot != null 
                      ? 'Vị trí đã chọn: $_selectedSlot'
                      : 'Chưa chọn vị trí cụ thể',
                  style: TextStyle(
                    fontSize: 12,
                    color: _selectedSlot != null ? AppColors.primaryBlue : AppColors.textSecondary,
                    fontWeight: _selectedSlot != null ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
          if (_isLoadingSlots)
            const SizedBox(
              width: 20, height: 20,
              child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(AppColors.primaryBlue)),
            )
          else
            TextButton(
              onPressed: _showSlotPickerSheet,
              child: Text(
                _selectedSlot != null ? 'Thay đổi' : 'Chọn ngay',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.primaryBlue),
              ),
            ),
        ],
      ),
    );
  }

  void _showSlotPickerSheet() async {
    setState(() => _isLoadingSlots = true);
    try {
      final activeSlots = await BookingService(token: widget.token)
          .fetchActiveSlots(widget.lot.id);
      if (mounted) {
        setState(() {
          _occupiedSlots = activeSlots;
          _isLoadingSlots = false;
        });
        _openBottomSheet();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingSlots = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi tải sơ đồ vị trí: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  void _openBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Drag handle
                  Center(
                    child: Container(
                      width: 40, height: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Sơ đồ vị trí đỗ xe',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
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
                  // Chú thích màu sắc
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _legendItem('Còn trống', Colors.grey.shade100, Colors.grey.shade400, false),
                      _legendItem('Đang bận', Colors.red.shade50, Colors.red, true),
                      _legendItem('Đang chọn', AppColors.primaryBlue.withAlpha(25), AppColors.primaryBlue, false),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Grid 2D Slots
                  const Text('Dãy A (Khuyên dùng cho Ô tô)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textSecondary)),
                  const SizedBox(height: 8),
                  _buildSlotGrid(
                    prefix: 'A',
                    count: 10,
                    setModalState: setModalState,
                  ),
                  const SizedBox(height: 16),
                  const Text('Dãy B (Khuyên dùng cho Xe máy)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textSecondary)),
                  const SizedBox(height: 8),
                  _buildSlotGrid(
                    prefix: 'B',
                    count: 10,
                    setModalState: setModalState,
                  ),
                  const SizedBox(height: 24),
                  // Nút xác nhận
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        setState(() {}); // Cập nhật màn hình chính
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryBlue,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text('Xác nhận vị trí', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSlotGrid({
    required String prefix,
    required int count,
    required void Function(void Function()) setModalState,
  }) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 5,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 1.2,
      ),
      itemCount: count,
      itemBuilder: (context, index) {
        final slotName = '$prefix${index + 1}';
        final isOccupied = _occupiedSlots.contains(slotName);
        final isSelected = _selectedSlot == slotName;

        Color bgColor = Colors.grey.shade100;
        Color borderColor = Colors.grey.shade300;
        Color textColor = AppColors.textPrimary;
        IconData? icon;

        if (isOccupied) {
          bgColor = Colors.red.shade50;
          borderColor = Colors.red.shade200;
          textColor = Colors.red.shade900;
          icon = prefix == 'A' ? Icons.directions_car_rounded : Icons.two_wheeler_rounded;
        } else if (isSelected) {
          bgColor = AppColors.primaryBlue.withAlpha(25);
          borderColor = AppColors.primaryBlue;
          textColor = AppColors.primaryBlue;
          icon = Icons.check_circle_rounded;
        }

        return GestureDetector(
          onTap: isOccupied
              ? null
              : () {
                  setModalState(() {
                    _selectedSlot = isSelected ? null : slotName;
                  });
                },
          child: Container(
            decoration: BoxDecoration(
              color: bgColor,
              border: Border.all(color: borderColor, width: isSelected ? 2 : 1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (icon != null) ...[
                  Icon(icon, color: isOccupied ? Colors.red.shade400 : AppColors.primaryBlue, size: 14),
                  const SizedBox(height: 2),
                ],
                Text(
                  slotName,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: isOccupied ? Colors.red.shade900 : textColor,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _legendItem(String text, Color bgColor, Color borderColor, bool isOccupied) {
    return Row(
      children: [
        Container(
          width: 16, height: 16,
          decoration: BoxDecoration(
            color: bgColor,
            border: Border.all(color: borderColor),
            borderRadius: BorderRadius.circular(4),
          ),
          child: isOccupied 
              ? const Icon(Icons.close, size: 10, color: Colors.red)
              : null,
        ),
        const SizedBox(width: 6),
        Text(text, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
      ],
    );
  }
}
