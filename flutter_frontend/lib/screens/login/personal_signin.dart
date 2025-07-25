import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../routes.dart';
import '../../config.dart';

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
    /*try {
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
    }*/

    try {
      final uri = Uri.parse(ApiPath.checkPersonalEmail); //API
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'personalEmail': personalEmail}), //email json
      );

      final result = jsonDecode(response.body);
      print(response.statusCode);
      final exists = result['exists'] as bool;

      if (response.statusCode == 200 && exists == true) {
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
    final personalEmail = _emailController.text.trim();
    final personalPassword = _passwordController.text.trim();

    if (personalPassword.isEmpty) return;

    setState(() {
      _isLoading = true;
    });

    /*
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
    }*/

    try {
      final uri = Uri.parse(ApiPath.checkPassword); //API
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': personalEmail,
          'password': personalPassword,
        }), //password json
      );

      final result = jsonDecode(response.body);

      if (response.statusCode == 200 && result['success'] == true) {
        //密碼正確
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/personal_home_tab',
          (route) => false,
        );
      } else {
        //密碼錯誤
        setState(() => _showMessage('密碼錯誤，請再次嘗試:${response.body}'));
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
                    '/personal_signup',
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
      appBar: AppBar(title: const Text('個人帳戶登入')),
      body: SingleChildScrollView(
        child: Align(
          alignment: Alignment.topCenter,
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: 400),
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
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton(
                        onPressed: () {
                          Navigator.pushNamed(context, '/personal_signup');
                        },
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: Size(0, 0),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          visualDensity: VisualDensity.compact,
                        ),
                        child: Text(
                          '註冊帳號',
                          style: TextStyle(
                            color: Colors.blue,
                            decoration: TextDecoration.underline,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),

                    //提交email按鈕
                    ElevatedButton(
                      onPressed: _isLoading ? null : _handleEmailSubmit,
                      child:
                          _isLoading
                              ? const CircularProgressIndicator()
                              : const Text('下一步'),
                    ),

                    const SizedBox(height: 24),

                    ElevatedButton.icon(
                      icon: const Icon(Icons.account_circle),
                      label: const Text('使用 Google 登入'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () async {
                        try {
                          final googleUser =
                              await GoogleSignIn(
                                clientId:
                                    '51601454665-9n15a5gkudl21va57aeeoneg85lomibt.apps.googleusercontent.com',
                              ).signIn();

                          if (googleUser == null) return; // 使用者取消

                          final googleAuth = await googleUser.authentication;

                          final credential = GoogleAuthProvider.credential(
                            accessToken: googleAuth.accessToken,
                            idToken: googleAuth.idToken,
                          );

                          await FirebaseAuth.instance.signInWithCredential(
                            credential,
                          );

                          if (context.mounted) {
                            Navigator.pushNamedAndRemoveUntil(
                              context,
                              '/home_tab',
                              (route) => false,
                            );
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Google 登入失敗：$e')),
                            );
                          }
                        }
                      },
                    ),

                    const SizedBox(height: 16),

                    ElevatedButton.icon(
                      label: const Text('使用 LINE 登入'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () async {
                        const url =
                            'https://access.line.me/oauth2/v2.1/authorize'
                            '?response_type=code'
                            '&client_id=2007781853'
                            '&redirect_uri=https%3A%2F%2Flogin-app-67d5a.firebaseapp.com%2F__%2Fauth%2Fhandler'
                            '&state=test123'
                            '&scope=profile%20openid%20email';

                        if (await canLaunchUrl(Uri.parse(url))) {
                          await launchUrl(
                            Uri.parse(url),
                            mode: LaunchMode.externalApplication,
                          );
                        } else {
                          debugPrint("無法打開 LINE 授權頁");
                        }
                      },
                    ),

                    const Padding(
                      padding: EdgeInsets.only(top: 8.0),
                      child: Text(
                        'Firebase可能需要收費，具體登入暫未實作',
                        style: TextStyle(fontSize: 8, color: Colors.grey),
                      ),
                    ),
                  ],

                  //密碼輸入格
                  if (_showPasswordField) ...[
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton(
                        onPressed: () {
                          setState(() {
                            _showPasswordField = false;
                            _passwordController.clear();
                          });
                        },
                        child: const Text('← 上一步'),
                      ),
                    ),
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
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () {
                          _showMessage('尚未實作忘記密碼功能');
                        },
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: Size(0, 0),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          visualDensity: VisualDensity.compact,
                        ),
                        child: Text(
                          '忘記密碼？',
                          style: TextStyle(
                            color: Colors.blue,
                            decoration: TextDecoration.underline,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),

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
        ),
      ),
    );
  }
}
