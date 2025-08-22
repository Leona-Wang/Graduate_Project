import 'package:flutter/material.dart';
import 'package:flutter_frontend/screens/personal_screens/personal_home.dart';
import 'package:flutter_frontend/screens/personal_screens/personal_map.dart';
import 'package:flutter_frontend/screens/personal_screens/personal_pet.dart';
import 'package:flutter_frontend/screens/personal_screens/personal_shop.dart';
import 'package:flutter_frontend/screens/personal_screens/personal_event.dart';
import 'package:flutter_frontend/screens/personal_screens/personal_setting.dart';

class PersonalHomeTab extends StatefulWidget {
  const PersonalHomeTab({super.key});

  static _HomePageState? of(BuildContext context) {
    return context.findAncestorStateOfType<_HomePageState>();
  }

  @override
  State<PersonalHomeTab> createState() => _HomePageState();
}

class _HomePageState extends State<PersonalHomeTab> {
  int _currentTabIndex = 0;

  void switchTab(int indext) {
    setState(() {
      _currentTabIndex = indext;
    });
  }

  final List<Widget> _pages = const [
    PersonalHomePage(), //0
    PersonalPetPage(), //1
    PersonalShopPage(), //2
    PersonalEventPage(), //3
    PersonalSettingPage(), //4
  ];

  final List<GlobalKey<NavigatorState>> _navigatorKeys = List.generate(
    5,
    (index) => GlobalKey<NavigatorState>(),
  );

  void _selectTab(int index) {
    if (_currentTabIndex == index) {
      // 重複點擊 pop 回該頁的根
      _navigatorKeys[index].currentState?.popUntil((route) => route.isFirst);
    } else {
      setState(() {
        _currentTabIndex = index;
      });
    }
  }

  void _openMapPage() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const PersonalMapPage()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      /**appBar: AppBar(
        automaticallyImplyLeading: false,
        leading:
            _currentTabIndex != 0
                ? IconButton(
                  onPressed: () {
                    setState(() => _currentTabIndex = 0);
                  },
                  icon: const Icon(Icons.arrow_back),
                )
                : null,
        title: Text(_getTitleForIndex(_currentTabIndex)),
      ),**/
      body: Stack(
        children: List.generate(_pages.length, (index) {
          return Offstage(
            offstage: _currentTabIndex != index,
            child: Navigator(
              key: _navigatorKeys[index],
              onGenerateRoute:
                  (settings) =>
                      MaterialPageRoute(builder: (_) => _pages[index]),
            ),
          );
        }),
      ), //切換頁面
      //地圖按鈕，大圓圓
      floatingActionButton: SizedBox(
        height: 64,
        width: 64,
        child: FloatingActionButton(
          backgroundColor: Colors.amber,
          shape: const CircleBorder(),
          onPressed: _openMapPage,
          child: const Icon(Icons.map, size: 32, color: Colors.brown),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8.0,
        child: SizedBox(
          height: 72,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _navButton(
                icon: Icons.cruelty_free_outlined,
                label: '寵物',
                pageIndex: 1,
              ),
              _navButton(
                icon: Icons.add_shopping_cart,
                label: '商城',
                pageIndex: 2,
              ),
              const SizedBox(width: 48), //中間主按鈕位置
              _navButton(
                icon: Icons.announcement_rounded,
                label: '活動',
                pageIndex: 3,
              ),
              _navButton(icon: Icons.construction, label: '設定', pageIndex: 4),
            ],
          ),
        ),
      ),
    );
  }

  //按鈕格式
  Widget _navButton({
    required IconData icon,
    required String label,
    required int pageIndex,
  }) {
    final isSelected = _currentTabIndex == pageIndex;
    return GestureDetector(
      onTap: () => _selectTab(pageIndex),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 26,
            color: isSelected ? Colors.amber : Colors.grey[700],
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: isSelected ? Colors.amber : Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }

  //最上層返回鍵標題
  /**String _getTitleForIndex(int index) {
    switch (index) {
      case 1:
        return '寵物';
      case 2:
        return '商城';
      case 3:
        return '活動';
      case 4:
        return '設定';
      default:
        return "";
    }
  }**/
}
