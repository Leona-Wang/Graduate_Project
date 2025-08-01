import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../../routes.dart';
import '../../config.dart';

class GroupSignupPage extends StatefulWidget {
  final String email;
  const GroupSignupPage({super.key, required this.email});

  @override
  State<GroupSignupPage> createState() => GroupSignupState();
}

class GroupSignupState extends State<GroupSignupPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _idController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmController = TextEditingController();

  late String email;
  Set<String> _selectType = Set.from([]);

  bool _isPasswordState = false;
  bool _isLoading = false;

  String _errorMessage = '';

  //帶email過來
  @override
  void initState() {
    super.initState();
    _emailController.text = widget.email;
  }

  void _nextStep() {
    final email = _emailController.text.trim();
    final name = _nameController.text.trim();
    final id = _idController.text.trim();
    final address = _addressController.text.trim();
    final phone = _phoneController.text.trim();

    if (email.isEmpty || !email.contains('@')) {
      setState(() => _errorMessage = '請輸入正確的email');
      return;
    }
    if (name.isEmpty) {
      setState(() => _errorMessage = '請輸入機構名稱');
      return;
    }
    if (_selectType.isEmpty) {
      setState(() => _errorMessage = '請選擇機構類型');
    }
    /*
    if (id.isEmpty) {
      setState(() => _errorMessage = '請輸入機構代碼');
      return;
    }*/
    if (address.isEmpty) {
      setState(() => _errorMessage = '請輸入地址');
      return;
    }
    if (phone.isEmpty) {
      setState(() => _errorMessage = '請輸入電話');
      return;
    }
    setState(() {
      _isPasswordState = true;
      _errorMessage = "";
    });
  }

  Future<void> _submitRegister() async {
    final groupPassword = _passwordController.text.trim();
    final confirmPassword = _confirmController.text.trim();
    if (groupPassword.isEmpty) {
      setState(() => _errorMessage = '請設定密碼');
      return;
    }
    //暫定的密碼檢驗機制，可更改
    if (groupPassword.length < 8) {
      setState(() => _errorMessage = '密碼須至少8個字元');
      return;
    }
    if (groupPassword != confirmPassword) {
      setState(() => _errorMessage = '密碼輸入不一致');
      return;
    }
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final uriData = Uri.parse(ApiPath.createCharityInfo); //資料API
      final uriPassword = Uri.parse(ApiPath.createCharityUser); //密碼API

      final accountCreate = await http.post(
        uriPassword,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'charityEmail': _emailController.text.trim(),
          'charityPassword': groupPassword,
          'charityPasswordConfirm': confirmPassword,
        }),
      );

      final infoCreate = await http.post(
        uriData,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': _emailController.text.trim(),
          'groupName': _nameController.text.trim(),
          'groupType': _selectType.toList(),
          'groupAddress': _addressController.text.trim(),
          'groupPhone': _phoneController.text.trim(),
          'groupId': _idController.text.trim(),
        }),
      );

      if (infoCreate.statusCode == 200 && accountCreate.statusCode == 200) {
        _showMessage('註冊成功!');
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/group_signin',
          ModalRoute.withName('/'),
        );
      } else if (infoCreate.statusCode != 200) {
        setState(() => _errorMessage = '機構資料建立失敗:${infoCreate.body}');
      } else {
        setState(() => _errorMessage = '密碼設定失敗:${accountCreate.body}');
      }
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
      appBar: AppBar(title: const Text('註冊機構帳號')),
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
                  //設定組織資料
                  if (!_isPasswordState) ...[
                    const SizedBox(height: 16),

                    //email 有預設輸入的值
                    TextField(
                      controller: _emailController,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: '機構帳號',
                        helperText: '請輸入您的email',
                      ),
                      onChanged: (_) {
                        if (_errorMessage.isNotEmpty) {
                          setState(() => _errorMessage = '');
                        }
                      },
                    ),
                    const SizedBox(height: 16),

                    //名稱
                    TextField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: '機構名稱',
                        helperText: '請輸入您的名稱',
                      ),
                      onChanged: (_) {
                        if (_errorMessage.isNotEmpty) {
                          setState(() => _errorMessage = '');
                        }
                      },
                    ),
                    const SizedBox(height: 16),

                    //機構類型
                    DropdownButtonFormField<String>(
                      //value: _selectType,
                      hint: const Text('請選擇您的機構類型'),
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
                                        value: _selectType.contains(e),
                                        onChanged: (isSelected) {
                                          if (isSelected == true) {
                                            _selectType.add(e);
                                          } else {
                                            _selectType.remove(e);
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
                        labelText: '機構類型',
                      ),
                    ),
                    const SizedBox(height: 16),

                    //機構代碼
                    TextField(
                      controller: _idController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: '機構代碼',
                        helperText: '請輸入您的機構代碼',
                      ),
                      onChanged: (_) {
                        if (_errorMessage.isNotEmpty) {
                          setState(() => _errorMessage = '');
                        }
                      },
                    ),
                    const SizedBox(height: 16),

                    //地址
                    TextField(
                      controller: _addressController,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: '機構地址',
                        helperText: '請輸入您的機構地址',
                      ),
                      onChanged: (_) {
                        if (_errorMessage.isNotEmpty) {
                          setState(() => _errorMessage = '');
                        }
                      },
                    ),
                    const SizedBox(height: 16),

                    //電話
                    TextField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: '連絡電話',
                        helperText: '請輸入您的聯絡電話',
                      ),
                      onChanged: (_) {
                        if (_errorMessage.isNotEmpty) {
                          setState(() => _errorMessage = '');
                        }
                      },
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
