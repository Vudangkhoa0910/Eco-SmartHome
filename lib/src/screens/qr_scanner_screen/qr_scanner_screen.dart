import 'dart:io';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:image_picker/image_picker.dart';
import 'package:smart_home/service/theme_service.dart';
import 'package:smart_home/config/size_config.dart';
import 'package:smart_home/src/widgets/custom_notification.dart';

class QRScannerScreen extends StatefulWidget {
  const QRScannerScreen({Key? key}) : super(key: key);

  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> with TickerProviderStateMixin {
  MobileScannerController controller = MobileScannerController();
  String? result;
  bool isScanning = true;
  bool flashOn = false;
  final ImagePicker _imagePicker = ImagePicker();
  
  late AnimationController _animationController;
  late AnimationController _pulseController;
  late Animation<double> _scanAnimation;
  late Animation<double> _pulseAnimation;
  
  @override
  void initState() {
    super.initState();
    
    // Scan line animation
    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _scanAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.repeat(reverse: true);

    // Pulse animation for corners
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _pulseController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _animationController.dispose();
    _pulseController.dispose();
    controller.dispose();
    super.dispose();
  }

  void _onQRViewCreated(BarcodeCapture capture) {
    if (!isScanning) return;
    
    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isNotEmpty) {
      final barcode = barcodes.first;
      if (barcode.rawValue != null) {
        setState(() {
          result = barcode.rawValue;
          isScanning = false;
        });
        _animationController.stop();
        _showResultDialog(barcode.rawValue!);
      }
    }
  }

  Future<void> _pickImageFromGallery() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 100,
      );
      
      if (image != null) {
        setState(() {
          isScanning = false;
        });
        
        // Process image for QR code
        await _processImageForQR(image.path);
      }
    } catch (e) {
      _showErrorDialog('Không thể chọn ảnh: $e');
    }
  }

  Future<void> _processImageForQR(String imagePath) async {
    try {
      // Show loading dialog
      _showLoadingDialog();
      
      // Analyze image with mobile_scanner
      final result = await controller.analyzeImage(imagePath);
      Navigator.of(context).pop(); // Close loading dialog
      
      if (result != null && result.barcodes.isNotEmpty) {
        final barcode = result.barcodes.first;
        if (barcode.rawValue != null) {
          _showResultDialog(barcode.rawValue!);
        } else {
          _showErrorDialog('Không tìm thấy mã QR trong ảnh');
        }
      } else {
        _showErrorDialog('Không tìm thấy mã QR trong ảnh');
      }
    } catch (e) {
      Navigator.of(context).pop(); // Close loading dialog
      _showErrorDialog('Lỗi khi xử lý ảnh: $e');
    }
  }

  void _toggleFlash() {
    setState(() {
      flashOn = !flashOn;
    });
    controller.toggleTorch();
  }

  void _showResultDialog(String qrData) {
    final theme = ThemeService.instance.currentPalette;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.qr_code_scanner,
                  color: theme.primaryColor,
                  size: 24,
                ),
              ),
              SizedBox(width: 12),
              Text(
                'Quét thành công!',
                style: TextStyle(
                  color: theme.primaryColor,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Mã QR đã được quét:',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: theme.primaryColor.withOpacity(0.3)),
                ),
                child: Text(
                  qrData,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
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
                  result = null;
                  isScanning = true;
                });
                _animationController.repeat(reverse: true);
              },
              child: Text(
                'Quét lại',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop(qrData);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text('Xác nhận'),
            ),
          ],
        );
      },
    );
  }

  void _showLoadingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          content: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(
                  ThemeService.instance.currentPalette.primaryColor,
                ),
              ),
              SizedBox(width: 16),
              Text(
                'Đang phân tích ảnh...',
                style: TextStyle(fontSize: 16),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = ThemeService.instance.currentPalette;
    final textColor = ThemeService.instance.getAdaptiveTextColor(theme.gradientColors.first);
    
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: theme.gradientColors,
          ),
        ),
        child: Stack(
          children: [
            // Main scanner view
            MobileScanner(
              controller: controller,
              onDetect: _onQRViewCreated,
            ),
            
            // Top overlay with gradient
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                height: 120,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withOpacity(0.7),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.of(context).pop(),
                          child: Container(
                            padding: EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                              backdropFilter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                            ),
                            child: Icon(
                              Icons.arrow_back_ios,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                        Text(
                          'Quét mã QR',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        GestureDetector(
                          onTap: _toggleFlash,
                          child: Container(
                            padding: EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: flashOn 
                                ? theme.primaryColor.withOpacity(0.3)
                                : Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                              backdropFilter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                            ),
                            child: Icon(
                              flashOn ? Icons.flash_on : Icons.flash_off,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            
            // Center scanning frame with animation
            Center(
              child: Container(
                width: 280,
                height: 280,
                child: Stack(
                  children: [
                    // Outer glow effect
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: theme.primaryColor.withOpacity(0.3),
                            blurRadius: 20,
                            spreadRadius: 10,
                          ),
                        ],
                      ),
                    ),
                    
                    // Main scanning frame
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: theme.primaryColor,
                          width: 3,
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(17),
                        child: Stack(
                          children: [
                            // Corner decorations
                            ...List.generate(4, (index) {
                              return Positioned(
                                top: index < 2 ? 8 : null,
                                bottom: index >= 2 ? 8 : null,
                                left: index % 2 == 0 ? 8 : null,
                                right: index % 2 == 1 ? 8 : null,
                                child: Container(
                                  width: 30,
                                  height: 30,
                                  decoration: BoxDecoration(
                                    color: theme.primaryColor,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                ),
                              );
                            }),
                            
                            // Animated scanning line
                            if (isScanning)
                              AnimatedBuilder(
                                animation: _animation,
                                builder: (context, child) {
                                  return Positioned(
                                    top: _animation.value * 240,
                                    left: 20,
                                    right: 20,
                                    child: Container(
                                      height: 3,
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            Colors.transparent,
                                            theme.primaryColor,
                                            Colors.transparent,
                                          ],
                                        ),
                                        borderRadius: BorderRadius.circular(2),
                                      ),
                                    ),
                                  );
                                },
                              ),
                          ],
                        ),
                      ),
                    ),
                    
                    // Pulse effect
                    AnimatedBuilder(
                      animation: _pulseAnimation,
                      builder: (context, child) {
                        return Container(
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: theme.primaryColor.withOpacity(
                                0.5 * (1 - _pulseAnimation.value),
                              ),
                              width: 2,
                            ),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          transform: Matrix4.identity()
                            ..scale(1 + _pulseAnimation.value * 0.1),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
            
            // Bottom overlay with controls
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                height: 160,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withOpacity(0.8),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: SafeArea(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Đưa mã QR vào khung để quét',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 20),
                      
                      // Gallery button
                      GestureDetector(
                        onTap: _pickImageFromGallery,
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: theme.primaryColor.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(25),
                            border: Border.all(
                              color: theme.primaryColor,
                              width: 2,
                            ),
                            backdropFilter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.photo_library,
                                color: Colors.white,
                                size: 20,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Chọn từ thư viện',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            
            // Result overlay
            if (result != null && !isScanning)
              Container(
                color: Colors.black.withOpacity(0.8),
                child: Center(
                  child: Container(
                    margin: EdgeInsets.all(32),
                    padding: EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 20,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.check_circle,
                          color: Colors.green,
                          size: 64,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Quét thành công!',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        SizedBox(height: 12),
                        Text(
                          result!,
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.black54,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 24),
                        Row(
                          children: [
                            Expanded(
                              child: TextButton(
                                onPressed: () {
                                  setState(() {
                                    result = null;
                                    isScanning = true;
                                  });
                                  _animationController.repeat(reverse: true);
                                },
                                child: Text('Quét lại'),
                              ),
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () {
                                  Navigator.of(context).pop(result);
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: theme.primaryColor,
                                  foregroundColor: Colors.white,
                                ),
                                child: Text('Xác nhận'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
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
        context.showInfoNotification('Chức năng phân tích QR từ hình ảnh đang được phát triển');
      }
    } catch (e) {
      print('Error picking image: $e');
      context.showErrorNotification('Lỗi khi chọn hình ảnh');
    }
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
        context.showErrorNotification('Mã QR không hợp lệ: $code');
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
