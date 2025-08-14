import 'package:flutter/material.dart';
import 'package:flutter_frontend/screens/charity_screens/charity_qr_code.dart';

class CharitySettingPage extends StatefulWidget {
  const CharitySettingPage({super.key});

  State<CharitySettingPage> createState() => CharitySettingPageState();
}

class CharitySettingPageState extends State<CharitySettingPage> {
  void _QRCode() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => const CharityQRCodePage()));
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
                  '活動入場',
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
