import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_frontend/api_client.dart';
import 'package:flutter_frontend/config.dart'; // ApiPath.getMailDetail / ApiPath.sendReward

class MessageDetailPage extends StatefulWidget {
  final int mailId;
  final String? typeHint;

  const MessageDetailPage({super.key, required this.mailId, this.typeHint});

  @override
  State<MessageDetailPage> createState() => _MessageDetailPageState();
}

class _MessageDetailPageState extends State<MessageDetailPage> {
  bool _loading = true;
  String? _error;
  MailDetail? _mail;
  bool _actionBusy = false; // 防重點擊
  bool _claimedLocal = false; // 後端沒提供 claimed 狀態時的本地 fallback

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
      final apiClient = ApiClient();
      await apiClient.init();

      final url = ApiPath.getMailDetail(widget.mailId);
      final resp = await apiClient.get(url).timeout(const Duration(seconds: 10));

      if (resp.statusCode >= 200 && resp.statusCode < 300) {
        final data = json.decode(utf8.decode(resp.bodyBytes)) as Map<String, dynamic>;
        if (data['success'] == true && data['mail'] is Map<String, dynamic>) {
          setState(() {
            _mail = MailDetail.fromJson(data['mail'] as Map<String, dynamic>);
            _loading = false;
            // 若後端已有 claimedAt，則以後端為準覆蓋本地旗標
            if (_mail?.claimedAt != null && _mail!.claimedAt!.isNotEmpty) {
              _claimedLocal = true;
            }
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
    final t = _mail?.type?.trim();
    if (t != null && t.isNotEmpty) return t;
    return widget.typeHint?.trim() ?? '';
  }

  bool get _isRewardType {
    final t = _effectiveType();
    // 依實際後端 type 調整
    return ["reward", "獎勵", "獎勵派發", "活動獎勵"].contains(t);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('信件詳情')),
      body: SafeArea(child: _buildBody()),
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
            FilledButton(onPressed: _fetchDetail, child: const Text('重試')),
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
          // 標題
          Text(
            mail.title ?? '(無標題)',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),

          // 中繼資訊
          Wrap(
            spacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _MetaChip(icon: Icons.person_outline, label: mail.sender ?? '—'),
              _MetaChip(icon: Icons.person, label: mail.receiver ?? '—'),
              _MetaChip(icon: Icons.access_time, label: _fmtDate(mail.date)),
              _MetaChip(icon: Icons.sell_outlined, label: mail.type ?? '—'),
              _MetaChip(
                icon: Icons.mark_email_read_outlined,
                label: mail.isRead == true ? '已讀' : '未讀',
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 內容
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

          // 互動：僅獎勵型信件需要動作
          if (_isRewardType) _buildRewardAction(mail),
        ],
      ),
    );
  }

  Widget _buildRewardAction(MailDetail mail) {
    final claimed = (mail.claimedAt != null && mail.claimedAt!.isNotEmpty) || _claimedLocal;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('獎勵派發', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: FilledButton.icon(
                onPressed: (_actionBusy || claimed) ? null : () => _onClaimReward(),
                icon: _actionBusy
                    ? const SizedBox(
                        width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.card_giftcard),
                label: Text(claimed ? '已領取' : '領取獎勵'),
              ),
            ),
          ],
        ),
        if (mail.claimedAt != null && mail.claimedAt!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Text('領取時間：${_fmtDate(mail.claimedAt)}',
                style: TextStyle(color: Colors.grey.shade700)),
          ),
      ],
    );
  }

  Future<void> _onClaimReward() async {
    setState(() => _actionBusy = true);

    try {
      final apiClient = ApiClient();
      await apiClient.init();

      final url = ApiPath.sendReward(widget.mailId);
      final resp = await apiClient.post(url, const {}).timeout(const Duration(seconds: 10));

      if (resp.statusCode >= 200 && resp.statusCode < 300) {
        try {
          final data = json.decode(utf8.decode(resp.bodyBytes)) as Map<String, dynamic>;
          if (data['success'] == true) {
            _claimedLocal = true;
          }
        } catch (_) {
          _claimedLocal = true;
        }

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

        await _fetchDetail();
      } else {
        if (!mounted) return;
        final msg = utf8.decode(resp.bodyBytes);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('領取失敗（${resp.statusCode}）：$msg')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('領取失敗：$e')));
    } finally {
      if (mounted) setState(() => _actionBusy = false);
    }
  }

  String _fmtDate(String? iso) {
    if (iso == null || iso.isEmpty) return '—';
    return iso.replaceFirst('T', ' ');
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
  final String? type; // e.g. reward（實際以後端定義為準）
  final String? title;
  final String? content;
  final bool? isRead;

  // 可能存在（若後端提供）
  final String? claimedAt;

  MailDetail({
    this.sender,
    this.receiver,
    this.date,
    this.type,
    this.title,
    this.content,
    this.isRead,
    this.claimedAt,
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
      claimedAt: json['claimedAt'] as String?, // 若後端暫無此欄，會是 null
    );
  }
}
