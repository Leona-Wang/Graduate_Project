import 'package:flutter/material.dart';
import 'package:flutter_frontend/screens/charity_screens/charity_qr_code.dart';
import 'package:flutter_frontend/screens/charity_screens/charity_home.dart';
import 'package:flutter_frontend/screens/charity_screens/charity_event_list.dart';
import 'package:flutter_frontend/screens/charity_screens/charity_event_detail_page.dart';
import 'package:flutter_frontend/screens/charity_screens/charity_mailbox.dart';
import 'package:flutter_frontend/screens/charity_screens/charity_mail_detail.dart';
import 'package:flutter_frontend/screens/charity_screens/charity_map.dart';
import 'package:flutter_frontend/screens/charity_screens/charity_new_event.dart';
import 'package:flutter_frontend/screens/charity_screens/charity_edit_event.dart';
import 'package:flutter_frontend/screens/charity_screens/charity_setting.dart';
import 'package:flutter_frontend/screens/charity_screens/charity_co-organizer.dart';
import 'package:flutter_frontend/screens/charity_screens/charity_co-organize_number.dart';
import 'package:flutter_frontend/screens/personal_screens/personal_qr_code.dart';
import 'package:flutter_frontend/screens/personal_screens/personal_event.dart';
import 'package:flutter_frontend/screens/personal_screens/personal_home_tab.dart';
import 'package:flutter_frontend/screens/login/group_signin.dart';
import 'package:flutter_frontend/screens/login/group_signup.dart';
import 'package:flutter_frontend/screens/login/personal_signin.dart';
import 'package:flutter_frontend/screens/login/personal_signup.dart';
import 'package:flutter_frontend/screens/login/test_image.dart';
import 'package:flutter_frontend/screens/personal_screens/personal_mailbox.dart';
import 'package:flutter_frontend/screens/personal_screens/personal_mail_detail.dart';
import 'package:flutter_frontend/screens/personal_screens/personal_map.dart';
import 'package:flutter_frontend/screens/personal_screens/personal_pet.dart';
import 'package:flutter_frontend/screens/personal_screens/personal_setting.dart';
import 'package:flutter_frontend/screens/personal_screens/personal_shop.dart';
import 'screens/welcome_slides.dart';
import 'screens/example_1.dart';
import 'screens/example_2.dart';
import 'screens/user_register.dart';
import 'package:flutter_frontend/screens/personal_screens/personal_event_list.dart'
    as pel;
import 'package:flutter_frontend/screens/personal_screens/personal_event_detail_page.dart';
import 'screens/personal_screens/personal_home.dart';

class AppRoutes {
  static const String welcomeSlides = '/';
  static const String userRegister = '/userRegister';
  static const String example1 = '/example1';
  static const String example2 = '/example2';

  //personal_screens
  static const String personalHomeTab = '/personal_home_tab'; //主頁面按鈕與功能
  static const String personalHome = '/personal_home'; //主頁面內容
  static const String personalMap = '/personal_map'; //地圖頁面
  static const String personalPet = '/personal_pet'; //寵物系統
  static const String personalShop = '/personal_shop'; //商城系統
  static const String personalEvent = '/personal_event'; //特殊活動
  static const String personalSetting = '/personal_setting'; //系統設定
  static const String personalEventDetail = '/personal_event_detail_page';
  static const String personalEventList =
      '/personal_event_list'; //活動清單(包含在map裡面)
  static const String personalQRCode = '/personal_qr_code'; //個人用戶QRcode(生產)
  static const String personalMailbox = '/personal_mailbox'; //個人用戶信箱
  static const String personalMailDetail = '/personal_maildetail'; //個人信箱詳情

  //charity_screens

  static const String charityEventList = '/charity_event_list'; //活動清單
  static const String charityHome = '/charity_home'; //主頁
  static const String charityMap = '/charity_map'; //新增活動的地址選擇頁面
  static const String charitySetting = '/charity_setting'; //系統設定
  static const String charityNewEvent = '/charity_new_event'; //新增活動
  static const String charityEditEvent = '/charity_edit_event';
  static const String charityCoorganizer = '/charity_co-organizer';
  static const String charityCoorganizeNumber = '/charity_co-organizer_number';
  static const String charityEventDetail = '/charity_event_detail_page';
  static const String charityQRCode = '/charity_qr_code'; //掃描QRCode
  static const String charityMailbox = '/charity_mailbox'; //機構信箱
  static const String charityMailDetail = '/charity_maildetail'; //機構信箱詳情

  //登入與註冊頁面
  static const String personalSignin = '/personal_signin'; //個人登入
  static const String personalSignup = '/personal_signup'; //個人註冊
  static const String groupSignin = '/group_signin'; //團體登入
  static const String groupSignup = '/group_signup'; //團體註冊
  static const String testImage = '/test_image';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case welcomeSlides:
        return MaterialPageRoute(builder: (_) => const WelcomeSlidesPage());

      case userRegister:
        return MaterialPageRoute(builder: (_) => const UserRegisterPage());

      case testImage:
        return MaterialPageRoute(builder: (_) => const TestImagePage());

      case example1:
        return MaterialPageRoute(builder: (_) => const Example1Page());

      case example2:
        final args = settings.arguments as int;
        return MaterialPageRoute(builder: (_) => Example2Page(result: args));

      //personal_screens
      case personalHome:
        return MaterialPageRoute(builder: (_) => PersonalHomePage());

      case personalHomeTab:
        return MaterialPageRoute(builder: (_) => PersonalHomeTab());

      case personalMap:
        return MaterialPageRoute(builder: (_) => PersonalMapPage());

      case personalPet:
        return MaterialPageRoute(builder: (_) => PersonalPetPage());

      case personalShop:
        return MaterialPageRoute(builder: (_) => PersonalShopPage());

      case personalEvent:
        return MaterialPageRoute(builder: (_) => PersonalEventPage());

      case personalSetting:
        return MaterialPageRoute(builder: (_) => PersonalSettingPage());

      case personalEventList:
        return MaterialPageRoute(builder: (_) => PersonalEventPage());

      case AppRoutes.personalEventDetail:
        final pel.Event event = settings.arguments as pel.Event;

        return MaterialPageRoute(
          builder: (_) => PersonalEventDetailPage(event: event),
        );

      case personalQRCode:
        return MaterialPageRoute(builder: (_) => PersonalQRCodePage());

      case personalMailbox:
        return MaterialPageRoute(builder: (_) => PersonalMailboxPage());

      case personalMailDetail:
        final mailId = settings.arguments as int;
        return MaterialPageRoute(
          builder: (_) => PersonalMailDetailPage(mailId: mailId),
        );

      //charity_screens
      case charityEventList:
        return MaterialPageRoute(builder: (_) => CharityEventListPage());

      case charityHome:
        return MaterialPageRoute(builder: (_) => CharityHomePage());

      case charityMap:
        return MaterialPageRoute(builder: (_) => CharityMapPage());

      case charitySetting:
        return MaterialPageRoute(builder: (_) => CharitySettingPage());

      case charityNewEvent:
        return MaterialPageRoute(builder: (_) => CharityNewEventPage());

      case charityEditEvent:
        final eventId = settings.arguments as int;
        return MaterialPageRoute(
          builder: (_) => CharityEditEventPage(eventId: eventId),
        );

      case charityCoorganizer:
        final eventId = settings.arguments as int;
        return MaterialPageRoute(
          builder: (_) => CharityCoorganizerPage(eventId: eventId),
        );

      case charityCoorganizeNumber:
        return MaterialPageRoute(builder: (_) => CharityCoorganizeNumberPage());

      case AppRoutes.charityEventDetail:
        final charityEvent = settings.arguments as CharityEvent;
        return MaterialPageRoute(
          builder: (_) => CharityEventDetailPage(event: charityEvent),
        );

      case charityQRCode:
        return MaterialPageRoute(builder: (_) => CharityQRCodePage());

      case charityMailbox:
        return MaterialPageRoute(builder: (_) => CharityMailboxPage());

      case charityMailDetail:
        final mailId = settings.arguments as int;
        return MaterialPageRoute(
          builder: (_) => CharityMailDetailPage(mailId: mailId),
        );

      //login-out
      case personalSignin:
        return MaterialPageRoute(builder: (_) => PersonalSigninPage());

      case personalSignup:
        final personalEmail = settings.arguments as String?;
        return MaterialPageRoute(
          builder:
              (_) => PersonalSignupPage(personalEmail: personalEmail ?? ''),
        );

      case groupSignin:
        return MaterialPageRoute(builder: (_) => GroupSigninPage());

      case groupSignup:
        final email = settings.arguments as String?;
        return MaterialPageRoute(
          builder: (_) => GroupSignupPage(email: email ?? ''),
        );

      default:
        return MaterialPageRoute(
          builder: (_) => const Scaffold(body: Center(child: Text('未知路由'))),
        );
    }
  }
}
