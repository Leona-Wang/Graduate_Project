import 'package:flutter/material.dart';
import 'package:flutter_frontend/screens/personal_screens/personal_qr_code.dart';

class PersonalFavoriteDetailPage extends StatefulWidget {
  final int eventId;

  const PersonalFavoriteDetailPage({super.key, required this.eventId});

  @override
  State<PersonalFavoriteDetailPage> createState() =>
      PersonalFavoriteDetailPageState();
}

class PersonalFavoriteDetailPageState
    extends State<PersonalFavoriteDetailPage> {
  final String eventName = '台北西門町的捐血車'; //測試用假資料
  void toQRCode() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PersonalQRCodePage(eventName: eventName),
      ),
    );
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
          children: <Widget>[SizedBox(width: 200, height: 60)],
        ),
      ),
    );
  }
}
