import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_frontend/config.dart';
import 'package:flutter_frontend/api_client.dart';

class CharityCoorganizerPage extends StatefulWidget {
  final int? eventId; // 可不帶；不帶就先選活動
  const CharityCoorganizerPage({super.key, this.eventId});

  @override
  State<CharityCoorganizerPage> createState() => _CharityCoorganizerPageState();
}

class _CharityCoorganizerPageState extends State<CharityCoorganizerPage> {
  int? _eventId;
  String? _eventName; // API 以 name 為主，所以要把 id 轉成 name
  bool _loading = false;
  bool _busy = false;

  final ApiClient _api = ApiClient();
  List<Map<String, dynamic>> _applications = [];

  @override
  void initState() {
    super.initState();
    _eventId = widget.eventId;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _api.init();
      if (_eventId == null) {
        await _pickEvent(); // 先選活動
      } else {
        await _ensureEventName(); // 用 id 換 name
        await _loadApplications();
      }
    });
  }

  Future<void> _ensureEventName() async {
    if (_eventName != null || _eventId == null) return;
    final url = ApiPath.charityEventDetail(_eventId!); // GET /events/{id}/
    final resp = await _api.get(url).timeout(const Duration(seconds: 10));
    if (resp.statusCode == 200) {
      final map = json.decode(utf8.decode(resp.bodyBytes)) as Map<String, dynamic>;
      _eventName = (map['name'] ?? map['eventName'] ?? '').toString();
    } else {
      throw Exception('取得活動名稱失敗 (${resp.statusCode})');
    }
  }

  Future<void> _loadApplications() async {
    if (_eventName == null || _eventName!.isEmpty) return;
    setState(() => _loading = true);
    try {
      final url = ApiPath.getCoOrganizeApplications; // POST /charity/event/coorganize/applications/
      final resp = await _api
          .post(url, {'charityEventName': _eventName})
          .timeout(const Duration(seconds: 10));
      if (resp.statusCode == 200) {
        final list = json.decode(utf8.decode(resp.bodyBytes)) as List;
        _applications = list.cast<Map<String, dynamic>>();
      } else {
        throw Exception('讀取協辦申請失敗 (${resp.statusCode})');
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _verify(String coOrganizerName, bool approve) async {
    if (_eventName == null) return;
    setState(() => _busy = true);
    try {
      final url = ApiPath.verifyCoOrganize; // POST /charity/event/coorganize/verify/
      final resp = await _api
          .post(url, {
            'charityEventName': _eventName,
            'coOrganizerName': coOrganizerName,
            'approve': approve,
          })
          .timeout(const Duration(seconds: 10));
      if (resp.statusCode == 200) {
        // 本地同步狀態
        final idx = _applications.indexWhere((a) => a['coOrganizerName'] == coOrganizerName);
        if (idx != -1) {
          _applications[idx] = {
            ..._applications[idx],
            'verified': approve, // true/false
          };
          setState(() {});
        }
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(approve ? '已接受 $coOrganizerName' : '已拒絕 $coOrganizerName')),
        );
      } else {
        throw Exception('審核失敗 (${resp.statusCode})');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _pickEvent() async {
    final chosen = await showModalBottomSheet<_PickResult>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const _EventPickerSheet(),
    );
    if (chosen != null) {
      setState(() {
        _eventId = chosen.id;
        _eventName = chosen.name;
      });
      await _loadApplications();
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = _eventName == null
        ? '協辦申請審核（尚未選活動）'
        : '協辦申請審核 (${_eventName ?? ""})';

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          if (_eventName == null)
            TextButton(onPressed: _pickEvent, child: const Text('選活動')),
          if (_eventName != null)
            IconButton(
              onPressed: _loading ? null : _loadApplications,
              icon: const Icon(Icons.refresh),
              tooltip: '重新整理',
            ),
        ],
      ),
      body: _eventName == null
          ? Center(
              child: ElevatedButton.icon(
                onPressed: _pickEvent,
                icon: const Icon(Icons.event),
                label: const Text('選擇活動'),
              ),
            )
          : _loading
              ? const Center(child: CircularProgressIndicator())
              : _applications.isEmpty
                  ? const Center(child: Text('目前沒有待審核的協辦申請'))
                  : ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: _applications.length,
                      itemBuilder: (context, index) {
                        final app = _applications[index];
                        final coName = (app['coOrganizerName'] ?? '').toString();
                        final verified = app['verified']; // null/true/false
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('申請單位：$coName',
                                    style: const TextStyle(
                                        fontSize: 16, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 4),
                                Text('Email：${app['coOrganizerEmail'] ?? '-'}'),
                                const SizedBox(height: 8),
                                _buildStatusArea(coName, verified),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
    );
  }

  Widget _buildStatusArea(String coName, dynamic verified) {
    if (verified == null) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          ElevatedButton.icon(
            onPressed: _busy ? null : () => _verify(coName, true),
            icon: const Icon(Icons.check),
            label: const Text('接受'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
          ),
          const SizedBox(width: 8),
          ElevatedButton.icon(
            onPressed: _busy ? null : () => _verify(coName, false),
            icon: const Icon(Icons.close),
            label: const Text('拒絕'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          ),
        ],
      );
    } else if (verified == true) {
      return const Text('✅ 已接受',
          style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold));
    } else {
      return const Text('❌ 已拒絕',
          style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold));
    }
  }
}

/* ───────────────── 活動挑選 bottom sheet（實串 events/） ──────────────── */

class _PickResult {
  final int id;
  final String name;
  const _PickResult(this.id, this.name);
}

class _EventPickerSheet extends StatefulWidget {
  const _EventPickerSheet();
  @override
  State<_EventPickerSheet> createState() => _EventPickerSheetState();
}

class _EventPickerSheetState extends State<_EventPickerSheet> {
  bool _loading = true;
  List<_PickResult> _items = [];

  final ApiClient _api = ApiClient(); // ← 新增

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      await _api.init(); // ← 新增
      final url = ApiPath.charityEventList; // GET /events/
      final resp = await _api.get(url).timeout(const Duration(seconds: 10));
      if (resp.statusCode == 200) {
        final list = json.decode(utf8.decode(resp.bodyBytes)) as List;
        _items = list
            .map((e) => e as Map<String, dynamic>)
            .map((m) => _PickResult(m['id'] as int, (m['name'] ?? '').toString()))
            .toList();
      } else {
        throw Exception('讀取活動清單失敗 (${resp.statusCode})');
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('選擇活動', style: TextStyle(fontSize: 18)),
                  const SizedBox(height: 12),
                  for (final it in _items)
                    ListTile(
                      title: Text(it.name.isEmpty ? '(未命名活動)' : it.name),
                      subtitle: Text('ID: ${it.id}'),
                      onTap: () => Navigator.pop<_PickResult>(context, it),
                    ),
                ],
              ),
      ),
    );
  }
}
