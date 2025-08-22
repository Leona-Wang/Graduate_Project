import 'package:flutter/material.dart';
import 'package:flutter_frontend/screens/personal_screens/personal_journal_detail.dart';

class PersonalEventJournalPage extends StatefulWidget {
  const PersonalEventJournalPage({super.key});

  @override
  State<PersonalEventJournalPage> createState() =>
      PersonalEventJournalPageState();
}

class PersonalEventJournalPageState extends State<PersonalEventJournalPage> {
  void toEventDetail() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const PersonalJournalDetailPage(),
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
              tooltip: '返回主頁',
            ),
          ),
        ),
        title: const Text('個人活動履歷'),
      ),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            SizedBox(
              width: 200,
              height: 60,
              child: ElevatedButton(
                onPressed: toEventDetail,
                child: const Text(
                  '已報名活動', //等這裡的API做好後改為動態更新的列表
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
