import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../../config.dart';

class PersonalSignupPage extends StatefulWidget {
  final String personalEmail;
  const PersonalSignupPage({super.key, required this.personalEmail});

  @override
  State<PersonalSignupPage> createState() => PersonalSignupState();
}

class PersonalSignupState extends State<PersonalSignupPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _nicknameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmController = TextEditingController();

  String? _selectLocation;
  Set<String> _selectPrefer = Set.from([]);
  late String personalEmail;

  bool _isPasswordState = false;
  bool _isLoading = false;

  String _errorMessage = '';

  //帶email過來
  @override
  void initState() {
    super.initState();
    _emailController.text = widget.personalEmail;
  }

  void _nextStep() {
    final email = _emailController.text.trim();
    final name = _nicknameController.text.trim();

    if (email.isEmpty || !email.contains('@')) {
      setState(() => _errorMessage = '請輸入正確的email');
      return;
    }
    if (name.isEmpty) {
      setState(() => _errorMessage = '請輸入暱稱');
      return;
    }
    if (_selectLocation == null) {
      setState(() => _errorMessage = '請選擇地區');
      return;
    }
    if (_selectPrefer.isEmpty) {
      setState(() => _errorMessage = '請選擇偏好活動');
      return;
    }
    setState(() {
      _isPasswordState = true;
      _errorMessage = "";
    });
  }

  Future<void> _submitRegister() async {
    final personalPassword = _passwordController.text.trim();
    final confirmPassword = _confirmController.text.trim();

    if (personalPassword.isEmpty) {
      setState(() => _errorMessage = '請設定密碼');
      return;
    }
    //暫定的密碼檢驗機制，可更改
    if (personalPassword.length < 8) {
      setState(() => _errorMessage = '密碼須至少8個字元');
      return;
    }
    if (personalPassword != confirmPassword) {
      setState(() => _errorMessage = '密碼輸入不一致');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final uriData = Uri.parse(ApiPath.createPersonalInfo); //個人資料API
      final uriPassword = Uri.parse(ApiPath.createPersonalUser); //密碼API

      final accountCreate = await http.post(
        uriPassword,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'personalEmail': _emailController.text.trim(),
          'personalPassword': personalPassword,
          'personalPasswordConfirm': confirmPassword,
        }),
      );

      final infoCreate = await http
          .post(
            uriData,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'email': _emailController.text.trim(),
              'nickname': _nicknameController.text.trim(),
              'location': _selectLocation,
              'eventType': _selectPrefer.toList(),
            }),
          )
          .timeout(const Duration(seconds: 10));

      if (accountCreate.statusCode == 200 && infoCreate.statusCode == 200) {
        _showMessage('註冊成功!');
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/personal_signin',
          ModalRoute.withName('/'),
        );
      } else if (accountCreate.statusCode != 200) {
        setState(() => _errorMessage = '密碼設定失敗:${accountCreate.body}');
      } else {
        setState(() => _errorMessage = '個人資料建立失敗:${infoCreate.body}');
      }

      print(infoCreate.statusCode);
      print(infoCreate.body);
      print(accountCreate.statusCode);
      print(accountCreate.body);
    } catch (e) {
      setState(() => _errorMessage = '錯誤:$e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showMessage(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('註冊個人帳號')),
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
                  //設定個人資料
                  if (!_isPasswordState) ...[
                    //email 有預設輸入的值
                    TextField(
                      controller: _emailController,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: '使用者帳號',
                        helperText: '請輸入您的email',
                      ),
                      onChanged: (_) {
                        if (_errorMessage.isNotEmpty) {
                          setState(() => _errorMessage = '');
                        }
                      },
                    ),
                    const SizedBox(height: 16),

                    //暱稱
                    TextField(
                      controller: _nicknameController,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: '使用者暱稱',
                        helperText: '請輸入暱稱',
                      ),
                      onChanged: (_) {
                        if (_errorMessage.isNotEmpty) {
                          setState(() => _errorMessage = '');
                        }
                      },
                    ),
                    const SizedBox(height: 16),

                    //使用者活動地區
                    DropdownButtonFormField<String>(
                      value: _selectLocation,
                      hint: const Text('請選擇您經常活動的地區'),
                      items:
                          [
                            '台北市',
                            '新北市',
                            '基隆市',
                            '桃園市',
                            '新竹市',
                            '新竹縣',
                            '苗栗縣',
                            '南投縣',
                            '台中市',
                            '彰化縣',
                            '雲林縣',
                            '嘉義市',
                            '嘉義縣',
                            '台南市',
                            '高雄市',
                            '屏東縣',
                            '宜蘭縣',
                            '花蓮縣',
                            '台東縣',
                            '澎湖縣',
                            '金門縣',
                            '連江縣',
                            '其他地區',
                          ].map((e) {
                            return DropdownMenuItem(value: e, child: Text(e));
                          }).toList(),
                      onChanged: (val) {
                        setState(() {
                          _selectLocation = val;
                          if (_errorMessage.isNotEmpty) {
                            _errorMessage = '';
                          }
                        });
                      },
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: '經常活動的地區',
                      ),
                    ),
                    const SizedBox(height: 16),

                    //使用者偏好
                    DropdownButtonFormField(
                      hint: const Text('請選擇您偏好的慈善活動'),
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
                            return DropdownMenuItem(
                              value: e,
                              child: StatefulBuilder(
                                builder: (context, _setState) {
                                  return Row(
                                    children: [
                                      //選取
                                      Checkbox(
                                        value: _selectPrefer.contains(e),
                                        onChanged: (isSelected) {
                                          if (isSelected == true) {
                                            _selectPrefer.add(e);
                                          } else {
                                            _selectPrefer.remove(e);
                                          }
                                          _setState(() {});
                                          setState(() {});
                                        },
                                      ),
                                      Text(e),
                                    ],
                                  );
                                },
                              ),
                            );
                          }).toList(),
                      onChanged: (x) {},
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: '偏好慈善活動',
                      ),
                    ),
                    const SizedBox(height: 24),

                    //下一步按鈕
                    ElevatedButton(
                      onPressed: _isLoading ? null : _nextStep,
                      child: const Text('下一步'),
                    ),
                  ],

                  //設定密碼頁面
                  if (_isPasswordState) ...[
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton(
                        onPressed: () {
                          setState(() {
                            _isPasswordState = false;
                            _passwordController.clear();
                          });
                        },
                        child: const Text('← 上一步'),
                      ),
                    ),
                    //密碼輸入
                    TextField(
                      controller: _passwordController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: '設定密碼',
                        helperText: '請輸入密碼',
                      ),
                    ),
                    const SizedBox(height: 16),

                    //再次輸入密碼
                    TextField(
                      controller: _confirmController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: '設定密碼',
                        helperText: '請再次輸入密碼',
                      ),
                    ),
                    const SizedBox(height: 24),

                    //提交按鈕
                    ElevatedButton(
                      onPressed: _isLoading ? null : _submitRegister,
                      child:
                          _isLoading
                              ? const CircularProgressIndicator()
                              : const Text('註冊完成'),
                    ),
                  ],

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
