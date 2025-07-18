import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_frontend/screens/charity_screens/charity_map.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../../routes.dart';
import '../../config.dart';

class CharityNewEventPage extends StatefulWidget {
  const CharityNewEventPage({super.key});

  @override
  State<CharityNewEventPage> createState() => CharityNewEventState();
}

class CharityNewEventState extends State<CharityNewEventPage> {
  TextEditingController locationController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('新增活動')),
      body: SingleChildScrollView(
        child: Align(
          alignment: Alignment.topCenter,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: 500),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: locationController,
                    readOnly: true,
                    onTap: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CharityMapPage(),
                        ),
                      );
                      if (result != null) {
                        locationController.text = result['address'];
                      }
                    },
                    decoration: const InputDecoration(
                      labelText: '活動地點',
                      suffixIcon: Icon(Icons.map),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
