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
        builder:
            (context) =>
                PersonalJournalDetailPage(eventId: event['charityEvent']),
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

      final urlOn = ApiPath.userCharityEventsOngoingJoin;
      final urlUp = ApiPath.userCharityEventsUpcomingJoin;

      final responseOn = await apiClient.get(urlOn);
      final responseUp = await apiClient.get(urlUp);

      if (responseOn.statusCode == 200 && responseUp.statusCode == 200) {
        final dataOn = jsonDecode(responseOn.body);
        final dataUp = jsonDecode(responseUp.body);

        final List eventsOn = dataOn['events'] ?? [];
        final List eventsUp = dataUp['events'] ?? [];

        final List<Map<String, dynamic>> combined = [
          ...eventsOn.map(
            (e) => {
              'id': e['id'],
              'title': e['eventName'],
              'joinType': e['joinType'],
              'charityEvent': e['charityEvent'],
              'status': '正在進行',
            },
          ),
          ...eventsUp.map(
            (e) => {
              'id': e['id'],
              'title': e['eventName'],
              'joinType': e['joinType'],
              'charityEvent': e['charityEvent'],
              'status': '即將到來',
            },
          ),
        ];

        setState(() {
          ongoingEvents = combined;
        });
      } else {
        debugPrint('取得進行中或即將到來任務失敗');
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

      final urlFin = ApiPath.userCharityEventsFinishedJoin;
      final urlDel = ApiPath.userCharityEventsDeletedJoin;

      final responseFin = await apiClient.get(urlFin);
      final responseDel = await apiClient.get(urlDel);

      if (responseFin.statusCode == 200 && responseDel.statusCode == 200) {
        final dataFin = jsonDecode(responseFin.body);
        final dataDel = jsonDecode(responseDel.body);

        final List eventsFin = dataFin['events'] ?? [];
        final List eventsDel = dataDel['events'] ?? [];

        final List<Map<String, dynamic>> combined = [
          ...eventsFin.map(
            (e) => {
              'id': e['id'],
              'title': e['eventName'],
              'joinType': e['joinType'],
              'charityEvent': e['charityEvent'],
              'status': '已結束',
            },
          ),
          ...eventsDel.map(
            (e) => {
              'id': e['id'],
              'title': e['eventName'],
              'joinType': e['joinType'],
              'charityEvent': e['charityEvent'],
              'status': '已刪除',
            },
          ),
        ];

        setState(() {
          pastEvents = combined;
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
    final brown = Colors.brown[800]!;

    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (events.isEmpty) {
      return const Center(
        child: Text(
          '目前沒有任務，快去探索看看吧!',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Colors.brown,
          ),
        ),
      );
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
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: events.length,
        itemBuilder: (context, index) {
          final event = events[index];
          final status = event['status'] ?? '';

          // 顏色與互動設定
          final Color labelColor = const Color.fromARGB(255, 199, 138, 33);
          final Color cardBG = Colors.white;

          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cardBG,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                ),
              ],
              border: Border.all(
                color: Colors.brown.withOpacity(0.15),
                width: 1,
              ),
            ),
            child: InkWell(
              onTap: () {
                if (status != '已刪除') {
                  toEventDetail(event);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('已刪除任務無法查看詳細內容')),
                  );
                }
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    event['title'] ?? '未命名任務',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: brown,
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Status label
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: labelColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: labelColor),
                    ),
                    child: Text(
                      status,
                      style: TextStyle(
                        color: labelColor,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final brown = Colors.brown[800]!;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Color(0xFFe6ccb2),
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.only(left: 12.0, top: 6.0, bottom: 6.0),
          child: CircleAvatar(
            backgroundColor: Colors.amber,
            child: IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back_ios_new, color: Colors.brown),
            ),
          ),
        ),
        title: Text(
          '個人任務履歷',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: brown,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: brown,
          labelStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
          unselectedLabelColor: brown,
          indicatorColor: Colors.amber,
          indicatorWeight: 3,
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
