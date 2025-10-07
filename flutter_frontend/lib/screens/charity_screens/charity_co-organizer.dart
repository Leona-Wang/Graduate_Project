import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_frontend/api_client.dart';
import 'package:flutter_frontend/config.dart';

class CharityCoorganizerPage extends StatefulWidget {
  const CharityCoorganizerPage({super.key, this.defaultEventName});

  /// 可選：若已知活動名稱可由外部傳入（charityEventName）
  final String? defaultEventName;

  @override
  State<CharityCoorganizerPage> createState() => _CharityCoorganizerPageState();
}

class _CharityCoorganizerPageState extends State<CharityCoorganizerPage>
    with SingleTickerProviderStateMixin {
  // ---- Tab 控制 ----
  late final TabController tabController;

  // ---- Tab1：輸入邀請碼 ----
  final formKey = GlobalKey<FormState>();
  final codeController = TextEditingController();
  final codeFocusNode = FocusNode();
  bool isSubmitting = false;
  String code = '';

  // ---- Tab2：審核清單 ----
  final _eventNameController = TextEditingController();
  String? _eventName; // charityEventName

  @override
  void initState() {
    super.initState();
    tabController = TabController(length: 2, vsync: this);

    final preset = (widget.defaultEventName ?? '').trim();
    if (preset.isNotEmpty) {
      _eventName = preset;
      _eventNameController.text = preset;
    }
  }

  @override
  void dispose() {
    tabController.dispose();
    codeController.dispose();
    codeFocusNode.dispose();
    _eventNameController.dispose();
    super.dispose();
  }

  // ===============================================================
  // Tab1：輸入協辦邀請碼（POST）
  // ===============================================================
  Future<void> _submitInviteCode() async {
    if (!(formKey.currentState?.validate() ?? false)) return;
    codeFocusNode.unfocus();
    setState(() => isSubmitting = true);

    try {
      final api = ApiClient();
      await api.init();

      final body = {'inviteCode': code.trim()};
      final resp = await api
          .post(ApiPath.coOrganizeEvent, body)
          .timeout(const Duration(seconds: 10));

      Map<String, dynamic>? data;
      try {
        data = jsonDecode(resp.body) as Map<String, dynamic>;
      } catch (_) {}

      final msg = data?['message']?.toString();
      final ok = data?['success'] == true ||
          data?['ok'] == true ||
          data?['status']?.toString().toLowerCase() == 'ok';

      if (!mounted) return;

      if (resp.statusCode == 200 && ok) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('邀請已送出，請等待主辦方審核')),
        );
        codeController.clear();
        setState(() => code = '');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '送出失敗（${resp.statusCode}）${msg != null ? "：$msg" : ""}',
            ),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('送出失敗：$e')));
    } finally {
      if (mounted) setState(() => isSubmitting = false);
    }
  }

  // ===============================================================
  // Tab2：讀取協辦申請清單（GET with charityEventName）
  // 未輸入活動名稱：不丟 Exception，直接回傳空清單
  // ===============================================================
  Future<List<Map<String, dynamic>>> _fetchApplications() async {
    final name = (_eventName ?? '').trim();
    if (name.isEmpty) return <Map<String, dynamic>>[];

    final api = ApiClient();
    await api.init();

    final uri = Uri.parse(ApiPath.getCoOrganizeApplications).replace(
      queryParameters: {
        'charityEventName': name,
      },
    );

    final resp =
        await api.get(uri.toString()).timeout(const Duration(seconds: 10));

    if (resp.statusCode != 200) {
      // 讓 FutureBuilder 進入 hasError，但畫面會顯示友善訊息（不曝露 Exception 內容）
      String backendMsg = '';
      try {
        final d = jsonDecode(resp.body);
        backendMsg = (d['message'] ?? d['detail'] ?? '').toString();
      } catch (_) {
        backendMsg = resp.body;
      }
      throw Exception('HTTP ${resp.statusCode}: $backendMsg');
    }

    dynamic decoded;
    try {
      decoded = jsonDecode(resp.body);
    } catch (_) {
      throw Exception('無法解析後端回傳');
    }

    // 後端預期：{"success": true, "applications": [...]}
    final list = decoded is Map ? (decoded['applications'] ?? []) : decoded;
    return List<Map<String, dynamic>>.from(
      (list as List).map((e) => Map<String, dynamic>.from(e as Map)),
    );
  }

  // ===============================================================
  // 審核（通過/拒絕）
  // 規格：{'charityEventName':(必填),'coOrganizerName':(必填),'approve':true/false}
  // 同時附帶 coOrganizerEmail（非必填，輔助辨識）
  // ===============================================================
  Future<void> _verifyApplication({
    required String coOrganizerName,
    required String coOrganizerEmail,
    required bool approve,
  }) async {
    final eventName = (_eventName ?? '').trim();
    if (eventName.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('請先輸入活動名稱')));
      return;
    }

    final safeName = coOrganizerName.trim().isNotEmpty
        ? coOrganizerName.trim()
        : coOrganizerEmail.trim();
    final safeEmail = coOrganizerEmail.trim();

    if (safeName.isEmpty && safeEmail.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('缺少協辦者辨識資訊')));
      return;
    }

    try {
      final api = ApiClient();
      await api.init();

      final body = {
        'charityEventName': eventName,
        'coOrganizerName': safeName,
        'approve': approve,
        if (safeEmail.isNotEmpty) 'coOrganizerEmail': safeEmail,
      };

      final resp = await api
          .post(ApiPath.verifyCoOrganize, body)
          .timeout(const Duration(seconds: 10));

      if (!mounted) return;

      if (resp.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(approve ? '已通過申請' : '已拒絕申請')),
        );
        setState(() {}); // 重新讀取列表
      } else {
        String backendMsg = '';
        try {
          final d = jsonDecode(resp.body);
          backendMsg = (d['message'] ?? d['detail'] ?? '').toString();
        } catch (_) {
          backendMsg = resp.body;
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('操作失敗（${resp.statusCode}）：$backendMsg')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('操作失敗：$e')));
    }
  }

  void _applyEventName() {
    setState(() => _eventName = _eventNameController.text.trim());
  }

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
          tabs: const [
            Tab(text: '協辦邀請碼輸入'),
            Tab(text: '協辦審核'),
          ],
        ),
      ),
      body: TabBarView(
        controller: tabController,
        children: [
          buildInviteTab(),
          buildReviewTab(),
        ],
      ),
    );
  }

  // ---------- Tab1：輸入邀請碼 ----------
  Widget buildInviteTab() {
    final canSubmit = code.length == 6 && !isSubmitting;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 24),
              Text('請輸入 6 位數邀請碼',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 12),
              TextFormField(
                controller: codeController,
                focusNode: codeFocusNode,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.done,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(6),
                ],
                decoration: const InputDecoration(
                  hintText: '例如：123456',
                  border: OutlineInputBorder(),
                ),
                onChanged: (v) => setState(() => code = v.trim()),
                validator: (v) {
                  final s = (v ?? '').trim();
                  if (s.length != 6) return '邀請碼必須為 6 位數字！';
                  return null;
                },
                onFieldSubmitted: (_) {
                  if (canSubmit) _submitInviteCode();
                },
              ),
              const Spacer(),
              SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: canSubmit ? _submitInviteCode : null,
                  child: isSubmitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(),
                        )
                      : const Text('送出'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------- Tab2：協辦審核 ----------
  Widget buildReviewTab() {
    final shouldLoad = (_eventName?.trim().isNotEmpty ?? false);

    return SafeArea(
      child: Column(
        children: [
          buildEventNameRow(),
          const SizedBox(height: 8),

          // 尚未輸入活動名稱：只顯示提示，不打 API、不顯示錯誤文案
          if (!shouldLoad)
            Expanded(
              child: Center(
                child: Text(
                  '請先輸入「活動名稱」並點「載入申請」。',
                  style: const TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ),
            )
          else
            Expanded(
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: _fetchApplications(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  // 讀取失敗 → 顯示友善訊息（不露 Exception）
                  if (snapshot.hasError) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('讀取失敗，請稍後再試。'),
                          const SizedBox(height: 8),
                          ElevatedButton(
                            onPressed: () => setState(() {}),
                            child: const Text('重試'),
                          ),
                        ],
                      ),
                    );
                  }

                  final apps = snapshot.data ?? [];
                  if (apps.isEmpty) {
                    return const Center(child: Text('目前沒有待審核的協辦申請'));
                  }

                  return RefreshIndicator(
                    onRefresh: () async => setState(() {}),
                    child: ListView.separated(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(16),
                      itemCount: apps.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final app = apps[index];

                        // 後端欄位（做 fallback）
                        final coName =
                            (app['coOrganizerName'] ?? app['name'] ?? '')
                                .toString()
                                .trim();
                        final coEmail =
                            (app['coOrganizerEmail'] ?? app['email'] ?? '')
                                .toString()
                                .trim();

                        final titleText = coName.isNotEmpty
                            ? coName
                            : (coEmail.isNotEmpty ? coEmail : '未知');
                        final subtitleText = coEmail.isNotEmpty ? coEmail : '—';

                        return _VerifyTile(
                          title: titleText,
                          subtitle: subtitleText,
                          onApprove: () async {
                            await _verifyApplication(
                              coOrganizerName: coName,
                              coOrganizerEmail: coEmail,
                              approve: true,
                            );
                          },
                          onReject: () async {
                            await _verifyApplication(
                              coOrganizerName: coName,
                              coOrganizerEmail: coEmail,
                              approve: false,
                            );
                          },
                        );
                      },
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  // 活動名稱輸入列
  Widget buildEventNameRow() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _eventNameController,
              decoration: const InputDecoration(
                hintText: '請輸入活動名稱',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              onSubmitted: (_) {
                _applyEventName();
                setState(() {}); // 觸發 FutureBuilder
              },
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton(
            onPressed: () {
              _applyEventName();
              setState(() {}); // 觸發 FutureBuilder
            },
            child: const Text('載入申請'),
          ),
        ],
      ),
    );
  }
}

// ====== 小元件：有 loading 的審核按鈕列 ======
class _VerifyTile extends StatefulWidget {
  const _VerifyTile({
    required this.title,
    required this.subtitle,
    required this.onApprove,
    required this.onReject,
  });

  final String title;
  final String subtitle;
  final Future<void> Function() onApprove;
  final Future<void> Function() onReject;

  @override
  State<_VerifyTile> createState() => _VerifyTileState();
}

class _VerifyTileState extends State<_VerifyTile> {
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(widget.title),
      subtitle: Text(widget.subtitle),
      trailing: _loading
          ? const SizedBox(
              height: 24,
              width: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.check, color: Colors.green),
                  tooltip: '通過',
                  onPressed: () async {
                    setState(() => _loading = true);
                    try {
                      await widget.onApprove();
                    } finally {
                      if (mounted) setState(() => _loading = false);
                    }
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.red),
                  tooltip: '不通過',
                  onPressed: () async {
                    setState(() => _loading = true);
                    try {
                      await widget.onReject();
                    } finally {
                      if (mounted) setState(() => _loading = false);
                    }
                  },
                ),
              ],
            ),
    );
  }
}
