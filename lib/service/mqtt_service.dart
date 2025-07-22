import 'dart:async';
import 'dart:io';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'package:smart_home/service/firebase_batch_service.dart';
import 'package:smart_home/service/gate_state_service.dart'; // Import gate service
import 'package:smart_home/service/device_state_service.dart'; // Import device state service

class MqttService {
  static const String _broker = 'i0bf1b65.ala.asia-southeast1.emqxsl.com';
  static const int _port = 8883;
  static const String _username = 'af07dd3c'; // App ID
  static const String _password = 'U0ofxmA6rbhSp4_O'; // App Secret
  static const String _clientIdBase = 'Flutter_SmartHome';
  
  // Firebase toggle - 🚨 DISABLED to reduce requests - use Widget-level saves instead
  static const bool _enableFirebase = false; // 🚨 Disabled để giảm requests

    // MQTT topics - outdoor ESP32 Dev
  static const String topicTemp = 'khoasmarthome/temperature';
  static const String topicHumid = 'khoasmarthome/humidity';
  static const String topicCurrent = 'khoasmarthome/current';
  static const String topicVoltage = 'khoasmarthome/voltage';
  static const String topicPower = 'khoasmarthome/power';
  static const String topicLedGate = 'khoasmarthome/led_gate';     // đèn cổng
  static const String topicLedAround = 'khoasmarthome/led_around'; // đèn xung quanh
  static const String topicMotor = 'khoasmarthome/motor';          // motor cổng (tương thích cũ)
  static const String topicGateLevel = 'khoasmarthome/gate_level'; // điều khiển mức độ cổng
  static const String topicGateStatus = 'khoasmarthome/gate_status'; // trạng thái cổng

  // Topics from ESP32-S3 (indoor) - Thiết bị trong nhà
  // Sensor data from indoor ESP32-S3
  static const String topicCurrentInside = 'inside/current';
  static const String topicVoltageInside = 'inside/voltage';
  static const String topicPowerInside = 'inside/power';
  
  // Floor 1 devices
  static const String topicKitchenLight = 'inside/kitchen_light';       // Đèn bếp lớn
  static const String topicLivingRoomLight = 'inside/living_room_light'; // Đèn phòng khách
  static const String topicBedroomLight = 'inside/bedroom_light';       // Đèn phòng ngủ
  
  // Floor 2 devices
  static const String topicCornerBedroomLight = 'inside/corner_bedroom_light'; // Đèn phòng ngủ góc
  static const String topicYardBedroomLight = 'inside/yard_bedroom_light';     // Đèn phòng ngủ sân
  static const String topicWorshipRoomLight = 'inside/worship_room_light';     // Đèn phòng thờ
  static const String topicHallwayLight = 'inside/hallway_light';             // Đèn hành lang
  static const String topicBalconyLight = 'inside/balcony_light';             // Đèn ban công lớn

  MqttServerClient? _client;
  bool _isConnected = false;
  
  // StreamControllers cho data streaming
  final StreamController<SensorData> _sensorDataController = StreamController<SensorData>.broadcast();
  final StreamController<bool> _connectionController = StreamController<bool>.broadcast();
  
  // Gate control streams
  final StreamController<Map<String, dynamic>> _gateStatusController = StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<bool> _connectionStatusController = StreamController<bool>.broadcast();

  // Firebase service instance
  final FirebaseBatchService _batchService = FirebaseBatchService();

  // Device state service instance for synchronization
  final DeviceStateService _deviceStateService = DeviceStateService();

  // Firebase write throttling - HEAVILY REDUCED to save costs
  DateTime? _lastFirebaseWrite;
  static const Duration _firebaseWriteInterval = Duration(minutes: 5); // Only write every 5 minutes!
  double _lastPowerValue = 0.0;
  double _lastIndoorPowerValue = 0.0;
  
  // Device control throttling - chỉ ghi tối đa 1 lần mỗi 30 giây cho device control (was 5 seconds!)
  DateTime? _lastDeviceWrite;
  static const Duration _deviceWriteInterval = Duration(seconds: 30);
  
  // Track last states to avoid duplicate writes
  final Map<String, bool> _lastLightStates = {};
  
  // Gate state management
  final StreamController<int> _gateStateController = StreamController<int>.broadcast();
  int _currentGateLevel = 0; // 0=closed, 1=33%, 2=66%, 3=open

  Stream<SensorData> get sensorDataStream => _sensorDataController.stream;
  Stream<bool> get connectionStream => _connectionController.stream;
  Stream<int> get gateStateStream => _gateStateController.stream;
  
  // New gate control streams
  Stream<Map<String, dynamic>> get gateStatusStream => _gateStatusController.stream;
  Stream<bool> get connectionStatusStream => _connectionStatusController.stream;
  bool get isConnected => _isConnected;
  int get currentGateLevel => _currentGateLevel;

  // Current sensor values (with defaults)
  SensorData _currentData = SensorData.defaultData();
  SensorData get currentData => _currentData;

  // Indoor sensor data from ESP32-S3
  SensorData _currentDataInside = SensorData.defaultData();
  SensorData get currentDataInside => _currentDataInside;

  Future<void> connect() async {
    try {
      final clientId = '${_clientIdBase}_${DateTime.now().millisecondsSinceEpoch}';
      _client = MqttServerClient.withPort(_broker, clientId, _port);
      _client!.logging(on: true);
      _client!.onConnected = _onConnected;
      _client!.onDisconnected = _onDisconnected;
      _client!.onUnsubscribed = _onUnsubscribed;
      _client!.onSubscribed = _onSubscribed;
      _client!.onSubscribeFail = _onSubscribeFail;
      _client!.pongCallback = _pong;
      _client!.keepAlivePeriod = 60;
      _client!.connectTimeoutPeriod = 15000; // Tăng timeout
      _client!.autoReconnect = true;
      
      // Try SSL first
      _client!.secure = true;
      _client!.port = 8883;
      
      // For SSL connections, we might need to configure security context
      _client!.securityContext = SecurityContext.defaultContext;

      final connMessage = MqttConnectMessage()
          .authenticateAs(_username, _password)
          .withClientIdentifier(clientId)
          .withWillTopic('khoasmarthome/status')
          .withWillMessage('offline')
          .startClean()
          .withWillQos(MqttQos.atLeastOnce)
          .withProtocolName('MQTT')
          .withProtocolVersion(4); // Use MQTT 3.1.1
      
      _client!.connectionMessage = connMessage;

      print('🔌 Connecting to MQTT broker with SSL...');
      await _client!.connect();
      
    } catch (e) {
      print('❌ SSL MQTT connection error: $e');
      // Fallback to non-SSL
      await _connectNonSSL();
    }
  }

  Future<void> _connectNonSSL() async {
    try {
      _client?.disconnect();
      
      final clientId = '${_clientIdBase}_${DateTime.now().millisecondsSinceEpoch}';
      _client = MqttServerClient.withPort(_broker, clientId, 1883);
      _client!.logging(on: true);
      _client!.onConnected = _onConnected;
      _client!.onDisconnected = _onDisconnected;
      _client!.onUnsubscribed = _onUnsubscribed;
      _client!.onSubscribed = _onSubscribed;
      _client!.onSubscribeFail = _onSubscribeFail;
      _client!.pongCallback = _pong;
      _client!.keepAlivePeriod = 60;
      _client!.connectTimeoutPeriod = 15000;
      _client!.autoReconnect = true;
      
      // Non-SSL connection
      _client!.secure = false;

      final connMessage = MqttConnectMessage()
          .authenticateAs(_username, _password)
          .withClientIdentifier(clientId)
          .withWillTopic('khoasmarthome/status')
          .withWillMessage('offline')
          .startClean()
          .withWillQos(MqttQos.atLeastOnce)
          .withProtocolName('MQTT')
          .withProtocolVersion(4); // Use MQTT 3.1.1
      
      _client!.connectionMessage = connMessage;

      print('🔌 Connecting to MQTT broker without SSL...');
      await _client!.connect();
      
    } catch (e) {
      print('❌ Non-SSL MQTT connection error: $e');
      _isConnected = false;
      _connectionController.add(false);
      _connectionStatusController.add(false);
      disconnect();
    }
  }

  void _onConnected() {
    print('✅ MQTT Connected');
    _isConnected = true;
    _connectionController.add(true);
    _connectionStatusController.add(true);
    _subscribeToTopics();
    
    // Initialize gate state when connected
    initializeGateState();
    
    // Request current device status from ESP32
    _requestDeviceStatus();
  }

  void _requestDeviceStatus() {
    // Send status request to ESP32 to get current device states
    try {
      // Request all device status
      publishDeviceCommand('khoasmarthome/status_request', 'ALL_DEVICES');
      
      // Request specific device status
      publishDeviceCommand('khoasmarthome/status_request', 'GATE_STATUS');
      publishDeviceCommand('khoasmarthome/status_request', 'LED_GATE');
      publishDeviceCommand('khoasmarthome/status_request', 'LED_AROUND');
      
      print('📡 Requested device status from ESP32');
    } catch (e) {
      print('❌ Error requesting device status: $e');
    }
  }

  void _onDisconnected() {
    print('❌ MQTT Disconnected');
    _isConnected = false;
    _connectionController.add(false);
    _connectionStatusController.add(false);
  }

  void _onSubscribed(String topic) {
    print('📡 Subscribed to: $topic');
  }

  void _onSubscribeFail(String topic) {
    print('❌ Failed to subscribe: $topic');
  }

  void _onUnsubscribed(String? topic) {
    print('📡 Unsubscribed from: $topic');
  }

  void _pong() {
    print('🏓 Ping response received');
  }

  // Firebase write throttling methods
  bool _shouldWriteToFirebaseHeavyThrottle() {
    if (_lastFirebaseWrite == null) return true;
    return DateTime.now().difference(_lastFirebaseWrite!) >= _firebaseWriteInterval;
  }

  bool _shouldWriteSignificantChange(double currentPower) {
    // Only write if power changed significantly OR enough time passed
    final powerChangeSignificant = (currentPower - _lastPowerValue).abs() > 50.0; // 50W change threshold
    final timeThresholdMet = DateTime.now().difference(_lastFirebaseWrite ?? DateTime.fromMillisecondsSinceEpoch(0)) >= _firebaseWriteInterval;
    
    return powerChangeSignificant || timeThresholdMet;
  }
  
  bool _shouldWriteDeviceState() {
    if (_lastDeviceWrite == null) return true;
    return DateTime.now().difference(_lastDeviceWrite!) >= _deviceWriteInterval;
  }

  void _subscribeToTopics() {
    final topics = [
      // Outdoor ESP32 Dev topics
      topicTemp,
      topicHumid,
      topicCurrent,
      topicVoltage,
      topicPower,
      // Gate status topic
      topicGateStatus,
      
      // Subscribe to device status topics for synchronization
      '$topicLedGate/status',        // Trạng thái đèn cổng
      '$topicLedAround/status',      // Trạng thái đèn xung quanh
      'khoasmarthome/device_status', // Trạng thái thiết bị chung
      'khoasmarthome/gate_percentage', // Gate percentage for compatibility
      
      // Other outdoor device status topics
      'khoasmarthome/device/yard_main_light/status',
      'khoasmarthome/device/fish_pond_light/status',
      'khoasmarthome/device/awning_light/status',
      'khoasmarthome/device/awning/status',
      
      // Indoor device status topics
      'khoasmarthome/device/living_room_light/status',
      'khoasmarthome/device/kitchen_light/status',
      'khoasmarthome/device/bedroom_light/status',
      'khoasmarthome/device/stairs_light/status',
      'khoasmarthome/device/bathroom_light/status',
      
      // Indoor ESP32-S3 topics
      topicCurrentInside,
      topicVoltageInside,
      topicPowerInside,
      
      // Subscribe to ESP32-S3 device status topics
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
      print('📡 Subscribed to: $topic');
    }

    _client!.updates!.listen((List<MqttReceivedMessage<MqttMessage?>>? c) {
      final recMess = c![0].payload as MqttPublishMessage;
      final pt = MqttPublishPayload.bytesToStringAsString(recMess.payload.message);
      final topic = c[0].topic;
      
      _handleMessage(topic, pt);
    });
  }

  void _handleMessage(String topic, String message) {
    print('📩 Received [$topic]: $message');
    
    // Handle device status messages first (before parsing as numbers)
    if (topic.endsWith('/status') || topic.contains('device_status') || topic.contains('gate_percentage')) {
      _handleDeviceStatus(topic, message);
      return;
    }
    
    try {
      final value = double.tryParse(message) ?? 0.0;
      
      // Handle outdoor ESP32 Dev data
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
        // Handle indoor ESP32-S3 data
        case topicCurrentInside:
          _currentDataInside = _currentDataInside.copyWith(current: value);
          break;
        case topicVoltageInside:
          _currentDataInside = _currentDataInside.copyWith(voltage: value);
          break;
        case topicPowerInside:
          _currentDataInside = _currentDataInside.copyWith(power: value);
          break;
        case topicGateStatus:
          _handleGateStatus(message);
          return; // Don't process as sensor data
      }
      
      // Update timestamps
      if (topic.startsWith('inside/')) {
        _currentDataInside = _currentDataInside.copyWith(lastUpdated: DateTime.now());
      } else {
        _currentData = _currentData.copyWith(lastUpdated: DateTime.now());
      }
      
      _sensorDataController.add(_currentData);
      
      // Send data to Firebase asynchronously (HEAVILY THROTTLED - only every 5 minutes)
      if (_enableFirebase && _shouldWriteToFirebaseHeavyThrottle()) {
        // Use optimized batch service - write MUCH less frequently
        if (!topic.startsWith('inside/')) {
          // Only write if power changes significantly or after long time
          if (_shouldWriteSignificantChange(_currentData.power)) {
            _batchService.writeSensorDataOptimized(_currentData).catchError((error) {
              print('⚠️ Firebase batch write error: $error');
              return false;
            });
            
            _lastFirebaseWrite = DateTime.now();
            _lastPowerValue = _currentData.power;
          }
        } else {
          // Write indoor data even LESS frequently - only if major power usage change
          if (_currentDataInside.power > 10.0 && 
              (_lastIndoorPowerValue == 0 || 
               (_currentDataInside.power - _lastIndoorPowerValue).abs() > 5.0)) {
            _batchService.addToBatch(
              collection: 'power_consumption_optimized',
              data: {
                'device': 'indoor_system',
                'power': _currentDataInside.power,
                'voltage': _currentDataInside.voltage,
                'current': _currentDataInside.current,
                'type': 'indoor_consumption',
                'location': 'inside_house',
              },
            );
            
            _lastFirebaseWrite = DateTime.now();
            _lastIndoorPowerValue = _currentDataInside.power;
          }
        }
      }
      
    } catch (e) {
      print('❌ Error parsing message: $e');
    }
  }

  void publishDeviceCommand(String topic, String command) {
    if (_isConnected && _client != null) {
      final builder = MqttClientPayloadBuilder();
      builder.addString(command);
      _client!.publishMessage(topic, MqttQos.atLeastOnce, builder.payload!);
      print('📤 Published [$topic]: $command');
    } else {
      print('❌ Cannot publish: MQTT not connected');
    }
  }

  void controlLedGate(bool isOn) {
    final command = isOn ? 'ON' : 'OFF';
    publishDeviceCommand(topicLedGate, command);
    
    // Log device state to Firebase asynchronously (HEAVILY THROTTLED)
    if (_enableFirebase && _shouldWriteDeviceState() && isOn != (_lastLightStates['led_gate'] ?? false)) {
      _batchService.writeDeviceStateOptimized('led_gate', command, metadata: {'room': 'entrance', 'type': 'light', 'zone': 'gate'})
          .catchError((error) {
            print('⚠️ Firebase LED Gate error: $error');
            return false;
          });
      
      // Cache state to avoid duplicates
      _lastLightStates['led_gate'] = isOn;
      
      // Only add power consumption for significant power usage
      if (isOn) {
        _batchService.addToBatch(
          collection: 'power_consumption_optimized',
          data: {
            'device': 'led_gate',
            'power': 10.0,
            'voltage': _currentData.voltage,
            'current': 2.0,
            'room': 'entrance',
            'type': 'light',
            'zone': 'gate',
            'state': command,
          },
        );
      }
      
      _lastDeviceWrite = DateTime.now();
    }
  }

  void controlLedAround(bool isOn) {
    final command = isOn ? 'ON' : 'OFF';
    publishDeviceCommand(topicLedAround, command);
    
    // Log device state to Firebase asynchronously (HEAVILY THROTTLED)
    if (_enableFirebase && _shouldWriteDeviceState() && isOn != (_lastLightStates['led_around'] ?? false)) {
      _batchService.writeDeviceStateOptimized('led_around', command, metadata: {'room': 'garden', 'type': 'light', 'zone': 'around'})
          .catchError((error) {
            print('⚠️ Firebase LED Around error: $error');
            return false;
          });
      
      // Cache state to avoid duplicates
      _lastLightStates['led_around'] = isOn;
      
      // Only add power consumption for significant power usage
      if (isOn) {
        _batchService.addToBatch(
          collection: 'power_consumption_optimized',
          data: {
            'device': 'led_around',
            'power': 15.0,
            'voltage': _currentData.voltage,
            'current': 3.0,
            'room': 'garden',
            'type': 'light',
            'zone': 'around',
            'state': command,
          },
        );
      }
      
      _lastDeviceWrite = DateTime.now();
    }
  }

  // ENHANCED: Gate control with direction for accurate motor control
  Future<void> publishGateControlWithDirection({
    required int currentLevel,
    required int targetLevel,
    String? direction,
    String? command,
  }) async {
    try {
      if (!_isConnected) {
        print('❌ Cannot publish gate control: MQTT not connected');
        return;
      }

      // Create enhanced command message format: "LEVEL|DIRECTION|COMMAND"
      String mqttMessage;
      
      if (command == 'STOP') {
        mqttMessage = 'STOP';
        print('🚪 Sending STOP command...');
      } else {
        // Format: "targetLevel|direction|command"
        // Example: "25|closing|OPEN_TO_25" or "75|opening|OPEN_TO_75"
        mqttMessage = '$targetLevel|${direction ?? 'none'}|${command ?? 'MOVE_TO_$targetLevel'}';
        print('🚪 Sending enhanced gate command:');
        print('   From: $currentLevel% → To: $targetLevel%');
        print('   Direction: ${direction ?? 'none'}');
        print('   Command: ${command ?? 'MOVE_TO_$targetLevel'}');
        print('   MQTT Message: $mqttMessage');
      }

      publishDeviceCommand(topicGateLevel, mqttMessage);
      
      // Update local state for responsive UI
      _currentGateLevel = targetLevel;
      _gateStatusController.add({
        'level': currentLevel, // Keep current until movement starts
        'isMoving': direction != null,
        'description': direction != null 
            ? 'Đang ${direction == "opening" ? "mở" : "đóng"} đến $targetLevel%...'
            : 'Đã đến $targetLevel%',
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });
      
      print('🚪 Enhanced gate command sent: $mqttMessage');
      
    } catch (e) {
      print('❌ Error in publishGateControlWithDirection: $e');
    }
  }

  // CẢI TIẾN: Điều khiển cổng với percentage (0-100%)
  Future<void> publishGateControl(int level, {bool shouldRequestStatus = false}) async {
    try {
      if (!_isConnected) {
        print('❌ Cannot publish gate control: MQTT not connected');
        return;
      }

      String command;
      if (shouldRequestStatus) {
        command = 'STATUS_REQUEST';
        print('🚪 Requesting gate status from ESP32...');
      } else if (level == -1) {
        command = 'STOP';
        print('🚪 Sending gate STOP command...');
      } else if (level >= 0 && level <= 100) {
        command = level.toString();
        print('🚪 Sending gate control command: $level%');
        
        // Immediately update local state to provide responsive UI
        _currentGateLevel = level;
        _gateStatusController.add({
          'level': level,
          'isMoving': true,
          'description': 'Đang di chuyển đến $level%...',
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        });
      } else {
        print('❌ Invalid gate level: $level');
        return;
      }

      publishDeviceCommand(topicGateLevel, command);
      print('🚪 Gate control command sent: $command');
      
      // Update connection status stream
      _connectionStatusController.add(_isConnected);
      
    } catch (e) {
      print('❌ Error in publishGateControl: $e');
    }
  }

  // Deprecated: Cũ - dùng controlGateLevel để tương thích
  void controlGateLevel(int level) {
    if (level < 0 || level > 3) return;
    
    // Convert old level (0-3) to new percentage (0-100)
    int percentage = (level * 33.33).round();
    if (level == 3) percentage = 100; // Đảm bảo level 3 = 100%
    
    publishGateControl(percentage);
    print('🚪 Điều khiển cổng đến mức $level ($percentage%)');
  }

  void controlMotor(String direction) {
    // Tương thích ngược - chuyển đổi sang system mới
    if (direction == 'FORWARD' || direction == 'ON') {
      controlGateLevel(_currentGateLevel == 0 ? 3 : 0); // Toggle giữa đóng và mở hoàn toàn
    } else {
      publishDeviceCommand(topicMotor, direction); // Vẫn hỗ trợ lệnh cũ
    }
    
    // Log device state to Firebase asynchronously (with throttling)
    if (_enableFirebase && _shouldWriteDeviceState()) {
      _batchService.writeDeviceStateOptimized('motor', direction, metadata: {'room': 'garage', 'type': 'motor', 'zone': 'entrance'})
          .catchError((error) {
            print('⚠️ Firebase Motor error: $error');
            return false;
          });
      
      _lastDeviceWrite = DateTime.now();
    }
  }

  // ========== DEVICE STATUS SYNCHRONIZATION ==========
  
  void _handleDeviceStatus(String topic, String message) {
    print('🔄 Processing device status: [$topic] = $message');
    
    try {
      // Extract device name from topic
      String deviceName = _extractDeviceNameFromTopic(topic);
      bool deviceState = (message.toUpperCase() == 'ON' || message.toUpperCase() == 'TRUE');
      
      // 🔧 FIX: Đảo logic cho yard_main_light để khớp với hardware thực tế
      // Note: led_around không cần đảo ở đây vì sẽ xử lý trong UI
      if (deviceName == 'yard_main_light') {
        deviceState = !deviceState;  // Đảo ngược logic từ ESP32
        print('🔧 Device $deviceName Status Inverted: ESP32=${message} -> UI=${deviceState ? 'ON' : 'OFF'}');
      }
      
      // Update device state service for synchronization
      if (deviceName.isNotEmpty) {
        _deviceStateService.updateDeviceState(deviceName, deviceState, source: 'ESP32');
        
        print('🔄 Device synchronized: $deviceName = ${deviceState ? 'ON' : 'OFF'} (from ESP32)');
        
        // Broadcast device state change for UI updates
        _broadcastDeviceStateChange(deviceName, deviceState);
      }
      
      // Handle special cases
      if (topic.contains('gate_percentage')) {
        // Gate percentage for compatibility
        final percentage = int.tryParse(message) ?? 0;
        final level = (percentage / 25).round(); // Convert percentage to level (0-4)
        _currentGateLevel = level;
        _gateStateController.add(level);
        print('🚪 Gate percentage updated: $percentage% (level $level)');
      }
      
    } catch (e) {
      print('❌ Error handling device status [$topic]: $e');
    }
  }
  
  String _extractDeviceNameFromTopic(String topic) {
    // Extract device name from various topic formats
    if (topic.contains('/status')) {
      // Format: "khoasmarthome/led_gate/status" -> "led_gate"
      // Format: "khoasmarthome/device/yard_main_light/status" -> "yard_main_light"
      final parts = topic.split('/');
      if (parts.length >= 3) {
        if (parts.contains('device') && parts.length >= 4) {
          // khoasmarthome/device/yard_main_light/status
          return parts[parts.length - 2]; // Take device name before /status
        } else {
          // khoasmarthome/led_gate/status or inside/kitchen_light/status
          return parts[parts.length - 2]; // Take device name before /status
        }
      }
    }
    
    if (topic.contains('device_status')) {
      // Parse JSON format for general device status
      try {
        // Expected format: {"device":"led_gate","state":"ON","timestamp":123456}
        // For now, return empty - JSON parsing can be added if needed
        return '';
      } catch (e) {
        return '';
      }
    }
    
    return '';
  }
  
  void _broadcastDeviceStateChange(String deviceName, bool state) {
    // Create a stream controller for device state changes if needed
    // This can be listened to by widgets that need real-time device updates
    // For now, just log the change
    print('📡 Broadcasting device state change: $deviceName = ${state ? 'ON' : 'OFF'}');
    
    // TODO: Add StreamController for device state broadcasts if needed
    // _deviceStateController.add({'device': deviceName, 'state': state});
  }

  // ========== GATE STATE MANAGEMENT ==========
  
  void _handleGateStatus(String statusMessage) {
    try {
      // Hỗ trợ nhiều format:
      // Format mới: "level:isMoving:description" (e.g., "75:false:OPEN_75")
      // Format cũ: "level:description" (e.g., "2:PARTIAL_66")
      final parts = statusMessage.split(':');
      
      if (parts.length >= 3) {
        // Format mới với isMoving
        final level = int.tryParse(parts[0]) ?? 0;
        final isMoving = parts[1].toLowerCase() == 'true';
        final description = parts[2];
        
        _currentGateLevel = level;
        
        // Emit to old stream for backward compatibility
        _gateStateController.add(level);
        
        // Emit to new detailed stream
        _gateStatusController.add({
          'level': level,
          'isMoving': isMoving,
          'description': description,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        });
        
        print('🚪 Gate status updated: Level $level%, Moving: $isMoving ($description)');
        
        // Save to Firebase - 🚨 ONLY if isMoving changed to avoid excessive writes
        if (_enableFirebase) {
          _saveGateStateToFirebase(level, isMoving: isMoving);
        }
        
      } else if (parts.length >= 2) {
        // Format cũ - tương thích ngược
        final firstPart = int.tryParse(parts[0]) ?? 0;
        
        // 🚨 FIX: Determine if first part is percentage or level
        int percentage;
        bool isMoving = false; // 🚨 CRITICAL: Default isMoving = false for legacy format
        
        if (firstPart <= 4) {
          // Old format: level (0-4) -> convert to percentage
          percentage = (firstPart * 25); // 0->0%, 1->25%, 2->50%, 3->75%, 4->100%
          _currentGateLevel = firstPart;
          print('🚪 Gate status updated (legacy level): Level $firstPart -> $percentage% (${parts[1]}) - isMoving: $isMoving');
        } else {
          // New format: already percentage -> use directly
          percentage = firstPart;
          _currentGateLevel = (percentage / 25).round(); // Convert back to level for compatibility
          print('🚪 Gate status updated (percentage): $percentage% (level ${_currentGateLevel}) (${parts[1]}) - isMoving: $isMoving');
        }
        
        _gateStateController.add(_currentGateLevel);
        
        _gateStatusController.add({
          'level': percentage,
          'isMoving': isMoving, // 🚨 CRITICAL: Always false for legacy format
          'description': parts[1],
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        });
      }
    } catch (e) {
      print('❌ Error parsing gate status: $e');
    }
  }
  
  Future<void> _saveGateStateToFirebase(int level, {bool isMoving = false}) async {
    if (!_enableFirebase || !_shouldWriteDeviceState()) return;
    
    try {
      // Sử dụng GateStateService mới
      final gateService = GateStateService();
      
      await gateService.saveGateState(GateState.withAutoStatus(
        level: level,
        isMoving: isMoving,
        timestamp: DateTime.now(),
      ));
      
      print('💾 Gate state saved to Firebase: $level%, moving: $isMoving');
      
      // Also trigger a status update to sync with HomeScreenViewModel
      _gateStatusController.add({
        'level': level,
        'isMoving': isMoving,
        'description': _getGateDescription(level, isMoving),
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });
      
    } catch (e) {
      print('❌ Error saving gate state to Firebase: $e');
    }
  }

  String _getGateDescription(int level, bool isMoving) {
    if (isMoving) return 'Đang di chuyển...';
    
    switch (level) {
      case 0: return 'Đóng hoàn toàn';
      case 25: return 'Mở 1/4 - Người đi bộ';
      case 50: return 'Mở 1/2 - Xe máy';
      case 75: return 'Mở 3/4 - Xe hơi nhỏ';
      case 100: return 'Mở hoàn toàn - Xe tải';
      default: return 'Mở $level%';
    }
  }

  // Compatibility methods for backward compatibility (outdoor ESP32 Dev)
  void controlLed1(bool isOn) => controlLedGate(isOn);
  void controlLed2(bool isOn) => controlLedAround(isOn);

  // ========== GATE STATE INITIALIZATION ==========
  
  Future<void> initializeGateState() async {
    try {
      final gateService = GateStateService();
      final GateState currentState = await gateService.getCurrentGateState();
      _currentGateLevel = currentState.level;
      // Emit current state to streams
      _gateStateController.add(_currentGateLevel);
      _gateStatusController.add({
        'level': currentState.level,
        'isMoving': currentState.isMoving,
        'description': _getGateDescription(currentState.level, currentState.isMoving),
        'timestamp': currentState.timestamp.millisecondsSinceEpoch,
      });
      print('🚪 Gate state initialized from Firebase: ${currentState.level}%');
      // Request fresh status from ESP32 without changing level
      await Future.delayed(const Duration(milliseconds: 500));
      publishDeviceCommand('khoasmarthome/status_request', 'GATE_STATUS');
    } catch (e) {
      print('❌ Error initializing gate state: $e');
      
      // Set default state on error
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

  // ========== ESP32-S3 Indoor Device Controls ==========
  
  // Floor 1 Controls
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

  // Floor 2 Controls
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

  // 🔧 FIX: Method điều khiển đèn sân chính với logic đảo ngược
  void controlYardMainLight(bool isOn) {
    // 🚨 INVERTED LOGIC: Hardware thực tế ngược với software expectation
    final command = isOn ? 'OFF' : 'ON';  // Đảo logic để khớp với hardware
    publishDeviceCommand('khoasmarthome/yard_main_light', command);
    print('🔧 Yard Main Light: UI=${isOn ? 'ON' : 'OFF'} -> Hardware=${command}');
    
    // Log device state with original UI state (not inverted command)
    if (_enableFirebase && _shouldWriteDeviceState()) {
      _batchService.writeDeviceStateOptimized('yard_main_light', isOn ? 'ON' : 'OFF', 
          metadata: {'room': 'yard', 'type': 'light', 'zone': 'main_yard', 'inverted': true})
          .catchError((error) {
            print('⚠️ Firebase Yard Main Light error: $error');
            return false;
          });
      _lastDeviceWrite = DateTime.now();
    }
  }

  // Helper method to log indoor device states (with optimized batching)
  void _logIndoorDeviceState(String deviceId, String command, String floor, String room, double estimatedPower) {
    if (!_enableFirebase || !_shouldWriteDeviceState()) return;
    
    final isOn = command == 'ON';
    
    // Use batch service for device state (HEAVILY THROTTLED - only significant changes)
    if (_shouldWriteDeviceState() && isOn != (_lastLightStates['led_${floor}_${room}'] ?? false)) {
      _batchService.writeDeviceStateOptimized(deviceId, command, metadata: {
        'floor': floor,
        'room': room,
        'type': 'light',
        'controller': 'esp32_s3_indoor',
      }).catchError((error) {
        print('⚠️ Firebase $deviceId error: $error');
        return false;
      });
      
      // Cache the state to avoid duplicate writes
      _lastLightStates[deviceId] = isOn;
      
      // Only add power consumption if state actually changed and power is significant
      if (isOn && estimatedPower > 15.0) { // Higher threshold for power logging
        _batchService.addToBatch(
          collection: 'power_consumption_optimized',
          data: {
            'device': deviceId,
            'power': estimatedPower,
            'voltage': _currentDataInside.voltage,
            'current': estimatedPower / _currentDataInside.voltage,
            'floor': floor,
            'room': room,
            'type': 'light',
            'controller': 'esp32_s3_indoor',
            'state': command,
          },
        );
      }
      
      _lastDeviceWrite = DateTime.now();
    }
  }

  void disconnect() {
    _client?.disconnect();
    _isConnected = false;
    _connectionController.add(false);
    _connectionStatusController.add(false);
  }

  void dispose() {
    disconnect();
    _batchService.flush(); // Flush pending writes before disposing
    _batchService.dispose();
    _sensorDataController.close();
    _connectionController.close();
  }

  /* CA Certificate for EMQX Cloud - Commented out as currently not used
  static const String _caCertificate = '''
-----BEGIN CERTIFICATE-----
MIIGFzCCBP+gAwIBAgIQCzlnQyWUs9z9wmDbbJKxbTANBgkqhkiG9w0BAQsFADBu
MQswCQYDVQQGEwJVUzEVMBMGA1UEChMMRGlnaUNlcnQgSW5jMRkwFwYDVQQLExB3
d3cuZGlnaWNlcnQuY29tMS0wKwYDVQQDEyRFbmNyeXB0aW9uIEV2ZXJ5d2hlcmUg
RFYgVExTIENBIC0gRzEwHhcNMjQxMDE2MDAwMDAwWhcNMjUxMDE1MjM1OTU5WjAr
MSkwJwYDVQQDDCAqLmFsYS5hc2lhLXNvdXRoZWFzdDEuZW1xeHNsLmNvbTCCASIw
DQYJKoZIhvcNAQEBBQADggEPADCCAQoCggEBAJbNPPCbZuBzKh0cX3pS353FzzY9
0bnqMq/fN44+gdZSCyZYBBRMSG96LFn8VeExIgHSaXxqp/d4A+4wViziyrpe3Nc6
MxTIAhBxa6fTkKC76s4lK8a6ybFwxTz+Q+utju0w0OwwItsblHTYREgzSwJcW0ie
rrn76mADXwx7edngoMziIggYGb716YRaHEzj7j3BPkVrPvSuzomTxDCPzSxU4/8v
UXzlyL+6OliLzU2iewrtpQ5tePE7pHRIWhrVyAw8KAbFD88yDRpEvuuNPRtlliB5
CZrPzgzzNEJtmhEOQOABqXHRIBONNQRdWr+cwilR2PWfQs0dLgcR0WVimr0CAwEA
AaOCAvIwggLuMB8GA1UdIwQYMBaAFFV0T7JyT/VgulDR1+ZRXJoBhxrXMB0GA1Ud
DgQWBBQB8aslZ14UD1ppHJWVYYkNyERgMDArBgNVHREEJDAigiAqLmFsYS5hc2lh
LXNvdXRoZWFzdDEuZW1xeHNsLmNvbTA+BgNVHSAENzA1MDMGBmeBDAECATApMCcG
CCsGAQUFBwIBFhtodHRwOi8vd3d3LmRpZ2ljZXJ0LmNvbS9DUFMwDgYDVR0PAQH/
BAQDAgWgMB0GA1UdJQQWMBQGCCsGAQUFBwMBBggrBgEFBQcDAjCBgAYIKwYBBQUH
AQEEdDByMCQGCCsGAQUFBzABhhhodHRwOi8vb2NzcC5kaWdpY2VydC5jb20wSgYI
KwYBBQUHMAKGPmh0dHA6Ly9jYWNlcnRzLmRpZ2ljZXJ0LmNvbS9FbmNyeXB0aW9u
RXZlcnl3aGVyZURWVExTQ0EtRzEuY3J0MAwGA1UdEwEB/wQCMAAwggF9BgorBgEE
AdZ5AgQCBIIBbQSCAWkBZwB1ABLxTjS9U3JMhAYZw48/ehP457Vih4icbTAFhOvl
hiY6AAABkpR7DJAAAAQDAEYwRAIgOSOQLk2NDbQSiaT2HYGufCOgcUOqjgYoqwy/
qsTuNeECIFAUMfLQuob4cbaHNgtKe5VK3DoQsaS5AEqHbSYYoOkgAHYAfVkeEuF4
KnscYWd8Xv340IdcFKBOlZ65Ay/ZDowuebgAAAGSlHsMUgAABAMARzBFAiB+jgqO
Ou8wPxgNVe608/7eY7SriDRxB2gBEKWUTwiFGwIhAK32ko1rVHLcLartbDZJ40os
1JxAMOy0BwHoQf4dk4+LAHYA5tIxY0B3jMEQQQbXcbnOwdJA9paEhvu6hzId/R43
jlAAAAGSlHsMVwAABAMARzBFAiEAh9euTmXv0ENZcx9/qE4j1r6D+W3TIk1GJzAW
gcRkLPUCIBLJ/pDwFis8smhMgxxemUSRfeb+jtYXKZdvBWHxXhcQMA0GCSqGSIb3
DQEBCwUAA4IBAQCwuo2NgaONkSbtmjGhgW0xjfc6QboJGwKxAWeRRmFQQ4qL9DAy
vAKmJKrV9A4LQpBEqEpmT8Z8zab07qbC1aknnGjjjLOerR8QipwvJ5mqLhDQiII/
eTG/z0edW/Mjn5H7ICBCVsWxIYbSsKctGKNxrLqXxBbi7Ri+UuYeuyDlrR9uByBR
JPgjXC/yncjOwF+CXh5+p6O3VY/sZdAyfKnYVD9GzCJzB9zlb4+K5ILrsB0G4h4t
4jlOPPtFKF81Et8zeYMAz80swh20dBpnW17BGOnImwOjSS4tWxg+Yndt15mv2OzX
WYp+G+xOvUe8a7hrA6/L/mVO+Z6gUxbBAnmu
-----END CERTIFICATE-----
  ''';
  */
}

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
