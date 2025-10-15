import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_frontend/api_client.dart';
import 'package:flutter_frontend/config.dart';
import 'package:flutter_frontend/screens/personal_screens/personal_journal_detail.dart';

class PersonalEventJournalPage extends StatefulWidget {
  const PersonalEventJournalPage({super.key});

  @override
  State<PersonalEventJournalPage> createState() =>
      PersonalEventJournalPageState();
}

class PersonalEventJournalPageState extends State<PersonalEventJournalPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  List<Map<String, dynamic>> ongoingEvents = [];
  List<Map<String, dynamic>> pastEvents = [];

  bool isLoadingOngoing = true;
  bool isLoadingPast = true;

  void toEventDetail(Map<String, dynamic> event) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PersonalJournalDetailPage(eventId: event['id']),
      ),
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

  //未到期的任務
  Future<void> fetchOngoingEvents() async {
    setState(() => isLoadingOngoing = true);
    try {
      final apiClient = ApiClient();
      await apiClient.init();

      final url = ApiPath.userCharityEventsUpcomingJoin;
      final response = await apiClient.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List events = data['events'] ?? [];

        setState(() {
          ongoingEvents =
              events
                  .map(
                    (e) => {
                      'id': e['id'],
                      'title': e['eventName'],
                      'joinType': e['joinType'], //這是啥
                      'charityEvent': e['charityEvent'], //這又是啥
                    },
                  )
                  .toList();
        });
      } else {
        debugPrint('取得進行中任務失敗');
      }
    } catch (e) {
      debugPrint('錯誤: $e');
    } finally {
      setState(() => isLoadingOngoing = false);
    }
  }

  //已過期的任務
  Future<void> fetchPastEvents() async {
    setState(() => isLoadingPast = true);

    try {
      final apiClient = ApiClient();
      await apiClient.init();

      final url = ApiPath.userCharityEventsFinishedJoin;
      final response = await apiClient.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List events = data['events'] ?? [];

        setState(() {
          pastEvents =
              events
                  .map(
                    (e) => {
                      'id': e['id'],
                      'title': e['eventName'],
                      'joinType': e['joinType'],
                      'charityEvent': e['charityEvent'],
                    },
                  )
                  .toList();
        });
      } else {
        debugPrint('取得已過期任務失敗');
      }
    } catch (e) {
      debugPrint('錯誤: $e');
    } finally {
      setState(() => isLoadingPast = false);
    }
  }

  Widget buildEventList(List<Map<String, dynamic>> events, bool isLoading) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (events.isEmpty) {
      return const Center(child: Text('目前沒有任務，快去探索看看吧!'));
    }
    return RefreshIndicator(
      onRefresh: () async {
        if (_tabController.index == 0) {
          await fetchOngoingEvents();
        } else {
          await fetchPastEvents();
        }
      },
      child: ListView.builder(
        itemCount: events.length,
        itemBuilder: (context, index) {
          final event = events[index];

          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 3,
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              title: Text(
                event['title'] ?? '未命名任務',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text('狀態: ${event['joinType'] ?? "未知"}'),
              onTap: () => toEventDetail(event),
            ),
          );
        },
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
        title: const Text('個人任務履歷'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.brown,
          indicatorColor: Colors.amberAccent,
          tabs: const [Tab(text: '進行中的任務'), Tab(text: '已結束的任務')],
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
