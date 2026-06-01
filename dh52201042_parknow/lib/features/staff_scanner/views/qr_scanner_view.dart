import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/utils/vnd_formatter.dart';
import '../../../features/authentication/models/user_model.dart';
import '../viewmodels/staff_viewmodel.dart';

/// Màn hình quét mã QR cho nhân viên để xử lý xe vào/ra.
/// QR code chứa: "PARKNOW:ENTRY:<bookingId>" hoặc "PARKNOW:EXIT:<bookingId>"
class QrScannerView extends StatefulWidget {
  final UserModel user;
  final StaffViewModel vm;
  final String? allowedAction; // ENTRY hoặc EXIT hoặc null
  const QrScannerView({super.key, required this.user, required this.vm, this.allowedAction});

  @override
  State<QrScannerView> createState() => _QrScannerViewState();
}

class _QrScannerViewState extends State<QrScannerView> {
  final MobileScannerController _cameraController = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    returnImage: false,
  );

  bool _isProcessing = false;
  String? _lastResult;
  String _statusMessage = 'Hướng camera vào mã QR của vé đỗ xe';
  bool _isSuccess = false;
  bool _isFlashOn = false;

  @override
  void dispose() {
    _cameraController.dispose();
    super.dispose();
  }

  // Phân tích QR và xử lý xe vào/ra
  Future<void> _handleQrDetect(BarcodeCapture capture) async {
    if (_isProcessing) return;
    final barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    final raw = barcodes.first.rawValue ?? '';
    if (raw == _lastResult) return;  // tránh xử lý trùng lặp

    _cameraController.stop();
    await _processBookingWithRawData(raw);
  }

  // Tách logic xử lý vé đỗ xe để dùng chung cho quét QR và nhập thủ công
  Future<void> _processBookingWithRawData(String raw) async {
    setState(() {
      _isProcessing = true;
      _lastResult = raw;
    });

    // Phân tích cú pháp: "PARKNOW:ENTRY:<bookingId>" hoặc "PARKNOW:EXIT:<bookingId>"
    final parts = raw.split(':');
    if (parts.length != 3 || parts[0] != 'PARKNOW') {
      _showResult(false, 'Mã QR không hợp lệ!\n"$raw"');
      return;
    }

    final action = parts[1].toUpperCase(); // ENTRY hoặc EXIT
    final bookingId = int.tryParse(parts[2]);

    if (bookingId == null) {
      _showResult(false, 'ID đặt chỗ không hợp lệ!');
      return;
    }

    // Kiểm tra tính hợp lệ của action so với allowedAction
    if (widget.allowedAction != null && widget.allowedAction != action) {
      final expectedText = widget.allowedAction == 'ENTRY' ? 'xe VÀO' : 'xe RA';
      final scanResultText = action == 'ENTRY' ? 'VÀO bãi' : 'RA bãi';
      _showResult(
        false, 
        'Quét sai mã!\nBạn chọn quét $expectedText, nhưng khách đưa mã QR $scanResultText.'
      );
      return;
    }

    // Kiểm tra ca đang hoạt động
    final shift = widget.vm.activeShift;
    if (shift == null) {
      _showResult(false, 'Không có ca trực đang hoạt động!\nVui lòng bắt đầu ca trước.');
      return;
    }

    try {
      if (action == 'ENTRY') {
        // Lấy thông tin booking trước
        final booking = await widget.vm.service.getBooking(bookingId);
        // Tiến hành check-in
        await widget.vm.service.checkInBooking(bookingId);
        // Ghi nhận vào ca trực
        final double fee = (booking['totalCost'] as num?)?.toDouble() ?? 0.0;
        await widget.vm.service.recordEntry(shift.id!, fee, 'online');
        // Refresh active shift state
        await widget.vm.loadActiveShift(widget.user.id);
        
        if (mounted) {
          NotificationService.instance.simulateIncomingNotification(
            context,
            'ParkNow - Xe vào bến 📥',
            'Booking #$bookingId check-in thành công. Đã cộng phí: ${fee.toVnd()}.',
          );
        }
        _showResult(true, '✅ Xe vào thành công!\nBooking #$bookingId\nPhí: ${fee.toVnd()}');
      } else if (action == 'EXIT') {
        // Tiến hành hoàn thành booking
        await widget.vm.service.completeBooking(bookingId);
        // Ghi nhận xe ra trong ca
        await widget.vm.service.recordExit(shift.id!);
        // Refresh active shift state
        await widget.vm.loadActiveShift(widget.user.id);
        
        if (mounted) {
          NotificationService.instance.simulateIncomingNotification(
            context,
            'ParkNow - Xe xuất bến 📤',
            'Booking #$bookingId check-out thành công.',
          );
        }
        _showResult(true, '✅ Xe ra thành công!\nBooking #$bookingId');
      } else {
        _showResult(false, 'Hành động không hợp lệ: $action');
      }
    } catch (e) {
      _showResult(false, 'Lỗi: ${e.toString().replaceFirst("Exception: ", "")}');
    }
  }

  void _showResult(bool success, String message) {
    setState(() {
      _isSuccess = success;
      _statusMessage = message;
      _isProcessing = false;
    });

    // Tự động quét lại sau 2.5 giây
    Future.delayed(const Duration(milliseconds: 2500), () {
      if (mounted) {
        setState(() {
          _statusMessage = 'Hướng camera vào mã QR của vé đỗ xe';
          _lastResult = null;
        });
        _cameraController.start();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('Quét mã QR', style: TextStyle(fontWeight: FontWeight.w700)),
        actions: [
          // Flash toggle
          IconButton(
            icon: Icon(_isFlashOn ? Icons.flash_on : Icons.flash_off, color: _isFlashOn ? Colors.yellow : Colors.white),
            onPressed: () {
              setState(() => _isFlashOn = !_isFlashOn);
              _cameraController.toggleTorch();
            },
          ),
          // Flip camera
          IconButton(
            icon: const Icon(Icons.flip_camera_android, color: Colors.white),
            onPressed: () => _cameraController.switchCamera(),
          ),
        ],
      ),
      body: Stack(
        children: [
          // ── Camera View ──────────────────────────────────────────
          MobileScanner(
            controller: _cameraController,
            onDetect: _handleQrDetect,
          ),

          // ── Overlay với khung quét ───────────────────────────────
          _buildScanOverlay(),

          // ── Status Panel ─────────────────────────────────────────
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _buildStatusPanel(),
          ),
        ],
      ),
    );
  }

  Widget _buildScanOverlay() {
    return LayoutBuilder(builder: (context, constraints) {
      final size = constraints.biggest;
      final scanSize = size.width * 0.68;
      final left = (size.width - scanSize) / 2;
      final top = (size.height - scanSize) / 2 - 40;

      return Stack(children: [
        // Dark overlay tứ phía
        Positioned.fill(
          child: CustomPaint(
            painter: _OverlayPainter(
              scanRect: Rect.fromLTWH(left, top, scanSize, scanSize),
              borderColor: _isProcessing
                  ? AppColors.warning
                  : _isSuccess
                      ? AppColors.success
                      : AppColors.primaryBlue,
            ),
          ),
        ),

        // Góc khung quét (decorative)
        ...[ [left, top], [left + scanSize - 28, top], [left, top + scanSize - 28], [left + scanSize - 28, top + scanSize - 28] ]
          .asMap()
          .entries
          .map((e) => Positioned(
            left: e.value[0],
            top:  e.value[1],
            child: _CornerBracket(index: e.key),
          )),

        // Nhãn hướng dẫn trên khung
        Positioned(
          left: 0, right: 0,
          top: top - 40,
          child: Text(
            'Đặt mã QR vào trong khung',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white.withAlpha(200), fontSize: 14),
          ),
        ),

        // Đường quét animate
        if (!_isProcessing)
          _ScanLine(top: top, scanSize: scanSize),
      ]);
    });
  }

  Widget _buildStatusPanel() {
    final color = _isProcessing
        ? AppColors.warning
        : _isSuccess
            ? AppColors.success
            : AppColors.error;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Color(0xDD000000),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 16),
          // Icon trạng thái
          if (_isProcessing)
            const SizedBox(width: 32, height: 32, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
          else
            Icon(
              _lastResult == null ? Icons.qr_code_scanner : (_isSuccess ? Icons.check_circle_rounded : Icons.error_rounded),
              color: _lastResult == null ? Colors.white60 : color,
              size: 36,
            ),
          const SizedBox(height: 12),
          Text(
            _statusMessage,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600, height: 1.5),
          ),
          const SizedBox(height: 16),
          // Hàng nút: quét lại & nhập thủ công
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              TextButton(
                onPressed: () {
                  setState(() { _lastResult = null; _statusMessage = 'Hướng camera vào mã QR của vé đỗ xe'; });
                  _cameraController.start();
                },
                child: const Text('Quét lại', style: TextStyle(color: Colors.white70, decoration: TextDecoration.underline, decorationColor: Colors.white70)),
              ),
              ElevatedButton.icon(
                onPressed: _showManualInputBookingDialog,
                icon: const Icon(Icons.edit_note_rounded, size: 18),
                label: const Text('Nhập mã vé'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryBlue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  void _showManualInputBookingDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          widget.allowedAction == 'ENTRY' ? 'Nhập mã vé VÀO' : 'Nhập mã vé RA',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Nhập mã vé đặt chỗ của khách hàng (VD: 1, 2, 3...) để xác thực.',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                hintText: 'Mã đặt chỗ (ID)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              final idText = controller.text.trim();
              Navigator.pop(ctx);
              if (idText.isNotEmpty) {
                final id = int.tryParse(idText);
                if (id != null) {
                  final mockRaw = 'PARKNOW:${widget.allowedAction ?? "ENTRY"}:$id';
                  _cameraController.stop();
                  _processBookingWithRawData(mockRaw);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Mã vé phải là số nguyên!')),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryBlue,
              foregroundColor: Colors.white,
            ),
            child: const Text('Xác nhận'),
          ),
        ],
      ),
    );
  }
}

// ── Custom Painter: vùng tối xung quanh khung quét ──────────────
class _OverlayPainter extends CustomPainter {
  final Rect scanRect;
  final Color borderColor;
  _OverlayPainter({required this.scanRect, required this.borderColor});

  @override
  void paint(Canvas canvas, Size size) {
    final dark = Paint()..color = Colors.black54;
    // Vùng trên
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, scanRect.top), dark);
    // Vùng dưới
    canvas.drawRect(Rect.fromLTWH(0, scanRect.bottom, size.width, size.height - scanRect.bottom), dark);
    // Vùng trái
    canvas.drawRect(Rect.fromLTWH(0, scanRect.top, scanRect.left, scanRect.height), dark);
    // Vùng phải
    canvas.drawRect(Rect.fromLTWH(scanRect.right, scanRect.top, size.width - scanRect.right, scanRect.height), dark);
    // Viền khung
    final border = Paint()..color = borderColor..strokeWidth = 2.5..style = PaintingStyle.stroke;
    canvas.drawRRect(RRect.fromRectAndRadius(scanRect, const Radius.circular(12)), border);
  }

  @override
  bool shouldRepaint(covariant _OverlayPainter old) => old.borderColor != borderColor;
}

// ── 4 góc trang trí ─────────────────────────────────────────────
class _CornerBracket extends StatelessWidget {
  final int index;
  const _CornerBracket({required this.index});

  @override
  Widget build(BuildContext context) {
    final isLeft  = index == 0 || index == 2;
    final isTop   = index == 0 || index == 1;
    return SizedBox(
      width: 28, height: 28,
      child: CustomPaint(painter: _BracketPainter(isLeft: isLeft, isTop: isTop)),
    );
  }
}

class _BracketPainter extends CustomPainter {
  final bool isLeft, isTop;
  _BracketPainter({required this.isLeft, required this.isTop});

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..color = AppColors.primaryBlue..strokeWidth = 4..style = PaintingStyle.stroke..strokeCap = StrokeCap.round;
    final x = isLeft ? 0.0 : size.width;
    final y = isTop  ? 0.0 : size.height;
    final dx = isLeft ? size.width : -size.width;
    final dy = isTop  ? size.height : -size.height;
    canvas.drawLine(Offset(x, y), Offset(x + dx, y), p);
    canvas.drawLine(Offset(x, y), Offset(x, y + dy), p);
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

// ── Đường quét ngang động ────────────────────────────────────────
class _ScanLine extends StatefulWidget {
  final double top, scanSize;
  const _ScanLine({required this.top, required this.scanSize});
  @override
  State<_ScanLine> createState() => _ScanLineState();
}

class _ScanLineState extends State<_ScanLine> with SingleTickerProviderStateMixin {
  late AnimationController _anim;
  late Animation<double> _pos;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);
    _pos  = Tween(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _anim, curve: Curves.easeInOut));
  }

  @override
  void dispose() { _anim.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pos,
      builder: (_, __) {
        final y = widget.top + _pos.value * widget.scanSize;
        return Positioned(
          top: y, left: 0, right: 0,
          child: Container(
            height: 2,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [Colors.transparent, AppColors.primaryBlue, Colors.transparent]),
            ),
          ),
        );
      },
    );
  }
}
