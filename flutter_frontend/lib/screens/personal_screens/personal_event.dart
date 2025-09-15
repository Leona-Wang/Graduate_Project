import 'package:flutter/material.dart';
import 'package:flutter_frontend/screens/personal_screens/personal_ff_event.dart';
import 'package:flutter_frontend/screens/personal_screens/personal_home_tab.dart';

class PersonalEventPage extends StatefulWidget {
  const PersonalEventPage({super.key});

  @override
  State<PersonalEventPage> createState() => PersonalEventPageState();
}

class PersonalEventPageState extends State<PersonalEventPage> {
  final List<Map<String, String>> events = [
    {
      'title': '5050 活動開催中!',
      'startDate': '2025-09-11',
      'endDate': '2025-10-11',
      'category': 'fifty',
    },
    {
      'title': '贊助我們的專案!',
      'startDate': '2025-09-11',
      'endDate': '2025-10-11',
      'category': 'donate',
    },
  ];

  void backToHome() {
    PersonalHomeTab.of(context)?.switchTab(0);
  }

  void goToDetail(Map<String, String> event) {
    final categoty = event['category'];

    Widget page;
    switch (categoty) {
      case 'fifty':
        page = PersonalFFEventPage();
        break;
      default:
        page = PersonalFFEventPage();
    }

    Navigator.push(context, MaterialPageRoute(builder: (_) => page));
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
      body: ListView.builder(
        itemCount: events.length,
        itemBuilder: (context, index) {
          final event = events[index];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: ListTile(
              title: Text(event['title']!),
              subtitle: Text('${event['startDate']} . ${event['endDate']}'),
              onTap: () => goToDetail(event),
            ),
          );
        },
      ),
    );
  }
}
