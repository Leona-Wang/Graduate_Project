import 'package:flutter/material.dart';
import 'package:flutter_frontend/screens/personal_screens/personal_mailbox.dart';
import 'package:flutter_frontend/screens/personal_screens/personal_profile.dart';

class PersonalHomePage extends StatefulWidget {
  const PersonalHomePage({super.key});

  @override
  State<PersonalHomePage> createState() => PersonalHomePageState();
}

class PersonalHomePageState extends State<PersonalHomePage> {
  void toMail() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const PersonalMailboxPage()),
    );
  }

  void toProfile() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const PersonalProfilePage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('首頁'),
        //左邊區域
        leading: Padding(
          padding: const EdgeInsets.only(left: 12.0, top: 6.0, bottom: 6.0),
          child: CircleAvatar(
            backgroundColor: Colors.amberAccent,
            child: IconButton(
              onPressed: toProfile,
              icon: const Icon(Icons.person, color: Colors.brown),
              tooltip: '個人資訊',
            ),
          ),
        ),
        //右邊區域
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12.0, top: 6.0, bottom: 6.0),
            child: CircleAvatar(
              backgroundColor: Colors.amber,
              child: IconButton(
                onPressed: toMail,
                icon: const Icon(Icons.mail, color: Colors.brown),
                tooltip: '信箱',
              ),
            ),
          ),
        ],
      ),
      body: Center(child: Text('首頁絕命開發中>>>')),
    );
  }
}
