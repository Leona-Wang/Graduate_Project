import 'package:flutter/material.dart';
import 'routes.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:firebase_core/firebase_core.dart';

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
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
          initialRoute: AppRoutes.charityNewEvent,
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
