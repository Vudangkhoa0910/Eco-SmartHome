import 'package:flutter/material.dart';
import 'package:smart_home/src/screens/analytics_screen/firebase_analytics_screen.dart';

class AnalyticsScreen extends StatelessWidget {
  static String routeName = '/analytics-screen';
  const AnalyticsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: null,
      body: const FirebaseAnalyticsScreen(),
    );
  }
}
