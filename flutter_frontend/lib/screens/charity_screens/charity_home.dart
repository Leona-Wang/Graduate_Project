import 'package:flutter/material.dart';
import 'package:flutter_frontend/screens/charity_screens/charity_event_list.dart';
import 'package:flutter_frontend/screens/charity_screens/charity_new_event.dart';

class CharityHomePage extends StatefulWidget {
  const CharityHomePage({super.key});

  State<CharityHomePage> createState() => CharityHomePageState();
}

class CharityHomePageState extends State<CharityHomePage> {
  void _newEventPage() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const CharityNewEventPage()),
    );
  }

  void _eventListPage() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const CharityEventListPage()),
    );
  }

  void _coEventPage() {
    /*
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => const ()))
    */
    //或是可以做成彈出式框框，直接在這裡接API
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('首頁')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            SizedBox(
              width: 200,
              height: 60,
              child: ElevatedButton(
                onPressed: _newEventPage,
                child: const Text(
                  '新增活動',
                  style: TextStyle(fontSize: 20, color: Colors.amber),
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: 200,
              height: 60,
              child: ElevatedButton(
                onPressed: _eventListPage,
                child: const Text(
                  '活動清單',
                  style: TextStyle(fontSize: 20, color: Colors.amber),
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: 200,
              height: 60,
              child: ElevatedButton(
                onPressed: _coEventPage,
                child: const Text(
                  '協辦活動',
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

/*
---------------------------
          設定|個人詳細資訊 
主頁


顯示機構資訊
查看您的活動按紐
新增活動(地圖)

              一隻芒果鳥


---------------------------

*/
