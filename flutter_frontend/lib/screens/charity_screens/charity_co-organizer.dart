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
  final formKey = GlobalKey<FormState>();
  final codeController = TextEditingController();
  final codeFocusNode = FocusNode();

  late final TabController tabController;
  bool isSubmitting = false;
  String code = '';

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
    super.dispose();
  }

  Future<void> submit() async {
    if (!(formKey.currentState?.validate() ?? false)) return;
    codeFocusNode.unfocus();
    setState(() => isSubmitting = true);

    try {
      final apiClient = ApiClient();
      await apiClient.init();

      final body = {'inviteCode': code};
      debugPrint('[POST] path=${ApiPath.coOrganizeEvent} body=$body');

      final response = await apiClient
          .post(ApiPath.coOrganizeEvent, body)
          .timeout(const Duration(seconds: 10));

      Map<String, dynamic>? data;
      try {
        data = jsonDecode(response.body) as Map<String, dynamic>;
      } catch (_) {
        data = null;
      }

      final msg = data?['message']?.toString();

      if (response.statusCode == 200) {
        final ok =
            data?['success'] == true ||
            data?['ok'] == true ||
            data?['status'] == 'ok';
        if (ok) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('邀請已經送出，請靜待主辦方審核！')));
          codeController.clear();
          setState(() => code = '');
        } else {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(msg ?? '處理失敗，請稍後再試。')));
        }
      } else if (response.statusCode >= 400 && response.statusCode < 500) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg ?? '送出失敗（${response.statusCode}）')),
        );
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('送出失敗（${response.statusCode}）')));
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('送出失敗：$e')));
    } finally {
      if (mounted) setState(() => isSubmitting = false);
    }
  }

  Future<void> _verifyApplication(int id, bool approve) async {
    try {
      final apiClient = ApiClient();
      await apiClient.init();

      final body = {"applicationId": id, "approve": approve};
      debugPrint('[POST] ${ApiPath.verifyCoOrganize} body=$body');

      final resp = await apiClient.post(ApiPath.verifyCoOrganize, body);
      debugPrint('[RESP] ${resp.statusCode} ${resp.body}');

      if (resp.statusCode == 200) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(approve ? '已通過申請' : '已拒絕申請')));
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('操作失敗（${resp.statusCode}）')));
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('操作失敗：$e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final canSubmit = code.length == 6 && !isSubmitting;

    return Scaffold(
      appBar: AppBar(
        title: const Text('協辦控制面板'),
        bottom: TabBar(
          controller: tabController,
          tabs: const [Tab(text: '協辦邀請碼輸入'), Tab(text: '協辦審核')],
        ),
      ),
      body: TabBarView(
        controller: tabController,
        children: [
          // TAB 1：協辦邀請碼輸入
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 24),
                    Text(
                      '請輸入 6 位數邀請碼',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
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
                        if (canSubmit) submit();
                      },
                    ),
                    const Spacer(),
                    SizedBox(
                      height: 48,
                      child: ElevatedButton(
                        onPressed: canSubmit ? submit : null,
                        child:
                            isSubmitting
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
          ),

          // TAB 2：協辦審核
          FutureBuilder(
            future: ApiClient().get(ApiPath.getCoOrganizeApplications),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(child: Text('讀取失敗：${snapshot.error}'));
              }
              if (!snapshot.hasData) {
                return const Center(child: Text('沒有資料'));
              }

              final resp = snapshot.data!;
              final decoded = jsonDecode(resp.body);

              // 處理可能是 List 或 Map
              final List<dynamic> list =
                  decoded is List
                      ? decoded
                      : (decoded['data'] is List ? decoded['data'] : []);

              final pending = list.where((e) => e['verified'] == null).toList();

              if (pending.isEmpty) {
                return const Center(child: Text('目前沒有待審核的協辦申請'));
              }

              return ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: pending.length,
                separatorBuilder: (_, __) => const Divider(),
                itemBuilder: (context, index) {
                  final app = pending[index];
                  final id = app['id'];
                  final name = app['name'] ?? '未知';
                  final email = app['email'] ?? '';

                  return ListTile(
                    title: Text(name),
                    subtitle: Text(email),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.check, color: Colors.green),
                          tooltip: '通過',
                          onPressed: () async {
                            await _verifyApplication(id, true);
                            setState(() {});
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.red),
                          tooltip: '不通過',
                          onPressed: () async {
                            await _verifyApplication(id, false);
                            setState(() {});
                          },
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}
