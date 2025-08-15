import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../api_client.dart';

class CharityMailboxPage extends StatefulWidget {
  const CharityMailboxPage({super.key});

  State<CharityMailboxPage> createState() => CharityMailboxPageState();
}

class CharityMailboxPageState extends State<CharityMailboxPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  List<Map<String, dynamic>> per_noti = [];
  List<Map<String, dynamic>> eve_noti = [];

  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    fetchMails();
  }

  Future<void> fetchMails() async {
    final uriMail = Uri.parse('uri'); //待新增

    try {
      final apiClient = ApiClient();
      await apiClient.init();

      final getMails = await apiClient.get(uriMail.toString());
      if (getMails.statusCode == 200) {
        final mails = jsonDecode(getMails.body) as List;

        //分類
        //待新增'類型名稱'
        setState(() {
          per_noti =
              mails
                  .where((m) => m['type'] == '')
                  .cast<Map<String, dynamic>>()
                  .toList();
          eve_noti =
              mails
                  .where((m) => m['type'] == '')
                  .cast<Map<String, dynamic>>()
                  .toList();
          isLoading = false;
        });
      }
    } catch (e) {
      print('API error: $e');
    }
  }

  Widget buildMailList(List<Map<String, dynamic>> mails) {
    if (isLoading) return const Center(child: CircularProgressIndicator());
    if (mails.isEmpty) return const Center(child: Text('沒有郵件'));

    return ListView.builder(
      itemCount: mails.length,
      itemBuilder: (context, index) {
        final mail = mails[index];
        return ListTile(
          title: Text(mail['title'] ?? ''),
          subtitle: Text('ID: ${mail['id']}'),
          //trailing: const Icon(Icons.chevron_right),
          /*onTap: () {
            Navigator.push(context, MaterialPageRoute(builder: (context) => 這裡放詳情頁面(mail: mail)));
          },*/
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
        children: [buildMailList(per_noti), buildMailList(eve_noti)],
      ),
    );
  }
}
