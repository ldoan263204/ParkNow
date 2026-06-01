import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import '../../../core/theme/app_colors.dart';
import '../../../core/services/location_service.dart';
import '../../../core/utils/vnd_formatter.dart';
import '../../../features/authentication/models/user_model.dart';
import '../../../features/authentication/views/welcome_view.dart';
import '../viewmodels/parking_map_viewmodel.dart';
import '../models/parking_lot_model.dart';
import 'lot_detail_view.dart';
import 'my_bookings_view.dart';

class CustomerMapView extends StatefulWidget {
  final UserModel user;
  const CustomerMapView({super.key, required this.user});

  @override
  State<CustomerMapView> createState() => _CustomerMapViewState();
}

class _CustomerMapViewState extends State<CustomerMapView> {
  final ParkingMapViewModel _viewModel = ParkingMapViewModel();
  final MapController _mapController = MapController();
  final TextEditingController _searchController = TextEditingController();

  // Tọa độ trung tâm mặc định: TP. Hồ Chí Minh
  final LatLng _center = const LatLng(10.762622, 106.660172);
  int _selectedTab = 0;
  String _searchQuery = '';
  bool _isSearching = false;

  // --- OSRM Routing ---
  List<LatLng> _routePoints = [];
  LatLng? _userLocation;
  bool _isLoadingRoute = false;

  // --- Violation Tracking & Timers ---
  Timer? _violationTimer;
  Timer? _countdownTimer;
  int _lastViolationCount = 0;
  bool _showBanner = true;

  @override
  void initState() {
    super.initState();
    // Xin quyền GPS và di chuyển bản đồ đến vị trí hiện tại của người dùng
    _initUserLocation();
    _viewModel.loadParkingLots().then((_) {
      if (mounted) setState(() {});
    });
    
    // Tải vi phạm ngay lập tức và theo dõi
    _viewModel.loadViolations(widget.user.id).then((_) {
      if (mounted) {
        _lastViolationCount = _viewModel.pendingViolations.length;
        setState(() {});
      }
    });

    // Lắng nghe sự thay đổi của viewModel để cập nhật UI
    _viewModel.addListener(_onViewModelChanged);

    // Polling vi phạm và bãi đỗ xe sau mỗi 15 giây
    _violationTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      _viewModel.loadViolations(widget.user.id);
      _viewModel.loadParkingLots();
    });

    // Đếm ngược mỗi giây để cập nhật UI
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted && _viewModel.pendingViolations.isNotEmpty) {
        setState(() {});
      }
    });
  }

  void _onViewModelChanged() {
    if (!mounted) return;
    final currentPending = _viewModel.pendingViolations.length;
    if (currentPending > _lastViolationCount) {
      // Có vi phạm mới phát sinh!
      _showBanner = true;
      // Bắn thông báo nổi lên màn hình (Snack hoặc Dialog)
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ CẢNH BÁO: Phát hiện vi phạm mới! Vui lòng kiểm tra và xử lý ngay.'),
          backgroundColor: AppColors.error,
          duration: Duration(seconds: 5),
        ),
      );
    }
    _lastViolationCount = currentPending;
    setState(() {});
  }

  Future<void> _initUserLocation() async {
    try {
      final pos = await LocationService.getCurrentLocation();
      if (pos != null && mounted) {
        setState(() {
          _userLocation = pos;
        });
        _mapController.move(pos, 15.0);
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _viewModel.removeListener(_onViewModelChanged);
    _violationTimer?.cancel();
    _countdownTimer?.cancel();
    _mapController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  // --- Lọc bãi xe theo từ khóa ---
  List<ParkingLot> get _sortedLots {
    var lots = List<ParkingLot>.from(_viewModel.parkingLots);
    // Lọc theo search
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      lots = lots.where((l) =>
        l.name.toLowerCase().contains(q) ||
        l.address.toLowerCase().contains(q)
      ).toList();
    }
    if (_selectedTab == 1) lots.sort((a, b) => a.pricePerHour.compareTo(b.pricePerHour));
    if (_selectedTab == 2) lots.sort((a, b) => b.availableSlots.compareTo(a.availableSlots));
    return lots;
  }

  // --- Nominatim Geocoding: tìm tọa độ theo từ khóa ---
  Future<void> _searchAndFly(String query) async {
    if (query.trim().isEmpty) return;
    setState(() => _isSearching = true);
    try {
      final uri = Uri.parse(
        'https://nominatim.openstreetmap.org/search'
        '?q=${Uri.encodeComponent(query)}&format=json&limit=1',
      );
      final response = await http.get(uri, headers: {
        'User-Agent': 'ParkNow/1.0 (parknow@example.com)',
      });
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as List;
        if (data.isNotEmpty) {
          final lat = double.parse(data[0]['lat']);
          final lon = double.parse(data[0]['lon']);
          _mapController.move(LatLng(lat, lon), 15.0);
        } else if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Không tìm thấy địa điểm này!')),
          );
        }
      }
    } catch (_) {} finally {
      if (mounted) setState(() => _isSearching = false);
    }
  }

  // --- Hiện Profile BottomSheet (Customer) ---
  void _showProfileSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _ProfileBottomSheet(
        user: widget.user,
        onLogout: _handleLogout,
        onViewViolations: _showViolationsSheet,
      ),
    );
  }

  // --- Đăng xuất ---
  void _handleLogout() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const WelcomeView()),
      (route) => false,
    );
  }

  // --- OSRM: Lấy tuyến đường từ vị trí người dùng đến bãi xe ---
  Future<void> _fetchRoute(ParkingLot lot) async {
    setState(() => _isLoadingRoute = true);
    try {
      // Lấy vị trí hiện tại
      final pos = await LocationService.getCurrentLocation();
      if (pos == null) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không lấy được vị trí GPS!')));
        setState(() => _isLoadingRoute = false);
        return;
      }
      _userLocation = pos;

      // Gọi OSRM API (miễn phí)
      final url = Uri.parse(
        'https://router.project-osrm.org/route/v1/driving/'
        '${pos.longitude},${pos.latitude};${lot.longitude},${lot.latitude}'
        '?overview=full&geometries=geojson',
      );
      final res = await http.get(url, headers: {'User-Agent': 'ParkNow/1.0'});
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final coords = data['routes'][0]['geometry']['coordinates'] as List;
        setState(() {
          _routePoints = coords
              .map((c) => LatLng((c[1] as num).toDouble(), (c[0] as num).toDouble()))
              .toList();
        });
        // Fly đến bãi xe
        _mapController.move(LatLng(lot.latitude, lot.longitude), 14.5);
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi chỉ đường: $e')));
    }
    if (mounted) setState(() => _isLoadingRoute = false);
  }

  // --- Xóa route ---
  void _clearRoute() => setState(() { _routePoints = []; _userLocation = null; });

  // Hiển thị thông tin bãi xe khi bấm vào marker trên bản đồ
  void _showLotInfo(ParkingLot lot) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [BoxShadow(color: Colors.black.withAlpha(30), blurRadius: 20)],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Container(
              width: 40, height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(color: AppColors.divider, borderRadius: BorderRadius.circular(2)),
            ),
            // Header icon
            Container(
              width: 56, height: 56,
              decoration: BoxDecoration(gradient: AppColors.primaryGradient, borderRadius: BorderRadius.circular(16)),
              child: const Icon(Icons.local_parking, color: Colors.white, size: 28),
            ),
            const SizedBox(height: 12),
            Text(lot.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textPrimary), textAlign: TextAlign.center),
            const SizedBox(height: 4),
            Text(lot.address, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary), textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 16),
            // Thống kê nhanh
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _infoStat(Icons.event_seat_rounded, '${lot.availableSlots}/${lot.totalSlots}', 'Chỗ trống', AppColors.success),
                _divider(),
                _infoStat(Icons.payments_rounded, lot.pricePerHour.toVnd(), '/giờ', AppColors.primaryBlue),
                _divider(),
                _infoStat(
                  lot.hasAvailableSlots ? Icons.check_circle_rounded : Icons.cancel_rounded,
                  lot.hasAvailableSlots ? 'Còn chỗ' : 'Hết chỗ',
                  'Trạng thái',
                  lot.hasAvailableSlots ? AppColors.success : AppColors.error,
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Thanh tiến trình công suất
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Mức độ lấp đầy', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                    Text('${(lot.occupancyPercent * 100).toInt()}%',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700,
                        color: lot.occupancyPercent > 0.8 ? AppColors.error : AppColors.success)),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: lot.occupancyPercent,
                    backgroundColor: AppColors.divider,
                    valueColor: AlwaysStoppedAnimation(lot.occupancyPercent > 0.8 ? AppColors.error : AppColors.success),
                    minHeight: 10,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Hai nút hành động
            Row(children: [
              // Nút Chỉ đường
              Expanded(child: OutlinedButton.icon(
                onPressed: _isLoadingRoute ? null : () {
                  Navigator.pop(context);
                  _fetchRoute(lot);
                },
                icon: _isLoadingRoute
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.directions_rounded),
                label: const Text('Chỉ đường'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primaryBlue,
                  side: const BorderSide(color: AppColors.primaryBlue),
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                ),
              )),
              const SizedBox(width: 12),
              // Nút Đặt ngay
              Expanded(child: ElevatedButton.icon(
                onPressed: (lot.hasAvailableSlots && !_viewModel.isCustomerLocked)
                    ? () {
                        Navigator.pop(context);
                        Navigator.push(context, MaterialPageRoute(
                          builder: (_) => LotDetailView(lot: lot, userId: widget.user.id, token: widget.user.token, userLocation: _userLocation),
                        ));
                      }
                    : null,
                icon: const Icon(Icons.bookmark_add_rounded),
                label: Text(_viewModel.isCustomerLocked 
                    ? 'Bị khóa' 
                    : (lot.hasAvailableSlots ? 'Đặt ngay' : 'Hết chỗ')),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _viewModel.isCustomerLocked ? AppColors.error : AppColors.primaryBlue,
                  disabledBackgroundColor: AppColors.divider,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                ),
              )),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _infoStat(IconData icon, String value, String label, Color color) {
    return Column(children: [
      Icon(icon, color: color, size: 22),
      const SizedBox(height: 4),
      Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: color)),
      Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
    ]);
  }

  Widget _divider() => Container(width: 1, height: 40, color: AppColors.divider);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _viewModel.isLoading
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                // --- Bản đồ OpenStreetMap ---
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: _center,
                    initialZoom: 13.5,
                    maxZoom: 19,
                    minZoom: 5,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.example.dh52201042_parknow',
                      maxZoom: 19,
                    ),
                    MarkerLayer(
                      markers: _viewModel.parkingLots.map((lot) {
                        return Marker(
                          point: LatLng(lot.latitude, lot.longitude),
                          width: 50, height: 60,
                          child: GestureDetector(
                            onTap: () => _showLotInfo(lot),
                            child: Column(children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: lot.hasAvailableSlots ? AppColors.success : AppColors.error,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text('${lot.availableSlots}',
                                  style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800)),
                              ),
                              Icon(Icons.location_on,
                                color: lot.hasAvailableSlots ? AppColors.primaryBlue : AppColors.error,
                                size: 40,
                                shadows: const [Shadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 2))]),
                            ]),
                          ),
                        );
                      }).toList(),
                    ),
                    // ── Tuyến đường OSRM ─────────────────────────────
                    if (_routePoints.isNotEmpty)
                      PolylineLayer(polylines: <Polyline<Object>>[
                        Polyline(
                          points: _routePoints,
                          strokeWidth: 5,
                          color: AppColors.primaryBlue,
                        ),
                      ]),
                    // ── Vị trí người dùng ─────────────────────────────
                    if (_userLocation != null)
                      MarkerLayer(markers: [
                        Marker(
                          point: _userLocation!,
                          width: 24, height: 24,
                          child: Container(
                            decoration: BoxDecoration(
                              color: AppColors.primaryBlue,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 3),
                              boxShadow: [BoxShadow(color: AppColors.primaryBlue.withAlpha(100), blurRadius: 8)],
                            ),
                          ),
                        ),
                      ]),
                  ],
                ),

                // --- Thanh tìm kiếm thông minh ---
                _buildSearchBar(),

                // --- Banner cảnh báo vi phạm ---
                _buildViolationBanner(),

                // --- Bottom Sheet danh sách bãi xe ---
                _buildBottomSheet(),

                // --- Nút xóa route nếu đang vẽ ---
                if (_routePoints.isNotEmpty)
                  Positioned(
                    bottom: MediaQuery.of(context).size.height * 0.37 + 56,
                    right: 16,
                    child: FloatingActionButton.small(
                      heroTag: 'clear_route',
                      backgroundColor: AppColors.error,
                      foregroundColor: Colors.white,
                      onPressed: _clearRoute,
                      child: const Icon(Icons.close_rounded),
                    ),
                  ),

                // --- Nút định vị vị trí hiện tại ---
                Positioned(
                  bottom: MediaQuery.of(context).size.height * 0.37,
                  right: 16,
                  child: FloatingActionButton.small(
                    heroTag: 'locate_me',
                    backgroundColor: Colors.white,
                    onPressed: () async {
                      final pos = await LocationService.getCurrentLocation();
                      if (pos != null) {
                        setState(() {
                          _userLocation = pos;
                        });
                        _mapController.move(pos, 15.5);
                      } else if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Không thể lấy vị trí. Hãy bật GPS và cấp quyền!')),
                        );
                      }
                    },
                    child: const Icon(Icons.my_location_rounded, color: AppColors.primaryBlue),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildSearchBar() {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 10,
      left: 16,
      right: 16,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withAlpha(20), blurRadius: 20)],
        ),
        child: Row(
          children: [
            _isSearching
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.search, color: AppColors.textSecondary),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: _searchController,
                decoration: const InputDecoration(
                  hintText: 'Tìm bãi đỗ xe hoặc địa điểm...',
                  border: InputBorder.none,
                  hintStyle: TextStyle(color: AppColors.textLight),
                ),
                textInputAction: TextInputAction.search,
                onChanged: (val) => setState(() => _searchQuery = val),
                onSubmitted: (val) {
                  setState(() => _searchQuery = val);
                  _searchAndFly(val);
                },
              ),
            ),
            // Nút xóa tìm kiếm
            if (_searchQuery.isNotEmpty)
              GestureDetector(
                onTap: () {
                  _searchController.clear();
                  setState(() => _searchQuery = '');
                },
                child: const Icon(Icons.close, color: AppColors.textLight, size: 18),
              ),
            const SizedBox(width: 8),
            // Avatar mở Profile
            GestureDetector(
              onTap: _showProfileSheet,
              child: CircleAvatar(
                radius: 18,
                backgroundColor: AppColors.primaryBlue,
                child: Text(
                  widget.user.fullName.isNotEmpty ? widget.user.fullName[0].toUpperCase() : 'U',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomSheet() {
    return DraggableScrollableSheet(
      initialChildSize: 0.35,
      minChildSize: 0.12,
      maxChildSize: 0.75,
      builder: (context, sc) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 20, offset: Offset(0, -4))],
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.divider, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  _searchQuery.isEmpty ? 'Bãi đỗ gần bạn' : 'Kết quả: "${_searchQuery}"',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                ),
              ),
            ),
            const SizedBox(height: 12),
            _buildTabs(),
            const SizedBox(height: 8),
            Expanded(
              child: _sortedLots.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.search_off_rounded, size: 48, color: AppColors.textLight),
                          const SizedBox(height: 8),
                          Text('Không tìm thấy bãi đỗ xe nào', style: TextStyle(color: AppColors.textSecondary)),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: () async {
                        await _viewModel.loadParkingLots();
                      },
                      color: AppColors.primaryBlue,
                      child: ListView.builder(
                        controller: sc,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _sortedLots.length,
                        itemBuilder: (_, i) => _buildLotCard(_sortedLots[i]),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabs() {
    final tabs = ['Gần tôi', 'Giá thấp nhất', 'Còn nhiều chỗ'];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: List.generate(tabs.length, (i) {
          final sel = _selectedTab == i;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => setState(() => _selectedTab = i),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  gradient: sel ? AppColors.primaryGradient : null,
                  color: sel ? null : AppColors.background,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(tabs[i], style: TextStyle(
                  color: sel ? Colors.white : AppColors.textSecondary,
                  fontSize: 13, fontWeight: FontWeight.w600,
                )),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildLotCard(ParkingLot lot) {
    return GestureDetector(
      onTap: () {
        if (_viewModel.isCustomerLocked) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('⚠️ Tài khoản của bạn đang bị khóa do quá hạn nộp phạt vi phạm!'),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
          return;
        }
        Navigator.push(context, MaterialPageRoute(
          builder: (_) => LotDetailView(lot: lot, userId: widget.user.id, token: widget.user.token, userLocation: _userLocation),
        ));
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.divider.withAlpha(128)),
          boxShadow: [BoxShadow(color: Colors.black.withAlpha(8), blurRadius: 8)],
        ),
        child: Row(
          children: [
            Container(
              width: 64, height: 64,
              decoration: BoxDecoration(gradient: AppColors.primaryGradient, borderRadius: BorderRadius.circular(12)),
              child: const Icon(Icons.local_parking, color: Colors.white, size: 30),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(lot.name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700), maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Text(lot.address, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary), maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 8),
                  Row(children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: lot.occupancyPercent,
                          backgroundColor: AppColors.divider,
                          valueColor: AlwaysStoppedAnimation(lot.occupancyPercent > 0.8 ? AppColors.error : AppColors.success),
                          minHeight: 6,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 60,
                      child: Text(
                        '${lot.availableSlots}/${lot.totalSlots}',
                        textAlign: TextAlign.right,
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                      ),
                    ),
                  ]),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Column(children: [
              Text(lot.pricePerHour.toVnd(),
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.primaryBlue)),
              const Text('/giờ', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(gradient: AppColors.primaryGradient, borderRadius: BorderRadius.circular(8)),
                child: const Text('Đặt ngay', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
              ),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _buildViolationBanner() {
    if (!_showBanner) return const SizedBox.shrink();

    // 1. Ưu tiên hiển thị vi phạm pending (chưa thanh toán)
    if (_viewModel.pendingViolations.isNotEmpty) {
      final v = _viewModel.pendingViolations.first;
      final isWithin = v.isWithinDeadline;
      final mins = v.secondsRemaining ~/ 60;
      final secs = v.secondsRemaining % 60;

      return Positioned(
        top: MediaQuery.of(context).padding.top + 70,
        left: 16,
        right: 16,
        child: GestureDetector(
          onTap: _showViolationsSheet,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isWithin ? Colors.orange.shade900 : AppColors.error,
              borderRadius: BorderRadius.circular(12),
              boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 10)],
            ),
            child: Row(
              children: [
                const Icon(Icons.warning_rounded, color: Colors.white, size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isWithin ? '⚠️ CẢNH BÁO VI PHẠM (Chưa nộp phạt)' : '🚨 TÀI KHOẢN BỊ KHÓA / PHẠT CHẬM',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        isWithin 
                            ? 'Xe ${v.vehiclePlate} (${v.reasonText}) bị phạt ${v.penaltyAmount?.toVnd()}. Hạn nộp: ${mins}p ${secs}s'
                            : 'Bạn đã quá hạn 30 phút nộp phạt vi phạm xe ${v.vehiclePlate}. Vui lòng liên hệ Admin.',
                        style: const TextStyle(color: Colors.white, fontSize: 11),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: const Icon(Icons.close, color: Colors.white, size: 18),
                  onPressed: () => setState(() => _showBanner = false),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // 2. Hiển thị vi phạm resolved đang trong 1 phút penalty mở khóa
    final activePenalties = _viewModel.violations.where((v) => v.isInOneMinutePenalty).toList();
    if (activePenalties.isNotEmpty) {
      final v = activePenalties.first;
      final secs = v.unlockSecondsRemaining;

      return Positioned(
        top: MediaQuery.of(context).padding.top + 70,
        left: 16,
        right: 16,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.blue.shade800,
            borderRadius: BorderRadius.circular(12),
            boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 10)],
          ),
          child: Row(
            children: [
              const Icon(Icons.hourglass_empty_rounded, color: Colors.white, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '⏳ ĐÃ THANH TOÁN - ĐANG KHỞI TẠO LẠI',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Hệ thống đang mở khóa tài khoản của bạn. Vui lòng chờ: ${secs}s.',
                      style: const TextStyle(color: Colors.white, fontSize: 11),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: const Icon(Icons.close, color: Colors.white, size: 18),
                onPressed: () => setState(() => _showBanner = false),
              ),
            ],
          ),
        ),
      );
    }

    return const SizedBox.shrink();
  }

  void _showViolationsSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CustomerViolationsBottomSheet(
        user: widget.user,
        viewModel: _viewModel,
      ),
    );
  }
}

// ============================================================
// Profile BottomSheet cho Customer
// ============================================================
class _ProfileBottomSheet extends StatelessWidget {
  final UserModel user;
  final VoidCallback onLogout;
  final VoidCallback onViewViolations;
  const _ProfileBottomSheet({
    required this.user,
    required this.onLogout,
    required this.onViewViolations,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(25), blurRadius: 20)],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(width: 40, height: 4, margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
          // Avatar
          CircleAvatar(
            radius: 36,
            backgroundColor: AppColors.primaryBlue,
            child: Text(
              user.fullName.isNotEmpty ? user.fullName[0].toUpperCase() : 'U',
              style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w800),
            ),
          ),
          const SizedBox(height: 12),
          Text(user.fullName, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Icon(Icons.email_outlined, size: 14, color: AppColors.textSecondary),
            const SizedBox(width: 4),
            Text(user.email, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
          ]),
          if (user.phone.isNotEmpty) ...[
            const SizedBox(height: 4),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Icon(Icons.phone_outlined, size: 14, color: AppColors.textSecondary),
              const SizedBox(width: 4),
              Text(user.phone, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
            ]),
          ],
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              user.role == 'CUSTOMER' ? '🚗 Khách hàng' : user.role,
              style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(height: 24),
          const Divider(height: 1),
          // Nút Vé đỗ xe của tôi
          ListTile(
            onTap: () {
              Navigator.pop(context); // Đóng Profile BottomSheet
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => MyBookingsView(user: user)),
              );
            },
            leading: Container(
              width: 40, height: 40,
              decoration: BoxDecoration(color: AppColors.primaryBlue.withAlpha(25), borderRadius: BorderRadius.circular(12)),
              child: const Icon(Icons.confirmation_number_rounded, color: AppColors.primaryBlue, size: 20),
            ),
            title: const Text('Vé đỗ xe của tôi', style: TextStyle(fontWeight: FontWeight.w700)),
            subtitle: const Text('Xem danh sách vé & mã QR check-in/out', style: TextStyle(fontSize: 12)),
            trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.textLight),
          ),
          const Divider(height: 1),
          // Nút Lịch sử vi phạm
          ListTile(
            onTap: () {
              Navigator.pop(context); // Đóng Profile BottomSheet
              onViewViolations();
            },
            leading: Container(
              width: 40, height: 40,
              decoration: BoxDecoration(color: AppColors.error.withAlpha(25), borderRadius: BorderRadius.circular(12)),
              child: const Icon(Icons.warning_amber_rounded, color: AppColors.error, size: 20),
            ),
            title: const Text('Lịch sử vi phạm', style: TextStyle(fontWeight: FontWeight.w700)),
            subtitle: const Text('Xem danh sách vi phạm & hạn đóng phạt', style: TextStyle(fontSize: 12)),
            trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.textLight),
          ),
          const Divider(height: 1),
          // Nút Đăng xuất
          ListTile(
            onTap: () {
              Navigator.pop(context);
              onLogout();
            },
            leading: Container(
              width: 40, height: 40,
              decoration: BoxDecoration(color: AppColors.error.withAlpha(25), borderRadius: BorderRadius.circular(12)),
              child: const Icon(Icons.logout_rounded, color: AppColors.error, size: 20),
            ),
            title: const Text('Đăng xuất', style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.error)),
            subtitle: const Text('Thoát khỏi tài khoản hiện tại', style: TextStyle(fontSize: 12)),
            trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.textLight),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

// ============================================================
// BottomSheet xem vi phạm của Customer
// ============================================================
class _CustomerViolationsBottomSheet extends StatelessWidget {
  final UserModel user;
  final ParkingMapViewModel viewModel;
  const _CustomerViolationsBottomSheet({required this.user, required this.viewModel});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: viewModel,
      builder: (context, _) {
        final list = viewModel.violations;
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag handle
              Container(
                width: 40, height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
              ),
              const Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: AppColors.error, size: 28),
                  SizedBox(width: 10),
                  Text('Lịch sử vi phạm của bạn', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                ],
              ),
              const SizedBox(height: 16),
              if (list.isEmpty)
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle_rounded, color: Colors.green, size: 30),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Chúc mừng! Bạn không có lịch sử vi phạm đỗ xe nào trên hệ thống.',
                          style: TextStyle(color: Colors.green.shade900, fontWeight: FontWeight.w600, fontSize: 13),
                        ),
                      )
                    ],
                  ),
                )
              else
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: list.length,
                    itemBuilder: (ctx, i) {
                      final v = list[i];
                      final isPending = v.status == 'pending';
                      final isWithin = v.isWithinDeadline;
                      final mins = v.secondsRemaining ~/ 60;
                      final secs = v.secondsRemaining % 60;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey.shade200),
                          boxShadow: [BoxShadow(color: Colors.black.withAlpha(5), blurRadius: 8)],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Biển số: ${v.vehiclePlate}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: isPending 
                                        ? (isWithin ? Colors.orange.shade100 : Colors.red.shade100) 
                                        : Colors.green.shade100,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    isPending 
                                        ? (isWithin ? 'Chờ thanh toán' : 'Quá hạn / Khóa tài khoản') 
                                        : 'Đã giải quyết',
                                    style: TextStyle(
                                      color: isPending 
                                          ? (isWithin ? Colors.orange.shade900 : Colors.red.shade900) 
                                          : Colors.green.shade900,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 11,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text('Lý do: ${v.reasonText}', style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                            if (v.createdAt != null)
                              Text(
                                'Thời gian: ${v.createdAt!.day}/${v.createdAt!.month}/${v.createdAt!.year} ${v.createdAt!.hour.toString().padLeft(2,'0')}:${v.createdAt!.minute.toString().padLeft(2,'0')}',
                                style: const TextStyle(fontSize: 11, color: AppColors.textLight),
                              ),
                            if (v.penaltyAmount != null) ...[
                              const SizedBox(height: 6),
                              Text(
                                'Tiền phạt: ${v.penaltyAmount!.toVnd()}',
                                style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.error, fontSize: 13),
                              ),
                            ],
                            if (isPending) ...[
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: isWithin ? Colors.amber.shade50 : Colors.red.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      isWithin ? Icons.timer_rounded : Icons.lock_rounded,
                                      color: isWithin ? Colors.amber.shade900 : Colors.red.shade900,
                                      size: 16,
                                    ),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        isWithin 
                                            ? 'Hạn nộp phạt còn lại: ${mins}p ${secs}s (Vui lòng di chuyển xe và gặp Staff đóng phạt)'
                                            : 'TÀI KHOẢN ĐÃ BỊ KHÓA / PHẠT CHẬM (Vui lòng liên hệ quầy Admin để mở khóa)',
                                        style: TextStyle(
                                          color: isWithin ? Colors.amber.shade900 : Colors.red.shade900,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 10),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: () async {
                                    final scaffoldMessenger = ScaffoldMessenger.of(context);
                                    final confirmed = await showDialog<bool>(
                                      context: context,
                                      builder: (ctx) => AlertDialog(
                                        title: const Text('Thanh toán vi phạm'),
                                        content: Text('Bạn có đồng ý thanh toán số tiền ${v.penaltyAmount?.toVnd()} qua ví điện tử/thẻ để giải quyết vi phạm này không?'),
                                        actions: [
                                          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
                                          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Xác nhận')),
                                        ],
                                      ),
                                    );

                                    if (confirmed == true) {
                                      final success = await viewModel.payViolation(v.id ?? 0, user.id);
                                      if (success) {
                                        scaffoldMessenger.showSnackBar(
                                          const SnackBar(content: Text('Thanh toán thành công! Tài khoản sẽ được kích hoạt lại sau 1 phút.'), backgroundColor: Colors.green),
                                        );
                                      } else {
                                        scaffoldMessenger.showSnackBar(
                                          const SnackBar(content: Text('Thanh toán thất bại, vui lòng thử lại!'), backgroundColor: AppColors.error),
                                        );
                                      }
                                    }
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.orange.shade900,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    padding: const EdgeInsets.symmetric(vertical: 10),
                                  ),
                                  icon: const Icon(Icons.payment_rounded, size: 16),
                                  label: const Text('Nộp phạt ngay (Momo/Thẻ)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                ),
                              ),
                            ],
                            if (v.imageUrl != null && v.imageUrl!.isNotEmpty) ...[
                              const SizedBox(height: 10),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  v.imageUrl!,
                                  height: 120,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Container(
                                    height: 50,
                                    color: Colors.grey.shade100,
                                    child: const Center(child: Icon(Icons.broken_image_outlined, color: AppColors.textLight)),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      );
                    },
                  ),
                ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryBlue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text('Đóng', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }
}