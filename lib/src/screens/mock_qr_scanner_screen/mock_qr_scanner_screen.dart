import 'package:flutter/material.dart';
import 'package:smart_home/config/size_config.dart';

class MockQRScannerScreen extends StatefulWidget {
  const MockQRScannerScreen({Key? key}) : super(key: key);

  @override
  State<MockQRScannerScreen> createState() => _MockQRScannerScreenState();
}

class _MockQRScannerScreenState extends State<MockQRScannerScreen>
    with TickerProviderStateMixin {
  late AnimationController _scanAnimationController;
  late Animation<double> _scanAnimation;
  bool isScanning = false;

  final List<String> mockQRCodes = [
    'smarthome99',
    'smarthome88',
    'smarthome66',
  ];

  @override
  void initState() {
    super.initState();
    _scanAnimationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _scanAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _scanAnimationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _scanAnimationController.dispose();
    super.dispose();
  }

  void _startScanning() {
    setState(() => isScanning = true);
    _scanAnimationController.repeat();

    // Simulate scanning process
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() => isScanning = false);
        _scanAnimationController.stop();
        _showScanResult();
      }
    });
  }

  void _showScanResult() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Chọn mã QR để test'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: mockQRCodes.map((code) {
              return ListTile(
                title: Text(code),
                subtitle: Text(_getCodeDescription(code)),
                onTap: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).pop(code);
                },
              );
            }).toList(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Hủy'),
            ),
          ],
        );
      },
    );
  }

  String _getCodeDescription(String code) {
    switch (code) {
      case 'smarthome99':
        return 'Gói Premium - Đầy đủ thiết bị';
      case 'smarthome88':
        return 'Gói Standard - Cần thêm thiết bị';
      case 'smarthome66':
        return 'Gói Basic - Cần thêm thiết bị';
      default:
        return 'Mã không xác định';
    }
  }

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
          'Quét mã QR thiết bị (Demo)',
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
                // Mock QR scanner view
                Container(
                  color: Colors.black87,
                  child: Center(
                    child: Container(
                      width: 280,
                      height: 280,
                      decoration: BoxDecoration(
                        border: Border.all(color: const Color(0xFF4CAF50), width: 3),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Stack(
                        children: [
                          // Corner decorations
                          ...List.generate(4, (index) {
                            final positions = [
                              const Alignment(-1, -1), // Top-left
                              const Alignment(1, -1),  // Top-right
                              const Alignment(-1, 1),  // Bottom-left
                              const Alignment(1, 1),   // Bottom-right
                            ];
                            return Align(
                              alignment: positions[index],
                              child: Container(
                                margin: const EdgeInsets.all(8),
                                width: 30,
                                height: 30,
                                decoration: BoxDecoration(
                                  border: Border(
                                    top: index < 2 ? BorderSide(color: const Color(0xFF4CAF50), width: 4) : BorderSide.none,
                                    bottom: index >= 2 ? BorderSide(color: const Color(0xFF4CAF50), width: 4) : BorderSide.none,
                                    left: index % 2 == 0 ? BorderSide(color: const Color(0xFF4CAF50), width: 4) : BorderSide.none,
                                    right: index % 2 == 1 ? BorderSide(color: const Color(0xFF4CAF50), width: 4) : BorderSide.none,
                                  ),
                                ),
                              ),
                            );
                          }),
                          // Scanning line animation
                          if (isScanning)
                            AnimatedBuilder(
                              animation: _scanAnimation,
                              builder: (context, child) {
                                return Positioned(
                                  top: _scanAnimation.value * 240 + 20,
                                  left: 20,
                                  right: 20,
                                  child: Container(
                                    height: 3,
                                    decoration: BoxDecoration(
                                      color: Colors.red,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.red.withOpacity(0.5),
                                          blurRadius: 8,
                                          spreadRadius: 2,
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
                // Instructions overlay
                Positioned(
                  top: 40,
                  left: 20,
                  right: 20,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Column(
                      children: [
                        Icon(
                          Icons.qr_code_scanner,
                          color: Colors.white,
                          size: 32,
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Demo QR Scanner',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Nhấn nút quét để xem danh sách mã demo',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
                // Bottom controls
                Positioned(
                  bottom: 40,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: ElevatedButton(
                      onPressed: isScanning ? null : _startScanning,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4CAF50),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                      ),
                      child: isScanning
                          ? const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                ),
                                SizedBox(width: 12),
                                Text('Đang quét...'),
                              ],
                            )
                          : const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.qr_code_scanner),
                                SizedBox(width: 8),
                                Text('Bắt đầu quét'),
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
}
