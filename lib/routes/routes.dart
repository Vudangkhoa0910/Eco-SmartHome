import 'package:smart_home/src/screens/set_event_screen/set_event_screen.dart';
import 'package:smart_home/src/screens/edit_profile/edit_profile.dart';
import 'package:smart_home/src/screens/auth_screen/auth_screen.dart';
import 'package:smart_home/src/screens/device_connection_screen/device_connection_screen.dart';
import 'package:smart_home/src/screens/settings_screen/settings_screen.dart';
import 'package:smart_home/src/screens/electricity_settings/electricity_settings_screen.dart';
import 'package:smart_home/src/screens/splash_screen/splash_screen.dart';
import 'package:smart_home/src/screens/stats_screen/stats_screen.dart';
import 'package:smart_home/src/screens/rooms_screen/rooms_screen.dart';
import 'package:smart_home/src/screens/ai_voice_screen/ai_voice_screen.dart';
import 'package:smart_home/src/screens/analytics_screen/analytics_screen.dart';
import 'package:smart_home/src/screens/analytics_screen/ai_analytics_detail_screen.dart';
import 'package:smart_home/src/screens/profile_screen/profile_screen.dart';
import 'package:smart_home/src/screens/about_screen/about_us_screen.dart';
import 'package:smart_home/src/screens/qr_scanner_screen.dart';
import 'package:flutter/cupertino.dart';
import 'package:smart_home/src/screens/home_screen/home_screen.dart';
import 'package:smart_home/src/screens/my_list_screen/my_list_screen.dart';
import 'package:smart_home/src/screens/savings_screen/savings_screen.dart';

// Routes arranged in ascending order

final Map<String, WidgetBuilder> routes = {
  EditProfile.routeName: (context) => const EditProfile(),
  ElectricitySettingsScreen.routeName: (context) =>
      const ElectricitySettingsScreen(),
  HomeScreen.routeName: (context) => const HomeScreen(),
  AuthScreen.routeName: (context) => const AuthScreen(),
  DeviceConnectionScreen.routeName: (context) => const DeviceConnectionScreen(),
  SavingsScreen.routeName: (context) => const SavingsScreen(),
  SetEventScreen.routeName: (context) => const SetEventScreen(),
  SettingScreen.routeName: (context) => const SettingScreen(),
  SplashScreen.routeName: (context) => const SplashScreen(),
  StatsScreen.routeName: (context) => const StatsScreen(),
  MyListScreen.routeName: (context) => const MyListScreen(),
  RoomsScreen.routeName: (context) => const RoomsScreen(),
  AIVoiceScreen.routeName: (context) => const AIVoiceScreen(),
  AnalyticsScreen.routeName: (context) => const AnalyticsScreen(),
  AIAnalyticsDetailScreen.routeName: (context) =>
      const AIAnalyticsDetailScreen(),
  ProfileScreen.routeName: (context) => const ProfileScreen(),
  AboutUs.routeName: (context) => const AboutUs(),
  '/qr-scanner': (context) => const QRScannerScreen(),
};
