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
  final Color textColor; // Thêm thuộc tính textColor

  SmartDevice({
    required this.name,
    required this.type,
    required this.isOn,
    required this.icon,
    required this.mqttTopic,
    required this.color,
    this.textColor = Colors.black, // Giá trị mặc định là Colors.black
  });

  SmartDevice copyWith({
    String? name,
    String? type,
    bool? isOn,
    IconData? icon,
    String? mqttTopic,
    Color? color,
    Color? textColor,
  }) {
    return SmartDevice(
      name: name ?? this.name,
      type: type ?? this.type,
      isOn: isOn ?? this.isOn,
      icon: icon ?? this.icon,
      mqttTopic: mqttTopic ?? this.mqttTopic,
      color: color ?? this.color,
      textColor: textColor ?? this.textColor,
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
        color: Color(0xFF888DF2),
        rooms: [
          HouseRoom(
            name: 'Cổng chính',
            type: 'entrance',
            description: 'Hệ thống cổng và an ninh',
            icon: Icons.door_sliding,
            color: Color(0xFF868AF2),
            devices: [
              SmartDevice(
                name: 'Cổng điện',
                type: 'gate',
                isOn: false,
                icon: Icons.garage_outlined,
                mqttTopic: 'khoasmarthome/motor',
                color: Color(0xFF8183F2),
                textColor: Colors.black,
              ),
              SmartDevice(
                name: 'Đèn cổng',
                type: 'light',
                isOn: false,
                icon: Icons.lightbulb_outline,
                mqttTopic: 'khoasmarthome/led_gate',
                color: Color(0xFF7F80F2),
                textColor: Colors.black,
              ),
            ],
          ),
          HouseRoom(
            name: 'Sân trước',
            type: 'yard',
            description: 'Khu vực sân vườn',
            icon: Icons.yard,
            color: Color(0xFF7C7DF2),
            devices: [
              SmartDevice(
                name: 'Đèn sân',
                type: 'light',
                isOn: false,
                icon: Icons.lightbulb,
                mqttTopic: 'khoasmarthome/led_around',
                color: Color(0xFF7A79F2),
                textColor: Colors.black,
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
        color: Color(0xFF716DF2),
        rooms: [
          HouseRoom(
            name: 'Phòng khách',
            type: 'living_room',
            description: 'Khu vực sinh hoạt chung',
            icon: Icons.weekend,
            color: Color(0xFF716DF2),
            devices: [
              SmartDevice(
                name: 'Đèn phòng khách',
                type: 'light',
                isOn: false,
                icon: Icons.lightbulb_outline,
                mqttTopic: 'inside/living_room_light',
                color: Color(0xFF716DF2),
                textColor: Colors.black,
              ),
              SmartDevice(
                name: 'Quạt phòng khách',
                type: 'fan',
                isOn: false,
                icon: Icons.air,
                mqttTopic: 'inside/fan_living_room',
                color: Color(0xFF4CAF50),
                textColor: Colors.black,
              ),
              SmartDevice(
                name: 'Điều hòa phòng khách',
                type: 'air_conditioner',
                isOn: false,
                icon: Icons.ac_unit,
                mqttTopic: 'inside/ac_living_room',
                color: Color(0xFF2196F3),
                textColor: Colors.black,
              ),
            ],
          ),
          HouseRoom(
            name: 'Phòng bếp',
            type: 'kitchen',
            description: 'Khu vực nấu ăn',
            icon: Icons.kitchen,
            color: Color(0xFF716DF2),
            devices: [
              SmartDevice(
                name: 'Đèn bếp',
                type: 'light',
                isOn: false,
                icon: Icons.lightbulb,
                mqttTopic: 'inside/kitchen_light',
                color: Color(0xFF716DF2),
                textColor: Colors.black,
              ),
            ],
          ),
          HouseRoom(
            name: 'Phòng ngủ',
            type: 'bedroom',
            description: 'Phòng ngủ tầng trệt',
            icon: Icons.bed,
            color: Color(0xFF716DF2),
            devices: [
              SmartDevice(
                name: 'Đèn ngủ',
                type: 'light',
                isOn: false,
                icon: Icons.bedtime,
                mqttTopic: 'inside/bedroom_light',
                color: Color(0xFF716DF2),
                textColor: Colors.black,
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
        color: Color(0xFF716DF2),
        rooms: [
          HouseRoom(
            name: 'Phòng ngủ sân',
            type: 'yard_bedroom',
            description: 'Phòng ngủ hướng sân (Room 1)',
            icon: Icons.single_bed,
            color: Color(0xFF716DF2),
            devices: [
              SmartDevice(
                name: 'Đèn phòng ngủ sân',
                type: 'light',
                isOn: false,
                icon: Icons.lightbulb,
                mqttTopic: 'inside/yard_bedroom_light',
                color: Color(0xFF716DF2),
                textColor: Colors.black,
              ),
              SmartDevice(
                name: 'Điều hòa phòng ngủ 1',
                type: 'air_conditioner',
                isOn: false,
                icon: Icons.ac_unit,
                mqttTopic: 'inside/ac_bedroom1',
                color: Color(0xFF2196F3),
                textColor: Colors.black,
              ),
            ],
          ),
          HouseRoom(
            name: 'Phòng ngủ góc',
            type: 'corner_bedroom',
            description: 'Phòng ngủ góc (Room 2)',
            icon: Icons.bed,
            color: Color(0xFF716DF2),
            devices: [
              SmartDevice(
                name: 'Đèn phòng ngủ góc',
                type: 'light',
                isOn: false,
                icon: Icons.lightbulb,
                mqttTopic: 'inside/corner_bedroom_light',
                color: Color(0xFF716DF2),
                textColor: Colors.black,
              ),
              SmartDevice(
                name: 'Điều hòa phòng ngủ 2',
                type: 'air_conditioner',
                isOn: false,
                icon: Icons.ac_unit,
                mqttTopic: 'inside/ac_bedroom2',
                color: Color(0xFF2196F3),
                textColor: Colors.black,
              ),
            ],
          ),
          HouseRoom(
            name: 'Phòng thờ',
            type: 'worship_room',
            description: 'Khu vực thờ cúng',
            icon: Icons.temple_buddhist,
            color: Color(0xFF716DF2),
            devices: [
              SmartDevice(
                name: 'Đèn thờ',
                type: 'light',
                isOn: false,
                icon: Icons.lightbulb,
                mqttTopic: 'inside/worship_room_light',
                color: Color(0xFF716DF2),
                textColor: Colors.black,
              ),
            ],
          ),
          HouseRoom(
            name: 'Hành lang',
            type: 'hallway',
            description: 'Hành lang tầng 2',
            icon: Icons.map,
            color: Color(0xFF716DF2),
            devices: [
              SmartDevice(
                name: 'Đèn hành lang',
                type: 'light',
                isOn: false,
                icon: Icons.lightbulb,
                mqttTopic: 'inside/hallway_light',
                color: Color(0xFF716DF2),
                textColor: Colors.black,
              ),
            ],
          ),
          HouseRoom(
            name: 'Ban công lớn',
            type: 'large_balcony',
            description: 'Ban công tầng 2',
            icon: Icons.deck,
            color: Color(0xFF716DF2),
            devices: [
              SmartDevice(
                name: 'Đèn ban công',
                type: 'light',
                isOn: false,
                icon: Icons.lightbulb_outline,
                mqttTopic: 'inside/balcony_light',
                color: Color(0xFF716DF2),
                textColor: Colors.black,
              ),
            ],
          ),
        ],
      ),
    ];
  }
}
