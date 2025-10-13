import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:flutter_frontend/config.dart';
import 'package:flutter_frontend/api_client.dart';
import 'charity_co-organizer_list.dart';
import 'charity_event_list.dart';
import 'charity_edit_event.dart';

class FullEvent {
  final int id;
  final String title;
  final String type;
  final String location;
  final String address;
  final String mainOrganizer;
  final List<String> coOrganizers;
  final DateTime? startTime;
  final DateTime? endTime;
  final DateTime? signupDeadline;
  final String status;
  final int participants;
  final String description;
  final int inviteCode;

  FullEvent({
    required this.id,
    required this.title,
    required this.type,
    required this.location,
    required this.address,
    required this.mainOrganizer,
    required this.coOrganizers,
    required this.startTime,
    required this.endTime,
    required this.signupDeadline,
    required this.status,
    required this.participants,
    required this.description,
    required this.inviteCode,
  });

  static int _toIntCount(dynamic v) {
    if (v == null) return 0;
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v) ?? 0;
    if (v is List) return v.length;
    return 0;
  }

  static DateTime? _tryParse(dynamic v) {
    if (v == null) return null;
    final s = v.toString();
    if (s.isEmpty) return null;
    try {
      return DateTime.parse(s);
    } catch (_) {
      return null;
    }
  }

  factory FullEvent.fromJson(Map<String, dynamic> json) {
    final inviteStr = json['inviteCode']?.toString() ?? '0';
    return FullEvent(
      id: (json['id'] as num?)?.toInt() ?? 0,
      title: (json['name'] ?? json['title'] ?? '').toString(),
      type: (json['eventType'] ?? json['type'] ?? '').toString(),
      location: (json['location'] ?? json['city'] ?? '此為線上活動').toString(),
      address: (json['address'] ?? '線上').toString(),
      mainOrganizer: (json['mainOrganizer'] ?? '').toString(),
      coOrganizers:
          (json['coOrganizers'] is List)
              ? List<String>.from(
                (json['coOrganizers'] as List).map((e) => e.toString()),
              )
              : <String>[],
      startTime: _tryParse(json['startTime']),
      endTime: _tryParse(json['endTime']),
      signupDeadline: _tryParse(json['signupDeadline']),
      status: (json['statusDisplay'] ?? '').toString(),
      participants: _toIntCount(json['participants']),
      description: (json['description'] ?? '（無活動介紹）').toString(),
      inviteCode: int.tryParse(inviteStr) ?? 0,
    );
  }
}

class CharityEventDetailPage extends StatefulWidget {
  final CharityEvent event;

  const CharityEventDetailPage({super.key, required this.event});

  @override
  State<CharityEventDetailPage> createState() => _CharityEventDetailPageState();
}

class _CharityEventDetailPageState extends State<CharityEventDetailPage> {
  late Future<FullEvent> _eventFuture;
  bool _deleting = false;

  @override
  void initState() {
    super.initState();
    _eventFuture = fetchDetail(widget.event.id);
  }

  Future<FullEvent> fetchDetail(int id) async {
    final apiClient = ApiClient();
    await apiClient.init();
    final url = ApiPath.charityEventDetail(id);
    final resp = await apiClient.get(url);
    if (resp.statusCode == 200) {
      final root = json.decode(resp.body) as Map<String, dynamic>;
      final map =
          (root['event'] is Map<String, dynamic>)
              ? root['event'] as Map<String, dynamic>
              : root;
      return FullEvent.fromJson(map);
    } else {
      throw Exception('載入詳情失敗 (${resp.statusCode})');
    }
  }

  Future<void> _deleteEvent(String eventName) async {
    if (_deleting) return;
    setState(() => _deleting = true);
    try {
      final apiClient = ApiClient();
      await apiClient.init();
      final url = ApiPath.deleteCharityEvent;
      final body = {"eventName": eventName};
      final resp = await apiClient.post(url, body);

      if (resp.statusCode == 200 || resp.statusCode == 201) {
        final data = json.decode(resp.body);
        final success = (data is Map && data['success'] == true);
        final msg =
            (data is Map && data['message'] is String)
                ? data['message'] as String
                : '刪除成功';

        if (success && mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(msg)));
          Navigator.of(context).pop(true);
          return;
        } else {
          throw Exception(msg);
        }
      } else {
        throw Exception('刪除失敗（${resp.statusCode}）');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('刪除失敗：$e')));
      }
    } finally {
      if (mounted) setState(() => _deleting = false);
    }
  }

  Future<void> _confirmAndDelete(String eventName) async {
    final ok = await showDialog<bool>(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text('確認刪除'),
            content: Text('確定要刪除「$eventName」嗎？此操作無法復原。'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('取消'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('刪除'),
              ),
            ],
          ),
    );
    if (ok == true) await _deleteEvent(eventName);
  }

  String formatDateTime(DateTime? dt) {
    if (dt == null) return "未定義";
    return "${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} "
        "${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";
  }

  @override
  Widget build(BuildContext context) {
    const bgColor = Color(0xFFFDF8EC); // 米白
    const borderColor = Color.fromRGBO(199, 167, 108, 1); // 金黃
    const textColor = Color(0xFF4A3C1A); // 深棕

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: const Text("活動詳情"),
        backgroundColor: borderColor,
        foregroundColor: textColor,
        automaticallyImplyLeading: true,
      ),
      body: FutureBuilder<FullEvent>(
        future: _eventFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text("錯誤：${snapshot.error}"));
          }

          final event = snapshot.data!;
          const titleColor = Color(0xFF4A3C1A);
          const subtitleColor = Color(0xFF7B5E3C);
          const cardBgColor = Color(0xFFFFF9F0);
          const buttonColor = Color.fromRGBO(208, 179, 138, 1);

          return Padding(
            padding: const EdgeInsets.all(16),
            child: SingleChildScrollView(
              child: Card(
                color: cardBgColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: const BorderSide(color: Color(0xFFDAB67D), width: 1.5),
                ),
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 24,
                    horizontal: 20,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // 任務名稱
                      Text(
                        event.title,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: titleColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "${event.type} | ${event.location}",
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 14,
                          color: subtitleColor,
                        ),
                      ),
                      const Divider(
                        height: 24,
                        thickness: 1,
                        color: Color(0xFFDAB67D),
                      ),

                      // 資訊列表
                      _infoRow(
                        "任務時間",
                        "${formatDateTime(event.startTime)} ～ ${formatDateTime(event.endTime)}",
                      ),
                      _infoRow("任務地點", "${event.location} ${event.address}"),
                      _infoRow("委託所", event.mainOrganizer),
                      _infoRow("參與人數", "${event.participants} 位冒險者"),
                      const SizedBox(height: 16),

                      // 活動介紹
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          "任務詳情",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: titleColor,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        event.description,
                        style: const TextStyle(fontSize: 14, color: titleColor),
                        textAlign: TextAlign.left,
                      ),
                      const SizedBox(height: 24),

                      // 底部按鈕
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () async {
                                final updated = await Navigator.push<bool?>(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (_) => CharityCoOrganizerListPage(
                                          charityEventName: event.title,
                                        ),
                                  ),
                                );
                                if (updated == true)
                                  setState(
                                    () => _eventFuture = fetchDetail(event.id),
                                  );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: buttonColor,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: const Text(
                                "查看協辦單位",
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () async {
                                final updated = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (_) => CharityEditEventPage(
                                          eventId: event.id,
                                        ),
                                  ),
                                );
                                if (updated == true)
                                  setState(
                                    () => _eventFuture = fetchDetail(event.id),
                                  );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: titleColor,
                                side: const BorderSide(color: buttonColor),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: const Text(
                                "編輯任務",
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ElevatedButton(
                              onPressed:
                                  _deleting
                                      ? null
                                      : () => _confirmAndDelete(event.title),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color.fromARGB(
                                  255,
                                  187,
                                  80,
                                  78,
                                ),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: Text(
                                _deleting ? "刪除中…" : "刪除任務",
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

Widget _infoRow(String label, String value) {
  const labelColor = Color(0xFF4A3C1A);
  const valueColor = Color(0xFF7B5E3C);
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: Text(
            "$label：",
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: labelColor,
            ),
          ),
        ),
        Expanded(
          flex: 3,
          child: Text(value, style: const TextStyle(color: valueColor)),
        ),
      ],
    ),
  );
}
