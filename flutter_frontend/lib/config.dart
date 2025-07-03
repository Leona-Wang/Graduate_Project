// config.dart
const String baseUrl = 'http://192.168.0.121:8000';

class ApiPath {
  static const String testApi = '/testApi/';
  static const String login = '/login/';

  //個人設定密碼，需回傳值：{'personalEmail':,'personalPassword':,'personalPasswordConfirm':}
  static const String createPersonalUser = '/user/create/?type=personal';
  //團體設定密碼，需回傳值：{'charityEmail':,'charityPassword':,'charityPasswordConfirm':}
  static const String createCharityUser = '/user/create/?type=charity';

  //個人用戶創建資料，需回傳值：{'email':,'nickname':,'location':,'eventType':[可多選，把選項名稱用外面這種括號包起來]}
  static const String createPersonalInfo = '/person/create/';
  //團體創建資料，需回傳值：{'email':,'groupName':,'groupType':,'groupAddress':,'groupPhone':,'groupId':}
  //如果前端想要有透過 id 找 organization 資料的話再跟汪說，我寫一個 API 給你們
  static const String createCharityInfo = '/charity/create/';
}
