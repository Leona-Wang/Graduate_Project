import 'package:flutter/material.dart';

class PersonalMapPage extends StatelessWidget {
  const PersonalMapPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('地圖')), //之後返回鍵改為回到首頁，避免堆疊太多子頁面
      body: const Center(child: Text('絕命測試中...')),
    );
  }
}
