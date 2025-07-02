import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class PersonalSigninPage extends StatefulWidget {
  const PersonalSigninPage({super.key});

  @override
  State<PersonalSigninPage> createState() => PersonalSigninState();
}

class PersonalSigninState extends State<PersonalSigninPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _showPasswordField = false;
  bool _isLoading = false;

  Future<void> _handleEmailSubmit() async {
    final personalEmail = _emailController.text.trim();

    if (personalEmail.isEmpty) return;

    setState(() => _isLoading = true);

    //測試用
    try {
      await Future.delayed(const Duration(seconds: 1));

      bool accountExists = personalEmail.contains('test');

      if (accountExists) {
        setState(() => _showPasswordField = true);
      } else {
        _showRegisterDialog();
      }
    } catch (e) {
      _showMessage('模擬錯誤:$e');
    } finally {
      setState(() => _isLoading = false);
    }

    /*
    try {
      final uri = Uri.parse('http://'); //API
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'personalEmail': personalEmail}), //email json
      );

      final result = jsonDecode(response.body);

      if (response.statusCode == 200 && result['exists'] == true) {
        //帳號存在，進入輸入密碼頁面
        setState(() => _showPasswordField = true);
      } else {
        //帳號不存在，跳出警示框
        _showRegisterDialog();
      }
    } catch (e) {
      _showMessage('錯誤:$e');
    } finally {
      setState(() => _isLoading = false);
    }*/
  }

  Future<void> _handlePasswordSubmit() async {
    final personalPassword = _passwordController.text.trim();

    if (personalPassword.isEmpty) return;

    setState(() {
      _isLoading = true;
    });

    //測試用
    try {
      await Future.delayed(const Duration(seconds: 1));

      bool isCorret = personalPassword == '123';

      if (isCorret) {
        _showMessage('登入成功');
        Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
      } else {
        setState(() => _showMessage('密碼錯誤，請再次嘗試'));
      }
    } catch (e) {
      _showMessage('模擬錯誤:$e');
    } finally {
      setState(() => _isLoading = false);
    }

    /*
    try {
      final uri = Uri.parse('http://'); //API
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'personalPassword': personalPassword,
        }), //password json
      );

      final result = jsonDecode(response.body);

      if (response.statusCode == 200 && result['corret'] == true) {
        //密碼正確
        Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
      } else {
        //密碼錯誤
        setState(() => _showMessage('密碼錯誤，請再次嘗試'));
      }
    } catch (e) {
      _showMessage('錯誤:$e');
    } finally {
      setState(() => _isLoading = false);
    }*/
  }

  //驗證失敗
  void _showRegisterDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('找不到此帳號'),
            content: const Text('是否註冊新帳號?'),
            actions: [
              //不註冊
              TextButton(
                onPressed: () => Navigator.of(context).pop, //按下按鈕後關閉警示框
                child: const Text('否'),
              ),
              //註冊
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.pushNamed(context, '/personal_signup');
                },
                child: const Text('是'),
              ),
            ],
          ),
    );
  }

  void _showMessage(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('個人帳戶登入')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              //email輸入格
              if (!_showPasswordField) ...[
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.text,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: '帳號',
                    helperText: '請輸入帳號email',
                  ),
                ),

                const SizedBox(height: 16),

                //提交email按鈕
                ElevatedButton(
                  onPressed: _isLoading ? null : _handleEmailSubmit,
                  child:
                      _isLoading
                          ? const CircularProgressIndicator()
                          : const Text('下一步'),
                ),
              ],

              //密碼輸入格
              if (_showPasswordField) ...[
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: '密碼',
                    helperText: '請輸入帳號密碼',
                  ),
                ),
                const SizedBox(height: 16),

                //提交密碼按鈕
                ElevatedButton(
                  onPressed: _isLoading ? null : _handlePasswordSubmit,
                  child:
                      _isLoading
                          ? const CircularProgressIndicator()
                          : const Text('登入'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
