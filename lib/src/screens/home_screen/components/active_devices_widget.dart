import 'package:flutter/material.dart';
import 'package:smart_home/config/size_config.dart';
import 'package:smart_home/view/home_screen_view_model.dart';
import 'package:smart_home/service/device_state_service.dart';
import 'package:provider/provider.dart';

class ActiveDevicesWidget extends StatelessWidget {
  final HomeScreenViewModel model;

  const ActiveDevicesWidget({Key? key, required this.model}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: model,
      child: Consumer<HomeScreenViewModel>(
        builder: (context, viewModel, child) {
          return StreamBuilder<Map<String, bool>>(
            stream: DeviceStateService().stateStream,
            builder: (context, snapshot) {
              final activeDevices = _getActiveDevices(viewModel, snapshot.data);
              
              if (activeDevices.isEmpty) {
                return _buildEmptyState();
              }

              return Container(
                margin: EdgeInsets.symmetric(
                  horizontal: getProportionateScreenWidth(20),
                  vertical: getProportionateScreenHeight(8),
                ),
                padding: EdgeInsets.all(getProportionateScreenWidth(16)),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      spreadRadius: 1,
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.power_settings_new,
                          color: Colors.green,
                          size: 16,
                        ),
                        SizedBox(width: getProportionateScreenWidth(8)),
                        Text(
                          'Thiết bị đang hoạt động',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[800],
                          ),
                        ),
                        SizedBox(width: getProportionateScreenWidth(8)),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: getProportionateScreenWidth(6),
                            vertical: getProportionateScreenHeight(2),
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${activeDevices.length}',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: getProportionateScreenHeight(12)),
                    Wrap(
                      spacing: getProportionateScreenWidth(8),
                      runSpacing: getProportionateScreenHeight(6),
                      children: activeDevices.map((device) => _buildDeviceChip(device)).toList(),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: getProportionateScreenWidth(20),
        vertical: getProportionateScreenHeight(8),
      ),
      padding: EdgeInsets.all(getProportionateScreenWidth(16)),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.power_off,
            color: Colors.grey,
            size: 16,
          ),
          SizedBox(width: getProportionateScreenWidth(8)),
          Text(
            'Tất cả thiết bị đang tắt',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeviceChip(ActiveDevice device) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: getProportionateScreenWidth(8),
        vertical: getProportionateScreenHeight(4),
      ),
      decoration: BoxDecoration(
        color: device.color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: device.color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            device.icon,
            size: 12,
            color: device.color,
          ),
          SizedBox(width: getProportionateScreenWidth(4)),
          Text(
            device.name,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: device.color,
            ),
          ),
        ],
      ),
    );
  }

  List<ActiveDevice> _getActiveDevices(HomeScreenViewModel viewModel, Map<String, bool>? deviceStates) {
    List<ActiveDevice> activeDevices = [];

    // Safely get device state - ONLY read, no side effects
    bool getDeviceState(String deviceKey) {
      return deviceStates?[deviceKey] ?? false;
    }

    // Check outdoor devices using ONLY read-only device state
    if (getDeviceState('led_gate')) {
      activeDevices.add(ActiveDevice(
        name: 'Đèn cổng',
        icon: Icons.lightbulb_outline,
        color: Color(0xFF7F80F2),
      ));
    }

    if (getDeviceState('led_around')) {
      activeDevices.add(ActiveDevice(
        name: 'Đèn sân',
        icon: Icons.lightbulb,
        color: Color(0xFF7A79F2),
      ));
    }

    // Check gate status using ViewModel state only
    if (viewModel.currentGateLevel > 0) {
      activeDevices.add(ActiveDevice(
        name: 'Cổng điện (${viewModel.currentGateLevel}%)',
        icon: Icons.garage_outlined,
        color: Color(0xFF8183F2),
      ));
    }

    // Check indoor devices using ViewModel state only
    if (viewModel.isKitchenLightOn) {
      activeDevices.add(ActiveDevice(
        name: 'Đèn bếp',
        icon: Icons.lightbulb,
        color: Color(0xFF716DF2),
      ));
    }

    if (viewModel.isLivingRoomLightOn) {
      activeDevices.add(ActiveDevice(
        name: 'Đèn phòng khách',
        icon: Icons.lightbulb_outline,
        color: Color(0xFF716DF2),
      ));
    }

    if (viewModel.isBedroomLightOn) {
      activeDevices.add(ActiveDevice(
        name: 'Đèn phòng ngủ T1',
        icon: Icons.bedtime,
        color: Color(0xFF716DF2),
      ));
    }

    if (viewModel.isCornerBedroomLightOn) {
      activeDevices.add(ActiveDevice(
        name: 'Đèn phòng ngủ góc',
        icon: Icons.lightbulb,
        color: Color(0xFF716DF2),
      ));
    }

    if (viewModel.isYardBedroomLightOn) {
      activeDevices.add(ActiveDevice(
        name: 'Đèn phòng ngủ sân',
        icon: Icons.lightbulb,
        color: Color(0xFF716DF2),
      ));
    }

    if (viewModel.isWorshipRoomLightOn) {
      activeDevices.add(ActiveDevice(
        name: 'Đèn phòng thờ',
        icon: Icons.lightbulb,
        color: Color(0xFF716DF2),
      ));
    }

    if (viewModel.isHallwayLightOn) {
      activeDevices.add(ActiveDevice(
        name: 'Đèn hành lang',
        icon: Icons.lightbulb,
        color: Color(0xFF716DF2),
      ));
    }

    if (viewModel.isBalconyLightOn) {
      activeDevices.add(ActiveDevice(
        name: 'Đèn ban công',
        icon: Icons.lightbulb_outline,
        color: Color(0xFF716DF2),
      ));
    }

    // Check legacy devices using ViewModel state only
    if (viewModel.isLightOn) {
      activeDevices.add(ActiveDevice(
        name: 'Đèn chính',
        icon: Icons.lightbulb,
        color: Colors.amber,
      ));
    }

    if (viewModel.isACON) {
      activeDevices.add(ActiveDevice(
        name: 'Điều hòa',
        icon: Icons.ac_unit,
        color: Colors.blue,
      ));
    }

    if (viewModel.isFanON) {
      activeDevices.add(ActiveDevice(
        name: 'Quạt',
        icon: Icons.wind_power,
        color: Colors.teal,
      ));
    }

    if (viewModel.isSpeakerON) {
      activeDevices.add(ActiveDevice(
        name: 'Loa',
        icon: Icons.speaker,
        color: Colors.purple,
      ));
    }

    return activeDevices;
  }
}

class ActiveDevice {
  final String name;
  final IconData icon;
  final Color color;

  ActiveDevice({
    required this.name,
    required this.icon,
    required this.color,
  });
}
