//因為很懶一個個設定地圖地址格式所以直接弄了一個函式

import 'package:geocoding/geocoding.dart';

String formatPlacemark(Placemark place, {String separator = ''}) {
  return [
        place.administrativeArea, //縣市
        place.subAdministrativeArea, //區
        place.locality, //里or區
        place.street, //街道
        place.name, //街道or建築物名稱
      ]
      .where((e) => e != null && e.trim().isNotEmpty)
      .toSet() //移除多餘名稱
      .join(separator); //間隔
}
