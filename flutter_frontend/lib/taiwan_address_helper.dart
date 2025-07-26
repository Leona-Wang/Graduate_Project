//中文地址轉換器
//ver1.0 可以轉換縣市中文

import 'package:latlong2/latlong.dart';
import 'package:geocoding/geocoding.dart';

class TaiwanAddressHelper {
  static const Map<String, String> _cityNameMap = {
    "Taipei City": "台北市",
    "New Taipei City": "新北市",
    "Taoyuan City": "桃園市",
    "Taichung City": "台中市",
    "Tainan City": "台南市",
    "Kaohsiung City": "高雄市",
    "Keelung City": "基隆市",
    "Hsinchu City": "新竹市",
    "Chiayi City": "嘉義市",
    "Hsinchu County": "新竹縣",
    "Miaoli County": "苗栗縣",
    "Changhua County": "彰化縣",
    "Nantou County": "南投縣",
    "Yunlin County": "雲林縣",
    "Chiayi County": "嘉義縣",
    "Pingtung County": "屏東縣",
    "Yilan County": "宜蘭縣",
    "Hualien County": "花蓮縣",
    "Taitung County": "台東縣",
    "Penghu County": "澎湖縣",
    "Kinmen County": "金門縣",
    "Lienchiang County": "連江縣",
  };

  // 從座標取得市/縣（轉成中文）
  static Future<String> getCityFromCoordinates(LatLng latlng) async {
    final placemarks = await placemarkFromCoordinates(
      latlng.latitude,
      latlng.longitude,
    );
    final englishName = placemarks.first.administrativeArea ?? '';
    return _cityNameMap[englishName] ?? englishName;
  }

  // 從座標取得完整地址資訊（含市、區、街）
  static Future<Map<String, String>> getFullAddressParts(LatLng latlng) async {
    final placemarks = await placemarkFromCoordinates(
      latlng.latitude,
      latlng.longitude,
    );
    final place = placemarks.first;
    return {
      'city':
          _cityNameMap[place.administrativeArea ?? ''] ??
          (place.administrativeArea ?? ''),
      'district': place.subAdministrativeArea ?? '',
      'street': place.street ?? '',
    };
  }
}
