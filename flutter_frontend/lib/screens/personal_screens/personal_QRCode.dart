import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_frontend/config.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_frontend/qr_code_generator.dart';

class PersonalQRCodePage extends StatefulWidget {
  const PersonalQRCodePage({super.key});

  @override
  State<PersonalQRCodePage> createState() => PersonalQRCodePageState();
}

class PersonalQRCodePageState extends State<PersonalQRCodePage> {
  String token = '';
  int secondsLeft = 300;
  Timer? countdownTimer;

  @override
  void initState() {
    super.initState();
    fetchToken();
    startCountdown();
  }

  @override
  void dispose() {
    countdownTimer?.cancel();
    super.dispose();
  }

  Future<void> fetchToken() async {
    try {
      final getToken = await http.get(Uri.parse(ApiPath.createUserQRCode));
      if (getToken.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(getToken.body); //解析
        if (data['success'] == true && data['code'] != null) {
          setState(() {
            token = data['code'];
            secondsLeft = 300;
          });
        } else {
          debugPrint('後端回傳失敗or沒有token');
        }
      } else {
        debugPrint('HTTP 錯誤: ${getToken.statusCode}');
      }
    } catch (e) {
      debugPrint('錯誤:$e');
    }
  }

  void startCountdown() {
    countdownTimer?.cancel();
    countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (secondsLeft > 0) {
        setState(() {
          secondsLeft--;
        });
      } else {
        fetchToken(); // 倒數結束刷新 token
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final minutes = (secondsLeft ~/ 60).toString().padLeft(2, '0');
    final seconds = (secondsLeft % 60).toString().padLeft(2, '0');

    return Scaffold(
      appBar: AppBar(title: const Text('報到QRCode')),
      body: Center(
        child:
            token.isEmpty
                ? const CircularProgressIndicator()
                : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    QRCodeGenerator(token: token),
                    const SizedBox(height: 20),
                    Text(
                      "剩餘時間：$minutes:$seconds",
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: fetchToken,
                      child: const Text("手動刷新"),
                    ),
                  ],
                ),
      ),
    );
  }
}
