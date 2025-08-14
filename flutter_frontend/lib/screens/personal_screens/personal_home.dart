import 'package:flutter/material.dart';
import 'package:flutter_frontend/screens/personal_screens/personal_mailbox.dart';

class PersonalHomePage extends StatefulWidget {
  const PersonalHomePage({super.key});

  State<PersonalHomePage> createState() => PersonalHomePageState();
}

class PersonalHomePageState extends State<PersonalHomePage> {
  void _toMail() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const PersonalMailboxPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('首頁'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12.0, top: 6.0, bottom: 6.0),
            child: CircleAvatar(
              backgroundColor: Colors.amber,
              child: IconButton(
                onPressed: _toMail,
                icon: const Icon(Icons.mail, color: Colors.brown),
                tooltip: '信箱',
              ),
            ),
          ),
        ],
      ),
      body: Center(child: Text('絕命開發中>>>')),
    );
  }
}
