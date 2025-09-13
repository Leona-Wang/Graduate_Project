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

      debugPrint('[URL] ${response.request?.url}');
      debugPrint('[RESP] ${response.statusCode} ${response.reasonPhrase}');
      debugPrint('[BODY] ${response.body}');

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
          // 成功
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('邀請已經送出，請靜待主辦方審核！')));
          // 可選：清空輸入
          codeController.clear();
          setState(() => code = '');
        } else {
          // 200 但 success=false
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(msg ?? '處理失敗，請稍後再試。')));
        }
      } else if (response.statusCode >= 400 && response.statusCode < 500) {
        // 業務錯誤（例如邀請碼錯、活動不存在），後端用 4xx 回
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg ?? '送出失敗（${response.statusCode}）')),
        );
      } else {
        // 其他非預期錯誤
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

          // TAB 2：其他（先放空白占位）
          const Center(child: Text('這裡放第二個標籤的內容')),
        ],
      ),
    );
  }
}
