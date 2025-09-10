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

  //創建慈善活動，需回傳值：{'name':(必填，活動名稱),'startTime':(必填),'endTime':,'signupDeadline':報名截止時間, 'description':,'eventType':(typeName、單選),'location':中文縣市, 'address':中文詳細地址, 'online':true/false(是否為線上活動), permanent:true/false(是否為常駐活動))}
  static String get createCharityEvent =>
      '${BaseConfig.baseUrl}/charity/event/create/';

  //活動主辦方編輯活動，需回傳值：{'name':(必填,活動名稱),'eventType':,'location':,'address':,'startTime':,'endTime':,'signupDeadline':,'description':,'online':true/false}
  //只需傳要修改的欄位即可，未傳欄位不會被修改，如果endTime或signupDeadline要改成沒有時間(刪掉原本的值就傳空字串
  //現在是做不能改name的，因為name作為唯一識別，如果想改成可以改name的再跟我說
  static String get editCharityEvent =>
      '${BaseConfig.baseUrl}/charity/event/edit/';

  //活動主辦方刪除活動，需回傳值：{'eventName':(必填,活動名稱)}
  static String get deleteCharityEvent =>
      '${BaseConfig.baseUrl}/charity/event/delete/';

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

  //拿事件清單(個人帳號跟組織都用這個)(支援 eventType/location/time 篩選)，需回傳值(有預設值，第一次拿不用給值)(用 GET ，不是 POST )：
  //{'page':(分頁，預設為1),'eventType':(typeName，若需要當成filter再填),'location':(若需要當成filter再填),'time':(到 settings.py 看 ACTIVITY_LIST_TIME_CHOICES ，回傳''裡面的值 )}
  //拿到的值怎麼填可以參考 https://chatgpt.com/share/68824fd7-1740-8001-a131-6c1385e4510b
  //收藏跟參加人數我寫成 list 格式，就跟 event 的順序一樣，可以照填
  static String get charityEventList => '${BaseConfig.baseUrl}/events/';

  // 取得個人用戶參加過的活動清單（已結束的活動）(支援 eventType/location/time 篩選)，需回傳值(有預設值，第一次拿不用給值)(用 GET ，不是 POST )：
  // {'page':(分頁，預設為1),'eventType':(typeName，若需要當成filter再填),'location':(若需要當成filter再填),'time':(到 settings.py 看 ACTIVITY_LIST_TIME_CHOICES ，回傳''裡面的值 )}
  // 幾乎與拿事件清單相同(上面那個)，只是拿到的活動是該用戶參加過且已結束的活動，拿到的值怎麼填可以參考 https://chatgpt.com/share/68824fd7-1740-8001-a131-6c1385e4510b
  // 回傳：
  // {
  //   "events": [ {第一個event的所有值}, {第二個event的所有值}, ... ],
  //   "eventTypes": [ "typeNameA", "typeNameB", ... ],
  //   "locations": [ "locationNameA", "locationNameB", ... ]
  // }
  static String get personalJoinedEventList =>
      '${BaseConfig.baseUrl}/events/personal_joined/';

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

  //用 GET ，後端回傳：{'success': True, 'code': code} 拿 code 產 QRcode
  static String get createUserQRCode =>
      '${BaseConfig.baseUrl}/events/user_QRCode/';

  //用 POST ，前端給：{'code':,'eventName':}
  //不用擔心兩個 url 一樣的問題，我有區分開
  static String get verifyUserQRCode =>
      '${BaseConfig.baseUrl}/events/user_QRCode/';

  //查看單一郵件詳細資訊與內容(查看後該信件會自動設為已讀)，用 GET，mailId填入信件的id，後端回傳範例:
  // {
  //   "success": true,
  //   "mail": {
  //     "receiver": "使用者暱稱A",
  //     "date": "2025-08-16T12:34:56",
  //     "type": "活動",
  //     "title": "活動提醒",
  //     "content": "您的活動...即將開始！",
  //     "isRead": true
  //   }
  // }
  static String getMailDetail(int mailId) =>
    '${BaseConfig.baseUrl}/mail/$mailId/';
  
  //查詢user的某種type的mail list，用GET，後端回傳範例:
  // {
  //   "success": true,
  //   "mails": [
  //     {
  //       "id": 1,
  //       "title": "活動提醒",
  //       "isRead": true
  //     },
  //     {
  //       "id": 2,
  //       "title": "系統通知",
  //       "isRead": false
  //     }
  //   ]
  // }
  static String mailListByType(String mailType) =>
    '${BaseConfig.baseUrl}/mail/list/?type=$mailType';
}
