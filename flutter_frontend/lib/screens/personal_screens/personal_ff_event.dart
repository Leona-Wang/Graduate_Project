import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:marquee/marquee.dart';
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

  late TextEditingController _numberController;

  @override
  void initState() {
    super.initState();
    _numberController = TextEditingController(
      text: playerNumber?.toString() ?? '0',
    );
    fetchNumber();
  }

  @override
  void dispose() {
    _numberController.dispose();
    super.dispose();
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
      print('fetchNumber response body: ${response.body}');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          playerNumber = int.tryParse(data['userBetAmount'].toString()) ?? 0;
          total = int.tryParse(data['totalBetAmount'].toString()) ?? 0;
          _numberController.text = playerNumber.toString();
        });
        print(playerNumber);
        print(total);
      } else {
        debugPrint("取得金幣數量失敗: ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("錯誤: $e");
    } finally {
      setState(() {
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
        /*setState(() {
          playerNumber = newNumber;
          _numberController.text = playerNumber.toString();
        });*/
        //await Future.delayed(Duration(milliseconds: 500));
        await fetchNumber();
      } else if (response.statusCode == 400) {
        coinExecption();
      } else {
        throw Exception("下注失敗: ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("錯誤: $e");
    }
  }

  void openNumberInputDialog() {
    /*final controller = TextEditingController(
      text: playerNumber?.toString() ?? "0",
    );*/

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("輸入金額"),
          content: TextField(
            controller: _numberController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              hintText: "請輸入金額",
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("取消"),
            ),
            ElevatedButton(
              onPressed: () {
                final value = int.tryParse(_numberController.text.trim());
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

  void coinExecption() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("金幣數量不足 QQ"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("確認"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    double progress = 0;
    if (playerNumber != null && total != null && total! > 0) {
      progress = (playerNumber! / total!) * 100;
    } else {
      progress = 0;
    }

    final primaryColor = Colors.amber;
    final textOnDark = Colors.white;

    return Theme(
      data: Theme.of(context).copyWith(
        textTheme: Theme.of(context).textTheme.copyWith(
          // 大標題
          titleLarge: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
          titleMedium: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          titleSmall: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),

          // 內文
          bodyLarge: Theme.of(
            context,
          ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w800),
          bodyMedium: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w800),
          bodySmall: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w800),
        ),
      ),
      child: Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage("assets/background/casinoBackground.png"),
              fit: BoxFit.cover,
            ),
          ),
          child: Container(
            // 蓋一層深色漸層，讓前景更乾淨
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.brown.withOpacity(0.50),
                  Colors.brown.withOpacity(0.55),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                child: Stack(
                  children: [
                    /// 整體主結構：上方 bar + 中間內容
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        //上方列：返回鍵 + 跑馬燈 + 說明鍵
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 20,
                              backgroundColor: Colors.amber,
                              child: IconButton(
                                padding: EdgeInsets.zero,
                                icon: const Icon(
                                  Icons.arrow_back_ios_new,
                                  color: Colors.brown,
                                  size: 18,
                                ),
                                onPressed: () => Navigator.pop(context),
                              ),
                            ),
                            const SizedBox(width: 12),
                            // 跑馬燈區
                            Expanded(
                              child: Container(
                                height: 40,
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.25),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                clipBehavior: Clip.antiAlias,
                                child: Marquee(
                                  text:
                                      '活動日期 : $startDate ~ $endDate  ｜ 本期合作機構 : $currentCharity',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: textOnDark,
                                  ),
                                  scrollAxis: Axis.horizontal,
                                  blankSpace: 40.0,
                                  velocity: 40.0,
                                  pauseAfterRound: const Duration(seconds: 1),
                                  startPadding: 16.0,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              icon: const Icon(Icons.help_outline),
                              color: textOnDark,
                              iconSize: 26,
                              onPressed: () {
                                setState(() {
                                  showGuide = !showGuide;
                                });
                              },
                            ),
                          ],
                        ),

                        const SizedBox(height: 32),

                        //  中間主要內容：置中
                        Expanded(
                          child: Center(
                            child:
                                isLoading
                                    ? const CircularProgressIndicator(
                                      strokeWidth: 3,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.amber,
                                      ),
                                    )
                                    : Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        // 人物 + 對話框
                                        Stack(
                                          clipBehavior: Clip.none,
                                          alignment: Alignment.center,
                                          children: [
                                            GestureDetector(
                                              onTap: () {
                                                setState(() {
                                                  showCharacterDialog =
                                                      !showCharacterDialog;
                                                });
                                              },
                                              child: Container(
                                                width: 140,
                                                height: 140,
                                                decoration: BoxDecoration(
                                                  color: const Color(
                                                    0xFFf8f5f0,
                                                  ).withOpacity(0.15),
                                                  shape: BoxShape.circle,
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color: Color(
                                                        0xFF4A2E14,
                                                      ).withOpacity(0.15),
                                                      blurRadius: 6,
                                                      offset: const Offset(
                                                        0,
                                                        3,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                child: ClipOval(
                                                  child: Image.asset(
                                                    "assets/background/mango.PNG",
                                                    fit: BoxFit.cover,
                                                  ),
                                                ),
                                              ),
                                            ),
                                            if (showCharacterDialog)
                                              Positioned(
                                                top: -90,
                                                child: Column(
                                                  children: [
                                                    Container(
                                                      padding:
                                                          const EdgeInsets.symmetric(
                                                            horizontal: 12,
                                                            vertical: 8,
                                                          ),
                                                      decoration: BoxDecoration(
                                                        color: Colors.white
                                                            .withOpacity(0.95),
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              12,
                                                            ),
                                                        boxShadow: const [
                                                          BoxShadow(
                                                            color:
                                                                Colors.black12,
                                                            blurRadius: 4,
                                                            offset: Offset(
                                                              0,
                                                              2,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                      child: Text(
                                                        "您現在的中獎機率是 ${(progress).toStringAsFixed(1)} %",
                                                        style: const TextStyle(
                                                          fontSize: 17,
                                                          fontWeight:
                                                              FontWeight.w700,
                                                          color: Colors.brown,
                                                        ),
                                                      ),
                                                    ),
                                                    // 對話框三角形
                                                    ClipPath(
                                                      clipper:
                                                          _TriangleClipper(),
                                                      child: Container(
                                                        width: 20,
                                                        height: 10,
                                                        color: Colors.white
                                                            .withOpacity(0.95),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                          ],
                                        ),

                                        const SizedBox(height: 28),

                                        // 你的投注金額
                                        const Text(
                                          '你的投注金額',
                                          style: TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.w900,
                                            color: Colors.white,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 18,
                                            horizontal: 40,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.white.withOpacity(
                                              0.9,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              24,
                                            ),
                                            boxShadow: const [
                                              BoxShadow(
                                                color: Color(0xFF4A2E14),
                                                blurRadius: 8,
                                                offset: Offset(0, 4),
                                              ),
                                            ],
                                          ),
                                          child: Text(
                                            playerNumber?.toString() ?? '0',
                                            style: TextStyle(
                                              fontSize: 40,
                                              fontWeight: FontWeight.w800,
                                              color: primaryColor,
                                            ),
                                          ),
                                        ),

                                        const SizedBox(height: 24),

                                        // 下注按鈕
                                        SizedBox(
                                          width: double.infinity,
                                          child: ElevatedButton(
                                            onPressed: openNumberInputDialog,
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: primaryColor,
                                              foregroundColor: Color(
                                                0xFF4A2E14,
                                              ),
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    vertical: 14,
                                                  ),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(999),
                                              ),
                                              elevation: 6,
                                            ),
                                            child: const Text(
                                              '請輸入下注金額',
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          ),
                                        ),

                                        const SizedBox(height: 28),

                                        // 進度條區塊
                                        if (total != null && total! > 0)
                                          TweenAnimationBuilder<double>(
                                            tween: Tween<double>(
                                              begin: 0,
                                              end: (total ?? 0) / 2,
                                            ),
                                            duration: const Duration(
                                              milliseconds: 600,
                                            ),
                                            builder: (context, value, child) {
                                              final maxReward =
                                                  (total ?? 0) / 2.0;
                                              final percent =
                                                  maxReward == 0
                                                      ? 0.0
                                                      : (value / maxReward)
                                                          .clamp(0.0, 1.0);

                                              return Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.stretch,
                                                children: [
                                                  const Text(
                                                    '玩家可獲得金額（50%）',
                                                    style: TextStyle(
                                                      fontSize: 14,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 8),
                                                  ClipRRect(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          999,
                                                        ),
                                                    child: SizedBox(
                                                      height: 12,
                                                      child: LinearProgressIndicator(
                                                        value: percent,
                                                        backgroundColor:
                                                            Colors.white24,
                                                        valueColor:
                                                            AlwaysStoppedAnimation<
                                                              Color
                                                            >(primaryColor),
                                                      ),
                                                    ),
                                                  ),
                                                  const SizedBox(height: 8),
                                                  Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .spaceBetween,
                                                    children: [
                                                      Text(
                                                        '目前總量：$total',
                                                        style: const TextStyle(
                                                          fontSize: 14,
                                                          color: Colors.white70,
                                                        ),
                                                      ),
                                                      Text(
                                                        value.toStringAsFixed(
                                                          0,
                                                        ),
                                                        style: const TextStyle(
                                                          fontSize: 17,
                                                          fontWeight:
                                                              FontWeight.w800,
                                                          color: Colors.white,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              );
                                            },
                                          )
                                        else
                                          const Text(
                                            '目前尚無投注紀錄',
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: Colors.white70,
                                            ),
                                          ),
                                      ],
                                    ),
                          ),
                        ),
                      ],
                    ),

                    // 右上角的遊戲指引浮窗
                    if (showGuide)
                      Align(
                        alignment: Alignment.topRight,
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 280),
                          child: Padding(
                            padding: const EdgeInsets.only(top: 60.0),
                            child: Material(
                              color: Colors.white.withOpacity(0.96),
                              elevation: 4,
                              borderRadius: BorderRadius.circular(16),
                              child: Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Text(
                                  "遊戲指引\n\n"
                                  "歡迎來到 50 / 50 活動會場！\n"
                                  "在這裡，你可以使用金幣進行投注。\n\n"
                                  "當期數結束時：\n"
                                  "・你有機會獲得金幣總額的 50%\n"
                                  "・另 50% 將捐給本期合作機構\n\n"
                                  "中獎機率 = 你的投注金額 / 全體投注總額\n"
                                  "投注越多，中獎機率越高，快來試試你的手氣吧！",
                                  style: const TextStyle(
                                    fontSize: 16,
                                    height: 1.5,
                                    color: Colors.brown,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
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
