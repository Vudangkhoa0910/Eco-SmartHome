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

  /// Get SVG asset path for device type - consistent with default devices
  String _getDeviceSvgAsset(String deviceType) {
    switch (deviceType.toLowerCase()) {
      case 'light':
        return 'assets/icons/svg/light.svg';
      case 'fan':
        return 'assets/icons/svg/fan.svg';
      case 'ac':
        return 'assets/icons/svg/ac.svg';
      case 'speaker':
        return 'assets/icons/svg/speaker.svg';
      case 'tv':
        return 'assets/icons/svg/music.svg'; // Use music icon for TV/entertainment
      case 'camera':
        return 'assets/icons/svg/profile.svg'; // Use profile icon for camera/security
      case 'sensor':
        return 'assets/icons/svg/eco.svg'; // Use eco icon for sensors
      case 'switch':
        return 'assets/icons/svg/star.svg'; // Use star icon for switches
      default:
        return 'assets/icons/svg/info.svg'; // Default fallback
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
            horizontal: getProportionateScreenWidth(10),
            vertical: getProportionateScreenHeight(6),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: userDevice.device.isOn
                          ? (Theme.of(context).brightness == Brightness.dark
                              ? const Color.fromARGB(255, 254, 254, 254)
                              : const Color.fromARGB(255, 182, 174, 255))
                          : (Theme.of(context).brightness == Brightness.dark
                              ? const Color(0xFF1A202C)
                              : const Color.fromARGB(255, 255, 255, 255)),
                      borderRadius:
                          const BorderRadius.all(Radius.elliptical(45, 45)),
                    ),
                    child: SvgPicture.asset(
                      _getDeviceSvgAsset(userDevice.device.type),
                      color: userDevice.device.isOn
                          ? const Color.fromARGB(255, 29, 93, 202)
                          : const Color.fromARGB(255, 0, 0, 0),
                    ),
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
                    style: Theme.of(context).textTheme.displayMedium!.copyWith(
                          color: userDevice.device.isOn
                              ? (Theme.of(context).brightness == Brightness.dark
                                  ? Colors.white
                                  : Colors.white)
                              : Theme.of(context)
                                  .textTheme
                                  .displayMedium!
                                  .color,
                        ),
                  ),
                  Text(
                    '${userDevice.roomName}',
                    textAlign: TextAlign.left,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        color: userDevice.device.isOn
                            ? const Color.fromARGB(255, 255, 254, 254)
                            : Theme.of(context).textTheme.bodyMedium!.color,
                        fontSize: 13,
                        letterSpacing: 0,
                        fontWeight: FontWeight.normal,
                        height: 1.6),
                  ),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    userDevice.device.isOn ? 'On' : 'Off',
                    textAlign: TextAlign.left,
                    style: Theme.of(context).textTheme.displayMedium!.copyWith(
                          color: userDevice.device.isOn
                              ? Colors.white
                              : Colors.black,
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
