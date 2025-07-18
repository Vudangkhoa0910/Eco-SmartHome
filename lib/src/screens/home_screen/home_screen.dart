import 'package:smart_home/config/size_config.dart';
import 'package:smart_home/provider/base_view.dart';
import 'package:smart_home/provider/theme_provider.dart';
import 'package:smart_home/src/screens/edit_profile/edit_profile.dart';
import 'package:smart_home/core/constants/app_colors.dart';

import 'package:smart_home/src/screens/rooms_screen/rooms_screen.dart';
import 'package:smart_home/src/screens/analytics_screen/analytics_screen.dart';
import 'package:smart_home/src/screens/profile_screen/profile_screen.dart';
import 'package:smart_home/src/screens/ai_voice_screen/ai_voice_screen.dart';

import 'package:smart_home/src/widgets/custom_bottom_nav_bar.dart';
import 'package:smart_home/src/widgets/connection_status_widget.dart';
import 'package:smart_home/view/home_screen_view_model.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'components/body.dart';
import 'package:smart_home/src/screens/menu_page/menu_screen.dart';

class HomeScreen extends StatelessWidget {
  static String routeName = '/home-screen';
  const HomeScreen({Key? key}) : super(key: key);

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Chào buổi sáng';
    } else if (hour < 18) {
      return 'Chào buổi trưa';
    } else {
      return 'Chào buổi tối';
    }
  }

  @override
  Widget build(BuildContext context) {
    SizeConfig().init(context);

    return BaseView<HomeScreenViewModel>(
      onModelReady: (model) {
        model.generateRandomNumber();
        model.initializeServices();
      },
      builder: (context, model, child) {
        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          appBar: AppBar(
            toolbarHeight: getProportionateScreenHeight(45),
            elevation: 0,
            backgroundColor: Colors.transparent,
            iconTheme: IconThemeData(
                color: Theme.of(context).textTheme.bodyLarge!.color),
            title: Padding(
              padding: EdgeInsets.symmetric(
                  horizontal: getProportionateScreenWidth(4)),
              child: Row(
                children: [
                  Expanded(
                    flex: 4,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _getGreeting(),
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context).textTheme.bodySmall!.color,
                            fontWeight: FontWeight.w400,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Xin chào, ${model.userName} 👋',
                          style: TextStyle(
                            fontSize: 20,
                            color: Theme.of(context).textTheme.bodyLarge!.color,
                            fontWeight: FontWeight.w700,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  // Connection Status - Simple dot
                  Container(
                    margin: EdgeInsets.symmetric(
                        horizontal: getProportionateScreenWidth(8)),
                    child: ConnectionStatusWidget(model: model),
                  ),
                  SizedBox(width: getProportionateScreenWidth(4)),
                  // Theme toggle button
                  Consumer<ThemeProvider>(
                    builder: (context, themeProvider, child) {
                      return Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: themeProvider.isDarkMode
                                ? [
                                    const Color(0xFF2D3748),
                                    const Color(0xFF4A5568)
                                  ]
                                : [
                                    const Color(0xFFF7F9FC),
                                    const Color(0xFFE6F0FA)
                                  ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF6B73FF).withOpacity(0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: IconButton(
                          padding: EdgeInsets.zero,
                          splashRadius: 20,
                          icon: Icon(
                            themeProvider.isDarkMode
                                ? Icons.light_mode
                                : Icons.dark_mode,
                            color: const Color(0xFF6B73FF),
                            size: 20,
                          ),
                          onPressed: () {
                            themeProvider.toggleTheme();
                          },
                        ),
                      );
                    },
                  ),
                  SizedBox(width: getProportionateScreenWidth(4)),
                  // Profile button (compact)
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: Theme.of(context).brightness == Brightness.dark
                            ? [const Color(0xFF2D3748), const Color(0xFF4A5568)]
                            : [
                                const Color(0xFFF7F9FC),
                                const Color(0xFFE6F0FA)
                              ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF6B73FF).withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      splashRadius: 20,
                      icon: const Icon(
                        Icons.person_outline,
                        color: Color(0xFF6B73FF),
                        size: 20,
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const EditProfile()),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          drawer: SizedBox(
            width: getProportionateScreenWidth(270),
            child: const Menu(),
          ),

          floatingActionButtonLocation:
              FloatingActionButtonLocation.centerDocked,
          floatingActionButton: Container(
            margin: const EdgeInsets.only(top: 70), // Đẩy xuống gần navbar hơn
            child: SizedBox(
              width: 56, // Kích thước lớn hơn một chút
              height: 56, // Kích thước lớn hơn một chút
              child: Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFF6B73FF),
                      Color(0xFF9C88FF)
                    ], // Giữ màu như code cũ
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
                child: FloatingActionButton(
                  onPressed: () {
                    // Navigate to AI Voice Screen hoặc show dialog/popup
                    model.onItemTapped(2);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const AIVoiceScreenContent()),
                    );
                  },
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  child: AnimatedScale(
                    duration: const Duration(milliseconds: 200),
                    scale: model.selectedIndex == 2 ? 1.1 : 1.0,
                    child: const Icon(
                      Icons.mic,
                      color: Colors.white,
                      size: 32, // Icon mic lớn hơn một chút
                    ),
                  ),
                ),
              ),
            ),
          ),

          // BODY sử dụng PageView để đồng bộ với BottomNavigationBar
          body: Container(
            decoration: const BoxDecoration(
              gradient: AppColors.mainGradient,
            ),
            child: PageView(
              controller: model.pageController,
              physics: const BouncingScrollPhysics(),
              onPageChanged: (pageIdx) {
                // map page index back to nav index (account for AI voice at nav 2)
                final navIndex = pageIdx >= 2 ? pageIdx + 1 : pageIdx;
                model.selectedIndex = navIndex;
                // Will automatically trigger rebuild through Provider
              },
              children: <Widget>[
                Body(model: model),
                // Rooms Screen Content
                const RoomsScreenContent(),
                // Analytics Screen Content (skip AI Voice for PageView)
                const AnalyticsScreenContent(),
                // Profile Screen Content
                const ProfileScreenContent(),
              ],
            ),
          ),

          bottomNavigationBar: CustomBottomNavBar(model: model),
        );
      },
    );
  }
}

// Content screens for bottom navigation
class RoomsScreenContent extends StatelessWidget {
  const RoomsScreenContent({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const RoomsScreen();
  }
}

class AIVoiceScreenContent extends StatelessWidget {
  const AIVoiceScreenContent({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const AIVoiceScreen();
  }
}

class AnalyticsScreenContent extends StatelessWidget {
  const AnalyticsScreenContent({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const AnalyticsScreen();
  }
}

class ProfileScreenContent extends StatelessWidget {
  const ProfileScreenContent({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const ProfileScreen();
  }
}
