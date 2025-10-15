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
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PersonalQRCodePage(eventName: eventData!['eventName']),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget bodyContent;

    if (isLoading) {
      bodyContent = const Center(child: CircularProgressIndicator());
    } else if (errorMessage != null) {
      bodyContent = Center(child: Text(errorMessage!));
    } else if (eventData == null) {
      bodyContent = const Center(child: Text('找不到活動資料'));
    } else {
      final event = eventData!;
      bodyContent = SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              event['name'] ?? '未命名活動',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.brown,
              ),
            ),
            const SizedBox(height: 10),

            Text(
              event['statusDisplay'] ?? '',
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 20),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.amberAccent),
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
            const SizedBox(height: 30),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amberAccent,
                foregroundColor: Colors.brown,
                minimumSize: const Size(160, 48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.qr_code),
              label: const Text('查看 QR Code'),
              onPressed: toQRCode,
            ),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: Padding(
          padding: const EdgeInsets.only(left: 12.0, top: 6.0, bottom: 6.0),
          child: CircleAvatar(
            backgroundColor: Colors.amberAccent,
            child: IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back_ios_new, color: Colors.brown),
              tooltip: '返回',
            ),
          ),
        ),
        title: const Text('活動詳情'),
      ),
      body: bodyContent,
    );
  }

  Widget infoRow(String title, dynamic value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$title：', style: const TextStyle(fontWeight: FontWeight.bold)),
          Expanded(child: Text(value?.toString() ?? '-')),
        ],
      ),
    );
  }
}
