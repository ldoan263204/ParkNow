/// Model đặt chỗ (Booking)
class BookingModel {
  final int? id;
  final int userId;
  final int parkingLotId;
  final String vehiclePlate;
  final String vehicleType; // car, motorbike
  final DateTime startTime;
  final DateTime endTime;
  final double? totalCost;
  final double? parkingFee;
  final double? serviceFee;
  final double? tax;
  final String? status;
  final String? paymentMethod;  // momo, card, cash
  final String? paymentStatus;  // paid, unpaid
  final String? slotNumber;

  BookingModel({
    this.id,
    required this.userId,
    required this.parkingLotId,
    required this.vehiclePlate,
    required this.vehicleType,
    required this.startTime,
    required this.endTime,
    this.totalCost,
    this.parkingFee,
    this.serviceFee,
    this.tax,
    this.status,
    this.paymentMethod,
    this.paymentStatus,
    this.slotNumber,
  });

  factory BookingModel.fromJson(Map<String, dynamic> json) {
    return BookingModel(
      id: json['id'],
      userId: json['userId'] ?? 0,
      parkingLotId: json['parkingLotId'] ?? 0,
      vehiclePlate: json['vehiclePlate'] ?? '',
      vehicleType: json['vehicleType'] ?? 'car',
      startTime: DateTime.parse(json['startTime']),
      endTime: DateTime.parse(json['endTime']),
      totalCost: json['totalCost'] != null
          ? double.parse(json['totalCost'].toString())
          : null,
      parkingFee: json['parkingFee'] != null
          ? double.parse(json['parkingFee'].toString())
          : null,
      serviceFee: json['serviceFee'] != null
          ? double.parse(json['serviceFee'].toString())
          : null,
      tax: json['tax'] != null
          ? double.parse(json['tax'].toString())
          : null,
      status: json['status'],
      paymentMethod: json['paymentMethod'],
      paymentStatus: json['paymentStatus'],
      slotNumber: json['slotNumber'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'parkingLotId': parkingLotId,
      'vehiclePlate': vehiclePlate,
      'vehicleType': vehicleType,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime.toIso8601String(),
      if (paymentMethod != null) 'paymentMethod': paymentMethod,
      if (slotNumber != null) 'slotNumber': slotNumber,
    };
  }
}
