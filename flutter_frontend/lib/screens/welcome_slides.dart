import 'package:flutter/material.dart';

class WelcomeSlidesPage extends StatefulWidget {
  const WelcomeSlidesPage({super.key});
  @override
  WelcomeSlidesPageState createState() => WelcomeSlidesPageState();
}

class WelcomeSlidesPageState extends State<WelcomeSlidesPage> {
  late PageController _pageController;
  int currentPage = 0;
  late List<Widget> slideList;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
    slideList = _buildSlides();
  }

  List<Widget> _buildSlides() {
    return [
      Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/welcomeSlides/image1.png'),
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(Colors.black26, BlendMode.darken),
          ),
        ),
        child: const Padding(
          padding: EdgeInsets.only(top: 70.0, left: 20),
          child: Text(
            'Welcome!',
            style: TextStyle(
              color: Colors.white,
              fontSize: 25,
              decoration: TextDecoration.none,
            ),
          ),
        ),
      ),
      for (int i = 2; i <= 4; i++)
        Container(
          decoration: BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/welcomeSlides/image$i.png'),
              fit: BoxFit.cover,
              colorFilter: const ColorFilter.mode(
                Colors.black26,
                BlendMode.darken,
              ),
            ),
          ),
        ),
    ];
  }

  void _nextPage() {
    if (currentPage < slideList.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      // TODO: 導入下一頁，例如 Navigator.pushReplacementNamed(context, AppRoutes.login);
      print('開始使用');
    }
  }

  void _prevOrSkip() {
    if (currentPage == 0) {
      // TODO: 略過導覽頁邏輯
      print('跳過導覽');
    } else {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          PageView(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                currentPage = index;
              });
            },
            children: slideList,
          ),
          Positioned(
            bottom: 30,
            left: 20,
            right: 20,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: _prevOrSkip,
                  child: Text(
                    currentPage == 0 ? '跳過' : '上一頁',
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ),
                Row(
                  children: List.generate(
                    slideList.length,
                    (index) => Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color:
                            currentPage == index
                                ? Colors.white
                                : Colors.white30,
                      ),
                    ),
                  ),
                ),
                TextButton(
                  onPressed: _nextPage,
                  child: Text(
                    currentPage == slideList.length - 1 ? '開始使用' : '下一頁',
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
