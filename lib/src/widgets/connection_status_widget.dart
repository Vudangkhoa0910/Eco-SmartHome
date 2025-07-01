import 'package:flutter/material.dart';
import 'package:smart_home/view/home_screen_view_model.dart';

class ConnectionStatusWidget extends StatelessWidget {
  final HomeScreenViewModel model;
  
  const ConnectionStatusWidget({
    Key? key,
    required this.model,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Simple connection indicator
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: model.isMqttConnected ? Colors.green : Colors.red,
            shape: BoxShape.circle,
          ),
        ),
      ],
    );
  }
}
