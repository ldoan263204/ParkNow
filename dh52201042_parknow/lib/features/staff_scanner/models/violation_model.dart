class ViolationModel {
  final int? id;
  final int parkingLotId;
  final int reportedBy;
  final String vehiclePlate;
  final String reason;
  final String? imageUrl;
  final String status;
  final DateTime? createdAt;

  // Giai đoạn 3: tiền phạt và hạn thanh toán
  final double? penaltyAmount;
  final DateTime? paymentDeadline;
  final DateTime? resolvedAt;

  ViolationModel({
    this.id,
    required this.parkingLotId,
    required this.reportedBy,
    required this.vehiclePlate,
    required this.reason,
    this.imageUrl,
    this.status = 'pending',
    this.createdAt,
    this.penaltyAmount,
    this.paymentDeadline,
    this.resolvedAt,
  });

  String get reasonText {
    switch (reason) {
      case 'wrong_spot': return 'Đỗ sai vạch';
      case 'expired': return 'Hết hạn gửi';
      case 'no_ticket': return 'Không có vé';
      default: return 'Khác';
    }
  }

  /// Kiểm tra còn trong thời hạn thanh toán không
  bool get isWithinDeadline {
    if (paymentDeadline == null) return true;
    return DateTime.now().isBefore(paymentDeadline!);
  }

  /// Số giây còn lại đến deadline
  int get secondsRemaining {
    if (paymentDeadline == null) return 0;
    final diff = paymentDeadline!.difference(DateTime.now()).inSeconds;
    return diff > 0 ? diff : 0;
  }

  /// Kiểm tra xem có đang bị phạt khóa 1 phút sau khi đóng phạt không
  bool get isInOneMinutePenalty {
    if (status != 'resolved' || resolvedAt == null) return false;
    final unlockTime = resolvedAt!.add(const Duration(minutes: 1));
    return DateTime.now().isBefore(unlockTime);
  }

  /// Số giây còn lại cho đến khi được mở khóa (sau khi đóng phạt)
  int get unlockSecondsRemaining {
    if (status != 'resolved' || resolvedAt == null) return 0;
    final diff = resolvedAt!.add(const Duration(minutes: 1)).difference(DateTime.now()).inSeconds;
    return diff > 0 ? diff : 0;
  }

  factory ViolationModel.fromJson(Map<String, dynamic> json) {
    return ViolationModel(
      id: json['id'],
      parkingLotId: _parseInt(json['parkingLotId']),
      reportedBy: _parseInt(json['reportedBy']),
      vehiclePlate: json['vehiclePlate'] ?? '',
      reason: json['reason'] ?? '',
      imageUrl: json['imageUrl'],
      status: json['status'] ?? 'pending',
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt'].toString()) : null,
      penaltyAmount: json['penaltyAmount'] != null ? double.tryParse(json['penaltyAmount'].toString()) : null,
      paymentDeadline: json['paymentDeadline'] != null ? DateTime.tryParse(json['paymentDeadline'].toString()) : null,
      resolvedAt: json['resolvedAt'] != null ? DateTime.tryParse(json['resolvedAt'].toString()) : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'parkingLotId': parkingLotId,
    'reportedBy': reportedBy,
    'vehiclePlate': vehiclePlate,
    'reason': reason,
    if (imageUrl != null) 'imageUrl': imageUrl,
  };

  static int _parseInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    return int.tryParse(v.toString()) ?? 0;
  }
}
