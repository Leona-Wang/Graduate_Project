import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_frontend/config.dart';
import 'package:flutter_frontend/screens/charity_screens/charity_map.dart';
import 'package:flutter_frontend/taiwan_address_helper.dart';
import 'package:latlong2/latlong.dart';
import '../../api_client.dart';

class CharityEditEventPage extends StatefulWidget {
  final int eventId;
  const CharityEditEventPage({super.key, required this.eventId});

  @override
  State<CharityEditEventPage> createState() => _CharityEditEventPageState();
}

class _CharityEditEventPageState extends State<CharityEditEventPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _startController = TextEditingController();
  final TextEditingController _endController = TextEditingController();
  final TextEditingController _ddlController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  String? _selectEventType;
  String _errorMessage = '';
  bool _isLoading = false;
  bool _isFetching = false;

  bool _isOnline = false; // 線上活動
  String? _originalName; // 後端以 name 當唯一識別，送出必帶

  LatLng? selectedLocationData;
  DateTime? _startDateTime;
  DateTime? _endDateTime;
  DateTime? _ddlDateTime;

  @override
  void initState() {
    super.initState();
    _fetchDetail();
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

      final resp = await apiClient
          .get(uriData)
          .timeout(const Duration(seconds: 10));

      if (resp.statusCode != 200) {
        setState(() => _errorMessage = '取得活動內容失敗：${resp.body}');
        return;
      }

      final data = jsonDecode(resp.body) as Map<String, dynamic>;

      // 後端欄位對應
      _originalName = (data['name'] ?? '').toString();
      _nameController.text = _originalName ?? '';

      _selectEventType =
          (data['eventType'] ?? '') == '' ? null : data['eventType'];
      _descriptionController.text = (data['description'] ?? '').toString();
      _isOnline = (data['online'] ?? false) == true;

      String startStr = (data['startTime'] ?? '').toString();
      String endStr = (data['endTime'] ?? '').toString();
      String ddlStr = (data['signupDeadline'] ?? '').toString();

      DateTime? tryParse(String s) {
        if (s.isEmpty) return null;
        try {
          return DateTime.parse(s);
        } catch (_) {
          return null;
        }
      }

      _startDateTime = tryParse(startStr);
      _endDateTime = tryParse(endStr);
      _ddlDateTime = tryParse(ddlStr);

      if (_startDateTime != null) {
        _startController.text = _formatDateTime(_startDateTime!);
      } else if (startStr.isNotEmpty) {
        _startController.text = startStr;
      }

      if (_endDateTime != null) {
        _endController.text = _formatDateTime(_endDateTime!);
      } else if (endStr.isNotEmpty) {
        _endController.text = endStr;
      }

      if (_ddlDateTime != null) {
        _ddlController.text = _formatDateTime(_ddlDateTime!);
      } else if (ddlStr.isNotEmpty) {
        _ddlController.text = ddlStr;
      }

      if (!_isOnline) {
        _locationController.text = (data['address'] ?? '').toString();
        final lat = (data['lat'] as num?)?.toDouble();
        final lng = (data['lng'] as num?)?.toDouble();
        if (lat != null && lng != null) {
          selectedLocationData = LatLng(lat, lng);
        }
      } else {
        _locationController.clear();
        selectedLocationData = null;
      }
    } catch (e) {
      setState(() => _errorMessage = '錯誤：$e');
    } finally {
      setState(() => _isFetching = false);
    }
  }

  Future<void> _submit() async {
    final name =
        _nameController.text.trim(); // 後端目前用 name 做唯一識別，實際送出以 _originalName 為準
    final start = _startController.text;
    final end = _endController.text;
    final ddl = _ddlController.text;
    final type = _selectEventType;
    final address = _locationController.text.trim();
    String? cityLocation;

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

      final uriData = ApiPath.createCharityEvent;

      // 只需傳要修改的欄位；未傳欄位不會被修改
      final body = <String, dynamic>{
        'name': _originalName, // 後端用它來定位活動，暫不允許修改 name
        'eventType': type,
        'online': _isOnline,
        'startTime': start,
        'endTime': end,
        'signupDeadline': ddl,
        'description': description,
        if (!_isOnline) 'location': cityLocation,
        if (!_isOnline) 'address': address,
      };

      final resp = await apiClient
          .post(uriData, body)
          .timeout(const Duration(seconds: 10));

      if (resp.statusCode == 200) {
        _showMessage('更新成功！');
        if (mounted) {
          Navigator.pushNamedAndRemoveUntil(
            context,
            '/charity_home',
            (_) => false,
          );
        }
      } else {
        setState(() => _errorMessage = '更新活動失敗：${resp.body}');
      }
    } catch (e) {
      setState(() => _errorMessage = '錯誤：$e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<DateTime?> pickDateTime(
    BuildContext context,
    DateTime? initialDateTime,
  ) async {
    final DateTime? date = await showDatePicker(
      context: context,
      firstDate: DateTime(2025, 01),
      lastDate: DateTime(2050, 12),
    );
    if (date == null) return null;

    final TimeOfDay? time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initialDateTime ?? DateTime.now()),
    );
    if (time == null) return null;

    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  String _formatDateTime(DateTime dt) {
    return "${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} "
        "${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";
  }

  void _showMessage(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('編輯活動')),
      body:
          _isFetching
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

                          // 名稱（目前後端不允許修改，設成 readOnly）
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
                              final selected = await pickDateTime(
                                context,
                                _startDateTime,
                              );
                              if (selected != null) {
                                setState(() {
                                  _startDateTime = selected;
                                  _startController.text = _formatDateTime(
                                    selected,
                                  );
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
                              final selected = await pickDateTime(
                                context,
                                _endDateTime,
                              );
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
                                  _endController.text = _formatDateTime(
                                    selected,
                                  );
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
                              final selected = await pickDateTime(
                                context,
                                _ddlDateTime,
                              );
                              if (selected != null) {
                                setState(() {
                                  _ddlDateTime = selected;
                                  _ddlController.text = _formatDateTime(
                                    selected,
                                  );
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
                            items:
                                const [
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
                                    ]
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
                                if (_errorMessage.isNotEmpty)
                                  _errorMessage = '';
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
                            onTap:
                                _isOnline
                                    ? null
                                    : () async {
                                      final result = await Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder:
                                              (context) => CharityMapPage(
                                                initialLatLng:
                                                    selectedLocationData,
                                                initialAddress:
                                                    _locationController.text,
                                              ),
                                        ),
                                      );
                                      if (result != null) {
                                        selectedLocationData = LatLng(
                                          result['lat'],
                                          result['lng'],
                                        );
                                        _locationController.text =
                                            result['address'];
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
                          ElevatedButton(
                            onPressed: _isLoading ? null : _submit,
                            child:
                                _isLoading
                                    ? const CircularProgressIndicator()
                                    : const Text('更新活動'),
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
              ),
    );
  }
}
