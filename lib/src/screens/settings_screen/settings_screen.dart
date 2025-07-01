import 'package:flutter/material.dart';
import 'components/body.dart';

class SettingScreen extends StatelessWidget {
  static String routeName = '/settings_screen';
  const SettingScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Material(
        color: Theme.of(context).scaffoldBackgroundColor,
        child: ListView(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(32, 64, 48, 20),
              child: Row(
                children: [
                  Text(
                    "Settings",
                    style: TextStyle(
                        fontFamily: 'Lexend',
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).textTheme.displayLarge!.color,
                        fontSize: 36,
                        letterSpacing: -0.3199999928474426,
                        height: 0.5833333333333334),
                  ),
                  const SizedBox(width: 102),
                  Icon(
                    Icons.close_sharp,
                    color: Theme.of(context).iconTheme.color,
                    size: 30,
                  )
                ],
              ),
            ),
            const SettingTile(),
            const SwitchTiles(),
            const SizedBox(
              height: 24.44,
            ),
            const SettingTile(),
          ],
        ));
  }
}
