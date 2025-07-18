import 'dart:isolate';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_frontend/screens/charity_screens/charity_map.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:latlong2/latlong.dart';

class CharityNewEventPage extends StatefulWidget {
  const CharityNewEventPage({super.key});

  @override
  State<CharityNewEventPage> createState() => CharityNewEventState();
}

class CharityNewEventState extends State<CharityNewEventPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _startController = TextEditingController();
  final TextEditingController _endController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();

  String _errorMessage = '';

  bool _isLoading = false;

  LatLng? selectedLacationData;
  DateTime? _startDateTime;
  DateTime? _endDateTime;

  Future<void> _submit() async {
    final name = _nameController.text.trim();
    final start = _startController.text;
    final end = _endController.text;
    final location = _locationController.text.trim();

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
    if (location.isEmpty) {
      setState(() => _errorMessage = '請選擇地點');
      return;
    }
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final uriData = Uri.parse(''); //新增活動API

      final eventCreate = await http
          .post(
            uriData,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({}),
          )
          .timeout(const Duration(seconds: 10));

      if (eventCreate.statusCode == 200) {
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/charity_home_tap',
          (_) => false,
        );
      } else if (eventCreate.statusCode != 200) {
        setState(() => _errorMessage = '密碼設定失敗:${eventCreate.body}');
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
              constraints: BoxConstraints(maxWidth: 500),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 16),
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
                  //地址輸入欄
                  TextFormField(
                    controller: _locationController,
                    readOnly: true,
                    onTap: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) => CharityMapPage(
                                initialLatLng: selectedLacationData,
                                initialAddress: _locationController.text,
                              ),
                        ),
                      );
                      if (result != null) {
                        selectedLacationData = LatLng(
                          result['lat'],
                          result['lng'],
                        ); //儲存完整資訊
                        _locationController.text = result['address'];
                      }
                    },
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: '活動地點',
                      suffixIcon: Icon(Icons.map),
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
