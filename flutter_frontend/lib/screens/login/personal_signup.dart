import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class PersonalSignupPage extends StatefulWidget {
  const PersonalSignupPage({super.key});

  @override
  State<PersonalSignupPage> createState() => PersonalSignupState();
}

class PersonalSignupState extends State<PersonalSignupPage> {}

@override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(title: const Text('pup')),
    body: const Center(child: Text('絕命測試中...')),
  );
}
