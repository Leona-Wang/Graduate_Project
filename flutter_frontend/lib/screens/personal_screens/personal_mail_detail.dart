import 'package:flutter/material.dart';
import 'package:flutter_frontend/screens/mail/mail_detail.dart';

class PersonalMailDetailPage extends StatelessWidget {
  final int mailId;
  const PersonalMailDetailPage({super.key, required this.mailId});

  @override
  Widget build(BuildContext context) {
    return MessageDetailPage(mailId: mailId);
  }
}
