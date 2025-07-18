import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:latlong2/latlong.dart';

class CharityMapPage extends StatefulWidget {
  const CharityMapPage({super.key});

  @override
  State<CharityMapPage> createState() => CharityMapState();
}

class CharityMapState extends State<CharityMapPage> {
  late MapController _mapController;
  LatLng? _selectedLatLng;
  TextEditingController _addressController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _getCurrentLocation();
  }

  //使用者定位
  void _getCurrentLocation() async {
    final position = await Geolocator.getCurrentPosition();
    setState(() {
      _selectedLatLng = LatLng(position.latitude, position.longitude);
    });
    _mapController.move(_selectedLatLng!, 15);
  }

  //使用者搜尋地址後定位
  void _searchAddress() async {
    final query = _addressController.text;
    if (query.isEmpty) return;

    final locations = await locationFromAddress(query);
    if (locations.isNotEmpty) {
      final loc = locations.first;
      setState(() {
        _selectedLatLng = LatLng(loc.latitude, loc.longitude);
      });
      _mapController.move(_selectedLatLng!, 15);
    }
  }

  void _confirm() async {
    if (_selectedLatLng == null) return;

    final placemarks = await placemarkFromCoordinates(
      _selectedLatLng!.latitude,
      _selectedLatLng!.longitude,
    );

    final address = placemarks.first.street ?? '未命名地點';

    Navigator.pop(context, {
      'lat': _selectedLatLng!.latitude,
      'lng': _selectedLatLng!.longitude,
      'address': address,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('選擇地點')), //之後返回鍵改為回到首頁，避免堆疊太多子頁面
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _addressController,
              onSubmitted: (_) => _searchAddress(),
              decoration: InputDecoration(
                labelText: '輸入地址',
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
                        initialZoom: 15,
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
