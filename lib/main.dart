import 'package:firebase_core/firebase_core.dart';
import 'package:smart_home/firebase_options.dart';
import 'package:smart_home/provider/getit.dart';
import 'package:smart_home/provider/theme_provider.dart';
import 'package:smart_home/routes/routes.dart';
import 'package:smart_home/service/navigation_service.dart';
import 'package:smart_home/service/theme_service.dart';
import 'package:smart_home/service/mqtt_unified_service.dart';
import 'package:smart_home/src/screens/splash_screen/splash_screen.dart';
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
  
  // Initialize MQTT service
  try {
    final mqttService = getIt<MqttUnifiedService>();
    await mqttService.initialize();
    print('MQTT service initialized and connected');
  } catch (e) {
    print('Failed to initialize MQTT service: $e');
  }
  
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
