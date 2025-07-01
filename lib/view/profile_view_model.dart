import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smart_home/provider/base_model.dart';
import 'package:smart_home/provider/theme_provider.dart';

class ProfileViewModel extends BaseModel {
  String _userName = 'Vũ Đăng Khoa';
  String _userEmail = 'vudangkhoa@gmail.com';
  int _totalDevices = 15;
  int _totalRooms = 6;
  int _totalSavings = 2350; // in thousand VND
  bool _isVoiceEnabled = true;

  String get userName => _userName;
  String get userEmail => _userEmail;
  int get totalDevices => _totalDevices;
  int get totalRooms => _totalRooms;
  int get totalSavings => _totalSavings;
  bool get isVoiceEnabled => _isVoiceEnabled;

  bool isDarkMode(BuildContext context) {
    return Provider.of<ThemeProvider>(context, listen: false).isDarkMode;
  }

  void loadProfile() {
    // Load user profile data
    notifyListeners();
  }

  void editProfile(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Chỉnh sửa hồ sơ'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: const InputDecoration(
                labelText: 'Họ và tên',
                border: OutlineInputBorder(),
              ),
              controller: TextEditingController(text: _userName),
            ),
            const SizedBox(height: 15),
            TextField(
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
              controller: TextEditingController(text: _userEmail),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Save profile logic
            },
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
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
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const DeviceManagementScreen(),
      ),
    );
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
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const EnergySettingsScreen(),
      ),
    );
  }

  void toggleDarkMode(bool value, BuildContext context) {
    Provider.of<ThemeProvider>(context, listen: false).setTheme(value);
    notifyListeners();
  }

  void toggleVoice(bool value) {
    _isVoiceEnabled = value;
    notifyListeners();
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
        content: const Text('Liên hệ với chúng tôi qua email: support@smarthome.vn hoặc hotline: 1900-1234'),
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
            onPressed: () {
              Navigator.pop(context);
              // Navigate to login screen
              Navigator.pushNamedAndRemoveUntil(
                context,
                '/login-screen',
                (route) => false,
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Đăng xuất', style: TextStyle(color: Colors.white)),
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
