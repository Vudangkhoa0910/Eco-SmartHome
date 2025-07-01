import 'package:flutter/material.dart';
import 'package:smart_home/config/size_config.dart';
import 'package:smart_home/domain/entities/house_structure.dart';
import 'package:smart_home/view/home_screen_view_model.dart';
import 'package:smart_home/provider/getit.dart';


class RoomDetailScreen extends StatelessWidget {
  final HouseRoom room;
  
  const RoomDetailScreen({
    Key? key,
    required this.room,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(room.name),
        backgroundColor: room.color.withOpacity(0.1),
        foregroundColor: room.color,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              // TODO: Implement room settings
            },
          ),
        ],
      ),
      body: Builder(
        builder: (context) {
          final model = getIt<HomeScreenViewModel>();
          return Padding(
            padding: EdgeInsets.all(getProportionateScreenWidth(20)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Room Header
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(getProportionateScreenWidth(20)),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        room.color.withOpacity(0.2),
                        room.color.withOpacity(0.1),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(getProportionateScreenWidth(15)),
                        decoration: BoxDecoration(
                          color: room.color.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Icon(
                          room.icon,
                          color: room.color,
                          size: 40,
                        ),
                      ),
                      SizedBox(width: getProportionateScreenWidth(15)),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              room.name,
                              style: Theme.of(context).textTheme.headlineSmall!.copyWith(
                                fontWeight: FontWeight.bold,
                                color: room.color,
                              ),
                            ),
                            Text(
                              room.description,
                              style: Theme.of(context).textTheme.titleMedium!.copyWith(
                                color: Colors.grey[600],
                              ),
                            ),
                            Text(
                              '${room.devices.length} thiết bị',
                              style: Theme.of(context).textTheme.titleSmall!.copyWith(
                                color: room.color.withOpacity(0.8),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                
                SizedBox(height: getProportionateScreenHeight(30)),
                
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Thiết bị',
                      style: Theme.of(context).textTheme.titleLarge!.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () {
                        _showAddDeviceDialog(context);
                      },
                      icon: const Icon(Icons.add),
                      label: const Text('Thêm thiết bị'),
                    ),
                  ],
                ),
                
                SizedBox(height: getProportionateScreenHeight(15)),
                
                // Devices List
                Expanded(
                  child: GridView.builder(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: getProportionateScreenWidth(15),
                      mainAxisSpacing: getProportionateScreenHeight(15),
                      childAspectRatio: 1.1,
                    ),
                    itemCount: room.devices.length,
                    itemBuilder: (context, index) {
                      final device = room.devices[index];
                      return _buildDeviceCard(context, device, model);
                    },
                  ),
                ),
              ],
            ),
          );
        }),
      );
  }

  Widget _buildDeviceCard(BuildContext context, SmartDevice device, HomeScreenViewModel model) {
    // Determine if this device is controlled by our MQTT system
    bool isControllable = _isDeviceControllable(device);
    bool currentState = _getDeviceState(device, model);
    
    return GestureDetector(
      onTap: isControllable ? () => _toggleDevice(device, model) : null,
      child: Container(
        padding: EdgeInsets.all(getProportionateScreenWidth(15)),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: device.color.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
          border: Border.all(
            color: currentState 
                ? device.color.withOpacity(0.5)
                : Colors.grey.withOpacity(0.2),
            width: currentState ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Device Icon and Status
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: EdgeInsets.all(getProportionateScreenWidth(10)),
                  decoration: BoxDecoration(
                    color: currentState 
                        ? device.color.withOpacity(0.2)
                        : Colors.grey.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    device.icon,
                    color: currentState ? device.color : Colors.grey,
                    size: 24,
                  ),
                ),
                if (isControllable)
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: currentState ? Colors.green : Colors.grey,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
              ],
            ),
            
            SizedBox(height: getProportionateScreenHeight(15)),
            
            // Device Name
            Text(
              device.name,
              style: Theme.of(context).textTheme.titleMedium!.copyWith(
                fontWeight: FontWeight.bold,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            
            SizedBox(height: getProportionateScreenHeight(5)),
            
            // Device Type
            Text(
              _getDeviceTypeLabel(device.type),
              style: Theme.of(context).textTheme.bodySmall!.copyWith(
                color: Colors.grey[600],
              ),
            ),
            
            const Spacer(),
            
            // Control Button or Status
            if (isControllable)
              Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(vertical: getProportionateScreenHeight(8)),
                decoration: BoxDecoration(
                  color: currentState 
                      ? device.color.withOpacity(0.1)
                      : Colors.grey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  currentState ? 'BẬT' : 'TẮT',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: currentState ? device.color : Colors.grey,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              )
            else
              Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(vertical: getProportionateScreenHeight(8)),
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Chưa kết nối',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  bool _isDeviceControllable(SmartDevice device) {
    // Check if device is in our controllable MQTT topics
    const controllableTopics = [
      'khoasmarthome/led1',
      'khoasmarthome/led2',
      'khoasmarthome/motor',
    ];
    return controllableTopics.contains(device.mqttTopic);
  }

  bool _getDeviceState(SmartDevice device, HomeScreenViewModel model) {
    switch (device.mqttTopic) {
      case 'khoasmarthome/led1':
        return model.isLightOn;
      case 'khoasmarthome/led2':
        return model.isACON; // Using AC state for LED2
      case 'khoasmarthome/motor':
        return model.isFanON;
      default:
        return device.isOn; // Default state from device
    }
  }

  void _toggleDevice(SmartDevice device, HomeScreenViewModel model) {
    switch (device.mqttTopic) {
      case 'khoasmarthome/led1':
        model.toggleLed1();
        break;
      case 'khoasmarthome/led2':
        model.toggleLed2();
        break;
      case 'khoasmarthome/motor':
        model.toggleMotor();
        break;
    }
  }

  String _getDeviceTypeLabel(String type) {
    switch (type) {
      case 'light':
        return 'Đèn chiếu sáng';
      case 'fan':
        return 'Quạt thông gió';
      case 'ac':
        return 'Điều hòa không khí';
      case 'tv':
        return 'Tivi';
      case 'gate':
        return 'Cổng tự động';
      case 'sprinkler':
        return 'Hệ thống tưới';
      case 'exhaust':
        return 'Máy hút khí';
      case 'fridge':
        return 'Tủ lạnh thông minh';
      default:
        return 'Thiết bị thông minh';
    }
  }

  void _showAddDeviceDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Thêm thiết bị mới'),
        content: const Text('Tính năng này sẽ được phát triển trong phiên bản tiếp theo.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }
}
