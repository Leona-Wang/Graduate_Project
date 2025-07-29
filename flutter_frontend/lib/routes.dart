import 'package:flutter/material.dart';
import 'package:flutter_frontend/screens/charity_screens/charity_home.dart';
import 'package:flutter_frontend/screens/charity_screens/charity_event_list.dart';
import 'package:flutter_frontend/screens/charity_screens/charity_map.dart';
import 'package:flutter_frontend/screens/charity_screens/charity_new_event.dart';
import 'package:flutter_frontend/screens/charity_screens/charity_setting.dart';
import 'package:flutter_frontend/screens/personal_screens/personal_event.dart';
import 'package:flutter_frontend/screens/personal_screens/personal_home_tab.dart';
import 'package:flutter_frontend/screens/login/group_signin.dart';
import 'package:flutter_frontend/screens/login/group_signup.dart';
import 'package:flutter_frontend/screens/login/personal_signin.dart';
import 'package:flutter_frontend/screens/login/personal_signup.dart';
import 'package:flutter_frontend/screens/personal_screens/personal_map.dart';
import 'package:flutter_frontend/screens/personal_screens/personal_pet.dart';
import 'package:flutter_frontend/screens/personal_screens/personal_setting.dart';
import 'package:flutter_frontend/screens/personal_screens/personal_shop.dart';
import 'screens/welcome_slides.dart';
import 'screens/example_1.dart';
import 'screens/example_2.dart';
import 'screens/user_register.dart';

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

  //charity_screens
  static const String charityEventList = '/charity_event_list';
  static const String charityHome = '/charity_home';
  static const String charityMap = '/charity_map';
  static const String charitySetting = '/charity_setting';
  static const String charityNewEvent = '/charity_new_event';

  //登入與註冊頁面
  static const String personalSignin = '/personal_signin'; //個人登入
  static const String personalSignup = '/personal_signup'; //個人註冊
  static const String groupSignin = '/group_signin'; //團體登入
  static const String groupSignup = '/group_signup'; //團體註冊

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case welcomeSlides:
        return MaterialPageRoute(builder: (_) => const WelcomeSlidesPage());

      case userRegister:
        return MaterialPageRoute(builder: (_) => const UserRegisterPage());

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
