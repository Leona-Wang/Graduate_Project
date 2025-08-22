import 'package:flutter/material.dart';
import 'package:flutter_frontend/screens/personal_screens/personal_home_tab.dart';

class PersonalEventPage extends StatefulWidget {
  const PersonalEventPage({super.key});

  @override
  State<PersonalEventPage> createState() => PersonalEventPageState();
}

class PersonalEventPageState extends State<PersonalEventPage> {
  void backToHome() {
    PersonalHomeTab.of(context)?.switchTab(0);
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
        title: const Text('活動'),
      ),
      body: const Center(child: Text('絕命測試中...')),
    );
  }
}
