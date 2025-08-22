import 'package:flutter/material.dart';
import 'package:flutter_frontend/screens/personal_screens/personal_qr_code.dart';
import 'package:flutter_frontend/screens/personal_screens/personal_home_tab.dart';

class PersonalSettingPage extends StatefulWidget {
  const PersonalSettingPage({super.key});

  @override
  State<PersonalSettingPage> createState() => PersonalSettingPageState();
}

class PersonalSettingPageState extends State<PersonalSettingPage> {
  void backToHome() {
    PersonalHomeTab.of(context)?.switchTab(0);
  }

  void qrCode() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => const PersonalQRCodePage()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: Padding(
          padding: const EdgeInsets.only(left: 12.0, top: 6.0, bottom: 6.0),
          child: CircleAvatar(
            backgroundColor: Colors.amberAccent,
            child: IconButton(
              onPressed: backToHome,
              icon: const Icon(Icons.arrow_back_ios_new, color: Colors.brown),
              tooltip: '返回主頁',
            ),
          ),
        ),
        title: const Text('設定'),
      ),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            SizedBox(
              width: 200,
              height: 60,
              child: ElevatedButton(
                onPressed: qrCode,
                child: const Text(
                  '活動報到',
                  style: TextStyle(fontSize: 20, color: Colors.amber),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
