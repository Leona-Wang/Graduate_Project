import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:flutter_frontend/config.dart';
import 'package:flutter_frontend/api_client.dart';

class CharityCoOrganizerListPage extends StatefulWidget {
  final String charityEventName;

  const CharityCoOrganizerListPage({super.key, required this.charityEventName});

  @override
  State<CharityCoOrganizerListPage> createState() =>
      _CharityCoOrganizerListPageState();
}

class _CharityCoOrganizerListPageState
    extends State<CharityCoOrganizerListPage> {
  List<coOrganizer> coOrganizers = []; //已通過認證協辦者s
  bool loading = false;
  String? removingName;

  @override
  void initState() {
    super.initState();
    _loadCoOrganizers();
  }

  //popup用
  Future<void> _showPopup(String mes) async {
    if (!mounted) return;

    await showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            content: Text(mes),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('確定'),
              ),
            ],
          ),
    );
  }

  //載入協辦者
  Future<void> _loadCoOrganizers() async {
    setState(() => loading = true);

    try {
      final api = ApiClient();
      await api.init();

      final eventName = widget.charityEventName.trim();

      final url = ApiPath.getCoOrganizers;
      final body = {'eventName': eventName};

      final resp = await api.post(url, body);

      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);

        if (data is Map && data['success'] == true) {
          final listRaw = data['coOrganizers'] ?? [];
          if (listRaw is List) {
            final list =
                listRaw
                    .map((e) => coOrganizer.fromJson(e as Map<String, dynamic>))
                    .toList();
            setState(() {
              coOrganizers = list;
            });
          } else {
            setState(() => coOrganizers = []);
          }
        } else {
          final msg =
              (data is Map && data['message'] is String)
                  ? data['message']
                  : '讀取協辦者清單失敗';
          await _showPopup(msg.toString());
          setState(() => coOrganizers = []);
        }
      } else {
        await _showPopup('讀取協辦者清單失敗（${resp.statusCode}）');
        setState(() => coOrganizers = []);
      }
    } catch (e) {
      await _showPopup('讀取協辦者清單時發生錯誤：$e');
      setState(() {
        coOrganizers = [];
      });
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  //移除協辦者
  Future<void> _removeCoOrganizer(coOrganizer item) async {
    if (removingName != null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text('確認移除'),
            content: Text('確定要移除協辦單位「${item.name}」嗎？'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('取消'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('移除'),
              ),
            ],
          ),
    );

    if (confirm != true) return;

    setState(() => removingName = item.name);

    try {
      final api = ApiClient();
      await api.init();

      final url = ApiPath.removeCoOrganizer;
      final body = {
        'charityEventName': widget.charityEventName,
        'coOrganizerName': item.name,
      };

      final resp = await api.post(url, body);

      if (resp.statusCode == 200 || resp.statusCode == 201) {
        final data = jsonDecode(resp.body);
        final success = data is Map && data['success'] == true;

        if (success) {
          setState(() {
            coOrganizers.removeWhere((e) => e.name == item.name);
          });
          await _showPopup('移除成功');
        } else {
          final msg =
              (data is Map && data['message'] is String)
                  ? data['message']
                  : '移除失敗';
          await _showPopup(msg.toString());
        }
      } else {
        await _showPopup('移除失敗（${resp.statusCode}）');
      }
    } catch (e) {
      await _showPopup('移除失敗：$e');
    } finally {
      if (mounted) setState(() => removingName = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('協辦單位 - ${widget.charityEventName}'),
        actions: [
          IconButton(
            tooltip: '重新整理',
            icon: const Icon(Icons.refresh),
            onPressed: loading ? null : _loadCoOrganizers,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (loading && coOrganizers.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (coOrganizers.isEmpty) {
      return Center(
        child: Text('目前沒有協辦單位', style: Theme.of(context).textTheme.bodyLarge),
      );
    }

    // 有資料時支援下拉刷新
    return RefreshIndicator(
      onRefresh: _loadCoOrganizers,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(12),
        itemCount: coOrganizers.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, idx) {
          final item = coOrganizers[idx];

          return Card(
            child: ListTile(
              title: Text(item.name),
              subtitle: item.email.isNotEmpty ? Text(item.email) : null,
              trailing:
                  removingName == item.name
                      ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                      : IconButton(
                        tooltip: '移除協辦者',
                        icon: const Icon(Icons.remove_circle_outline),
                        onPressed: () => _removeCoOrganizer(item),
                      ),
            ),
          );
        },
      ),
    );
  }
}

class coOrganizer {
  final String name;
  final String email;

  coOrganizer({required this.name, required this.email});

  factory coOrganizer.fromJson(Map<String, dynamic> json) {
    final rawName = json['coOrganizerName'].toString().trim();
    final rawEmail = json['coOrganizerEmail'].toString().trim();

    final safeName =
        rawName.isNotEmpty
            ? rawName
            : (rawEmail.isNotEmpty ? rawEmail.split('@').first : '未填寫名稱');

    return coOrganizer(name: safeName, email: rawEmail);
  }
}
