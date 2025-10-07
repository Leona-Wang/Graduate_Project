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
      title: _toString(json['title'] ?? json['name']),
      type: _toString(json['type'] ?? json['eventType']),
      location: _toString(json['location'] ?? json['city']),
      address: _toString(json['address']),
      mainOrganizer: _toString(json['mainOrganizer'] ?? json['main_organizer']),
      coOrganizers: _toStringList(json['coOrganizers'] ?? json['co_organizers']),
      startTime: _parseDate(json['startTime'] ?? json['start_time']),
      endTime: _parseDate(json['endTime'] ?? json['end_time']),
      signupDeadline: _parseDate(json['signupDeadline'] ?? json['signup_deadline']),
      status: _toString(json['statusDisplay']),
      participants: _toIntCount(json['participants']),
      description: _toString(json['description'], '（無活動介紹）'),
    );
  }
}

class PersonalEventDetailPage extends StatefulWidget {
  final Event event; // 從列表傳入的簡略資料（含 id）

  const PersonalEventDetailPage({super.key, required this.event});

  @override
  State<PersonalEventDetailPage> createState() => _PersonalEventDetailPageState();
}

class _PersonalEventDetailPageState extends State<PersonalEventDetailPage> {
  late Future<FullEvent> eventFuture;
  bool isFavorite = false;
  bool busyFavorite = false;
  bool busyJoin = false;
  bool joined = false;
  int? participantsOverride; // 報名／取消後前端即時顯示

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

    if (resp.statusCode == 200) {
      final map = json.decode(utf8.decode(resp.bodyBytes)) as Map<String, dynamic>;
      final raw = (map['event'] is Map<String, dynamic>) ? map['event'] as Map<String, dynamic> : map;
      // TODO: 若後端有提供使用者是否已收藏/已報名，這裡可據回傳初始化 isFavorite/joined
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

  // ---- Helpers ----

  // 強制把 ApiPath 內的 revert 參數改成首字大寫 Revert（避免後端 400）
  String _revertUrl(int eventId) {
    final raw = ApiPath.addCharityEventUserRevert(eventId);
    return raw.replaceFirst('user_record_choice=revert', 'user_record_choice=Revert');
  }

  // 讀後端錯誤訊息字串
  String _respMsg(dynamic resp) {
    try {
      return utf8.decode(resp.bodyBytes);
    } catch (_) {
      try {
        return resp.body?.toString() ?? '';
      } catch (_) {
        return '';
      }
    }
  }

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  // ---- 收藏（與報名互斥）----
  Future<void> handleFavorite(int eventId) async {
    if (busyFavorite || isFavorite) return;

    // 互斥保護：已報名就不允許收藏
    if (joined) {
      _showSnack('你已報名此活動，無法收藏。若要收藏，請先取消報名');
      return;
    }

    setState(() => busyFavorite = true);

    final apiClient = ApiClient();
    await apiClient.init();
    final url = ApiPath.addCharityEventUserSave(eventId);

    try {
      final resp = await apiClient.post(url, {}).timeout(const Duration(seconds: 10));
      if (resp.statusCode == 200 || resp.statusCode == 201) {
        setState(() => isFavorite = true);
        _showSnack('已加入收藏');
      } else if (resp.statusCode == 409) {
        setState(() => isFavorite = true);
        _showSnack('你已收藏過');
      } else if (resp.statusCode == 401) {
        _showSnack('請先登入後再試');
      } else {
        _showSnack('加入收藏失敗：${resp.statusCode}｜${_respMsg(resp)}');
      }
    } catch (e) {
      _showSnack('加入收藏時發生錯誤：$e');
    } finally {
      if (mounted) setState(() => busyFavorite = false);
    }
  }

  Future<void> handleUnfavorite(int eventId) async {
    if (busyFavorite || !isFavorite) return;
    setState(() => busyFavorite = true);

    final apiClient = ApiClient();
    await apiClient.init();
    final url = _revertUrl(eventId);

    try {
      final resp = await apiClient.post(url, {}).timeout(const Duration(seconds: 10));
      if (resp.statusCode == 200 || resp.statusCode == 204) {
        setState(() => isFavorite = false);
        _showSnack('已取消收藏');
      } else if (resp.statusCode == 401) {
        _showSnack('請先登入後再試');
      } else {
        _showSnack('取消收藏失敗：${resp.statusCode}｜${_respMsg(resp)}');
      }
    } catch (e) {
      _showSnack('取消收藏時發生錯誤：$e');
    } finally {
      if (mounted) setState(() => busyFavorite = false);
    }
  }

  // ---- 報名（與收藏互斥）----
  Future<void> handleJoin(FullEvent event) async {
    if (busyJoin || joined) return;

    // 互斥保護：已收藏就不允許報名
    if (isFavorite) {
      _showSnack('你已收藏此活動，無法報名。若要報名，請先取消收藏');
      return;
    }

    setState(() => busyJoin = true);

    final apiClient = ApiClient();
    await apiClient.init();
    final url = ApiPath.addCharityEventUserJoin(event.id);

    try {
      final resp = await apiClient.post(url, {}).timeout(const Duration(seconds: 10));
      if (resp.statusCode == 200 || resp.statusCode == 201) {
        setState(() {
          joined = true;
          final base = participantsOverride ?? event.participants;
          participantsOverride = base + 1;
        });
        _showSnack('報名成功！');
      } else if (resp.statusCode == 409) {
        setState(() => joined = true);
        _showSnack('你已報名過此活動');
      } else if (resp.statusCode == 401) {
        _showSnack('請先登入後再試');
      } else {
        _showSnack('報名失敗：${resp.statusCode}｜${_respMsg(resp)}');
      }
    } catch (e) {
      _showSnack('報名時發生錯誤：$e');
    } finally {
      if (mounted) setState(() => busyJoin = false);
    }
  }

  Future<void> handleUnjoin(FullEvent event) async {
    if (busyJoin || !joined) return;
    setState(() => busyJoin = true);

    final apiClient = ApiClient();
    await apiClient.init();
    final url = _revertUrl(event.id);

    try {
      final resp = await apiClient.post(url, {}).timeout(const Duration(seconds: 10));
      if (resp.statusCode == 200 || resp.statusCode == 204) {
        setState(() {
          joined = false;
          final base = participantsOverride ?? event.participants;
          final next = base - 1;
          participantsOverride = next < 0 ? 0 : next;
        });
        _showSnack('已取消報名');
      } else if (resp.statusCode == 401) {
        _showSnack('請先登入後再試');
      } else {
        _showSnack('取消報名失敗：${resp.statusCode}｜${_respMsg(resp)}');
      }
    } catch (e) {
      _showSnack('取消報名時發生錯誤：$e');
    } finally {
      if (mounted) setState(() => busyJoin = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('活動詳情'),
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
            return const Center(child: Text('查無活動資料'));
          }

          final event = snapshot.data!;
          final participantsShown = participantsOverride ?? event.participants;

          // 互斥：當一方成立時，另一方（未切換狀態的主動動作）被禁用
          final bool joinBlockedByFavorite = !joined && isFavorite; // 未報名且已收藏 → 禁用「我要參加」
          final bool favoriteBlockedByJoin = !isFavorite && joined; // 未收藏且已報名 → 禁用「加入收藏」

          // 允許使用者在已經 "加入" 的狀態下做「取消」行為
          final bool joinEnabled = !busyJoin && (joined || !joinBlockedByFavorite);
          final bool favoriteEnabled = !busyFavorite && (isFavorite || !favoriteBlockedByJoin);

          return Padding(
            padding: const EdgeInsets.all(20),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 標題
                  Text(
                    event.title,
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),

                  const SizedBox(height: 16),

                  // 主/協辦
                  if (event.mainOrganizer.isNotEmpty) Text('主辦單位：${event.mainOrganizer}')
                  else const SizedBox.shrink(),
                  if (event.coOrganizers.isNotEmpty) Text('協辦單位：${event.coOrganizers.join(', ')}')
                  else const SizedBox.shrink(),

                  const SizedBox(height: 16),

                  // 基本資訊
                  if (event.type.isNotEmpty) Text('活動類型：${event.type}') else const SizedBox.shrink(),
                  if (event.location.isNotEmpty) Text('活動地區：${event.location}') else const SizedBox.shrink(),
                  if (event.address.isNotEmpty) Text('地址：${event.address}') else const SizedBox.shrink(),

                  const SizedBox(height: 16),

                  // 時間
                  const Text('活動時間：'),
                  Text('${formatDateTime(event.startTime)} ～ ${formatDateTime(event.endTime)}'),
                  const SizedBox(height: 8),
                  Text('報名截止：${formatDateTime(event.signupDeadline)}'),

                  // 狀態與人數
                  if (event.status.isNotEmpty) Text('狀態：${event.status}') else const SizedBox.shrink(),
                  Text('目前報名人數：$participantsShown'),

                  const SizedBox(height: 24),

                  // 介紹
                  const Text('活動介紹', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(event.description),

                  const SizedBox(height: 32),

                  // 報名按鈕（切換 + 互斥）
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      icon: joined
                          ? const Icon(Icons.cancel)
                          : const Icon(Icons.check_circle_outline),
                      label: Text(
                        joined
                            ? '取消報名'
                            : (joinBlockedByFavorite ? '已收藏，無法報名' : '我要參加'),
                      ),
                      onPressed: joinEnabled
                          ? () => joined ? handleUnjoin(event) : handleJoin(event)
                          : null,
                    ),
                  ),

                  const SizedBox(height: 12),

                  // 收藏按鈕（切換 + 互斥）
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      icon: isFavorite ? const Icon(Icons.star) : const Icon(Icons.star_border),
                      label: Text(
                        isFavorite
                            ? '取消收藏'
                            : (favoriteBlockedByJoin ? '已報名，無法收藏' : '加入收藏'),
                      ),
                      onPressed: favoriteEnabled
                          ? () => isFavorite
                              ? handleUnfavorite(widget.event.id)
                              : handleFavorite(widget.event.id)
                          : null,
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
