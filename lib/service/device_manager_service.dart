import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_home/domain/entities/house_structure.dart';
import 'package:smart_home/service/firebase_data_service.dart';
import 'package:smart_home/service/mqtt_service_simple.dart';
import 'package:smart_home/service/gate_state_service.dart';

class DeviceManagerService {
  static final DeviceManagerService _instance =
      DeviceManagerService._internal();
  factory DeviceManagerService() => _instance;
  DeviceManagerService._internal();

  static const String _devicesKey = 'user_added_devices';
  final FirebaseDataService _firebaseService = FirebaseDataService();
  final MqttServiceSimple _mqttService = MqttServiceSimple();

  // Cache for user-added devices
  List<UserAddedDevice> _userDevices = [];
  bool _isInitialized = false;

  /// Initialize the service and MQTT connection
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      await _loadUserDevices();

      // Initialize MQTT if there are devices that need it
      if (_userDevices.any((device) => device.device.mqttTopic.isNotEmpty)) {
        await _mqttService.initialize();
      }

      _isInitialized = true;
      print('✅ DeviceManagerService initialized');
    } catch (e) {
      print('❌ Error initializing DeviceManagerService: $e');
    }
  }

  /// Get all user-added devices
  Future<List<UserAddedDevice>> getUserDevices() async {
    if (!_isInitialized) {
      await initialize();
    }
    return _userDevices;
  }

  /// Add a new device
  Future<bool> addDevice({
    required SmartDevice device,
    required String roomName,
    required String floorName,
  }) async {
    try {
      final userDevice = UserAddedDevice(
        device: device,
        roomName: roomName,
        floorName: floorName,
        dateAdded: DateTime.now(),
        isActive: true,
      );

      _userDevices.add(userDevice);

      // Save to local storage
      await _saveUserDevices();

      // Initialize MQTT service if not connected
      if (!_mqttService.isConnected) {
        await _mqttService.initialize();
      }

      // Save to Firebase
      await _saveDeviceToFirebase(userDevice);

      print('✅ Device "${device.name}" added successfully');
      return true;
    } catch (e) {
      print('❌ Error adding device: $e');
      return false;
    }
  }

  /// Remove a device
  Future<bool> removeDevice(String deviceName) async {
    try {
      _userDevices
          .removeWhere((userDevice) => userDevice.device.name == deviceName);
      await _saveUserDevices();

      print('✅ Device "$deviceName" removed successfully');
      return true;
    } catch (e) {
      print('❌ Error removing device: $e');
      return false;
    }
  }

  /// Update device state
  Future<bool> updateDeviceState(String deviceName, bool isOn) async {
    try {
      final deviceIndex = _userDevices.indexWhere(
        (userDevice) => userDevice.device.name == deviceName,
      );

      if (deviceIndex != -1) {
        final userDevice = _userDevices[deviceIndex];
        final updatedDevice = userDevice.device.copyWith(isOn: isOn);

        _userDevices[deviceIndex] = userDevice.copyWith(device: updatedDevice);
        await _saveUserDevices();

        // Send MQTT command to control physical device
        if (userDevice.device.mqttTopic.isNotEmpty) {
          await _sendMqttCommand(userDevice.device, isOn);
          print('📤 MQTT command sent for device: ${userDevice.device.name}');
        }

        // Save state to Firebase
        await _firebaseService.writeDeviceState(
          deviceName,
          isOn ? 'ON' : 'OFF',
          metadata: {
            'room': userDevice.roomName,
            'floor': userDevice.floorName,
            'type': userDevice.device.type,
            'mqtt_topic': userDevice.device.mqttTopic,
          },
        );

        print('✅ Device "$deviceName" state updated to ${isOn ? 'ON' : 'OFF'}');
        return true;
      }

      return false;
    } catch (e) {
      print('❌ Error updating device state: $e');
      return false;
    }
  }

  /// Get devices by room
  List<UserAddedDevice> getDevicesByRoom(String roomName, String floorName) {
    return _userDevices
        .where((userDevice) =>
            userDevice.roomName == roomName &&
            userDevice.floorName == floorName)
        .toList();
  }

  /// Get devices by floor
  List<UserAddedDevice> getDevicesByFloor(String floorName) {
    return _userDevices
        .where((userDevice) => userDevice.floorName == floorName)
        .toList();
  }

  /// Load user devices from local storage
  Future<void> _loadUserDevices() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final devicesJson = prefs.getString(_devicesKey);

      if (devicesJson != null) {
        final List<dynamic> devicesList = json.decode(devicesJson);
        _userDevices = devicesList
            .map((deviceData) => UserAddedDevice.fromJson(deviceData))
            .toList();
      }
    } catch (e) {
      print('❌ Error loading user devices: $e');
      _userDevices = [];
    }
  }

  /// Save user devices to local storage
  Future<void> _saveUserDevices() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final devicesJson = json.encode(
        _userDevices.map((userDevice) => userDevice.toJson()).toList(),
      );
      await prefs.setString(_devicesKey, devicesJson);
    } catch (e) {
      print('❌ Error saving user devices: $e');
    }
  }

  /// Save device to Firebase
  Future<void> _saveDeviceToFirebase(UserAddedDevice userDevice) async {
    try {
      await _firebaseService.writeDeviceState(
        userDevice.device.name,
        userDevice.device.isOn ? 'ON' : 'OFF',
        metadata: {
          'room': userDevice.roomName,
          'floor': userDevice.floorName,
          'type': userDevice.device.type,
          'mqtt_topic': userDevice.device.mqttTopic,
          'date_added': userDevice.dateAdded.toIso8601String(),
          'is_user_added': true,
        },
      );
    } catch (e) {
      print('❌ Error saving device to Firebase: $e');
    }
  }

  /// Get total active devices count
  int getTotalActiveDevices() {
    return _userDevices
        .where((userDevice) => userDevice.device.isOn && userDevice.isActive)
        .length;
  }

  /// Clear all user devices (for testing)
  Future<void> clearAllDevices() async {
    _userDevices.clear();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_devicesKey);
  }

  /// Send MQTT command based on device type
  Future<void> _sendMqttCommand(SmartDevice device, bool isOn) async {
    final mqttTopic = device.mqttTopic;
    if (mqttTopic.isEmpty) return;

    try {
      // Determine if this is an indoor device (ESP32-S3) or outdoor device (ESP32)
      bool isIndoorDevice = mqttTopic.startsWith('inside/');
      
      // Handle different device types
      switch (device.type.toLowerCase()) {
        case 'gate':
          // Enhanced gate control with Firebase state sync
          if (isOn) {
            // Smart logic: if gate is closed, open to walking mode (25%)
            // if already open, open fully (100%)
            final gateService = GateStateService();
            gateService.getCurrentGateState().then((currentState) {
              if (currentState.level <= 0) {
                // Closed - open to walking mode
                _mqttService.moveGateAbsolute(25);
              } else if (currentState.level < 100) {
                // Partially open - open fully
                _mqttService.moveGateAbsolute(100);
              } else {
                // Already fully open - no action needed
                print('🚪 Gate is already fully open');
              }
            });
          } else {
            // Close gate completely
            _mqttService.moveGateAbsolute(0);
          }
          break;

        case 'light':
        case 'led':
          // LED/Light devices use ON/OFF commands
          final command = isOn ? 'ON' : 'OFF';
          if (isIndoorDevice) {
            // Use indoor device command for ESP32-S3
            _mqttService.publishIndoorDeviceCommand(mqttTopic, command);
          } else {
            // Use regular command for ESP32
            _mqttService.publishDeviceCommand(mqttTopic, command);
          }
          break;

        case 'fan':
        case 'motor':
          // Motor/Fan devices might use different commands
          final command = isOn ? 'ON' : 'OFF';
          if (isIndoorDevice) {
            _mqttService.publishIndoorDeviceCommand(mqttTopic, command);
          } else {
            _mqttService.publishDeviceCommand(mqttTopic, command);
          }
          break;

        case 'awning':
        case 'curtain':
          // Awning/Curtain devices might use position commands
          final command = isOn ? 'OPEN' : 'CLOSE';
          if (isIndoorDevice) {
            _mqttService.publishIndoorDeviceCommand(mqttTopic, command);
          } else {
            _mqttService.publishDeviceCommand(mqttTopic, command);
          }
          break;

        default:
          // Default: Simple ON/OFF command
          final command = isOn ? 'ON' : 'OFF';
          if (isIndoorDevice) {
            _mqttService.publishIndoorDeviceCommand(mqttTopic, command);
          } else {
            _mqttService.publishDeviceCommand(mqttTopic, command);
          }
          break;
      }

    } catch (e) {
      print('❌ Error sending MQTT command: $e');
    }
  }
}

/// Model for user-added devices
class UserAddedDevice {
  final SmartDevice device;
  final String roomName;
  final String floorName;
  final DateTime dateAdded;
  final bool isActive;

  UserAddedDevice({
    required this.device,
    required this.roomName,
    required this.floorName,
    required this.dateAdded,
    required this.isActive,
  });

  UserAddedDevice copyWith({
    SmartDevice? device,
    String? roomName,
    String? floorName,
    DateTime? dateAdded,
    bool? isActive,
  }) {
    return UserAddedDevice(
      device: device ?? this.device,
      roomName: roomName ?? this.roomName,
      floorName: floorName ?? this.floorName,
      dateAdded: dateAdded ?? this.dateAdded,
      isActive: isActive ?? this.isActive,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'device': {
        'name': device.name,
        'type': device.type,
        'isOn': device.isOn,
        'icon': device.icon.codePoint,
        'mqttTopic': device.mqttTopic,
        'color': device.color.value,
      },
      'roomName': roomName,
      'floorName': floorName,
      'dateAdded': dateAdded.toIso8601String(),
      'isActive': isActive,
    };
  }

  factory UserAddedDevice.fromJson(Map<String, dynamic> json) {
    final deviceData = json['device'] as Map<String, dynamic>;

    return UserAddedDevice(
      device: SmartDevice(
        name: deviceData['name'],
        type: deviceData['type'],
        isOn: deviceData['isOn'],
        icon: IconData(deviceData['icon'], fontFamily: 'MaterialIcons'),
        mqttTopic: deviceData['mqttTopic'],
        color: Color(deviceData['color']),
      ),
      roomName: json['roomName'],
      floorName: json['floorName'],
      dateAdded: DateTime.parse(json['dateAdded']),
      isActive: json['isActive'] ?? true,
    );
  }
}
