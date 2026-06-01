import 'package:flutter/material.dart';
import '../models/parking_lot_model.dart';
import '../services/parking_map_service.dart';
import '../../../features/staff_scanner/models/violation_model.dart';

class ParkingMapViewModel extends ChangeNotifier {
  final ParkingMapService _service = ParkingMapService();
  
  List<ParkingLot> _parkingLots = [];
  List<ViolationModel> _violations = [];
  bool _isLoading = false;
  String _errorMessage = '';

  List<ParkingLot> get parkingLots => _parkingLots;
  List<ViolationModel> get violations => _violations;
  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;

  /// Các vi phạm chưa xử lý (pending)
  List<ViolationModel> get pendingViolations => 
      _violations.where((v) => v.status == 'pending').toList();

  /// Kiểm tra Customer có bị khóa (do có bất kỳ vi phạm pending nào quá hạn, hoặc vừa đóng phạt chưa quá 1 phút) không
  bool get isCustomerLocked => 
      _violations.any((v) => (v.status == 'pending' && !v.isWithinDeadline) || v.isInOneMinutePenalty);

  Future<void> loadParkingLots() async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      _parkingLots = await _service.fetchParkingLots();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Tải danh sách vi phạm của Customer
  Future<void> loadViolations(int customerId) async {
    try {
      final list = await _service.fetchCustomerViolations(customerId);
      // Sắp xếp vi phạm mới nhất lên đầu
      list.sort((a, b) {
        if (a.createdAt == null) return 1;
        if (b.createdAt == null) return -1;
        return b.createdAt!.compareTo(a.createdAt!);
      });
      _violations = list;
      notifyListeners();
    } catch (_) {}
  }

  /// Thực hiện nộp phạt
  Future<bool> payViolation(int violationId, int customerId) async {
    _isLoading = true;
    notifyListeners();
    final success = await _service.resolveViolation(violationId);
    if (success) {
      await loadViolations(customerId);
    }
    _isLoading = false;
    notifyListeners();
    return success;
  }
}