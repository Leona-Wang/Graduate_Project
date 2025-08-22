import 'package:flutter/material.dart';
import 'package:flutter_frontend/screens/personal_screens/personal_qr_code.dart';

class PersonalJournalDetailPage extends StatefulWidget {
  const PersonalJournalDetailPage({super.key});

  @override
  State<PersonalJournalDetailPage> createState() =>
      PersonalJournalDetailPageState();
}

class PersonalJournalDetailPageState extends State<PersonalJournalDetailPage> {
  void toQRCode() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => PersonalQRCodePage()));
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
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back_ios_new, color: Colors.brown),
              tooltip: '返回',
            ),
          ),
        ),
        title: const Text('活動詳情'),
      ),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            SizedBox(
              width: 200,
              height: 60,
              child: ElevatedButton(
                onPressed: toQRCode,
                child: const Text(
                  '報到!',
                  style: TextStyle(fontSize: 20, color: Colors.brown),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
