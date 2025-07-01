import 'package:flutter/material.dart';
import 'package:smart_home/src/screens/analytics_screen/influx_analytics_screen.dart';

class AnalyticsScreen extends StatelessWidget {
  static String routeName = '/analytics-screen';
  const AnalyticsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).cardColor,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Text(
          'Thống kê & Phân tích',
          style: TextStyle(
            fontFamily: 'Lexend',
            fontSize: 24,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).textTheme.displayLarge!.color,
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 8),
            child: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF4CAF50).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.bug_report, 
                  color: Color(0xFF4CAF50), 
                  size: 16
                ),
              ),
              onPressed: () {
                // Access debug toggle via a callback or global state
                // This is a placeholder - you might need to implement proper communication
              },
            ),
          ),
          Container(
            margin: const EdgeInsets.only(right: 16),
            child: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF2196F3).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.refresh, 
                  color: Color(0xFF2196F3), 
                  size: 20
                ),
              ),
              onPressed: () {
                // Refresh analytics data
              },
            ),
          ),
        ],
      ),
      body: const InfluxAnalyticsScreen(),
    );
  }
}
