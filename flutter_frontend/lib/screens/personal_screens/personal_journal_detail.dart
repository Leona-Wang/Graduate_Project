import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_frontend/api_client.dart';
import 'package:flutter_frontend/config.dart';
import 'package:flutter_frontend/screens/personal_screens/personal_qr_code.dart';

class PersonalJournalDetailPage extends StatefulWidget {
  final int eventId;

  const PersonalJournalDetailPage({super.key, required this.eventId});

  @override
  State<PersonalJournalDetailPage> createState() =>
      PersonalJournalDetailPageState();
}

class PersonalJournalDetailPageState extends State<PersonalJournalDetailPage> {
  Map<String, dynamic>? eventData;
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    fetchEventDetail();
  }

  Future<void> fetchEventDetail() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final apiClient = ApiClient();
      await apiClient.init();

      final url = ApiPath.charityEventDetail(widget.eventId);
      final response = await apiClient.get(url);
      print(response.body);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['event'] != null) {
          setState(() => eventData = Map<String, dynamic>.from(data['event']));
        } else {
          setState(() => errorMessage = '無法取得活動資料');
        }
      } else {
        setState(() => errorMessage = '伺服器回應錯誤 (${response.statusCode})');
      }
    } catch (e) {
      setState(() => errorMessage = '取得詳情時發生錯誤: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  void toQRCode() {
    if (eventData == null) return;

    final String eventName = (eventData!['name'] ?? '未命名活動').toString();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PersonalQRCodePage(eventName: eventName),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final brown = Colors.brown[800]!;

    Widget bodyContent;

    if (isLoading) {
      bodyContent = const Center(child: CircularProgressIndicator());
    } else if (errorMessage != null) {
      bodyContent = Center(
        child: Text(
          errorMessage!,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: brown,
          ),
          textAlign: TextAlign.center,
        ),
      );
    } else if (eventData == null) {
      bodyContent = Center(
        child: Text(
          '找不到活動資料',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: brown,
          ),
        ),
      );
    } else {
      final event = eventData!;
      bodyContent = SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // 活動名稱
            Text(
              event['name'] ?? '未命名活動',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w900,
                color: brown,
              ),
            ),
            const SizedBox(height: 14),

            // 狀態顯示
            if ((event['statusDisplay'] ?? '').toString().isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.amber[100],
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  event['statusDisplay'],
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: brown,
                  ),
                ),
              ),
            const SizedBox(height: 26),

            // 資訊卡片
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: Colors.brown.withOpacity(0.18),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.07),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  infoRow('主辦單位', event['mainOrganizer']),
                  infoRow('活動類型', event['eventType']),
                  infoRow('地址', event['address']),
                  infoRow('報名截止', event['signupDeadline']),
                  infoRow('開始時間', event['startTime']),
                  infoRow('結束時間', event['endTime']),
                  infoRow('描述', event['description']),
                ],
              ),
            ),
            const SizedBox(height: 36),

            if (event['statusDisplay'] == '進行中')
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber,
                  foregroundColor: Colors.brown[900],
                  minimumSize: const Size(200, 55),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                  elevation: 4,
                ),
                icon: const Icon(Icons.qr_code, size: 28),
                label: const Text('進行報到'),
                onPressed: toQRCode,
              ),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Color(0xFFe6ccb2),
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.only(left: 12.0, top: 6.0, bottom: 6.0),
          child: CircleAvatar(
            backgroundColor: Colors.amber,
            child: IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back_ios_new, color: Colors.brown),
            ),
          ),
        ),
        title: Text(
          '任務詳情',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w900,
            color: brown,
          ),
        ),
      ),
      body: bodyContent,
    );
  }

  Widget infoRow(String title, dynamic value) {
    final brown = Colors.brown[800]!;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$title：',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: brown,
            ),
          ),
          Expanded(
            child: Text(
              value?.toString().isNotEmpty == true ? value.toString() : '-',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: Colors.brown[700],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
