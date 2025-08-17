import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_frontend/config.dart'; // ApiPath.getMailDetail


///獎勵派發要等API
///催票詢問要等API
class MessageDetailPage extends StatefulWidget {
  final int mailId;
  final String? typeHint;

  const MessageDetailPage({
    super.key,
    required this.mailId,
    this.typeHint,
  });

  @override
  State<MessageDetailPage> createState() => _MessageDetailPageState();
}

class _MessageDetailPageState extends State<MessageDetailPage> {
  bool _loading = true;
  String? _error;
  MailDetail? _mail;
  bool _actionBusy = false; // 按鈕防重點

  @override
  void initState() {
    super.initState();
    _fetchDetail();
  }

  Future<void> _fetchDetail() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final url = ApiPath.getMailDetail(widget.mailId);
      final resp = await http.get(Uri.parse(url));

      if (resp.statusCode >= 200 && resp.statusCode < 300) {
        final data = json.decode(utf8.decode(resp.bodyBytes)) as Map<String, dynamic>;
        if (data['success'] == true && data['mail'] is Map<String, dynamic>) {
          setState(() {
            _mail = MailDetail.fromJson(data['mail'] as Map<String, dynamic>);
            _loading = false;
          });
        } else {
          setState(() {
            _error = '資料格式不正確';
            _loading = false;
          });
        }
      } else {
        setState(() {
          _error = '伺服器回應 ${resp.statusCode}';
          _loading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = '讀取失敗：$e';
        _loading = false;
      });
    }
  }

  String _effectiveType() {
    // 以 API 回傳為主，沒有就用 hint
    final t = _mail?.type?.trim();
    if (t != null && t.isNotEmpty) return t;
    return widget.typeHint?.trim() ?? '';
  }

  bool get _isRewardType {
    final t = _effectiveType();
    // 以後端定義為準
    return ["reward", "獎勵", "獎勵派發", "活動獎勵"].contains(t);
  }

  bool get _isGroupReminderType {
    final t = _effectiveType();
    return ["group_reminder", "催票", "催票詢問", "團體催票"].contains(t);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('信件詳情')),
      body: SafeArea(
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_error!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: _fetchDetail,
              child: const Text('重試'),
            ),
          ],
        ),
      );
    }
    if (_mail == null) {
      return const Center(child: Text('找不到信件內容'));
    }

    final mail = _mail!;

    return RefreshIndicator(
      onRefresh: _fetchDetail,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 信件主體
          Text(mail.title ?? '(無標題)', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Wrap(
            spacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _MetaChip(icon: Icons.person_outline, label: mail.sender ?? '—'),
              _MetaChip(icon: Icons.person, label: mail.receiver ?? '—'),
              _MetaChip(icon: Icons.access_time, label: mail.date ?? '—'),
              _MetaChip(icon: Icons.sell_outlined, label: mail.type ?? '—'),
              _MetaChip(icon: Icons.mark_email_read_outlined, label: mail.isRead == true ? '已讀' : '未讀'),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Text(mail.content ?? '(無內容)'),
          ),

          const SizedBox(height: 24),
          const Divider(height: 1),
          const SizedBox(height: 12),

          // 下半部：依類型顯示互動區
          if (_isRewardType) _buildRewardAction(mail) else if (_isGroupReminderType) _buildGroupReminderAction(mail) else _buildUnknownTypeHint(),
        ],
      ),
    );
  }

  Widget _buildUnknownTypeHint() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('（這封信件的類型未定義，暫無互動動作）', style: TextStyle(color: Colors.grey.shade600)),
      ],
    );
  }

  Widget _buildRewardAction(MailDetail mail) {
    final claimed = mail.claimedAt != null; // 等後端

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('獎勵派發', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: FilledButton.icon(
                onPressed: (_actionBusy || claimed) ? null : () => _onClaimReward(mail),
                icon: _actionBusy ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.card_giftcard),
                label: Text(claimed ? '已領取' : '領取獎勵'),
              ),
            ),
          ],
        ),
        if (claimed)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Text('領取時間：${mail.claimedAt}', style: TextStyle(color: Colors.grey.shade700)),
          ),
      ],
    );
  }

  Future<void> _onClaimReward(MailDetail mail) async {
    setState(() => _actionBusy = true);

    try {
      // TODO: 等後端提供 claim API，例如：POST /mail/{id}/claim/
      // final url = ApiPath.claimMailReward(widget.mailId);
      // final resp = await http.post(Uri.parse(url));
      // if (resp.statusCode == 200) { ... }

      await Future.delayed(const Duration(milliseconds: 400)); // 模擬等待

      if (!mounted) return;
      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('領取成功'),
          content: const Text('你的獎勵已成功領取。'),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('好')), 
          ],
        ),
      );

      // 取得最新狀態（若後端之後會回傳 claimedAt 等欄位）
      await _fetchDetail();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('領取失敗：$e')),
      );
    } finally {
      if (mounted) setState(() => _actionBusy = false);
    }
  }

  Widget _buildGroupReminderAction(MailDetail mail) {
    final responded = mail.responded == true;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('催票詢問', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: (_actionBusy || responded) ? null : () => _onRespondYesNo('yes'),
                child: const Text('是'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton(
                onPressed: (_actionBusy || responded) ? null : () => _onRespondYesNo('no'),
                child: const Text('否'),
              ),
            ),
          ],
        ),
        if (responded)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Text('已回覆：${mail.response ?? '-'}', style: TextStyle(color: Colors.grey.shade700)),
          ),
      ],
    );
  }

  Future<void> _onRespondYesNo(String choice) async {
    setState(() => _actionBusy = true);

    try {
      // TODO: 等後端提供 respond API，例如：POST /mail/{id}/respond/，body: { response: yes | no }
      // final url = ApiPath.respondMail(widget.mailId);
      // final resp = await http.post(Uri.parse(url), body: json.encode({ 'response': choice }), headers: { 'Content-Type': 'application/json' });
      // if (resp.statusCode == 200) { ... }

      await Future.delayed(const Duration(milliseconds: 300)); // 模擬等待

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('已回覆：$choice')),
      );

      await _fetchDetail();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('回覆失敗：$e')),
      );
    } finally {
      if (mounted) setState(() => _actionBusy = false);
    }
  }
}

class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _MetaChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: Icon(icon, size: 16),
      label: Text(label),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }
}

class MailDetail {
  final String? sender;
  final String? receiver;
  final String? date;
  final String? type; // e.g. reward / group_reminder（實際以後端定義為準）
  final String? title;
  final String? content;
  final bool? isRead;

  // 以下欄位未必存在；若後端之後提供可直接接上
  final String? claimedAt;
  final bool? responded;
  final String? response; // yes/no

  MailDetail({
    this.sender,
    this.receiver,
    this.date,
    this.type,
    this.title,
    this.content,
    this.isRead,
    this.claimedAt,
    this.responded,
    this.response,
  });

  factory MailDetail.fromJson(Map<String, dynamic> json) {
    return MailDetail(
      sender: json['sender'] as String?,
      receiver: json['receiver'] as String?,
      date: json['date'] as String?,
      type: json['type'] as String?,
      title: json['title'] as String?,
      content: json['content'] as String?,
      isRead: json['isRead'] as bool?,
      claimedAt: json['claimedAt'] as String?,
      responded: json['responded'] as bool?,
      response: json['response'] as String?,
    );
  }
}
