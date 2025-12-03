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
      final resp = await apiClient
          .get(url)
          .timeout(const Duration(seconds: 10));

      if (resp.statusCode >= 200 && resp.statusCode < 300) {
        final data =
            json.decode(utf8.decode(resp.bodyBytes)) as Map<String, dynamic>;
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

  bool get _isRewardType => _effectiveType() == 'reward';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 251, 247, 241),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Color(0xFFe6ccb2),
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.only(left: 12.0, top: 6.0, bottom: 6.0),
          child: CircleAvatar(
            backgroundColor: Colors.amber,
            child: IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back_ios_new, color: Colors.brown),
            ),
          ),
        ),
        title: Text(
          '信件詳情',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w900,
            color: Colors.brown[800]!,
          ),
        ),
      ),
      body: SafeArea(child: _buildBody()),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Color.fromARGB(255, 188, 66, 57)),
              ),
              const SizedBox(height: 12),
              FilledButton(onPressed: _fetchDetail, child: const Text('重試')),
            ],
          ),
        ),
      );
    }
    if (_mail == null) {
      return const Center(child: Text('找不到信件內容'));
    }

    final mail = _mail!;
    final theme = Theme.of(context);
    final titleStyle = theme.textTheme.titleLarge?.copyWith(
      fontWeight: FontWeight.bold,
      fontSize: 20,
      color: Colors.brown[800],
    );
    final sectionTitleStyle = theme.textTheme.titleMedium?.copyWith(
      fontWeight: FontWeight.w800,
      fontSize: 18,
      color: Colors.brown[700],
    );
    return RefreshIndicator(
      onRefresh: _fetchDetail,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 標題
          _buildHeaderCard(mail, titleStyle),
          const SizedBox(height: 20),

          // 內容卡片
          Text('信件內容', style: sectionTitleStyle),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFBF5),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.brown.withOpacity(0.18)),
              boxShadow: [
                BoxShadow(
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                  color: Colors.brown.withOpacity(0.08),
                ),
              ],
            ),
            child: Text(
              mail.content?.isNotEmpty == true ? mail.content! : '(無內容)',
              style: theme.textTheme.bodyMedium?.copyWith(
                height: 1.5,
                fontSize: 16,
                color: Colors.brown[900],
              ),
            ),
          ),

          const SizedBox(height: 24),
          const Divider(height: 1),
          const SizedBox(height: 12),

          // 互動：僅獎勵型信件需要動作
          if (_isRewardType) _buildRewardAction(mail, sectionTitleStyle),
        ],
      ),
    );
  }

  Widget _buildHeaderCard(MailDetail mail, TextStyle? titleStyle) {
    final isReward = _isRewardType;
    final isRead = mail.isRead == true;

    final iconData = isReward ? Icons.card_giftcard : Icons.mail_outline;
    final iconBg = isReward ? const Color(0xFFFFE082) : const Color(0xFFD7CCC8);

    final typeText = mail.type ?? (isReward ? '獎勵信件' : '一般信件');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFEFC),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            blurRadius: 8,
            offset: const Offset(0, 4),
            color: Colors.brown.withOpacity(0.10),
          ),
        ],
        border: Border.all(color: Colors.brown.withOpacity(0.15), width: 0.8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 上排：icon + 標題 + 狀態小標籤們
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: iconBg,
                  shape: BoxShape.circle,
                ),
                child: Icon(iconData, color: Colors.brown[800], size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      mail.title?.isNotEmpty == true ? mail.title! : '(無標題)',
                      style: titleStyle,
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        _buildTagChip(
                          isReward ? '獎勵信件' : typeText,
                          isReward
                              ? const Color(0xFFFFECB3)
                              : const Color(0xFFE0E0E0),
                          Colors.brown[800]!,
                        ),
                        _buildTagChip(
                          isRead ? '已讀' : '未讀',
                          isRead
                              ? const Color(0xFFE0F2F1)
                              : const Color(0xFFFFE0B2),
                          isRead
                              ? const Color(0xFF00695C)
                              : const Color(0xFFBF360C),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // 下排：寄件人 / 收件人 / 時間（灰字小資訊）
          Wrap(
            spacing: 16,
            runSpacing: 6,
            children: [
              if (mail.sender != null && mail.sender!.isNotEmpty)
                _buildInfoRow(Icons.person_outline, '寄件人：${mail.sender}'),
              if (mail.receiver != null && mail.receiver!.isNotEmpty)
                _buildInfoRow(Icons.person, '收件人：${mail.receiver}'),
              if (mail.date != null && mail.date!.isNotEmpty)
                _buildInfoRow(Icons.access_time, _fmtDate(mail.date)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTagChip(String text, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: fg),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: Colors.brown.withOpacity(0.7)),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(fontSize: 14, color: Colors.brown.withOpacity(0.8)),
        ),
      ],
    );
  }

  Widget _buildRewardAction(MailDetail mail, TextStyle? sectionTitleStyle) {
    final claimed =
        (mail.claimedAt != null && mail.claimedAt!.isNotEmpty) || _claimedLocal;

    return Container(
      margin: const EdgeInsets.only(top: 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.amber.shade300, width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Icon(Icons.card_giftcard, size: 28, color: Colors.amber),
              const SizedBox(width: 8),
              Text(
                '獎勵派發',
                style: sectionTitleStyle?.copyWith(fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              if (claimed)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green.shade600,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: const Text(
                    '已領取',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(255, 255, 176, 79),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: const Text(
                    '可領取',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed:
                      (_actionBusy || claimed) ? null : () => _onClaimReward(),
                  icon:
                      _actionBusy
                          ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                          : const Icon(Icons.touch_app),
                  label: Text(claimed ? '已領取獎勵' : '領取獎勵'),
                ),
              ),
            ],
          ),
          if (mail.claimedAt != null && mail.claimedAt!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(
                '領取時間：${_fmtDate(mail.claimedAt)}',
                style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _onClaimReward() async {
    if (_actionBusy) return;

    setState(() => _actionBusy = true);

    try {
      final apiClient = ApiClient();
      await apiClient.init();

      final url = ApiPath.sendReward(widget.mailId);
      final resp = await apiClient
          .post(url, const {})
          .timeout(const Duration(seconds: 10));

      if (resp.statusCode >= 200 && resp.statusCode < 300) {
        try {
          final data =
              json.decode(utf8.decode(resp.bodyBytes)) as Map<String, dynamic>;
          if (data['success'] == true) {
            _claimedLocal = true;
          } else {
            if (!mounted) return;
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('領取失敗：伺服器返回失敗狀態')));
            return;
          }
        } catch (_) {
          _claimedLocal = true;
        }

        if (!mounted) return;

        await showDialog(
          context: context,
          builder:
              (context) => AlertDialog(
                title: const Text('領取成功'),
                content: const Text('你的獎勵已成功領取。'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('好'),
                  ),
                ],
              ),
        );

        if (!mounted) return;
        Navigator.of(context).pop();

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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('領取失敗：$e')));
    } finally {
      if (mounted) setState(() => _actionBusy = false);
    }
  }

  String _fmtDate(String? iso) {
    if (iso == null || iso.isEmpty) return '—';
    return iso.replaceFirst('T', ' ');
  }
}

// class _MetaChip extends StatelessWidget {
//   final IconData icon;
//   final String label;
//   const _MetaChip({required this.icon, required this.label});

//   @override
//   Widget build(BuildContext context) {
//     return Chip(
//       avatar: Icon(icon, size: 16),
//       label: Text(label),
//       materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
//     );
//   }
// }

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
