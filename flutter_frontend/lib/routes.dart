import 'package:flutter/material.dart';
import 'screens/welcome_slides.dart';
import 'screens/home.dart';

class AppRoutes {
  static const String welcomeSlides = '/';
  static const String home = '/result';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case welcomeSlides:
        return MaterialPageRoute(builder: (_) => const WelcomeSlidesPage());

      default:
        return MaterialPageRoute(
          builder: (_) => const Scaffold(body: Center(child: Text('未知路由'))),
        );
    }
  }
}
