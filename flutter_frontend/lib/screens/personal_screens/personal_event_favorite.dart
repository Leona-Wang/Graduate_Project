import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_frontend/api_client.dart';
import 'package:flutter_frontend/config.dart';
import 'package:flutter_frontend/screens/personal_screens/personal_favorite_detail.dart';

class PersonalEventFavoritePage extends StatefulWidget {
  const PersonalEventFavoritePage({super.key});

  @override
  State<PersonalEventFavoritePage> createState() =>
      PersonalEventFavoritePageState();
}

class PersonalEventFavoritePageState extends State<PersonalEventFavoritePage>
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
                PersonalFavoriteDetailPage(eventId: event['charityEvent']),
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

  //未到期任務
  Future<void> fetchOngoingEvents() async {
    setState(() => isLoadingOngoing = true);
    try {
      final apiClient = ApiClient();
      await apiClient.init();

      final urlOn = ApiPath.userCharityEventsOngoingSave;
      final urlUp = ApiPath.userCharityEventsUpcomingSave;

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

  //已到期任務+已刪除任務
  Future<void> fetchPastEvents() async {
    setState(() => isLoadingPast = true);

    try {
      final apiClient = ApiClient();
      await apiClient.init();

      final urlFin = ApiPath.userCharityEventsFinishedSave;
      final urlDel = ApiPath.userCharityEventsDeletedSave;

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
        debugPrint('取得已過期或已刪除任務失敗');
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
          final status = event['status'] ?? '';

          // 顏色與互動設定
          late Color cardColor;
          late Color labelColor;

          switch (status) {
            case '正在進行':
              cardColor = const Color.fromARGB(255, 255, 235, 205);
              labelColor = const Color.fromARGB(255, 239, 187, 109);
              break;
            case '即將到來':
              cardColor = const Color.fromARGB(255, 233, 198, 164);
              labelColor = const Color.fromARGB(255, 159, 121, 68);
              break;
            case '已結束':
              cardColor = const Color.fromARGB(255, 255, 235, 205);
              labelColor = const Color.fromARGB(255, 239, 187, 109);
              break;
            case '已刪除':
              cardColor = const Color.fromARGB(255, 233, 198, 164);
              labelColor = const Color.fromARGB(255, 159, 121, 68);
              break;
            default:
              cardColor = Colors.grey.shade50;
              labelColor = Colors.grey;
          }

          return Card(
            color: cardColor,
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
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: labelColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: labelColor),
                  ),
                  child: Text(
                    status,
                    style: TextStyle(
                      color: labelColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
              onTap: () {
                if (status != '已刪除') {
                  toEventDetail(event);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('已刪除任務無法查看詳細內容'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                }
              },
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
        title: const Text('個人任務收藏庫'),
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
