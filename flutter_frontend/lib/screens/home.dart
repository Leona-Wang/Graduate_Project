import 'package:flutter/material.dart';

class HomePage extends StatelessWidget {
  final int result;
  const HomePage({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('結果')),
      body: Center(child: Text('結果是：$result', style: TextStyle(fontSize: 24))),
    );
  }
}
