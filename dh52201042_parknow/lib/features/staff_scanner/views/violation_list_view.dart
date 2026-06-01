import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import '../../../core/utils/vnd_formatter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import '../../../core/theme/app_colors.dart';
import '../../../core/constants/api_config.dart';
import '../../../features/authentication/models/user_model.dart';
import '../viewmodels/staff_viewmodel.dart';
import '../models/violation_model.dart';

class ViolationListView extends StatefulWidget {
  final UserModel user;
  final StaffViewModel vm;
  const ViolationListView({super.key, required this.user, required this.vm});
  @override
  State<ViolationListView> createState() => _ViolationListViewState();
}
class _ViolationListViewState extends State<ViolationListView> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    widget.vm.loadViolations();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<ViolationModel> _filter(int tab) {
    final all = widget.vm.violations;
    if (tab == 1) return all.where((v) => v.status == 'pending').toList();
    if (tab == 2) return all.where((v) => v.status == 'resolved').toList();
    return all;
  }



  void _showCreateSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => CreateViolationSheet(user: widget.user, vm: widget.vm),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Báo cáo vi phạm', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w800)),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppColors.textSecondary),
            tooltip: 'Tải lại',
            onPressed: () => widget.vm.loadViolations(),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primaryPurple,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primaryPurple,
          tabs: const [Tab(text: 'Tất cả'), Tab(text: 'Chưa xử lý'), Tab(text: 'Đã xử lý')],
          onTap: (_) => setState(() {}),
        ),
      ),
      body: ListenableBuilder(
        listenable: widget.vm,
        builder: (ctx, _) {
          if (widget.vm.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (widget.vm.error.isNotEmpty) {
            return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.wifi_off_rounded, size: 48, color: AppColors.textLight),
              const SizedBox(height: 8),
              Text(widget.vm.error, style: const TextStyle(color: AppColors.error), textAlign: TextAlign.center),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: () => widget.vm.loadViolations(),
                icon: const Icon(Icons.refresh),
                label: const Text('Thử lại'),
              ),
            ]));
          }
          final list = _filter(_tabController.index);
          if (list.isEmpty) return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.report_off_rounded, size: 48, color: AppColors.textLight),
            const SizedBox(height: 8),
            const Text('Chưa có vi phạm nào', style: TextStyle(color: AppColors.textSecondary)),
          ]));
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: list.length,
            itemBuilder: (_, i) {
              final v = list[i];
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: Colors.black.withAlpha(8), blurRadius: 8)],
                ),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Container(
                      width: 44, height: 44,
                      decoration: BoxDecoration(
                        color: v.status == 'pending' ? AppColors.error.withAlpha(25) : AppColors.success.withAlpha(25),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.warning_rounded, color: v.status == 'pending' ? AppColors.error : AppColors.success),
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(v.vehiclePlate, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                      Text(v.reasonText, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                      if (v.createdAt != null)
                        Text('${v.createdAt!.day}/${v.createdAt!.month}/${v.createdAt!.year} • ${v.createdAt!.hour.toString().padLeft(2,'0')}:${v.createdAt!.minute.toString().padLeft(2,'0')}',
                          style: const TextStyle(fontSize: 11, color: AppColors.textLight)),
                    ])),
                    Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: v.status == 'pending' ? AppColors.tagRejected : AppColors.tagApproved,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          v.status == 'pending' ? 'Chờ xử lý' : 'Đã xử lý',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
                            color: v.status == 'pending' ? AppColors.tagRejectedText : AppColors.tagApprovedText),
                        ),
                      ),
                      if (v.status == 'pending') ...[
                        const SizedBox(height: 6),
                        GestureDetector(
                          onTap: () => widget.vm.resolveViolation(v.id!),
                          child: const Text('Đánh dấu đã xử lý', style: TextStyle(fontSize: 11, color: AppColors.primaryBlue, decoration: TextDecoration.underline, decorationColor: AppColors.primaryBlue)),
                        ),
                      ],
                    ]),
                  ]),
                  // Hiển thị tiền phạt và hạn thanh toán
                  if (v.penaltyAmount != null || v.paymentDeadline != null) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: v.isWithinDeadline ? AppColors.tagPending : AppColors.tagRejected,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(children: [
                        Icon(
                          v.isWithinDeadline ? Icons.timer_rounded : Icons.timer_off_rounded,
                          size: 16,
                          color: v.isWithinDeadline ? AppColors.tagPendingText : AppColors.tagRejectedText,
                        ),
                        const SizedBox(width: 6),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          if (v.penaltyAmount != null)
                            Text('Tiền phạt: ${v.penaltyAmount!.toVnd()}',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700,
                                color: v.isWithinDeadline ? AppColors.tagPendingText : AppColors.tagRejectedText)),
                          if (v.paymentDeadline != null)
                            Text(
                              v.isWithinDeadline
                                ? 'Hạn thanh toán: ${v.paymentDeadline!.hour.toString().padLeft(2,'0')}:${v.paymentDeadline!.minute.toString().padLeft(2,'0')} - ${v.secondsRemaining ~/ 60} phút nữa'
                                : 'QUÁ HẠN THANH TOÁN',
                              style: TextStyle(fontSize: 11,
                                color: v.isWithinDeadline ? AppColors.tagPendingText : AppColors.tagRejectedText),
                            ),
                        ])),
                      ]),
                    ),
                  ],
                  // Hiển thị ảnh nếu có
                  if (v.imageUrl != null && v.imageUrl!.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.network(v.imageUrl!, height: 140, width: double.infinity, fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(height: 60, color: AppColors.background,
                          child: const Center(child: Icon(Icons.broken_image_outlined, color: AppColors.textLight)))),
                    ),
                  ],
                ]),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateSheet,
        backgroundColor: AppColors.primaryPurple,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

class CreateViolationSheet extends StatefulWidget {
  final UserModel user;
  final StaffViewModel vm;
  const CreateViolationSheet({super.key, required this.user, required this.vm});

  @override
  State<CreateViolationSheet> createState() => _CreateViolationSheetState();
}

class _CreateViolationSheetState extends State<CreateViolationSheet> {
  final _plateCtrl = TextEditingController();
  String _selectedReason = 'wrong_spot';
  File? _pickedImage;
  bool _isUploading = false;

  @override
  void dispose() {
    _plateCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: source, imageQuality: 75, maxWidth: 1280);
    if (picked != null) {
      setState(() => _pickedImage = File(picked.path));
    }
  }

  void _showImagePickerSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          ListTile(
            leading: const Icon(Icons.camera_alt_rounded, color: AppColors.primaryBlue),
            title: const Text('Chụp ảnh'),
            onTap: () { Navigator.pop(context); _pickImage(ImageSource.camera); },
          ),
          ListTile(
            leading: const Icon(Icons.photo_library_rounded, color: AppColors.staffTeal),
            title: const Text('Chọn từ thư viện'),
            onTap: () { Navigator.pop(context); _pickImage(ImageSource.gallery); },
          ),
          if (_pickedImage != null)
            ListTile(
              leading: const Icon(Icons.delete_outline, color: AppColors.error),
              title: const Text('Xóa ảnh', style: TextStyle(color: AppColors.error)),
              onTap: () { Navigator.pop(context); setState(() => _pickedImage = null); },
            ),
        ]),
      ),
    );
  }

  Future<String?> _uploadImage(File image) async {
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('${ApiConfig.baseUrl}/violations/upload'),
      );
      if (widget.user.token != null && widget.user.token!.isNotEmpty) {
        request.headers['Authorization'] = 'Bearer ${widget.user.token}';
      }
      request.files.add(await http.MultipartFile.fromPath('file', image.path));
      final response = await request.send();
      final body = await response.stream.bytesToString();
      if (response.statusCode == 200) {
        final data = jsonDecode(body);
        return data['url'] as String?;
      }
    } catch (_) {}
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 24, right: 24, top: 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 16),
            const Text('Báo cáo vi phạm mới', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
            const SizedBox(height: 16),
            TextField(
              controller: _plateCtrl,
              textCapitalization: TextCapitalization.characters,
              decoration: InputDecoration(
                hintText: 'Biển số xe (VD: 51A-123.45)',
                prefixIcon: const Icon(Icons.confirmation_number_outlined),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _selectedReason,
              decoration: InputDecoration(border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
              items: const [
                DropdownMenuItem(value: 'wrong_spot', child: Text('Đỗ sai vạch')),
                DropdownMenuItem(value: 'expired', child: Text('Hết hạn gửi')),
                DropdownMenuItem(value: 'no_ticket', child: Text('Không có vé')),
                DropdownMenuItem(value: 'other', child: Text('Khác')),
              ],
              onChanged: (v) { setState(() => _selectedReason = v ?? 'wrong_spot'); },
            ),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: _showImagePickerSheet,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: double.infinity,
                height: _pickedImage != null ? 160 : 80,
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.divider, style: BorderStyle.solid),
                ),
                child: _pickedImage != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Stack(fit: StackFit.expand, children: [
                          Image.file(_pickedImage!, fit: BoxFit.cover),
                          Positioned(top: 8, right: 8, child: GestureDetector(
                            onTap: () { setState(() => _pickedImage = null); },
                            child: Container(
                              width: 28, height: 28,
                              decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                              child: const Icon(Icons.close, color: Colors.white, size: 16),
                            ),
                          )),
                        ]),
                      )
                    : const Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Icon(Icons.camera_alt_outlined, color: AppColors.textSecondary, size: 28),
                        SizedBox(height: 6),
                        Text('Chụp ảnh bằng chứng (tuỳ chọn)', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                      ]),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _isUploading
                    ? null
                    : () async {
                        if (_plateCtrl.text.trim().isEmpty) return;
                        setState(() => _isUploading = true);
                        String? imageUrl;
                        if (_pickedImage != null) {
                          imageUrl = await _uploadImage(_pickedImage!);
                        }
                        await widget.vm.createViolation(ViolationModel(
                          parkingLotId: widget.vm.activeShift?.parkingLotId ?? 1,
                          reportedBy: widget.user.id,
                          vehiclePlate: _plateCtrl.text.trim(),
                          reason: _selectedReason,
                          imageUrl: imageUrl,
                        ));
                        if (mounted) {
                          Navigator.pop(context);
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryPurple,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isUploading
                    ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                    : const Text('Gửi báo cáo', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
