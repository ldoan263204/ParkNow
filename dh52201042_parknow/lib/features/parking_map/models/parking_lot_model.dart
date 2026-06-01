/// Model bãi đỗ xe (phiên bản đầy đủ)
class ParkingLot {
  final int id;
  final int? ownerId;
  final String name;
  final String address;
  final double latitude;
  final double longitude;
  final int totalSlots;
  final int availableSlots;
  final double pricePerHour;
  final String status;
  final String? rejectionReason;

  ParkingLot({
    required this.id,
    this.ownerId,
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.totalSlots,
    required this.availableSlots,
    required this.pricePerHour,
    required this.status,
    this.rejectionReason,
  });

  // Tính phần trăm chỗ đã đỗ
  double get occupancyPercent =>
      totalSlots > 0 ? (totalSlots - availableSlots) / totalSlots : 0;

  // Kiểm tra còn chỗ trống
  bool get hasAvailableSlots => availableSlots > 0;

  factory ParkingLot.fromJson(Map<String, dynamic> json) {
    return ParkingLot(
      id: json['id'],
      ownerId: json['ownerId'],
      name: json['name'] ?? '',
      address: json['address'] ?? '',
      latitude: (json['latitude'] ?? 0).toDouble(),
      longitude: (json['longitude'] ?? 0).toDouble(),
      totalSlots: json['totalSlots'] ?? 0,
      availableSlots: json['availableSlots'] ?? 0,
      pricePerHour: json['pricePerHour'] != null
          ? double.parse(json['pricePerHour'].toString())
          : 0.0,
      status: json['status'] ?? 'pending',
      rejectionReason: json['rejectionReason'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'ownerId': ownerId,
      'name': name,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'totalSlots': totalSlots,
      'availableSlots': availableSlots,
      'pricePerHour': pricePerHour,
      'status': status,
      'rejectionReason': rejectionReason,
    };
  }
}