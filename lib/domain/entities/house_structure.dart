import 'package:flutter/material.dart';

class HouseFloor {
  final String name;
  final String description;
  final List<HouseRoom> rooms;
  final IconData icon;
  final Color color;

  HouseFloor({
    required this.name,
    required this.description,
    required this.rooms,
    required this.icon,
    required this.color,
  });

  int get totalDevices {
    return rooms.fold(0, (total, room) => total + room.devices.length);
  }
}

class HouseRoom {
  final String name;
  final String type;
  final List<SmartDevice> devices;
  final IconData icon;
  final Color color;
  final String description;

  HouseRoom({
    required this.name,
    required this.type,
    required this.devices,
    required this.icon,
    required this.color,
    required this.description,
  });
}

class SmartDevice {
  final String name;
  final String type;
  final bool isOn;
  final IconData icon;
  final String mqttTopic;
  final Color color;

  SmartDevice({
    required this.name,
    required this.type,
    required this.isOn,
    required this.icon,
    required this.mqttTopic,
    required this.color,
  });

  SmartDevice copyWith({
    String? name,
    String? type,
    bool? isOn,
    IconData? icon,
    String? mqttTopic,
    Color? color,
  }) {
    return SmartDevice(
      name: name ?? this.name,
      type: type ?? this.type,
      isOn: isOn ?? this.isOn,
      icon: icon ?? this.icon,
      mqttTopic: mqttTopic ?? this.mqttTopic,
      color: color ?? this.color,
    );
  }
}

// Data structure for the house
class HouseData {
  static List<HouseFloor> getHouseStructure() {
    return [
      // Sân
      HouseFloor(
        name: 'Sân',
        description: 'Khu vực ngoài trời',
        icon: Icons.yard,
        color: Colors.green,
        rooms: [
          HouseRoom(
            name: 'Cổng chính',
            type: 'entrance',
            description: 'Hệ thống cổng và an ninh',
            icon: Icons.door_sliding,
            color: Colors.brown,
            devices: [
              SmartDevice(
                name: 'Cổng điện',
                type: 'gate',
                isOn: false,
                icon: Icons.garage_outlined,
                mqttTopic: 'khoasmarthome/motor',
                color: Colors.brown,
              ),
              SmartDevice(
                name: 'Đèn cổng',
                type: 'light',
                isOn: false,
                icon: Icons.lightbulb_outline,
                mqttTopic: 'khoasmarthome/led_gate',
                color: Colors.amber,
              ),
            ],
          ),
          HouseRoom(
            name: 'Sân trước',
            type: 'yard',
            description: 'Khu vực sân vườn',
            icon: Icons.yard,
            color: Colors.green,
            devices: [
              SmartDevice(
                name: 'Đèn sân',
                type: 'light',
                isOn: false,
                icon: Icons.lightbulb,
                mqttTopic: 'khoasmarthome/led_around',
                color: Colors.amber,
              ),
              SmartDevice(
                name: 'Mái che',
                type: 'awning',
                isOn: false,
                icon: Icons.local_parking,
                mqttTopic: 'khoasmarthome/awning',
                color: Colors.brown,
              ),
              SmartDevice(
                name: 'Đèn sân chính',
                type: 'light',
                isOn: false,
                icon: Icons.wb_incandescent,
                mqttTopic: 'khoasmarthome/yard_main_light',
                color: Colors.amber,
              ),
              SmartDevice(
                name: 'Đèn khu bể cá',
                type: 'light',
                isOn: false,
                icon: Icons.waves,
                mqttTopic: 'khoasmarthome/fish_pond_light',
                color: Colors.blue,
              ),
              SmartDevice(
                name: 'Đèn mái hiên',
                type: 'light',
                isOn: false,
                icon: Icons.wb_sunny,
                mqttTopic: 'khoasmarthome/awning_light',
                color: Colors.orange,
              ),
              SmartDevice(
                name: 'Hệ thống tưới',
                type: 'sprinkler',
                isOn: false,
                icon: Icons.water_drop,
                mqttTopic: 'khoasmarthome/sprinkler',
                color: Colors.blue,
              ),
            ],
          ),
        ],
      ),

      // Tầng 1
      HouseFloor(
        name: 'Tầng 1',
        description: 'Tầng trệt',
        icon: Icons.home,
        color: Colors.blue,
        rooms: [
          HouseRoom(
            name: 'Phòng khách',
            type: 'living_room',
            description: 'Khu vực sinh hoạt chung',
            icon: Icons.weekend,
            color: Colors.orange,
            devices: [
              SmartDevice(
                name: 'Đèn phòng khách',
                type: 'light',
                isOn: false,
                icon: Icons.lightbulb_outline,
                mqttTopic: 'inside/living_room_light',
                color: Colors.amber,
              ),
            ],
          ),
          HouseRoom(
            name: 'Phòng bếp',
            type: 'kitchen',
            description: 'Khu vực nấu ăn',
            icon: Icons.kitchen,
            color: Colors.red,
            devices: [
              SmartDevice(
                name: 'Đèn bếp',
                type: 'light',
                isOn: false,
                icon: Icons.lightbulb,
                mqttTopic: 'inside/kitchen_light',
                color: Colors.amber,
              ),
            ],
          ),
          HouseRoom(
            name: 'Phòng ngủ',
            type: 'bedroom',
            description: 'Phòng ngủ tầng trệt',
            icon: Icons.bed,
            color: Colors.purple,
            devices: [
              SmartDevice(
                name: 'Đèn ngủ',
                type: 'light',
                isOn: false,
                icon: Icons.bedtime,
                mqttTopic: 'inside/bedroom_light',
                color: Colors.amber,
              ),
            ],
          ),
        ],
      ),

      // Tầng 2
      HouseFloor(
        name: 'Tầng 2',
        description: 'Tầng lầu',
        icon: Icons.home_work,
        color: Colors.indigo,
        rooms: [
          HouseRoom(
            name: 'Phòng ngủ sân',
            type: 'yard_bedroom',
            description: 'Phòng ngủ hướng sân (Room 1)',
            icon: Icons.single_bed,
            color: Colors.pink,
            devices: [
              SmartDevice(
                name: 'Đèn phòng ngủ sân',
                type: 'light',
                isOn: false,
                icon: Icons.lightbulb,
                mqttTopic: 'inside/yard_bedroom_light',
                color: Colors.amber,
              ),
            ],
          ),
          HouseRoom(
            name: 'Phòng ngủ góc',
            type: 'corner_bedroom',
            description: 'Phòng ngủ góc (Room 2)',
            icon: Icons.bed,
            color: Colors.purple,
            devices: [
              SmartDevice(
                name: 'Đèn phòng ngủ góc',
                type: 'light',
                isOn: false,
                icon: Icons.lightbulb,
                mqttTopic: 'inside/corner_bedroom_light',
                color: Colors.amber,
              ),
            ],
          ),
          HouseRoom(
            name: 'Phòng thờ',
            type: 'worship_room',
            description: 'Khu vực thờ cúng',
            icon: Icons.temple_buddhist,
            color: Colors.deepOrange,
            devices: [
              SmartDevice(
                name: 'Đèn thờ',
                type: 'light',
                isOn: false,
                icon: Icons.lightbulb,
                mqttTopic: 'inside/worship_room_light',
                color: Colors.amber,
              ),
            ],
          ),
          HouseRoom(
            name: 'Hành lang',
            type: 'hallway',
            description: 'Hành lang tầng 2',
            icon: Icons.map,
            color: Colors.grey,
            devices: [
              SmartDevice(
                name: 'Đèn hành lang',
                type: 'light',
                isOn: false,
                icon: Icons.lightbulb,
                mqttTopic: 'inside/hallway_light',
                color: Colors.amber,
              ),
            ],
          ),
          HouseRoom(
            name: 'Ban công lớn',
            type: 'large_balcony',
            description: 'Ban công tầng 2',
            icon: Icons.deck,
            color: Colors.lightGreen,
            devices: [
              SmartDevice(
                name: 'Đèn ban công',
                type: 'light',
                isOn: false,
                icon: Icons.lightbulb_outline,
                mqttTopic: 'inside/balcony_light',
                color: Colors.amber,
              ),
            ],
          ),
        ],
      ),
    ];
  }
}
