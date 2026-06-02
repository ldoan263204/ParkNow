import 'package:flutter/material.dart';
import '../../../core/utils/vnd_formatter.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/services/notification_service.dart';
import '../../../shared_widgets/app_widgets.dart';
import '../models/parking_lot_model.dart';
import '../models/booking_model.dart';
import '../services/booking_service.dart';

class PaymentView extends StatefulWidget {
  final ParkingLot lot;
  final int userId;
  final String? token;
  final BookingModel booking;
  final double totalAmount;

  const PaymentView({
    super.key,
    required this.lot,
    required this.userId,
    this.token,
    required this.booking,
    required this.totalAmount,
  });

  @override
  State<PaymentView> createState() => _PaymentViewState();
}

class _PaymentViewState extends State<PaymentView> {
  String _selectedMethod = 'momo'; // momo, card, cash
  bool _isProcessing = false;

  void _processPayment() async {
    setState(() => _isProcessing = true);

    // Giả lập kết nối cổng thanh toán trong 1.8 giây
    await Future.delayed(const Duration(milliseconds: 1800));

    try {
      final bookingWithPayment = BookingModel(
        userId: widget.booking.userId,
        parkingLotId: widget.booking.parkingLotId,
        vehiclePlate: widget.booking.vehiclePlate,
        vehicleType: widget.booking.vehicleType,
        startTime: widget.booking.startTime,
        endTime: widget.booking.endTime,
        slotNumber: widget.booking.slotNumber,
        paymentMethod: _selectedMethod, // momo / card / cash
      );

      final created = await BookingService(token: widget.token).createBooking(bookingWithPayment);

      if (mounted) {
        // Kích hoạt thông báo in-app
        NotificationService.instance.simulateIncomingNotification(
          context,
          'ParkNow - Thanh toán thành công! 💳',
          'Bạn đã đặt chỗ tại ${widget.lot.name}. Vui lòng xuất trình mã QR Vé đỗ xe khi tới bãi.',
        );

        // Hiển thị màn hình thành công
        _showSuccessDialog(created);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi thanh toán: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  void _showSuccessDialog(BookingModel createdBooking) {
    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierLabel: 'Success',
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, anim1, anim2) {
        return Scaffold(
          backgroundColor: Colors.white,
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Spacer(),
                  // Icon thành công động
                  Container(
                    width: 90, height: 90,
                    decoration: BoxDecoration(
                      color: AppColors.success.withAlpha(25),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 54),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Thanh toán hoàn tất!',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Đặt chỗ của bạn đã được hệ thống ghi nhận thành công.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: AppColors.textSecondary, height: 1.4),
                  ),
                  const SizedBox(height: 32),
                  // Thông tin vé
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.divider),
                    ),
                    child: Column(
                      children: [
                        _infoRow('Bãi đỗ xe', widget.lot.name),
                        _infoRow('Biển số xe', widget.booking.vehiclePlate),
                        _infoRow('Loại xe', widget.booking.vehicleType == 'car' ? 'Ô tô' : 'Xe máy'),
                        _infoRow('Tổng tiền', widget.totalAmount.toVnd()),
                        _infoRow('Trạng thái', 'ĐÃ THANH TOÁN', color: AppColors.success),
                      ],
                    ),
                  ),
                  const Spacer(),
                  PrimaryButton(
                    text: 'Trở lại bản đồ',
                    onPressed: () {
                      // Pop dialog và pop LotDetailView
                      Navigator.pop(context); // Đóng Dialog
                      Navigator.pop(context); // Đóng PaymentView
                      Navigator.pop(context); // Đóng LotDetailView
                    },
                    icon: Icons.map_rounded,
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _infoRow(String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 13,
              color: color ?? AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Thanh toán', style: TextStyle(fontWeight: FontWeight.w700)),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: _isProcessing
          ? _buildProcessingState()
          : Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Tóm tắt đơn hàng
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            gradient: AppColors.primaryGradient,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primaryBlue.withAlpha(50),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('TỔNG THANH TOÁN', style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w600)),
                              const SizedBox(height: 4),
                              Text(
                                widget.totalAmount.toVnd(),
                                style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900),
                              ),
                              const Divider(color: Colors.white24, height: 24),
                              Row(
                                children: [
                                  const Icon(Icons.local_parking_rounded, color: Colors.white, size: 18),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      widget.lot.name,
                                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 32),
                        const Text('Chọn phương thức thanh toán', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                        const SizedBox(height: 16),
                        _buildMethodTile('momo', 'Ví điện tử MoMo', 'assets/images/momo_icon.png', Icons.wallet_rounded, const Color(0xFFA50064)),
                        const SizedBox(height: 12),
                        _buildMethodTile('card', 'Thẻ ATM / Visa / Mastercard', '', Icons.credit_card_rounded, AppColors.primaryBlue),
                        const SizedBox(height: 12),
                        _buildMethodTile('cash', 'Thanh toán tiền mặt tại quầy', '', Icons.payments_rounded, AppColors.success),
                      ],
                    ),
                  ),
                ),
                // Nút thanh toán ở dưới cùng
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(10),
                        blurRadius: 10,
                        offset: const Offset(0, -4),
                      ),
                    ],
                  ),
                  child: PrimaryButton(
                    text: 'Xác nhận thanh toán',
                    onPressed: _processPayment,
                    icon: Icons.security_rounded,
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildProcessingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryBlue),
          ),
          const SizedBox(height: 24),
          const Text('Đang kết nối cổng thanh toán...', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
          const SizedBox(height: 8),
          Text('Vui lòng không tắt ứng dụng hoặc chuyển màn hình.', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        ],
      ),
    );
  }

  Widget _buildMethodTile(String method, String title, String assetPath, IconData defaultIcon, Color iconColor) {
    final isSelected = _selectedMethod == method;
    return GestureDetector(
      onTap: () => setState(() => _selectedMethod = method),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? iconColor.withAlpha(15) : AppColors.background,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? iconColor : AppColors.divider,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(10),
                    blurRadius: 4,
                  ),
                ],
              ),
              child: Icon(defaultIcon, color: iconColor, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                  color: isSelected ? iconColor : AppColors.textPrimary,
                  fontSize: 14,
                ),
              ),
            ),
            Radio<String>(
              value: method,
              groupValue: _selectedMethod,
              activeColor: iconColor,
              onChanged: (value) {
                if (value != null) {
                  setState(() => _selectedMethod = value);
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
