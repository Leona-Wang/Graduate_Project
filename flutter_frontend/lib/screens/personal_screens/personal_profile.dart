import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_frontend/api_client.dart';
import 'package:flutter_frontend/config.dart';
import 'package:flutter_frontend/screens/personal_screens/personal_event_favorite.dart';
import 'package:flutter_frontend/screens/personal_screens/personal_event_journal.dart';
import 'package:flutter_frontend/screens/personal_screens/personal_home.dart';

class PersonalProfilePage extends StatefulWidget {
  const PersonalProfilePage({super.key});

  @override
  State<PersonalProfilePage> createState() => PersonalProfilePageState();
}

class PersonalProfilePageState extends State<PersonalProfilePage> {
  String? avatarUrl; //頭像
  String? userName;

  bool isLoading = true;

  void backToHome() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const PersonalHomePage()),
      (route) => false,
    );
  }

  @override
  void initState() {
    super.initState();
    fetchUserData();
  }

  Future<void> fetchUserData() async {
    try {
      final apiClient = ApiClient();
      await apiClient.init();

      final url = ApiPath.getPersonalInfo;
      final response = await apiClient.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        setState(() {
          userName = data['personalName'];
          avatarUrl = data['personalImageUrl'];
          isLoading = false;
        });
      } else {
        debugPrint('載入失敗: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('取個人資訊錯誤: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  void toEventHistory() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const PersonalEventJournalPage()),
    );
  }

  void toEventFavorite() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const PersonalEventFavoritePage(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: Padding(
          padding: const EdgeInsets.only(left: 12.0, top: 6.0, bottom: 6.0),
          child: CircleAvatar(
            backgroundColor: Colors.amberAccent,
            child: IconButton(
              onPressed: backToHome,
              icon: const Icon(Icons.arrow_back_ios_new, color: Colors.brown),
              tooltip: '返回主頁',
            ),
          ),
        ),
        title: const Text('個人資訊'),
      ),
      body:
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                child: Column(
                  children: [
                    // 頭像區背景
                    Container(
                      //width: double.infinity,
                      height: 300,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.orange, Colors.deepOrangeAccent],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      //color: Colors.orange[100],
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircleAvatar(
                            radius: 55,
                            backgroundImage:
                                avatarUrl != null && avatarUrl!.isNotEmpty
                                    ? NetworkImage(avatarUrl!)
                                    : null,
                            backgroundColor: Colors.orange[400],
                            child:
                                avatarUrl == null || avatarUrl!.isNotEmpty
                                    ? const Icon(
                                      Icons.person,
                                      size: 55,
                                      color: Colors.white,
                                    )
                                    : null,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            userName ?? '使用者名稱',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 40),

                    // 兩個按鈕區塊
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        children: [
                          _buildActionButton(
                            context,
                            title: '已參加的活動',
                            icon: Icons.event_available,
                            onTap: toEventHistory,
                          ),
                          const SizedBox(height: 20),
                          _buildActionButton(
                            context,
                            title: '已收藏的活動',
                            icon: Icons.favorite,
                            onTap: toEventFavorite,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
    );
  }

  // 共用按鈕樣式
  Widget _buildActionButton(
    BuildContext context, {
    required String title,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
        decoration: BoxDecoration(
          color: Colors.orange[200],
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.orange.withOpacity(0.3),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(icon, size: 30, color: Colors.white),
            const SizedBox(width: 16),
            Text(
              title,
              style: const TextStyle(fontSize: 18, color: Colors.white),
            ),
            const Spacer(),
            const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 18),
          ],
        ),
      ),
    );
  }
}
