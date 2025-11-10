//因為很懶一個個設定地圖地址格式所以直接弄了一個函式
//ver1.0 這是一個會拿到完整地址字串的功能(英文)

//ver1.1 將組合地址功能轉移至taiwan_address_helper，這裡改成方便呼叫與重組的功能函式

import 'package:geocoding/geocoding.dart';
import 'package:flutter_frontend/taiwan_address_helper.dart';

/// 將 geocoding Placemark 轉為較完整的中文地址。
String formatPlacemark(Placemark place, {String separator = ''}) {
  return TaiwanAddressHelper.formatFromPlacemark(place, separator: separator);
}
