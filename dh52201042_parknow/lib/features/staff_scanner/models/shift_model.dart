class ShiftModel {
  final int? id;
  final int staffId;
  final int parkingLotId;
  final DateTime? startTime;
  final DateTime? endTime;
  final int totalIn;
  final int totalOut;
  final double cashRevenue;
  final double onlineRevenue;
  final String status;

  ShiftModel({this.id, required this.staffId, required this.parkingLotId, this.startTime, this.endTime, this.totalIn = 0, this.totalOut = 0, this.cashRevenue = 0, this.onlineRevenue = 0, this.status = 'active'});

  double get totalRevenue => cashRevenue + onlineRevenue;

  factory ShiftModel.fromJson(Map<String, dynamic> json) {
    return ShiftModel(
      id: json['id'], staffId: json['staffId'], parkingLotId: json['parkingLotId'],
      startTime: json['startTime'] != null ? DateTime.parse(json['startTime']) : null,
      endTime: json['endTime'] != null ? DateTime.parse(json['endTime']) : null,
      totalIn: json['totalIn'] ?? 0, totalOut: json['totalOut'] ?? 0,
      cashRevenue: json['cashRevenue'] != null ? double.parse(json['cashRevenue'].toString()) : 0,
      onlineRevenue: json['onlineRevenue'] != null ? double.parse(json['onlineRevenue'].toString()) : 0,
      status: json['status'] ?? 'active',
    );
  }
}
