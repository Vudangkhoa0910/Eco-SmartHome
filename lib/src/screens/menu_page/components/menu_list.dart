import 'package:smart_home/src/screens/menu_page/components/list_tile.dart';
import 'package:smart_home/src/screens/stats_screen/stats_screen.dart';
import 'package:smart_home/src/screens/savings_screen/savings_screen.dart';
import 'package:smart_home/src/screens/ai_voice_screen/ai_voice_screen.dart';
import 'package:smart_home/src/screens/device_connection_screen/device_connection_screen.dart';
import 'package:flutter/material.dart';
import 'package:smart_home/config/size_config.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MenuList extends StatelessWidget {
  const MenuList({Key? key}) : super(key: key);

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Đăng xuất'),
          content: const Text('Bạn có chắc chắn muốn đăng xuất không?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: () async {
                await FirebaseAuth.instance.signOut();
                Navigator.of(context).pushNamedAndRemoveUntil(
                  '/auth-screen',
                  (route) => false,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Đăng xuất'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Điều khiển giọng nói AI
        MenuListItems(
          iconPath: 'assets/icons/menu_icons/notifications.svg',
          itemName: 'Điều khiển giọng nói',
          function: () => Navigator.of(context).pushNamed(
            AIVoiceScreen.routeName,
          ),
        ),
        SizedBox(height: getProportionateScreenHeight(8)),
        // Quản lý thiết bị
        MenuListItems(
          iconPath: 'assets/icons/menu_icons/devices.svg',
          itemName: 'Quản lý thiết bị',
          function: () => Navigator.of(context).pushNamed(
            DeviceConnectionScreen.routeName,
          ),
        ),
        SizedBox(height: getProportionateScreenHeight(8)),
        // Thống kê sử dụng
        MenuListItems(
          iconPath: 'assets/icons/menu_icons/stats.svg',
          itemName: 'Thống kê sử dụng',
          function: () => Navigator.of(context).pushNamed(
            StatsScreen.routeName,
          ),
        ),
        SizedBox(height: getProportionateScreenHeight(8)),
        // Tiết kiệm năng lượng
        MenuListItems(
          iconPath: 'assets/icons/menu_icons/savings.svg',
          itemName: 'Tiết kiệm năng lượng',
          function: () {
            Navigator.of(context).pushNamed(SavingsScreen.routeName);
          },
        ),
        SizedBox(height: getProportionateScreenHeight(8)),
        // Cài đặt
        MenuListItems(
          iconPath: 'assets/icons/menu_icons/settings.svg',
          itemName: 'Cài đặt',
          function: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Tính năng cài đặt đang được phát triển'),
                backgroundColor: Color(0xFF464646),
              ),
            );
          },
        ),
        SizedBox(height: getProportionateScreenHeight(8)),
        // FAQ
        MenuListItems(
          iconPath: 'assets/icons/menu_icons/faq.svg',
          itemName: 'Câu hỏi thường gặp',
          function: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Tính năng FAQ đang được phát triển'),
                backgroundColor: Color(0xFF464646),
              ),
            );
          },
        ),
        SizedBox(height: getProportionateScreenHeight(24)),
        // Đăng xuất
        Container(
          width: double.infinity,
          child: MenuListItems(
            iconPath: 'assets/icons/menu_icons/settings.svg',
            itemName: 'Đăng xuất',
            function: () => _showLogoutDialog(context),
          ),
        ),
      ],
    );
  }
}
