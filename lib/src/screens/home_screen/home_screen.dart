import 'package:smart_home/config/size_config.dart';
import 'package:smart_home/provider/base_view.dart';
import 'package:smart_home/provider/theme_provider.dart';
import 'package:smart_home/src/screens/edit_profile/edit_profile.dart';

import 'package:smart_home/src/screens/rooms_screen/rooms_screen.dart';
import 'package:smart_home/src/screens/analytics_screen/analytics_screen.dart';
import 'package:smart_home/src/screens/profile_screen/profile_screen.dart';
import 'package:smart_home/src/screens/ai_voice_screen/ai_voice_screen.dart';


import 'package:smart_home/src/widgets/custom_bottom_nav_bar.dart';
import 'package:smart_home/src/widgets/connection_status_widget.dart';
import 'package:smart_home/view/home_screen_view_model.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
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
            iconTheme: IconThemeData(color: Theme.of(context).textTheme.bodyLarge!.color),
            title: Padding(
              padding: EdgeInsets.symmetric(horizontal: getProportionateScreenWidth(4)),
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
                    margin: EdgeInsets.symmetric(horizontal: getProportionateScreenWidth(8)),
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
                              ? [const Color(0xFF2D3748), const Color(0xFF4A5568)]
                              : [const Color(0xFFF7F9FC), const Color(0xFFE6F0FA)],
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
                            themeProvider.isDarkMode ? Icons.light_mode : Icons.dark_mode,
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
                          : [const Color(0xFFF7F9FC), const Color(0xFFE6F0FA)],
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
                          MaterialPageRoute(builder: (context) => const EditProfile()),
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

          // BODY sử dụng PageView để đồng bộ với BottomNavigationBar
          body: PageView(
            controller: model.pageController,
            onPageChanged: (index) {
              model.selectedIndex = index;
              // Sử dụng setState thay vì notifyListeners
            },
            children: <Widget>[
              Body(model: model),
              // Rooms Screen Content
              const RoomsScreenContent(),
              // AI Voice Screen Content
              const AIVoiceScreenContent(),
              // Analytics Screen Content  
              const AnalyticsScreenContent(),
              // Profile Screen Content
              const ProfileScreenContent(),
            ],
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
