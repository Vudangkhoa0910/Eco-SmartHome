import 'package:flutter/material.dart';
import 'dart:async';
import 'package:smart_home/config/size_config.dart';
import 'package:smart_home/domain/entities/house_structure.dart';
import 'package:smart_home/src/screens/house_floor/house_floor_screen.dart';
import 'package:smart_home/src/widgets/gate_device_control_widget.dart'; // 🚨 CONSOLIDATED: Using unified gate widget
import 'package:smart_home/service/device_state_service.dart'; // Import for device synchronization

class HouseOverviewScreen extends StatefulWidget {
  const HouseOverviewScreen({Key? key}) : super(key: key);

  @override
  State<HouseOverviewScreen> createState() => _HouseOverviewScreenState();
}

class _HouseOverviewScreenState extends State<HouseOverviewScreen> {
  final DeviceStateService _deviceStateService = DeviceStateService();
  late StreamSubscription _deviceStateSubscription;

  @override
  void initState() {
    super.initState();
    
    // Listen to device state changes for UI synchronization
    _deviceStateSubscription = _deviceStateService.stateStream.listen((states) {
      if (mounted) {
        setState(() {
          // Trigger rebuild when device states change
        });
      }
    });
  }

  @override
  void dispose() {
    _deviceStateSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final floors = HouseData.getHouseStructure();
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Smart Home'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        centerTitle: true,
      ),
      body: Padding(
        padding: EdgeInsets.all(getProportionateScreenWidth(20)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Text(
              'Tổng quan nhà thông minh',
              style: Theme.of(context).textTheme.headlineMedium!.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            
            SizedBox(height: getProportionateScreenHeight(12)),
            
            Text(
              'Điều khiển và theo dõi tất cả thiết bị trong nhà',
              style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                color: Colors.grey[600],
              ),
            ),
            
            SizedBox(height: getProportionateScreenHeight(20)),
            
            // Gate Control Widget - 🚨 CONSOLIDATED: Using GateDeviceControlWidget instead of duplicate GateControlWidget
            GateDeviceControlWidget(
              deviceName: 'Cổng chính',
              deviceColor: Colors.blue,
            ),
            
            SizedBox(height: getProportionateScreenHeight(24)),
            
            // Floors List
            Expanded(
              child: ListView.builder(
                itemCount: floors.length,
                itemBuilder: (context, index) {
                  final floor = floors[index];
                  return _buildFloorCard(context, floor, index);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFloorCard(BuildContext context, HouseFloor floor, int index) {
    return Container(
      margin: EdgeInsets.only(bottom: getProportionateScreenHeight(20)),
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => HouseFloorScreen(floor: floor),
            ),
          );
        },
        child: Container(
          padding: EdgeInsets.all(getProportionateScreenWidth(20)),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                floor.color.withOpacity(0.1),
                floor.color.withOpacity(0.05),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: floor.color.withOpacity(0.3),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: floor.color.withOpacity(0.1),
                spreadRadius: 1,
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Floor Header
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(getProportionateScreenWidth(12)),
                    decoration: BoxDecoration(
                      color: floor.color.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Icon(
                      floor.icon,
                      color: floor.color,
                      size: 30,
                    ),
                  ),
                  SizedBox(width: getProportionateScreenWidth(15)),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          floor.name,
                          style: Theme.of(context).textTheme.titleLarge!.copyWith(
                            fontWeight: FontWeight.bold,
                            color: floor.color.withOpacity(0.9),
                          ),
                        ),
                        Text(
                          floor.description,
                          style: Theme.of(context).textTheme.titleMedium!.copyWith(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios,
                    color: floor.color,
                    size: 20,
                  ),
                ],
              ),
              
              SizedBox(height: getProportionateScreenHeight(15)),
              
              // Rooms Summary
              Text(
                '${floor.rooms.length} khu vực',
                style: Theme.of(context).textTheme.titleMedium!.copyWith(
                  fontWeight: FontWeight.w600,
                  color: floor.color,
                ),
              ),
              
              SizedBox(height: getProportionateScreenHeight(10)),
              
              // Rooms Icons Preview
              SizedBox(
                height: getProportionateScreenHeight(40),
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: floor.rooms.length,
                  itemBuilder: (context, roomIndex) {
                    final room = floor.rooms[roomIndex];
                    return Container(
                      margin: EdgeInsets.only(right: getProportionateScreenWidth(10)),
                      padding: EdgeInsets.all(getProportionateScreenWidth(8)),
                      decoration: BoxDecoration(
                        color: room.color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: room.color.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            room.icon,
                            color: room.color,
                            size: 16,
                          ),
                          SizedBox(width: getProportionateScreenWidth(5)),
                          Text(
                            room.name,
                            style: TextStyle(
                              color: room.color,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              
              SizedBox(height: getProportionateScreenHeight(10)),
              
              // Devices Count
              Row(
                children: [
                  Icon(
                    Icons.devices,
                    color: Colors.grey[600],
                    size: 16,
                  ),
                  SizedBox(width: getProportionateScreenWidth(5)),
                  Text(
                    '${_getTotalDevices(floor)} thiết bị',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'Chạm để xem chi tiết',
                    style: TextStyle(
                      color: floor.color,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  int _getTotalDevices(HouseFloor floor) {
    return floor.rooms.fold(0, (total, room) => total + room.devices.length);
  }
}
