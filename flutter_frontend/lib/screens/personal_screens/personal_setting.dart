import 'package:flutter/material.dart';
import 'package:flutter_frontend/screens/personal_screens/personal_QRCode.dart';

class PersonalSettingPage extends StatefulWidget {
  const PersonalSettingPage({super.key});

  State<PersonalSettingPage> createState() => PersonalSettingPageState();
}

class PersonalSettingPageState extends State<PersonalSettingPage> {
  void _QRCode() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => const PersonalQRCodePage()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('系統設定')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            SizedBox(
              width: 200,
              height: 60,
              child: ElevatedButton(
                onPressed: _QRCode,
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
