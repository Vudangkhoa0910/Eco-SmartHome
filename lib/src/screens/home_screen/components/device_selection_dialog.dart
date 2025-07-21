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
          height: getProportionateScreenHeight(550),
          padding: EdgeInsets.all(getProportionateScreenWidth(20)),
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
                          fontSize: 20,
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
                SizedBox(height: getProportionateScreenHeight(15)),

                // Step 1: Location Selection
                _buildStepHeader(1, 'Chọn vị trí', true),
                SizedBox(height: getProportionateScreenHeight(10)),

                // Floor Selection
                _buildDropdown(
                  label: 'Tầng/Khu vực',
                  value: selectedFloor,
                  hint: 'Chọn tầng/khu vực',
                  items: floors
                      .map((floor) => DropdownMenuItem<String>(
                            value: floor.name,
                            child: Text(floor.name),
                          ))
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedFloor = value;
                      selectedRoom = null;
                      selectedDeviceType = null;
                      deviceNameController.clear();
                    });
                  },
                ),

                SizedBox(height: getProportionateScreenHeight(8)),

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
                                child: Text(room.name),
                              ))
                          .toList()
                      : [],
                  onChanged: selectedFloor != null
                      ? (value) {
                          setState(() {
                            selectedRoom = value;
                            selectedDeviceType = null;
                            deviceNameController.clear();
                          });
                        }
                      : null,
                ),

                SizedBox(height: getProportionateScreenHeight(15)),

                // Step 2: Device Type Selection
                _buildStepHeader(2, 'Chọn loại thiết bị', selectedRoom != null),
                if (selectedRoom != null) ...[
                  SizedBox(height: getProportionateScreenHeight(5)),
                  Text(
                    'Các loại thiết bị có sẵn trong ${selectedRoom}:',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
                SizedBox(height: getProportionateScreenHeight(10)),

                Container(
                  height: getProportionateScreenHeight(110),
                  child: selectedRoom != null
                      ? () {
                          final availableTypes =
                              _getAvailableDeviceTypesForRoom();
                          if (availableTypes.isEmpty) {
                            return _buildDisabledSection(
                                'Không có thiết bị nào trong phòng này');
                          }
                          return GridView.count(
                            crossAxisCount: 4,
                            mainAxisSpacing: 8,
                            crossAxisSpacing: 4,
                            childAspectRatio: 0.85,
                            children: availableTypes.map((deviceType) {
                              if (availableDeviceTypes
                                  .containsKey(deviceType)) {
                                return _buildDeviceTypeCard(deviceType,
                                    availableDeviceTypes[deviceType]!);
                              }
                              return Container(); // Fallback for unknown device types
                            }).toList(),
                          );
                        }()
                      : _buildDisabledSection(
                          'Chọn vị trí trước để hiển thị thiết bị'),
                ),

                SizedBox(height: getProportionateScreenHeight(15)),

                // Step 3: Device Name Input
                _buildStepHeader(
                    3, 'Đặt tên thiết bị', selectedDeviceType != null),
                SizedBox(height: getProportionateScreenHeight(10)),

                TextField(
                  controller: deviceNameController,
                  enabled: selectedDeviceType != null,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  decoration: InputDecoration(
                    hintText: selectedDeviceType != null
                        ? 'Nhập tên thiết bị...'
                        : 'Chọn loại thiết bị trước',
                    hintStyle: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                    filled: true,
                    fillColor: selectedDeviceType != null 
                        ? Colors.white 
                        : Colors.grey[50],
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

                SizedBox(height: getProportionateScreenHeight(20)),

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

  // Get available device types for selected room
  List<String> _getAvailableDeviceTypesForRoom() {
    if (selectedFloor == null || selectedRoom == null) {
      return [];
    }

    final floors = HouseData.getHouseStructure();
    final floor = floors.firstWhere((f) => f.name == selectedFloor);
    final room = floor.rooms.firstWhere((r) => r.name == selectedRoom);

    // Get unique device types from the selected room
    final Set<String> roomDeviceTypes =
        room.devices.map((device) => device.type).toSet();

    return roomDeviceTypes.toList();
  }

  // Get count of each device type in selected room
  Map<String, int> _getDeviceTypeCountInRoom() {
    if (selectedFloor == null || selectedRoom == null) {
      return {};
    }

    final floors = HouseData.getHouseStructure();
    final floor = floors.firstWhere((f) => f.name == selectedFloor);
    final room = floor.rooms.firstWhere((r) => r.name == selectedRoom);

    final Map<String, int> deviceCount = {};
    for (final device in room.devices) {
      deviceCount[device.type] = (deviceCount[device.type] ?? 0) + 1;
    }

    return deviceCount;
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
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
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
                  child: Container(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      item.child is Text 
                          ? (item.child as Text).data ?? ''
                          : item.value ?? '',
                      style: TextStyle(
                        color: Colors.black87,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                );
              }).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDeviceTypeCard(
      String deviceType, Map<String, dynamic> deviceInfo) {
    final isSelected = selectedDeviceType == deviceType;
    final deviceCounts = _getDeviceTypeCountInRoom();
    final count = deviceCounts[deviceType] ?? 0;

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedDeviceType = deviceType;
          deviceNameController.text = deviceInfo['name'];
        });
      },
      child: Container(
        padding: EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: isSelected
              ? deviceInfo['color'].withOpacity(0.2)
              : Colors.grey.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? deviceInfo['color'] : Colors.transparent,
            width: 2,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              deviceInfo['icon'],
              color: isSelected ? deviceInfo['color'] : Colors.grey,
              size: 18,
            ),
            SizedBox(height: 2),
            Text(
              _getShortDeviceName(deviceType),
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w600,
                color: isSelected ? deviceInfo['color'] : Colors.grey[600],
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (count > 0) ...[
              SizedBox(height: 1),
              Text(
                '($count có sẵn)',
                style: TextStyle(
                  fontSize: 7,
                  color: isSelected ? deviceInfo['color'] : Colors.grey[500],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
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
    return selectedDeviceType != null &&
        deviceNameController.text.isNotEmpty &&
        selectedFloor != null &&
        selectedRoom != null;
  }

  String _getShortDeviceName(String deviceType) {
    switch (deviceType) {
      case 'light':
        return 'Đèn';
      case 'gate':
        return 'Cổng';
      case 'awning':
        return 'Mái che';
      case 'sprinkler':
        return 'Tưới';
      case 'ac':
        return 'Điều hòa';
      case 'speaker':
        return 'Loa';
      case 'fan':
        return 'Quạt';
      case 'tv':
        return 'TV';
      case 'camera':
        return 'Camera';
      case 'sensor':
        return 'Cảm biến';
      case 'switch':
        return 'Công tắc';
      default:
        return deviceType.toUpperCase();
    }
  }

  void _addDevice() {
    if (!_canAddDevice()) return;

    final deviceInfo = availableDeviceTypes[selectedDeviceType]!;

    // Generate MQTT topic based on device name
    final deviceNameSlug = deviceNameController.text
        .toLowerCase()
        .replaceAll(' ', '_')
        .replaceAll(RegExp(r'[^\w_]'), '');

    final mqttTopic = '${deviceInfo['mqttTopicPrefix']}$deviceNameSlug';

    final newDevice = SmartDevice(
      name: deviceNameController.text,
      type: selectedDeviceType!,
      isOn: false,
      icon: deviceInfo['icon'],
      mqttTopic: mqttTopic,
      color: deviceInfo['color'],
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
