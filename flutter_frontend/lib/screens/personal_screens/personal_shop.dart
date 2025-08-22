import 'package:flutter/material.dart';
import 'package:flutter_frontend/screens/personal_screens/personal_home_tab.dart';

class PersonalShopPage extends StatefulWidget {
  const PersonalShopPage({super.key});

  @override
  State<PersonalShopPage> createState() => PersonalShopPageState();
}

class PersonalShopPageState extends State<PersonalShopPage> {
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
        title: const Text('商城'),
      ),
      body: const Center(child: Text('絕命測試中...')),
    );
  }
}
