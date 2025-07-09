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
                name: 'Đèn chính',
                type: 'light',
                isOn: false,
                icon: Icons.lightbulb,
                mqttTopic: 'khoasmarthome/led1',
                color: Colors.amber,
              ),
              SmartDevice(
                name: 'Đèn phòng khách',
                type: 'light',
                isOn: false,
                icon: Icons.lightbulb_outline,
                mqttTopic: 'khoasmarthome/living_room_light',
                color: Colors.amber,
              ),
              SmartDevice(
                name: 'TV',
                type: 'tv',
                isOn: false,
                icon: Icons.tv,
                mqttTopic: 'khoasmarthome/tv',
                color: Colors.black,
              ),
              SmartDevice(
                name: 'Điều hòa',
                type: 'ac',
                isOn: false,
                icon: Icons.ac_unit,
                mqttTopic: 'khoasmarthome/ac_living',
                color: Colors.cyan,
              ),
            ],
          ),
          HouseRoom(
            name: 'Phòng ngủ 1',
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
                mqttTopic: 'khoasmarthome/bedroom_light',
                color: Colors.amber,
              ),
              SmartDevice(
                name: 'Quạt trần',
                type: 'fan',
                isOn: false,
                icon: Icons.toys,
                mqttTopic: 'khoasmarthome/motor',
                color: Colors.grey,
              ),
              SmartDevice(
                name: 'Điều hòa',
                type: 'ac',
                isOn: false,
                icon: Icons.ac_unit,
                mqttTopic: 'khoasmarthome/ac_bedroom1',
                color: Colors.cyan,
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
                mqttTopic: 'khoasmarthome/kitchen_light',
                color: Colors.amber,
              ),
              SmartDevice(
                name: 'Máy hút mùi',
                type: 'exhaust',
                isOn: false,
                icon: Icons.air,
                mqttTopic: 'khoasmarthome/kitchen_exhaust',
                color: Colors.grey,
              ),
              SmartDevice(
                name: 'Tủ lạnh thông minh',
                type: 'fridge',
                isOn: true,
                icon: Icons.kitchen_outlined,
                mqttTopic: 'khoasmarthome/fridge',
                color: Colors.blue,
              ),
            ],
          ),
          HouseRoom(
            name: 'Phòng vệ sinh',
            type: 'bathroom',
            description: 'Nhà vệ sinh tầng 1',
            icon: Icons.bathroom,
            color: Colors.teal,
            devices: [
              SmartDevice(
                name: 'Đèn WC',
                type: 'light',
                isOn: false,
                icon: Icons.lightbulb,
                mqttTopic: 'khoasmarthome/bathroom_light',
                color: Colors.amber,
              ),
              SmartDevice(
                name: 'Quạt thông gió',
                type: 'exhaust',
                isOn: false,
                icon: Icons.air,
                mqttTopic: 'khoasmarthome/bathroom1_fan',
                color: Colors.grey,
              ),
            ],
          ),
          HouseRoom(
            name: 'Cầu thang',
            type: 'stairs',
            description: 'Khu vực cầu thang tầng 1',
            icon: Icons.stairs,
            color: Colors.brown,
            devices: [
              SmartDevice(
                name: 'Đèn cầu thang',
                type: 'light',
                isOn: false,
                icon: Icons.lightbulb,
                mqttTopic: 'khoasmarthome/stairs_light',
                color: Colors.amber,
              ),
            ],
          ),
          HouseRoom(
            name: 'Ban công lớn',
            type: 'balcony',
            description: 'Ban công tầng 1',
            icon: Icons.balcony,
            color: Colors.lightGreen,
            devices: [
              SmartDevice(
                name: 'Đèn ban công',
                type: 'light',
                isOn: false,
                icon: Icons.lightbulb_outline,
                mqttTopic: 'khoasmarthome/balcony1_light',
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
            name: 'Cầu thang',
            type: 'stairs',
            description: 'Khu vực cầu thang tầng 2',
            icon: Icons.stairs,
            color: Colors.brown,
            devices: [
              SmartDevice(
                name: 'Đèn cầu thang',
                type: 'light',
                isOn: false,
                icon: Icons.lightbulb,
                mqttTopic: 'khoasmarthome/stairs2_light',
                color: Colors.amber,
              ),
            ],
          ),
          HouseRoom(
            name: 'Phòng ngủ 2',
            type: 'bedroom',
            description: 'Phòng ngủ chính',
            icon: Icons.bed,
            color: Colors.purple,
            devices: [
              SmartDevice(
                name: 'Đèn chính',
                type: 'light',
                isOn: false,
                icon: Icons.lightbulb,
                mqttTopic: 'khoasmarthome/bedroom2_light',
                color: Colors.amber,
              ),
              SmartDevice(
                name: 'Đèn ngủ',
                type: 'light',
                isOn: false,
                icon: Icons.bedtime,
                mqttTopic: 'khoasmarthome/bedroom2_night',
                color: Colors.amber,
              ),
              SmartDevice(
                name: 'Quạt trần',
                type: 'fan',
                isOn: false,
                icon: Icons.toys,
                mqttTopic: 'khoasmarthome/bedroom2_fan',
                color: Colors.grey,
              ),
              SmartDevice(
                name: 'Điều hòa',
                type: 'ac',
                isOn: false,
                icon: Icons.ac_unit,
                mqttTopic: 'khoasmarthome/ac_bedroom2',
                color: Colors.cyan,
              ),
            ],
          ),
          HouseRoom(
            name: 'Phòng ngủ 3',
            type: 'bedroom',
            description: 'Phòng ngủ phụ',
            icon: Icons.single_bed,
            color: Colors.pink,
            devices: [
              SmartDevice(
                name: 'Đèn phòng',
                type: 'light',
                isOn: false,
                icon: Icons.lightbulb,
                mqttTopic: 'khoasmarthome/bedroom3_light',
                color: Colors.amber,
              ),
              SmartDevice(
                name: 'Quạt trần',
                type: 'fan',
                isOn: false,
                icon: Icons.toys,
                mqttTopic: 'khoasmarthome/bedroom3_fan',
                color: Colors.grey,
              ),
            ],
          ),
          HouseRoom(
            name: 'Phòng thờ',
            type: 'altar',
            description: 'Khu vực thờ cúng',
            icon: Icons.temple_buddhist,
            color: Colors.deepOrange,
            devices: [
              SmartDevice(
                name: 'Đèn thờ',
                type: 'light',
                isOn: false,
                icon: Icons.lightbulb,
                mqttTopic: 'khoasmarthome/altar_light',
                color: Colors.amber,
              ),
              SmartDevice(
                name: 'Đèn trang trí',
                type: 'light',
                isOn: false,
                icon: Icons.auto_awesome,
                mqttTopic: 'khoasmarthome/altar_decoration',
                color: Colors.amber,
              ),
            ],
          ),
          HouseRoom(
            name: 'Ban công rộng',
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
                mqttTopic: 'khoasmarthome/balcony2_light',
                color: Colors.amber,
              ),
              SmartDevice(
                name: 'Đèn trang trí',
                type: 'light',
                isOn: false,
                icon: Icons.lightbulb_outline,
                mqttTopic: 'khoasmarthome/balcony2_decoration',
                color: Colors.amber,
              ),
            ],
          ),
        ],
      ),
    ];
  }
}
