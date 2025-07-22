import 'package:smart_home/config/size_config.dart';
import 'package:smart_home/src/screens/home_screen/components/weather_container.dart';
import 'package:smart_home/src/screens/home_screen/components/sensor_data_container.dart';
import 'package:smart_home/src/screens/home_screen/components/energy_overview_widget.dart';
import 'package:smart_home/src/screens/set_event_screen/set_event_screen.dart';
import 'package:smart_home/view/home_screen_view_model.dart';
import 'package:smart_home/service/device_manager_service.dart';
import 'package:smart_home/src/widgets/custom_notification.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'add_device_widget.dart';

class Body extends StatefulWidget {
  final HomeScreenViewModel model;
  const Body({Key? key, required this.model}) : super(key: key);

  @override
  _BodyState createState() => _BodyState();
}

class _BodyState extends State<Body> {
  final DeviceManagerService _deviceManager = DeviceManagerService();
  List<UserAddedDevice> _userDevices = [];

  @override
  void initState() {
    super.initState();
    _loadUserDevices();
  }

  Future<void> _loadUserDevices() async {
    final devices = await _deviceManager.getUserDevices();
    setState(() {
      _userDevices = devices;
    });
  }

  /// Get SVG asset path for device type - comprehensive device mapping
  String _getDeviceSvgAsset(String deviceType) {
    switch (deviceType.toLowerCase()) {
      // Lighting devices
      case 'light':
      case 'bulb':
      case 'lamp':
      case 'lighting':
        return 'assets/icons/svg/light.svg';
      
      // Climate control
      case 'fan':
      case 'ceiling_fan':
      case 'ventilation':
        return 'assets/icons/svg/fan.svg';
      case 'ac':
      case 'air_conditioner':
      case 'hvac':
      case 'climate':
        return 'assets/icons/svg/ac.svg';
      
      // Audio/Video devices
      case 'speaker':
      case 'audio':
      case 'sound_system':
        return 'assets/icons/svg/speaker.svg';
      case 'tv':
      case 'television':
      case 'smart_tv':
      case 'entertainment':
        return 'assets/icons/svg/music.svg'; // Use music icon for TV/entertainment
      
      // Security & Monitoring
      case 'camera':
      case 'security':
      case 'cctv':
      case 'surveillance':
        return 'assets/icons/svg/profile.svg'; // Use profile icon for camera/security
      
      // Sensors & IoT
      case 'sensor':
      case 'temperature':
      case 'humidity':
      case 'motion':
      case 'door':
      case 'window':
        return 'assets/icons/svg/eco.svg'; // Use eco icon for sensors
      
      // Switches & Controls
      case 'switch':
      case 'outlet':
      case 'plug':
      case 'smart_switch':
        return 'assets/icons/svg/star.svg'; // Use star icon for switches
      
      // Smart Home Appliances
      case 'robot':
      case 'vacuum':
      case 'cleaner':
        return 'assets/icons/svg/info.svg'; // Use info icon for robots/cleaners
      
      // Kitchen & Appliances
      case 'refrigerator':
      case 'fridge':
      case 'microwave':
      case 'oven':
        return 'assets/icons/svg/eco.svg'; // Use eco for appliances
      
      // Health & Wellness
      case 'health':
      case 'heart_rate':
      case 'wellness':
        return 'assets/icons/svg/heart.svg';
      
      // Solar & Energy
      case 'solar':
      case 'sun':
      case 'solar_panel':
        return 'assets/icons/svg/sun.svg';
      case 'savings':
      case 'energy':
        return 'assets/icons/svg/savings_filled.svg';
      
      // Communication
      case 'chat':
      case 'communication':
      case 'intercom':
        return 'assets/icons/svg/chat.svg';
      
      // Air & Climate Extended
      case 'air':
      case 'air_purifier':
        return 'assets/icons/svg/air.svg';
      case 'cooling':
      case 'cooler':
        return 'assets/icons/svg/cool.svg';
      
      // Team/Group devices
      case 'team':
      case 'group':
      case 'multi_user':
        return 'assets/icons/svg/team.svg';
      
      // Help & Support
      case 'help':
      case 'support':
        return 'assets/icons/svg/help.svg';
      
      // Default fallback
      default:
        return 'assets/icons/svg/info.svg';
    }
  }

  /// Build device icon widget - tries SVG first, falls back to Material icon
  Widget _buildDeviceIcon(String deviceType, bool isOn) {
    final svgPath = _getDeviceSvgAsset(deviceType);
    final iconColor = isOn
        ? const Color.fromARGB(255, 29, 93, 202)
        : Theme.of(context).brightness == Brightness.dark 
            ? Colors.white.withOpacity(0.8)
            : const Color.fromARGB(255, 0, 0, 0);
    
    final iconSize = getProportionateScreenWidth(32);
    
    try {
      return SvgPicture.asset(
        svgPath,
        colorFilter: ColorFilter.mode(iconColor, BlendMode.srcIn),
        width: iconSize,
        height: iconSize,
        fit: BoxFit.contain,
      );
    } catch (e) {
      // Fallback to Material icon if SVG is not found or fails to load
      return Icon(
        _getDeviceIcon(deviceType),
        color: iconColor,
        size: iconSize,
      );
    }
  }

  /// Build device icon widget specifically for UserAddedDevice - uses the device's actual icon
  Widget _buildUserDeviceIcon(UserAddedDevice userDevice) {
    // Make icon colors darker and more vibrant
    final baseColor = userDevice.device.color;
    final iconColor = userDevice.device.isOn
        ? Color.fromARGB(
            255,
            (baseColor.red * 0.8).clamp(0, 255).toInt(),
            (baseColor.green * 0.8).clamp(0, 255).toInt(),
            (baseColor.blue * 0.8).clamp(0, 255).toInt(),
          )
        : Color.fromARGB(
            255,
            (baseColor.red * 0.6).clamp(0, 255).toInt(),
            (baseColor.green * 0.6).clamp(0, 255).toInt(),
            (baseColor.blue * 0.6).clamp(0, 255).toInt(),
          );
    
    final iconSize = getProportionateScreenWidth(28); // Slightly smaller for better appearance
    
    // Use the device's actual icon from house_structure.dart
    return Icon(
      userDevice.device.icon,
      color: iconColor,
      size: iconSize,
    );
  }

  /// Get Material icon for device type when SVG is not available
  IconData _getDeviceIcon(String deviceType) {
    switch (deviceType.toLowerCase()) {
      // Lighting devices
      case 'light':
      case 'bulb':
      case 'lamp':
      case 'lighting':
        return Icons.lightbulb_outline;
      
      // Climate control
      case 'fan':
      case 'ceiling_fan':
      case 'ventilation':
        return Icons.air;
      case 'ac':
      case 'air_conditioner':
      case 'hvac':
      case 'climate':
        return Icons.ac_unit;
      
      // Audio/Video devices
      case 'speaker':
      case 'audio':
      case 'sound_system':
        return Icons.speaker;
      case 'tv':
      case 'television':
      case 'smart_tv':
      case 'entertainment':
        return Icons.tv;
      
      // Security & Monitoring
      case 'camera':
      case 'security':
      case 'cctv':
      case 'surveillance':
        return Icons.videocam_outlined;
      
      // Sensors & IoT
      case 'sensor':
      case 'temperature':
      case 'humidity':
        return Icons.sensors;
      case 'motion':
        return Icons.motion_photos_on;
      case 'door':
        return Icons.door_front_door_outlined;
      case 'window':
        return Icons.window_outlined;
      
      // Switches & Controls
      case 'switch':
      case 'outlet':
      case 'plug':
      case 'smart_switch':
        return Icons.power_settings_new;
      
      // Smart Home Appliances
      case 'robot':
      case 'vacuum':
      case 'cleaner':
        return Icons.smart_toy_outlined;
      
      // Kitchen & Appliances
      case 'refrigerator':
      case 'fridge':
        return Icons.kitchen_outlined;
      case 'microwave':
        return Icons.microwave_outlined;
      case 'oven':
        return Icons.kitchen_outlined;
      
      // Health & Wellness
      case 'health':
      case 'heart_rate':
      case 'wellness':
        return Icons.favorite_outline;
      
      // Solar & Energy
      case 'solar':
      case 'sun':
      case 'solar_panel':
        return Icons.wb_sunny_outlined;
      case 'savings':
      case 'energy':
        return Icons.energy_savings_leaf;
      
      // Communication
      case 'chat':
      case 'communication':
      case 'intercom':
        return Icons.chat_outlined;
      
      // Air & Climate Extended
      case 'air':
      case 'air_purifier':
        return Icons.air_outlined;
      case 'cooling':
      case 'cooler':
        return Icons.ac_unit_outlined;
      
      // Team/Group devices
      case 'team':
      case 'group':
      case 'multi_user':
        return Icons.group_outlined;
      
      // Help & Support
      case 'help':
      case 'support':
        return Icons.help_outline;
      
      // Default fallback
      default:
        return Icons.device_unknown;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: getProportionateScreenWidth(7),
          vertical: getProportionateScreenHeight(7),
        ),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
        ),
        child: Column(
          children: [
            // Compact Environmental Data Row - Đầu tiên
            Container(
              margin: EdgeInsets.only(
                left: getProportionateScreenWidth(8),
                right: getProportionateScreenWidth(8),
                bottom: getProportionateScreenHeight(8),
              ),
              child: Row(
                children: [
                  // Compact Weather
                  Expanded(
                    flex: 1,
                    child: Container(
                      height: getProportionateScreenHeight(60),
                      child: WeatherContainer(
                          model: widget.model, isCompact: true),
                    ),
                  ),
                  SizedBox(width: getProportionateScreenWidth(8)),
                  // Compact Sensor Data
                  Expanded(
                    flex: 1,
                    child: Container(
                      height: getProportionateScreenHeight(60),
                      child: SensorDataContainer(
                          model: widget.model, isCompact: true),
                    ),
                  ),
                ],
              ),
            ),

            // Quick Controls Section - Thứ hai
            Container(
              margin: EdgeInsets.symmetric(
                horizontal: getProportionateScreenWidth(8),
                vertical: getProportionateScreenHeight(5),
              ),
              padding: EdgeInsets.all(getProportionateScreenWidth(16)),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Điều khiển nhanh',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF2D3748),
                        ),
                      ),
                      Row(
                        children: [
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: getProportionateScreenWidth(8),
                              vertical: getProportionateScreenHeight(4),
                            ),
                            decoration: BoxDecoration(
                              color: Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? const Color(0xFF6B73FF).withOpacity(0.2)
                                  : const Color(0xFF6B73FF).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${_userDevices.length} thiết bị',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF6B73FF),
                              ),
                            ),
                          ),
                          if (_userDevices.isNotEmpty) ...[
                            SizedBox(width: getProportionateScreenWidth(8)),
                            GestureDetector(
                              onTap: _showEditDevicesDialog,
                              child: Container(
                                padding: EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: Colors.orange.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  Icons.edit,
                                  size: 16,
                                  color: Colors.orange,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                  SizedBox(height: getProportionateScreenHeight(12)),
                  // User Added Devices - Dynamic Grid
                  if (_userDevices.isNotEmpty) ...[
                    ..._buildUserDevicesGrid(),
                  ] else ...[
                    // Empty state when no devices
                    Container(
                      height: getProportionateScreenHeight(120),
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.grey[300]!,
                          style: BorderStyle.solid,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.devices_other_outlined,
                            size: 32,
                            color: Colors.grey[500],
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Chưa có thiết bị nào',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey[600],
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Nhấn nút bên dưới để thêm thiết bị',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Add New Device - Prominent position
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: getProportionateScreenWidth(8),
                vertical: getProportionateScreenHeight(4),
              ),
              child: AddNewDevice(
                onDeviceAdded: (device, roomName, floorName) async {
                  final success = await _deviceManager.addDevice(
                    device: device,
                    roomName: roomName,
                    floorName: floorName,
                  );

                  if (success) {
                    await _loadUserDevices(); // Refresh the device list
                    context.showSuccessNotification(
                        'Đã thêm thiết bị "${device.name}" vào phần điều khiển nhanh');
                  }
                },
              ),
            ),

            // Energy Overview - New widget
            Container(
              margin: EdgeInsets.symmetric(
                horizontal: getProportionateScreenWidth(8),
                vertical: getProportionateScreenHeight(4),
              ),
              child: EnergyOverviewWidget(model: widget.model),
            ),

            // Navigation Buttons
            Container(
              margin: EdgeInsets.symmetric(
                horizontal: getProportionateScreenWidth(8),
                vertical: getProportionateScreenHeight(8),
              ),
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: getProportionateScreenHeight(45),
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.of(context)
                            .pushNamed(SetEventScreen.routeName);
                      },
                      icon: const Icon(Icons.schedule,
                          color: Colors.white, size: 18),
                      label: const Text(
                        'Thiết lập sự kiện',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 14),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6B73FF),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: getProportionateScreenHeight(8)),
                  SizedBox(
                    width: double.infinity,
                    height: getProportionateScreenHeight(45),
                    child: ElevatedButton.icon(
                      onPressed: () {
                        // Navigation removed - functionality disabled
                      },
                      icon: const Icon(Icons.tv, color: Colors.white, size: 18),
                      label: const Text(
                        'Smart TV',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 14),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4CAF50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build grid of user-added devices
  List<Widget> _buildUserDevicesGrid() {
    List<Widget> deviceRows = [];

    // Group devices in pairs for rows
    for (int i = 0; i < _userDevices.length; i += 2) {
      List<Widget> rowDevices = [];

      // First device in row
      rowDevices.add(Expanded(
        child: Container(
          height: getProportionateScreenHeight(105),
          child: _buildUserDeviceCard(_userDevices[i]),
        ),
      ));

      // Second device in row (if exists)
      if (i + 1 < _userDevices.length) {
        rowDevices.add(SizedBox(width: getProportionateScreenWidth(8)));
        rowDevices.add(Expanded(
          child: Container(
            height: getProportionateScreenHeight(105),
            child: _buildUserDeviceCard(_userDevices[i + 1]),
          ),
        ));
      } else {
        // Add empty space if only one device in row
        rowDevices.add(SizedBox(width: getProportionateScreenWidth(8)));
        rowDevices.add(Expanded(child: Container()));
      }

      deviceRows.add(Row(children: rowDevices));

      // Add spacing between rows (except for last row)
      if (i + 2 < _userDevices.length) {
        deviceRows.add(SizedBox(height: getProportionateScreenHeight(8)));
      }
    }

    return deviceRows;
  }

  /// Build a device card that looks exactly like DarkContainer
  Widget _buildUserDeviceCard(UserAddedDevice userDevice) {
    return InkWell(
      onTap: () async {
        // Toggle device state
        final newState = !userDevice.device.isOn;
        final success = await _deviceManager.updateDeviceState(
          userDevice.device.name,
          newState,
        );

        if (success) {
          await _loadUserDevices();
        }
      },
      child: Container(
        width: getProportionateScreenWidth(140),
        height: getProportionateScreenHeight(140),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: userDevice.device.isOn
              ? (Theme.of(context).brightness == Brightness.dark
                  ? const Color(0xFF2D3748)
                  : const Color.fromARGB(255, 182, 174, 255))
              : Theme.of(context).cardColor,
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.black.withOpacity(0.3)
                  : Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: getProportionateScreenWidth(12), // Slightly more horizontal padding
            vertical: getProportionateScreenHeight(8), // Slightly more vertical padding
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: 45, // Slightly smaller
                    height: 45,
                    decoration: BoxDecoration(
                      color: userDevice.device.isOn
                          ? userDevice.device.color.withOpacity(0.15) // Use device color with transparency
                          : (Theme.of(context).brightness == Brightness.dark
                              ? const Color(0xFF1A202C)
                              : Colors.grey.withOpacity(0.1)),
                      borderRadius: BorderRadius.circular(22.5), // More standard circular border
                    ),
                    child: _buildUserDeviceIcon(userDevice),
                  ),
                  // Delete button (instead of star)
                  GestureDetector(
                    onTap: () => _deleteUserDevice(userDevice),
                    child: Icon(
                      Icons.delete_outline,
                      color: Colors.red.withOpacity(0.7),
                      size: 20,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    userDevice.device.name,
                    textAlign: TextAlign.left,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: userDevice.device.isOn
                          ? (Theme.of(context).brightness == Brightness.dark
                              ? Colors.white
                              : Colors.white)
                          : Theme.of(context).textTheme.bodyLarge!.color,
                      fontSize: 13, // Smaller font size for compactness
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.2,
                      height: 1.2,
                    ),
                  ),
                  SizedBox(height: 2), // Reduce spacing
                  Text(
                    '${userDevice.roomName}',
                    textAlign: TextAlign.left,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        color: userDevice.device.isOn
                            ? Colors.white.withOpacity(0.8)
                            : Theme.of(context).textTheme.bodySmall!.color,
                        fontSize: 10, // Smaller room name
                        letterSpacing: -0.1,
                        fontWeight: FontWeight.w400,
                        height: 1.2),
                  ),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    userDevice.device.isOn ? 'Bật' : 'Tắt',
                    textAlign: TextAlign.left,
                    style: TextStyle(
                      color: userDevice.device.isOn
                          ? Colors.white
                          : Theme.of(context).textTheme.bodyMedium!.color,
                      fontSize: 11, // Smaller status text
                      fontWeight: FontWeight.w500,
                      letterSpacing: -0.1,
                    ),
                  ),
                  GestureDetector(
                    onTap: () async {
                      // Toggle device state
                      final newState = !userDevice.device.isOn;
                      final success = await _deviceManager.updateDeviceState(
                        userDevice.device.name,
                        newState,
                      );

                      if (success) {
                        await _loadUserDevices();
                      }
                    },
                    child: Container(
                      width: 48,
                      height: 25.6,
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        color: userDevice.device.isOn
                            ? const Color.fromARGB(255, 66, 135, 255)
                            : const Color(0xffd6d6d6),
                      ),
                      child: Row(
                        children: [
                          userDevice.device.isOn
                              ? const Spacer()
                              : const SizedBox(),
                          Container(
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(50),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Delete user device with confirmation
  Future<void> _deleteUserDevice(UserAddedDevice userDevice) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Xóa thiết bị'),
        content: Text(
            'Bạn có chắc muốn xóa thiết bị "${userDevice.device.name}" khỏi điều khiển nhanh?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('Xóa', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final success = await _deviceManager.removeDevice(userDevice.device.name);
      if (success) {
        await _loadUserDevices();
        context.showWarningNotification('Đã xóa thiết bị "${userDevice.device.name}"');
      }
    }
  }

  /// Show edit devices dialog
  void _showEditDevicesDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Quản lý thiết bị'),
        content: Container(
          width: double.maxFinite,
          height: 400,
          child: _userDevices.isEmpty
              ? Center(
                  child: Text('Chưa có thiết bị nào'),
                )
              : ListView.builder(
                  itemCount: _userDevices.length,
                  itemBuilder: (context, index) {
                    final userDevice = _userDevices[index];
                    return Card(
                      margin: EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: Container(
                          padding: EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: userDevice.device.color.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            userDevice.device.icon,
                            color: userDevice.device.color,
                            size: 20,
                          ),
                        ),
                        title: Text(
                          userDevice.device.name,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        subtitle: Text(
                          '${userDevice.floorName} - ${userDevice.roomName}\n'
                          'Loại: ${userDevice.device.type}',
                          style: TextStyle(fontSize: 12),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Switch(
                              value: userDevice.device.isOn,
                              onChanged: (value) async {
                                final success =
                                    await _deviceManager.updateDeviceState(
                                  userDevice.device.name,
                                  value,
                                );
                                if (success) {
                                  await _loadUserDevices();
                                }
                              },
                              activeColor: userDevice.device.color,
                            ),
                            IconButton(
                              icon: Icon(Icons.delete,
                                  color: Colors.red, size: 20),
                              onPressed: () async {
                                Navigator.of(context)
                                    .pop(); // Close dialog first
                                await _deleteUserDevice(userDevice);
                              },
                            ),
                          ],
                        ),
                        isThreeLine: true,
                      ),
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Đóng'),
          ),
          if (_userDevices.isNotEmpty)
            TextButton(
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text('Xóa tất cả'),
                    content: Text('Bạn có chắc muốn xóa tất cả thiết bị?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        child: Text('Hủy'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        child: Text('Xóa tất cả',
                            style: TextStyle(color: Colors.red)),
                      ),
                    ],
                  ),
                );

                if (confirm == true) {
                  await _deviceManager.clearAllDevices();
                  await _loadUserDevices();
                  Navigator.of(context).pop(); // Close edit dialog
                  context.showWarningNotification('Đã xóa tất cả thiết bị');
                }
              },
              child: Text('Xóa tất cả', style: TextStyle(color: Colors.red)),
            ),
        ],
      ),
    );
  }
}
