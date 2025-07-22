import 'package:flutter/material.dart';
import 'dart:async';
import 'package:smart_home/config/size_config.dart';
import 'package:smart_home/domain/entities/house_structure.dart';
import 'package:smart_home/view/home_screen_view_model.dart';
import 'package:smart_home/provider/getit.dart';
import 'package:smart_home/service/mqtt_service.dart';
import 'package:smart_home/service/mqtt_service_simple.dart';
import 'package:smart_home/service/device_state_service.dart';
import 'package:smart_home/src/widgets/gate_device_control_widget.dart';

class HouseFloorScreen extends StatefulWidget {
  final HouseFloor floor;

  const HouseFloorScreen({
    Key? key,
    required this.floor,
  }) : super(key: key);

  @override
  State<HouseFloorScreen> createState() => _HouseFloorScreenState();
}

class _HouseFloorScreenState extends State<HouseFloorScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  String? _expandedRoomName;
  final HomeScreenViewModel _model = getIt<HomeScreenViewModel>();
  final MqttService _mqttService = getIt<MqttService>();
  final DeviceStateService _deviceStateService = DeviceStateService();

  late StreamSubscription _deviceStateSubscription;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    // Listen to device state changes
    _deviceStateSubscription = _deviceStateService.stateStream.listen((states) {
      if (mounted) {
        setState(() {
          // Trigger rebuild when device states change
        });
      }
    });

    // Request indoor device status sync when entering floor screen
    _requestIndoorDeviceStatusSync();
  }

  void _requestIndoorDeviceStatusSync() {
    // Get MQTT service and request indoor device status for real-time sync
    try {
      final MqttServiceSimple mqttService = getIt<MqttServiceSimple>();
      if (mqttService.isConnected) {
        mqttService.requestIndoorDeviceStatus();
        print('🏠 Requested indoor device status sync for ${widget.floor.name}');
      }
    } catch (e) {
      print('❌ Error requesting indoor device status sync: $e');
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _deviceStateSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.floor.name),
        backgroundColor: widget.floor.color.withOpacity(0.1),
        foregroundColor: widget.floor.color,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(getProportionateScreenWidth(16)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Floor Header - Compact
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(getProportionateScreenWidth(16)),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    widget.floor.color.withOpacity(0.2),
                    widget.floor.color.withOpacity(0.1),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(getProportionateScreenWidth(10)),
                    decoration: BoxDecoration(
                      color: widget.floor.color.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      widget.floor.icon,
                      color: widget.floor.color,
                      size: 28,
                    ),
                  ),
                  SizedBox(width: getProportionateScreenWidth(12)),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.floor.name,
                          style:
                              Theme.of(context).textTheme.titleLarge!.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: widget.floor.color,
                                    fontSize: 18,
                                  ),
                        ),
                        Text(
                          widget.floor.description,
                          style:
                              Theme.of(context).textTheme.bodyMedium!.copyWith(
                                    color: Colors.grey[600],
                                    fontSize: 13,
                                  ),
                        ),
                        Text(
                          '${widget.floor.rooms.length} khu vực • ${_getTotalDevices()} thiết bị',
                          style:
                              Theme.of(context).textTheme.bodySmall!.copyWith(
                                    color: widget.floor.color.withOpacity(0.8),
                                    fontSize: 11,
                                  ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: getProportionateScreenHeight(20)),

            Text(
              'Các khu vực',
              style: Theme.of(context).textTheme.titleMedium!.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
            ),

            SizedBox(height: getProportionateScreenHeight(12)),

            // Rooms List với khả năng expand
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: widget.floor.rooms.length,
              itemBuilder: (context, index) {
                final room = widget.floor.rooms[index];
                final isExpanded = _expandedRoomName == room.name;
                return _buildExpandableRoomCard(
                    context, room, isExpanded, index);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpandableRoomCard(
      BuildContext context, HouseRoom room, bool isExpanded, int index) {
    final activeDevices =
        room.devices.where((device) => _getDeviceState(device)).length;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: EdgeInsets.only(bottom: getProportionateScreenHeight(12)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: room.color.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
        border: Border.all(
          color: isExpanded
              ? room.color.withOpacity(0.5)
              : room.color.withOpacity(0.2),
          width: isExpanded ? 2 : 1,
        ),
      ),
      child: Column(
        children: [
          // Room Header - Clickable - Compact
          GestureDetector(
            onTap: () {
              setState(() {
                _expandedRoomName = isExpanded ? null : room.name;
              });
              if (isExpanded) {
                _animationController.reverse();
              } else {
                _animationController.forward();
              }
            },
            child: Container(
              padding: EdgeInsets.all(getProportionateScreenWidth(16)),
              child: Row(
                children: [
                  // Room Icon - Smaller
                  Container(
                    padding: EdgeInsets.all(getProportionateScreenWidth(8)),
                    decoration: BoxDecoration(
                      color: room.color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      room.icon,
                      color: room.color,
                      size: 20,
                    ),
                  ),

                  SizedBox(width: getProportionateScreenWidth(12)),

                  // Room Info - Compact
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          room.name,
                          style:
                              Theme.of(context).textTheme.titleMedium!.copyWith(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                        ),
                        Text(
                          room.description,
                          style:
                              Theme.of(context).textTheme.bodySmall!.copyWith(
                                    color: Colors.grey[600],
                                    fontSize: 12,
                                  ),
                        ),
                        SizedBox(height: getProportionateScreenHeight(4)),
                        Row(
                          children: [
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: getProportionateScreenWidth(6),
                                vertical: getProportionateScreenHeight(2),
                              ),
                              decoration: BoxDecoration(
                                color: activeDevices > 0
                                    ? Colors.green.withOpacity(0.1)
                                    : Colors.grey.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '$activeDevices/${room.devices.length} hoạt động',
                                style: TextStyle(
                                  color: activeDevices > 0
                                      ? Colors.green
                                      : Colors.grey,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            SizedBox(width: getProportionateScreenWidth(8)),
                            Text(
                              '${room.devices.length} thiết bị',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall!
                                  .copyWith(
                                    color: room.color.withOpacity(0.8),
                                    fontSize: 11,
                                  ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Expand/Collapse Icon - Smaller
                  AnimatedRotation(
                    turns: isExpanded ? 0.5 : 0.0,
                    duration: const Duration(milliseconds: 300),
                    child: Icon(
                      Icons.keyboard_arrow_down,
                      color: room.color,
                      size: 24,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Devices Section - Expandable
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            height: isExpanded ? null : 0,
            child: isExpanded
                ? _buildDevicesSection(room)
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _buildDevicesSection(HouseRoom room) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        getProportionateScreenWidth(16),
        0,
        getProportionateScreenWidth(16),
        getProportionateScreenWidth(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Divider(color: room.color.withOpacity(0.3)),
          SizedBox(height: getProportionateScreenHeight(10)),
          Text(
            'Thiết bị trong khu vực',
            style: Theme.of(context).textTheme.titleSmall!.copyWith(
                  fontWeight: FontWeight.w600,
                  color: room.color,
                  fontSize: 13,
                ),
          ),
          SizedBox(height: getProportionateScreenHeight(10)),

          // Devices Grid - Responsive & Compact
          _buildDevicesGrid(room),
        ],
      ),
    );
  }

  Widget _buildDevicesGrid(HouseRoom room) {
    // Tính toán số cột dựa trên số thiết bị để tối ưu hiển thị
    int crossAxisCount;
    if (room.devices.length <= 2) {
      crossAxisCount = room.devices.length;
    } else if (room.devices.length <= 4) {
      crossAxisCount = 2;
    } else {
      crossAxisCount = 3;
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: getProportionateScreenWidth(8),
        mainAxisSpacing: getProportionateScreenHeight(8),
        childAspectRatio: 1.0, // Làm vuông hơn để compact
      ),
      itemCount: room.devices.length,
      itemBuilder: (context, index) {
        final device = room.devices[index];
        return _buildDeviceButton(device, room.color);
      },
    );
  }

  Widget _buildDeviceButton(SmartDevice device, Color roomColor) {
    bool isControllable = _isDeviceControllable(device);
    bool currentState = _getDeviceState(device);

    // Special handling for gate/motor devices
    if (device.type == 'gate' || device.mqttTopic == 'khoasmarthome/motor') {
      return GateDeviceControlWidget(
        deviceName: device.name,
        deviceColor: device.color,
        onTap: () {
          // Optional: Still allow legacy toggle for compatibility
          if (isControllable) {
            _toggleDevice(device);
          }
        },
      );
    }

    return GestureDetector(
      onTap: isControllable ? () => _toggleDevice(device) : null,
      child: Container(
        padding: EdgeInsets.all(getProportionateScreenWidth(8)),
        decoration: BoxDecoration(
          color: currentState
              ? device.color.withOpacity(0.1)
              : Colors.grey.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: currentState
                ? device.color.withOpacity(0.5)
                : Colors.grey.withOpacity(0.3),
            width: currentState ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min, // Add this to prevent overflow
          children: [
            // Device Icon với hiệu ứng - Smaller
            Container(
              padding: EdgeInsets.all(
                  getProportionateScreenWidth(4)), // Reduced from 6
              decoration: BoxDecoration(
                color: currentState
                    ? device.color.withOpacity(0.2)
                    : Colors.grey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6), // Reduced from 8
              ),
              child: Icon(
                device.icon,
                color: currentState ? device.color : Colors.grey,
                size: 16, // Reduced from 18
              ),
            ),

            SizedBox(height: getProportionateScreenHeight(2)), // Reduced from 4

            // Device Name - Smaller
            Flexible(
              // Wrap with Flexible to prevent overflow
              child: Text(
                device.name,
                style: Theme.of(context).textTheme.bodySmall!.copyWith(
                      fontWeight: FontWeight.w600,
                      color: device
                          .textColor, // Sử dụng textColor thay vì logic điều kiện
                      fontSize: 11,
                    ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),

            SizedBox(height: getProportionateScreenHeight(1)), // Reduced from 2

            // Status Indicator - Smaller
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: getProportionateScreenWidth(3), // Reduced from 4
                vertical: getProportionateScreenHeight(0.5), // Reduced from 1
              ),
              decoration: BoxDecoration(
                color: isControllable
                    ? (currentState
                        ? Colors.green.withOpacity(0.2)
                        : Colors.grey.withOpacity(0.2))
                    : Colors.orange.withOpacity(0.2),
                borderRadius: BorderRadius.circular(3), // Reduced from 4
              ),
              child: Text(
                isControllable ? (currentState ? 'BẬT' : 'TẮT') : 'N/A',
                style: TextStyle(
                  color: isControllable
                      ? (currentState ? Colors.green : Colors.grey)
                      : Colors.orange,
                  fontSize: 7, // Reduced from 8
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _isDeviceControllable(SmartDevice device) {
    const controllableTopics = [
      // ESP32 Dev (outdoor) topics
      'khoasmarthome/led1',
      'khoasmarthome/led2',
      'khoasmarthome/motor',
      'khoasmarthome/led_gate', // Thêm đèn cổng từ ESP32
      'khoasmarthome/led_around', // Đèn sân

      // ESP32-S3 (indoor) topics - Floor 1
      'inside/kitchen_light', // Đèn bếp lớn
      'inside/living_room_light', // Đèn phòng khách
      'inside/bedroom_light', // Đèn phòng ngủ

      // ESP32-S3 (indoor) topics - Floor 2
      'inside/corner_bedroom_light', // Đèn phòng ngủ góc
      'inside/yard_bedroom_light', // Đèn phòng ngủ sân
      'inside/worship_room_light', // Đèn phòng thờ
      'inside/hallway_light', // Đèn hành lang
      'inside/balcony_light', // Đèn ban công lớn

      // Quạt và điều hòa
      'inside/fan_living_room', // Quạt tầng 1 phòng khách
      'inside/ac_living_room', // Điều hòa tầng 1 phòng khách
      'inside/ac_bedroom1', // Điều hòa tầng 2 phòng ngủ 1
      'inside/ac_bedroom2', // Điều hòa tầng 2 phòng ngủ 2

      // Legacy topics for compatibility
      'khoasmarthome/living_room_light', // Đèn phòng khách (legacy)
      'khoasmarthome/kitchen_light', // Đèn phòng bếp (legacy)
      'khoasmarthome/bedroom_light', // Đèn phòng ngủ (legacy)
      'khoasmarthome/stairs_light', // Đèn cầu thang (legacy)
      'khoasmarthome/bathroom_light', // Đèn phòng vệ sinh (legacy)
    ];
    return controllableTopics.contains(device.mqttTopic);
  }

  bool _getDeviceState(SmartDevice device) {
    // Extract device id from MQTT topic for device state service
    String deviceId = _extractDeviceId(device.mqttTopic);

    // 🔄 PRIORITY: Check DeviceStateService first for synchronized state from ESP32
    if (_deviceStateService.currentStates.containsKey(deviceId)) {
      bool syncedState = _deviceStateService.getDeviceState(deviceId);
      
      // 🔧 FIX: Đảo logic cho led_around vì ESP32 dùng logic âm (LOW=ON, HIGH=OFF)
      if (deviceId == 'led_around') {
        syncedState = !syncedState;  // Đảo ngược từ ESP32 logic
        print('🔧 LED Around UI State: ESP32=${!syncedState} -> UI=$syncedState');
      }
      
      print('🔄 Using synced state for $deviceId: $syncedState (from ESP32)');
      return syncedState;
    }

    // 🔄 FALLBACK: Use local ViewModel state if no synced state available
    print('📱 Using local state for $deviceId (fallback)');

    // For specific ESP32 devices, use device state service
    switch (device.mqttTopic) {
      case 'khoasmarthome/led_gate':
        return _deviceStateService.getDeviceState('led_gate');
      case 'khoasmarthome/led_around':
        return _deviceStateService.getDeviceState('led_around');
      case 'khoasmarthome/motor':
        // Sử dụng trạng thái cổng thực tế thay vì boolean
        return _model.currentGateLevel > 0; // Mở nếu level > 0
    }

    // For indoor devices (ESP32-S3), use device state service with extracted ID
    if (device.mqttTopic.startsWith('inside/')) {
      return _deviceStateService.getDeviceState(deviceId);
    }

    // For legacy devices, keep existing logic as fallback
    switch (device.mqttTopic) {
      // ESP32 Dev (outdoor) devices
      case 'khoasmarthome/led1':
        return !_model.isLightOn; // Đảo trạng thái vì ESP32 dùng cực âm
      case 'khoasmarthome/led2':
        return !_model.isACON; // Đảo trạng thái vì ESP32 dùng cực âm

      // ESP32-S3 (indoor) devices - Floor 1
      case 'inside/kitchen_light':
        return _model.isKitchenLightOn; // State riêng cho đèn bếp
      case 'inside/living_room_light':
        return _model.isLivingRoomLightOn; // State riêng cho đèn phòng khách
      case 'inside/bedroom_light':
        return _model.isBedroomLightOn; // State riêng cho đèn phòng ngủ

      // ESP32-S3 (indoor) devices - Floor 2
      case 'inside/corner_bedroom_light':
        return _model
            .isCornerBedroomLightOn; // State riêng cho đèn phòng ngủ góc
      case 'inside/yard_bedroom_light':
        return _model.isYardBedroomLightOn; // State riêng cho đèn phòng ngủ sân
      case 'inside/worship_room_light':
        return _model.isWorshipRoomLightOn; // State riêng cho đèn phòng thờ
      case 'inside/hallway_light':
        return _model.isHallwayLightOn; // State riêng cho đèn hành lang
      case 'inside/balcony_light':
        return _model.isBalconyLightOn; // State riêng cho đèn ban công

      // Quạt và điều hòa
      case 'inside/fan_living_room':
        return _model.isFanLivingRoomOn; // State cho quạt phòng khách
      case 'inside/ac_living_room':
        return _model.isACLivingRoomOn; // State cho điều hòa phòng khách
      case 'inside/ac_bedroom1':
        return _model.isACBedroom1On; // State cho điều hòa phòng ngủ 1
      case 'inside/ac_bedroom2':
        return _model.isACBedroom2On; // State cho điều hòa phòng ngủ 2

      // Legacy topics for backward compatibility
      case 'khoasmarthome/living_room_light':
        return _model
            .isSpeakerFav; // Sử dụng speaker favourite cho đèn phòng khách (legacy)
      case 'khoasmarthome/kitchen_light':
        return _model.isFanFav; // Sử dụng fan favourite cho đèn bếp (legacy)
      case 'khoasmarthome/bedroom_light':
        return _model
            .isLightOn; // Sử dụng light state cho đèn phòng ngủ (legacy)
      case 'khoasmarthome/stairs_light':
        return _model.isACON; // Sử dụng AC state cho đèn cầu thang (legacy)
      case 'khoasmarthome/bathroom_light':
        return _model
            .isSpeakerON; // Sử dụng speaker state cho đèn vệ sinh (legacy)
      default:
        return device.isOn;
    }
  }

  // Helper function to extract device ID from MQTT topic
  String _extractDeviceId(String mqttTopic) {
    switch (mqttTopic) {
      case 'khoasmarthome/led_gate':
        return 'led_gate';
      case 'khoasmarthome/led_around':
        return 'led_around';
      case 'inside/kitchen_light':
        return 'kitchen_light';
      case 'inside/living_room_light':
        return 'living_room_light';
      case 'inside/bedroom_light':
        return 'bedroom_light';
      case 'inside/corner_bedroom_light':
        return 'corner_bedroom_light';
      case 'inside/yard_bedroom_light':
        return 'yard_bedroom_light';
      case 'inside/worship_room_light':
        return 'worship_room_light';
      case 'inside/hallway_light':
        return 'hallway_light';
      case 'inside/balcony_light':
        return 'balcony_light';
      // Quạt và điều hòa
      case 'inside/fan_living_room':
        return 'fan_living_room';
      case 'inside/ac_living_room':
        return 'ac_living_room';
      case 'inside/ac_bedroom1':
        return 'ac_bedroom1';
      case 'inside/ac_bedroom2':
        return 'ac_bedroom2';
      default:
        // Extract from topic format: prefix/device_name or prefix/device_name/status
        final parts = mqttTopic.split('/');
        return parts.length >= 2 ? parts.last : mqttTopic;
    }
  }

  void _toggleDevice(SmartDevice device) {
    String deviceId = _extractDeviceId(device.mqttTopic);
    bool currentState = _getDeviceState(device);
    bool newState = !currentState;

    // Update device state service first
    _deviceStateService.updateDeviceState(deviceId, newState, source: 'UI');

    // Handle indoor devices (ESP32-S3)
    if (device.mqttTopic.startsWith('inside/')) {
      // Update specific states in HomeScreenViewModel
      switch (device.mqttTopic) {
        case 'inside/kitchen_light':
          _model.setKitchenLight(newState);
          break;
        case 'inside/living_room_light':
          _model.setLivingRoomLight(newState);
          break;
        case 'inside/bedroom_light':
          _model.setBedroomLight(newState);
          break;
        case 'inside/corner_bedroom_light':
          _model.setCornerBedroomLight(newState);
          break;
        case 'inside/yard_bedroom_light':
          _model.setYardBedroomLight(newState);
          break;
        case 'inside/worship_room_light':
          _model.setWorshipRoomLight(newState);
          break;
        case 'inside/hallway_light':
          _model.setHallwayLight(newState);
          break;
        case 'inside/balcony_light':
          _model.setBalconyLight(newState);
          break;
        // Quạt và điều hòa
        case 'inside/fan_living_room':
          _model.setFanLivingRoom(newState);
          break;
        case 'inside/ac_living_room':
          _model.setACLivingRoom(newState);
          break;
        case 'inside/ac_bedroom1':
          _model.setACBedroom1(newState);
          break;
        case 'inside/ac_bedroom2':
          _model.setACBedroom2(newState);
          break;
      }
      try {
        final mqttServiceSimple = getIt<MqttServiceSimple>();
        if (mqttServiceSimple.isConnected) {
          final command = newState ? 'ON' : 'OFF';
          mqttServiceSimple.publishIndoorDeviceCommand(device.mqttTopic, command);
          print('🏠 UI: ${device.name} = $newState via Indoor MQTT');
        } else {
          print('⚠️ MqttServiceSimple not connected, initializing...');
          mqttServiceSimple.initialize().then((_) {
            if (mqttServiceSimple.isConnected) {
              final command = newState ? 'ON' : 'OFF';
              mqttServiceSimple.publishIndoorDeviceCommand(device.mqttTopic, command);
              print('🏠 UI: ${device.name} = $newState via Indoor MQTT (after init)');
            } else {
              print('❌ Failed to connect MqttServiceSimple');
            }
          });
        }
      } catch (e) {
        print('❌ Error controlling indoor device: $e');
        // Fallback: Try using the regular MQTT service if available
        try {
          _mqttService.publishDeviceCommand(device.mqttTopic, newState ? 'ON' : 'OFF');
          print('🔄 Fallback: Using regular MQTT service for ${device.name}');
        } catch (fallbackError) {
          print('❌ Fallback also failed: $fallbackError');
        }
      }
      return;
    }

    // Handle outdoor devices and legacy devices
    switch (device.mqttTopic) {
      // ESP32 devices - use direct MQTT control
      case 'khoasmarthome/led_gate':
        _mqttService.controlLedGate(newState);
        print('🔄 UI: LED Gate = $newState via MQTT');
        break;
      case 'khoasmarthome/led_around':
        _mqttService.controlLedAround(newState);
        print('🔄 UI: LED Around = $newState via MQTT');
        break;

      // Legacy ESP32 Dev devices
      case 'khoasmarthome/led1':
        _model.toggleLed1();
        break;
      case 'khoasmarthome/led2':
        _model.toggleLed2();
        break;
      case 'khoasmarthome/motor':
        _model.toggleMotor();
        break;

      // Legacy topics for backward compatibility
      case 'khoasmarthome/living_room_light':
        // Điều khiển đèn phòng khách (legacy)
        _model
            .speakerFav(); // Sử dụng speaker favourite toggle cho đèn phòng khách
        break;
      case 'khoasmarthome/kitchen_light':
        // Điều khiển đèn phòng bếp (legacy)
        _model.fanFav(); // Sử dụng fan favourite toggle cho đèn bếp
        break;
      case 'khoasmarthome/bedroom_light':
        // Điều khiển đèn phòng ngủ (legacy)
        _model.lightSwitch(); // Sử dụng light switch cho đèn phòng ngủ
        break;
      case 'khoasmarthome/stairs_light':
        // Điều khiển đèn cầu thang (legacy)
        _model.acSwitch(); // Sử dụng AC switch cho đèn cầu thang
        break;
      case 'khoasmarthome/bathroom_light':
        // Điều khiển đèn phòng vệ sinh (legacy)
        _model.speakerSwitch(); // Sử dụng speaker switch cho đèn vệ sinh
        break;
    }
    setState(() {}); // Refresh UI after toggle
  }

  int _getTotalDevices() {
    return widget.floor.rooms
        .fold(0, (total, room) => total + room.devices.length);
  }
}
