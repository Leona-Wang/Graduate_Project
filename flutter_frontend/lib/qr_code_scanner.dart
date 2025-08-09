import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class QRCodeScanner extends StatefulWidget {
  final void Function(String token) onTokenScanned;

  const QRCodeScanner({Key? key, required this.onTokenScanned})
    : super(key: key);

  @override
  State<QRCodeScanner> createState() => QRCodeScannerState();
}

class QRCodeScannerState extends State<QRCodeScanner> {
  bool _isScanned = false; //是否重複掃描
  final MobileScannerController controller = MobileScannerController();

  @override
  Widget build(BuildContext context) {
    return MobileScanner(
      controller: controller,
      onDetect: (BarcodeCapture capture) {
        if (_isScanned) return; //避免重複觸發
        final List<Barcode> barcodes = capture.barcodes;
        if (barcodes.isNotEmpty && barcodes.first.rawValue != null) {
          _isScanned = true;
          widget.onTokenScanned(barcodes.first.rawValue!);
        }
      },
    );
  }
}
