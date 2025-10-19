import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_frontend/api_client.dart';
import 'package:flutter_frontend/config.dart';

class CharityCoorganizerPage extends StatefulWidget {
  const CharityCoorganizerPage({super.key});

  @override
  State<CharityCoorganizerPage> createState() => _CharityCoorganizerPageState();
}

class _CharityCoorganizerPageState extends State<CharityCoorganizerPage>
    with SingleTickerProviderStateMixin {
  late final TabController tabController;

  final codeController = TextEditingController();
  final codeFocusNode = FocusNode();
  bool isSubmitting = false;

  final _eventNameController = TextEditingController();
  //String? _eventName;

  @override
  void initState() {
    super.initState();
    tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    tabController.dispose();
    codeController.dispose();
    codeFocusNode.dispose();
    _eventNameController.dispose();
    super.dispose();
  }

  // ---------- Popup helper ----------
  Future<void> _showPopup(String message) async {
    if (!mounted) return;
    await showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('確定'),
              ),
            ],
          ),
    );
  }

  // ===============================================================
  // Tab1：輸入協辦邀請碼
  // ===============================================================
  Future<void> _submitInviteCode() async {
    final code = codeController.text.trim();

    if (code.length != 6) {
      await _showPopup('邀請碼需為6位數');
      return;
    }

    setState(() => isSubmitting = true);
    codeFocusNode.unfocus();

    try {
      final api = ApiClient();
      await api.init();

      final body = {'inviteCode': code};
      final resp = await api
          .post(ApiPath.coOrganizeEvent, body)
          .timeout(const Duration(seconds: 10));

      if (resp.statusCode == 200) {
        await _showPopup('邀請碼已送出，請等待審核');
        codeController.clear();
      } else {
        await _showPopup('送出失敗（${resp.statusCode}）');
      }
    } catch (e) {
      await _showPopup('送出錯誤：$e');
    } finally {
      if (mounted) setState(() => isSubmitting = false);
    }
  }

  // ===============================================================
  // Tab2：讀取協辦申請清單
  // ===============================================================
  Future<List<Map<String, dynamic>>> _fetchAllApplications() async {
    try {
      final api = ApiClient();
      await api.init();

      // 先取得活動清單
      final resp = await api.get(ApiPath.charityEventList);
      if (resp.statusCode != 200) {
        debugPrint('取得活動清單失敗: ${resp.statusCode}');
        return [];
      }

      final decoded = jsonDecode(resp.body);
      final events = (decoded['events'] ?? []) as List;
      final results = <Map<String, dynamic>>[];

      // Step 2. 對每個活動呼叫 getCoOrganizeApplications
      for (final e in events) {
        final name = e['name']?.toString() ?? '';
        if (name.isEmpty) continue;

        final uri = Uri.parse(
          ApiPath.getCoOrganizeApplications,
        ).replace(queryParameters: {'charityEventName': name});

        final appResp = await api.get(uri.toString());

        if (appResp.statusCode == 200) {
          final data = jsonDecode(appResp.body);
          final apps = data['applications'] ?? [];
          results.add({'eventName': name, 'applications': apps});
        } else {
          debugPrint('讀取 $name 協辦申請失敗 (${appResp.statusCode})');
        }
      }

      return results;
    } catch (e) {
      debugPrint('錯誤：$e');
      return [];
    }
  }

  // ===============================================================
  // 協辦審核（通過 / 拒絕）
  // ===============================================================
  Future<void> _verifyApplication({
    required String eventName,
    required String coOrganizerName,
    required bool approve,
  }) async {
    try {
      final api = ApiClient();
      await api.init();

      final body = {
        'charityEventName': eventName,
        'coOrganizerName': coOrganizerName,
        'approve': approve,
      };

      final resp = await api
          .post(ApiPath.verifyCoOrganize, body)
          .timeout(const Duration(seconds: 10));

      if (resp.statusCode == 200) {
        await _showPopup(approve ? '已通過申請' : '已拒絕申請');
      } else {
        await _showPopup('操作失敗 (${resp.statusCode})');
      }
    } catch (e) {
      await _showPopup('操作錯誤：$e');
    }
  }

  /*
  void _applyEventName() {
    setState(() => _eventName = _eventNameController.text.trim());
  }*/

  // ===============================================================
  // UI
  // ===============================================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('協辦控制面板'),
        bottom: TabBar(
          controller: tabController,
          tabs: const [Tab(text: '邀請碼輸入'), Tab(text: '協辦審核')],
        ),
      ),
      body: TabBarView(
        controller: tabController,
        children: [_buildInviteTab(), _buildAllReviewTab()],
      ),
    );
  }

  Widget _buildInviteTab() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: codeController,
              focusNode: codeFocusNode,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(6),
              ],
              decoration: const InputDecoration(
                labelText: '邀請碼',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 48,
              child: ElevatedButton(
                onPressed: isSubmitting ? null : _submitInviteCode,
                child:
                    isSubmitting
                        ? const CircularProgressIndicator()
                        : const Text('送出'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAllReviewTab() {
    return SafeArea(
      child: FutureBuilder<List<Map<String, dynamic>>>(
        future: _fetchAllApplications(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return const Center(child: Text('讀取失敗'));
          }

          final events = snapshot.data ?? [];
          if (events.isEmpty) {
            return const Center(child: Text('目前沒有協辦申請'));
          }

          return ListView.builder(
            itemCount: events.length,
            itemBuilder: (context, index) {
              final event = events[index];
              final eventName = event['eventName'] ?? '';
              final apps = event['applications'] as List;
              final count = apps.length;

              return Stack(
                children: [
                  Card(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    elevation: 2,
                    child: ExpansionTile(
                      tilePadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 4,
                      ),
                      title: Text(
                        eventName,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      children:
                          apps.isEmpty
                              ? [const ListTile(title: Text('目前無申請'))]
                              : apps.map((app) {
                                final name =
                                    (app['coOrganizerName'] ?? '')
                                        .toString()
                                        .trim();
                                final email =
                                    (app['coOrganizerEmail'] ?? '')
                                        .toString()
                                        .trim();

                                return ListTile(
                                  title: Text(name.isNotEmpty ? name : '未知機構'),
                                  subtitle: Text(email),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(
                                          Icons.check,
                                          color: Colors.green,
                                        ),
                                        onPressed:
                                            () => _verifyApplication(
                                              eventName: eventName,
                                              coOrganizerName: name,
                                              approve: true,
                                            ),
                                      ),
                                      IconButton(
                                        icon: const Icon(
                                          Icons.close,
                                          color: Colors.red,
                                        ),
                                        onPressed:
                                            () => _verifyApplication(
                                              eventName: eventName,
                                              coOrganizerName: name,
                                              approve: false,
                                            ),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                    ),
                  ),

                  // Badge：紅色數字提示在右上角
                  if (count > 0)
                    Positioned(
                      right: 20,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.redAccent,
                          borderRadius: BorderRadius.circular(50),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.red.withOpacity(0.5),
                              blurRadius: 4,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 22,
                          minHeight: 22,
                        ),
                        child: Center(
                          child: Text(
                            '$count',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
