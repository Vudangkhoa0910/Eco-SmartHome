import 'package:smart_home/view/home_screen_view_model.dart';
import 'package:flutter/material.dart';
import 'package:smart_home/config/size_config.dart';

class CustomBottomNavBar extends StatelessWidget {
  const CustomBottomNavBar({
    Key? key,
    required this.model,
  }) : super(key: key);

  final HomeScreenViewModel model;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: getProportionateScreenHeight(80),
      decoration: BoxDecoration(
        color: Theme.of(context).bottomNavigationBarTheme.backgroundColor ?? 
               Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).shadowColor.withOpacity(0.1),
            blurRadius: 25,
            offset: const Offset(0, -8),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(
            context,
            icon: Icons.home_outlined,
            selectedIcon: Icons.home,
            label: 'Home',
            isSelected: model.selectedIndex == 0,
            onTap: () => model.onItemTapped(0),
          ),
          _buildNavItem(
            context,
            icon: Icons.meeting_room_outlined,
            selectedIcon: Icons.meeting_room,
            label: 'Rooms',
            isSelected: model.selectedIndex == 1,
            onTap: () => model.onItemTapped(1),
          ),
          // AI Voice Button - Center
          _buildAIButton(context),
          _buildNavItem(
            context,
            icon: Icons.analytics_outlined,
            selectedIcon: Icons.analytics,
            label: 'Analytics',
            isSelected: model.selectedIndex == 3,
            onTap: () => model.onItemTapped(3),
          ),
          _buildNavItem(
            context,
            icon: Icons.person_outline,
            selectedIcon: Icons.person,
            label: 'Profile',
            isSelected: model.selectedIndex == 4,
            onTap: () => model.onItemTapped(4),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context, {
    required IconData icon,
    required IconData selectedIcon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(
          vertical: getProportionateScreenHeight(8),
          horizontal: getProportionateScreenWidth(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: isSelected ? const Color(0xFF6B73FF).withOpacity(0.1) : Colors.transparent,
              ),
              child: Icon(
                isSelected ? selectedIcon : icon,
                color: isSelected ? const Color(0xFF6B73FF) : 
                       (Theme.of(context).brightness == Brightness.dark ? 
                        Colors.grey[400] : const Color(0xFF9E9E9E)),
                size: 26,
              ),
            ),
            SizedBox(height: getProportionateScreenHeight(4)),
            AnimatedOpacity(
              duration: const Duration(milliseconds: 200),
              opacity: isSelected ? 1.0 : 0.0,
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF6B73FF),
                  height: 1.2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAIButton(BuildContext context) {
    return GestureDetector(
      onTap: () {
        model.onItemTapped(2); // AI tab is at index 2
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: getProportionateScreenWidth(60),
        height: getProportionateScreenWidth(60),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: model.selectedIndex == 2 
              ? [const Color(0xFF6B73FF), const Color(0xFF9C88FF)]
              : [const Color(0xFF6B73FF).withOpacity(0.8), const Color(0xFF9C88FF).withOpacity(0.8)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF6B73FF).withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 8),
              spreadRadius: 0,
            ),
          ],
        ),
        child: AnimatedScale(
          duration: const Duration(milliseconds: 200),
          scale: model.selectedIndex == 2 ? 1.1 : 1.0,
          child: const Icon(
            Icons.mic,
            color: Colors.white,
            size: 28,
          ),
        ),
      ),
    );
  }
}
