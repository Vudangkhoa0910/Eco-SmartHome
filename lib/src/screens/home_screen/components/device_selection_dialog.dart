import 'package:flutter/material.dart';
import 'package:smart_home/config/size_config.dart';
import 'package:smart_home/domain/entities/house_structure.dart';

class DeviceSelectionDialog extends StatefulWidget {
  final Function(SmartDevice device, String roomName, String floorName)
      onDeviceSelected;

  const DeviceSelectionDialog({
    Key? key,
    required this.onDeviceSelected,
  }) : super(key: key);

  @override
  _DeviceSelectionDialogState createState() => _DeviceSelectionDialogState();
}

class _DeviceSelectionDialogState extends State<DeviceSelectionDialog> {
  String? selectedFloor;
  String? selectedRoom;
  String? selectedDeviceType;
  final TextEditingController deviceNameController = TextEditingController();

  // Available device types - All existing device types from house_structure.dart
  final Map<String, Map<String, dynamic>> availableDeviceTypes = {
    'light': {
      'name': 'Đèn LED thông minh',
      'icon': Icons.lightbulb_outline,
      'color': Colors.amber,
      'mqttTopicPrefix': 'khoasmarthome/',
      'svgAsset': 'assets/icons/svg/light.svg',
    },
    'gate': {
      'name': 'Cổng tự động',
      'icon': Icons.garage_outlined,
      'color': Colors.brown,
      'mqttTopicPrefix': 'khoasmarthome/',
      'svgAsset': 'assets/icons/svg/light.svg', // Use light icon as fallback
    },
    'awning': {
      'name': 'Mái che tự động',
      'icon': Icons.local_parking,
      'color': Colors.brown,
      'mqttTopicPrefix': 'khoasmarthome/',
      'svgAsset': 'assets/icons/svg/light.svg', // Use light icon as fallback
    },
    'sprinkler': {
      'name': 'Hệ thống tưới',
      'icon': Icons.water_drop,
      'color': Colors.blue,
      'mqttTopicPrefix': 'khoasmarthome/',
      'svgAsset': 'assets/icons/svg/light.svg', // Use light icon as fallback
    },
    'ac': {
      'name': 'Điều hòa',
      'icon': Icons.ac_unit,
      'color': Colors.cyan,
      'mqttTopicPrefix': 'khoasmarthome/',
      'svgAsset': 'assets/icons/svg/ac.svg',
    },
    'speaker': {
      'name': 'Loa thông minh',
      'icon': Icons.speaker,
      'color': Colors.purple,
      'mqttTopicPrefix': 'khoasmarthome/',
      'svgAsset': 'assets/icons/svg/speaker.svg',
    },
    'fan': {
      'name': 'Quạt điều hòa',
      'icon': Icons.air,
      'color': Colors.blue,
      'mqttTopicPrefix': 'khoasmarthome/',
      'svgAsset': 'assets/icons/svg/fan.svg',
    },
    'tv': {
      'name': 'TV thông minh',
      'icon': Icons.tv,
      'color': Colors.black87,
      'mqttTopicPrefix': 'khoasmarthome/',
      'svgAsset': 'assets/icons/svg/music.svg', // Use music icon for TV
    },
    'camera': {
      'name': 'Camera an ninh',
      'icon': Icons.videocam,
      'color': Colors.grey,
      'mqttTopicPrefix': 'khoasmarthome/',
      'svgAsset': 'assets/icons/svg/profile.svg', // Use profile icon for camera
    },
    'sensor': {
      'name': 'Cảm biến thông minh',
      'icon': Icons.sensors,
      'color': Colors.green,
      'mqttTopicPrefix': 'khoasmarthome/',
      'svgAsset': 'assets/icons/svg/eco.svg', // Use eco icon for sensors
    },
    'switch': {
      'name': 'Công tắc thông minh',
      'icon': Icons.toggle_on,
      'color': Colors.orange,
      'mqttTopicPrefix': 'khoasmarthome/',
      'svgAsset': 'assets/icons/svg/light.svg', // Use light icon as fallback
    },
  };

  @override
  Widget build(BuildContext context) {
    final floors = HouseData.getHouseStructure();

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Material(
        borderRadius: BorderRadius.circular(20),
        child: Container(
          width: getProportionateScreenWidth(380),
          height: getProportionateScreenHeight(490),
          padding: EdgeInsets.all(getProportionateScreenWidth(16)),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        'Thêm thiết bị mới',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: Icon(Icons.close),
                    ),
                  ],
                ),
                SizedBox(height: getProportionateScreenHeight(6)),

                // Step 1: Location Selection
                _buildStepHeader(1, 'Chọn vị trí', true),
                SizedBox(height: getProportionateScreenHeight(6)),

                // Floor Selection
                _buildDropdown(
                  label: 'Tầng/Khu vực',
                  value: selectedFloor,
                  hint: 'Chọn tầng/khu vực',
                  items: floors
                      .map((floor) => DropdownMenuItem<String>(
                            value: floor.name,
                            child: Text(
                              floor.name,
                              style: TextStyle(
                                color: Colors.black87,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ))
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedFloor = value;
                      selectedRoom = null;
                      selectedDevice = null; // Reset selected device when floor changes
                      selectedDeviceType = null;
                      deviceNameController.clear();
                    });
                  },
                ),

                SizedBox(height: getProportionateScreenHeight(6)),

                // Room Selection
                _buildDropdown(
                  label: 'Phòng',
                  value: selectedRoom,
                  hint: 'Chọn phòng',
                  items: selectedFloor != null
                      ? floors
                          .firstWhere((floor) => floor.name == selectedFloor)
                          .rooms
                          .map((room) => DropdownMenuItem<String>(
                                value: room.name,
                                child: Text(
                                  room.name,
                                  style: TextStyle(
                                    color: Colors.black87,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ))
                          .toList()
                      : [],
                  onChanged: selectedFloor != null
                      ? (value) {
                          setState(() {
                            selectedRoom = value;
                            selectedDevice = null; // Reset selected device when room changes
                            selectedDeviceType = null;
                            deviceNameController.clear();
                          });
                        }
                      : null,
                ),

                SizedBox(height: getProportionateScreenHeight(6)),

                // Step 2: Device Selection from Available Devices
                _buildStepHeader(
                    2, 'Chọn thiết bị có sẵn', selectedRoom != null),
                SizedBox(height: getProportionateScreenHeight(6)),

                Container(
                  height: getProportionateScreenHeight(60),
                  child: selectedRoom != null
                      ? () {
                          final availableDevices =
                              _getAvailableDevicesForRoom();
                          if (availableDevices.isEmpty) {
                            return _buildDisabledSection(
                                'Không có thiết bị nào trong phòng này');
                          }
                          return _buildDeviceDropdown(availableDevices);
                        }()
                      : _buildDisabledSection(
                          'Chọn vị trí trước để hiển thị thiết bị'),
                ),

                SizedBox(height: getProportionateScreenHeight(6)),

                // Step 3: Device Name Confirmation
                _buildStepHeader(
                    3, 'Xác nhận thông tin thiết bị', selectedDevice != null),
                SizedBox(height: getProportionateScreenHeight(6)),

                TextField(
                  controller: deviceNameController,
                  enabled: selectedDevice != null,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Tên thiết bị',
                    hintText: selectedDevice != null
                        ? 'Có thể đổi tên thiết bị...'
                        : 'Chọn thiết bị trước',
                    hintStyle: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                    filled: true,
                    fillColor:
                        selectedDevice != null ? Colors.white : Colors.grey[50],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(
                        color: Colors.grey[300]!,
                        width: 1,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(
                        color: Colors.grey[300]!,
                        width: 1,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(
                        color: Color(0xFF6B73FF),
                        width: 2,
                      ),
                    ),
                    disabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(
                        color: Colors.grey[200]!,
                        width: 1,
                      ),
                    ),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: getProportionateScreenWidth(16),
                      vertical: getProportionateScreenHeight(14),
                    ),
                  ),
                ),

                if (selectedDevice != null) ...[
                  SizedBox(height: getProportionateScreenHeight(8)),
                  Container(
                    padding: EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.blue.withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Text(
                          'Loại: ',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[600],
                          ),
                        ),
                        Text(
                          _getDeviceTypeName(selectedDevice!.type),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                SizedBox(height: getProportionateScreenHeight(10)),

                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: Text(
                          'Hủy',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.grey[700],
                          side: BorderSide(
                            color: Colors.grey[300]!,
                            width: 1.5,
                          ),
                          padding: EdgeInsets.symmetric(
                            vertical: getProportionateScreenHeight(14),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: getProportionateScreenWidth(12)),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _canAddDevice() ? _addDevice : null,
                        child: Text(
                          'Thêm thiết bị',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _canAddDevice()
                              ? Color(0xFF6B73FF)
                              : Colors.grey[400],
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(
                            vertical: getProportionateScreenHeight(14),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: _canAddDevice() ? 2 : 0,
                          shadowColor: Color(0xFF6B73FF).withOpacity(0.3),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Get available devices for selected room
  List<SmartDevice> _getAvailableDevicesForRoom() {
    if (selectedFloor == null || selectedRoom == null) {
      return [];
    }

    final floors = HouseData.getHouseStructure();
    final floor = floors.firstWhere((f) => f.name == selectedFloor);
    final room = floor.rooms.firstWhere((r) => r.name == selectedRoom);

    // Return all devices from the selected room
    return room.devices;
  }

  SmartDevice? selectedDevice;

  Widget _buildDeviceDropdown(List<SmartDevice> availableDevices) {
    // Only use selectedDevice.name if the device exists in current room
    final validSelectedDevice = selectedDevice != null && 
        availableDevices.any((device) => device.name == selectedDevice!.name) 
        ? selectedDevice!.name 
        : null;
        
    return _buildDropdown(
      label: 'Thiết bị',
      value: validSelectedDevice,
      hint: 'Chọn thiết bị có sẵn',
      items: availableDevices
          .map((device) => DropdownMenuItem<String>(
                value: device.name,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color: device.color.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(3),
                      ),
                      child: Icon(
                        device.icon,
                        color: device.color,
                        size: 9,
                      ),
                    ),
                    SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        '${device.name} (${_getDeviceTypeName(device.type)})',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Colors.black87,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                  ],
                ),
              ))
          .toList(),
      onChanged: (deviceName) {
        if (deviceName != null) {
          final device = availableDevices.firstWhere(
            (d) => d.name == deviceName,
          );
          setState(() {
            selectedDevice = device;
            selectedDeviceType = device.type;
            deviceNameController.text = device.name;
          });
        }
      },
    );
  }

  String _getDeviceTypeName(String deviceType) {
    switch (deviceType) {
      case 'light':
        return 'Đèn LED';
      case 'gate':
        return 'Cổng tự động';
      case 'awning':
        return 'Mái che';
      case 'sprinkler':
        return 'Hệ thống tưới';
      case 'ac':
        return 'Điều hòa';
      case 'speaker':
        return 'Loa thông minh';
      case 'fan':
        return 'Quạt';
      case 'tv':
        return 'TV thông minh';
      case 'camera':
        return 'Camera an ninh';
      case 'sensor':
        return 'Cảm biến';
      case 'switch':
        return 'Công tắc';
      default:
        return deviceType;
    }
  }

  Widget _buildStepHeader(int step, String title, bool isActive) {
    return Row(
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isActive ? Colors.blue[600] : Colors.grey[400],
          ),
          child: Center(
            child: Text(
              '$step',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: isActive ? Colors.blue[700] : Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildDropdown({
    required String label,
    required String? value,
    required String hint,
    required List<DropdownMenuItem<String>> items,
    required ValueChanged<String?>? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 1),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(
              color: value != null ? Color(0xFF6B73FF) : Colors.grey[300]!,
              width: value != null ? 2 : 1,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              hint: Text(
                hint,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
              isExpanded: true,
              icon: Icon(
                Icons.keyboard_arrow_down,
                color: value != null ? Color(0xFF6B73FF) : Colors.grey[600],
              ),
              style: TextStyle(
                color: Colors.black87,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              dropdownColor: Colors.white,
              borderRadius: BorderRadius.circular(12),
              items: items.map((item) {
                return DropdownMenuItem<String>(
                  value: item.value,
                  child: item
                      .child, // Use the widget directly without extra padding
                );
              }).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDisabledSection(String message) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Text(
          message,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 12,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  bool _canAddDevice() {
    return selectedDevice != null &&
        deviceNameController.text.isNotEmpty &&
        selectedFloor != null &&
        selectedRoom != null;
  }

  void _addDevice() {
    if (!_canAddDevice() || selectedDevice == null) return;

    // Create a copy of the selected device with custom name if changed
    final newDevice = SmartDevice(
      name: deviceNameController.text.trim(),
      type: selectedDevice!.type,
      isOn: false, // Start with device off
      icon: selectedDevice!.icon,
      mqttTopic: selectedDevice!.mqttTopic, // Use the original MQTT topic
      color: selectedDevice!.color,
    );

    widget.onDeviceSelected(newDevice, selectedRoom!, selectedFloor!);
    Navigator.of(context).pop();
  }

  @override
  void dispose() {
    deviceNameController.dispose();
    super.dispose();
  }
}
