import 'package:flutter/material.dart';
import 'package:flutter_frontend/formatPlacemark.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:latlong2/latlong.dart';

class CharityMapPage extends StatefulWidget {
  final LatLng? initialLatLng;
  final String? initialAddress;
  const CharityMapPage({super.key, this.initialLatLng, this.initialAddress});

  @override
  State<CharityMapPage> createState() => CharityMapState();
}

class CharityMapState extends State<CharityMapPage> {
  late MapController _mapController;
  LatLng? _selectedLatLng;
  final TextEditingController _addressController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _mapController = MapController();

    if (widget.initialLatLng != null) {
      _updateLocation(widget.initialLatLng!, skipReverseGeocoding: true);
      _addressController.text = widget.initialAddress ?? "";
    } else {
      _getCurrentLocation();
    }
  }

  //使用者定位
  void _getCurrentLocation() async {
    LocationPermission permission = await Geolocator.checkPermission();

    //確認是否有開啟權限
    if (permission == LocationPermission.denied) {
      //要求權限
      permission = await Geolocator.requestPermission();
      //使用者拒絕開啟權限
      if (permission == LocationPermission.denied) {
        _setDefaultLocation();
        return;
      }
    }

    //使用者永久拒絕定位權限
    if (permission == LocationPermission.deniedForever) {
      _setDefaultLocation();
      return;
    }

    try {
      final position = await Geolocator.getCurrentPosition();
      _updateLocation(LatLng(position.latitude, position.longitude));
      _mapController.move(_selectedLatLng!, 20);
    } catch (_) {
      print('定位失敗'); //抓蟲用
      _setDefaultLocation();
    }
  }

  //預設定位，暫定政大商院
  void _setDefaultLocation() {
    _updateLocation(const LatLng(24.98750, 121.57639)); //政大商院

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('未授權定位，將設定為預設位址')));
  }

  //地圖位置+輸入欄資訊動態更新+放置圖標
  void _updateLocation(
    LatLng latlng, {
    bool skipReverseGeocoding = false,
  }) async {
    setState(() {
      _selectedLatLng = latlng;
    });

    if (skipReverseGeocoding) return;

    try {
      final placesmark = await placemarkFromCoordinates(
        latlng.latitude,
        latlng.longitude,
      );
      final place = placesmark.first;
      _addressController.text = formatPlacemark(place, separator: '');
    } catch (e) {
      _addressController.text = '無法取得地址';
    }
  }

  //使用者搜尋地址後定位
  void _searchAddress() async {
    final query = _addressController.text;
    if (query.isEmpty) return;

    final locations = await locationFromAddress(query);
    if (locations.isNotEmpty) {
      final loc = locations.first;
      _updateLocation(LatLng(loc.latitude, loc.longitude));
      _mapController.move(_selectedLatLng!, 20);
    }
  }

  void _confirm() async {
    if (_selectedLatLng == null) return;

    Navigator.pop(context, {
      'lat': _selectedLatLng!.latitude,
      'lng': _selectedLatLng!.longitude,
      'address': _addressController.text,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('選擇地點')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _addressController,
              onSubmitted: (_) => _searchAddress(),
              decoration: InputDecoration(
                labelText: '輸入地址',
                border: OutlineInputBorder(),
                suffixIcon: IconButton(
                  onPressed: _searchAddress,
                  icon: const Icon(Icons.search),
                ),
              ),
            ),
          ),
          Expanded(
            child:
                _selectedLatLng == null
                    ? const Center(child: CircularProgressIndicator())
                    : FlutterMap(
                      mapController: _mapController,
                      options: MapOptions(
                        initialCenter: _selectedLatLng!,
                        initialZoom: 20,
                        onPositionChanged: (position, hasGesture) {
                          if (hasGesture) {
                            _updateLocation(position.center!);
                          }
                        },
                      ),
                      children: [
                        TileLayer(
                          urlTemplate:
                              'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          userAgentPackageName: 'com.example.flutter_frontend',
                        ),
                        MarkerLayer(
                          markers: [
                            Marker(
                              point: _selectedLatLng!,
                              width: 50,
                              height: 50,
                              child: const Icon(
                                Icons.location_pin,
                                color: Colors.amber,
                                size: 50,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
          ),
          ElevatedButton(onPressed: _confirm, child: const Text('確認地點')),
        ],
      ),
    );
  }
}
