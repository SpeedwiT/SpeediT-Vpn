import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../l10n/strings.dart';

class QrScanScreen extends StatefulWidget {
  const QrScanScreen({super.key});
  @override
  State<QrScanScreen> createState() => _QrScanScreenState();
}

class _QrScanScreenState extends State<QrScanScreen> {
  bool _done = false;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(s.t('scan_qr'))),
      body: MobileScanner(
        onDetect: (capture) {
          if (_done) return;
          final codes = capture.barcodes;
          if (codes.isEmpty) return;
          final value = codes.first.rawValue;
          if (value == null || value.isEmpty) return;
          _done = true;
          Navigator.of(context).pop(value);
        },
      ),
    );
  }
}
