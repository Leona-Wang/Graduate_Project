import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

class QRCodeGenerator extends StatelessWidget {
  final String token;
  final double size;

  const QRCodeGenerator({Key? key, required this.token, this.size = 200.0})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (token.isEmpty) {
      return const Center(child: Text('無可用的 Token'));
    }

    return QrImageView(data: token, version: QrVersions.auto, size: size);
  }
}
