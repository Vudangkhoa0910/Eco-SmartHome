import 'dart:async';
import 'package:smart_home/service/mqtt_service.dart';

enum ZoneType {
  courtyard,
  gate,
  livingRoom,
  bedroom,
  kitchen,
  bathroom,
}

class Zone {
  final String id;
  final String name;
  final ZoneType type;
  final List<Device> devices;
  final String icon;
  
  Zone({
    required this.id,
    required this.name,
    required this.type,
    required this.devices,
    required this.icon,
  });
}

class Device {
  final String id;
  final String name;
  final DeviceType type;
  final bool isOn;
  final double powerConsumption; // Watts
  final String mqttTopic;
  
  Device({
    required this.id,
    required this.name,
    required this.type,
    required this.isOn,
    required this.powerConsumption,
    required this.mqttTopic,
  });
  
  Device copyWith({
    String? id,
    String? name,
    DeviceType? type,
    bool? isOn,
    double? powerConsumption,
    String? mqttTopic,
  }) {
    return Device(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      isOn: isOn ?? this.isOn,
      powerConsumption: powerConsumption ?? this.powerConsumption,
      mqttTopic: mqttTopic ?? this.mqttTopic,
    );
  }
}

enum DeviceType {
  light,
  motor,
  fan,
  airConditioner,
  speaker,
}

class ZoneManagementService {
  static final ZoneManagementService _instance = ZoneManagementService._internal();
  factory ZoneManagementService() => _instance;
  ZoneManagementService._internal();

  final StreamController<List<Zone>> _zonesController = StreamController<List<Zone>>.broadcast();
  Stream<List<Zone>> get zonesStream => _zonesController.stream;
  
  List<Zone> _zones = [];
  List<Zone> get zones => _zones;

  void initialize(MqttService mqttService) {
    _initializeZones();
    _zonesController.add(_zones);
  }

  void _initializeZones() {
    _zones = [
      Zone(
        id: 'courtyard',
        name: 'Sân',
        type: ZoneType.courtyard,
        icon: '🏞️',
        devices: [
          Device(
            id: 'led1',
            name: 'Đèn sân',
            type: DeviceType.light,
            isOn: false,
            powerConsumption: 10.0,
            mqttTopic: 'home/led1',
          ),
        ],
      ),
      Zone(
        id: 'gate',
        name: 'Cổng',
        type: ZoneType.gate,
        icon: '🚪',
        devices: [
          Device(
            id: 'led2',
            name: 'Đèn cổng',
            type: DeviceType.light,
            isOn: false,
            powerConsumption: 10.0,
            mqttTopic: 'home/led2',
          ),
        ],
      ),
      Zone(
        id: 'living_room',
        name: 'Phòng khách',
        type: ZoneType.livingRoom,
        icon: '🛋️',
        devices: [],
      ),
      Zone(
        id: 'bedroom',
        name: 'Phòng ngủ',
        type: ZoneType.bedroom,
        icon: '🛏️',
        devices: [
          Device(
            id: 'motor',
            name: 'Quạt',
            type: DeviceType.motor,
            isOn: false,
            powerConsumption: 50.0,
            mqttTopic: 'home/motor',
          ),
        ],
      ),
      Zone(
        id: 'kitchen',
        name: 'Nhà bếp',
        type: ZoneType.kitchen,
        icon: '🍳',
        devices: [],
      ),
      Zone(
        id: 'bathroom',
        name: 'Phòng tắm',
        type: ZoneType.bathroom,
        icon: '🚿',
        devices: [],
      ),
    ];
  }

  void updateDeviceState(String zoneId, String deviceId, bool isOn) {
    final zoneIndex = _zones.indexWhere((zone) => zone.id == zoneId);
    if (zoneIndex != -1) {
      final deviceIndex = _zones[zoneIndex].devices.indexWhere((device) => device.id == deviceId);
      if (deviceIndex != -1) {
        _zones[zoneIndex].devices[deviceIndex] = _zones[zoneIndex].devices[deviceIndex].copyWith(isOn: isOn);
        _zonesController.add(_zones);
      }
    }
  }

  Zone? getZoneById(String zoneId) {
    try {
      return _zones.firstWhere((zone) => zone.id == zoneId);
    } catch (e) {
      return null;
    }
  }

  Device? getDeviceById(String deviceId) {
    for (final zone in _zones) {
      try {
        return zone.devices.firstWhere((device) => device.id == deviceId);
      } catch (e) {
        continue;
      }
    }
    return null;
  }

  List<Device> getAllDevices() {
    List<Device> allDevices = [];
    for (final zone in _zones) {
      allDevices.addAll(zone.devices);
    }
    return allDevices;
  }

  double getTotalPowerConsumption() {
    double total = 0;
    for (final zone in _zones) {
      for (final device in zone.devices) {
        if (device.isOn) {
          total += device.powerConsumption;
        }
      }
    }
    return total;
  }

  double getZonePowerConsumption(String zoneId) {
    final zone = getZoneById(zoneId);
    if (zone == null) return 0;
    
    double total = 0;
    for (final device in zone.devices) {
      if (device.isOn) {
        total += device.powerConsumption;
      }
    }
    return total;
  }

  void dispose() {
    _zonesController.close();
  }
}
