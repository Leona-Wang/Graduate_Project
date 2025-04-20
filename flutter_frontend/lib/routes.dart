import 'package:flutter/material.dart';
import 'screens/loginOption.dart';
import 'screens/home.dart';

class AppRoutes {
  static const String login = '/';
  static const String home = '/result';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case login:
        return MaterialPageRoute(builder: (_) => const LoginPage());

      case home:
        final args = settings.arguments as int;
        return MaterialPageRoute(builder: (_) => HomePage(result: args));

      default:
        return MaterialPageRoute(
          builder: (_) => const Scaffold(body: Center(child: Text('未知路由'))),
        );
    }
  }
}
