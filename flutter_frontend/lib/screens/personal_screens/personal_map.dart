import 'package:flutter/material.dart';
import 'package:flutter_frontend/config.dart';
import 'package:flutter_frontend/screens/personal_screens/personal_event_list.dart';
import 'package:flutter_frontend/screens/personal_screens/personal_home_tab.dart';

import 'dart:convert';
import '../../api_client.dart';

class PersonalMapPage extends StatefulWidget {
  const PersonalMapPage({super.key});

  @override
  State<PersonalMapPage> createState() => PersonalMapPageState();
}

class PersonalMapPageState extends State<PersonalMapPage> {
  void backToHome() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => const PersonalHomeTab()));
  }

  void toEventList() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const PersonalEventListPage()),
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
              onPressed: backToHome,
              icon: const Icon(Icons.arrow_back_ios_new, color: Colors.brown),
              tooltip: '返回主頁',
            ),
          ),
        ),
        title: const Text('活動地圖'),
      ),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            SizedBox(
              width: 200,
              height: 60,
              child: ElevatedButton(
                onPressed: toEventList,
                child: const Text(
                  '查看附近的活動',
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
