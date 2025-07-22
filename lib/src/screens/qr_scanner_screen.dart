import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:smart_home/core/permission_helper.dart';
import 'package:smart_home/src/widgets/custom_notification.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class QRScannerScreen extends StatefulWidget {
  const QRScannerScreen({Key? key}) : super(key: key);

  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> {
  MobileScannerController cameraController = MobileScannerController();
  bool isFlashOn = false;
  bool isScanning = true;
  String? scannedCode;

  @override
  void initState() {
    super.initState();
    _checkCameraPermission();
  }

  Future<void> _checkCameraPermission() async {
    final hasPermission = await PermissionHelper.requestCameraPermission();
    if (!hasPermission) {
      _showPermissionDialog();
    }
  }

  void _showPermissionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cần quyền Camera'),
        content: const Text('Ứng dụng cần quyền truy cập camera để quét mã QR.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await PermissionHelper.requestCameraPermission();
            },
            child: const Text('Cấp quyền'),
          ),
        ],
      ),
    );
  }

  Future<void> _pickImageFromGallery() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    
    if (image != null) {
      final result = await cameraController.analyzeImage(image.path);
      if (result != null && result.barcodes.isNotEmpty) {
        _onQRCodeDetected(result.barcodes.first.rawValue ?? '');
      } else {
        _showMessage('Không tìm thấy mã QR trong ảnh');
      }
    }
  }

  void _onQRCodeDetected(String code) {
    if (!isScanning) return;
    
    setState(() {
      isScanning = false;
      scannedCode = code;
    });
    
    _showResultDialog(code);
  }

  void _showResultDialog(String code) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Mã QR đã quét'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Nội dung:'),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                code,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              setState(() {
                isScanning = true;
                scannedCode = null;
              });
            },
            child: const Text('Quét lại'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop(code);
            },
            child: const Text('Sử dụng'),
          ),
        ],
      ),
    );
  }

  void _showMessage(String message) {
    context.showInfoNotification(message);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Quét mã QR', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            onPressed: () async {
              await cameraController.toggleTorch();
              setState(() {
                isFlashOn = !isFlashOn;
              });
            },
            icon: Icon(
              isFlashOn ? Icons.flash_on : Icons.flash_off,
              color: Colors.white,
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          // Camera Preview
          MobileScanner(
            controller: cameraController,
            onDetect: (capture) {
              final List<Barcode> barcodes = capture.barcodes;
              if (barcodes.isNotEmpty) {
                _onQRCodeDetected(barcodes.first.rawValue ?? '');
              }
            },
          ),
          
          // Overlay with QR frame
          Container(
            decoration: ShapeDecoration(
              shape: QRScannerOverlayShape(
                borderColor: Colors.white,
                borderRadius: 10,
                borderLength: 30,
                borderWidth: 5,
                cutOutSize: 250,
                overlayColor: Colors.black.withOpacity(0.5),
              ),
            ),
          ),
          
          // QR Corner Guides
          Center(
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.transparent),
              ),
              child: Stack(
                children: [
                  // Góc trên trái
                  Positioned(
                    top: 0,
                    left: 0,
                    child: _buildCornerIndicator(),
                  ),
                  // Góc trên phải
                  Positioned(
                    top: 0,
                    right: 0,
                    child: _buildCornerIndicator(isRotated: true),
                  ),
                  // Góc dưới trái
                  Positioned(
                    bottom: 0,
                    left: 0,
                    child: _buildCornerIndicator(isFlippedVertically: true),
                  ),
                  // Góc dưới phải
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: _buildCornerIndicator(isRotated: true, isFlippedVertically: true),
                  ),
                ],
              ),
            ),
          ),
          
          // Top instruction
          Positioned(
            top: 50,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.6),
                borderRadius: BorderRadius.circular(8),
              ),
              margin: const EdgeInsets.symmetric(horizontal: 40),
              child: const Text(
                'Đặt mã QR vào trong khung để quét',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          
          // Bottom controls
          Positioned(
            bottom: 80,
            left: 0,
            right: 0,
            child: Column(
              children: [
                // Scanning status indicator
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isScanning ? Colors.green : Colors.orange,
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isScanning ? Icons.qr_code_scanner : Icons.check_circle,
                        color: isScanning ? Colors.green : Colors.orange,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        isScanning ? 'Đang quét mã QR...' : 'Đã quét xong',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 20),
                
                // Action buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Gallery button
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(50),
                        border: Border.all(color: Colors.white30),
                      ),
                      child: Tooltip(
                        message: "Chọn ảnh từ thư viện",
                        child: IconButton(
                          onPressed: _pickImageFromGallery,
                          icon: const Icon(Icons.photo_library, color: Colors.white, size: 30),
                          iconSize: 30,
                        ),
                      ),
                    ),
                    // Switch camera button
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(50),
                      ),
                      child: IconButton(
                        onPressed: () => cameraController.switchCamera(),
                        icon: const Icon(Icons.camera_rear, color: Colors.white, size: 30),
                        iconSize: 50,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    cameraController.dispose();
    super.dispose();
  }

  Widget _buildCornerIndicator({bool isRotated = false, bool isFlippedVertically = false}) {
    return Transform.rotate(
      angle: isRotated ? 1.5708 : 0, // 90 degrees if rotated
      child: Transform.scale(
        scaleY: isFlippedVertically ? -1 : 1,
        child: Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            border: Border(
              top: const BorderSide(color: Colors.green, width: 3),
              left: const BorderSide(color: Colors.green, width: 3),
            ),
          ),
        ),
      ),
    );
  }
}

// Custom overlay shape for QR scanner
class QRScannerOverlayShape extends ShapeBorder {
  final Color borderColor;
  final double borderWidth;
  final Color overlayColor;
  final double borderRadius;
  final double borderLength;
  final double cutOutSize;

  const QRScannerOverlayShape({
    this.borderColor = Colors.red,
    this.borderWidth = 3.0,
    this.overlayColor = const Color.fromRGBO(0, 0, 0, 80),
    this.borderRadius = 0,
    this.borderLength = 40,
    this.cutOutSize = 250,
  });

  @override
  EdgeInsetsGeometry get dimensions => const EdgeInsets.all(10);

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) {
    return Path()
      ..fillType = PathFillType.evenOdd
      ..addPath(getOuterPath(rect), Offset.zero);
  }

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) {
    Path path = Path()..addRect(rect);
    Path oval = Path()
      ..addRRect(RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: rect.center,
          width: cutOutSize,
          height: cutOutSize,
        ),
        Radius.circular(borderRadius),
      ));
    return Path.combine(PathOperation.difference, path, oval);
  }

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    final width = rect.width;
    final borderWidthSize = width / 2;
    final height = rect.height;
    final borderOffset = borderWidth / 2;
    final borderRadius = this.borderRadius;
    final borderLength = this.borderLength;
    final cutOutWidth = cutOutSize;
    final cutOutHeight = cutOutSize;

    final cutOutRect = Rect.fromCenter(
      center: rect.center,
      width: cutOutWidth,
      height: cutOutHeight,
    );

    final cutOutRRect = RRect.fromRectAndRadius(
      cutOutRect,
      Radius.circular(borderRadius),
    );

    final backgroundPaint = Paint()
      ..color = overlayColor
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth;

    final boxPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.fill
      ..blendMode = BlendMode.dstOut;

    // Draw overlay
    canvas.drawPath(
      Path.combine(
        PathOperation.difference,
        Path()..addRect(rect),
        Path()..addRRect(cutOutRRect),
      ),
      backgroundPaint,
    );

    // Draw border corners
    canvas.drawPath(
      Path()
        ..moveTo(cutOutRect.left, cutOutRect.top + borderLength)
        ..lineTo(cutOutRect.left, cutOutRect.top)
        ..lineTo(cutOutRect.left + borderLength, cutOutRect.top),
      borderPaint,
    );

    canvas.drawPath(
      Path()
        ..moveTo(cutOutRect.right - borderLength, cutOutRect.top)
        ..lineTo(cutOutRect.right, cutOutRect.top)
        ..lineTo(cutOutRect.right, cutOutRect.top + borderLength),
      borderPaint,
    );

    canvas.drawPath(
      Path()
        ..moveTo(cutOutRect.right, cutOutRect.bottom - borderLength)
        ..lineTo(cutOutRect.right, cutOutRect.bottom)
        ..lineTo(cutOutRect.right - borderLength, cutOutRect.bottom),
      borderPaint,
    );

    canvas.drawPath(
      Path()
        ..moveTo(cutOutRect.left + borderLength, cutOutRect.bottom)
        ..lineTo(cutOutRect.left, cutOutRect.bottom)
        ..lineTo(cutOutRect.left, cutOutRect.bottom - borderLength),
      borderPaint,
    );
  }

  @override
  ShapeBorder scale(double t) {
    return QRScannerOverlayShape(
      borderColor: borderColor,
      borderWidth: borderWidth,
      overlayColor: overlayColor,
    );
  }
}
