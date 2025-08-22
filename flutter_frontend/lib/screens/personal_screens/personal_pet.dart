import 'package:flutter/material.dart';
import 'package:flutter_frontend/screens/personal_screens/personal_home_tab.dart';

class PersonalPetPage extends StatefulWidget {
  const PersonalPetPage({super.key});

  @override
  State<PersonalPetPage> createState() => PersonalPetPageState();
}

class PersonalPetPageState extends State<PersonalPetPage> {
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
        title: const Text('寵物'),
      ),
      body: const Center(child: Text('絕命測試中...')),
    );
  }
}
