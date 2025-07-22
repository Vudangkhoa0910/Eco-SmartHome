import 'package:smart_home/view/home_screen_view_model.dart';
import 'package:flutter/material.dart';
import 'package:smart_home/core/theme/app_theme.dart';
import 'package:smart_home/src/screens/ai_voice_screen/ai_voice_screen.dart';

// Custom clipper để tạo notch trong navigation bar
class BottomNavBarClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    // Bắt đầu từ góc trái trên
    path.lineTo(0, 0);
    // Đường viền trên đến gần center
    path.lineTo(size.width * 0.35, 0);
    // Tạo notch tròn ở center
    path.quadraticBezierTo(
      size.width * 0.40, 0,
      size.width * 0.40, 20,
    );
    path.arcToPoint(
      Offset(size.width * 0.60, 20),
      radius: const Radius.circular(20),
      clockwise: false,
    );
    path.quadraticBezierTo(
      size.width * 0.60, 0,
      size.width * 0.65, 0,
    );
    // Tiếp tục đường viền trên đến góc phải
    path.lineTo(size.width, 0);
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

class CustomBottomNavBar extends StatelessWidget {
  const CustomBottomNavBar({
    Key? key,
    required this.model,
  }) : super(key: key);

  final HomeScreenViewModel model;

  void _onTap(int index) {
    if (index == 2) {
      // AI Voice control - handle navigation to AI Voice screen
      model.onItemTapped(index);
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
          color: isSelected ? Colors.black.withOpacity(0.1) : Colors.transparent,
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
    return Stack(
      alignment: Alignment.center,
      children: [
        // Navigation Bar với notch
        ClipPath(
          clipper: BottomNavBarClipper(),
          child: Container(
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 20),
            height: 70.0,
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(35),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                  spreadRadius: 0,
                ),
              ],
              border: Border.all(
                color: AppColors.textLight.withOpacity(0.1),
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
                  // Khoảng trống cho mic button
                  const SizedBox(width: 60),
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
          ),
        ),
        // Mic Button nằm chính xác trong notch của navigation bar
        Positioned(
          bottom: 30, // Điều chỉnh để nằm trong notch
          child: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF6B73FF), Color(0xFF9C88FF)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF6B73FF).withOpacity(0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                  spreadRadius: 0,
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(28),
                onTap: () {
                  model.onItemTapped(2);
                  // Navigate to AI Voice Screen
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AIVoiceScreen(),
                    ),
                  );
                },
                child: AnimatedScale(
                  duration: const Duration(milliseconds: 200),
                  scale: model.selectedIndex == 2 ? 1.1 : 1.0,
                  child: const Icon(
                    Icons.mic,
                    color: Colors.white,
                    size: 30,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
