import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_frontend/config.dart';
import '../../api_client.dart';
import 'package:flutter_frontend/routes.dart';

class CharityMailboxPage extends StatefulWidget {
  const CharityMailboxPage({super.key});

  @override
  State<CharityMailboxPage> createState() => CharityMailboxPageState();
}

class CharityMailboxPageState extends State<CharityMailboxPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  List<Map<String, dynamic>> perNoti = [];
  List<Map<String, dynamic>> eveNoti = [];

  bool isLoading = false;

  final ApiClient _apiClient = ApiClient();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        final type = getTypeForIndex(_tabController.index);
        fetchMails(type);
      }
    });

    _apiClient.init().then((_) {
      fetchMails(getTypeForIndex(0));
    });
  }

  String getTypeForIndex(int index) {
    switch (index) {
      case 0:
        return 'notice';
      case 1:
        return 'canvass';
      default:
        return 'notice';
    }
  }

  Future<void> fetchMails(String type) async {
    setState(() => isLoading = true);

    final url = ApiPath.mailListByType(type);
    final uriMail = Uri.parse(url);

    try {
      final getMails = await _apiClient.get(uriMail.toString());
      if (getMails.statusCode == 200) {
        final mails =
            (jsonDecode(getMails.body) as List).cast<Map<String, dynamic>>();

        //分類
        //待新增'類型名稱'
        setState(() {
          switch (type) {
            case 'notice':
              perNoti = mails;
              break;
            case 'canvass':
              eveNoti = mails;
              break;
          }
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
        print('API錯誤: ${getMails.statusCode} -> ${getMails.body}');
      }
    } catch (e) {
      print('API Exception: $e');
      setState(() => isLoading = false);
    }
  }

  Widget buildMailList(String type, List<Map<String, dynamic>> mails) {
    if (isLoading == true) {
      return const Center(child: CircularProgressIndicator());
    }
    if (mails.isEmpty) return const Center(child: Text('沒有郵件'));

    return ListView.builder(
      itemCount: mails.length,
      itemBuilder: (context, index) {
        final mail = mails[index];
        final bool isRead = mail['isRead'] ?? false;

        return ListTile(
          leading: Icon(
            isRead ? Icons.mark_email_read : Icons.mark_email_unread,
            color: isRead ? Colors.grey : Colors.brown,
          ),
          title: Text(
            mail['title'] ?? '',
            style: TextStyle(
              fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
            ),
          ),
          subtitle: Text('ID: ${mail['id']}'),
          onTap: () async {
            final result = await Navigator.pushNamed(
              context,
              AppRoutes.charityMailDetail, // 路由
              arguments: mail['id'] as int, // 傳 int
            );

            if (result == true) {
              setState(() {
                mails[index]['isRead'] = true;
              });
            }
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('信箱'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [Tab(text: '個人信件'), Tab(text: '活動通知')],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          buildMailList('notice', perNoti),
          buildMailList('canvass', eveNoti),
        ],
      ),
    );
  }
}
