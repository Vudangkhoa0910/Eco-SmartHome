import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'package:smart_home/service/firebase_batch_service.dart';
import 'package:smart_home/service/gate_state_service.dart';
import 'package:smart_home/service/device_state_service.dart';
import 'package:smart_home/service/optimized_device_status_service.dart';

/// Unified MQTT Service that consolidates mqtt_service.dart and mqtt_service_simple.dart
/// Features:
/// - Complete device state synchronization
/// - Simplified logic for LED Around and all devices
/// - Firebase integration with optimized batching
/// - Gate control with multiple levels
/// - Indoor and outdoor device management
/// - Real-time state updates and streams
class MqttUnifiedService {
  static const String _broker = 'i0bf1b65.ala.asia-southeast1.emqxsl.com';
  static const int _port = 8883;
  static const String _username = 'af07dd3c';
  static const String _password = 'U0ofxmA6rbhSp4_O';
  static const String _clientIdentifier = 'flutter_unified_client';

  // MQTT topics - Outdoor ESP32 Dev
  static const String topicTemp = 'khoasmarthome/temperature';
  static const String topicHumid = 'khoasmarthome/humidity';
  static const String topicCurrent = 'khoasmarthome/current';
  static const String topicVoltage = 'khoasmarthome/voltage';
  static const String topicPower = 'khoasmarthome/power';
  static const String topicLedGate = 'khoasmarthome/led_gate';
  static const String topicLedAround = 'khoasmarthome/led_around';
  static const String topicMotor = 'khoasmarthome/motor';
  static const String topicGateLevel = 'khoasmarthome/gate_level';
  static const String topicGateStatus = 'khoasmarthome/gate_status';
  
  // Device status topics
  static const String topicDeviceStatus = 'khoasmarthome/device_status';
  static const String topicLedGateStatus = 'khoasmarthome/led_gate/status';
  static const String topicLedAroundStatus = 'khoasmarthome/led_around/status';
  static const String topicStatusRequest = 'khoasmarthome/status_request';

  // Indoor device status sync topics (ESP32-S3 Indoor)
  static const String topicIndoorStatusRequest = 'inside/device_status/request';
  static const String topicIndoorStatusResponse = 'inside/device_status/response';

  // Indoor ESP32-S3 topics
  static const String topicCurrentInside = 'inside/current';
  static const String topicVoltageInside = 'inside/voltage';
  static const String topicPowerInside = 'inside/power';
  
  // Floor 1 devices
  static const String topicKitchenLight = 'inside/kitchen_light';
  static const String topicLivingRoomLight = 'inside/living_room_light';
  static const String topicBedroomLight = 'inside/bedroom_light';
  
  // Floor 2 devices
  static const String topicCornerBedroomLight = 'inside/corner_bedroom_light';
  static const String topicYardBedroomLight = 'inside/yard_bedroom_light';
  static const String topicWorshipRoomLight = 'inside/worship_room_light';
  static const String topicHallwayLight = 'inside/hallway_light';
  static const String topicBalconyLight = 'inside/balcony_light';

  // Climate control topics - Combined AC and Fan
  static const String topicClimateControl = 'inside/climate_control';

  MqttServerClient? _client;
  bool _isConnected = false;
  bool _enableFirebase = true;

  // StreamControllers
  final StreamController<SensorData> _sensorDataController =
      StreamController<SensorData>.broadcast();
  final StreamController<bool> _connectionController =
      StreamController<bool>.broadcast();
  final StreamController<int> _gateStateController =
      StreamController<int>.broadcast();
  final StreamController<Map<String, dynamic>> _gateStatusController =
      StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<Map<String, bool>> _indoorDeviceStatusController =
      StreamController<Map<String, bool>>.broadcast();

  // Firebase services
  final FirebaseBatchService _batchService = FirebaseBatchService();
  
  // Device state service
  final DeviceStateService _deviceStateService = DeviceStateService();
  
  // Optimized device status service - ADDED: Để giảm tải hệ thống
  final OptimizedDeviceStatusService _optimizedStatusService = OptimizedDeviceStatusService();

  // Current data
  SensorData _currentData = SensorData.defaultData();
  SensorData _currentDataInside = SensorData.defaultData();
  int _currentGateLevel = 0;

  // Throttling
  DateTime? _lastFirebaseWrite;
  DateTime? _lastDeviceWrite;
  static const Duration _firebaseWriteInterval = Duration(minutes: 5);
  static const Duration _deviceWriteInterval = Duration(seconds: 30);
  final Map<String, bool> _lastLightStates = {};

  // Getters
  Stream<SensorData> get sensorDataStream => _sensorDataController.stream;
  Stream<bool> get connectionStream => _connectionController.stream;
  Stream<int> get gateStateStream => _gateStateController.stream;
  Stream<Map<String, dynamic>> get gateStatusStream =>
      _gateStatusController.stream;
  Stream<Map<String, bool>> get indoorDeviceStatusStream =>
      _indoorDeviceStatusController.stream;
  bool get isConnected => _isConnected;
  int get currentGateLevel => _currentGateLevel;
  SensorData get currentData => _currentData;
  SensorData get currentDataInside => _currentDataInside;
  
  // Device state getters
  DeviceStateService get deviceStateService => _deviceStateService;
  Stream<Map<String, bool>> get deviceStateStream => _deviceStateService.stateStream;
  
  // ADDED: Optimized device status service getter
  OptimizedDeviceStatusService get optimizedStatusService => _optimizedStatusService;

  // Initialize MQTT
  Future<void> initialize() async {
    await connect();
  }

  Future<void> connect() async {
    try {
      final clientId = '${_clientIdentifier}_${DateTime.now().millisecondsSinceEpoch}';
      _client = MqttServerClient.withPort(_broker, clientId, _port);
      _client!.secure = true;
      _client!.securityContext = SecurityContext.defaultContext;
      _client!.keepAlivePeriod = 20;
      _client!.onDisconnected = _onDisconnected;
      _client!.onConnected = _onConnected;
      _client!.autoReconnect = true;

      final connMessage = MqttConnectMessage()
          .withClientIdentifier(clientId)
          .authenticateAs(_username, _password)
          .withWillTopic('willtopic')
          .withWillMessage('My Will message')
          .startClean()
          .withWillQos(MqttQos.atLeastOnce);

      _client!.connectionMessage = connMessage;

      await _client!.connect();
    } catch (e) {
      print('❌ MQTT connection failed: $e');
      _client?.disconnect();
    }

    if (_client!.connectionStatus!.state == MqttConnectionState.connected) {
      print('✅ MQTT Connected');
      _subscribeToTopics();
    } else {
      print('❌ MQTT Connection failed');
    }
  }

  void _onConnected() {
    _isConnected = true;
    _connectionController.add(true);
    print('✅ MQTT Connected');

    // Initialize device states
    _deviceStateService.initializeDefaultStates();
    
    // Wait a bit for connection to fully stabilize before sending requests
    Future.delayed(const Duration(seconds: 1), () {
      if (_isConnected && _client?.connectionStatus?.state == MqttConnectionState.connected) {
        // Initialize gate state when connected
        initializeGateState();
        
        // Request all device status from ESP32
        _requestAllDeviceStatus();
      }
    });
    
    // Request indoor device status from ESP32-S3 Indoor with additional delay
    Future.delayed(const Duration(seconds: 3), () {
      if (_isConnected && _client?.connectionStatus?.state == MqttConnectionState.connected) {
        requestIndoorDeviceStatus();
      }
    });
  }

  void _onDisconnected() {
    _isConnected = false;
    _connectionController.add(false);
    print('❌ MQTT Disconnected');
  }

  void _subscribeToTopics() {
    final topics = [
      // Outdoor ESP32 topics
      topicTemp,
      topicHumid,
      topicCurrent,
      topicVoltage,
      topicPower,
      topicGateStatus,
      
      // Device status topics
      topicDeviceStatus,
      topicLedGateStatus,
      topicLedAroundStatus,
      
      // Indoor device status topics
      topicIndoorStatusResponse,
      
      // Indoor ESP32-S3 sensor topics
      topicCurrentInside,
      topicVoltageInside,
      topicPowerInside,
      
      // Indoor device status topics
      '$topicKitchenLight/status',
      '$topicLivingRoomLight/status',
      '$topicBedroomLight/status',
      '$topicCornerBedroomLight/status',
      '$topicYardBedroomLight/status',
      '$topicWorshipRoomLight/status',
      '$topicHallwayLight/status',
      '$topicBalconyLight/status',
    ];

    for (String topic in topics) {
      _client!.subscribe(topic, MqttQos.atLeastOnce);
    }

    _client!.updates!.listen((List<MqttReceivedMessage<MqttMessage?>>? c) {
      final recMess = c![0].payload as MqttPublishMessage;
      final pt =
          MqttPublishPayload.bytesToStringAsString(recMess.payload.message);
      final topic = c[0].topic;

      _handleMessage(topic, pt);
    });
  }

  void _handleMessage(String topic, String message) {
    if (topic == topicGateStatus) {
      _handleGateStatus(message);
      return;
    }

    // Handle device status messages
    if (topic == topicDeviceStatus) {
      _deviceStateService.parseDeviceStatusJson(message);
      return;
    }
    
    // Handle indoor device status response
    if (topic == topicIndoorStatusResponse) {
      _handleIndoorDeviceStatus(message);
      return;
    }
    
    // Handle individual device status
    if (topic == topicLedGateStatus) {
      final isOn = message.toUpperCase() == 'ON';
      _deviceStateService.updateDeviceState('led_gate', isOn, source: 'ESP32');
      // ADDED: Cập nhật cache tối ưu
      _optimizedStatusService.updateDeviceState('led_gate', isOn);
      return;
    }
    
    if (topic == topicLedAroundStatus) {
      // FIXED: No more inverted logic - direct state mapping
      final isOn = message.toUpperCase() == 'ON';
      _deviceStateService.updateDeviceState('led_around', isOn, source: 'ESP32');
      // ADDED: Cập nhật cache tối ưu
      _optimizedStatusService.updateDeviceState('led_around', isOn);
      return;
    }

    // Handle indoor device status
    if (topic.startsWith('inside/') && topic.endsWith('/status')) {
      final deviceId = topic.replaceAll('inside/', '').replaceAll('/status', '');
      final isOn = message.toUpperCase() == 'ON';
      _deviceStateService.updateDeviceState(deviceId, isOn, source: 'ESP32-Indoor');
      // ADDED: Cập nhật cache tối ưu cho indoor devices
      _optimizedStatusService.updateDeviceState(deviceId, isOn);
      return;
    }

    // Handle sensor data
    final value = double.tryParse(message) ?? 0.0;

    // Handle outdoor ESP32 data
    if (topic.startsWith('khoasmarthome/')) {
      switch (topic) {
        case topicTemp:
          _currentData = _currentData.copyWith(temperature: value);
          break;
        case topicHumid:
          _currentData = _currentData.copyWith(humidity: value);
          break;
        case topicCurrent:
          _currentData = _currentData.copyWith(current: value);
          break;
        case topicVoltage:
          _currentData = _currentData.copyWith(voltage: value);
          break;
        case topicPower:
          _currentData = _currentData.copyWith(power: value);
          break;
      }
      _currentData = _currentData.copyWith(lastUpdated: DateTime.now());
    }
    
    // Handle indoor ESP32-S3 data
    else if (topic.startsWith('inside/')) {
      switch (topic) {
        case topicCurrentInside:
          _currentDataInside = _currentDataInside.copyWith(current: value);
          break;
        case topicVoltageInside:
          _currentDataInside = _currentDataInside.copyWith(voltage: value);
          break;
        case topicPowerInside:
          _currentDataInside = _currentDataInside.copyWith(power: value);
          break;
      }
      _currentDataInside = _currentDataInside.copyWith(lastUpdated: DateTime.now());
    }

    _sensorDataController.add(_currentData);

    // Write to Firebase (heavily throttled)
    if (_enableFirebase && _shouldWriteToFirebase()) {
      _batchService.writeSensorDataOptimized(_currentData).catchError((error) {
        print('⚠️ Firebase write error: $error');
        return false;
      });
      _lastFirebaseWrite = DateTime.now();
    }
  }

  void _handleGateStatus(String statusMessage) {
    try {
      print('🔍 [DEBUG] Parsing gate status: "$statusMessage"');
      
      // Handle ESP32 format: "25:false:LEVEL_25" or "Level 25:STOPPED" or "0:STOPPED"
      final parts = statusMessage.split(':');
      
      if (parts.length >= 3) {
        // New ESP32 format: "25:false:LEVEL_25" (percentage:isMoving:description)
        final percentage = int.tryParse(parts[0]) ?? 0;
        final isMovingStr = parts[1].toLowerCase().trim();
        final isMoving = isMovingStr == 'true' || isMovingStr.contains('moving') || isMovingStr.contains('running');
        
        // Convert percentage to level value for internal storage
        int levelValue = 0;
        if (percentage <= 0) {
          levelValue = 0;
        } else if (percentage <= 33) {
          levelValue = 1;
        } else if (percentage <= 66) {
          levelValue = 2;
        } else {
          levelValue = 3;
        }
        
        _currentGateLevel = levelValue;
        _gateStateController.add(levelValue);

        _gateStatusController.add({
          'level': percentage,
          'isMoving': isMoving,
          'description': _getGateDescription(percentage, isMoving),
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        });

        print('🚪 Gate status updated: Level $levelValue -> $percentage% (moving: $isMoving)');
        
      } else if (parts.length >= 2) {
        // Handle different formats
        if (statusMessage.toLowerCase().contains('level')) {
          // Format: "Level 25:STOPPED" or "Level 25"
          final levelPart = parts[0].toLowerCase().replaceAll('level', '').trim();
          final level = int.tryParse(levelPart) ?? 0;
          final status = parts.length > 1 ? parts[1] : 'STOPPED';
          
          // If ESP32 sends percentage directly, use it
          int percentage = level;
          int levelValue = 0;
          
          // Convert percentage to level value for internal storage
          if (percentage <= 0) {
            levelValue = 0;
          } else if (percentage <= 33) {
            levelValue = 1;
          } else if (percentage <= 66) {
            levelValue = 2;
          } else {
            levelValue = 3;
          }
          
          _currentGateLevel = levelValue;
          _gateStateController.add(levelValue);

          _gateStatusController.add({
            'level': percentage,
            'isMoving': status.contains('MOVING') || status.contains('RUNNING'),
            'description': _getGateDescription(percentage, status.contains('MOVING')),
            'timestamp': DateTime.now().millisecondsSinceEpoch,
          });

          print('🚪 Gate status updated: Level $levelValue -> $percentage% ($status)');
        } else {
          // Handle traditional format: "0:STOPPED", "1:STOPPED", etc.
          final level = int.tryParse(parts[0]) ?? 0;
          final status = parts[1];

          _currentGateLevel = level;
          _gateStateController.add(level);

          // Convert ESP32 level to percentage for UI
          int percentage;
          switch (level) {
            case 0:
              percentage = 0;
              break;
            case 1:
              percentage = 25;
              break;
            case 2:
              percentage = 50;
              break;
            case 3:
              percentage = 100;
              break;
            default:
              percentage = 0;
          }

          _gateStatusController.add({
            'level': percentage,
            'isMoving': status.contains('MOVING') || status.contains('RUNNING'),
            'description': _getGateDescription(percentage, status.contains('MOVING')),
            'timestamp': DateTime.now().millisecondsSinceEpoch,
          });

          print('🚪 Gate status updated: Level $level -> $percentage% ($status)');
        }
      }
    } catch (e) {
      print('❌ Error parsing gate status: $e');
    }
  }

  String _getGateDescription(int percentage, bool isMoving) {
    if (isMoving) return 'Đang di chuyển...';

    switch (percentage) {
      case 0:
        return 'Đóng hoàn toàn';
      case 25:
        return 'Mở 1/4 - Người đi bộ';
      case 50:
        return 'Mở 1/2 - Xe máy';
      case 75:
        return 'Mở 3/4 - Xe hơi nhỏ';
      case 100:
        return 'Mở hoàn toàn - Xe tải';
      default:
        return 'Mở $percentage%';
    }
  }

  void _handleIndoorDeviceStatus(String statusMessage) {
    try {
      final Map<String, dynamic> statusData = 
          Map<String, dynamic>.from(json.decode(statusMessage) as Map);
      
      final Map<String, bool> deviceStates = {};
      
      statusData.forEach((key, value) {
        if (key != 'timestamp' && value is bool) {
          deviceStates[key] = value;
          _deviceStateService.updateDeviceState(key, value, source: 'ESP32-Indoor');
        }
      });
      
      _indoorDeviceStatusController.add(deviceStates);
      
      print('🏠 Indoor device status updated: ${deviceStates.length} devices');
      print('📊 Status: $deviceStates');
      
    } catch (e) {
      print('❌ Error parsing indoor device status: $e');
    }
  }

  bool _shouldWriteToFirebase() {
    if (_lastFirebaseWrite == null) return true;
    return DateTime.now().difference(_lastFirebaseWrite!) >=
        _firebaseWriteInterval;
  }

  bool _shouldWriteDeviceState() {
    if (_lastDeviceWrite == null) return true;
    return DateTime.now().difference(_lastDeviceWrite!) >= _deviceWriteInterval;
  }

  void publishDeviceCommand(String topic, String command) {
    if (!_isConnected || _client == null) {
      print('❌ MQTT not connected, cannot send: $topic = $command');
      return;
    }
    
    if (_client!.connectionStatus?.state != MqttConnectionState.connected) {
      print('❌ MQTT connection state invalid for: $topic = $command (State: ${_client!.connectionStatus?.state})');
      return;
    }
    
    try {
      final builder = MqttClientPayloadBuilder();
      builder.addString(command);
      _client!.publishMessage(topic, MqttQos.atLeastOnce, builder.payload!);
      print('📤 MQTT: $topic = $command');
    } catch (e) {
      print('❌ Error publishing MQTT message: $e');
    }
  }

  // ========== DEVICE CONTROLS - SIMPLIFIED LOGIC ==========

  /// LED Gate control - Direct logic, no inversion
  void controlLedGate(bool isOn) {
    final command = isOn ? 'ON' : 'OFF';
    publishDeviceCommand(topicLedGate, command);
    _logDeviceStateChange('led_gate', isOn, 'entrance', 'light');
  }

  /// LED Around control - FIXED: Direct logic, no inversion
  void controlLedAround(bool isOn) {
    final command = isOn ? 'ON' : 'OFF';
    publishDeviceCommand(topicLedAround, command);
    _logDeviceStateChange('led_around', isOn, 'garden', 'light');
  }

  /// Yard Main Light control - Direct logic
  void controlYardMainLight(bool isOn) {
    final command = isOn ? 'ON' : 'OFF';
    publishDeviceCommand('khoasmarthome/yard_main_light', command);
    _logDeviceStateChange('yard_main_light', isOn, 'yard', 'light');
  }

  // ========== GATE CONTROLS ==========

  void controlGateLevel(int level) {
    if (level < 0 || level > 3) return;

    // 🚨 CRITICAL FIX: Convert internal level to percentage for ESP32
    int percentage = level == 0 ? 0 : level == 1 ? 25 : level == 2 ? 50 : 100;
    
    publishDeviceCommand(topicGateLevel, percentage.toString());
    print('🚪 Điều khiển cổng: Level $level -> $percentage% sent to ESP32');

    if (_enableFirebase) {
      // 🚨 Convert level back to percentage for Firebase storage
      _saveGateStateToFirebase(percentage);
    }
  }

  Future<void> publishGateControl(int percentage,
      {bool shouldRequestStatus = false}) async {
    try {
      // 🚨 CRITICAL FIX: Send PERCENTAGE directly to ESP32, not internal level
      // ESP32 expects 0-100% values, NOT 0-3 level values

      if (shouldRequestStatus) {
        publishDeviceCommand('khoasmarthome/status_request', 'GATE_STATUS');
        print('📡 Requesting gate status from ESP32');
        return;
      }

      // 🚨 SEND PERCENTAGE DIRECTLY: ESP32 will convert to internal level
      publishDeviceCommand(topicGateLevel, percentage.toString());
      print('🚪 Gate control: $percentage% sent directly to ESP32');

      // Convert percentage to internal level for local tracking
      int level;
      if (percentage <= 0) {
        level = 0;
      } else if (percentage <= 33) {
        level = 1;
      } else if (percentage <= 66) {
        level = 2;
      } else {
        level = 3;
      }

      _currentGateLevel = level;
      _gateStateController.add(level);

      if (_enableFirebase) {
        // 🚨 FIX: Save ACTUAL percentage received from ESP32, not internal level
        _saveGateStateToFirebase(percentage);
      }
    } catch (e) {
      print('❌ Error controlling gate: $e');
      rethrow;
    }
  }

  void controlMotor(String direction) {
    if (direction == 'FORWARD' || direction == 'ON') {
      controlGateLevel(_currentGateLevel == 0 ? 3 : 0);
    } else {
      publishDeviceCommand(topicMotor, direction);
    }
  }

  // ========== INDOOR DEVICE CONTROLS ==========

  void controlKitchenLight(bool isOn) {
    final command = isOn ? 'ON' : 'OFF';
    publishDeviceCommand(topicKitchenLight, command);
    _logIndoorDeviceState('kitchen_light', command, 'floor_1', 'kitchen', 8.0);
  }

  void controlLivingRoomLight(bool isOn) {
    final command = isOn ? 'ON' : 'OFF';
    publishDeviceCommand(topicLivingRoomLight, command);
    _logIndoorDeviceState('living_room_light', command, 'floor_1', 'living_room', 12.0);
  }

  void controlBedroomLight(bool isOn) {
    final command = isOn ? 'ON' : 'OFF';
    publishDeviceCommand(topicBedroomLight, command);
    _logIndoorDeviceState('bedroom_light', command, 'floor_1', 'bedroom', 10.0);
  }

  void controlCornerBedroomLight(bool isOn) {
    final command = isOn ? 'ON' : 'OFF';
    publishDeviceCommand(topicCornerBedroomLight, command);
    _logIndoorDeviceState('corner_bedroom_light', command, 'floor_2', 'corner_bedroom', 10.0);
  }

  void controlYardBedroomLight(bool isOn) {
    final command = isOn ? 'ON' : 'OFF';
    publishDeviceCommand(topicYardBedroomLight, command);
    _logIndoorDeviceState('yard_bedroom_light', command, 'floor_2', 'yard_bedroom', 10.0);
  }

  void controlWorshipRoomLight(bool isOn) {
    final command = isOn ? 'ON' : 'OFF';
    publishDeviceCommand(topicWorshipRoomLight, command);
    _logIndoorDeviceState('worship_room_light', command, 'floor_2', 'worship_room', 15.0);
  }

  void controlHallwayLight(bool isOn) {
    final command = isOn ? 'ON' : 'OFF';
    publishDeviceCommand(topicHallwayLight, command);
    _logIndoorDeviceState('hallway_light', command, 'floor_2', 'hallway', 6.0);
  }

  void controlBalconyLight(bool isOn) {
    final command = isOn ? 'ON' : 'OFF';
    publishDeviceCommand(topicBalconyLight, command);
    _logIndoorDeviceState('balcony_light', command, 'floor_2', 'balcony', 20.0);
  }

  // ========== ENHANCED INDOOR DEVICE CONTROLS ==========

  /// 🌟 UNIFIED CLIMATE CONTROL: Combined Fan + AC control via single topic
  /// Sends JSON format: {"device": "device_name", "command": "ON/OFF"}
  Future<void> publishClimateControlCommand(String deviceName, String command) async {
    if (!_isConnected || _client == null) {
      print('❌ MQTT not connected, cannot send climate control command');
      return;
    }
    
    try {
      // Create JSON payload for climate control
      final jsonPayload = '{"device": "$deviceName", "command": "$command"}';
      
      print('🌟 [CLIMATE] Publishing command: $jsonPayload to $topicClimateControl');
      
      await _client!.publishMessage(
        topicClimateControl,
        MqttQos.atLeastOnce,
        MqttClientPayloadBuilder().addString(jsonPayload).payload!,
      );
      
      print('✅ [CLIMATE] Command sent successfully: $deviceName = $command');
    } catch (e) {
      print('❌ Error publishing climate control command: $e');
    }
  }

  // 🌀 FAN CONTROLS via unified climate control
  Future<void> publishFanLivingRoomCommand(String command) async {
    print('🌀 [DEBUG] Publishing Fan Living Room command: $command via unified climate control');
    await publishClimateControlCommand('fan_living_room', command);
    print('🌀 [DEBUG] Fan Living Room command sent successfully');
  }

  // ❄️ AC CONTROLS via unified climate control
  Future<void> publishACLivingRoomCommand(String command) async {
    print('❄️ [DEBUG] Publishing AC Living Room command: $command via unified climate control');
    await publishClimateControlCommand('ac_living_room', command);
    print('❄️ [DEBUG] AC Living Room command sent successfully');
  }

  Future<void> publishACBedroom1Command(String command) async {
    print('❄️ [DEBUG] Publishing AC Bedroom1 command: $command via unified climate control');
    await publishClimateControlCommand('ac_bedroom1', command);
    print('❄️ [DEBUG] AC Bedroom1 command sent successfully');
  }

  Future<void> publishACBedroom2Command(String command) async {
    print('❄️ [DEBUG] Publishing AC Bedroom2 command: $command via unified climate control');
    await publishClimateControlCommand('ac_bedroom2', command);
    print('❄️ [DEBUG] AC Bedroom2 command sent successfully');
  }

  /// 💡 INDOOR DEVICE COMMAND: For lights and other individual devices
  /// Climate devices (Fan/AC) should use publishClimateControlCommand instead
  Future<void> publishIndoorDeviceCommand(String deviceTopic, String command) async {
    if (!_isConnected || _client == null) {
      print('❌ MQTT not connected, cannot send: $deviceTopic = $command');
      return;
    }
    
    try {
      print('🏠 Publishing indoor device command: $deviceTopic = $command');
      
      await _client!.publishMessage(
        deviceTopic,
        MqttQos.atLeastOnce,
        MqttClientPayloadBuilder().addString(command).payload!,
      );
      
      print('✅ Indoor device command sent: $deviceTopic = $command');
    } catch (e) {
      print('❌ Error publishing indoor device command: $e');
    }
  }

  // ========== DEVICE STATUS REQUESTS ==========

  Future<void> _requestAllDeviceStatus() async {
    if (!_isConnected || _client == null) {
      print('❌ MQTT not connected for device status request');
      return;
    }
    
    // Double check connection state
    if (_client!.connectionStatus?.state != MqttConnectionState.connected) {
      print('❌ MQTT connection state is not connected: ${_client!.connectionStatus?.state}');
      return;
    }
    
    try {
      await Future.delayed(const Duration(milliseconds: 1000));
      
      print('📡 Requesting all device status from ESP32...');
      await _client!.publishMessage(
        topicStatusRequest,
        MqttQos.atLeastOnce,
        MqttClientPayloadBuilder().addString('ALL_DEVICES').payload!,
      );
      
      await Future.delayed(const Duration(milliseconds: 500));
      await _client!.publishMessage(
        topicStatusRequest,
        MqttQos.atLeastOnce,
        MqttClientPayloadBuilder().addString('LED_GATE').payload!,
      );
      
      await Future.delayed(const Duration(milliseconds: 200));
      await _client!.publishMessage(
        topicStatusRequest,
        MqttQos.atLeastOnce,
        MqttClientPayloadBuilder().addString('LED_AROUND').payload!,
      );
      
      print('✅ Device status requests sent');
    } catch (e) {
      print('❌ Error requesting device status: $e');
    }
  }

  Future<void> requestDeviceStatus([String? specificDevice]) async {
    if (!_isConnected || _client == null) return;
    
    try {
      String command = specificDevice ?? 'ALL_DEVICES';
      print('📡 Requesting device status: $command');
      
      await _client!.publishMessage(
        topicStatusRequest,
        MqttQos.atLeastOnce,
        MqttClientPayloadBuilder().addString(command).payload!,
      );
    } catch (e) {
      print('❌ Error requesting device status: $e');
    }
  }

  Future<void> requestIndoorDeviceStatus() async {
    if (!_isConnected || _client == null) {
      print('❌ MQTT not connected for indoor device status request');
      return;
    }
    
    // Double check connection state
    if (_client!.connectionStatus?.state != MqttConnectionState.connected) {
      print('❌ MQTT connection state is not connected: ${_client!.connectionStatus?.state}');
      return;
    }
    
    try {
      print('🏠 Requesting indoor device status...');
      
      await _client!.publishMessage(
        topicIndoorStatusRequest,
        MqttQos.atLeastOnce,
        MqttClientPayloadBuilder().addString('get_all_status').payload!,
      );
      
      print('✅ Indoor device status request sent');
    } catch (e) {
      print('❌ Error requesting indoor device status: $e');
    }
  }

  // ========== GATE STATE MANAGEMENT ==========

  Future<void> initializeGateState() async {
    try {
      final gateService = GateStateService();
      final GateState currentState = await gateService.getCurrentGateState();

      // Convert Firebase percentage to internal level
      int level;
      if (currentState.level <= 0) {
        level = 0;
      } else if (currentState.level <= 33) {
        level = 1;
      } else if (currentState.level <= 66) {
        level = 2;
      } else {
        level = 3;
      }

      _currentGateLevel = level;
      _gateStateController.add(level);

      _gateStatusController.add({
        'level': currentState.level,
        'isMoving': currentState.isMoving,
        'description': _getGateDescription(currentState.level, currentState.isMoving),
        'timestamp': currentState.timestamp.millisecondsSinceEpoch,
      });

      print('🚪 Gate state initialized from Firebase: ${currentState.level}% (Level $level)');
      
      // Send current Firebase state to ESP32 to sync hardware with app state
      if (currentState.level > 0 && _isConnected && _client?.connectionStatus?.state == MqttConnectionState.connected) {
        print('🔄 Syncing ESP32 with Firebase state: ${currentState.level}% -> Level $level');
        publishDeviceCommand(topicGateLevel, level.toString());
        
        // Wait a bit then request status to confirm
        await Future.delayed(const Duration(milliseconds: 1000));
      } else if (currentState.level > 0) {
        print('⚠️ Skipping Firebase->ESP32 sync - MQTT not connected');
      }
      
      // Always request current ESP32 status for verification
      await Future.delayed(const Duration(milliseconds: 500));
      
      // 🚨 WAIT FOR CONNECTION: Only send if truly connected
      if (_isConnected && _client?.connectionStatus?.state == MqttConnectionState.connected) {
        publishDeviceCommand('khoasmarthome/status_request', 'GATE_STATUS');
        print('📡 Requesting ESP32 gate status for verification...');
      } else {
        print('⚠️ Skipping gate status request - MQTT not fully connected yet');
      }
      
    } catch (e) {
      print('❌ Error initializing gate state: $e');

      _currentGateLevel = 0;
      _gateStateController.add(0);
      _gateStatusController.add({
        'level': 0,
        'isMoving': false,
        'description': 'Đóng hoàn toàn',
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });
    }
  }

  Future<void> _saveGateStateToFirebase(int level) async {
    if (!_enableFirebase || !_shouldWriteDeviceState()) return;

    try {
      final gateService = GateStateService();

      // 🚨 DIRECT PERCENTAGE: ESP32 now sends percentage values directly (0, 25, 50, 75, 100)
      // No need for legacy level mapping anymore
      final percentage = level; // Direct usage - ESP32 sends 0, 25, 50, 75, 100

      await gateService.saveGateState(GateState.withAutoStatus(
        level: percentage,
        isMoving: false,
        timestamp: DateTime.now(),
      ));

      _lastDeviceWrite = DateTime.now();
      print('✅ Gate state saved to Firebase: $percentage% (direct from ESP32)');
    } catch (e) {
      print('❌ Error saving gate state to Firebase: $e');
    }
  }

  // ========== FIREBASE LOGGING ==========

  void _logDeviceStateChange(String deviceId, bool isOn, String location, String type) {
    if (!_enableFirebase || !_shouldWriteDeviceState()) return;
    
    if (isOn != (_lastLightStates[deviceId] ?? false)) {
      _batchService.writeDeviceStateOptimized(deviceId, isOn ? 'ON' : 'OFF', 
          metadata: {'location': location, 'type': type})
          .catchError((error) {
            print('⚠️ Firebase $deviceId error: $error');
            return false;
          });
      
      _lastLightStates[deviceId] = isOn;
      _lastDeviceWrite = DateTime.now();
    }
  }

  void _logIndoorDeviceState(String deviceId, String command, String floor, String room, double estimatedPower) {
    if (!_enableFirebase || !_shouldWriteDeviceState()) return;
    
    final isOn = command == 'ON';
    
    if (_shouldWriteDeviceState() && isOn != (_lastLightStates[deviceId] ?? false)) {
      _batchService.writeDeviceStateOptimized(deviceId, command, metadata: {
        'floor': floor,
        'room': room,
        'type': 'light',
        'controller': 'esp32_s3_indoor',
      }).catchError((error) {
        print('⚠️ Firebase $deviceId error: $error');
        return false;
      });
      
      _lastLightStates[deviceId] = isOn;
      _lastDeviceWrite = DateTime.now();
    }
  }

  // ========== COMPATIBILITY METHODS ==========
  
  void controlLed1(bool isOn) => controlLedGate(isOn);
  void controlLed2(bool isOn) => controlLedAround(isOn);
  
  /// Compatibility method for device_manager_service.dart
  Future<void> moveGateAbsolute(int percentage) async {
    await publishGateControl(percentage);
  }

  // ========== CLEANUP ==========

  void disconnect() {
    _client?.disconnect();
    _isConnected = false;
    _connectionController.add(false);
  }

  void dispose() {
    _batchService.flush();
    _batchService.dispose();
    _sensorDataController.close();
    _connectionController.close();
    _gateStateController.close();
    _gateStatusController.close();
    _indoorDeviceStatusController.close();
    _deviceStateService.dispose();
  }
}

/// Sensor data class for compatibility
class SensorData {
  final double temperature;
  final double humidity;
  final double current;
  final double voltage;
  final double power;
  final DateTime lastUpdated;

  SensorData({
    required this.temperature,
    required this.humidity,
    required this.current,
    required this.voltage,
    required this.power,
    required this.lastUpdated,
  });

  factory SensorData.defaultData() {
    return SensorData(
      temperature: 28.5,
      humidity: 65.0,
      current: 125.5,
      voltage: 5.02,
      power: 630.0,
      lastUpdated: DateTime.now(),
    );
  }

  SensorData copyWith({
    double? temperature,
    double? humidity,
    double? current,
    double? voltage,
    double? power,
    DateTime? lastUpdated,
  }) {
    return SensorData(
      temperature: temperature ?? this.temperature,
      humidity: humidity ?? this.humidity,
      current: current ?? this.current,
      voltage: voltage ?? this.voltage,
      power: power ?? this.power,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}
