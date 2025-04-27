import 'package:flutter/material.dart';
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

      default:
        return MaterialPageRoute(
          builder: (_) => const Scaffold(body: Center(child: Text('未知路由'))),
        );
    }
  }
}
