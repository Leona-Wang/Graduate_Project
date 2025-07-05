import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

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
  String? _selectPrefer;
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
    if (_selectPrefer == null) {
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
      final uriData = Uri.parse('http://localhost/person/create/'); //個人資料API
      final uriPassword = Uri.parse(
        'http://localhost/user/create/?type=personal',
      );
      final response1 = await http.post(
        uriData,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': _emailController.text.trim(),
          'nickname': _nicknameController.text.trim(),
          'location': _selectLocation,
          'eventType': _selectPrefer,
        }),
      );

      if (response1.statusCode == 200) {
        Navigator.pushNamedAndRemoveUntil(context, '/', (_) => false);
      } else {
        setState(() => _errorMessage = '個人資料建立失敗:${response1.body}');
      }

      final response2 = await http.post(
        uriPassword,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'personalEmail': _emailController.text.trim(),
          'personalPassword': personalPassword,
          'personalPasswordConfirm': confirmPassword,
        }),
      );

      if (response2.statusCode == 200) {
        Navigator.pushNamedAndRemoveUntil(context, '/', (_) => false);
      } else {
        setState(() => _errorMessage = '密碼設定失敗:${response1.body}');
      }
    } catch (e) {
      setState(() => _errorMessage = '錯誤:$e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('註冊個人帳號')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
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
                      '臺北',
                      '新北',
                      '基隆',
                      '桃園',
                      '新竹',
                      '苗栗',
                      '臺中',
                      '彰化',
                      '雲林',
                      '嘉義',
                      '台南',
                      '高雄',
                      '屏東',
                      '宜蘭',
                      '花蓮',
                      '台東',
                      '澎湖',
                      '金門',
                      '連江',
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

              //使用者偏好(之後做成可複選)
              DropdownButtonFormField<String>(
                value: _selectPrefer,
                hint: const Text('請選擇您偏好的慈善活動'),
                items:
                    ['群體福利', '社會議題', '教育文化', '醫療衛生', '綜合項目'].map((e) {
                      return DropdownMenuItem(value: e, child: Text(e));
                    }).toList(), //再增加
                onChanged: (val) => setState(() => _selectPrefer = val),
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
    );
  }
}
