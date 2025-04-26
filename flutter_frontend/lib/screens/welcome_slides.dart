import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class WelcomeSlidesPage extends StatefulWidget {
  const WelcomeSlidesPage({super.key});
  @override
  WelcomeSlidesPageState createState() => WelcomeSlidesPageState();
}

class WelcomeSlidesPageState extends State<WelcomeSlidesPage> {
  late PageController _pageController;
  int currentPage = 0;

  final List<String> slideList = [
    'assets/welcomeSlides/image1.png',
    'assets/welcomeSlides/image2.png',
    'assets/welcomeSlides/image3.png',
    'assets/welcomeSlides/image4.png',
  ];

  final List<List<String>> titles = [
    ['做好事，蒐集寶物'],
    ['捐獻給支持的機構'],
    ['以小博大，拼運氣'],
    ['準備好了嗎?', '申辦好忙國入境許可，', '成為我們的一員!'],
  ];

  final List<List<String>> descriptions = [
    ['與寵物一起參與慈善活動，', '蒐集掉落的寶物!'],
    ['將取得的鑽石捐獻給慈善機構，', '用行動支持慈善事業經營!'],
    ['把鑽石投入公益彩券，', '做善事的同時發大財!'],
    [],
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
  }

  void _nextPage() {
    if (currentPage < slideList.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      // 最後一頁按下去，導到主畫面或做其他事
      // Navigator.pushReplacementNamed(context, Routes.home);
    }
  }

  void _prevOrSkip() {
    if (currentPage == 0) {
      // 跳過直接到主畫面或其他地方
      // Navigator.pushReplacementNamed(context, Routes.home);
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
      body: Column(
        children: [
          Expanded(
            flex: 3,
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() {
                  currentPage = index;
                });
              },
              itemCount: slideList.length,
              itemBuilder: (context, index) {
                return Container(
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      image: AssetImage(slideList[index]),
                      fit: BoxFit.cover,
                    ),
                  ),
                  alignment: Alignment.topLeft,
                  padding: EdgeInsets.only(top: 70.h, left: 20.w),
                );
              },
            ),
          ),
          Expanded(
            flex: 2,
            child: Container(
              color: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 24.h),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  titles[currentPage].isNotEmpty
                      ? Column(
                        children:
                            titles[currentPage].map<Widget>((line) {
                              return Text(
                                line,
                                style: TextStyle(
                                  fontSize: 32.sp,
                                  color: Colors.black87,
                                ),
                                textAlign: TextAlign.center,
                              );
                            }).toList(),
                      )
                      : const SizedBox.shrink(),
                  descriptions[currentPage].isNotEmpty
                      ? Column(
                        children:
                            descriptions[currentPage].map<Widget>((line) {
                              return Text(
                                line,
                                style: TextStyle(
                                  fontSize: 16.sp,
                                  color: Colors.black87,
                                ),
                                textAlign: TextAlign.center,
                              );
                            }).toList(),
                      )
                      : const SizedBox.shrink(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton(
                        onPressed: _prevOrSkip,
                        child: Text(
                          currentPage == 0 ? '跳過' : '上一頁',
                          style: TextStyle(fontSize: 16.sp),
                        ),
                      ),
                      Row(
                        children: List.generate(
                          slideList.length,
                          (index) => Container(
                            margin: EdgeInsets.symmetric(horizontal: 4.w),
                            width: 8.w,
                            height: 8.w,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color:
                                  currentPage == index
                                      ? Colors.black
                                      : Colors.grey[300],
                            ),
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: _nextPage,
                        child: Text(
                          currentPage == slideList.length - 1 ? '開始使用' : '下一頁',
                          style: TextStyle(fontSize: 16.sp),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
