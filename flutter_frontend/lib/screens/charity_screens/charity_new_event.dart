import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_frontend/config.dart';
import 'package:flutter_frontend/screens/charity_screens/charity_map.dart';

import 'package:latlong2/latlong.dart';
import 'package:flutter_frontend/taiwan_address_helper.dart';

import '../../api_client.dart';

class CharityNewEventPage extends StatefulWidget {
  const CharityNewEventPage({super.key});

  @override
  State<CharityNewEventPage> createState() => CharityNewEventState();
}

class CharityNewEventState extends State<CharityNewEventPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _startController = TextEditingController();
  final TextEditingController _endController = TextEditingController();
  final TextEditingController _ddlController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  String? _selectEventType;

  String _errorMessage = '';

  bool _isLoading = false;
  bool _isOnline = false;
  // bool _isPermanent = false; //常駐活動

  LatLng? selectedLocationData;
  DateTime? _startDateTime;
  DateTime? _endDateTime;
  DateTime? _ddlDateTime;

  //late LatLng location;

  Future<void> _submit() async {
    final name = _nameController.text.trim();
    final start = _startController.text;
    final end = _endController.text;
    final ddl = _ddlController.text;
    final type = _selectEventType;
    final address = _locationController.text.trim();
    String? cityLocation; // 改名避免混淆，僅線下活動時才會計算
    final description = _descriptionController.text.trim();

    if (name.isEmpty) {
      setState(() => _errorMessage = '請輸入活動名稱');
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
      // 線下活動才需要推回縣市
      cityLocation = await TaiwanAddressHelper.getCityFromCoordinates(
        selectedLocationData!,
      );
    }
    if (description.isEmpty) {
      setState(() => _errorMessage = '請描述你的活動內容');
      return;
    }
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    debugPrint('取得 location:$cityLocation, online=$_isOnline');

    try {
      final apiClient = ApiClient();
      await apiClient.init();

      final uriData = ApiPath.createCharityEvent; //新增活動API
      //需回傳值：{'name':(必填),'startTime':(必填),'endTime':(必填),'signupDeadline':報名截止時間,
      // 'description':,'eventType':(typeName、單選),'location':中文縣市, 'address':中文詳細地址, 'online':true/false}

      final body = {
        'name': name,
        'startTime': start,
        'endTime': end,
        'signupDeadline': ddl,
        'description': description,
        'eventType': type,
        'online': _isOnline,
        // 'permanent': _isPermanent, //常駐活動
        if (!_isOnline) 'location': cityLocation,
        if (!_isOnline) 'address': address,
      };

      final eventCreate = await apiClient
          .post(uriData, body)
          .timeout(const Duration(seconds: 10));

      if (eventCreate.statusCode == 200) {
        _showMessage('創建成功!');
        if (mounted) {
          Navigator.pushNamedAndRemoveUntil(
            context,
            '/charity_home',
            (_) => false,
          );
        }
      } else {
        setState(() => _errorMessage = '創建活動失敗:${eventCreate.body}');
      }
    } catch (e) {
      setState(() => _errorMessage = '錯誤:$e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  //日期時間選擇器
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

  //時間日期格式
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
      appBar: AppBar(title: const Text('新增活動')),
      body: SingleChildScrollView(
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

                  // 新增：線上活動開關
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

                  //名稱輸入欄
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: '活動名稱',
                      helperText: '請輸入名稱',
                    ),
                  ),
                  const SizedBox(height: 16),

                  //開始日期時間輸入欄
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

                  //結束日期時間輸入欄
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
                            const SnackBar(content: Text('結束時間不可早於開始時間')),
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

                  //報名截止期限
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

                  // const SizedBox(width: 12),
                  // Column(
                  //   children: [
                  //     const Text('常駐'),
                  //     Switch(
                  //       value: _isPermanent,
                  //       onChanged: (v) {
                  //         setState(() => _isPermanent = v);
                  //       },
                  //     ),
                  //   ],
                  // ),

                  //活動類型下拉式選單
                  DropdownButtonFormField<String>(
                    value: _selectEventType,
                    hint: const Text('請選擇您的活動類型'),
                    items:
                        [
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
                        ].map((e) {
                          return DropdownMenuItem(value: e, child: Text(e));
                        }).toList(),
                    onChanged: (val) {
                      setState(() {
                        _selectEventType = val;
                        if (_errorMessage.isNotEmpty) {
                          _errorMessage = '';
                        }
                      });
                    },
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: '活動類型',
                    ),
                  ),
                  const SizedBox(height: 16),

                  //地址輸入欄（線上活動停用）
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
                                        initialLatLng: selectedLocationData,
                                        initialAddress:
                                            _locationController.text,
                                      ),
                                ),
                              );
                              if (result != null) {
                                selectedLocationData = LatLng(
                                  result['lat'],
                                  result['lng'],
                                ); //儲存完整資訊
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

                  //活動詳情輸入欄
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

                  //提交
                  ElevatedButton(
                    onPressed: _isLoading ? null : _submit,
                    child:
                        _isLoading
                            ? const CircularProgressIndicator()
                            : const Text('新增活動'),
                  ),

                  //錯誤訊息
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
