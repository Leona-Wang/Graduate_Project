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
  final DateTime? startTime;
  final DateTime? endTime;
  final DateTime? signupDeadline;
  final String status;
  final int joinAmount;
  final int saveAmount;
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
    required this.joinAmount,
    required this.saveAmount,
    required this.description,
  });

  static String _toString(dynamic v, [String fallback = '']) {
    if (v == null) return fallback;
    return v.toString();
  }

  static List<String> _toStringList(dynamic v) {
    if (v is List) return v.map((e) => e.toString()).toList();
    return const <String>[];
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

  factory FullEvent.fromJson(Map<String, dynamic> json) {
    return FullEvent(
      id: (json['id'] as num?)?.toInt() ?? 0,
      title: _toString(json['name'], '未命名活動'),
      type: _toString(json['eventType'], '未分類'),
      location: _toString(json['location'], '未知地點'), //地區
      address: _toString(json['address'], '（無地址資料）'), //地址
      mainOrganizer: _toString(json['mainOrganizer']), //主辦單位
      coOrganizers: _toStringList(json['coOrganizers']),
      startTime: _parseDate(json['startTime']),
      endTime: _parseDate(json['endTime']),
      signupDeadline: _parseDate(json['signupDeadline']),
      status: _toString(json['statusDisplay'], '未知狀態'),
      joinAmount: _toIntCount(json['joinAmount']),
      saveAmount: _toIntCount(json['saveAmount']),
      description: _toString(json['description'], '（無活動介紹）'),
    );
  }
}

class PersonalEventDetailPage extends StatefulWidget {
  final Event event;

  const PersonalEventDetailPage({super.key, required this.event});

  @override
  State<PersonalEventDetailPage> createState() =>
      _PersonalEventDetailPageState();
}

class _PersonalEventDetailPageState extends State<PersonalEventDetailPage> {
  late Future<FullEvent> eventFuture;
  bool isFavorite = false;
  bool busyFavorite = false;
  bool busyJoin = false;
  bool joined = false;
  int? participantsOverride;

  @override
  void initState() {
    super.initState();
    eventFuture = fetchDetail(widget.event.id);
  }

  Future<FullEvent> fetchDetail(int id) async {
    final apiClient = ApiClient();
    await apiClient.init();
    final url = ApiPath.charityEventDetail(id);
    final resp = await apiClient.get(url);
    //print(resp.body);
    if (resp.statusCode == 200) {
      final map =
          json.decode(utf8.decode(resp.bodyBytes)) as Map<String, dynamic>;
      final raw = (map['event'] is Map<String, dynamic>) ? map['event'] : map;
      return FullEvent.fromJson(raw);
    } else {
      throw Exception('載入詳情失敗 (${resp.statusCode})');
    }
  }

  String formatDateTime(DateTime? dt) {
    if (dt == null) return '未定義';
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} '
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  /*
  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }
*/

  Future<void> handleFavorite(int eventId) async {
    if (busyFavorite || isFavorite || joined) return;

    if (joined) {
      await _showResultDialog(context, '已參加任務，無法收藏。');
      return;
    }

    final confirmed = await _confirmAction(context, '確定收藏這個任務嗎？');
    if (!confirmed) return;

    setState(() => busyFavorite = true);

    final apiClient = ApiClient();
    await apiClient.init();

    final url = ApiPath.addCharityEventUserSave(eventId);

    try {
      final resp = await apiClient.post(url, {});
      if (resp.statusCode == 200 || resp.statusCode == 201) {
        setState(() => isFavorite = true);

        await _showResultDialog(context, '已成功收藏任務！');

        setState(() {
          eventFuture = fetchDetail(widget.event.id);
        });
      }
    } catch (e) {
      debugPrint('加入收藏錯誤：$e');
    } finally {
      setState(() => busyFavorite = false);
    }
  }

  Future<void> handleUnfavorite(int eventId) async {
    if (busyFavorite || !isFavorite) return;

    final confirmed = await _confirmAction(context, '確定要移除收藏嗎？');
    if (!confirmed) return;

    setState(() => busyFavorite = true);

    final apiClient = ApiClient();
    await apiClient.init();

    final url = ApiPath.addCharityEventUserRevert(eventId);

    try {
      final resp = await apiClient.post(url, {});
      print('🔹 回傳狀態: ${resp.statusCode}');
      print('🔹 回傳內容: ${resp.body}');
      if (resp.statusCode == 200 || resp.statusCode == 204) {
        setState(() => isFavorite = false);

        await _showResultDialog(context, '已取消收藏');

        setState(() {
          eventFuture = fetchDetail(widget.event.id);
        });
      }
    } catch (e) {
      debugPrint('取消收藏錯誤：$e');
    } finally {
      setState(() => busyFavorite = false);
    }
  }

  Future<void> handleJoin(FullEvent event) async {
    if (busyJoin || joined || isFavorite) return;

    final confirmed = await _confirmAction(context, '確定參加這個任務嗎？');
    if (!confirmed) return;

    setState(() => busyJoin = true);

    final apiClient = ApiClient();
    await apiClient.init();

    final url = ApiPath.addCharityEventUserJoin(event.id);

    try {
      final resp = await apiClient.post(url, {});
      if (resp.statusCode == 200 || resp.statusCode == 201) {
        setState(() {
          joined = true;
        });
        await _showResultDialog(context, '報名成功！');

        setState(() {
          eventFuture = fetchDetail(widget.event.id);
        });
      }
    } catch (e) {
      debugPrint('報名錯誤：$e');
    } finally {
      setState(() => busyJoin = false);
    }
  }

  Future<void> handleUnjoin(FullEvent event) async {
    if (busyJoin || !joined) return;

    final confirmed = await _confirmAction(context, '確定取消參加這個任務嗎？');
    if (!confirmed) return;

    setState(() => busyJoin = true);

    final apiClient = ApiClient();
    await apiClient.init();

    final url = ApiPath.addCharityEventUserRevert(event.id);

    try {
      final resp = await apiClient.post(url, {});
      if (resp.statusCode == 200 || resp.statusCode == 204) {
        setState(() {
          joined = false;
        });
        await _showResultDialog(context, '已成功取消任務。');
        setState(() {
          eventFuture = fetchDetail(widget.event.id);
        });
      }
    } catch (e) {
      debugPrint('取消報名錯誤：$e');
    } finally {
      setState(() => busyJoin = false);
    }
  }

  //確認是否值行動作用popup
  Future<bool> _confirmAction(BuildContext context, String message) async {
    return await showDialog<bool>(
          context: context,
          builder:
              (ctx) => AlertDialog(
                title: const Text('確認動作'),
                content: Text(message),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: const Text('取消'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    child: const Text('確定'),
                  ),
                ],
              ),
        ) ??
        false;
  }

  //確認執行結果popup
  Future<void> _showResultDialog(BuildContext context, String message) async {
    await showDialog<void>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('提示'),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('確定'),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const parchmentColor = Color(0xFFF8F4E3); //底色
    const borderColor = Color.fromRGBO(199, 167, 108, 1); //邊框主題色
    const textMain = Color(0xFF4A3C1A); //文字顏色

    return Scaffold(
      backgroundColor: parchmentColor,
      appBar: AppBar(
        backgroundColor: borderColor,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          "任務詳情",
          style: TextStyle(color: textMain, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: textMain),
      ),
      body: FutureBuilder<FullEvent>(
        future: eventFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('錯誤：${snapshot.error}'));
          }
          if (!snapshot.hasData) {
            return const Center(child: Text('查無任務資料'));
          }

          final event = snapshot.data!;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFFDF8EC),
                border: Border.all(color: borderColor, width: 2),
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: Colors.brown.withOpacity(0.25),
                    offset: const Offset(3, 3),
                    blurRadius: 8,
                  ),
                ],
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  //標題
                  Center(
                    child: Column(
                      children: [
                        Text(
                          event.title,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: textMain,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "${event.type}｜${event.location}",
                          style: const TextStyle(color: Color(0xFF7A6543)),
                        ),
                        const SizedBox(height: 10),
                        Container(width: 100, height: 2, color: borderColor),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  _infoLine(
                    "任務時間",
                    "${formatDateTime(event.startTime)} ～ ${formatDateTime(event.endTime)}",
                  ),
                  _infoLine(
                    "任務地點",
                    "${event.location} ${event.address.isNotEmpty ? event.address : '（無地址資料）'}",
                  ),
                  _infoLine(
                    "委託所",
                    "${event.mainOrganizer}${event.coOrganizers.isNotEmpty ? "、${event.coOrganizers.join(", ")}" : ""}",
                  ),
                  _infoLine("參與人數", "${event.joinAmount} 位冒險者"),
                  _infoLine('收藏人數', "${event.saveAmount} 位冒險者"),
                  const SizedBox(height: 20),

                  const Text(
                    "任務詳情",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: textMain,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    event.description,
                    style: const TextStyle(
                      fontSize: 15,
                      height: 1.5,
                      color: textMain,
                    ),
                  ),

                  const SizedBox(height: 30),
                  _rpgButton(
                    label: joined ? "取消任務" : "接受任務",
                    onPressed:
                        () => joined ? handleUnjoin(event) : handleJoin(event),
                    filled: true,
                  ),
                  const SizedBox(height: 12),
                  _rpgButton(
                    label: isFavorite ? "移除收藏" : (joined ? "已參加，無法收藏" : "收藏任務"),
                    onPressed:
                        joined
                            ? () {} // 禁用，點了沒反應
                            : () =>
                                isFavorite
                                    ? handleUnfavorite(widget.event.id)
                                    : handleFavorite(widget.event.id),
                    filled: false,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _infoLine(String title, String content) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(
            fontSize: 15,
            height: 1.5,
            color: Color(0xFF4A3C1A),
          ),
          children: [
            TextSpan(
              text: "$title：",
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            TextSpan(text: content),
          ],
        ),
      ),
    );
  }

  Widget _rpgButton({
    required String label,
    required VoidCallback onPressed,
    bool filled = true,
  }) {
    const gold = Color(0xFFD7C09A);
    const textMain = Color(0xFF4A3C1A);

    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: filled ? gold : Colors.transparent,
          foregroundColor: textMain,
          shadowColor: Colors.brown.withOpacity(0.3),
          elevation: filled ? 3 : 0,
          side: BorderSide(color: gold, width: 2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        onPressed: onPressed,
        child: Text(
          label,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
