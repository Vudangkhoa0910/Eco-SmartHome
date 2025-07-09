import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class MockQRScannerScreen extends StatefulWidget {
  const MockQRScannerScreen({Key? key}) : super(key: key);

  @override
  State<MockQRScannerScreen> createState() => _MockQRScannerScreenState();
}

class _MockQRScannerScreenState extends State<MockQRScannerScreen> {
  MobileScannerController controller = MobileScannerController();
  String? result;
  bool isScanning = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(Icons.close, color: Colors.white),
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Quét mã QR thiết bị',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: <Widget>[
          Expanded(
            flex: 4,
            child: Stack(
              children: [
                MobileScanner(
                  controller: controller,
                  onDetect: _onQRViewCreated,
                ),
                Positioned(
                  bottom: 40,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: ElevatedButton(
                      onPressed: () async {
                        await controller.toggleTorch();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4CAF50),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 32, vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.flash_on),
                          SizedBox(width: 8),
                          Text('Bật/Tắt đèn pin'),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _onQRViewCreated(BarcodeCapture capture) {
    if (!isScanning) return;

    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isNotEmpty && result == null) {
      final barcode = barcodes.first;
      if (barcode.rawValue != null) {
        setState(() {
          result = barcode.rawValue;
          isScanning = false;
        });
        _handleScanResult(barcode.rawValue);
      }
    }
  }

  void _handleScanResult(String? code) {
    if (code != null) {
      final validKeys = ['smarthome99', 'smarthome88', 'smarthome66'];
      if (validKeys.contains(code)) {
        Navigator.of(context).pop(code);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Mã QR không hợp lệ: $code'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() {
          result = null;
          isScanning = true;
        });
      }
    }
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }
}
