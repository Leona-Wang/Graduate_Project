// config.dart

//API Path 設定格式
//static String get /API名稱/ => '${BaseConfig.baseUrl}/設定的url/;
//之後只要在base_config.dart改自己的IP就好

import 'base_config.dart';

class ApiPath {
  static String get testApi => '${BaseConfig.baseUrl}/testApi/';
  static const String login = '/login/';

  //個人用戶email驗證，需回傳值：{'personalEmail':}
  static String get checkPersonalEmail =>
      '${BaseConfig.baseUrl}/email/check/?type=personal';
  //團體用戶email驗證，需回傳值：{'groupEmail':} *注意API名稱是check"Charity"Email，但回傳值是"group"Email
  static String get checkCharityEmail =>
      '${BaseConfig.baseUrl}/email/check/?type=charity';

  //帳號登入(個人團體都用這個)，需回傳值：{'email':,'password':}
  static String get checkPassword => '${BaseConfig.baseUrl}/login/';

  //個人設定密碼，需回傳值：{'personalEmail':,'personalPassword':,'personalPasswordConfirm':}
  static String get createPersonalUser =>
      '${BaseConfig.baseUrl}/user/create/?type=personal';
  //團體設定密碼，需回傳值：{'charityEmail':,'charityPassword':,'charityPasswordConfirm':}
  static String get createCharityUser =>
      '${BaseConfig.baseUrl}/user/create/?type=charity';

  //個人用戶創建資料，需回傳值：{'email':,'nickname':,'location':,'eventType':[可多選，把選項名稱用外面這種括號包起來]}
  static String get createPersonalInfo =>
      '${BaseConfig.baseUrl}/person/create/';
  //團體創建資料，需回傳值：{'email':,'groupName':,'groupType':,'groupAddress':,'groupPhone':,'groupId':}
  //如果前端想要有透過 id 找 organization 資料的話再跟汪說，我寫一個 API 給你們
  static String get createCharityInfo =>
      '${BaseConfig.baseUrl}/charity/create/';
}
