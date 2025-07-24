import 'package:flutter/material.dart';
import 'package:smart_home/config/size_config.dart';
import 'package:smart_home/view/home_screen_view_model.dart';
import 'package:smart_home/src/screens/electricity_settings/electricity_settings_screen.dart';

class EnergyManagementWidget extends StatelessWidget {
  const EnergyManagementWidget({Key? key, required this.model, this.isCompact = false}) : super(key: key);

  final HomeScreenViewModel model;
  final bool isCompact;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: getProportionateScreenWidth(5)),
      child: isCompact ?
        // Compact layout - single row
        _buildCompactCard(
          context: context,
          title: 'Năng lượng',
          subtitle: 'Quản lý & Thống kê',
          icon: Icons.electric_bolt,
          color: Colors.green,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const ElectricitySettingsScreen(),
              ),
            );
          },
        ) :
        // Full layout
        Row(
          children: [
            // Electricity Settings Button
            Expanded(
              child: _buildManagementCard(
                context: context,
                title: 'Cài đặt điện',
                subtitle: 'Quản lý biểu giá điện',
                icon: Icons.settings,
                color: Colors.orange,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ElectricitySettingsScreen(),
                    ),
                  );
                },
              ),
            ),
            SizedBox(width: getProportionateScreenWidth(10)),
            // Energy Dashboard Button
            Expanded(
              child: _buildManagementCard(
                context: context,
                title: 'Năng lượng',
                subtitle: 'Xem thống kê tiêu thụ',
                icon: Icons.bar_chart,
                color: Colors.green,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ElectricitySettingsScreen(),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
    );
  }

  Widget _buildManagementCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: getProportionateScreenHeight(85),
        padding: EdgeInsets.all(getProportionateScreenWidth(16)),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: color,
                size: 28,
              ),
            ),
            SizedBox(width: getProportionateScreenWidth(16)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: getProportionateScreenWidth(16),
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: getProportionateScreenHeight(2)),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: getProportionateScreenWidth(12),
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: getProportionateScreenHeight(60),
        padding: EdgeInsets.symmetric(
          horizontal: getProportionateScreenWidth(12),
          vertical: getProportionateScreenHeight(8),
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: color,
                size: 18,
              ),
            ),
            SizedBox(width: getProportionateScreenWidth(8)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w400,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: Colors.grey[400],
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}
