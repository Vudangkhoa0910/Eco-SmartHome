import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../service/device_state_service.dart';
import '../../../../service/device_manager_service.dart';
import '../../../../domain/entities/house_structure.dart';
import '../../../../view/home_screen_view_model.dart';

class ActiveDevicesWidget extends StatefulWidget {
  final HomeScreenViewModel model;
  
  const ActiveDevicesWidget({
    super.key, 
    required this.model,
  });

  @override
  State<ActiveDevicesWidget> createState() => _ActiveDevicesWidgetState();
}

class _ActiveDevicesWidgetState extends State<ActiveDevicesWidget> {
  Timer? _refreshTimer;
  StreamSubscription? _deviceStateSubscription;

  @override
  void initState() {
    super.initState();
    _setupRealTimeUpdates();
  }

  void _setupRealTimeUpdates() {
    // Set up a timer for periodic refresh
    _refreshTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (mounted) {
        setState(() {});
      }
    });

    // Listen to device state changes from the model
    widget.model.addListener(_onModelChanged);
  }

  void _onModelChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _deviceStateSubscription?.cancel();
    widget.model.removeListener(_onModelChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _getAllDevices(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E1E),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                ),
              ),
            ),
          );
        }

        if (snapshot.hasError) {
          return const SizedBox.shrink();
        }

        final allDevices = snapshot.data ?? [];
        final activeDevices = allDevices.where((device) => _getDeviceRealTimeState(device)).toList();

        if (activeDevices.isEmpty) {
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E1E),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.power_off,
                  color: Colors.grey[400],
                  size: 20,
                ),
                const SizedBox(width: 12),
                Text(
                  'Không có thiết bị nào đang hoạt động',
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          );
        }

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E1E),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.power_settings_new,
                    color: Colors.green,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Thiết bị đang hoạt động (${activeDevices.length})',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: activeDevices.map((device) => _buildActiveDeviceChip(device)).toList(),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildActiveDeviceChip(Map<String, dynamic> device) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.green.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _getDeviceIcon(device['type'] ?? ''),
            color: Colors.green,
            size: 16,
          ),
          const SizedBox(width: 6),
          Text(
            device['name'] ?? 'Thiết bị',
            style: const TextStyle(
              color: Colors.green,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getDeviceIcon(String deviceType) {
    switch (deviceType.toLowerCase()) {
      case 'light':
      case 'đèn':
        return Icons.lightbulb;
      case 'fan':
      case 'quạt':
        return Icons.air;
      case 'tv':
      case 'television':
        return Icons.tv;
      case 'air_conditioner':
      case 'điều hòa':
        return Icons.ac_unit;
      case 'door':
      case 'cửa':
        return Icons.door_front_door;
      case 'window':
      case 'cửa sổ':
        return Icons.window;
      case 'camera':
        return Icons.camera_alt;
      case 'sensor':
      case 'cảm biến':
        return Icons.sensors;
      default:
        return Icons.device_unknown;
    }
  }

  Future<List<Map<String, dynamic>>> _getAllDevices() async {
    final devices = <Map<String, dynamic>>[];
    
    // Get house structure devices
    final houseStructure = HouseData.getHouseStructure();
    for (final floor in houseStructure) {
      for (final room in floor.rooms) {
        for (final device in room.devices) {
          devices.add({
            'name': device.name,
            'type': device.type,
            'topic': device.mqttTopic,
            'isUserDevice': false,
          });
        }
      }
    }

    // Get user devices from DeviceManager and sync their state
    try {
      final deviceManager = DeviceManagerService();
      final userDevices = await deviceManager.getUserDevices();
      for (final userDevice in userDevices) {
        // Get real-time state for user device
        final realTimeState = _getUserDeviceRealTimeState(userDevice);
        
        devices.add({
          'name': userDevice.device.name,
          'type': userDevice.device.type,
          'topic': userDevice.device.mqttTopic,
          'isUserDevice': true,
          'realTimeState': realTimeState,
        });
      }
    } catch (e) {
      // Handle error silently
    }

    return devices;
  }

  bool _getDeviceRealTimeState(Map<String, dynamic> device) {
    // For user devices, use the cached real-time state
    if (device['isUserDevice'] == true && device.containsKey('realTimeState')) {
      return device['realTimeState'] as bool;
    }

    final topic = device['topic'] as String?;
    
    if (topic == null || topic.isEmpty) return false;

    // Use ViewModel state which is synchronized with room controls
    // Only include devices that actually exist in the ViewModel
    switch (topic) {
      case 'smart_home/living_room/light':
      case 'inside/living_room_light':
        return widget.model.isLivingRoomLightOn;
      case 'smart_home/living_room/fan':
      case 'inside/fan_living_room':
        return widget.model.isFanLivingRoomOn;
      case 'smart_home/living_room/air_conditioner':
      case 'inside/ac_living_room':
        return widget.model.isACLivingRoomOn;
      case 'smart_home/bedroom/light':
        return widget.model.isBedroomLightOn;
      case 'smart_home/bedroom1/air_conditioner':
      case 'inside/ac_bedroom1':
        return widget.model.isACBedroom1On;
      case 'smart_home/bedroom2/air_conditioner':
      case 'inside/ac_bedroom2':
        return widget.model.isACBedroom2On;
      case 'smart_home/kitchen/light':
        return widget.model.isKitchenLightOn;
      case 'smart_home/corner_bedroom/light':
        return widget.model.isCornerBedroomLightOn;
      case 'smart_home/yard_bedroom/light':
        return widget.model.isYardBedroomLightOn;
      case 'smart_home/worship_room/light':
        return widget.model.isWorshipRoomLightOn;
      case 'smart_home/hallway/light':
        return widget.model.isHallwayLightOn;
      case 'smart_home/balcony/light':
        return widget.model.isBalconyLightOn;
      // ESP32 outdoor devices - use DeviceStateService
      case 'khoasmarthome/led_gate':
        return widget.model.mqttServiceSimple.deviceStateService.getDeviceState('led_gate');
      case 'khoasmarthome/led_around':
        return widget.model.mqttServiceSimple.deviceStateService.getDeviceState('led_around');
      default:
        return false;
    }
  }

  /// Get real-time state for user devices using the same logic as room controls
  bool _getUserDeviceRealTimeState(UserAddedDevice userDevice) {
    final topic = userDevice.device.mqttTopic;
    
    if (topic.isEmpty) return userDevice.device.isOn;

    // Check if this is an indoor device (ESP32-S3)
    if (topic.startsWith('inside/')) {
      // Use ViewModel state for indoor devices (same as room controls)
      switch (topic) {
        case 'inside/kitchen_light':
          return widget.model.isKitchenLightOn;
        case 'inside/living_room_light':
          return widget.model.isLivingRoomLightOn;
        case 'inside/bedroom_light':
          return widget.model.isBedroomLightOn;
        case 'inside/corner_bedroom_light':
          return widget.model.isCornerBedroomLightOn;
        case 'inside/yard_bedroom_light':
          return widget.model.isYardBedroomLightOn;
        case 'inside/worship_room_light':
          return widget.model.isWorshipRoomLightOn;
        case 'inside/hallway_light':
          return widget.model.isHallwayLightOn;
        case 'inside/balcony_light':
          return widget.model.isBalconyLightOn;
        case 'inside/fan_living_room':
          return widget.model.isFanLivingRoomOn;
        case 'inside/ac_living_room':
          return widget.model.isACLivingRoomOn;
        case 'inside/ac_bedroom1':
          return widget.model.isACBedroom1On;
        case 'inside/ac_bedroom2':
          return widget.model.isACBedroom2On;
        default:
          return userDevice.device.isOn;
      }
    }

    // Check if this is an outdoor device (ESP32)
    switch (topic) {
      case 'khoasmarthome/led_gate':
        return widget.model.isLightOn; // LED Gate state
      case 'khoasmarthome/led_around':
        return widget.model.isACON; // LED Around state (using AC variable)
      case 'khoasmarthome/motor':
        return widget.model.currentGateLevel > 0; // Gate is open if level > 0
      default:
        // For custom user devices, use stored state
        return userDevice.device.isOn;
    }
  }
}
