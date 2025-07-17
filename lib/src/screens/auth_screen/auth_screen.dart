import 'package:flutter/material.dart';
import 'package:smart_home/src/screens/auth_screen/components/body.dart';

class AuthScreen extends StatelessWidget {
  static String routeName = '/auth-screen';
  const AuthScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      resizeToAvoidBottomInset: true, // Thay đổi thành true để cho phép màn hình tự resize khi bàn phím hiện lên
      body: const Body(),
    );
  }
}
