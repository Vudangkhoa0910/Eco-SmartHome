import 'dart:async';
import 'dart:io';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'package:smart_home/service/firebase_batch_service.dart';
import 'package:smart_home/service/gate_state_service.dart';
import 'package:smart_home/service/mqtt_service.dart'; // Import để sử dụng SensorData

class MqttServiceSimple {
  static const String _broker = 'i0bf1b65.ala.asia-southeast1.emqxsl.com';
  static const int _port = 8883;
  static const String _username = 'af07dd3c';
  static const String _password = 'U0ofxmA6rbhSp4_O';
  static const String _clientIdentifier = 'flutter_client';

  // MQTT topics
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

  // Firebase services
  final FirebaseBatchService _batchService = FirebaseBatchService();

  // Current data
  SensorData _currentData = SensorData.defaultData();
  int _currentGateLevel = 0;

  // Throttling
  DateTime? _lastFirebaseWrite;
  DateTime? _lastDeviceWrite;
  static const Duration _firebaseWriteInterval = Duration(minutes: 5);
  static const Duration _deviceWriteInterval = Duration(seconds: 30);

  // Getters
  Stream<SensorData> get sensorDataStream => _sensorDataController.stream;
  Stream<bool> get connectionStream => _connectionController.stream;
  Stream<int> get gateStateStream => _gateStateController.stream;
  Stream<Map<String, dynamic>> get gateStatusStream =>
      _gateStatusController.stream;
  bool get isConnected => _isConnected;
  int get currentGateLevel => _currentGateLevel;

  // Initialize MQTT
  Future<void> initialize() async {
    _client = MqttServerClient.withPort(_broker, _clientIdentifier, _port);
    _client!.secure = true;
    _client!.securityContext = SecurityContext.defaultContext;
    _client!.keepAlivePeriod = 20;
    _client!.onDisconnected = _onDisconnected;
    _client!.onConnected = _onConnected;

    final connMessage = MqttConnectMessage()
        .withClientIdentifier(_clientIdentifier)
        .withWillTopic('willtopic')
        .withWillMessage('My Will message')
        .startClean()
        .withWillQos(MqttQos.atLeastOnce);

    _client!.connectionMessage = connMessage;

    try {
      await _client!.connect(_username, _password);
    } catch (e) {
      print('❌ MQTT connection failed: $e');
      _client!.disconnect();
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

    // Initialize gate state when connected
    initializeGateState();
  }

  // Initialize gate state from Firebase and sync with ESP32
  Future<void> initializeGateState() async {
    try {
      final gateService = GateStateService();
      final GateState currentState = await gateService.getCurrentGateState();

      // Convert percentage back to ESP32 level
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

      // Emit to status stream
      _gateStatusController.add({
        'level': currentState.level,
        'isMoving': currentState.isMoving,
        'description':
            _getGateDescription(currentState.level, currentState.isMoving),
        'timestamp': currentState.timestamp.millisecondsSinceEpoch,
      });

      print('🚪 Gate state initialized: ${currentState.level}% (Level $level)');

      // Request fresh status from ESP32
      await Future.delayed(const Duration(milliseconds: 500));
      await publishGateControl(0, shouldRequestStatus: true);
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

  void _onDisconnected() {
    _isConnected = false;
    _connectionController.add(false);
    print('❌ MQTT Disconnected');
  }

  void _subscribeToTopics() {
    final topics = [
      topicTemp,
      topicHumid,
      topicCurrent,
      topicVoltage,
      topicPower,
      topicGateStatus,
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
    print('📩 MQTT: $topic = $message');

    if (topic == topicGateStatus) {
      _handleGateStatus(message);
      return;
    }

    final value = double.tryParse(message) ?? 0.0;

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
      final parts = statusMessage.split(':');
      if (parts.length >= 2) {
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
            break; // Show as 25% instead of 33%
          case 2:
            percentage = 50;
            break; // Show as 50% instead of 66%
          case 3:
            percentage = 100;
            break;
          default:
            percentage = 0;
        }

        // Emit to new status stream for GateDeviceControlWidget
        _gateStatusController.add({
          'level': percentage,
          'isMoving': status.contains('MOVING') || status.contains('RUNNING'),
          'description':
              _getGateDescription(percentage, status.contains('MOVING')),
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        });

        print('🚪 Gate status updated: Level $level -> $percentage% ($status)');
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
    if (_client?.connectionStatus?.state == MqttConnectionState.connected) {
      final builder = MqttClientPayloadBuilder();
      builder.addString(command);
      _client!.publishMessage(topic, MqttQos.atLeastOnce, builder.payload!);
      print('📤 MQTT: $topic = $command');
    }
  }

  // Device controls
  void controlLedGate(bool isOn) {
    final command = isOn ? 'ON' : 'OFF';
    publishDeviceCommand(topicLedGate, command);
  }

  void controlLedAround(bool isOn) {
    final command = isOn ? 'ON' : 'OFF';
    publishDeviceCommand(topicLedAround, command);
  }

  void controlGateLevel(int level) {
    if (level < 0 || level > 3) return;

    publishDeviceCommand(topicGateLevel, level.toString());
    print('🚪 Điều khiển cổng đến mức $level');

    // Save to Firebase
    if (_enableFirebase) {
      _saveGateStateToFirebase(level);
    }
  }

  // NEW: Control gate by percentage (0-100%) - convert to ESP32 levels
  Future<void> publishGateControl(int percentage,
      {bool shouldRequestStatus = false}) async {
    try {
      int level;

      // Convert percentage to ESP32 level format
      if (percentage <= 0) {
        level = 0; // Closed
      } else if (percentage <= 33) {
        level = 1; // 33% open
      } else if (percentage <= 66) {
        level = 2; // 66% open
      } else {
        level = 3; // 100% open
      }

      if (shouldRequestStatus) {
        // Request current status from ESP32
        publishDeviceCommand('khoasmarthome/status_request', 'GATE_STATUS');
        print('📡 Requesting gate status from ESP32');
        return;
      }

      // Send level command to ESP32
      publishDeviceCommand(topicGateLevel, level.toString());
      print('🚪 Gate control: $percentage% -> Level $level sent to ESP32');

      // Update local state immediately for responsive UI
      _currentGateLevel = level;
      _gateStateController.add(level);

      // Save to Firebase
      if (_enableFirebase) {
        _saveGateStateToFirebase(level);
      }
    } catch (e) {
      print('❌ Error controlling gate: $e');
      rethrow;
    }
  }

  void controlMotor(String direction) {
    // Backward compatibility
    if (direction == 'FORWARD' || direction == 'ON') {
      controlGateLevel(_currentGateLevel == 0 ? 3 : 0);
    } else {
      publishDeviceCommand(topicMotor, direction);
    }
  }

  Future<void> _saveGateStateToFirebase(int level) async {
    if (!_enableFirebase || !_shouldWriteDeviceState()) return;

    try {
      final gateService = GateStateService();

      // Convert ESP32 level to percentage for Firebase
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

      await gateService.saveGateState(GateState(
        level: percentage,
        isMoving: false,
        timestamp: DateTime.now(),
      ));

      _lastDeviceWrite = DateTime.now();
      print('✅ Gate state saved to Firebase: $percentage%');
    } catch (e) {
      print('❌ Error saving gate state to Firebase: $e');
    }
  }

  // Compatibility methods
  void controlLed1(bool isOn) => controlLedGate(isOn);
  void controlLed2(bool isOn) => controlLedAround(isOn);

  // ========== ENHANCED GATE CONTROL WITH FIREBASE STATE SYNC ==========
  
  /// Enhanced gate control with relative movement based on Firebase state
  Future<bool> moveGateRelative(int relativePercent) async {
    try {
      final gateService = GateStateService();
      final result = await gateService.moveGateRelative(relativePercent);
      
      if (!result.success) {
        print('❌ Gate control failed: ${result.message}');
        return false;
      }

      print('🚪 ${result.message}');
      
      // Send MQTT command with new target level
      await publishGateControl(result.targetLevel);
      
      return true;
    } catch (e) {
      print('❌ Error in relative gate movement: $e');
      return false;
    }
  }

  /// Enhanced gate control with absolute positioning based on Firebase state
  Future<bool> moveGateAbsolute(int targetPercent) async {
    try {
      final gateService = GateStateService();
      final result = await gateService.moveGateAbsolute(targetPercent);
      
      if (!result.success) {
        print('❌ Gate control failed: ${result.message}');
        return false;
      }

      print('🚪 ${result.message}');
      
      // Send MQTT command with target level
      await publishGateControl(result.targetLevel);
      
      return true;
    } catch (e) {
      print('❌ Error in absolute gate movement: $e');
      return false;
    }
  }

  /// Convenience methods for common gate operations
  Future<bool> openGateMore(int additionalPercent) => 
      moveGateRelative(additionalPercent);
  
  Future<bool> closeGatePartially(int reducePercent) => 
      moveGateRelative(-reducePercent);
  
  Future<bool> openGateFully() => moveGateAbsolute(100);
  
  Future<bool> closeGateCompletely() => moveGateAbsolute(0);

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
  }
}
