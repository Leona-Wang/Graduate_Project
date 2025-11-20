import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_frontend/screens/personal_screens/personal_event_detail_page.dart';
import 'dart:ui' as ui;
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_frontend/config.dart';
import 'package:flutter_frontend/screens/personal_screens/personal_event_list.dart';
import 'package:flutter_frontend/screens/personal_screens/personal_home_tab.dart';
import '../../api_client.dart';
import 'dart:convert';

import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

import 'package:google_fonts/google_fonts.dart';

class PersonalMapPage extends StatefulWidget {
  const PersonalMapPage({super.key});

  @override
  State<PersonalMapPage> createState() => PersonalMapPageState();
}

//圖標用
class EventPin {
  final int id;
  final String title;
  final String type;
  final String location;
  final DateTime date;
  final bool online;
  final LatLng loc;
  EventPin({
    required this.id,
    required this.title,
    required this.type,
    required this.location,
    required this.date,
    required this.online,
    required this.loc,
  });
}

class PersonalMapPageState extends State<PersonalMapPage> {
  final MapController _mapController = MapController();
  LatLng? _currentLocation; //使用者當前座標

  List<Marker> markers = [];
  final List<EventPin> _events = [];

  double _zoom = 14.0; //地圖縮放變數

  EventPin? selected; //被選中的marker

  @override
  void initState() {
    super.initState();
    fetchEvents();
    getUserLocation();
  }

  //取得使用者定位
  void getUserLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      debugPrint("定位服務未開啟");
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        debugPrint("使用者拒絕定位權限");
        return;
      }
    }
    if (permission == LocationPermission.deniedForever) {
      debugPrint("使用者永久拒絕定位權限");
      return;
    }

    try {
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
        timeLimit: const Duration(seconds: 5),
      );

      setState(() {
        _currentLocation = LatLng(pos.latitude, pos.longitude);
      });
    } on TimeoutException {
      debugPrint("定位超時，改用預設位置");
      setState(() {
        _currentLocation = const LatLng(24.98750, 121.57639);
      });
    } catch (e) {
      debugPrint("定位失敗: $e");
    }
  }

  //呼叫API獲取活動，轉換成地標點
  Future<void> fetchEvents() async {
    final uriEvent = Uri.parse(ApiPath.charityEventList);

    try {
      final apiClient = ApiClient();
      await apiClient.init();
      final response = await apiClient.get(uriEvent.toString());

      //debugPrint('活動列表狀態碼: ${response.statusCode}');
      //debugPrint('活動列表回傳內容: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        final List<dynamic> events = data['events'] ?? [];

        final List<EventPin> pins = [];

        for (var e in events) {
          final id = e['id'] as int;
          final title = e['name'] ?? '未命名任務';
          final type = e['eventType'] ?? '';
          final location = e['address'] ?? '';
          final date = DateTime.parse(e['startTime']);
          final online = e['online'] ?? false;

          final loc = await getLatLngFromAddress(location);

          if (loc != null) {
            pins.add(
              EventPin(
                id: id,
                title: title,
                type: type,
                location: location,
                date: date,
                online: online,
                loc: loc,
              ),
            );
          }
        }

        final List<Marker> mks =
            pins.map((p) {
              return Marker(
                width: 60,
                height: 60,
                point: p.loc,
                child: GestureDetector(
                  onTap: () => onMarkerTap(p),
                  child: const Icon(
                    Icons.location_on_rounded,
                    color: Color(0xFFd4a373),
                    size: 40,
                  ),
                ),
              );
            }).toList();

        if (!mounted) return;
        setState(() {
          _events
            ..clear()
            ..addAll(pins);
          markers = mks;
        });
      }
    } catch (e) {
      debugPrint('取得活動失敗: $e');
    }
  }

  //點擊卡片
  void onMarkerTap(EventPin pin) {
    //再次點擊
    if (selected != null && selected!.id == pin.id) {
      goToDetail(pin);
      return;
    }

    //初次點擊
    final double targetZoom = (_zoom < 16.0 ? 16.0 : _zoom).clamp(3.0, 18.0);
    setState(() {
      selected = pin;
      _zoom = targetZoom;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _mapController.move(pin.loc, targetZoom);
    });
  }

  //地址轉座標
  Future<LatLng?> getLatLngFromAddress(String address) async {
    try {
      final locations = await locationFromAddress(address);
      if (locations.isNotEmpty) {
        return LatLng(locations.first.latitude, locations.first.longitude);
      }
    } catch (e) {
      debugPrint('地址轉換失敗: $e');
    }
    return null;
  }

  //一鍵回到定位點
  void goToCurrentLoc() {
    if (_currentLocation == null) return;

    const double tergetZoom = 14;
    setState(() {
      _zoom = tergetZoom;
    });

    _mapController.move(_currentLocation!, _zoom);
  }

  void backToHome() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => const PersonalHomeTab()));
  }

  void goToDetail(EventPin pin) {
    final event = Event(
      id: pin.id,
      title: pin.title,
      type: pin.type,
      location: pin.location,
      date: pin.date,
      online: pin.online,
    );
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => PersonalEventDetailPage(event: event),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFf8f5f0),
      appBar: AppBar(
        title: Text(
          '活動地圖',
          style: GoogleFonts.notoSerifTc(
            // 中文用 Noto Serif TC
            textStyle: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: Color(0xFF4b3832),
              letterSpacing: 0.5,
            ),
          ),
        ),
        backgroundColor: const Color(0xFFe6ccb2),
        elevation: 4,
      ),
      body:
          _currentLocation == null
              ? const Center(child: CircularProgressIndicator())
              : Stack(
                children: [
                  FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(center: _currentLocation, zoom: _zoom),
                    children: [
                      TileLayer(
                        urlTemplate:
                            'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                        //subdomains: const ['a', 'b', 'c'],
                        userAgentPackageName: 'com.example.flutter_frontend',
                      ),
                      MarkerLayer(
                        markers: [
                          if (_currentLocation != null)
                            Marker(
                              width: 60,
                              height: 60,
                              point: _currentLocation!,
                              child: const Icon(
                                Icons.person_pin_circle_rounded,
                                color: Color.fromARGB(255, 46, 95, 136),
                                size: 40,
                              ),
                            ),
                          ...markers,
                        ],
                      ),
                      if (selected != null)
                        MarkerLayer(
                          markers: [
                            Marker(
                              point: selected!.loc,
                              width:
                                  MediaQuery.of(context).size.width *
                                  0.8, // 卡片寬度
                              height: 160, // 預留高度
                              alignment:
                                  Alignment.bottomCenter, // 讓 child 的底對準座標
                              child: Transform.translate(
                                // 固定上移 36px（可再調整）
                                offset: const Offset(0, -120),
                                child: _PopupAboveMarker(
                                  title: selected!.title,
                                  subtitle: selected!.location,
                                  onClose:
                                      () => setState(() => selected = null),
                                  onTap: () => goToDetail(selected!),
                                ),
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),

                  //放大縮小按鈕
                  Positioned(
                    right: 16,
                    bottom: 16,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _roundButton(Icons.add, () {
                          setState(() {
                            _zoom = (_zoom + 1).clamp(3.0, 18.0);
                            _mapController.move(_mapController.center, _zoom);
                          });
                        }),
                        const SizedBox(height: 8),
                        _roundButton(Icons.remove, () {
                          setState(() {
                            _zoom = (_zoom - 1).clamp(3.0, 18.0);
                            _mapController.move(_mapController.center, _zoom);
                          });
                        }),
                        const SizedBox(height: 12),
                        _roundButton(Icons.my_location, goToCurrentLoc),
                      ],
                    ),
                  ),
                ],
              ),
    );
  }

  Widget _roundButton(IconData icon, VoidCallback onTap) {
    return FloatingActionButton(
      heroTag: icon.codePoint,
      backgroundColor: const Color(0xFFe6ccb2),
      mini: true,
      onPressed: onTap,
      child: Icon(icon, color: const Color(0xFF5b4636)),
    );
  }
}

class _PopupAboveMarker extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback onClose;
  final VoidCallback onTap;

  const _PopupAboveMarker({
    required this.title,
    required this.subtitle,
    required this.onClose,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 上方的資訊卡片
        Material(
          elevation: 10,
          borderRadius: BorderRadius.circular(18),
          color: const Color(0xFFfef9f2),
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 6, 12),
              child: Row(
                children: [
                  const Icon(
                    Icons.menu_book_rounded,
                    size: 44,
                    color: Color(0xFFd4a373),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: GoogleFonts.notoSerifTc(
                            textStyle: const TextStyle(
                              fontSize: 19,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF3e2e25),
                              letterSpacing: 0.2,
                            ),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          subtitle,
                          style: GoogleFonts.notoSerifTc(
                            textStyle: const TextStyle(
                              fontSize: 15.5,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF5c4f46),
                              height: 1.25,
                            ),
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Color(0xFFb08968)),
                    onPressed: onClose,
                  ),
                ],
              ),
            ),
          ),
        ),
        // 卡片下方的小三角，指向地標
        const _BubblePointer(
          color: Color(0xFFfef9f2),
          borderColor: Color(0xFFfef9f2),
        ),
        const SizedBox(height: 8), // 卡片底到座標點的距離（調整卡片與圖標的垂直間隙）
      ],
    );
  }
}

class _BubblePointer extends StatelessWidget {
  final Color color;
  final Color borderColor;
  const _BubblePointer({required this.color, required this.borderColor});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 18,
      height: 10,
      child: CustomPaint(
        painter: _TrianglePainter(color: color, borderColor: borderColor),
      ),
    );
  }
}

class _TrianglePainter extends CustomPainter {
  final Color color;
  final Color borderColor;
  _TrianglePainter({required this.color, required this.borderColor});

  @override
  void paint(Canvas canvas, Size size) {
    final path =
        ui.Path()
          ..moveTo(0.0, 0)
          ..lineTo(size.width / 2, size.height)
          ..lineTo(size.width, 0)
          ..close();

    // 邊框
    final border =
        Paint()
          ..color = borderColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2;
    canvas.drawPath(path, border);

    // 內填色
    final fill =
        Paint()
          ..color = color
          ..style = PaintingStyle.fill;
    // 稍微往上填，避免和邊框有縫
    final inner =
        ui.Path()
          ..moveTo(1, 1)
          ..lineTo(size.width / 2, size.height - 1)
          ..lineTo(size.width - 1, 1)
          ..close();
    canvas.drawPath(inner, fill);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
