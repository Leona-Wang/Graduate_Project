import 'package:flutter/material.dart';
import 'package:flutter_frontend/screens/personal_screens/personal_event_list.dart';
import 'package:flutter_frontend/screens/personal_screens/personal_home_tab.dart';
import 'package:flutter_frontend/screens/personal_screens/personal_map.dart';

class PersonalMapTab extends StatefulWidget {
  const PersonalMapTab({super.key});

  static MapTabState? of(BuildContext context) {
    return context.findAncestorStateOfType<MapTabState>();
  }

  @override
  State<PersonalMapTab> createState() => MapTabState();
}

class MapTabState extends State<PersonalMapTab> {
  int _currentTabIndex = 0;
  bool _showBottomBar = true;

  void switchTab(int indext) {
    setState(() {
      _currentTabIndex = indext;
    });
  }

  void hideBottomBar() {
    setState(() => _showBottomBar = false);
  }

  void showBottomBar() {
    setState(() => _showBottomBar = true);
  }

  final List<Widget> _pages = const [
    PersonalMapPage(), //0
    PersonalEventListPage(), //1
    PersonalEventListPage(), //2，再更改為其他頁面
    PersonalEventListPage(), //3，再更改為其他頁面
    PersonalEventListPage(), //4，再更改為其他頁面
  ];

  final List<GlobalKey<NavigatorState>> _navigatorKeys = List.generate(
    5,
    (index) => GlobalKey<NavigatorState>(),
  );

  void _selectTab(int index) {
    setState(() {
      _currentTabIndex = index;
    });
  }

  void _openHomePage() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const PersonalHomeTab()));
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
      ),
      //切換頁面
      //地圖按鈕，大圓圓
      floatingActionButton: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        //height: _showBottomBar ?  : 0,
        child:
            _showBottomBar
                ? SizedBox(
                  height: 64,
                  width: 64,
                  child: FloatingActionButton(
                    backgroundColor: Colors.amber,
                    shape: const CircleBorder(),
                    onPressed: _openHomePage,
                    child: const Icon(
                      Icons.home_filled,
                      size: 32,
                      color: Colors.brown,
                    ),
                  ),
                )
                : null,
      ),

      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

      bottomNavigationBar: Offstage(
        offstage: !_showBottomBar,
        child: AnimatedOpacity(
          opacity: _showBottomBar ? 1 : 0,
          duration: const Duration(milliseconds: 300),
          child: BottomAppBar(
            shape: const CircularNotchedRectangle(),
            notchMargin: 8.0,
            child: SizedBox(
              height: 72,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _navButton(
                    icon: Icons.event_note_sharp,
                    label: '任務一覽',
                    pageIndex: 1,
                  ),
                  _navButton(
                    icon: Icons.star_outline_rounded,
                    label: '任務推薦',
                    pageIndex: 2,
                  ),
                  const SizedBox(width: 48), //中間主按鈕位置
                  _navButton(
                    icon: Icons.emergency_share_rounded,
                    label: '宣傳任務',
                    pageIndex: 3,
                  ),
                  _navButton(
                    icon: Icons.construction,
                    label: '系統設定',
                    pageIndex: 4,
                  ),
                ],
              ),
            ),
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
