import 'package:flutter/material.dart';
import 'routes.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:firebase_core/firebase_core.dart';

import 'package:flutter/material.dart';
//import 'package:firebase_core/firebase_core.dart';

import 'package:google_fonts/google_fonts.dart';

final RouteObserver<PageRoute> routeObserver = RouteObserver<PageRoute>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: const FirebaseOptions(
          apiKey: 'AIzaSyD7ib12dOqN1QCPCaE9-zUUvqAQ4jZvhrc',
          authDomain: 'login-app-67d5a.firebaseapp.com',
          projectId: 'login-app-67d5a',
          storageBucket: 'login-app-67d5a.firebasestorage.app',
          messagingSenderId: '51601454665',
          appId: '1:51601454665:web:f9bae49fc8350494d13198',
          measurementId: 'G-HB7JGM9V4G',
        ),
      );
    }
  } catch (e, stack) {
    print('Firebase initialize failed: $e');
    print(stack);
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final serif = GoogleFonts.notoSerifTc().fontFamily;
    return ScreenUtilInit(
      designSize: Size(411, 891), // 這裡換成你的設計稿大小（很重要）
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return MaterialApp(
          title: '',
          initialRoute: AppRoutes.welcomeSlides,
          onGenerateRoute: AppRoutes.generateRoute,
          navigatorObservers: [routeObserver],

          theme: ThemeData(
            useMaterial3: false, // 保留舊風格
            fontFamily: serif, // 全站套用 NotoSerifTC 中文復古字型

            appBarTheme: AppBarTheme(
              backgroundColor: const Color(0xFFe6ccb2), // 米棕色背景
              elevation: 4,
              titleTextStyle: GoogleFonts.notoSerifTc(
                textStyle: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF4b3832), // 深咖啡字
                  letterSpacing: .5,
                ),
              ),
              toolbarTextStyle: GoogleFonts.notoSerifTc(
                textStyle: const TextStyle(
                  fontSize: 16,
                  color: Color(0xFF4b3832),
                ),
              ),
            ),

            // 整體配色
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFFd4a373),
              background: const Color(0xFFf8f5f0),
            ),

            // 全局文字顏色與按鈕圓角風格
            textTheme: GoogleFonts.notoSerifTcTextTheme()
                .apply(
                  bodyColor: const Color(0xFF3b2f28),
                  displayColor: const Color(0xFF3b2f28),
                )
                .copyWith(
                  bodyLarge: const TextStyle(fontWeight: FontWeight.w700),
                  bodyMedium: const TextStyle(fontWeight: FontWeight.w600),
                  bodySmall: const TextStyle(fontWeight: FontWeight.w600),
                  titleLarge: const TextStyle(fontWeight: FontWeight.w800),
                  titleMedium: const TextStyle(fontWeight: FontWeight.w700),
                  titleSmall: const TextStyle(fontWeight: FontWeight.w700),
                  labelLarge: const TextStyle(fontWeight: FontWeight.w700),
                ),

            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFe6ccb2),
                foregroundColor: const Color(0xFF4b3832),
                textStyle: const TextStyle(
                  fontWeight: FontWeight.w700, // ← 按鈕字體更明顯
                  letterSpacing: 0.5,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),

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
