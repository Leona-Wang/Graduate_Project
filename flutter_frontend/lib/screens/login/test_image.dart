import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class TestImagePage extends StatefulWidget {
  const TestImagePage({super.key});

  @override
  State<TestImagePage> createState() => TestImagePageState();
}

class TestImagePageState extends State<TestImagePage> {
  File? avatarFile;
  final picker = ImagePicker();

  final usernameController = TextEditingController();
  final passwordController = TextEditingController();
  final emailController = TextEditingController();

  Future<void> pickImage() async {
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        avatarFile = File(pickedFile.path);
      });
    }
  }

  void register() {
    // 這裡你可以把 username/password/email + avatarFile 傳到後端
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("註冊")),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            // 大頭照選擇欄位
            GestureDetector(
              onTap: pickImage,
              child: CircleAvatar(
                radius: 50,
                backgroundImage:
                    avatarFile != null ? FileImage(avatarFile!) : null,
                child:
                    avatarFile == null
                        ? Icon(Icons.camera_alt, size: 40)
                        : null,
              ),
            ),
            SizedBox(height: 16),

            // 帳號欄位
            TextField(
              controller: usernameController,
              decoration: InputDecoration(labelText: "帳號"),
            ),

            // 密碼欄位
            TextField(
              controller: passwordController,
              decoration: InputDecoration(labelText: "密碼"),
              obscureText: true,
            ),

            // Email 欄位
            TextField(
              controller: emailController,
              decoration: InputDecoration(labelText: "Email"),
            ),

            SizedBox(height: 20),

            ElevatedButton(onPressed: register, child: Text("註冊")),
          ],
        ),
      ),
    );
  }
}
