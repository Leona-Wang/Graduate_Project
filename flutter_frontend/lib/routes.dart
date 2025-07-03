import 'package:flutter/material.dart';
import 'package:flutter_frontend/screens/event.dart';
import 'package:flutter_frontend/screens/home_tab.dart';
import 'package:flutter_frontend/screens/login/group_signin.dart';
import 'package:flutter_frontend/screens/login/group_signup.dart';
import 'package:flutter_frontend/screens/login/personal_signin.dart';
import 'package:flutter_frontend/screens/login/personal_signup.dart';
import 'package:flutter_frontend/screens/map.dart';
import 'package:flutter_frontend/screens/pet.dart';
import 'package:flutter_frontend/screens/setting.dart';
import 'package:flutter_frontend/screens/shop.dart';
import 'screens/welcome_slides.dart';
import 'screens/example_1.dart';
import 'screens/example_2.dart';
import 'screens/user_register.dart';

import 'screens/home.dart';

class AppRoutes {
  static const String welcomeSlides = '/';
  static const String userRegister = '/userRegister';
  static const String example1 = '/example1';
  static const String example2 = '/example2';

  static const String home = '/home'; //主頁面按鈕與功能
  static const String homeTab = '/home_tab'; //主頁面內容
  static const String map = '/map'; //地圖頁面
  static const String pet = '/pet'; //寵物系統
  static const String shop = '/shop'; //商城系統
  static const String event = '/event'; //特殊活動
  static const String setting = '/setting'; //系統設定

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

      case home:
        return MaterialPageRoute(builder: (_) => HomePage());

      case homeTab:
        return MaterialPageRoute(builder: (_) => HomeTab());

      case map:
        return MaterialPageRoute(builder: (_) => MapPage());

      case pet:
        return MaterialPageRoute(builder: (_) => PetPage());

      case shop:
        return MaterialPageRoute(builder: (_) => ShopPage());

      case event:
        return MaterialPageRoute(builder: (_) => EventPage());

      case setting:
        return MaterialPageRoute(builder: (_) => SettingPage());

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
        return MaterialPageRoute(builder: (_) => GroupSignupPage());

      default:
        return MaterialPageRoute(
          builder: (_) => const Scaffold(body: Center(child: Text('未知路由'))),
        );
    }
  }
}
