import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:smart_home/firebase_options.dart';
import 'package:smart_home/provider/getit.dart';
import 'package:smart_home/provider/theme_provider.dart';
import 'package:smart_home/routes/routes.dart';
import 'package:smart_home/service/navigation_service.dart';
import 'package:smart_home/service/theme_service.dart';
import 'package:smart_home/src/screens/splash_screen/splash_screen.dart';
import 'package:smart_home/src/screens/auth_screen/auth_screen.dart';
import 'package:smart_home/src/screens/device_connection_screen/device_connection_screen.dart';
import 'package:smart_home/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase with error handling
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    // Handle duplicate app error
    if (e.toString().contains('duplicate-app')) {
      print('Firebase already initialized');
    } else {
      print('Firebase initialization error: $e');
    }
  }

  // Initialize date formatting
  try {
    await initializeDateFormatting('en_US', null);
    print('Date formatting initialized');
  } catch (e) {
    print('Failed to initialize date formatting: $e');
  }

  // Initialize Theme Service
  try {
    await ThemeService.instance.initialize();
    print('Theme service initialized');
  } catch (e) {
    print('Failed to initialize theme service: $e');
  }

  setupLocator();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => ThemeProvider(),
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            title: 'Smart Home',
            navigatorKey: getIt<NavigationService>().navigatorKey,
            debugShowCheckedModeBanner: false,
            themeMode: themeProvider.themeMode,
            theme: ThemeProvider.lightTheme,
            darkTheme: ThemeProvider.darkTheme,
            routes: routes,
            home: const SplashScreen(),
          );
        },
      ),
    );
  }
}
