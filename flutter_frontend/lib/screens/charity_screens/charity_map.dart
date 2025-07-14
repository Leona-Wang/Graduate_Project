import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class CharityMapPage extends StatelessWidget {
  const CharityMapPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('地圖')), //之後返回鍵改為回到首頁，避免堆疊太多子頁面
      body: FlutterMap(
        options: MapOptions(
          initialCenter: LatLng(24.98750, 121.57639), //中心位置，改為使用者定位or組織地址
          initialZoom: 18.0,
        ),
        children: [
          //顯示地圖圖磚，預設使用OpenStreetMap
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            subdomains: const ['a', 'b', 'c'],
            userAgentPackageName: 'com.example.flutter_frontend', //注意這個名字要打對!
          ),
          //放置地圖標記
          MarkerLayer(
            markers: [
              Marker(
                width: 80.0,
                height: 80.0,
                point: LatLng(24.98750, 121.57639),
                child: const Icon(
                  Icons.location_pin,
                  color: Colors.amber,
                  size: 40,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
