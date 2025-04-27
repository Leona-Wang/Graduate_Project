import 'package:flutter/material.dart';
import 'package:getwidget/getwidget.dart';
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
    ['快來入境好忙國!'],
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
    _pageController.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _prevOrSkip() {
    if (currentPage == 0) {
      _pageController.animateToPage(
        descriptions.length - 1,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Widget _buildNormalPageContent() {
    return Column(
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
                        fontWeight: FontWeight.bold,
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
                      style: TextStyle(fontSize: 16.sp, color: Colors.black87),
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
                        currentPage == index ? Colors.black : Colors.grey[300],
                  ),
                ),
              ),
            ),
            TextButton(
              onPressed: _nextPage,
              child: Text('下一頁', style: TextStyle(fontSize: 16.sp)),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLastPageContent() {
    return SizedBox.expand(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '歡迎入境好忙國',
            style: TextStyle(
              fontSize: 32.sp,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 10.h),
          Text(
            '一起用行動支持公益～',
            style: TextStyle(fontSize: 16.sp, color: Colors.black87),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 10.h),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: double.infinity,
                child: GFButton(
                  onPressed: () {},
                  color: GFColors.SECONDARY,
                  shape: GFButtonShape.pills,
                  type: GFButtonType.solid,
                  child: Text(
                    "我是個人使用者，入境接收任務",
                    style: TextStyle(
                      fontSize: 16.sp,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              //SizedBox(height: 16.h),
              SizedBox(
                width: double.infinity,
                child: GFButton(
                  onPressed: () {},
                  color: GFColors.SECONDARY,
                  shape: GFButtonShape.pills,
                  type: GFButtonType.solid,
                  child: Text(
                    "我是慈善機構，入境創建委託所",
                    style: TextStyle(
                      fontSize: 16.sp,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 20.h),
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
              TextButton(onPressed: () {}, child: Text('')),
            ],
          ),
        ],
      ),
    );
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
              child:
                  currentPage == slideList.length - 1
                      ? _buildLastPageContent()
                      : _buildNormalPageContent(),
            ),
          ),
        ],
      ),
    );
  }
}
