import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_frontend/config.dart';
import '../../api_client.dart';

class PersonalFFEventPage extends StatefulWidget {
  const PersonalFFEventPage({super.key});

  @override
  State<PersonalFFEventPage> createState() => PersonalFFEventPageState();
}

class PersonalFFEventPageState extends State<PersonalFFEventPage> {
  int? playerNumber; //目前玩家投注金額
  int? total; // 目前所有玩家投入總金額
  String? startDate = '2025-09-11';
  String? endDate = '2025-10-11';
  String? currentCharity = 'NCCU';
  //以上資料為測試用

  bool isLoading = true;
  bool showGuide = false; //遊戲指引
  bool showCharacterDialog = false; //對話框

  @override
  void initState() {
    super.initState();
    fetchNumber();
  }

  //取得玩家投注金額
  Future<void> fetchNumber() async {
    setState(() => isLoading = true);

    try {
      final apiClient = ApiClient();
      await apiClient.init();

      final url = ApiPath.getBetDetail;
      final uriNum = Uri.parse(url);

      final response = await apiClient.get(uriNum.toString());
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          playerNumber = data["userBetAmount"] ?? 0;
          total = data['totalBetAmount'] ?? 0;
        });
      } else {
        debugPrint("取得金幣數量失敗: ${response.statusCode}");
        setState(() {
          playerNumber = 0;
          total = 0;
        });
      }
    } catch (e) {
      debugPrint("錯誤: $e");
    } finally {
      setState(() {
        playerNumber = 0;
        total = 0;
        isLoading = false;
      });
    }
  }

  //下注，並更新投注金額
  Future<void> updateNumber(int newNumber) async {
    try {
      final apiClient = ApiClient();
      await apiClient.init();

      final url = ApiPath.createOrUpdateBet;
      final uriNum = Uri.parse(url);
      final body = {'betAmount': newNumber};

      final response = await apiClient.post(uriNum.toString(), body);

      if (response.statusCode == 200) {
        setState(() {
          playerNumber = newNumber;
        });
      } else {
        throw Exception("下注失敗: ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("錯誤: $e");
    }
  }

  void openNumberInputDialog() {
    final controller = TextEditingController(
      text: playerNumber?.toString() ?? "0",
    );

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("輸入數字"),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              hintText: "請輸入數字",
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("取消"),
            ),
            ElevatedButton(
              onPressed: () {
                final value = int.tryParse(controller.text);
                if (value != null) {
                  updateNumber(value);
                }
                Navigator.pop(context);
              },
              child: const Text("確認"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    double progress = 0.0;
    if (playerNumber != null && total != null && total! > 0) {
      progress = playerNumber! / total!;
    }

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 底圖
          Image.asset(
            "assets/background/casinoBackground.png",
            fit: BoxFit.cover,
          ),

          // 主要內容置中
          Center(
            child:
                isLoading
                    ? const CircularProgressIndicator()
                    : Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Stack(
                          clipBehavior: Clip.none,
                          children: [
                            // 愛文
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  showCharacterDialog = !showCharacterDialog;
                                });
                              },
                              child: Container(
                                width: 60,
                                height: 60,
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade300,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.person,
                                  size: 40,
                                  color: Colors.black54,
                                ),
                              ),
                            ),

                            // 對話框
                            if (showCharacterDialog)
                              Positioned(
                                bottom: 60, // 在人物上方
                                left: 0,
                                right: 0,
                                child: Column(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.9),
                                        borderRadius: BorderRadius.circular(12),
                                        boxShadow: const [
                                          BoxShadow(
                                            color: Colors.black26,
                                            blurRadius: 4,
                                            offset: Offset(2, 2),
                                          ),
                                        ],
                                      ),
                                      child: const Text(
                                        "您現在的中獎機率是: !",
                                        style: TextStyle(fontSize: 14),
                                      ),
                                    ),
                                    ClipPath(
                                      clipper: _TriangleClipper(),
                                      child: Container(
                                        width: 20,
                                        height: 10,
                                        color: Colors.white.withOpacity(0.9),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // 目前投入數字
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.8),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            playerNumber?.toString() ?? '0',
                            style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        ElevatedButton(
                          onPressed: openNumberInputDialog,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                          ),
                          child: const Text('請輸入下注金額'),
                        ),
                        const SizedBox(height: 20),

                        // 進度條
                        if (total != null) ...[
                          const Text(
                            '可獲得金額',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          SizedBox(
                            width: 250,
                            child: LinearProgressIndicator(
                              value: progress,
                              minHeight: 12,
                              backgroundColor: Colors.grey.shade300,
                              color: Colors.amber,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '目前總量: $total',
                            style: const TextStyle(fontSize: 14),
                          ),
                        ],
                      ],
                    ),
          ),

          // 上方日期與機構名稱
          Positioned(
            top: 40,
            left: 16,
            right: 16,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '$startDate ~ $endDate',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  '本期合作機構: $currentCharity',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.help_outline_outlined,
                    color: Colors.white,
                  ),
                  onPressed: () {
                    setState(() {
                      showGuide = !showGuide;
                    });
                  },
                ),
              ],
            ),
          ),

          // 遊戲指引浮動
          if (showGuide)
            Positioned(
              top: 80,
              left: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  "遊戲指引：幫我寫 ;)",
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _TriangleClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.moveTo(0, 0);
    path.lineTo(size.width / 2, size.height);
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(_TriangleClipper oldClipper) => false;
}
