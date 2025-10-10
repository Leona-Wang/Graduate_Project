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

  //活動主辦方查詢協辦申請列表(Verified=None的)，前端需回傳值：{'charityEventName':(必填)}，後端傳回範例:{"coOrganizerName": "協辦單位A","coOrganizerEmail": "a@example.com"}(一次回傳全部申請)
  static String get getCoOrganizeApplications =>
      '${BaseConfig.baseUrl}/charity/event/coorganize/applications/';

  //活動主辦方查詢已認證過的協辦者列表(Verified=True的)，前端需回傳值：{'charityEventName':(必填)}，後端傳回範例:{"coOrganizerName": "協辦單位A","coOrganizerEmail": "a@example.com"}(一次回傳全部已認證過的協辦者)
  static String get getCoOrganizers =>
      '${BaseConfig.baseUrl}/charity/event/coorganizers/';
  //活動主辦方審核協辦者申請，需回傳值：{'charityEventName':(必填),'coOrganizerName':(必填),'approve':true/false(必填，同意/不同意該協辦者申請)}
  static String get verifyCoOrganize =>
      '${BaseConfig.baseUrl}/charity/event/coorganize/verify/';

  //活動主辦方移除協辦者(一次一個，該協辦者的verified會從True變成False)，需回傳值：{'charityEventName':(必填),'coOrganizerName':(必填)}
  static String get removeCoOrganizer =>
      '${BaseConfig.baseUrl}/charity/event/coorganize/remove/';

  //拿事件清單(個人帳號跟組織都用這個)(支援 eventType/location/time 篩選)，需回傳值(有預設值，第一次拿不用給值)(用 GET ，不是 POST )：
  //{'page':(分頁，預設為1),'eventType':(typeName，若需要當成filter再填),'location':(若需要當成filter再填),'time':(到 settings.py 看 ACTIVITY_LIST_TIME_CHOICES ，回傳''裡面的值 )}
  //拿到的值怎麼填可以參考 https://chatgpt.com/share/68824fd7-1740-8001-a131-6c1385e4510b
  //後端回傳過來的值會多一個 statusDisplay 中文欄位，就是原本event的status欄位轉換成中文的，可以把這個顯示給使用者看
  //收藏跟參加人數我寫成 list 格式，就跟 event 的順序一樣，可以照填
  static String get charityEventList => '${BaseConfig.baseUrl}/events/';

  // 取得個人用戶已完成的活動清單(已經完成活動，並非報名) (支援 eventType/location/time 篩選)，需回傳值(有預設值，第一次拿不用給值)(用 GET ，不是 POST )：
  // {'page':(分頁，預設為1),'eventType':(typeName，若需要當成filter再填),'location':(若需要當成filter再填),'time':(到 settings.py 看 ACTIVITY_LIST_TIME_CHOICES ，回傳''裡面的值 )}
  // 幾乎與拿事件清單相同(上面那個)，只是拿到的活動是該用戶參加過且已結束的活動(註:但這個function CharityEvent.status=deleted(已被刪除) 的活動也會包含)，拿到的值怎麼填可以參考 https://chatgpt.com/share/68824fd7-1740-8001-a131-6c1385e4510b
  // 回傳：
  // {
  //   "events": [ {第一個event的所有值}, {第二個event的所有值}, ... ],
  //   "eventTypes": [ "typeNameA", "typeNameB", ... ],
  //   "locations": [ "locationNameA", "locationNameB", ... ]
  // }
  // 後端回傳過來的值會多一個 statusDisplay 中文欄位，就是原本event的status欄位轉換成中文的，可以把這個顯示給使用者看
  static String get personalJoinedEventList =>
      '${BaseConfig.baseUrl}/events/personal_joined/';

  //給事件清單看詳情的詳細資訊回傳(個人帳號跟組織都用這個)
  //使用方式：final url = ApiPath.charityEventDetail(eventId); eventId 給前面 event 拿到的 id
  static String charityEventDetail(int eventId) =>
      '${BaseConfig.baseUrl}/events/$eventId/';

  //讓用戶加入收藏清單
  static String addCharityEventUserSave(int eventId) =>
      '${BaseConfig.baseUrl}/events/$eventId/participant_record/?user_record_choice=Save';

  //讓用戶加入參加清單
  static String addCharityEventUserJoin(int eventId) =>
      '${BaseConfig.baseUrl}/events/$eventId/participant_record/?user_record_choice=Join';

  //讓用戶取消參加/收藏
  static String addCharityEventUserRevert(int eventId) =>
      '${BaseConfig.baseUrl}/events/$eventId/participant_record/?user_record_choice=revert';

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

  //用 POST ，不用給{}(如果不能不給就隨便丟個 id 或其他的就好，反正我用不到)
  //成功傳{'success':True}，失敗回404(找不到 mailId)
  static String sendReward(int mailId) =>
      '${BaseConfig.baseUrl}/mail/$mailId/reward/';

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

  //後端傳{'success': True,'totalBetAmount': totalBetAmount,'userBetAmount': userBetAmount}機率前端動態算，不然要用 ajax ，小麻煩
  static String get getBetDetail => '${BaseConfig.baseUrl}/events/casino/';

  //前端傳{'betAmount':}前端可以檢查輸入是不是非負整數(0也可以)
  static String get createOrUpdateBet =>
      '${BaseConfig.baseUrl}/events/casino/bet_amount/edit/';

  //後端傳{'success': True, 'isWinner': True/False} isWinner 為 True 就是中獎人
  static String get isBetWinner =>
      '${BaseConfig.baseUrl}/events/casino/winner/';

  //後端傳{'success':True,'itemList':({'name': , 'quantity': , 'imageUrl': })},itemList傳的會是一個list，裡面有圖片，再自己查一下要怎麼用url拿圖
  static String get getPowerupList => '${BaseConfig.baseUrl}/pet/powerup/';

  //前端傳{'powerupName':,'petName':,'quantity':}給我名字，因為我沒給你們id
  static String get deductPowerup => '${BaseConfig.baseUrl}/pet/powerup/edit/';

  // 回傳所有寵物以及該玩家是否有該寵物
  // 後端回傳範例:
  // {
  //   "success": true,
  //   "pets": [
  //     {
  //       "id": 1,
  //       "name": "血哥",
  //       "hasThisPet": true  (true代表玩家有這隻寵物，false代表沒有)
  //     },
  //     {
  //       "id": 2,
  //       "name": "白米星人",
  //       "hasThisPet": false
  //     },
  //     // ...更多寵物
  //   ]
  // }
  static String getAllPets() => '${BaseConfig.baseUrl}/pets/all/';

  // 回傳特定寵物的詳細資訊(一次查一隻寵物)
  // 使用方式：final url = ApiPath.petDetail(petId);
  // 後端回傳範例:
  // {
  // "success": true,
  // "name": "白米星人",
  // "description": "...",
  // "point": 75 (寵物親密度百分比，0~100)
  // "imageUrl": "/media/pet/白米星人.png", (寵物圖片url)
  // }
  static String petDetail(int petId) => '${BaseConfig.baseUrl}/pets/$petId/';

  // 寵物扭蛋機(用POST)，一次花費5金幣，若抽到已擁有的寵物則親密度+10(若親密度已滿則不再加親密度)
  // 後端回傳範例:
  // {
  //   "success": true,
  //   "pet": { (抽到的寵物資訊)
  //     "id": 1,
  //     "name": "章魚燒紳士",
  //     "description": "章魚燒紳士",
  //     "imageUrl": "/media/pet/章魚燒紳士.png",
  //     "newPet": true  (true代表抽到新寵物，false代表抽到已擁有的寵物)
  //   }
  // }
  static String get gachaPet => '${BaseConfig.baseUrl}/pets/gacha/';

  //個人活動清單(用 GET )，回傳長這樣，
  //如果想做連過去的詳情用 charityEvent 拿到的 id 塞進 charityEventDetail 的 id 就好
  //{
  //  "events": [
  //      {
  //          "id": 2,
  //          "eventName": "789",
  //          "joinType": "Join",
  //          "personalUser": 4,
  //          "charityEvent": 3
  //      },
  //  ]
  //}
  static String get userCharityEventsUpcomingJoin =>
      '${BaseConfig.baseUrl}person/event_list/?joinType=Join&eventStatus=upcoming';
  static String get userCharityEventsUpcomingSave =>
      '${BaseConfig.baseUrl}person/event_list/?joinType=Save&eventStatus=upcoming';
  static String get userCharityEventsFinishedJoin =>
      '${BaseConfig.baseUrl}person/event_list/?joinType=Join&eventStatus=finished';
  static String get userCharityEventsFinishedSave =>
      '${BaseConfig.baseUrl}person/event_list/?joinType=Save&eventStatus=finished';
  static String get userCharityEventsDeletedJoin =>
      '${BaseConfig.baseUrl}person/event_list/?joinType=Join&eventStatus=deleted';
  static String get userCharityEventsDeletedSave =>
      '${BaseConfig.baseUrl}person/event_list/?joinType=Save&eventStatus=deleted';
}
