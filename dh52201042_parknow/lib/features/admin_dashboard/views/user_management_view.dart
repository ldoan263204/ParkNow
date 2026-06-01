import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../features/authentication/models/user_model.dart';
import '../services/user_admin_service.dart';

/// Màn hình quản lý người dùng cho Admin.
/// Hỗ trợ: Xem danh sách, Thêm, Sửa, Xóa tài khoản.
class UserManagementView extends StatefulWidget {
  final UserModel adminUser;
  const UserManagementView({super.key, required this.adminUser});

  @override
  State<UserManagementView> createState() => _UserManagementViewState();
}

class _UserManagementViewState extends State<UserManagementView> {
  late final UserAdminService _service;
  List<UserModel> _users = [];
  List<UserModel> _filtered = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _roleFilter = 'ALL';

  @override
  void initState() {
    super.initState();
    _service = UserAdminService(token: widget.adminUser.token);
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() => _isLoading = true);
    try {
      _users = await _service.fetchAllUsers();
      _applyFilter();
    } catch (_) {}
    setState(() => _isLoading = false);
  }

  void _applyFilter() {
    var list = List<UserModel>.from(_users);
    if (_roleFilter != 'ALL') list = list.where((u) => u.role == _roleFilter).toList();
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      list = list.where((u) =>
        u.fullName.toLowerCase().contains(q) ||
        u.email.toLowerCase().contains(q)
      ).toList();
    }
    _filtered = list;
  }

  // ── Màu & Icon theo Role ──────────────────────────────────────
  Color _roleColor(String role) {
    switch (role) {
      case 'ADMIN':    return const Color(0xFF6C3EB8);
      case 'STAFF':    return AppColors.staffTeal;
      default:         return AppColors.primaryBlue;
    }
  }

  IconData _roleIcon(String role) {
    switch (role) {
      case 'ADMIN':    return Icons.shield_rounded;
      case 'STAFF':    return Icons.badge_rounded;
      default:         return Icons.person_rounded;
    }
  }

  String _roleLabel(String role) {
    switch (role) {
      case 'ADMIN':    return 'Quản trị';
      case 'STAFF':    return 'Nhân viên';
      default:         return 'Khách hàng';
    }
  }

  // ── Dialog Thêm / Sửa user ───────────────────────────────────
  void _showUserDialog({UserModel? user}) {
    final isEdit = user != null;
    final nameCtrl  = TextEditingController(text: user?.fullName ?? '');
    final emailCtrl = TextEditingController(text: user?.email ?? '');
    final phoneCtrl = TextEditingController(text: user?.phone ?? '');
    final passCtrl  = TextEditingController();
    String selectedRole = user?.role ?? 'CUSTOMER';
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(builder: (ctx, dlgSet) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
        contentPadding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
        title: Row(children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(gradient: AppColors.primaryGradient, borderRadius: BorderRadius.circular(12)),
            child: Icon(isEdit ? Icons.edit_rounded : Icons.person_add_rounded, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Text(isEdit ? 'Chỉnh sửa tài khoản' : 'Thêm tài khoản mới',
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
        ]),
        content: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const SizedBox(height: 8),
            _dialogField(nameCtrl,  'Họ và tên', Icons.person_outline, false),
            const SizedBox(height: 12),
            _dialogField(emailCtrl, 'Email', Icons.email_outlined, false, readOnly: isEdit,
              keyboardType: TextInputType.emailAddress),
            const SizedBox(height: 12),
            _dialogField(phoneCtrl, 'Số điện thoại', Icons.phone_outlined, false,
              keyboardType: TextInputType.phone),
            if (!isEdit) ...[
              const SizedBox(height: 12),
              _dialogField(passCtrl,  'Mật khẩu', Icons.lock_outline, true),
            ],
            // Hiện staffCode nếu đang sửa nhân viên
            if (isEdit && user.staffCode != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(color: AppColors.staffTeal.withAlpha(20), borderRadius: BorderRadius.circular(12)),
                child: Row(children: [
                  const Icon(Icons.badge_rounded, color: AppColors.staffTeal, size: 20),
                  const SizedBox(width: 10),
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('Mã nhân viên', style: TextStyle(fontSize: 11, color: AppColors.staffTeal)),
                    Text(user.staffCode!, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.staffTeal, fontFamily: 'monospace')),
                  ]),
                ]),
              ),
            ],
            const SizedBox(height: 12),
            // Role selector
            DropdownButtonFormField<String>(
              value: selectedRole,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.manage_accounts_outlined),
                labelText: 'Vai trò',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
              items: [
                DropdownMenuItem(value: 'CUSTOMER', child: Text(_roleLabel('CUSTOMER'))),
                DropdownMenuItem(value: 'STAFF',    child: Text(_roleLabel('STAFF'))),
                DropdownMenuItem(value: 'ADMIN',    child: Text(_roleLabel('ADMIN'))),
              ],
              onChanged: (v) => dlgSet(() => selectedRole = v ?? 'CUSTOMER'),
            ),
            const SizedBox(height: 8),
          ]),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: isSaving ? null : () async {
              if (nameCtrl.text.trim().isEmpty || emailCtrl.text.trim().isEmpty) return;
              dlgSet(() => isSaving = true);
              try {
                if (isEdit) {
                  await _service.updateUser(user.id,
                    fullName: nameCtrl.text.trim(),
                    phone:    phoneCtrl.text.trim(),
                    role:     selectedRole,
                  );
                } else {
                  if (passCtrl.text.trim().isEmpty) {
                    dlgSet(() => isSaving = false);
                    return;
                  }
                  await _service.createUser(
                    email:    emailCtrl.text.trim(),
                    password: passCtrl.text.trim(),
                    fullName: nameCtrl.text.trim(),
                    phone:    phoneCtrl.text.trim(),
                    role:     selectedRole,
                  );
                }
                if (ctx.mounted) Navigator.pop(ctx);
                await _loadUsers();
                if (mounted) _showSnack(isEdit ? 'Cập nhật thành công!' : 'Tạo tài khoản thành công!', AppColors.success);
              } catch (e) {
                dlgSet(() => isSaving = false);
                if (mounted) _showSnack(e.toString().replaceFirst('Exception: ', ''), AppColors.error);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryBlue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
            ),
            child: isSaving
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : Text(isEdit ? 'Lưu' : 'Tạo', style: const TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      )),
    );
  }

  // ── Xác nhận xóa ─────────────────────────────────────────────
  void _confirmDelete(UserModel user) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Xóa tài khoản', style: TextStyle(fontWeight: FontWeight.w800)),
        content: RichText(text: TextSpan(
          style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
          children: [
            const TextSpan(text: 'Bạn có chắc muốn xóa tài khoản '),
            TextSpan(text: user.fullName, style: const TextStyle(fontWeight: FontWeight.w700)),
            const TextSpan(text: '? Hành động này không thể khôi phục.'),
          ],
        )),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await _service.deleteUser(user.id);
                await _loadUsers();
                if (mounted) _showSnack('Đã xóa tài khoản ${user.fullName}', AppColors.success);
              } catch (e) {
                if (mounted) _showSnack(e.toString().replaceFirst('Exception: ', ''), AppColors.error);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error, foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            child: const Text('Xóa', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  void _showSnack(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message, style: const TextStyle(fontWeight: FontWeight.w600)),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  Widget _dialogField(TextEditingController ctrl, String label, IconData icon, bool obscure, {
    bool readOnly = false, TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: ctrl,
      obscureText: obscure,
      readOnly: readOnly,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        prefixIcon: Icon(icon),
        labelText: label,
        filled: readOnly,
        fillColor: readOnly ? AppColors.background : null,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      // ── Header ───────────────────────────────────────────────
      Container(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Quản lý người dùng', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
                Text('Thêm, sửa, xóa tài khoản hệ thống', style: TextStyle(color: AppColors.textSecondary)),
              ]),
            ),
            ElevatedButton.icon(
              onPressed: () => _showUserDialog(),
              icon: const Icon(Icons.person_add_rounded, size: 18),
              label: const Text('Thêm', style: TextStyle(fontWeight: FontWeight.w700)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ]),
          const SizedBox(height: 16),
          // Search + Role Filter
          Row(children: [
            Expanded(
              child: TextField(
                onChanged: (v) => setState(() { _searchQuery = v; _applyFilter(); }),
                decoration: InputDecoration(
                  hintText: 'Tìm theo tên hoặc email...',
                  prefixIcon: const Icon(Icons.search, size: 20),
                  filled: true,
                  fillColor: AppColors.background,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Role filter chips
            _roleChip('ALL', 'Tất cả'),
          ]),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(children: [
              _roleChip('CUSTOMER', 'Khách hàng'),
              const SizedBox(width: 8),
              _roleChip('STAFF',    'Nhân viên'),
              const SizedBox(width: 8),
              _roleChip('ADMIN',    'Quản trị'),
            ]),
          ),
          const SizedBox(height: 12),
          // Summary stats
          Row(children: [
            _statPill('${_users.length}', 'Tổng', AppColors.primaryBlue),
            const SizedBox(width: 8),
            _statPill('${_users.where((u) => u.role == "CUSTOMER").length}', 'KH', AppColors.staffTeal),
            const SizedBox(width: 8),
            _statPill('${_users.where((u) => u.role == "STAFF").length}', 'NV', AppColors.staffOrange),
            const SizedBox(width: 8),
            _statPill('${_users.where((u) => u.role == "ADMIN").length}', 'Admin', const Color(0xFF6C3EB8)),
          ]),
          const SizedBox(height: 12),
        ]),
      ),
      const Divider(height: 1),
      // ── User List ────────────────────────────────────────────
      Expanded(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _filtered.isEmpty
                ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.people_outline, size: 48, color: AppColors.textLight),
                    const SizedBox(height: 8),
                    const Text('Không tìm thấy người dùng nào', style: TextStyle(color: AppColors.textSecondary)),
                    const SizedBox(height: 12),
                    TextButton(onPressed: _loadUsers, child: const Text('Tải lại')),
                  ]))
                : RefreshIndicator(
                    onRefresh: _loadUsers,
                    child: ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: _filtered.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (_, i) => _buildUserCard(_filtered[i]),
                    ),
                  ),
      ),
    ]);
  }

  Widget _buildUserCard(UserModel user) {
    final color = _roleColor(user.role);
    final isCurrentAdmin = user.id == widget.adminUser.id;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: isCurrentAdmin ? Border.all(color: AppColors.primaryBlue, width: 1.5) : null,
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(8), blurRadius: 8)],
      ),
      child: Row(children: [
        // Avatar
        CircleAvatar(
          radius: 24,
          backgroundColor: color.withAlpha(30),
          child: Text(
            user.fullName.isNotEmpty ? user.fullName[0].toUpperCase() : '?',
            style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.w800),
          ),
        ),
        const SizedBox(width: 14),
        // Info
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(child: Text(user.fullName,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
              maxLines: 1, overflow: TextOverflow.ellipsis)),
            if (isCurrentAdmin) Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(color: AppColors.primaryBlue.withAlpha(25), borderRadius: BorderRadius.circular(8)),
              child: const Text('Bạn', style: TextStyle(fontSize: 10, color: AppColors.primaryBlue, fontWeight: FontWeight.w700)),
            ),
          ]),
          const SizedBox(height: 3),
          Text(user.email, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
            maxLines: 1, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 6),
          Row(children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(color: color.withAlpha(25), borderRadius: BorderRadius.circular(8)),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(_roleIcon(user.role), size: 12, color: color),
                const SizedBox(width: 4),
                Text(_roleLabel(user.role), style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w700)),
              ]),
            ),
            if (user.phone.isNotEmpty) ...[
              const SizedBox(width: 8),
              Icon(Icons.phone_outlined, size: 12, color: AppColors.textLight),
              const SizedBox(width: 3),
              Text(user.phone, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
            ],
            // Hiện staffCode nếu là nhân viên
            if (user.staffCode != null) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: AppColors.staffTeal.withAlpha(20), borderRadius: BorderRadius.circular(6)),
                child: Text(user.staffCode!, style: const TextStyle(fontSize: 10, color: AppColors.staffTeal, fontWeight: FontWeight.w700, fontFamily: 'monospace')),
              ),
            ],
          ]),
        ])),
        // Actions
        if (!isCurrentAdmin) PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert, color: AppColors.textSecondary),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          itemBuilder: (_) => [
            const PopupMenuItem(value: 'edit',   child: Row(children: [Icon(Icons.edit_outlined, size: 18), SizedBox(width: 10), Text('Chỉnh sửa')])),
            const PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete_outline, color: AppColors.error, size: 18), SizedBox(width: 10), Text('Xóa', style: TextStyle(color: AppColors.error))])),
          ],
          onSelected: (action) {
            if (action == 'edit')   _showUserDialog(user: user);
            if (action == 'delete') _confirmDelete(user);
          },
        ),
      ]),
    );
  }

  Widget _roleChip(String role, String label) {
    final sel = _roleFilter == role;
    return GestureDetector(
      onTap: () => setState(() { _roleFilter = role; _applyFilter(); }),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          gradient: sel ? AppColors.primaryGradient : null,
          color: sel ? null : AppColors.background,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(label, style: TextStyle(
          color: sel ? Colors.white : AppColors.textSecondary,
          fontSize: 13, fontWeight: FontWeight.w600,
        )),
      ),
    );
  }

  Widget _statPill(String value, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: color.withAlpha(20), borderRadius: BorderRadius.circular(10)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: color)),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: 12, color: color.withAlpha(200))),
      ]),
    );
  }
}
