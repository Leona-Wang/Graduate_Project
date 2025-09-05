import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_frontend/config.dart';
import 'package:flutter_frontend/screens/personal_screens/personal_event_list.dart';
import 'package:flutter_frontend/screens/personal_screens/personal_home_tab.dart';
import '../../api_client.dart';
import 'dart:convert';

import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class PersonalMapPage extends StatefulWidget {
  const PersonalMapPage({super.key});

  @override
  State<PersonalMapPage> createState() => PersonalMapPageState();
}

class PersonalMapPageState extends State<PersonalMapPage> {
  final MapController _mapController = MapController();
  LatLng? _currentLocation; //使用者當前座標
  List<dynamic> markers = [];

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

  /*
  //呼叫API獲取活動，轉換成地標點
  Future<void> fetchEvents() async {
    final uriEvent = Uri.parse(ApiPath.charityEventList); //待確認

    //待API確認後新增內容
    try {
      final apiClient = ApiClient();
      await apiClient.init();
      final response = await apiClient.get(uriEvent.toString());

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        List<Marker> newMarkers = [];

        for (var event in data) {
          final address = event['address'] ?? '';
          final name = event['name'] ?? '任務';

          final latLng = await getLatLngFromAddress(address);
          if (latLng != null) {
            newMarkers.add(
              Marker(
                width: 60,
                height: 60,
                point: latLng,
                child: GestureDetector(
                  onTap: () => toEventList(),
                  child: Tooltip(
                    message: name,
                    child: const Icon(
                      Icons.location_on_rounded,
                      color: Colors.amber,
                      size: 40,
                    ),
                  ),
                ),
              ),
            );
          }
        }

        setState(() {
          markers = newMarkers;
        });
      }
    } catch (e) {
      debugPrint('取得活動失敗: $e');
    }
  }
*/

  //測試用假資料
  Future<void> fetchEvents() async {
    try {
      // 📌 測試用假資料 (模擬 API 回傳的 JSON 陣列)
      final data = [
        {
          "id": 1,
          "name": "台北公益活動",
          "address": "台北市中正區忠孝西路一段49號", // 台北車站
        },
        {"id": 2, "name": "消滅Google總部", "address": "美國加州聖塔克拉拉郡的山景城圓形劇場園道"},
        {
          "id": 3,
          "name": "高雄助學市集",
          "address": "高雄市苓雅區四維三路2號", // 高雄市政府
        },
      ];

      List<Marker> newMarkers = [];

      for (var event in data) {
        final address = event['address'] ?? '';
        final name = event['name'] ?? '任務';

        final latLng = await getLatLngFromAddress(address.toString());
        if (latLng != null) {
          newMarkers.add(
            Marker(
              width: 60,
              height: 60,
              point: latLng,
              child: GestureDetector(
                onTap: () => toEventList(),
                child: Tooltip(
                  message: name.toString(),
                  child: const Icon(
                    Icons.location_on_rounded,
                    color: Colors.amber,
                    size: 40,
                  ),
                ),
              ),
            ),
          );
        }
      }

      setState(() {
        markers = newMarkers;
      });
    } catch (e) {
      debugPrint('取得活動失敗: $e');
    }
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

  void backToHome() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => const PersonalHomeTab()));
  }

  void toEventList() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const PersonalEventListPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        /*leading: Padding(
          padding: const EdgeInsets.only(left: 12.0, top: 6.0, bottom: 6.0),
          child: CircleAvatar(
            backgroundColor: Colors.amberAccent,
            child: IconButton(
              onPressed: backToHome,
              icon: const Icon(Icons.arrow_back_ios_new, color: Colors.brown),
              tooltip: '返回主頁',
            ),
          ),
        ),*/
        title: const Text('活動地圖'),
      ),
      body:
          _currentLocation == null
              ? const Center(child: CircularProgressIndicator())
              : FlutterMap(
                mapController: _mapController,
                options: MapOptions(center: _currentLocation, zoom: 14),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                    subdomains: const ['a', 'b', 'c'],
                    userAgentPackageName: 'com.example.flutter_frontend',
                  ),
                  MarkerLayer(
                    markers: [
                      //使用者位置
                      if (_currentLocation != null)
                        Marker(
                          width: 60,
                          height: 60,
                          point: _currentLocation!,
                          child: const Icon(
                            Icons.person_pin_circle_rounded,
                            color: Colors.blue,
                            size: 40,
                          ),
                        ),
                      //活動位置
                      ...markers,
                    ],
                  ),
                ],
              ),
    );
  }
}
