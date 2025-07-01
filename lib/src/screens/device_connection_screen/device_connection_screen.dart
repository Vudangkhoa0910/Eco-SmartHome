import 'package:flutter/material.dart';
import 'package:smart_home/src/screens/device_connection_screen/components/body.dart';

class DeviceConnectionScreen extends StatelessWidget {
  static String routeName = '/device-connection-screen';
  const DeviceConnectionScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Body(),
    );
  }
}
