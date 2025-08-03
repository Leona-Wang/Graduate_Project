import 'package:flutter/material.dart';

class CharityCoorganizerPage extends StatefulWidget {
  final int eventId; // 活動ID

  const CharityCoorganizerPage({Key? key, required this.eventId}) : super(key: key);

  @override
  _CharityCoorganizerPageState createState() => _CharityCoorganizerPageState();
}

class _CharityCoorganizerPageState extends State<CharityCoorganizerPage> {
  // 測試用假資料
  List<Map<String, dynamic>> applications = [
    {
      "id": 1,
      "userName": "A用戶",
      "message": "提供場地",
      "status": "pending",
    },
    {
      "id": 2,
      "userName": "B協會",
      "message": "提供人力",
      "status": "pending",
    },
    {
      "id": 3,
      "userName": "C協會",
      "message": "提供物資",
      "status": "accepted",
    },
  ];

  @override
  void initState() {
    super.initState();
    debugPrint('進入協辦審核頁，活動 ID：${widget.eventId}');
  }

  void _updateStatus(int id, String newStatus) {
    setState(() {
      final index = applications.indexWhere((app) => app["id"] == id);
      if (index != -1) {
        applications[index]["status"] = newStatus;
      }
    });

    // TODO: 未來串後端更新狀態
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("協辦申請審核 (活動 ID: ${widget.eventId})"),
      ),
      body: ListView.builder(
        padding: EdgeInsets.all(12),
        itemCount: applications.length,
        itemBuilder: (context, index) {
          final app = applications[index];

          return Card(
            margin: EdgeInsets.symmetric(vertical: 8),
            child: Padding(
              padding: EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("申請者：${app["userName"]}", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  SizedBox(height: 4),
                  Text("留言：${app["message"]}"),
                  SizedBox(height: 8),
                  _buildStatusButton(app),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatusButton(Map<String, dynamic> app) {
    final status = app["status"];
    final id = app["id"];

    if (status == "pending") {
      return Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          ElevatedButton.icon(
            icon: Icon(Icons.check),
            label: Text("接受"),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            onPressed: () => _updateStatus(id, "accepted"),
          ),
          SizedBox(width: 8),
          ElevatedButton.icon(
            icon: Icon(Icons.close),
            label: Text("拒絕"),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => _updateStatus(id, "rejected"),
          ),
        ],
      );
    } else if (status == "accepted") {
      return Text("✅ 已接受", style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold));
    } else if (status == "rejected") {
      return Text("❌ 已拒絕", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold));
    } else {
      return Text("未知狀態");
    }
  }
}
