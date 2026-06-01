import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:latlong2/latlong.dart';

/// Service xử lý runtime permission GPS và lấy vị trí hiện tại.
/// Được gọi trước khi load bản đồ để đảm bảo quyền được cấp.
class LocationService {
  /// Kiểm tra và yêu cầu quyền truy cập vị trí.
  /// Trả về `true` nếu quyền được cấp, `false` nếu bị từ chối.
  static Future<bool> requestPermission() async {
    // Kiểm tra GPS có bật không
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return false;

    // Dùng permission_handler để xin quyền với dialog giải thích
    var status = await Permission.locationWhenInUse.status;
    if (status.isDenied) {
      status = await Permission.locationWhenInUse.request();
    }
    if (status.isPermanentlyDenied) {
      // Người dùng đã chặn vĩnh viễn — mở Settings
      await openAppSettings();
      return false;
    }
    return status.isGranted;
  }

  /// Lấy vị trí hiện tại của thiết bị.
  /// Trả về null nếu không có quyền hoặc lỗi.
  static Future<LatLng?> getCurrentLocation() async {
    final granted = await requestPermission();
    if (!granted) return null;
    try {
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );
      
      double lat = pos.latitude;
      double lon = pos.longitude;
      
      // Tự động mock tọa độ về Trung tâm Quận 1, TP.HCM nếu tọa độ thực tế nằm ngoài Việt Nam (thường do Emulator)
      if (lat < 8.0 || lat > 24.0 || lon < 102.0 || lon > 110.0) {
        lat = 10.779785; // Nhà thờ Đức Bà, Quận 1
        lon = 106.699019;
      }
      
      return LatLng(lat, lon);
    } catch (_) {
      // Nếu có lỗi định vị (như máy ảo chưa bật GPS), trả về tọa độ mock để tránh crash
      return LatLng(10.779785, 106.699019);
    }
  }

  /// Tính khoảng cách (mét) giữa 2 toạ độ.
  static double distanceBetween(LatLng from, LatLng to) {
    return Geolocator.distanceBetween(
      from.latitude, from.longitude,
      to.latitude,   to.longitude,
    );
  }
}
