import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:flutter_frontend/config.dart';
import 'package:flutter_frontend/api_client.dart';

class CharityCoOrganizerListPage extends StatefulWidget {
  final String charityEventName;
  final List<String>? initialCoOrganizers;

  /// [charityEventName] 必填（API 需要）
  /// [initialCoOrganizers] 可選：如果你從詳情頁已有 coOrganizers（只是一串名稱），建議傳進來，畫面會更快
  const CharityCoOrganizerListPage({
    super.key,
    required this.charityEventName,
    this.initialCoOrganizers,
  });

  @override
  State<CharityCoOrganizerListPage> createState() =>
      _CharityCoOrganizerListPageState();
}

class _CharityCoOrganizerListPageState
    extends State<CharityCoOrganizerListPage> {
  late List<String> _coOrganizers;
  bool _loading = false;
  bool _changed = false; // 若有移除則設為 true，pop 時會回傳

  @override
  void initState() {
    super.initState();
    // 直接使用 initialCoOrganizers（若有），否則從空陣列開始
    _coOrganizers = widget.initialCoOrganizers != null
        ? List<String>.from(widget.initialCoOrganizers!)
        : <String>[];
  }

  /// 如果你想改成向後端撈（比如要 email），可以在這裡實作 call API 的邏輯
  /// 目前題目需求是只顯示目前協辦且能移除，所以用 initialCoOrganizers 足夠
  Future<void> _removeCoOrganizer(String name) async {
    if (_loading) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('確認移除'),
        content: Text('確定要移除協辦者「$name」嗎？此操作會將該單位從協辦名單中移除。'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('取消')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('移除')),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _loading = true);

    try {
      final api = ApiClient();
      await api.init();

      final url = ApiPath.removeCoOrganizer;
      final body = {
        'charityEventName': widget.charityEventName,
        'coOrganizerName': name,
      };

      final resp = await api.post(url, body);
      if (resp.statusCode == 200 || resp.statusCode == 201) {
        final data = json.decode(resp.body);
        final success = data is Map && data['success'] == true;
        if (success) {
          // 從 local list 移除並標記已變更
          setState(() {
            _coOrganizers.removeWhere((e) => e == name);
            _changed = true;
          });
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('移除成功')));
        } else {
          final msg = (data is Map && data['message'] is String) ? data['message'] : '移除失敗';
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg.toString())));
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('移除失敗（${resp.statusCode}）')));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('移除失敗：$e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    // 當畫面被關閉時，如果有變動就回傳 true
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.pop(context, _changed);
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text('協辦單位 - ${widget.charityEventName}'),
          actions: [
            IconButton(
              tooltip: '重新整理',
              icon: const Icon(Icons.refresh),
              onPressed: () {
                // 若你需要從後端重新抓，可在此實作。現在我們只有 local list，所以不做動作。
                // 提供一個 Snackbar 提示使用者（以免按了沒有反應）
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('已更新顯示（本地資料）')));
              },
            ),
          ],
        ),
        body: _coOrganizers.isEmpty
            ? Center(
                child: Text(
                  '目前沒有協辦單位',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              )
            : ListView.separated(
                padding: const EdgeInsets.all(12),
                itemCount: _coOrganizers.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, idx) {
                  final name = _coOrganizers[idx];
                  return Card(
                    child: ListTile(
                      title: Text(name),
                      trailing: _loading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : IconButton(
                              tooltip: '移除協辦者',
                              icon: const Icon(Icons.remove_circle_outline),
                              onPressed: () => _removeCoOrganizer(name),
                            ),
                    ),
                  );
                },
              ),
        floatingActionButton: _changed
            ? FloatingActionButton.extended(
                onPressed: () {
                  // 讓使用者可以立即返回並告知上一頁有變動
                  Navigator.pop(context, true);
                },
                label: const Text('完成（有變更）'),
                icon: const Icon(Icons.check),
              )
            : null,
      ),
    );
  }
}
