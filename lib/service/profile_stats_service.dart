import 'dart:async';
import 'package:smart_home/service/device_state_service.dart';
import 'package:smart_home/service/mqtt_unified_service.dart';

/// Profile Statistics Service
/// Tính toán thống kê thực tế cho profile screen
class ProfileStatsService {
  static final ProfileStatsService _instance = ProfileStatsService._internal();
  factory ProfileStatsService() => _instance;
  ProfileStatsService._internal();

  final DeviceStateService _deviceStateService = DeviceStateService();
  
  // Device categories and their power consumption (watts per hour)
  static const Map<String, double> devicePowerConsumption = {
    // Outdoor devices
    'led_gate': 10.0,
    'led_around': 15.0,
    'yard_main_light': 20.0,
    
    // Indoor lights
    'kitchen_light': 8.0,
    'living_room_light': 12.0,
    'bedroom_light': 10.0,
    'corner_bedroom_light': 10.0,
    'yard_bedroom_light': 10.0,
    'worship_room_light': 15.0,
    'hallway_light': 6.0,
    'balcony_light': 20.0,
    
    // Climate devices (higher consumption)
    'fan_living_room': 60.0,
    'ac_living_room': 800.0,
    'ac_bedroom1': 700.0,
    'ac_bedroom2': 700.0,
  };

  // Room mapping
  static const Map<String, List<String>> roomDevices = {
    'Phòng khách': ['living_room_light', 'fan_living_room', 'ac_living_room'],
    'Bếp': ['kitchen_light'],
    'Phòng ngủ chính': ['bedroom_light'],
    'Phòng ngủ góc': ['corner_bedroom_light', 'ac_bedroom1'],
    'Phòng ngủ sân': ['yard_bedroom_light', 'ac_bedroom2'],
    'Phòng thờ': ['worship_room_light'],
    'Hành lang': ['hallway_light'],
    'Ban công': ['balcony_light'],
    'Ngoài trời': ['led_gate', 'led_around', 'yard_main_light'],
  };

  /// Get total number of devices
  int getTotalDevices() {
    return devicePowerConsumption.keys.length;
  }

  /// Get total number of rooms
  int getTotalRooms() {
    return roomDevices.keys.length;
  }

  /// Get number of active devices
  int getActiveDevices() {
    final states = _deviceStateService.currentStates;
    return states.values.where((isOn) => isOn).length;
  }

  /// Calculate estimated monthly savings compared to conventional system
  /// Based on LED vs incandescent bulbs and smart control vs manual control
  int getEstimatedMonthlySavings() {
    final states = _deviceStateService.currentStates;
    double totalSavings = 0.0;
    
    // Electricity cost in Vietnam: ~2,500 VND per kWh
    const double electricityCostPerKwh = 2500.0;
    
    // Estimate daily usage hours for different device types
    const Map<String, double> estimatedDailyHours = {
      'lights': 6.0, // Average 6 hours per day for lights
      'ac': 8.0,     // 8 hours for AC
      'fan': 10.0,   // 10 hours for fans
    };

    devicePowerConsumption.forEach((deviceId, powerWatts) {
      // Calculate savings based on device type
      double dailyHours = 0.0;
      double efficiencyGain = 0.0;
      
      if (deviceId.contains('light')) {
        dailyHours = estimatedDailyHours['lights']!;
        efficiencyGain = 0.8; // LED vs incandescent: 80% savings
      } else if (deviceId.contains('ac')) {
        dailyHours = estimatedDailyHours['ac']!;
        efficiencyGain = 0.3; // Smart AC control: 30% savings
      } else if (deviceId.contains('fan')) {
        dailyHours = estimatedDailyHours['fan']!;
        efficiencyGain = 0.2; // Smart fan control: 20% savings
      }

      if (dailyHours > 0) {
        // Calculate monthly consumption in kWh
        double monthlyKwh = (powerWatts / 1000.0) * dailyHours * 30;
        
        // Calculate savings in VND
        double savingsVnd = monthlyKwh * electricityCostPerKwh * efficiencyGain;
        totalSavings += savingsVnd;
      }
    });

    // Return savings in thousands of VND
    return (totalSavings / 1000).round();
  }

  /// Get room-wise device distribution
  Map<String, int> getRoomDeviceCount() {
    Map<String, int> roomCounts = {};
    
    roomDevices.forEach((roomName, devices) {
      roomCounts[roomName] = devices.length;
    });
    
    return roomCounts;
  }

  /// Get active devices by room
  Map<String, int> getActiveDevicesByRoom() {
    final states = _deviceStateService.currentStates;
    Map<String, int> activeByRoom = {};
    
    roomDevices.forEach((roomName, devices) {
      int activeCount = 0;
      for (String deviceId in devices) {
        if (states[deviceId] == true) {
          activeCount++;
        }
      }
      activeByRoom[roomName] = activeCount;
    });
    
    return activeByRoom;
  }

  /// Get current power consumption in watts
  double getCurrentPowerConsumption() {
    final states = _deviceStateService.currentStates;
    double totalPower = 0.0;
    
    devicePowerConsumption.forEach((deviceId, powerWatts) {
      if (states[deviceId] == true) {
        totalPower += powerWatts;
      }
    });
    
    return totalPower;
  }

  /// Get estimated daily cost in VND
  double getEstimatedDailyCost() {
    double currentPowerWatts = getCurrentPowerConsumption();
    
    // Estimate average daily usage (considering devices are not on 24/7)
    double estimatedDailyKwh = 0.0;
    final states = _deviceStateService.currentStates;
    
    devicePowerConsumption.forEach((deviceId, powerWatts) {
      if (states[deviceId] == true) {
        double dailyHours = 0.0;
        
        if (deviceId.contains('light')) {
          dailyHours = 6.0; // Lights: 6 hours/day average
        } else if (deviceId.contains('ac')) {
          dailyHours = 8.0; // AC: 8 hours/day average
        } else if (deviceId.contains('fan')) {
          dailyHours = 10.0; // Fans: 10 hours/day average
        }
        
        estimatedDailyKwh += (powerWatts / 1000.0) * dailyHours;
      }
    });
    
    // Electricity cost: ~2,500 VND per kWh
    return estimatedDailyKwh * 2500.0;
  }

  /// Listen to device state changes and update stats
  void startListening() {
    _deviceStateService.stateStream.listen((states) {
      // Stats will be recalculated automatically when getters are called
    });
  }

  void dispose() {
    // Clean up if needed
  }
}
