import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class StockScannerPage extends StatefulWidget {
  const StockScannerPage({super.key});

  @override
  State<StockScannerPage> createState() => _StockScannerPageState();
}

class _StockScannerPageState extends State<StockScannerPage> {
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
  );
  bool _hasDetected = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Barkod Tara'),
        actions: [
          IconButton(
            icon: const Icon(Icons.flash_on_outlined),
            onPressed: () => _controller.toggleTorch(),
          ),
        ],
      ),
      body: MobileScanner(
        controller: _controller,
        fit: BoxFit.cover,
        onDetect: (capture) {
          if (_hasDetected) return;
          final barcode = capture.barcodes.firstOrNull;
          final rawValue = barcode?.displayValue ?? barcode?.rawValue;
          if (rawValue != null) {
            _hasDetected = true;
            Navigator.of(context).pop(rawValue);
          }
        },
      ),
    );
  }
}

extension<T> on List<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
