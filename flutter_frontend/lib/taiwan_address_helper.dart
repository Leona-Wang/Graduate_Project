//中文地址轉換器
//ver1.0 可以轉換縣市中文
//ver1.1 可以轉換縣市、區、鄉鎮市中文，並組合完整中文地址
//ver2.0 版本新增:公開轉換方法+街道正規化+直接由Placemark組合中文地址

import 'package:latlong2/latlong.dart';
import 'package:geocoding/geocoding.dart';

class TaiwanAddressHelper {
  //資料區

  //縣市
  static const Map<String, String> _cityNameMap = {
    "Taipei City": "台北市",
    "New Taipei City": "新北市",
    "Taoyuan City": "桃園市",
    "Taichung City": "台中市",
    "Tainan City": "臺南市",
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
    // ==================== 台北市 ====================
    "Zhongzheng District": "中正區",
    "Datong District": "大同區",
    "Zhongshan District": "中山區",
    "Songshan District": "松山區",
    "Da’an District": "大安區",
    "Daan District": "大安區",
    "Wanhua District": "萬華區",
    "Xinyi District": "信義區",
    "Shilin District": "士林區",
    "Beitou District": "北投區",
    "Neihu District": "內湖區",
    "Nangang District": "南港區",
    "Wenshan District": "文山區",

    // ==================== 新北市 ====================
    "Banqiao District": "板橋區",
    "Sanchong District": "三重區",
    "Zhonghe District": "中和區",
    "Yonghe District": "永和區",
    "Xinzhuang District": "新莊區",
    "Xindian District": "新店區",
    "Tucheng District": "土城區",
    "Luzhou District": "蘆洲區",
    "Xizhi District": "汐止區",
    "Sanxia District": "三峽區",
    "Yingge District": "鶯歌區",
    "Shulin District": "樹林區",
    "Tamsui District": "淡水區",
    "Ruifang District": "瑞芳區",
    "Wugu District": "五股區",
    "Bali District": "八里區",
    "Linkou District": "林口區",
    "Shenkeng District": "深坑區",
    "Shiding District": "石碇區",
    "Pinglin District": "坪林區",
    "Pingxi District": "平溪區",
    "Shuangxi District": "雙溪區",
    "Gongliao District": "貢寮區",
    "Jinshan District": "金山區",
    "Wanli District": "萬里區",
    "Ulay District": "烏來區",

    // ==================== 桃園市 ====================
    "Taoyuan District": "桃園區",
    "Zhongli District": "中壢區",
    "Pingzhen District": "平鎮區",
    "Bade District": "八德區",
    "Yangmei District": "楊梅區",
    "Luzhu District": "蘆竹區",
    "Guishan District": "龜山區",
    "Longtan District": "龍潭區",
    "Daxi District": "大溪區",
    "Dayuan District": "大園區",
    "Xinwu District": "新屋區",
    "Guanyin District": "觀音區",
    "Fuxing District": "復興區",

    // ==================== 台中市 ====================
    "Central District": "中區",
    "East District": "東區",
    "South District": "南區",
    "West District": "西區",
    "North District": "北區",
    "Xitun District": "西屯區",
    "Nantun District": "南屯區",
    "Beitun District": "北屯區",
    "Fengyuan District": "豐原區",
    "Dongshi District": "東勢區",
    "Shigang District": "石岡區",
    "Heping District": "和平區",
    "Xinshe District": "新社區",
    "Tanzi District": "潭子區",
    "Daya District": "大雅區",
    "Shengang District": "神岡區",
    "Dajia District": "大甲區",
    "Waipu District": "外埔區",
    //"Da’an District": "大安區",//名稱與台北市的相同
    "Qingshui District": "清水區",
    "Shalu District": "沙鹿區",
    "Longjing District": "龍井區",
    "Wuqi District": "梧棲區",
    "Dadu District": "大肚區",
    "Wuri District": "烏日區",
    "Dali District": "大里區",
    "Wufeng District": "霧峰區",

    // ==================== 台南市 ====================
    "West Central District": "中西區",
    "East District (Tainan)": "東區",
    "South District (Tainan)": "南區",
    "North District (Tainan)": "北區",
    "Anping District": "安平區",
    "Annan District": "安南區",
    "Yongkang District": "永康區",
    "Guiren District": "歸仁區",
    "Guanmiao District": "關廟區",
    "Longqi District": "龍崎區",
    "Xinhua District": "新化區",
    "Zuozhen District": "左鎮區",
    "Yujing District": "玉井區",
    "Nanxi District": "楠西區",
    "Nanhua District": "南化區",
    "Rende District": "仁德區",
    "Guantian District": "官田區",
    "Madou District": "麻豆區",
    "Jiali District": "佳里區",
    "Xuejia District": "學甲區",
    "Beimen District": "北門區",
    "Xigang District": "西港區",
    "Qigu District": "七股區",
    "Jiangjun District": "將軍區",
    "Liuying District": "柳營區",
    "Liujia District": "六甲區",
    "Dongshan District": "東山區",
    "Shanhua District": "善化區",
    "Danei District": "大內區",

    // ==================== 高雄市 ====================
    "Xinxing District": "新興區",
    "Qianjin District": "前金區",
    "Lingya District": "苓雅區",
    "Yancheng District": "鹽埕區",
    "Gushan District": "鼓山區",
    "Qianzhen District": "前鎮區",
    "Sanmin District": "三民區",
    "Nanzi District": "楠梓區",
    "Xiaogang District": "小港區",
    "Zuoying District": "左營區",
    "Renwu District": "仁武區",
    "Dashe District": "大社區",
    "Gangshan District": "岡山區",
    "Luzhu District (Kaohsiung)": "路竹區",
    "Alian District": "阿蓮區",
    "Tianliao District": "田寮區",
    "Yanchao District": "燕巢區",
    "Qiaotou District": "橋頭區",
    "Ziguan District": "梓官區",
    "Mituo District": "彌陀區",
    "Yong’an District": "永安區",
    "Hunei District": "湖內區",
    "Fengshan District": "鳳山區",
    "Daliao District": "大寮區",
    "Linyuan District": "林園區",
    "Niaosong District": "鳥松區",
    "Dashu District": "大樹區",
    "Qishan District": "旗山區",
    "Meinong District": "美濃區",
    "Liugui District": "六龜區",
    "Jiaxian District": "甲仙區",
    "Shanlin District": "杉林區",
    "Neimen District": "內門區",
    "Maolin District": "茂林區",
    "Taoyuan District (Kaohsiung)": "桃源區",

    // ==================== 其他縣市常見 ====================
    // 基隆市
    "Ren’ai District": "仁愛區",
    "Xinyi District (Keelung)": "信義區",
    "Zhongzheng District (Keelung)": "中正區",
    "Zhongshan District (Keelung)": "中山區",
    "Anle District": "安樂區",
    "Nuannuan District": "暖暖區",
    "Qidu District": "七堵區",

    // 新竹市 / 縣
    "East District (Hsinchu)": "東區",
    "North District (Hsinchu)": "北區",
    "Xiangshan District": "香山區",
    "Zhubei City": "竹北市",
    "Hukou Township": "湖口鄉",
    "Xinfeng Township": "新豐鄉",
    "Xinpu Township": "新埔鎮",

    // 苗栗縣
    "Miaoli City": "苗栗市",
    "Toufen City": "頭份市",
    "Zhunan Township": "竹南鎮",
    "Gongguan Township": "公館鄉",
    "Tongluo Township": "銅鑼鄉",
    "Dahu Township": "大湖鄉",
    "Sanyi Township": "三義鄉",
    "Nanzhuang Township": "南庄鄉",
    "Shitan Township": "獅潭鄉",

    // 彰化縣
    "Changhua City": "彰化市",
    "Lukang Township": "鹿港鎮",
    "Fenyuan Township": "芬園鄉",
    "Huatan Township": "花壇鄉",
    "Hemei Township": "和美鎮",
    "Xihu Township": "溪湖鎮",
    "Yongjing Township": "永靖鄉",

    // 南投縣
    "Nantou City": "南投市",
    "Puli Township": "埔里鎮",
    "Caotun Township": "草屯鎮",
    "Jiji Township": "集集鎮",
    "Guoxing Township": "國姓鄉",
    "Yuchi Township": "魚池鄉",
    "Ren'ai Township": "仁愛鄉",

    // 雲林縣
    "Douliu City": "斗六市",
    "Dounan Township": "斗南鎮",
    "Huwei Township": "虎尾鎮",
    "Mailiao Township": "麥寮鄉",
    "Shuilin Township": "水林鄉",

    // 嘉義市 / 縣
    "East District (Chiayi)": "東區",
    "West District (Chiayi)": "西區",
    "Chiayi City": "嘉義市",
    "Taibao City": "太保市",
    "Puzi City": "朴子市",
    "Budai Township": "布袋鎮",

    // 屏東縣
    "Pingtung City": "屏東市",
    "Chaozhou Township": "潮州鎮",
    "Donggang Township": "東港鎮",
    "Hengchun Township": "恆春鎮",
    "Wanluan Township": "萬巒鄉",
    "Neipu Township": "內埔鄉",

    // 宜蘭縣
    "Yilan City": "宜蘭市",
    "Luodong Township": "羅東鎮",
    "Suao Township": "蘇澳鎮",
    "Toucheng Township": "頭城鎮",
    "Jiaoxi Township": "礁溪鄉",

    // 花蓮縣
    "Hualien City": "花蓮市",
    "Ji’an Township": "吉安鄉",
    "Shoufeng Township": "壽豐鄉",
    "Fenglin Township": "鳳林鎮",

    // 台東縣
    "Taitung City": "台東市",
    "Beinan Township": "卑南鄉",
    "Luye Township": "鹿野鄉",
    "Chishang Township": "池上鄉",

    // 澎湖縣
    "Magong City": "馬公市",
    "Huxi Township": "湖西鄉",
    "Baisha Township": "白沙鄉",
    "Xiyu Township": "西嶼鄉",

    // 金門縣
    "Jincheng Township": "金城鎮",
    "Jinhu Township": "金湖鎮",
    "Jinning Township": "金寧鄉",

    // 連江縣（馬祖）
    "Nangan Township": "南竿鄉",
    "Beigan Township": "北竿鄉",
    "Dongyin Township": "東引鄉",
  };

  //工具區

  // 單純把英文縣市名稱轉成中文，若沒有對照則回傳原字串（或空字串）
  static String cityToChinese(String? englishCity) {
    if (englishCity == null || englishCity.trim().isEmpty) return '';
    return _cityNameMap[englishCity] ?? englishCity;
  }

  // 單純把英文行政區名稱轉成中文，若沒有對照則回傳原字串（或空字串）
  static String districtToChinese(String? englishDistrict) {
    if (englishDistrict == null || englishDistrict.trim().isEmpty) return '';
    return _districtNameMap[englishDistrict] ?? englishDistrict;
  }

  // 對街道做「路 / 街 / 巷 / 弄 / 段 / 號」等正規化
  static String normalizeStreet(
    String? rawStreet, {
    String? city,
    String? district,
  }) {
    String s = (rawStreet ?? '').trim();
    if (s.isEmpty) return '';

    // 移除「台灣 / 臺灣 / Taiwan」
    s = s.replaceAll(RegExp(r'(台灣|臺灣|Taiwan)', caseSensitive: false), '');

    // 1️⃣ 移除開頭的郵遞區號（3~5 碼數字）
    s = s.replaceFirst(RegExp(r'^\s*\d{3,5}(?=\D)'), '');

    // 如果 street 內又包含縣市 / 行政區名稱，把它拿掉，避免重複
    void removeAreaName(String? name) {
      if (name == null || name.trim().isEmpty) return;

      // 同時處理「台 / 臺」兩種寫法
      final n = name.trim();
      final alt1 = n.replaceAll('台', '臺');
      final alt2 = n.replaceAll('臺', '台');

      for (final v in {n, alt1, alt2}) {
        if (v.isEmpty) continue;
        s = s.replaceAll(v, '');
      }
    }

    removeAreaName(city);
    removeAreaName(district);

    s = s.trim();

    //常見英文路名關鍵字轉中文
    s = s.replaceAll(RegExp(r'Road', caseSensitive: false), '路');
    s = s.replaceAll(RegExp(r'Rd\.?', caseSensitive: false), '路');

    s = s.replaceAll(RegExp(r'Street', caseSensitive: false), '街');
    s = s.replaceAll(RegExp(r'St\.?', caseSensitive: false), '街');

    s = s.replaceAll(RegExp(r'Lane', caseSensitive: false), '巷');
    s = s.replaceAll(RegExp(r'Ln\.?', caseSensitive: false), '巷');

    s = s.replaceAll(RegExp(r'Alley', caseSensitive: false), '弄');

    s = s.replaceAll(RegExp(r'Section', caseSensitive: false), '段');
    s = s.replaceAll(RegExp(r'Sec\.?', caseSensitive: false), '段');

    // No. / # 轉成「號」
    s = s.replaceAll(RegExp(r'No\.?\s*', caseSensitive: false), '');
    s = s.replaceAll('#', '');

    // 若以數字結尾，補上「號」
    if (RegExp(r'\d+$').hasMatch(s) && !s.endsWith('號')) {
      s = '$s號';
    }

    return s.trim();
  }

  // 直接從 Placemark 組成「縣市 + 區 + 街道」中文地址
  static String formatFromPlacemark(Placemark place, {String separator = ''}) {
    final englishCity = place.administrativeArea ?? '';

    // geocoding 在台灣常見的情況：
    // administrativeArea: Taipei City / New Taipei City...
    // subAdministrativeArea 或 locality: Wenshan District / Banqiao District...
    final englishDistrict =
        place.subAdministrativeArea?.isNotEmpty == true
            ? place.subAdministrativeArea!
            : (place.locality ?? '');

    final city = cityToChinese(englishCity);
    final district = districtToChinese(englishDistrict);

    // street 通常會包含路 / 巷 / 弄 / 號，有時候會在 name 裡
    String streetRaw = place.street ?? '';
    if (streetRaw.trim().isEmpty && place.name != null) {
      streetRaw = place.name!;
    }
    final street = normalizeStreet(streetRaw, city: city, district: district);

    final parts =
        <String>[
          city,
          district,
          street,
        ].where((e) => e.trim().isNotEmpty).toSet(); // 去重

    if (parts.isEmpty && place.name != null) {
      return place.name!;
    }

    return parts.join(separator);
  }

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
