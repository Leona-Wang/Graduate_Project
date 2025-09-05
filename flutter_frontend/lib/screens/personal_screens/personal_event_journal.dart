import 'package:flutter/material.dart';
import 'package:flutter_frontend/screens/personal_screens/personal_journal_list.dart';

class PersonalEventJournalPage extends StatefulWidget {
  const PersonalEventJournalPage({super.key});

  @override
  State<PersonalEventJournalPage> createState() =>
      PersonalEventJournalPageState();
}

class PersonalEventJournalPageState extends State<PersonalEventJournalPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  List<String> ongoingEvents = [];
  List<String> pastEvents = [];

  bool isLoadingOngoing = true;
  bool isLoadingPast = true;

  void toEventDetail() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const PersonalJournalListPage()),
    );
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    fetchOngoingEvents();
    fetchPastEvents();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> fetchOngoingEvents() async {
    await Future.delayed(const Duration(seconds: 1));
    setState(() => isLoadingOngoing = false); //補API
  }

  Future<void> fetchPastEvents() async {
    await Future.delayed(const Duration(seconds: 1));
    setState(() => isLoadingPast = false); //補API
  }

  Widget buildEventList(List<String> events, bool isLoading) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (events.isEmpty) {
      return const Center(child: Text('目前沒有任務，快去探索看看吧!'));
    }
    return ListView.builder(
      itemCount: events.length,
      itemBuilder: (context, index) {
        final event = events[index];
        return ListTile(title: Text(event), onTap: toEventDetail);
      },
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
        title: const Text('個人任務履歷'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.brown,
          indicatorColor: Colors.amberAccent,
          tabs: const [Tab(text: '進行中的任務'), Tab(text: '參加過的任務')],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          buildEventList(ongoingEvents, isLoadingOngoing),
          buildEventList(pastEvents, isLoadingPast),
        ],
      ),
    );
  }
}
