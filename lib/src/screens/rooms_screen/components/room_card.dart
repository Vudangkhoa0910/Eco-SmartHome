import 'package:flutter/material.dart';
import 'package:smart_home/config/size_config.dart';
import 'package:smart_home/view/home_screen_view_model.dart';

import 'package:provider/provider.dart';

class RoomCard extends StatelessWidget {
  final dynamic room;
  final VoidCallback onTap;

  const RoomCard({
    Key? key,
    required this.room,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).shadowColor.withOpacity(0.1),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: ClipRect(
          child: Padding(
            padding: EdgeInsets.all(getProportionateScreenWidth(8)),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
              // Room Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: EdgeInsets.all(getProportionateScreenWidth(10)),
                    decoration: BoxDecoration(
                      color: _getRoomColor().withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      _getRoomIcon(),
                      color: _getRoomColor(),
                      size: 24,
                    ),
                  ),
                  Text(
                    '${room.temperature}°C',
                    style: Theme.of(context).textTheme.headlineMedium!.copyWith(
                      fontWeight: FontWeight.bold,
                      color: _getRoomColor(),
                    ),
                  ),
                ],
              ),
              
              SizedBox(height: getProportionateScreenHeight(4)),
              
              // Room Name
              Text(
                room.name,
                style: Theme.of(context).textTheme.displayMedium!.copyWith(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              
              SizedBox(height: getProportionateScreenHeight(2)),
              
              // Device Count
              Text(
                '${room.devices.length} devices',
                style: Theme.of(context).textTheme.headlineMedium!.copyWith(
                  fontSize: 11,
                ),
              ),
              
              SizedBox(height: getProportionateScreenHeight(4)),
              
              // Active Devices Row
              SizedBox(
                height: getProportionateScreenHeight(20),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      ...room.devices.take(3).map<Widget>((device) => 
                        Container(
                          margin: EdgeInsets.only(right: getProportionateScreenWidth(4)),
                          padding: EdgeInsets.all(getProportionateScreenWidth(3)),
                          decoration: BoxDecoration(
                            color: device.isOn ? _getRoomColor().withOpacity(0.2) : Colors.grey[200],
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: Icon(
                            _getDeviceIcon(device.type),
                            size: 12,
                            color: device.isOn ? _getRoomColor() : Colors.grey[500],
                          ),
                        ),
                      ).toList(),
                      if (room.devices.length > 3)
                        Container(
                          padding: EdgeInsets.all(getProportionateScreenWidth(3)),
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: Text(
                            '+${room.devices.length - 3}',
                            style: TextStyle(
                              fontSize: 9,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      // LED Control for Living Room
                      if (room.name == 'Living Room')
                        _buildLedControl(),
                      // Motor Control for Bedroom
                      if (room.name == 'Bedroom')
                        _buildMotorControl(),
                    ],
                  ),
                ),
              ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLedControl() {
    return Consumer<HomeScreenViewModel>(
      builder: (context, model, child) {
        return Row(
          children: [
        // LED 1 Control
        GestureDetector(
          onTap: () => model.toggleLed1(),
          child: Container(
            margin: EdgeInsets.only(left: getProportionateScreenWidth(4)),
            padding: EdgeInsets.all(getProportionateScreenWidth(3)),
            decoration: BoxDecoration(
              color: model.isLightOn 
                  ? Colors.amber.withOpacity(0.2) 
                  : (Theme.of(context).brightness == Brightness.dark 
                      ? Colors.grey[800] 
                      : Colors.grey[200]),
              borderRadius: BorderRadius.circular(5),
              border: Border.all(
                color: model.isLightOn 
                    ? Colors.amber 
                    : (Theme.of(context).brightness == Brightness.dark 
                        ? Colors.grey[600]! 
                        : Colors.grey[400]!),
                width: 1,
              ),
            ),
            child: Icon(
              Icons.lightbulb,
              size: 14,
              color: model.isLightOn 
                  ? Colors.amber[700] 
                  : (Theme.of(context).brightness == Brightness.dark 
                      ? Colors.grey[400] 
                      : Colors.grey[500]),
            ),
          ),
        ),
        // LED 2 Control
        GestureDetector(
          onTap: () => model.toggleLed2(),
          child: Container(
            margin: EdgeInsets.only(left: getProportionateScreenWidth(2)),
            padding: EdgeInsets.all(getProportionateScreenWidth(3)),
            decoration: BoxDecoration(
              // FIXED: LED Around logic ngược - isACON=true nghĩa là tắt đèn
              color: model.isACON 
                  ? Colors.red.withOpacity(0.2)  // ON = Tắt đèn (màu đỏ)
                  : Colors.lightBlue.withOpacity(0.2), // OFF = Mở đèn (màu xanh)
              borderRadius: BorderRadius.circular(5),
              border: Border.all(
                color: model.isACON 
                    ? Colors.red  // ON = Tắt đèn (viền đỏ)
                    : Colors.lightBlue, // OFF = Mở đèn (viền xanh)
                width: 1,
              ),
            ),
            child: Icon(
              Icons.lightbulb_outline,
              size: 14,
              // FIXED: LED Around hiển thị màu đúng theo trạng thái thực tế
              color: model.isACON 
                  ? Colors.red[700]  // ON = Tắt đèn (màu đỏ)
                  : Colors.lightBlue[700], // OFF = Mở đèn (màu xanh)
            ),
          ),            ),
          ],
        );
      },
    );
  }

  Widget _buildMotorControl() {
    return Consumer<HomeScreenViewModel>(
      builder: (context, model, child) {
        return GestureDetector(
          onTap: () => model.toggleMotor(),
          child: Container(
            margin: EdgeInsets.only(left: getProportionateScreenWidth(4)),
            padding: EdgeInsets.all(getProportionateScreenWidth(3)),
            decoration: BoxDecoration(
              color: model.isFanON ? Colors.green.withOpacity(0.2) : Colors.grey[200],
              borderRadius: BorderRadius.circular(5),
              border: Border.all(
                color: model.isFanON ? Colors.green : Colors.grey[400]!,
                width: 1,
              ),
            ),
            child: Icon(
              Icons.toys,
              size: 14,
              color: model.isFanON ? Colors.green[700] : Colors.grey[500],
            ),
          ),
        );
      },
    );
  }

  Color _getRoomColor() {
    switch (room.type.toLowerCase()) {
      case 'bedroom':
        return const Color(0xFF6B73FF);
      case 'living room':
        return const Color(0xFF9C88FF);
      case 'kitchen':
        return const Color(0xFFFF6B6B);
      case 'bathroom':
        return const Color(0xFF4ECDC4);
      case 'office':
        return const Color(0xFFFFD93D);
      default:
        return const Color(0xFF464646);
    }
  }

  IconData _getRoomIcon() {
    switch (room.type.toLowerCase()) {
      case 'bedroom':
        return Icons.bed;
      case 'living room':
        return Icons.weekend;
      case 'kitchen':
        return Icons.kitchen;
      case 'bathroom':
        return Icons.bathtub;
      case 'office':
        return Icons.work;
      default:
        return Icons.room;
    }
  }

  IconData _getDeviceIcon(String deviceType) {
    switch (deviceType.toLowerCase()) {
      case 'light':
        return Icons.lightbulb_outline;
      case 'ac':
        return Icons.ac_unit;
      case 'fan':
        return Icons.toys;
      case 'speaker':
        return Icons.speaker;
      case 'tv':
        return Icons.tv;
      default:
        return Icons.device_unknown;
    }
  }
}
