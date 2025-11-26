import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:flutter_frontend/config.dart';
import 'package:flutter_frontend/api_client.dart';
import 'package:flutter_frontend/screens/charity_screens/charity_qr_code.dart';
import 'charity_co-organizer_list.dart';
import 'charity_event_list.dart';
import 'charity_edit_event.dart';
import 'package:flutter/services.dart';

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
  final int joinAmount;
  final int saveAmount;
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
    required this.joinAmount,
    required this.saveAmount,
    required this.description,
    required this.inviteCode,
  });

  static String _toString(dynamic v, [String fallback = '']) {
    if (v == null) return fallback;
    return v.toString();
  }

  static int _toIntCount(dynamic v) {
    if (v == null) return 0;
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v) ?? 0;
    if (v is List) return v.length;
    return 0;
  }

  static DateTime? _parseDate(dynamic v) {
    if (v == null) return null;
    final s = v.toString().trim();
    if (s.isEmpty) return null;
    try {
      return DateTime.parse(s);
    } catch (_) {
      return null;
    }
  }

  /*
  static DateTime? _tryParse(dynamic v) {
    if (v == null) return null;
    final s = v.toString();
    if (s.isEmpty) return null;
    try {
      return DateTime.parse(s);
    } catch (_) {
      return null;
    }
  }*/

  factory FullEvent.fromJson(Map<String, dynamic> json) {
    final inviteStr = json['inviteCode']?.toString() ?? '0';
    return FullEvent(
      id: (json['id'] as num?)?.toInt() ?? 0,
      title: _toString(json['name'], '未命名活動'),
      type: _toString(json['eventType'], '未分類'),
      location: _toString(json['location'], '未知地點'), //地區
      address: _toString(json['address'], '（無地址資料）'), //地址
      mainOrganizer: _toString(json['mainOrganizer']), //主辦單位
      coOrganizers:
          (json['coOrganizers'] is List)
              ? List<String>.from(
                (json['coOrganizers'] as List).map((e) => e.toString()),
              )
              : <String>[],
      startTime: _parseDate(json['startTime']),
      endTime: _parseDate(json['endTime']),
      signupDeadline: _parseDate(json['signupDeadline']),
      status: _toString(json['statusDisplay'], '未知狀態'),
      joinAmount: _toIntCount(json['joinAmount']),
      saveAmount: _toIntCount(json['saveAmount']),
      description: _toString(json['description'], '（無活動介紹）'),
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
    final brown = Colors.brown[800]!;
    final brownLight = Colors.brown[600];

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: const Color(0xFFe6ccb2),
        elevation: 0,
        centerTitle: true,
        title: Text(
          "活動詳情",
          style: TextStyle(
            color: brown,
            fontSize: 22,
            fontWeight: FontWeight.w800,
          ),
        ),
        iconTheme: IconThemeData(color: brown),
        foregroundColor: brown,
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
          final titleColor = brown;
          final subtitleColor = brownLight;
          const buttonBorderColor = Color(0xFFFFC977);

          return Padding(
            padding: const EdgeInsets.all(16),
            child: SingleChildScrollView(
              child: Card(
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                  side: BorderSide(
                    color: Colors.brown.withOpacity(0.15),
                    width: 1.5,
                  ),
                ),
                elevation: 5,
                shadowColor: Colors.black.withOpacity(0.08),
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
                        style: TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.w800,
                          color: titleColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "${event.type} | ${event.location}",
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 18, color: subtitleColor),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        width: 100,
                        height: 2,
                        color: Colors.amber[600],
                      ),
                      const SizedBox(height: 20),

                      // 資訊列表
                      _infoRow(
                        "任務時間",
                        "${formatDateTime(event.startTime)} ～ ${formatDateTime(event.endTime)}",
                      ),
                      _infoRow("任務地點", event.address),
                      _infoRow("委託所", event.mainOrganizer),
                      _infoRow("參與人數", "${event.saveAmount} 位冒險者"),
                      _infoRow('收藏人數', "${event.joinAmount} 位冒險者"),

                      const SizedBox(height: 20),

                      //邀請碼
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 2,
                              child: Text(
                                "邀請碼：",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: brown,
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 3,
                              child: Row(
                                children: [
                                  Text(
                                    event.inviteCode == 0
                                        ? "尚未產生"
                                        : event.inviteCode.toString(),
                                    style: TextStyle(
                                      fontSize: 18,
                                      color: brown,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.copy,
                                      size: 18,
                                      color: Color(0xFFC7A76C),
                                    ),
                                    tooltip: "複製邀請碼",
                                    onPressed: () {
                                      if (event.inviteCode != 0) {
                                        Clipboard.setData(
                                          ClipboardData(
                                            text: event.inviteCode.toString(),
                                          ),
                                        );
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text("已複製邀請碼！"),
                                          ),
                                        );
                                      }
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // 活動介紹
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          "任務詳情",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: titleColor,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        event.description,
                        style: TextStyle(
                          fontSize: 15,
                          height: 1.5,
                          color: brownLight,
                        ),
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
                                backgroundColor: Colors.amber,
                                foregroundColor: brown,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
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
                                foregroundColor: brown,
                                side: const BorderSide(
                                  color: buttonBorderColor,
                                  width: 2,
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
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
                                backgroundColor: const Color(0xFFBF4C4A),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                elevation: 2,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
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
                      if (event.status == '進行中') ...[
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => CharityQRCodePage(),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.amber[700],
                              foregroundColor: Colors.brown[900],
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              elevation: 3,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: const Text(
                              '參加者報到',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                      ],
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
  final brown = Colors.brown[800]!;
  final valueColor = Colors.brown[700];

  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: Text(
            "$label：",
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 16,
              color: brown,
            ),
          ),
        ),
        Expanded(
          flex: 3,
          child: Text(
            value,
            style: TextStyle(fontSize: 16, color: valueColor, height: 1.4),
          ),
        ),
      ],
    ),
  );
}
