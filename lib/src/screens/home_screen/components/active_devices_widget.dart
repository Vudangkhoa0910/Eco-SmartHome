import 'package:flutter/material.dart';
import 'package:smart_home/config/size_config.dart';
import 'package:smart_home/view/home_screen_view_model.dart';
import 'package:smart_home/service/device_state_service.dart';
import 'package:smart_home/domain/entities/house_structure.dart';
import 'package:smart_home/provider/getit.dart';
import 'package:provider/provider.dart';

class ActiveDevicesWidget extends StatelessWidget {
  final HomeScreenViewModel model;

  const ActiveDevicesWidget({Key? key, required this.model}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Debug: Check GetIt registration status
    print('🔍 Checking DeviceStateService registration...');
    print('🔍 DeviceStateService registered: ${getIt.isRegistered<DeviceStateService>()}');
    
    // Try multiple approaches to get DeviceStateService
    DeviceStateService? deviceStateService;
    
    // Approach 1: Direct GetIt access
    try {
      if (getIt.isRegistered<DeviceStateService>()) {
        deviceStateService = getIt<DeviceStateService>();
        print('✅ Successfully got DeviceStateService via GetIt');
      }
    } catch (e) {
      print('❌ Error accessing DeviceStateService via GetIt: $e');
    }
    
    // Approach 2: Direct instantiation as fallback
    if (deviceStateService == null) {
      try {
        deviceStateService = DeviceStateService();
        print('✅ Created new DeviceStateService instance as fallback');
      } catch (e) {
        print('❌ Error creating DeviceStateService instance: $e');
        return _buildErrorState();
      }
    }

    // If service is still not available, show error
    if (deviceStateService == null) {
      print('❌ DeviceStateService is null, showing error state');
      return _buildErrorState();
    }
    
    return ChangeNotifierProvider.value(
      value: model,
      child: Consumer<HomeScreenViewModel>(
        builder: (context, viewModel, child) {
          return StreamBuilder<Map<String, bool>>(
            stream: deviceStateService!.stateStream,
            initialData: deviceStateService.currentStates,
            builder: (context, snapshot) {
              final deviceStates = snapshot.data ?? {};
              final activeDevices = _getActiveDevices(viewModel, deviceStates);
              
              // Debug log để kiểm tra
              print('🔄 ActiveDevicesWidget: Found ${activeDevices.length} active devices');
              if (deviceStates.isNotEmpty) {
                print('🔄 Device states: $deviceStates');
              }
              
              if (activeDevices.isEmpty) {
                return _buildEmptyState();
              }

              return Container(
                margin: EdgeInsets.symmetric(
                  horizontal: getProportionateScreenWidth(20),
                  vertical: getProportionateScreenHeight(6),
                ),
                padding: EdgeInsets.all(getProportionateScreenWidth(12)),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.08),
                      spreadRadius: 1,
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Icon(
                            Icons.power_settings_new,
                            color: Colors.green,
                            size: 14,
                          ),
                        ),
                        SizedBox(width: getProportionateScreenWidth(8)),
                        Text(
                          'Thiết bị đang hoạt động',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[800],
                          ),
                        ),
                        SizedBox(width: getProportionateScreenWidth(6)),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: getProportionateScreenWidth(6),
                            vertical: getProportionateScreenHeight(2),
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
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
                    SizedBox(height: getProportionateScreenHeight(10)),
                    Wrap(
                      spacing: getProportionateScreenWidth(6),
                      runSpacing: getProportionateScreenHeight(5),
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
        vertical: getProportionateScreenHeight(6),
      ),
      padding: EdgeInsets.all(getProportionateScreenWidth(12)),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.grey.withOpacity(0.15),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              Icons.power_off,
              color: Colors.grey,
              size: 14,
            ),
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
        borderRadius: BorderRadius.circular(16),
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
              fontSize: 9,
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

    // Lấy danh sách thiết bị từ house structure
    final houseData = HouseData.getHouseStructure();
    
    // Duyệt qua tất cả các tầng và phòng để lấy thiết bị
    for (final floor in houseData) {
      for (final room in floor.rooms) {
        for (final device in room.devices) {
          // Extract device ID từ MQTT topic
          String deviceId = _extractDeviceId(device.mqttTopic);
          
          // Kiểm tra trạng thái thiết bị từ DeviceStateService hoặc ViewModel
          bool isActive = _getDeviceRealTimeState(device, deviceStates, viewModel);
          
          if (isActive) {
            activeDevices.add(ActiveDevice(
              name: device.name,
              icon: device.icon,
              color: device.color,
              deviceId: deviceId,
              mqttTopic: device.mqttTopic,
            ));
          }
        }
      }
    }

    // Kiểm tra cổng riêng từ ViewModel (vì có thể có logic đặc biệt)
    if (viewModel.currentGateLevel > 0) {
      // Tìm device cổng trong structure để lấy thông tin chính xác
      bool gateDeviceFound = false;
      for (final floor in houseData) {
        if (gateDeviceFound) break;
        for (final room in floor.rooms) {
          final gateDevice = room.devices.where(
            (d) => d.type == 'gate' || d.mqttTopic == 'khoasmarthome/motor'
          ).firstOrNull;
          
          if (gateDevice != null) {
            // Kiểm tra xem đã thêm chưa để tránh trùng lặp
            final existingIndex = activeDevices.indexWhere((d) => 
              d.deviceId == 'gate' || d.mqttTopic == 'khoasmarthome/motor');
            
            if (existingIndex >= 0) {
              // Cập nhật thông tin cổng với mức độ mở
              activeDevices[existingIndex] = ActiveDevice(
                name: '${gateDevice.name} (${viewModel.currentGateLevel}%)',
                icon: gateDevice.icon,
                color: gateDevice.color,
                deviceId: 'gate',
                mqttTopic: gateDevice.mqttTopic,
              );
            } else {
              activeDevices.add(ActiveDevice(
                name: '${gateDevice.name} (${viewModel.currentGateLevel}%)',
                icon: gateDevice.icon,
                color: gateDevice.color,
                deviceId: 'gate',
                mqttTopic: gateDevice.mqttTopic,
              ));
            }
            gateDeviceFound = true;
            break;
          }
        }
      }
    }

    return activeDevices;
  }

  // Helper function để lấy trạng thái real-time
  bool _getDeviceRealTimeState(SmartDevice device, Map<String, bool>? deviceStates, HomeScreenViewModel viewModel) {
    String deviceId = _extractDeviceId(device.mqttTopic);
    
    // 🔄 PRIORITY: Check DeviceStateService first for real-time state
    if (deviceStates?.containsKey(deviceId) == true) {
      return deviceStates![deviceId]!;
    }
    
    // 🔄 FALLBACK: Use ViewModel state cho các device đặc biệt
    switch (device.mqttTopic) {
      case 'khoasmarthome/motor':
        return viewModel.currentGateLevel > 0;
      case 'khoasmarthome/led_gate':
        return deviceStates?['led_gate'] ?? false;
      case 'khoasmarthome/led_around':
        return deviceStates?['led_around'] ?? false;
      case 'inside/kitchen_light':
        return deviceStates?['kitchen_light'] ?? false;
      case 'inside/living_room_light':
        return deviceStates?['living_room_light'] ?? false;
      case 'inside/bedroom_light':
        return deviceStates?['bedroom_light'] ?? false;
      case 'inside/corner_bedroom_light':
        return deviceStates?['corner_bedroom_light'] ?? false;
      case 'inside/yard_bedroom_light':
        return deviceStates?['yard_bedroom_light'] ?? false;
      case 'inside/worship_room_light':
        return deviceStates?['worship_room_light'] ?? false;
      case 'inside/hallway_light':
        return deviceStates?['hallway_light'] ?? false;
      case 'inside/balcony_light':
        return deviceStates?['balcony_light'] ?? false;
      default:
        return false; // Mặc định tắt nếu không tìm thấy
    }
  }

  // Helper function để extract device ID từ MQTT topic
  String _extractDeviceId(String mqttTopic) {
    switch (mqttTopic) {
      case 'khoasmarthome/led_gate':
        return 'led_gate';
      case 'khoasmarthome/led_around':
        return 'led_around';
      case 'khoasmarthome/motor':
        return 'gate';
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
      default:
        // Extract từ topic cuối cùng
        final parts = mqttTopic.split('/');
        return parts.last.replaceAll('_light', '').replaceAll('_', '');
    }
  }

  Widget _buildErrorState() {
    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: getProportionateScreenWidth(20),
        vertical: getProportionateScreenHeight(6),
      ),
      padding: EdgeInsets.all(getProportionateScreenWidth(12)),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red, size: 20),
          SizedBox(width: getProportionateScreenWidth(8)),
          Text(
            'Lỗi tải dịch vụ thiết bị',
            style: TextStyle(
              color: Colors.red,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    print('🔄 Building loading state for ActiveDevicesWidget');
    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: getProportionateScreenWidth(20),
        vertical: getProportionateScreenHeight(6),
      ),
      padding: EdgeInsets.all(getProportionateScreenWidth(12)),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blue.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
            ),
          ),
          SizedBox(width: getProportionateScreenWidth(8)),
          Text(
            'Đang tải dịch vụ thiết bị...',
            style: TextStyle(
              color: Colors.blue,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class ActiveDevice {
  final String name;
  final IconData icon;
  final Color color;
  final String deviceId;
  final String mqttTopic;

  ActiveDevice({
    required this.name,
    required this.icon,
    required this.color,
    required this.deviceId,
    required this.mqttTopic,
  });
}
