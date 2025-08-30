// 實機之後跑完再看看狀況，可能需要一個報到按鈕

import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:flutter_frontend/config.dart';
import 'package:flutter_frontend/api_client.dart';

import 'personal_event_list.dart';

class FullEvent {
  final int id;
  final String title;
  final String type;
  final String location;
  final String address;
  final String mainOrganizer;
  final List<String> coOrganizers;
  final DateTime startTime;
  final DateTime endTime;
  final DateTime signupDeadline;
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

  factory FullEvent.fromJson(Map<String, dynamic> json) {
    return FullEvent(
      id: json['id'],
      title: json['title'],
      type: json['type'],
      location: json['location'],
      address: json['address'],
      mainOrganizer: json['main_organizer'],
      coOrganizers: List<String>.from(json['co_organizers'] ?? []),
      startTime: DateTime.parse(json['start_time']),
      endTime: DateTime.parse(json['end_time']),
      signupDeadline: DateTime.parse(json['signup_deadline']),
      status: json['status'],
      participants: json['participants'],
      description: json['description'] ?? '（無活動介紹）',
    );
  }
}

class PersonalEventDetailPage extends StatefulWidget {
  final Event event; // 傳入簡略資料（包含 id）

  const PersonalEventDetailPage({super.key, required this.event});

  @override
  State<PersonalEventDetailPage> createState() => _EventDetailPageState();
}

class _EventDetailPageState extends State<PersonalEventDetailPage> {
  late Future<FullEvent> _eventFuture;
  bool isFavorite = false;
  bool _busyFavorite = false;
  bool _busyJoin = false;
  bool _joined = false;
  int? _participantsOverride; // 成功報名後，前端+1 顯示

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
      final map = json.decode(utf8.decode(resp.bodyBytes)) as Map<String, dynamic>;
      return FullEvent.fromJson(map);
    } else {
      throw Exception('載入詳情失敗 (${resp.statusCode})');
    }
  }

  String formatDateTime(DateTime dt) {
    return "${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} "
           "${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";
  }

  Future<void> _handleFavorite(int eventId) async {
    if (_busyFavorite) return;
    setState(() => _busyFavorite = true);

    final apiClient = ApiClient();
    await apiClient.init();

    final url = ApiPath.addCharityEventUserSave(eventId);

    try {
      final resp = await apiClient.post(url, {}).timeout(const Duration(seconds: 10));
      if (resp.statusCode == 200) {
        setState(() => isFavorite = true);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("已加入收藏")),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("加入收藏失敗：${resp.statusCode}")),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("加入收藏時發生錯誤：$e")),
        );
      }
    } finally {
      if (mounted) setState(() => _busyFavorite = false);
    }
  }

  Future<void> _handleJoin(FullEvent event) async {
    if (_busyJoin || _joined) return;
    setState(() => _busyJoin = true);

    final apiClient = ApiClient();
    await apiClient.init();

    final url = ApiPath.addCharityEventUserJoin(event.id);

    try {
      final resp = await apiClient.post(url, {}).timeout(const Duration(seconds: 10));
      if (resp.statusCode == 200) {
        setState(() {
          _joined = true;
          _participantsOverride = (event.participants) + 1;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("報名成功！")),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("報名失敗：${resp.statusCode}")),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("報名時發生錯誤：$e")),
        );
      }
    } finally {
      if (mounted) setState(() => _busyJoin = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("活動詳情"),
        actions: [
          FutureBuilder<FullEvent>(
            future: _eventFuture,
            builder: (context, snapshot) {
              // 收藏按鈕在資料載入完才顯示可按
              final enabled = snapshot.hasData && !_busyFavorite && !isFavorite;
              return IconButton(
                tooltip: isFavorite ? "已收藏" : "加入收藏",
                onPressed: enabled
                    ? () => _handleFavorite(widget.event.id)
                    : null,
                icon: Icon(isFavorite ? Icons.star : Icons.star_border),
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
          final participantsShown = _participantsOverride ?? event.participants;

          return Padding(
            padding: const EdgeInsets.all(20),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(event.title,
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  Text("主辦單位：${event.mainOrganizer}"),
                  if (event.coOrganizers.isNotEmpty)
                    Text("協辦單位：${event.coOrganizers.join(', ')}"),
                  const SizedBox(height: 16),
                  Text("活動類型：${event.type}"),
                  Text("活動地區：${event.location}"),
                  Text("地址：${event.address}"),
                  const SizedBox(height: 16),
                  Text("活動時間："),
                  Text("${formatDateTime(event.startTime)} ～ ${formatDateTime(event.endTime)}"),
                  const SizedBox(height: 8),
                  Text("報名截止：${formatDateTime(event.signupDeadline)}"),
                  Text("狀態：${event.status}"),
                  Text("目前報名人數：$participantsShown"),
                  const SizedBox(height: 24),
                  const Text("活動介紹", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(event.description),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      icon: _joined ? const Icon(Icons.check_circle) : const Icon(Icons.check_circle_outline),
                      label: Text(_joined ? "已報名" : "我要參加"),
                      onPressed: (_busyJoin || _joined) ? null : () => _handleJoin(event),
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
}
