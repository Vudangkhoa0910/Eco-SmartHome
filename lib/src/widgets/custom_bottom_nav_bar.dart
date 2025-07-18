import 'package:smart_home/view/home_screen_view_model.dart';
import 'package:flutter/material.dart';
import 'package:smart_home/core/theme/app_theme.dart';

class CustomBottomNavBar extends StatelessWidget {
  const CustomBottomNavBar({
    Key? key,
    required this.model,
  }) : super(key: key);

  final HomeScreenViewModel model;

  void _onTap(int index) {
    if (index == 2) {
      // AI Voice control - do nothing on tap, only handle special actions
      return;
    }
    model.onItemTapped(index);
  }

  // Helper method để tạo nav item với animation đẹp theo mẫu
  Widget _buildNavItem({
    required IconData icon,
    required IconData selectedIcon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color:
              isSelected ? Colors.black.withValues(alpha: 0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          child: Icon(
            isSelected ? selectedIcon : icon,
            color: isSelected ? AppColors.primary : Colors.grey.shade600,
            size: isSelected ? 26 : 24,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(
          16, 0, 16, 20), // Margin để tạo khoảng cách với cạnh màn hình
      height: 70.0, // Tăng chiều cao cho navbar
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(35), // Bo tròn thành hình trụ
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 20,
            offset: const Offset(0, 8),
            spreadRadius: 0,
          ),
        ],
        border: Border.all(
          color: AppColors.textLight.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Home Icon
            _buildNavItem(
              icon: Icons.home_outlined,
              selectedIcon: Icons.home,
              isSelected: model.selectedIndex == 0,
              onTap: () => _onTap(0),
            ),
            // Rooms Icon
            _buildNavItem(
              icon: Icons.meeting_room_outlined,
              selectedIcon: Icons.meeting_room,
              isSelected: model.selectedIndex == 1,
              onTap: () => _onTap(1),
            ),
            // Center space for AI FAB - tạo notch tròn lớn hơn một chút
            Container(
              width: 56, // Tăng lên để phù hợp với AI button lớn hơn
              height: 30,
              decoration: BoxDecoration(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(15),
              ),
            ),
            // Analytics Icon
            _buildNavItem(
              icon: Icons.analytics_outlined,
              selectedIcon: Icons.analytics,
              isSelected: model.selectedIndex == 3,
              onTap: () => _onTap(3),
            ),
            // Profile Icon
            _buildNavItem(
              icon: Icons.person_outline,
              selectedIcon: Icons.person,
              isSelected: model.selectedIndex == 4,
              onTap: () => _onTap(4),
            ),
          ],
        ),
      ),
    );
  }
}
