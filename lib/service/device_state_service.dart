import 'dart:async';
import 'dart:convert';

/// Device State Management Service
/// Quản lý trạng thái thiết bị và đồng bộ với ESP32 & Firebase
class DeviceStateService {
  static final DeviceStateService _instance = DeviceStateService._internal();
  factory DeviceStateService() => _instance;
  DeviceStateService._internal();

  // Device state storage
  final Map<String, bool> _deviceStates = {};
  final Map<String, DateTime> _lastUpdated = {};
  
  // Stream controllers for state changes
  final StreamController<Map<String, bool>> _stateController = 
      StreamController<Map<String, bool>>.broadcast();
  final StreamController<DeviceStateUpdate> _updateController = 
      StreamController<DeviceStateUpdate>.broadcast();

  // Getters
  Stream<Map<String, bool>> get stateStream => _stateController.stream;
  Stream<DeviceStateUpdate> get updateStream => _updateController.stream;
  Map<String, bool> get currentStates => Map<String, bool>.from(_deviceStates);

  /// Get device state (returns false if not found)
  bool getDeviceState(String deviceId) {
    return _deviceStates[deviceId] ?? false;
  }

  /// Update device state locally (from MQTT or UI)
  void updateDeviceState(String deviceId, bool isOn, {String? source}) {
    bool previousState = _deviceStates[deviceId] ?? false;
    
    // Only update if state actually changed
    if (previousState != isOn) {
      _deviceStates[deviceId] = isOn;
      _lastUpdated[deviceId] = DateTime.now();
      
      print('🔄 Device state updated: $deviceId = $isOn (source: ${source ?? "unknown"})');
      
      // Emit state change
      _stateController.add(currentStates);
      _updateController.add(DeviceStateUpdate(
        deviceId: deviceId,
        isOn: isOn,
        timestamp: DateTime.now(),
        source: source ?? 'unknown',
      ));
    }
  }

  /// Update multiple device states at once
  void updateMultipleStates(Map<String, bool> states, {String? source}) {
    bool hasChanges = false;
    
    states.forEach((deviceId, isOn) {
      bool previousState = _deviceStates[deviceId] ?? false;
      if (previousState != isOn) {
        _deviceStates[deviceId] = isOn;
        _lastUpdated[deviceId] = DateTime.now();
        hasChanges = true;
      }
    });
    
    if (hasChanges) {
      print('🔄 Multiple device states updated (source: ${source ?? "unknown"})');
      _stateController.add(currentStates);
      
      // Emit individual updates
      states.forEach((deviceId, isOn) {
        _updateController.add(DeviceStateUpdate(
          deviceId: deviceId,
          isOn: isOn,
          timestamp: DateTime.now(),
          source: source ?? 'unknown',
        ));
      });
    }
  }

  /// Parse device status from ESP32 JSON
  void parseDeviceStatusJson(String jsonString) {
    try {
      final Map<String, dynamic> data = json.decode(jsonString);
      String deviceId = data['device'] ?? '';
      String state = data['state'] ?? 'OFF';
      int timestamp = data['timestamp'] ?? 0;
      
      if (deviceId.isNotEmpty) {
        updateDeviceState(deviceId, state.toUpperCase() == 'ON', source: 'ESP32_JSON');
      }
    } catch (e) {
      print('❌ Error parsing device status JSON: $e');
    }
  }

  /// Get last update time for device
  DateTime? getLastUpdated(String deviceId) {
    return _lastUpdated[deviceId];
  }

  /// Check if device state is stale (older than 5 minutes)
  bool isStateStale(String deviceId) {
    final lastUpdate = _lastUpdated[deviceId];
    if (lastUpdate == null) return true;
    
    return DateTime.now().difference(lastUpdate).inMinutes > 5;
  }

  /// Get all stale devices
  List<String> getStaleDevices() {
    return _deviceStates.keys.where((deviceId) => isStateStale(deviceId)).toList();
  }

  /// Reset all device states (useful for app restart)
  void resetAllStates() {
    _deviceStates.clear();
    _lastUpdated.clear();
    _stateController.add(currentStates);
    print('🔄 All device states reset');
  }

  /// Initialize with default states for common devices
  void initializeDefaultStates() {
    final defaultStates = {
      'led_gate': false,
      'led_around': false,
      'kitchen_light': false,
      'living_room_light': false,
      'bedroom_light': false,
      'corner_bedroom_light': false,
      'yard_bedroom_light': false,
      'worship_room_light': false,
      'hallway_light': false,
      'balcony_light': false,
    };
    
    updateMultipleStates(defaultStates, source: 'INIT');
    print('✅ Default device states initialized');
  }

  /// Dispose resources
  void dispose() {
    _stateController.close();
    _updateController.close();
  }
}

/// Device state update event
class DeviceStateUpdate {
  final String deviceId;
  final bool isOn;
  final DateTime timestamp;
  final String source;

  DeviceStateUpdate({
    required this.deviceId,
    required this.isOn,
    required this.timestamp,
    required this.source,
  });

  @override
  String toString() {
    return 'DeviceStateUpdate(device: $deviceId, state: $isOn, source: $source, time: $timestamp)';
  }
}
