import 'package:flutter/material.dart';
import 'routes.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: Size(411, 891), // 這裡換成你的設計稿大小（很重要）
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return MaterialApp(
          title: '',
          initialRoute: AppRoutes.charityMap,
          onGenerateRoute: AppRoutes.generateRoute,
          builder: (context, widget) {
            // 這樣可以讓文字大小自動跟隨縮放
            ScreenUtil.init(context);
            return widget!;
          },
        );
      },
    );
  }
}
