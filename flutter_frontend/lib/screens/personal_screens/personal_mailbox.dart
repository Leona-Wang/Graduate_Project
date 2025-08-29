import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_frontend/config.dart';
import 'package:http/http.dart';
import '../../api_client.dart';
import 'package:flutter_frontend/routes.dart';

class PersonalMailboxPage extends StatefulWidget {
  const PersonalMailboxPage({super.key});

  @override
  State<PersonalMailboxPage> createState() => PersonalMailboxPageState();
}

class PersonalMailboxPageState extends State<PersonalMailboxPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  List<Map<String, dynamic>> perNoti = []; //個人通知
  List<Map<String, dynamic>> eveNoti = []; //活動通知
  List<Map<String, dynamic>> govNoti = []; //官方通知
  List<Map<String, dynamic>> priNoti = []; //獎勵通知

  bool isLoading = false;

  final ApiClient _apiClient = ApiClient();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);

    //監聽tab切換事件
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        final type = getTypeForIndex(_tabController.index);
        fetchMails(type);
      } //避免重複觸發
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
        return 'event';
      case 2:
        return 'system';
      case 3:
        return 'reward';
      default:
        return 'notice';
    }
  }

  Future<void> fetchMails(String type) async {
    setState(() => isLoading = true);

    final url = ApiPath.mailListByType(type);
    final uriMail = Uri.parse(url);
    print("呼叫 API URL: $url");

    try {
      final getMails = await _apiClient.get(uriMail.toString());
      if (getMails.statusCode == 200) {
        final mails =
            (jsonDecode(getMails.body) as List).cast<Map<String, dynamic>>();

        //分類
        setState(() {
          switch (type) {
            case 'notice':
              perNoti = mails;
              break;
            case 'event':
              eveNoti = mails;
              break;
            case 'system':
              govNoti = mails;
              break;
            case 'reward':
              priNoti = mails;
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

  //信件列表
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
              AppRoutes.personalMailDetail, // 路由
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
          tabs: const [
            Tab(text: '個人信件'),
            Tab(text: '活動通知'),
            Tab(text: '官方郵件'),
            Tab(text: '獎勵發放'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          buildMailList('notice', perNoti),
          buildMailList('event', eveNoti),
          buildMailList('system', govNoti),
          buildMailList('reward', priNoti),
        ],
      ),
    );
  }
}
