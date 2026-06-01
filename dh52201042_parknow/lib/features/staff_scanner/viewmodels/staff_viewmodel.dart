import 'package:flutter/material.dart';
import '../models/shift_model.dart';
import '../models/violation_model.dart';
import '../services/staff_service.dart';

class StaffViewModel extends ChangeNotifier {
  late final StaffService _service;
  int? _staffId;
  ShiftModel? _activeShift;
  List<ShiftModel> _shiftHistory = [];
  List<ViolationModel> _violations = [];
  bool _isLoading = false;
  String _error = '';

  /// Tên bãi đỗ xe hiện tại (resolve từ activeShift.parkingLotId)
  String _activeLotName = 'Bãi đỗ ParkNow';
  int _activeLotTotalSlots = 100;
  int _activeLotAvailableSlots = 100;

  StaffViewModel({String? token, int? staffId}) {
    _service = StaffService(token: token);
    _staffId = staffId;
  }

  ShiftModel? get activeShift => _activeShift;
  List<ShiftModel> get shiftHistory => _shiftHistory;
  List<ViolationModel> get violations => _violations;
  bool get isLoading => _isLoading;
  String get error => _error;
  String get activeLotName => _activeLotName;
  int get activeLotTotalSlots => _activeLotTotalSlots;
  int get activeLotAvailableSlots => _activeLotAvailableSlots;

  /// Exposed để QrScannerView gọi trực tiếp checkIn/checkOut
  StaffService get service => _service;

  Future<void> loadActiveShift(int staffId) async {
    _activeShift = await _service.getActiveShift(staffId);
    if (_activeShift != null) {
      _loadLotName(_activeShift!.parkingLotId);
    }
    notifyListeners();
  }

  Future<void> _loadLotName(int lotId) async {
    final lot = await _service.getParkingLot(lotId);
    if (lot != null) {
      _activeLotName = (lot['name'] as String?) ?? 'Bãi đỗ ParkNow';
      _activeLotTotalSlots = (lot['totalSlots'] as int?) ?? 100;
      _activeLotAvailableSlots = (lot['availableSlots'] as int?) ?? 100;
      notifyListeners();
    }
  }

  Future<void> startShift(int staffId, int lotId) async {
    _isLoading = true;
    _error = '';
    notifyListeners();
    try {
      _activeShift = await _service.startShift(staffId, lotId);
      _loadLotName(lotId);
    } catch (e) {
      _error = e.toString();
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> endShift() async {
    if (_activeShift == null) return;
    _isLoading = true;
    _error = '';
    notifyListeners();
    try {
      await _service.endShift(_activeShift!.id!);
      _activeShift = null;
      _activeLotName = 'Bãi đỗ ParkNow';
    } catch (e) {
      _error = e.toString();
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> recordEntry(double amount, String paymentType) async {
    if (_activeShift == null) return;
    _error = '';
    try {
      _activeShift = await _service.recordEntry(_activeShift!.id!, amount, paymentType);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> recordExit() async {
    if (_activeShift == null) return;
    _error = '';
    try {
      _activeShift = await _service.recordExit(_activeShift!.id!);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> loadShiftHistory(int staffId) async {
    try {
      _shiftHistory = await _service.getShiftHistory(staffId);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> loadViolations() async {
    try {
      _violations = await _service.getViolations(staffId: _staffId);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> createViolation(ViolationModel v) async {
    try {
      await _service.createViolation(v);
      await loadViolations();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> resolveViolation(int id) async {
    try {
      await _service.resolveViolation(id);
      await loadViolations();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> checkInManual(String vehiclePlate, String vehicleType, int staffId) async {
    if (_activeShift == null) return;
    _isLoading = true;
    _error = '';
    notifyListeners();
    try {
      // 1. Tạo booking data
      final now = DateTime.now();
      final data = {
        'userId': staffId,
        'parkingLotId': _activeShift!.parkingLotId,
        'vehiclePlate': vehiclePlate,
        'vehicleType': vehicleType,
        'startTime': now.toIso8601String(),
        // Giả sử đỗ 2 giờ để tính giá
        'endTime': now.add(const Duration(hours: 2)).toIso8601String(),
        'paymentMethod': 'cash',
        'status': 'confirmed'
      };
      
      // 2. Gọi API tạo booking ở backend
      final booking = await _service.createManualBooking(data);
      final bookingId = booking['id'] as int?;
      final totalCost = (booking['totalCost'] as num?)?.toDouble() ?? 0.0;
      
      if (bookingId != null) {
        // 3. Tiến hành check-in booking
        await _service.checkInBooking(bookingId);
        // 4. Ghi nhận xe vào trong ca trực với số tiền thật từ backend
        _activeShift = await _service.recordEntry(_activeShift!.id!, totalCost, 'cash');
      }
      
      // Load lại thông tin ca trực để cập nhật số xe hiện tại
      await loadActiveShift(staffId);
    } catch (e) {
      _error = e.toString().replaceFirst("Exception: ", "");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
