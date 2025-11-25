import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_frontend/config.dart';
import 'package:flutter_frontend/qr_code_generator.dart';
import '../../api_client.dart';

class PersonalQRCodePage extends StatefulWidget {
  final String eventName;
  const PersonalQRCodePage({super.key, required this.eventName});

  @override
  State<PersonalQRCodePage> createState() => PersonalQRCodePageState();
}

class PersonalQRCodePageState extends State<PersonalQRCodePage> {
  String token = '';
  int secondsLeft = 300; //5mins
  Timer? countdownTimer;

  bool isLoading = true;
  String? errorMessage;

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
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final apiClient = ApiClient();
      await apiClient.init();

      final getToken = await apiClient.get(ApiPath.createUserQRCode);

      if (getToken.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(getToken.body); //解析

        if (data['success'] == true && data['code'] != null) {
          setState(() {
            token = data['code'].toString();
            secondsLeft = 300;
            isLoading = false;
          });
        } else {
          setState(() {
            errorMessage = '後端回傳失敗或沒有 token';
            isLoading = false;
          });
          debugPrint('後端回傳失敗或沒有 token: ${getToken.body}');
        }
      } else {
        debugPrint('HTTP 錯誤: ${getToken.statusCode}');
      }
    } catch (e) {
      setState(() {
        errorMessage = '取得 token 時發生錯誤：$e';
        isLoading = false;
      });
      debugPrint('錯誤: $e');
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

  String get qrData {
    final Map<String, dynamic> data = {
      'token': token,
      'eventName': widget.eventName,
    };
    debugPrint('QR data: $data');
    return jsonEncode(data);
  }

  @override
  Widget build(BuildContext context) {
    final minutes = (secondsLeft ~/ 60).toString().padLeft(2, '0');
    final seconds = (secondsLeft % 60).toString().padLeft(2, '0');

    return Scaffold(
      appBar: AppBar(title: const Text('報到QRCode')),
      body: Center(
        child:
            isLoading
                ? const CircularProgressIndicator()
                : token.isEmpty
                ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 40,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      errorMessage ?? '目前無法取得 QRCode，請稍後再試',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: fetchToken,
                      child: const Text('重新嘗試取得 QRCode'),
                    ),
                  ],
                )
                : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    QRCodeGenerator(data: qrData),
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
