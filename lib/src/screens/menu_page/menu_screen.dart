import 'package:flutter/material.dart';

import 'package:smart_home/src/screens/menu_page/components/body.dart';

class Menu extends StatelessWidget {
  static String routeName = '/menu-screen';
  const Menu({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Scaffold(
        backgroundColor: Theme.of(context).brightness == Brightness.dark 
            ? const Color(0xFF2E3440) 
            : const Color(0xFFF7F9FC),
        body: const Body(),
      ),
    );
  }
}

