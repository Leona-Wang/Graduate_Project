import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../routes.dart';
import '../config.dart';

class Example1Page extends StatefulWidget {
  const Example1Page({super.key});
  @override
  Example1PageState createState() => Example1PageState();
}

class Example1PageState extends State<Example1Page> {
  final TextEditingController _controller = TextEditingController();

  Future<void> sendNumber() async {
    final int number = int.tryParse(_controller.text) ?? 0;
    final url = Uri.parse('$baseUrl${ApiPath.testApi}');

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'number': number}),
    );

    // 檢查 widget 是否還在畫面上
    if (!mounted) return;

    if (response.statusCode == 200) {
      final result = json.decode(response.body)['result'];
      Navigator.pushNamed(
        context,
        AppRoutes.example2,
        arguments: result, // result 是 int
      );
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('後端錯誤')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('輸入數字')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _controller,
              decoration: InputDecoration(labelText: '請輸入一個數字'),
              keyboardType: TextInputType.number,
            ),
            ElevatedButton(onPressed: sendNumber, child: Text('送出')),
          ],
        ),
      ),
    );
  }
}
