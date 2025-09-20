import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_frontend/config.dart';
import 'package:flutter_frontend/screens/charity_screens/charity_map.dart';
import 'package:flutter_frontend/taiwan_address_helper.dart';
import 'package:latlong2/latlong.dart';
import '../../api_client.dart';

class CharityEditEventPage extends StatefulWidget {
  final int eventId;

  /// 從詳情頁可傳入舊資料，讓本頁在 API 回來前就能先顯示
  final Map<String, dynamic>? initialEventJson;

  const CharityEditEventPage({
    super.key,
    required this.eventId,
    this.initialEventJson,
  });

  @override
  State<CharityEditEventPage> createState() => _CharityEditEventPageState();
}

class _CharityEditEventPageState extends State<CharityEditEventPage> {
  // Controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _startController = TextEditingController();
  final TextEditingController _endController = TextEditingController();
  final TextEditingController _ddlController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  // State
  String? _selectEventType;
  String _errorMessage = '';
  bool _isLoading = false;
  bool _isFetching = false;
  bool _isOnline = false; // 線上活動

  /// 後端以 name 當唯一識別，送出必帶（不可修改）
  String? _originalName;

  LatLng? selectedLocationData;
  DateTime? _startDateTime;
  DateTime? _endDateTime;
  DateTime? _ddlDateTime;

  static const List<String> _allowedTypes = [
    '綜合性服務',
    '兒童青少年福利',
    '婦女福利',
    '老人福利',
    '身心障礙福利',
    '家庭福利',
    '健康醫療',
    '心理衛生',
    '社區規劃(營造)',
    '環境保護',
    '國際合作交流',
    '教育與科學',
    '文化藝術',
    '人權和平',
    '消費者保護',
    '性別平等',
    '政府單位',
    '動物保護',
  ];

  @override
  void initState() {
    super.initState();

    // 先用詳情頁帶來的資料立即預填（若有）
    if (widget.initialEventJson != null) {
      _applyFromJson(widget.initialEventJson!);
    }

    // 再向後端取最新資料覆寫
    _fetchDetail();
  }

  // ------ Helpers ------

  /// 從可能不同來源鍵名的 JSON 取第一個非空值
  T? _pick<T>(Map<String, dynamic> m, List<String> keys) {
    for (final k in keys) {
      if (!m.containsKey(k)) continue;
      final v = m[k];
      if (v == null) continue;
      if (v is String && v.trim().isEmpty) continue;
      return v as T;
    }
    return null;
  }

  DateTime? _tryParseDate(dynamic v) {
    if (v == null) return null;
    if (v is DateTime) return v;
    final s = v.toString().trim();
    if (s.isEmpty) return null;
    try {
      return DateTime.parse(s);
    } catch (_) {
      return null;
    }
  }

  String _formatDateTime(DateTime dt) {
    return "${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} "
        "${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";
  }

  void _showMessage(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  /// 把後端（或外部傳入）的 JSON 資料套用到畫面與狀態
  void _applyFromJson(Map<String, dynamic> data) {
    String asString(dynamic v, [String fallback = '']) =>
        (v == null || (v is String && v.isEmpty)) ? fallback : v.toString();

    // name 有些來源用 title
    _originalName = asString(_pick<String>(data, ['name', 'title']));
    _nameController.text = _originalName ?? '';

    // eventType 有些來源用 type
    _selectEventType = _pick<String>(data, ['eventType', 'type']);

    // description 容錯
    _descriptionController.text =
        asString(_pick<String>(data, ['description', 'desc', 'content']));

    // 線上活動，有些來源用 isOnline / is_online
    final onlineVal = _pick<dynamic>(data, ['online', 'isOnline', 'is_online']);
    _isOnline =
        (onlineVal == true) || (onlineVal == 1) || (onlineVal == 'true');

    // 時間鍵名容錯
    _startDateTime =
        _tryParseDate(_pick(data, ['startTime', 'start_time', 'start']));
    _endDateTime =
        _tryParseDate(_pick(data, ['endTime', 'end_time', 'end']));
    _ddlDateTime = _tryParseDate(
        _pick(data, ['signupDeadline', 'deadline', 'ddl']));

    _startController.text = _startDateTime != null
        ? _formatDateTime(_startDateTime!)
        : asString(_pick(data, ['startTime', 'start_time', 'start']));
    _endController.text = _endDateTime != null
        ? _formatDateTime(_endDateTime!)
        : asString(_pick(data, ['endTime', 'end_time', 'end']));
    _ddlController.text = _ddlDateTime != null
        ? _formatDateTime(_ddlDateTime!)
        : asString(_pick(data, ['signupDeadline', 'deadline', 'ddl']));

    // 地址/座標：有些來源 address 在 'address'，有些在 'location' 或 'city'
    String? address =
        _pick<String>(data, ['address', 'location', 'city', 'addr']);

    // 先直接找平鋪 lat/lng
    double? lat = (_pick<num>(data, ['lat', 'latitude']) as num?)?.toDouble();
    double? lng =
        (_pick<num>(data, ['lng', 'lon', 'long', 'longitude']) as num?)
            ?.toDouble();

    // 若座標包在一個物件裡（例如 data['location'] = {'lat': ..., 'lng': ..., 'address': ...}）
    final locObj = _pick<Map<String, dynamic>>(data, ['location']);
    if (locObj != null) {
      address ??= _pick<String>(locObj, ['address', 'addr', 'name']);
      lat ??= (_pick<num>(locObj, ['lat', 'latitude']) as num?)?.toDouble();
      lng ??=
          (_pick<num>(locObj, ['lng', 'lon', 'long', 'longitude']) as num?)
              ?.toDouble();
    }

    if (!_isOnline) {
      _locationController.text = asString(address);
      selectedLocationData =
          (lat != null && lng != null) ? LatLng(lat, lng) : null;
    } else {
      _locationController.clear();
      selectedLocationData = null;
    }

    // Dropdown 初始值需要落在 items 清單範圍內
    if (_selectEventType != null && !_allowedTypes.contains(_selectEventType)) {
      _selectEventType = null;
    }

    if (mounted) setState(() {});
  }

  Future<void> _fetchDetail() async {
    setState(() {
      _isFetching = true;
      _errorMessage = '';
    });

    try {
      final apiClient = ApiClient();
      await apiClient.init();

      final uriData = ApiPath.charityEventDetail(widget.eventId);
      final resp =
          await apiClient.get(uriData).timeout(const Duration(seconds: 15));

      if (resp.statusCode != 200) {
        setState(() => _errorMessage = '取得活動內容失敗：${resp.body}');
        return;
      }

      final raw = jsonDecode(resp.body);

      // 容錯：有些後端會包一層 event/data/result
      final Map<String, dynamic> data = switch (raw) {
        Map<String, dynamic> m
            when m['event'] is Map<String, dynamic> =>
          m['event'] as Map<String, dynamic>,
        Map<String, dynamic> m
            when m['data'] is Map<String, dynamic> =>
          m['data'] as Map<String, dynamic>,
        Map<String, dynamic> m
            when m['result'] is Map<String, dynamic> =>
          m['result'] as Map<String, dynamic>,
        Map<String, dynamic> m => m,
        _ => <String, dynamic>{},
      };

      _applyFromJson(data);
    } catch (e) {
      setState(() => _errorMessage = '錯誤：$e');
    } finally {
      if (mounted) setState(() => _isFetching = false);
    }
  }

  Future<DateTime?> _pickDateTime(
    BuildContext context,
    DateTime? initialDateTime,
  ) async {
    final DateTime? date = await showDatePicker(
      context: context,
      firstDate: DateTime(2020, 1),
      lastDate: DateTime(2050, 12),
      initialDate: initialDateTime ?? DateTime.now(),
    );
    if (date == null) return null;

    final TimeOfDay? time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initialDateTime ?? DateTime.now()),
    );
    if (time == null) return null;

    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  Future<void> _submit() async {
    final name = _nameController.text.trim();
    final start = _startController.text.trim();
    final end = _endController.text.trim();
    final ddl = _ddlController.text.trim();
    final type = _selectEventType;
    final address = _locationController.text.trim();
    String? cityLocation;

    // 驗證
    if ((_originalName ?? '').isEmpty) {
      setState(() => _errorMessage = '缺少活動識別（name），請重新載入頁面');
      return;
    }
    if (start.isEmpty) {
      setState(() => _errorMessage = '請輸入活動開始時程');
      return;
    }
    if (end.isEmpty) {
      setState(() => _errorMessage = '請輸入活動結束時程');
      return;
    }
    if (_startDateTime != null &&
        _endDateTime != null &&
        _endDateTime!.isBefore(_startDateTime!)) {
      setState(() => _errorMessage = '結束時間不可早於開始時間');
      return;
    }
    if (type == null) {
      setState(() => _errorMessage = '請選擇您的活動類型');
      return;
    }
    if (!_isOnline) {
      if (address.isEmpty) {
        setState(() => _errorMessage = '請選擇地點');
        return;
      }
      if (selectedLocationData == null) {
        setState(() => _errorMessage = '請選擇地點');
        return;
      }
      cityLocation = await TaiwanAddressHelper.getCityFromCoordinates(
        selectedLocationData!,
      );
    }
    final description = _descriptionController.text.trim();
    if (description.isEmpty) {
      setState(() => _errorMessage = '請描述你的活動內容');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final apiClient = ApiClient();
      await apiClient.init();

      final uriData = ApiPath.editCharityEvent;

      // 只傳需要修改的欄位；未傳不會被後端覆寫
      final body = <String, dynamic>{
        'name': _originalName, // 後端用它定位活動，不允許修改 name
        'eventType': type,
        'online': _isOnline,
        'startTime': start,
        'endTime': end,
        'signupDeadline': ddl,
        'description': description,
        if (!_isOnline) 'location': cityLocation, // 例如 "新竹市"
        if (!_isOnline) 'address': address,
        // 若需要也可一併傳座標：
        if (!_isOnline && selectedLocationData != null) 'lat': selectedLocationData!.latitude,
        if (!_isOnline && selectedLocationData != null) 'lng': selectedLocationData!.longitude,
      };

      final resp =
          await apiClient.post(uriData, body).timeout(const Duration(seconds: 15));

      if (resp.statusCode == 200 || resp.statusCode == 201) {
        _showMessage('更新成功！');
        if (mounted) Navigator.pop(context, true); // 回詳情頁，觸發刷新
      } else {
        setState(() => _errorMessage = '更新活動失敗：${resp.statusCode} ${resp.body}');
      }
    } catch (e) {
      setState(() => _errorMessage = '錯誤：$e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ------ UI ------

  @override
  void dispose() {
    _nameController.dispose();
    _startController.dispose();
    _endController.dispose();
    _ddlController.dispose();
    _locationController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final body = _isFetching
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            child: Align(
              alignment: Alignment.topCenter,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 500),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const SizedBox(height: 16),

                      // 線上活動開關
                      SwitchListTile(
                        title: const Text('線上活動'),
                        value: _isOnline,
                        onChanged: (v) {
                          setState(() {
                            _isOnline = v;
                            if (_isOnline) {
                              _locationController.clear();
                              selectedLocationData = null;
                            }
                          });
                        },
                      ),
                      const SizedBox(height: 8),

                      // 名稱（後端不允許修改，設成 readOnly）
                      TextFormField(
                        controller: _nameController,
                        readOnly: true,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          labelText: '活動名稱（不可修改）',
                        ),
                      ),
                      const SizedBox(height: 16),

                      // 開始
                      TextFormField(
                        controller: _startController,
                        readOnly: true,
                        onTap: () async {
                          final selected =
                              await _pickDateTime(context, _startDateTime);
                          if (selected != null) {
                            setState(() {
                              _startDateTime = selected;
                              _startController.text = _formatDateTime(selected);
                            });
                          }
                        },
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          labelText: '活動開始日期與時間',
                          helperText: '請選擇時程',
                        ),
                      ),
                      const SizedBox(height: 16),

                      // 結束
                      TextFormField(
                        controller: _endController,
                        readOnly: true,
                        onTap: () async {
                          final selected =
                              await _pickDateTime(context, _endDateTime);
                          if (selected != null) {
                            if (_startDateTime != null &&
                                selected.isBefore(_startDateTime!)) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('結束時間不可早於開始時間'),
                                ),
                              );
                              return;
                            }
                            setState(() {
                              _endDateTime = selected;
                              _endController.text = _formatDateTime(selected);
                            });
                          }
                        },
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          labelText: '活動結束日期與時間',
                          helperText: '請選擇時程',
                        ),
                      ),
                      const SizedBox(height: 16),

                      // 報名截止
                      TextFormField(
                        controller: _ddlController,
                        readOnly: true,
                        onTap: () async {
                          final selected =
                              await _pickDateTime(context, _ddlDateTime);
                          if (selected != null) {
                            setState(() {
                              _ddlDateTime = selected;
                              _ddlController.text = _formatDateTime(selected);
                            });
                          }
                        },
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          labelText: '活動報名截止期限',
                          helperText: '請選擇時程',
                        ),
                      ),
                      const SizedBox(height: 16),

                      // 類型
                      DropdownButtonFormField<String>(
                        value: _selectEventType,
                        hint: const Text('請選擇您的活動類型'),
                        items: _allowedTypes
                            .map(
                              (e) => DropdownMenuItem(
                                value: e,
                                child: Text(e),
                              ),
                            )
                            .toList(),
                        onChanged: (val) {
                          setState(() {
                            _selectEventType = val;
                            if (_errorMessage.isNotEmpty) _errorMessage = '';
                          });
                        },
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          labelText: '活動類型',
                        ),
                      ),
                      const SizedBox(height: 16),

                      // 地點（線上活動停用）
                      TextFormField(
                        controller: _locationController,
                        readOnly: true,
                        enabled: !_isOnline,
                        onTap: _isOnline
                            ? null
                            : () async {
                                final result = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => CharityMapPage(
                                      initialLatLng: selectedLocationData,
                                      initialAddress: _locationController.text,
                                    ),
                                  ),
                                );
                                if (result != null) {
                                  selectedLocationData =
                                      LatLng(result['lat'], result['lng']);
                                  _locationController.text = result['address'];
                                }
                              },
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          labelText: '活動地點',
                          helperText: '線上活動不需選擇地點',
                          suffixIcon: Icon(Icons.map),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // 詳情
                      TextFormField(
                        controller: _descriptionController,
                        maxLines: 8,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          labelText: '活動詳情',
                          helperText: '請輸入活動內容詳情',
                        ),
                      ),
                      const SizedBox(height: 16),

                      // 送出
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _submit,
                          child: _isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Text('更新活動'),
                        ),
                      ),

                      if (_errorMessage.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Text(
                          _errorMessage,
                          style: const TextStyle(color: Colors.redAccent),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          );

    return Scaffold(
      appBar: AppBar(title: const Text('編輯活動')),
      body: body,
    );
  }
}
