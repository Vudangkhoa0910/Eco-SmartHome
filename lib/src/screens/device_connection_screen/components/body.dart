import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:smart_home/config/size_config.dart';
import 'package:smart_home/src/screens/home_screen/home_screen.dart';
import 'package:smart_home/src/screens/mock_qr_scanner_screen/mock_qr_scanner_screen.dart';
import 'package:smart_home/src/widgets/custom_notification.dart';

class Body extends StatefulWidget {
  const Body({Key? key}) : super(key: key);

  @override
  State<Body> createState() => _BodyState();
}

class _BodyState extends State<Body> with TickerProviderStateMixin {
  final TextEditingController deviceCodeController = TextEditingController();
  late AnimationController _fadeAnimationController;
  late Animation<double> _fadeAnimation;
  bool isConnecting = false;
  String _userName = 'Người dùng';
  List<Map<String, dynamic>> _savedDevices = []; // List of saved devices for this user
  bool _isLoadingDevices = true;

  // Valid device codes with their configurations
  final Map<String, Map<String, dynamic>> validDeviceCodes = {
    'smarthome99': {
      'name': 'Smart Home',
      'hasFullDevices': true,
      'description': 'Gói đầy đủ với tất cả thiết bị'
    },
    'smarthome88': {
      'name': 'Smart Home Standard',
      'hasFullDevices': false,
      'description': 'Gói cơ bản cần thêm thiết bị'
    },
    'smarthome66': {
      'name': 'Smart Home Basic',
      'hasFullDevices': false,
      'description': 'Gói khởi đầu cần thêm thiết bị'
    },
  };

  @override
  void initState() {
    super.initState();
    _fadeAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
          parent: _fadeAnimationController, curve: Curves.easeInOut),
    );

    _fadeAnimationController.forward();
    _loadUserData();
    _loadSavedDevices();
  }

  /// Load user data from Firebase
  Future<void> _loadUserData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // Load user document from Firestore
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (userDoc.exists) {
          final userData = userDoc.data() as Map<String, dynamic>;
          setState(() {
            _userName = userData['displayName'] ??
                user.displayName ??
                userData['name'] ??
                user.email?.split('@')[0] ??
                'Người dùng';
          });
        } else {
          setState(() {
            _userName =
                user.displayName ?? user.email?.split('@')[0] ?? 'Người dùng';
          });
        }
      }
    } catch (e) {
      // Handle error silently in production
      // Keep default if error occurs
    }
  }

  /// Load saved devices from Firebase
  Future<void> _loadSavedDevices() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final devicesSnapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('scanned_devices')
            .orderBy('scannedAt', descending: true)
            .get();

        setState(() {
          _savedDevices = devicesSnapshot.docs.map((doc) {
            final data = doc.data();
            return {
              'id': doc.id,
              'deviceCode': data['deviceCode'],
              'deviceName': data['deviceName'],
              'scannedAt': data['scannedAt'],
              'lastUsed': data['lastUsed'],
            };
          }).toList();
          _isLoadingDevices = false;
        });
      }
    } catch (e) {
      // Handle error silently in production
      setState(() {
        _isLoadingDevices = false;
      });
    }
  }

  /// Save scanned device to Firebase
  Future<void> _saveDeviceToFirebase(String deviceCode) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final deviceInfo = validDeviceCodes[deviceCode.toLowerCase()] ?? {
          'name': 'Smart Home Device',
          'hasFullDevices': false,
          'description': 'Thiết bị nhà thông minh'
        };

        // Check if device already exists
        final existingDevice = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('scanned_devices')
            .where('deviceCode', isEqualTo: deviceCode)
            .get();

        if (existingDevice.docs.isNotEmpty) {
          // Update last used time
          await existingDevice.docs.first.reference.update({
            'lastUsed': FieldValue.serverTimestamp(),
          });
        } else {
          // Add new device
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .collection('scanned_devices')
              .add({
            'deviceCode': deviceCode,
            'deviceName': deviceInfo['name'],
            'scannedAt': FieldValue.serverTimestamp(),
            'lastUsed': FieldValue.serverTimestamp(),
          });
        }

        // Reload saved devices
        await _loadSavedDevices();
      }
    } catch (e) {
      // Handle error silently in production
    }
  }

  /// Delete saved device from Firebase
  Future<void> _deleteDeviceFromFirebase(String deviceId) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('scanned_devices')
            .doc(deviceId)
            .delete();

        // Reload saved devices
        await _loadSavedDevices();
      }
    } catch (e) {
      // Handle error silently in production
    }
  }

  @override
  void dispose() {
    _fadeAnimationController.dispose();
    deviceCodeController.dispose();
    super.dispose();
  }

  void _startScanning() async {
    if (!mounted) return;
    
    try {
      final result = await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => const MockQRScannerScreen(),
        ),
      );

      if (result != null && mounted) {
        // Automatically fill the device code input field
        setState(() {
          deviceCodeController.text = result.toString();
        });

        // Save device to Firebase
        await _saveDeviceToFirebase(result.toString());

        // Show success message
        if (mounted) {
          context.showSuccessNotification('Đã quét thành công mã thiết bị: $result');
        }
        
        // Optionally auto-connect after a short delay
        if (mounted) {
          Future.delayed(const Duration(milliseconds: 500), () {
            if (mounted) {
              _connectToDevice();
            }
          });
        }
      }
    } catch (e) {
      if (mounted) {
        _showMessage('Lỗi khi quét QR: $e');
      }
    }
  }

  /// Select an existing saved device
  void _selectSavedDevice(Map<String, dynamic> device) async {
    if (!mounted) return;
    
    // Show immediate feedback
    if (mounted) {
      context.showInfoNotification('Đã chọn thiết bị: ${device['deviceName']}');
    }
    
    if (mounted) {
      setState(() {
        deviceCodeController.text = device['deviceCode'];
      });
    }

    // Update last used time in background (non-blocking)
    _saveDeviceToFirebase(device['deviceCode']).catchError((e) {
      // Handle error silently in production
    });
    
    // Auto-connect immediately without delay
    if (mounted) {
      _connectToDevice();
    }
  }

  /// Show delete device confirmation dialog
  void _showDeleteDeviceDialog(Map<String, dynamic> device) {
    if (!mounted) return;
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Xóa thiết bị'),
          content: Text('Bạn có chắc muốn xóa thiết bị "${device['deviceName']}" khỏi danh sách đã lưu?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Hủy'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await _deleteDeviceFromFirebase(device['id']);
                
                // Check if widget is still mounted before showing notification
                if (mounted) {
                  context.showWarningNotification('Đã xóa thiết bị "${device['deviceName']}"');
                }
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: Text('Xóa'),
            ),
          ],
        );
      },
    );
  }

  /// Show all saved devices dialog
  void _showAllDevicesDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Tất cả thiết bị đã lưu'),
          content: Container(
            width: double.maxFinite,
            constraints: BoxConstraints(maxHeight: 400),
            child: ListView.builder(
              itemCount: _savedDevices.length,
              itemBuilder: (context, index) {
                final device = _savedDevices[index];
                return Container(
                  margin: EdgeInsets.only(bottom: 8),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        Navigator.of(context).pop();
                        _selectSavedDevice(device);
                      },
                      borderRadius: BorderRadius.circular(8),
                      splashColor: Colors.blue.withOpacity(0.1),
                      highlightColor: Colors.blue.withOpacity(0.05),
                      child: Container(
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey[200]!),
                        ),
                        child: Row(
                          children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: Colors.blue[100],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(Icons.devices, color: Colors.blue[600], size: 20),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  device['deviceName'] ?? 'Smart Home Device',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                                Text(
                                  'Mã: ${device['deviceCode']}',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 12,
                                  ),
                                ),
                                if (device['lastUsed'] != null) ...[
                                  Text(
                                    'Sử dụng lần cuối: ${_formatDate(device['lastUsed'])}',
                                    style: TextStyle(
                                      color: Colors.grey[500],
                                      fontSize: 10,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                onPressed: () {
                                  Navigator.of(context).pop(); // Close dialog first
                                  _showDeleteDeviceDialog(device);
                                },
                                icon: Icon(Icons.delete_outline, color: Colors.red[400], size: 18),
                                constraints: BoxConstraints(
                                  minWidth: 32,
                                  minHeight: 32,
                                ),
                                padding: EdgeInsets.all(4),
                              ),
                              Icon(Icons.arrow_forward_ios, color: Colors.grey[400], size: 16),
                            ],
                          ),
                        ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Đóng'),
            ),
          ],
        );
      },
    );
  }

  /// Format date for display
  String _formatDate(dynamic timestamp) {
    if (timestamp == null) return 'Không xác định';
    
    try {
      DateTime date;
      if (timestamp is Timestamp) {
        date = timestamp.toDate();
      } else {
        return 'Không xác định';
      }
      
      final now = DateTime.now();
      final difference = now.difference(date);
      
      if (difference.inDays == 0) {
        return 'Hôm nay';
      } else if (difference.inDays == 1) {
        return 'Hôm qua';
      } else if (difference.inDays < 7) {
        return '${difference.inDays} ngày trước';
      } else {
        return '${date.day}/${date.month}/${date.year}';
      }
    } catch (e) {
      return 'Không xác định';
    }
  }

  void _connectToDevice() async {
    setState(() => isConnecting = true);

    // Simulate connection process
    await Future.delayed(const Duration(seconds: 2));

    if (mounted) {
      setState(() => isConnecting = false);
      // Pass default deviceInfo (e.g., smarthome99)
      final deviceInfo = validDeviceCodes['smarthome99']!;
      _showSuccessDialog(deviceInfo);
    }
  }

  void _connectWithCode() async {
    final code = deviceCodeController.text.trim().toLowerCase();

    if (code.isEmpty) {
      _showMessage('Vui lòng nhập mã thiết bị');
      return;
    }

    if (code.length < 8) {
      _showMessage('Mã thiết bị phải có ít nhất 8 ký tự');
      return;
    }

    setState(() => isConnecting = true);

    try {
      // Simulate connection process with validation
      await Future.delayed(const Duration(seconds: 2));

      // Check if code is valid
      if (!validDeviceCodes.containsKey(code)) {
        throw Exception('Mã thiết bị không hợp lệ');
      }

      if (mounted) {
        setState(() => isConnecting = false);
        final deviceInfo = validDeviceCodes[code]!;
        _showSuccessDialog(deviceInfo);
      }
    } catch (e) {
      if (mounted) {
        setState(() => isConnecting = false);
        _showMessage(
            'Kết nối thất bại: ${e.toString().replaceAll('Exception: ', '')}');
      }
    }
  }

  void _showSuccessDialog(Map<String, dynamic> deviceInfo) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(40),
                ),
                child: const Icon(
                  Icons.check_circle,
                  color: Colors.green,
                  size: 50,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Kết nối thành công!',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                deviceInfo['name'],
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF464646),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                deviceInfo['description'],
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    // Store device configuration for later use
                    _navigateToHome(deviceInfo);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF464646),
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Tiếp tục'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _navigateToHome(Map<String, dynamic> deviceInfo) {
    // You can pass device info to home screen if needed
    Navigator.of(context).pushReplacementNamed(
      HomeScreen.routeName,
      arguments: deviceInfo,
    );
  }

  void _skipConnection() {
    // Mặc định sử dụng gói Premium cho dev
    final deviceInfo = validDeviceCodes['smarthome99']!;
    Navigator.of(context).pushReplacementNamed(
      HomeScreen.routeName,
      arguments: deviceInfo,
    );
  }

  void _showMessage(String message) {
    if (mounted) {
      context.showInfoNotification(message);
    }
  }

  void _logout() async {
    await FirebaseAuth.instance.signOut();
    Navigator.of(context).pushReplacementNamed('/auth-screen');
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF2E3440),
            Color(0xFF3B4252),
            Color(0xFF434C5E),
          ],
        ),
      ),
      child: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Column(
            children: [
              // Header
              Padding(
                padding: EdgeInsets.all(getProportionateScreenWidth(20)),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Xin chào,',
                          style:
                              Theme.of(context).textTheme.bodyLarge!.copyWith(
                                    color: Colors.white.withOpacity(0.8),
                                  ),
                        ),
                        Text(
                          _userName,
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall!
                              .copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ],
                    ),
                    IconButton(
                      onPressed: _logout,
                      icon: const Icon(Icons.logout, color: Colors.white),
                    ),
                  ],
                ),
              ),

              // Main content
              Expanded(
                child: Container(
                  margin:
                      EdgeInsets.only(top: getProportionateScreenHeight(20)),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                  ),
                  child: SingleChildScrollView(
                    padding: EdgeInsets.all(getProportionateScreenWidth(20)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        SizedBox(height: getProportionateScreenHeight(15)), // Reduced from 30

                        // Title
                        Text(
                          'Kết nối thiết bị',
                          style: Theme.of(context)
                              .textTheme
                              .headlineMedium!
                              .copyWith(
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF2E3440),
                              ),
                        ),
                        SizedBox(height: getProportionateScreenHeight(5)), // Reduced from 8
                        Text(
                          'Chọn thiết bị đã lưu hoặc quét thiết bị mới',
                          style:
                              Theme.of(context).textTheme.bodyMedium!.copyWith(
                                    color: Colors.grey[600],
                                  ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: getProportionateScreenHeight(20)), // Reduced from 40

                        // Saved Devices Section
                        if (!_isLoadingDevices && _savedDevices.isNotEmpty) ...[
                          Container(
                            width: double.infinity,
                            padding: EdgeInsets.all(16),
                            margin: EdgeInsets.only(bottom: getProportionateScreenHeight(20)),
                            decoration: BoxDecoration(
                              color: Colors.blue[50],
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.blue[200]!),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.history, color: Colors.blue[600], size: 20),
                                    SizedBox(width: 8),
                                    Text(
                                      'Thiết bị đã lưu (${_savedDevices.length})',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: Colors.blue[700],
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 12),
                                Container(
                                  constraints: BoxConstraints(maxHeight: 120),
                                  child: ListView.builder(
                                    shrinkWrap: true,
                                    itemCount: _savedDevices.length > 3 ? 3 : _savedDevices.length,
                                    itemBuilder: (context, index) {
                                      final device = _savedDevices[index];
                                      return Container(
                                        margin: EdgeInsets.only(bottom: 8),
                                        child: Material(
                                          color: Colors.transparent,
                                          child: InkWell(
                                            onTap: () => _selectSavedDevice(device),
                                            borderRadius: BorderRadius.circular(8),
                                            splashColor: Colors.blue.withOpacity(0.1),
                                            highlightColor: Colors.blue.withOpacity(0.05),
                                            child: Container(
                                              padding: EdgeInsets.all(12),
                                              decoration: BoxDecoration(
                                                color: Colors.white,
                                                borderRadius: BorderRadius.circular(8),
                                                border: Border.all(color: Colors.blue[100]!),
                                              ),
                                              child: Row(
                                                children: [
                                                  Container(
                                                    width: 40,
                                                    height: 40,
                                                    decoration: BoxDecoration(
                                                      color: Colors.blue[100],
                                                      borderRadius: BorderRadius.circular(8),
                                                    ),
                                                    child: Icon(Icons.devices, color: Colors.blue[600], size: 20),
                                                  ),
                                                  SizedBox(width: 12),
                                                  Expanded(
                                                    child: Column(
                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                      children: [
                                                        Text(
                                                          device['deviceName'] ?? 'Smart Home Device',
                                                          style: TextStyle(
                                                            fontWeight: FontWeight.w600,
                                                            fontSize: 14,
                                                          ),
                                                        ),
                                                        Text(
                                                          'Mã: ${device['deviceCode']}',
                                                          style: TextStyle(
                                                            color: Colors.grey[600],
                                                            fontSize: 12,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                  Row(
                                                    mainAxisSize: MainAxisSize.min,
                                                    children: [
                                                      IconButton(
                                                        onPressed: () => _showDeleteDeviceDialog(device),
                                                        icon: Icon(Icons.delete_outline, color: Colors.red[400], size: 18),
                                                        constraints: BoxConstraints(
                                                          minWidth: 32,
                                                          minHeight: 32,
                                                        ),
                                                        padding: EdgeInsets.all(4),
                                                      ),
                                                      Icon(Icons.arrow_forward_ios, color: Colors.blue[400], size: 16),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                if (_savedDevices.length > 3) ...[
                                  Center(
                                    child: TextButton(
                                      onPressed: () {
                                        // Show all devices dialog
                                        _showAllDevicesDialog();
                                      },
                                      child: Text(
                                        'Xem tất cả ${_savedDevices.length} thiết bị',
                                        style: TextStyle(color: Colors.blue[600]),
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],

                        // QR Scanner section
                        GestureDetector(
                          onTap: _startScanning,
                          child: Container(
                            width: 200,
                            height: 200,
                            decoration: BoxDecoration(
                              border:
                                  Border.all(color: Colors.grey[300]!, width: 2),
                              borderRadius: BorderRadius.circular(16),
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Colors.grey[50]!,
                                  Colors.grey[100]!,
                                ],
                              ),
                            ),
                          child: Stack(
                            children: [
                              Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.qr_code_scanner,
                                      size: 60,
                                      color: Colors.grey[400],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Quét QR Code',
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // Corner decorations
                              Positioned(
                                top: 10,
                                left: 10,
                                child: Container(
                                  width: 20,
                                  height: 20,
                                  decoration: BoxDecoration(
                                    border: Border(
                                      top: BorderSide(
                                          color: const Color(0xFF464646),
                                          width: 3),
                                      left: BorderSide(
                                          color: const Color(0xFF464646),
                                          width: 3),
                                    ),
                                  ),
                                ),
                              ),
                              Positioned(
                                top: 10,
                                right: 10,
                                child: Container(
                                  width: 20,
                                  height: 20,
                                  decoration: BoxDecoration(
                                    border: Border(
                                      top: BorderSide(
                                          color: const Color(0xFF464646),
                                          width: 3),
                                      right: BorderSide(
                                          color: const Color(0xFF464646),
                                          width: 3),
                                    ),
                                  ),
                                ),
                              ),
                              Positioned(
                                bottom: 10,
                                left: 10,
                                child: Container(
                                  width: 20,
                                  height: 20,
                                  decoration: BoxDecoration(
                                    border: Border(
                                      bottom: BorderSide(
                                          color: const Color(0xFF464646),
                                          width: 3),
                                      left: BorderSide(
                                          color: const Color(0xFF464646),
                                          width: 3),
                                    ),
                                  ),
                                ),
                              ),
                              Positioned(
                                bottom: 10,
                                right: 10,
                                child: Container(
                                  width: 20,
                                  height: 20,
                                  decoration: BoxDecoration(
                                    border: Border(
                                      bottom: BorderSide(
                                          color: const Color(0xFF464646),
                                          width: 3),
                                      right: BorderSide(
                                          color: const Color(0xFF464646),
                                          width: 3),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ), // End of Container
                      ), // End of GestureDetector
                        SizedBox(height: getProportionateScreenHeight(20)),

                        // Scan button
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: isConnecting ? null : _startScanning,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF464646),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.qr_code_scanner),
                                SizedBox(width: 8),
                                Text('Quét mã QR'),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(height: getProportionateScreenHeight(30)),

                        // Divider
                        Row(
                          children: [
                            Expanded(child: Divider(color: Colors.grey[300])),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              child: Text(
                                'HOẶC',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            Expanded(child: Divider(color: Colors.grey[300])),
                          ],
                        ),
                        SizedBox(height: getProportionateScreenHeight(30)),

                        // Manual code input
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.grey[200]!),
                          ),
                          child: TextField(
                            controller: deviceCodeController,
                            decoration: InputDecoration(
                              hintText: 'Nhập mã thiết bị (vd: smarthome99)',
                              hintStyle: TextStyle(color: Colors.grey[500]),
                              prefixIcon:
                                  Icon(Icons.devices, color: Colors.grey[600]),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 16),
                            ),
                          ),
                        ),
                        SizedBox(height: getProportionateScreenHeight(8)),

                        // Instructions
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.blue[200]!),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Hãy nhập mã in trên thân của thiết bị để kết nối.',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium!
                                .copyWith(
                                  color: Colors.blue[800],
                                  fontWeight: FontWeight.w500,
                                ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        SizedBox(height: getProportionateScreenHeight(16)),

                        // Connect button
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: isConnecting ? null : _connectWithCode,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: const Color(0xFF464646),
                              side: const BorderSide(color: Color(0xFF464646)),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: isConnecting
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text('Kết nối với mã'),
                          ),
                        ),

                        SizedBox(height: getProportionateScreenHeight(30)),

                        // Development shortcuts
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.orange[50],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.orange[200]!),
                          ),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.developer_mode,
                                      color: Colors.orange[700], size: 20),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Dành cho phát triển',
                                    style: TextStyle(
                                      color: Colors.orange[800],
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: ElevatedButton(
                                      onPressed: _skipConnection,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.orange[100],
                                        foregroundColor: Colors.orange[800],
                                        elevation: 0,
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 8),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                      ),
                                      child: const Text(
                                        'Vào với gói Premium',
                                        style: TextStyle(fontSize: 12),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: ElevatedButton(
                                      onPressed: () {
                                        final deviceInfo =
                                            validDeviceCodes['smarthome66']!;
                                        _navigateToHome(deviceInfo);
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.orange[100],
                                        foregroundColor: Colors.orange[800],
                                        elevation: 0,
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 8),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                      ),
                                      child: const Text(
                                        'Vào với gói Basic',
                                        style: TextStyle(fontSize: 12),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        SizedBox(height: getProportionateScreenHeight(20)),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
