import 'package:flutter/material.dart';
import 'package:flutter_frontend/screens/home_tab.dart';

import 'package:flutter_frontend/screens/map.dart';
import 'package:flutter_frontend/screens/pet.dart';
import 'package:flutter_frontend/screens/shop.dart';
import 'package:flutter_frontend/screens/event.dart';
import 'package:flutter_frontend/screens/setting.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int? _currentTabIndex;
  final PageController _pageController = PageController();

  final List<Widget> _pages = const [
    PetPage(),
    ShopPage(),
    EventPage(),
    SettingPage(),
  ];

  void _onTabSelected(int index) {
    setState(() => _currentTabIndex = index);
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  Widget _buildTabButton({
    required IconData icon,
    required String label,
    required int index,
  }) {
    final isSelected = _currentTabIndex == index;
    return GestureDetector(
      onTap: () => _onTabSelected(index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 28,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('首頁')),

      //主內容區
      body:
          _currentTabIndex == null
              ? const HomeTab()
              : PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(), // 禁止滑動
                children: _pages,
              ),

      //主按鈕
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.amber,
        shape: const CircleBorder(),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const MapPage()),
          );
        },
        child: const Icon(Icons.map, color: Colors.brown, size: 32),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

      //底部固定欄位
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8.0,
        child: SizedBox(
          height: 72,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              //左側區
              _buildTabButton(
                icon: Icons.cruelty_free_outlined,
                label: '寵物系統',
                index: 0,
              ),
              _buildTabButton(
                icon: Icons.add_shopping_cart,
                label: '商城系統',
                index: 1,
              ),

              //中間主按鈕
              const SizedBox(width: 48),

              //右側區
              _buildTabButton(
                icon: Icons.announcement_rounded,
                label: '特殊活動',
                index: 2,
              ),
              _buildTabButton(
                icon: Icons.construction,
                label: '系統設定',
                index: 3,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
