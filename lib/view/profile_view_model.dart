import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smart_home/provider/base_model.dart';
import 'package:smart_home/provider/theme_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProfileViewModel extends BaseModel {
  String _userName = 'Đang tải...';
  String _userEmail = 'Đang tải...';
  int _totalDevices = 0;
  int _totalRooms = 0;
  int _totalSavings = 0; // in thousand VND
  bool _isVoiceEnabled = true;

  String get userName => _userName;
  String get userEmail => _userEmail;
  int get totalDevices => _totalDevices;
  int get totalRooms => _totalRooms;
  int get totalSavings => _totalSavings;
  bool get isVoiceEnabled => _isVoiceEnabled;

  // Constructor
  ProfileViewModel() {
    loadProfile();
  }

  bool isDarkMode(BuildContext context) {
    return Provider.of<ThemeProvider>(context, listen: false).isDarkMode;
  }

  void loadProfile() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // Load user basic info
        _userEmail = user.email ?? 'Không có email';

        // Load user document from Firestore
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (userDoc.exists) {
          final userData = userDoc.data() as Map<String, dynamic>;
          _userName = userData['displayName'] ??
              user.displayName ??
              userData['name'] ??
              'Người dùng';

          // Load statistics if available
          _totalDevices = userData['totalDevices'] ?? 0;
          _totalRooms = userData['totalRooms'] ?? 0;
          _totalSavings = userData['totalSavings'] ?? 0;
          _isVoiceEnabled = userData['isVoiceEnabled'] ?? true;
        } else {
          // If no document exists, use Firebase Auth data
          _userName = user.displayName ?? 'Người dùng';
          // Set default values for stats
          _totalDevices = 0;
          _totalRooms = 0;
          _totalSavings = 0;
        }
      } else {
        // No user logged in
        _userName = 'Chưa đăng nhập';
        _userEmail = '';
        _totalDevices = 0;
        _totalRooms = 0;
        _totalSavings = 0;
      }
    } catch (e) {
      print('Error loading profile: $e');
      // Keep default values if error occurs
      _userName = 'Lỗi tải dữ liệu';
      _userEmail = 'Lỗi tải dữ liệu';
    }

    notifyListeners();
  }

  void editProfile(BuildContext context) {
    // Navigate to the dedicated edit profile screen
    Navigator.pushNamed(context, '/edit-profile');
  }

  void openSecurity(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const SecuritySettingsScreen(),
      ),
    );
  }

  void openNotifications(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const NotificationSettingsScreen(),
      ),
    );
  }

  void openDeviceManagement(BuildContext context) {
    Navigator.pushNamed(context, '/rooms-screen');
  }

  void openAutomation(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AutomationScreen(),
      ),
    );
  }

  void openEnergySettings(BuildContext context) {
    Navigator.pushNamed(context, '/analytics-screen');
  }

  void toggleDarkMode(bool value, BuildContext context) {
    Provider.of<ThemeProvider>(context, listen: false).setTheme(value);
    notifyListeners();
  }

  void toggleVoice(bool value) async {
    _isVoiceEnabled = value;
    notifyListeners();

    // Save to Firebase
    await _saveUserData();
  }

  // Method to save user data to Firebase
  Future<void> _saveUserData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'displayName': _userName,
          'email': _userEmail,
          'totalDevices': _totalDevices,
          'totalRooms': _totalRooms,
          'totalSavings': _totalSavings,
          'isVoiceEnabled': _isVoiceEnabled,
          'lastUpdated': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
    } catch (e) {
      print('Error saving user data: $e');
    }
  }

  // Method to update statistics
  void updateStats({int? devices, int? rooms, int? savings}) async {
    if (devices != null) _totalDevices = devices;
    if (rooms != null) _totalRooms = rooms;
    if (savings != null) _totalSavings = savings;

    notifyListeners();
    await _saveUserData();
  }

  // Method to reload profile data
  void reloadProfile() {
    loadProfile();
  }

  void changeLanguage(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Chọn ngôn ngữ',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            ListTile(
              title: const Text('Tiếng Việt'),
              trailing: const Icon(Icons.check, color: Colors.green),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              title: const Text('English (US)'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              title: const Text('中文'),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }

  void openSupport(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hỗ trợ'),
        content: const Text(
            'Liên hệ với chúng tôi qua email: support@smarthome.vn hoặc hotline: 1900-1234'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  void openAbout(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Giới thiệu'),
        content: const SingleChildScrollView(
          child: Text(
            'Smart Home App v1.0.0\n\nỨng dụng quản lý nhà thông minh được phát triển bởi team Flutter Vietnam.\n\nTính năng chính:\n- Điều khiển thiết bị từ xa\n- Tự động hóa thông minh\n- Tiết kiệm năng lượng\n- Bảo mật cao\n\n© 2025 Smart Home Vietnam',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  void openPrivacy(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Chính sách bảo mật'),
        content: const SingleChildScrollView(
          child: Text(
            'Chúng tôi cam kết bảo vệ quyền riêng tư của bạn. Ứng dụng này thu thập và sử dụng dữ liệu để cung cấp dịch vụ nhà thông minh tốt nhất.\n\nDữ liệu được thu thập:\n- Thông tin thiết bị\n- Lịch sử sử dụng\n- Cài đặt cá nhân\n\nDữ liệu của bạn được mã hóa và bảo mật tuyệt đối.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  void logout(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Đăng xuất'),
        content: const Text('Bạn có chắc chắn muốn đăng xuất không?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);

              try {
                // Sign out from Firebase
                await FirebaseAuth.instance.signOut();

                // Navigate to auth screen
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/auth-screen',
                  (route) => false,
                );
              } catch (e) {
                print('Error signing out: $e');
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Lỗi đăng xuất: ${e.toString()}'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child:
                const Text('Đăng xuất', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

// Placeholder screens for navigation
class SecuritySettingsScreen extends StatelessWidget {
  const SecuritySettingsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Bảo mật & Quyền riêng tư')),
      body: const Center(child: Text('Cài đặt bảo mật - Sắp ra mắt')),
    );
  }
}

class NotificationSettingsScreen extends StatelessWidget {
  const NotificationSettingsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Thông báo')),
      body: const Center(child: Text('Cài đặt thông báo - Sắp ra mắt')),
    );
  }
}

class DeviceManagementScreen extends StatelessWidget {
  const DeviceManagementScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Quản lý thiết bị')),
      body: const Center(child: Text('Quản lý thiết bị - Sắp ra mắt')),
    );
  }
}

class AutomationScreen extends StatelessWidget {
  const AutomationScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Quy tắc tự động')),
      body: const Center(child: Text('Tự động hóa - Sắp ra mắt')),
    );
  }
}

class EnergySettingsScreen extends StatelessWidget {
  const EnergySettingsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cài đặt năng lượng')),
      body: const Center(child: Text('Cài đặt năng lượng - Sắp ra mắt')),
    );
  }
}

class SupportScreen extends StatelessWidget {
  const SupportScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Trợ giúp & Hỗ trợ')),
      body: const Center(child: Text('Trợ giúp & Hỗ trợ - Sắp ra mắt')),
    );
  }
}

class AboutScreen extends StatelessWidget {
  const AboutScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Về Smart Home')),
      body: const Center(child: Text('Thông tin ứng dụng - Sắp ra mắt')),
    );
  }
}

class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Chính sách bảo mật')),
      body: const Center(child: Text('Chính sách bảo mật - Sắp ra mắt')),
    );
  }
}
