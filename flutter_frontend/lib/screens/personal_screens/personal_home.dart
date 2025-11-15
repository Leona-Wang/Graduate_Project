import 'package:flutter/material.dart';
import 'package:flutter_frontend/screens/personal_screens/personal_mailbox.dart';
import 'package:flutter_frontend/screens/personal_screens/personal_profile.dart';
import 'package:flutter_frontend/screens/personal_screens/personal_home_tab.dart';

class PersonalHomePage extends StatefulWidget {
  const PersonalHomePage({super.key});

  @override
  State<PersonalHomePage> createState() => PersonalHomePageState();
}

class PersonalHomePageState extends State<PersonalHomePage> {
  void toMail() {
    PersonalHomeTab.of(context)?.hideBottomBar();
    Navigator.of(context)
        .push(
          MaterialPageRoute(builder: (context) => const PersonalMailboxPage()),
        )
        .then((_) {
          PersonalHomeTab.of(context)?.showBottomBar();
        });
  }

  void toProfile() {
    PersonalHomeTab.of(context)?.hideBottomBar();
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const PersonalProfilePage()))
        .then((_) {
          PersonalHomeTab.of(context)?.showBottomBar();
        });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFf8f5f0),
      appBar: AppBar(
        elevation: 0,
        title: const Text('首頁'),
        //左邊區域
        leading: Padding(
          padding: const EdgeInsets.only(left: 12.0, top: 6.0, bottom: 6.0),
          child: CircleAvatar(
            backgroundColor: Colors.amber,
            child: IconButton(
              onPressed: toProfile,
              icon: const Icon(Icons.person, color: Colors.brown),
              tooltip: '個人資訊',
            ),
          ),
        ),
        //右邊區域
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12.0, top: 6.0, bottom: 6.0),
            child: CircleAvatar(
              backgroundColor: Colors.amber,
              child: IconButton(
                onPressed: toMail,
                icon: const Icon(Icons.mail, color: Colors.brown),
                tooltip: '信箱',
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          // 用 Center + Column(mainAxisSize: min) 讓整塊靠中間
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  '歡迎回來！🌱',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF4A2E14),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  '今天也一起完成一點點任務，讓世界多一點溫暖 ',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    height: 1.45,
                    color: Color(0xFF6A4A2A),
                  ),
                ),
                const SizedBox(height: 24),

                const _HeroImage(),
                const SizedBox(height: 24),

                const _TipBubble(),

                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HeroImage extends StatelessWidget {
  const _HeroImage();

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final double heroHeight = size.height * 0.35; // 約 1/3 高度，可視情況調整

    return SizedBox(
      height: heroHeight,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              blurRadius: 18,
              spreadRadius: 1,
              offset: const Offset(0, 10),
              color: Colors.brown.withOpacity(0.12),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: Image.asset('assets/background/mango.PNG', fit: BoxFit.cover),
        ),
      ),
    );
  }
}

class _TipBubble extends StatelessWidget {
  const _TipBubble();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.center,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // 主體泡泡
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Color(0xFFE6C68A), width: 2),
              boxShadow: [
                BoxShadow(
                  blurRadius: 12,
                  spreadRadius: 1,
                  offset: const Offset(0, 6),
                  color: Colors.brown.withOpacity(0.12),
                ),
              ],
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '小提示',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF4A2E14),
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  '從下方頁籤前往「任務」、「寵物」、「商店」等頁面，\n'
                  '完成公益任務、養成你的可愛夥伴 ✨',
                  style: TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w600,
                    height: 1.55,
                    color: Color(0xFF6A4A2A),
                  ),
                ),
              ],
            ),
          ),

          // 對話框的小尾巴
          Positioned(
            top: -20,
            left: 60, // 尾巴位置，可依喜好調整
            child: CustomPaint(
              size: const Size(32, 22),
              painter: _BubbleTailPainter(
                fillColor: Colors.white,
                borderColor: Color(0xFFE6C68A),
                borderWidth: 2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BubbleTailPainter extends CustomPainter {
  final Color fillColor;
  final Color borderColor;
  final double borderWidth;

  _BubbleTailPainter({
    required this.fillColor,
    required this.borderColor,
    this.borderWidth = 2,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final fillPaint =
        Paint()
          ..color = fillColor
          ..style = PaintingStyle.fill;

    final strokePaint =
        Paint()
          ..color = borderColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = borderWidth
          ..strokeJoin = StrokeJoin.round;

    // 半月型小尾巴進行 Path 繪製
    final path =
        Path()
          ..moveTo(0, h) // 左下角開始（底部）
          ..quadraticBezierTo(
            w * 0.15,
            h * 0.45,
            w * 0.5,
            0, // 尖端
          )
          ..quadraticBezierTo(
            w * 0.85,
            h * 0.45,
            w,
            h, // 右下角
          )
          ..close();

    // 先填滿
    canvas.drawPath(path, fillPaint);

    //只畫「非底邊」的兩條邊框
    final borderPath =
        Path()
          ..moveTo(0, h)
          ..quadraticBezierTo(w * 0.15, h * 0.45, w * 0.5, 0)
          ..quadraticBezierTo(w * 0.85, h * 0.45, w, h);

    canvas.drawPath(borderPath, strokePaint); // 只有兩條弧線
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
