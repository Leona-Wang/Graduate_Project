import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_frontend/config.dart';
import 'package:flutter_frontend/qr_code_scanner.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_frontend/qr_code_scanner.dart';

class CharityQRCodePage extends StatefulWidget {
  const CharityQRCodePage({super.key});

  @override
  State<CharityQRCodePage> createState() => CharityQRCodePageState();
}

class CharityQRCodePageState extends State<CharityQRCodePage> {
  Future<void> verifyTokenWithBackend(String scannedToken) async {
    final verifyToken = await http.post(
      Uri.parse(ApiPath.verifyUserQRCode),
      body: {'code': scannedToken},
    );
    if (verifyToken.statusCode == 200) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("驗證成功")));
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("驗證失敗")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('掃描QRCode')),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('請掃描用戶的QRCode進行報到'),
          SizedBox(
            height: 250,
            width: 250,
            child: QRCodeScanner(
              onTokenScanned: (scannedToken) {
                verifyTokenWithBackend(scannedToken);
              },
            ),
          ),
        ],
      ),
    );
  }
}
