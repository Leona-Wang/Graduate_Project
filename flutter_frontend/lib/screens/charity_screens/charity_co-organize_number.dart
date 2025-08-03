import 'package:flutter/material.dart';

class CharityCoorganizeNumberPage extends StatefulWidget {
  const CharityCoorganizeNumberPage({Key? key}) : super(key: key);

  @override
  State<CharityCoorganizeNumberPage> createState() => _CharityCoorganizeNumberPageState();
}

class _CharityCoorganizeNumberPageState extends State<CharityCoorganizeNumberPage> {
  final TextEditingController _codeController = TextEditingController();

  void _submitCode() {
    final code = _codeController.text.trim();

    if (code.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("請輸入邀請碼")),
      );
      return;
    }

    // TODO: 後端 API
    print("使用者輸入的邀請碼：$code");

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("已提交邀請碼：$code")),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("請輸入協辦邀請碼："),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("請輸入協辦邀請碼", style: TextStyle(fontSize: 18)),
            SizedBox(height: 16),
            TextField(
              controller: _codeController,
              decoration: InputDecoration(
                hintText: "例如：ABNID9839439",
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 24),
            Center(
              child: ElevatedButton(
                onPressed: _submitCode,
                child: Text("送出"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
