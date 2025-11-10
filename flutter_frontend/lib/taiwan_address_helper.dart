//中文地址轉換器
//ver1.0 可以轉換縣市中文
//ver1.1 可以轉換縣市、區、鄉鎮市中文，並組合完整中文地址

import 'package:latlong2/latlong.dart';
import 'package:geocoding/geocoding.dart';

class TaiwanAddressHelper {
  //縣市
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

  //縣市行政區
  static const Map<String, String> _districtNameMap = {
    // 台北市各區
    "Zhongzheng District": "中正區",
    "Datong District": "大同區",
    "Zhongshan District": "中山區",
    "Songshan District": "松山區",
    "Da’an District": "大安區",
    "Daan District": "大安區", // 有時候少了 '
    "Wanhua District": "萬華區",
    "Xinyi District": "信義區",
    "Shilin District": "士林區",
    "Beitou District": "北投區",
    "Neihu District": "內湖區",
    "Nangang District": "南港區",
    "Wenshan District": "文山區",

    // 新北市常見區
    "Banqiao District": "板橋區",
    "Xinzhuang District": "新莊區",
    "Luzhou District": "蘆洲區",
    "Sanchong District": "三重區",
    "Yonghe District": "永和區",
    "Zhonghe District": "中和區",
    "Tucheng District": "土城區",
    "Xindian District": "新店區",
    "Tamsui District": "淡水區",
    "Xizhi District": "汐止區",
    "Shulin District": "樹林區",
    "Sanxia District": "三峽區",
    "Yingge District": "鶯歌區",

    // 台中市常見區
    "Xitun District": "西屯區",
    "Beitun District": "北屯區",
    "Nantun District": "南屯區",
    "Central District": "中區",
    "East District": "東區",
    "West District": "西區",
    "South District": "南區",
    "North District": "北區",
  };

  // 從座標取得市/縣（轉成中文）
  static Future<String> getCityFromCoordinates(LatLng latlng) async {
    final placemarks = await placemarkFromCoordinates(
      latlng.latitude,
      latlng.longitude,
    );
    final place = placemarks.first;
    final englishName = place.administrativeArea ?? '';
    return _cityNameMap[englishName] ?? englishName;
  }

  // 從座標取得「區 / 鄉鎮市」（轉成中文）
  static Future<String> getDistrictFromCoordinates(LatLng latlng) async {
    final placemarks = await placemarkFromCoordinates(
      latlng.latitude,
      latlng.longitude,
    );
    final place = placemarks.first;

    // geocoding 在台灣常見的情況：
    // administrativeArea: Taipei City / New Taipei City...
    // locality 或 subAdministrativeArea: Wenshan District / Banqiao District...
    final englishDistrict =
        place.subAdministrativeArea?.isNotEmpty == true
            ? place.subAdministrativeArea!
            : (place.locality ?? '');

    return _districtNameMap[englishDistrict] ?? englishDistrict;
  }

  // 從座標取得完整地址資訊（含市、區、街）
  static Future<Map<String, String>> getFullAddressParts(LatLng latlng) async {
    final placemarks = await placemarkFromCoordinates(
      latlng.latitude,
      latlng.longitude,
    );
    final place = placemarks.first;

    final englishCity = place.administrativeArea ?? '';
    final englishDistrict =
        place.subAdministrativeArea?.isNotEmpty == true
            ? place.subAdministrativeArea!
            : (place.locality ?? '');

    final city = _cityNameMap[englishCity] ?? englishCity; // 台北市 / 新北市...
    final district =
        _districtNameMap[englishDistrict] ?? englishDistrict; // 文山區 / 板橋區...

    // geocoding 的欄位可能會有：
    // street: 路 + 巷 + 弄 + 號（有時候附帶里）
    // thoroughfare: 路名
    final street = (place.street?.isNotEmpty == true ? place.street : '') ?? '';
    final postalCode = place.postalCode ?? '';

    return {
      'city': city,
      'district': district,
      'street': street,
      'postalCode': postalCode,
      // 方便你直接顯示用的組合版
      'full': '$city$district$street',
    };
  }

  // 直接從座標拿「完整中文地址字串」
  static Future<String> getFullChineseAddress(LatLng latlng) async {
    final parts = await getFullAddressParts(latlng);
    return parts['full'] ?? '';
  }
}
