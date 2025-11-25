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
      } else if (response.statusCode == 400) {
        debugPrint('載入失敗: ${response.statusCode}');
        setState(() {
          userName = '使用者名稱';
          avatarUrl = null;
          isLoading = false;
        });
      } else {
        // fallback
        debugPrint('非預期狀態碼：${response.statusCode}');
        setState(() {
          userName = '使用者名稱';
          avatarUrl = null;
          isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('取個人資訊錯誤: $e');
      setState(() {
        userName = '使用者名稱';
        avatarUrl = null;
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
    final brown = Colors.brown[800]!;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: Padding(
          padding: const EdgeInsets.only(left: 12.0, top: 6.0, bottom: 6.0),
          child: CircleAvatar(
            backgroundColor: Colors.amber,
            child: IconButton(
              onPressed: backToHome,
              icon: const Icon(Icons.arrow_back_ios_new, color: Colors.brown),
              tooltip: '返回主頁',
            ),
          ),
        ),
        title: Text(
          '個人資訊',
          style: TextStyle(
            color: brown,
            fontSize: 22,
            fontWeight: FontWeight.w800,
          ),
        ),
        backgroundColor: const Color(0xFFFFF0D8),
        elevation: 0,
      ),
      body:
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // 頭像區背景
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 32),
                      height: 300,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFFFFF2DD), Color(0xFFFFD798)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 130,
                            height: 130,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.4),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.15),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: CircleAvatar(
                              radius: 60,
                              backgroundColor: Colors.white,
                              foregroundImage:
                                  avatarUrl != null && avatarUrl!.isNotEmpty
                                      ? NetworkImage(avatarUrl!)
                                      : null,
                              child:
                                  (avatarUrl == null ||
                                          avatarUrl!.isEmpty) // ← 修正原本判斷
                                      ? Icon(
                                        Icons.person,
                                        size: 60,
                                        color: Colors.brown[300],
                                      )
                                      : null,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            userName ?? '使用者名稱',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              color: brown,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24), //40
                    // 兩個按鈕區塊
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 8,
                      ),
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
    final brown = Colors.brown[800]!;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.brown.withOpacity(0.08),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(color: Colors.brown.withOpacity(0.15), width: 1),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.amber[300],
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 22, color: Colors.brown[900]),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: brown,
                ),
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: brown, size: 18),
          ],
        ),
      ),
    );
  }
}
