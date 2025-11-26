import 'package:flutter/material.dart';
import 'package:flutter_frontend/config.dart';
import 'package:flutter_frontend/qr_code_scanner.dart';

import '../../api_client.dart';

class CharityQRCodePage extends StatefulWidget {
  const CharityQRCodePage({super.key});

  @override
  State<CharityQRCodePage> createState() => CharityQRCodePageState();
}

class CharityQRCodePageState extends State<CharityQRCodePage> {
  Future<void> verifyTokenWithBackend(String scannedToken) async {
    final apiClient = ApiClient();
    await apiClient.init();

    final uriData = ApiPath.verifyUserQRCode;
    final body = {'code': scannedToken};

    final verifyToken = await apiClient.post(uriData, body);

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
    final brown = Colors.brown[800]!;
    final brownLight = Colors.brown[600];

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: const Color(0xFFe6ccb2),
        elevation: 0,
        centerTitle: true,
        title: Text(
          '掃描 QRCode',
          style: TextStyle(
            color: brown,
            fontSize: 22,
            fontWeight: FontWeight.w800,
          ),
        ),
        iconTheme: IconThemeData(color: brown),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 16),
            Text(
              '請將鏡頭對準用戶畫面上的 QRCode\n掃描後即可完成報到',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: brown,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 32),

            // 掃描區塊
            Center(
              child: Container(
                width: 260,
                height: 260,
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.amber, width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 10,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(17),
                  child: QRCodeScanner(
                    onTokenScanned: (scannedToken) {
                      verifyTokenWithBackend(scannedToken);
                    },
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),
            Text(
              '掃描成功後，下方會顯示驗證結果提示。',
              textAlign: TextAlign.center,
              style: TextStyle(color: brownLight, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}
