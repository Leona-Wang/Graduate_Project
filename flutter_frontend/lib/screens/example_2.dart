import 'package:flutter/material.dart';

class Example2Page extends StatelessWidget {
  final int result;
  const Example2Page({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('結果')),
      body: Center(child: Text('結果是：$result', style: TextStyle(fontSize: 24))),
    );
  }
}
