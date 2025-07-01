import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:smart_home/src/screens/auth_screen/auth_screen.dart';
import 'package:smart_home/src/screens/device_connection_screen/device_connection_screen.dart';
import 'package:smart_home/src/screens/home_screen/home_screen.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }
        
        if (snapshot.hasData) {
          // User is logged in, check if they have connected devices
          return const DeviceConnectionScreen();
        } else {
          // User is not logged in
          return const AuthScreen();
        }
      },
    );
  }
}
