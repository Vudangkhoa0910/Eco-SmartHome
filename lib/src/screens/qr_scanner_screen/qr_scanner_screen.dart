import 'dart:io';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:image_picker/image_picker.dart';

class QRScannerScreen extends StatefulWidget {
  const QRScannerScreen({Key? key}) : super(key: key);

  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> with TickerProviderStateMixin {
  MobileScannerController controller = MobileScannerController();
  String? result;
  bool isScanning = true;
  final ImagePicker _imagePicker = ImagePicker();
  
  late AnimationController _animationController;
  late Animation<double> _animation;
  
  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.repeat(reverse: true);
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
                // Scanner overlay
                Container(
                  decoration: ShapeDecoration(
                    shape: QrScannerOverlayShape(
                      borderColor: const Color(0xFF4CAF50),
                      borderRadius: 20,
                      borderLength: 40,
                      borderWidth: 6,
                      cutOutSize: 280,
                    ),
                  ),
                ),
                
                // Animated scanning line
                AnimatedBuilder(
                  animation: _animation,
                  builder: (context, child) {
                    return Positioned(
                      left: MediaQuery.of(context).size.width / 2 - 140,
                      top: MediaQuery.of(context).size.height / 2 - 140 + (_animation.value * 280),
                      child: Container(
                        width: 280,
                        height: 2,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.transparent,
                              const Color(0xFF4CAF50).withOpacity(0.8),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    );
                  },
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
                          'Hướng camera về mã QR trên thiết bị',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Đảm bảo mã QR nằm trong khung quét',
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
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildControlButton(
                          icon: Icons.flash_on,
                          label: 'Đèn pin',
                          onTap: () async {
                            await controller.toggleTorch();
                          },
                        ),
                        _buildControlButton(
                          icon: Icons.photo_library,
                          label: 'Thư viện',
                          onTap: () async {
                            await _pickImageFromGallery();
                          },
                        ),
                        _buildControlButton(
                          icon: Icons.flip_camera_ios,
                          label: 'Đổi camera',
                          onTap: () async {
                            await controller.switchCamera();
                          },
                        ),
                      ],
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

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImageFromGallery() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxHeight: 1024,
        maxWidth: 1024,
      );

      if (image != null) {
        // Show loading dialog
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const AlertDialog(
            content: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(width: 16),
                Text('Đang phân tích hình ảnh...'),
              ],
            ),
          ),
        );

        // For now, we'll show a message that this feature is coming soon
        // In a real implementation, you'd use an image processing library
        // like google_ml_kit or similar to detect QR codes in the image
        await Future.delayed(const Duration(seconds: 1));
        
        Navigator.of(context).pop(); // Close loading dialog
        
        // Show info message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Chức năng phân tích QR từ hình ảnh đang được phát triển'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      print('Error picking image: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lỗi khi chọn hình ảnh'),
          backgroundColor: Colors.red,
        ),
      );
    }
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
        Navigator.of(context).pop(code); // Return the scanned key
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
    _animationController.dispose();
    controller.dispose();
    super.dispose();
  }
}

// Custom overlay shape for QR scanner
class QrScannerOverlayShape extends ShapeBorder {
  final Color borderColor;
  final double borderWidth;
  final Color overlayColor;
  final double borderRadius;
  final double borderLength;
  final double cutOutSize;

  const QrScannerOverlayShape({
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
    Path _getLeftTopPath(Rect rect) {
      return Path()
        ..moveTo(rect.left, rect.bottom)
        ..lineTo(rect.left, rect.top + borderRadius)
        ..quadraticBezierTo(
            rect.left, rect.top, rect.left + borderRadius, rect.top)
        ..lineTo(rect.right, rect.top);
    }

    return _getLeftTopPath(rect)
      ..lineTo(rect.right, rect.bottom)
      ..lineTo(rect.left, rect.bottom)
      ..lineTo(rect.left, rect.top);
  }

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    final width = rect.width;
    final borderWidthSize = width / 2;
    final height = rect.height;
    final borderOffset = borderWidth / 2;
    final _borderLength = borderLength > cutOutSize / 2 + borderWidth * 2
        ? borderWidthSize / 2
        : borderLength;
    final _cutOutSize = cutOutSize < width ? cutOutSize : width - borderOffset;

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

    final cutOutRect = Rect.fromLTWH(
      rect.left + width / 2 - _cutOutSize / 2 + borderOffset,
      rect.top + height / 2 - _cutOutSize / 2 + borderOffset,
      _cutOutSize - borderOffset * 2,
      _cutOutSize - borderOffset * 2,
    );

    canvas
      ..saveLayer(
        rect,
        backgroundPaint,
      )
      ..drawRect(rect, backgroundPaint)
      ..drawRRect(
        RRect.fromRectAndRadius(
          cutOutRect,
          Radius.circular(borderRadius),
        ),
        boxPaint,
      )
      ..restore();

    // Draw border corners
    final borderPath = Path()
      // Top left
      ..moveTo(cutOutRect.left - borderOffset, cutOutRect.top + _borderLength)
      ..lineTo(cutOutRect.left - borderOffset, cutOutRect.top + borderRadius)
      ..quadraticBezierTo(
          cutOutRect.left - borderOffset,
          cutOutRect.top - borderOffset,
          cutOutRect.left + borderRadius,
          cutOutRect.top - borderOffset)
      ..lineTo(cutOutRect.left + _borderLength, cutOutRect.top - borderOffset)
      // Top right
      ..moveTo(cutOutRect.right - _borderLength, cutOutRect.top - borderOffset)
      ..lineTo(cutOutRect.right - borderRadius, cutOutRect.top - borderOffset)
      ..quadraticBezierTo(
          cutOutRect.right + borderOffset,
          cutOutRect.top - borderOffset,
          cutOutRect.right + borderOffset,
          cutOutRect.top + borderRadius)
      ..lineTo(cutOutRect.right + borderOffset, cutOutRect.top + _borderLength)
      // Bottom right
      ..moveTo(
          cutOutRect.right + borderOffset, cutOutRect.bottom - _borderLength)
      ..lineTo(
          cutOutRect.right + borderOffset, cutOutRect.bottom - borderRadius)
      ..quadraticBezierTo(
          cutOutRect.right + borderOffset,
          cutOutRect.bottom + borderOffset,
          cutOutRect.right - borderRadius,
          cutOutRect.bottom + borderOffset)
      ..lineTo(
          cutOutRect.right - _borderLength, cutOutRect.bottom + borderOffset)
      // Bottom left
      ..moveTo(
          cutOutRect.left + _borderLength, cutOutRect.bottom + borderOffset)
      ..lineTo(cutOutRect.left + borderRadius, cutOutRect.bottom + borderOffset)
      ..quadraticBezierTo(
          cutOutRect.left - borderOffset,
          cutOutRect.bottom + borderOffset,
          cutOutRect.left - borderOffset,
          cutOutRect.bottom - borderRadius)
      ..lineTo(
          cutOutRect.left - borderOffset, cutOutRect.bottom - _borderLength);

    canvas.drawPath(borderPath, borderPaint);
  }

  @override
  ShapeBorder scale(double t) {
    return QrScannerOverlayShape(
      borderColor: borderColor,
      borderWidth: borderWidth,
      overlayColor: overlayColor,
    );
  }
}
