import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:flutter_frontend/config.dart';
import 'package:flutter_frontend/api_client.dart';

import 'charity_event_list.dart';
import 'charity_edit_event.dart';
import 'charity_co-organizer.dart';

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
  });

  static int _toIntCount(dynamic v) {
    if (v == null) return 0;
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v) ?? 0;
    if (v is List) return v.length; // 後端給名單陣列時，取長度
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
    return FullEvent(
      id: (json['id'] as num?)?.toInt() ?? 0,
      title: (json['name'] ?? json['title'] ?? '').toString(),
      type: (json['eventType'] ?? json['type'] ?? '').toString(),
      location: (json['location'] ?? json['city'] ?? '').toString(),
      address: (json['address'] ?? '').toString(),
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
      status: (json['status'] ?? '').toString(),
      participants: _toIntCount(json['participants']),
      description: (json['description'] ?? '（無活動介紹）').toString(),
    );
  }
}

class CharityEventDetailPage extends StatefulWidget {
  final CharityEvent event; // 傳入簡略資料（包含 id）

  const CharityEventDetailPage({super.key, required this.event});

  @override
  State<CharityEventDetailPage> createState() => _EventDetailPageState();
}

class _EventDetailPageState extends State<CharityEventDetailPage> {
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

      final url = ApiPath.deleteCharityEvent; // /charity/event/delete/
      final body = {"eventName": eventName};
      final resp = await apiClient.post(url, body);

      if (resp.statusCode == 200 || resp.statusCode == 201) {
        final data = json.decode(resp.body);
        final success = (data is Map && data['success'] == true);
        final msg =
            (data is Map && data['message'] is String)
                ? data['message'] as String
                : '刪除成功';

        if (success) {
          if (mounted) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(msg)));
            Navigator.of(context).pop(true); // 回到上一頁並回傳成功，方便列表刷新
          }
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

    if (ok == true) {
      await _deleteEvent(eventName);
    }
  }

  String formatDateTime(DateTime? dt) {
    if (dt == null) return "未定義";
    return "${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} "
        "${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("活動詳情"),
        actions: [
          // 編輯按鈕
          FutureBuilder<FullEvent>(
            future: _eventFuture,
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const SizedBox.shrink();
              final event = snapshot.data!;
              return IconButton(
                tooltip: '編輯活動',
                icon: const Icon(Icons.edit),
                onPressed: () async {
                  final updated = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CharityEditEventPage(eventId: event.id),
                    ),
                  );
                  if (updated == true) {
                    // 編輯完成後回來刷新詳情
                    setState(() {
                      _eventFuture = fetchDetail(event.id);
                    });
                  }
                },
              );
            },
          ),

          // 刪除按鈕
          FutureBuilder<FullEvent>(
            future: _eventFuture,
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const SizedBox.shrink();
              final event = snapshot.data!;
              return IconButton(
                tooltip: '刪除活動',
                onPressed:
                    _deleting ? null : () => _confirmAndDelete(event.title),
                icon:
                    _deleting
                        ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                        : const Icon(Icons.delete_outline),
              );
            },
          ),
        ],
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
          return Padding(
            padding: const EdgeInsets.all(20),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.title,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text("主辦單位：${event.mainOrganizer}"),
                  if (event.coOrganizers.isNotEmpty)
                    Text("協辦單位：${event.coOrganizers.join(', ')}"),
                  const SizedBox(height: 16),
                  Text("活動類型：${event.type}"),
                  Text("活動地區：${event.location}"),
                  Text("地址：${event.address}"),
                  const SizedBox(height: 16),
                  const Text("活動時間："),
                  Text(
                    "${formatDateTime(event.startTime)} ～ ${formatDateTime(event.endTime)}",
                  ),
                  const SizedBox(height: 8),
                  Text("報名截止：${formatDateTime(event.signupDeadline)}"),
                  Text("狀態：${event.status}"),
                  Text("目前報名人數：${event.participants}"),
                  const SizedBox(height: 24),
                  const Text(
                    "活動介紹",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(event.description),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
