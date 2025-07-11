import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../../routes.dart';
import '../../config.dart';

class GroupSigninPage extends StatefulWidget {
  const GroupSigninPage({super.key});

  @override
  State<GroupSigninPage> createState() => GroupSigninState();
}

class GroupSigninState extends State<GroupSigninPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _showPasswordField = false;
  bool _isLoading = false;

  Future<void> _handleEmailSubmit() async {
    final groupEmail = _emailController.text.trim();

    if (groupEmail.isEmpty) return;

    setState(() => _isLoading = true);

    //測試用
    /*try {
      await Future.delayed(const Duration(seconds: 1));

      bool accountExists = groupEmail.contains('test');

      if (accountExists) {
        setState(() => _showPasswordField = true);
      } else {
        _showRegisterDialog();
      }
    } catch (e) {
      _showMessage('模擬錯誤:$e');
    } finally {
      setState(() => _isLoading = false);
    }*/

    try {
      final uri = Uri.parse(ApiPath.checkCharityEmail); //驗證email API
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'groupEmail': groupEmail}), //email json
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
    }
  }

  Future<void> _handlePasswordSubmit() async {
    final groupEmail = _emailController.text.trim();
    final groupPassword = _passwordController.text.trim();

    if (groupPassword.isEmpty) return;

    setState(() {
      _isLoading = true;
    });

    /*
    //測試用
    try {
      await Future.delayed(const Duration(seconds: 1));

      bool isCorret = groupPassword == '123';

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
    }*/

    try {
      final uri = Uri.parse(ApiPath.checkPassword); //驗證密碼 API
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': groupEmail,
          'password': groupPassword,
        }), //password json
      );

      final result = jsonDecode(response.body);

      if (response.statusCode == 200 && result['corret'] == true) {
        //密碼正確
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/home_tab',
          (route) => false,
        );
      } else {
        //密碼錯誤
        setState(() => _showMessage('密碼錯誤，請再次嘗試'));
      }
    } catch (e) {
      _showMessage('錯誤:$e');
    } finally {
      setState(() => _isLoading = false);
    }
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
                onPressed: () => Navigator.of(context).pop(), //按下按鈕後關閉警示框
                child: const Text('否'),
              ),
              //註冊
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.pushNamed(
                    context,
                    '/group_signup',
                    arguments: _emailController.text.trim(),
                  );
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
      appBar: AppBar(title: const Text('機構帳戶登入')),
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
