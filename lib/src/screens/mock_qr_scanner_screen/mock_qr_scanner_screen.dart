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
                // QR Scanning Frame Overlay
                Center(
                  child: Container(
                    width: 250,
                    height: 250,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Colors.white,
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Stack(
                      children: [
                        // Corner indicators
                        _buildCornerIndicator(Alignment.topLeft, [
                          BorderSide(color: const Color(0xFF4CAF50), width: 4),
                          BorderSide(color: const Color(0xFF4CAF50), width: 4),
                        ], [true, false, false, true]), // top and left
                        _buildCornerIndicator(Alignment.topRight, [
                          BorderSide(color: const Color(0xFF4CAF50), width: 4),
                          BorderSide(color: const Color(0xFF4CAF50), width: 4),
                        ], [true, true, false, false]), // top and right
                        _buildCornerIndicator(Alignment.bottomLeft, [
                          BorderSide(color: const Color(0xFF4CAF50), width: 4),
                          BorderSide(color: const Color(0xFF4CAF50), width: 4),
                        ], [false, false, true, true]), // bottom and left
                        _buildCornerIndicator(Alignment.bottomRight, [
                          BorderSide(color: const Color(0xFF4CAF50), width: 4),
                          BorderSide(color: const Color(0xFF4CAF50), width: 4),
                        ], [false, true, true, false]), // bottom and right
                        
                        // Scanning line animation
                        Center(
                          child: Container(
                            width: 220,
                            height: 2,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.transparent,
                                  const Color(0xFF4CAF50),
                                  Colors.transparent,
                                ],
                                stops: [0.0, 0.5, 1.0],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Instructions
                Positioned(
                  bottom: 120,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'Đặt mã QR vào trong khung để quét',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ),
                // Flash button
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
      // Always return the scanned text, don't validate here
      // Let the device connection screen handle validation
      Navigator.of(context).pop(code);
    }
  }

  Widget _buildCornerIndicator(Alignment alignment, List<BorderSide> sides, List<bool> activeSides) {
    return Align(
      alignment: alignment,
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          border: Border(
            top: activeSides[0] ? sides[0] : BorderSide.none,
            right: activeSides[1] ? (sides.length > 1 ? sides[1] : sides[0]) : BorderSide.none,
            bottom: activeSides[2] ? (sides.length > 1 ? sides[1] : sides[0]) : BorderSide.none,
            left: activeSides[3] ? sides[0] : BorderSide.none,
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }
}
