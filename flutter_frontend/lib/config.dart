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

  //創建慈善活動，需回傳值：{'name':(必填),'startTime':(必填),'endTime':(必填),'signupDeadline':報名截止時間, 'description':,'eventType':(typeName、單選),'location':中文縣市, 'address':中文詳細地址}
  static String get createCharityEvent =>
      '${BaseConfig.baseUrl}/charity/event/create/';

  //透過邀請碼申請協辦活動，需回傳值：{'inviteCode':(必填)}
  static String get coOrganizeEvent =>
      '${BaseConfig.baseUrl}/charity/event/coorganize/';

  //活動主辦方查詢協辦申請列表，前端需回傳值：{'charityEventName':(必填)}，後端傳回範例:{"coOrganizerName": "協辦單位A","coOrganizerEmail": "a@example.com","verified": null(null=待審核, true=通過, false=不通過)}
  static String get getCoOrganizeApplications =>
      '${BaseConfig.baseUrl}/charity/event/coorganize/applications/';

  //活動主辦方審核協辦者申請，需回傳值：{'charityEventName':(必填),'coOrganizerName':(必填),'approve':true/false(必填，同意/不同意該協辦者申請)}
  static String get verifyCoOrganize =>
      '${BaseConfig.baseUrl}/charity/event/coorganize/verify/';

  //活動主辦方移除協辦者(一次一個，該協辦者的verified會從True變成False)，需回傳值：{'charityEventName':(必填),'coOrganizerName':(必填)}
  static String get removeCoOrganizer =>
      '${BaseConfig.baseUrl}/charity/event/coorganize/remove/';

  //拿事件清單(個人帳號跟組織都用這個)，需回傳值(有預設值，第一次拿不用給值)(用 GET ，不是 POST )：
  //{'page':,'eventType':,'location':,'time':(到 settings.py 看 ACTIVITY_LIST_TIME_CHOICES ，回傳''裡面的值 )}
  //拿到的值怎麼填可以參考 https://chatgpt.com/share/68824fd7-1740-8001-a131-6c1385e4510b
  //收藏跟參加人數我寫成 list 格式，就跟 event 的順序一樣，可以照填
  static String get charityEventList => '${BaseConfig.baseUrl}/events/';

  //給事件清單看詳情的詳細資訊回傳(個人帳號跟組織都用這個)
  //使用方式：final url = ApiPath.charityEventDetail(eventId); eventId 給前面 event 拿到的 id
  static String charityEventDetail(int eventId) =>
      '${BaseConfig.baseUrl}/events/$eventId/';

  //讓用戶加入收藏清單
  static String addCharityEventUserSave(int eventId) =>
      '${BaseConfig.baseUrl}/events/$eventId/?user_record_choice=Save';

  //讓用戶加入參加清單
  static String addCharityEventUserJoin(int eventId) =>
      '${BaseConfig.baseUrl}/events/$eventId/?user_record_choice=Join';
}
