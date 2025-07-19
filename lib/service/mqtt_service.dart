import 'dart:async';
import 'dart:io';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'package:smart_home/service/firebase_data_service.dart';

class MqttService {
  static const String _broker = 'i0bf1b65.ala.asia-southeast1.emqxsl.com';
  static const int _port = 8883;
  static const String _username = 'af07dd3c'; // App ID
  static const String _password = 'U0ofxmA6rbhSp4_O'; // App Secret
  static const String _clientIdBase = 'Flutter_SmartHome';
  
  // Firebase toggle - enable để lưu dữ liệu thực tế
  static const bool _enableFirebase = true; // Bật để lưu dữ liệu lên Firebase

  // Topics from ESP32 Dev (outdoor) - Giữ nguyên cho thiết bị ngoài trời
  static const String topicTemp = 'khoasmarthome/temperature';
  static const String topicHumid = 'khoasmarthome/humidity';
  static const String topicCurrent = 'khoasmarthome/current';
  static const String topicVoltage = 'khoasmarthome/voltage';
  static const String topicPower = 'khoasmarthome/power';
  static const String topicLedGate = 'khoasmarthome/led_gate';     // đèn cổng
  static const String topicLedAround = 'khoasmarthome/led_around'; // đèn xung quanh
  static const String topicMotor = 'khoasmarthome/motor';

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

  // Firebase service instance
  final FirebaseDataService _firebaseData = FirebaseDataService();

  Stream<SensorData> get sensorDataStream => _sensorDataController.stream;
  Stream<bool> get connectionStream => _connectionController.stream;
  bool get isConnected => _isConnected;

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
      disconnect();
    }
  }

  void _onConnected() {
    print('✅ MQTT Connected');
    _isConnected = true;
    _connectionController.add(true);
    _subscribeToTopics();
  }

  void _onDisconnected() {
    print('❌ MQTT Disconnected');
    _isConnected = false;
    _connectionController.add(false);
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

  void _subscribeToTopics() {
    final topics = [
      // Outdoor ESP32 Dev topics
      topicTemp,
      topicHumid,
      topicCurrent,
      topicVoltage,
      topicPower,
      // Indoor ESP32-S3 topics
      topicCurrentInside,
      topicVoltageInside,
      topicPowerInside,
    ];

    for (String topic in topics) {
      _client!.subscribe(topic, MqttQos.atLeastOnce);
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
      }
      
      // Update timestamps
      if (topic.startsWith('inside/')) {
        _currentDataInside = _currentDataInside.copyWith(lastUpdated: DateTime.now());
      } else {
        _currentData = _currentData.copyWith(lastUpdated: DateTime.now());
      }
      
      _sensorDataController.add(_currentData);
      
      // Send data to Firebase asynchronously (only if enabled)
      if (_enableFirebase) {
        // Write basic sensor data (outdoor)
        if (!topic.startsWith('inside/')) {
          _firebaseData.writeSensorData(_currentData).timeout(
            const Duration(seconds: 5),
          ).catchError((error) {
            print('⚠️ Firebase write error: $error');
            return false;
          });
          
          // Write detailed energy consumption data
          _firebaseData.writeEnergyConsumption(_currentData).timeout(
            const Duration(seconds: 5),
          ).catchError((error) {
            print('⚠️ Firebase energy write error: $error');
            return false;
          });
          
          // Also write power consumption data for energy tracking
          if (_currentData.power > 0) {
            _firebaseData.writePowerConsumption(
              deviceId: 'outdoor_system',
              power: _currentData.power,
              voltage: _currentData.voltage,
              current: _currentData.current,
              timestamp: DateTime.now(),
              metadata: {
                'type': 'outdoor_consumption',
                'efficiency': ((5.0 - _currentData.voltage) / 5.0 * 100).clamp(0, 100),
                'temperature': _currentData.temperature,
                'humidity': _currentData.humidity,
              },
            ).timeout(
              const Duration(seconds: 5),
            ).catchError((error) {
              print('⚠️ Firebase power consumption write error: $error');
              return false;
            });
          }
        } else {
          // Write indoor ESP32-S3 power consumption data
          if (_currentDataInside.power > 0) {
            _firebaseData.writePowerConsumption(
              deviceId: 'indoor_system',
              power: _currentDataInside.power,
              voltage: _currentDataInside.voltage,
              current: _currentDataInside.current,
              timestamp: DateTime.now(),
              metadata: {
                'type': 'indoor_consumption',
                'efficiency': ((5.0 - _currentDataInside.voltage) / 5.0 * 100).clamp(0, 100),
                'location': 'inside_house',
              },
            ).timeout(
              const Duration(seconds: 5),
            ).catchError((error) {
              print('⚠️ Firebase indoor power consumption write error: $error');
              return false;
            });
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
    // Log device state to Firebase asynchronously
    _firebaseData.writeDeviceState('led_gate', command, metadata: {'room': 'entrance', 'type': 'light', 'zone': 'gate'})
        .catchError((error) {
          print('⚠️ Firebase LED Gate error: $error');
          return false;
        });
    
    // Write estimated power consumption for LED Gate (assuming 10W when ON)
    if (_enableFirebase) {
      final estimatedPower = isOn ? 10.0 : 0.0;
      _firebaseData.writePowerConsumption(
        deviceId: 'led_gate',
        power: estimatedPower,
        voltage: _currentData.voltage,
        current: isOn ? 2.0 : 0.0, // Estimated current for 10W LED
        timestamp: DateTime.now(),
        metadata: {
          'room': 'entrance',
          'type': 'light',
          'zone': 'gate',
          'state': command,
        },
      ).catchError((error) {
        print('⚠️ Firebase LED Gate power error: $error');
        return false;
      });
    }
  }

  void controlLedAround(bool isOn) {
    final command = isOn ? 'ON' : 'OFF';
    publishDeviceCommand(topicLedAround, command);
    // Log device state to Firebase asynchronously
    _firebaseData.writeDeviceState('led_around', command, metadata: {'room': 'garden', 'type': 'light', 'zone': 'around'})
        .catchError((error) {
          print('⚠️ Firebase LED Around error: $error');
          return false;
        });
    
    // Write estimated power consumption for LED Around (assuming 15W when ON)
    if (_enableFirebase) {
      final estimatedPower = isOn ? 15.0 : 0.0;
      _firebaseData.writePowerConsumption(
        deviceId: 'led_around',
        power: estimatedPower,
        voltage: _currentData.voltage,
        current: isOn ? 3.0 : 0.0, // Estimated current for 15W LED
        timestamp: DateTime.now(),
        metadata: {
          'room': 'garden',
          'type': 'light',
          'zone': 'around',
          'state': command,
        },
      ).catchError((error) {
        print('⚠️ Firebase LED Around power error: $error');
        return false;
      });
    }
  }

  void controlMotor(String direction) {
    // direction can be 'FORWARD', 'REVERSE', or 'OFF'
    publishDeviceCommand(topicMotor, direction);
    // Log device state to Firebase asynchronously
    _firebaseData.writeDeviceState('motor', direction, metadata: {'room': 'garage', 'type': 'motor', 'zone': 'entrance'})
        .catchError((error) {
          print('⚠️ Firebase Motor error: $error');
          return false;
        });
    
    // Write estimated power consumption for Motor (assuming 50W when running)
    if (_enableFirebase) {
      final estimatedPower = (direction == 'FORWARD' || direction == 'REVERSE') ? 50.0 : 0.0;
      _firebaseData.writePowerConsumption(
        deviceId: 'motor',
        power: estimatedPower,
        voltage: _currentData.voltage,
        current: (direction == 'FORWARD' || direction == 'REVERSE') ? 10.0 : 0.0, // Estimated current for 50W Motor
        timestamp: DateTime.now(),
        metadata: {
          'room': 'garage',
          'type': 'motor',
          'zone': 'entrance',
          'state': direction,
        },
      ).catchError((error) {
        print('⚠️ Firebase Motor power error: $error');
        return false;
      });
    }
  }

  // Compatibility methods for backward compatibility (outdoor ESP32 Dev)
  void controlLed1(bool isOn) => controlLedGate(isOn);
  void controlLed2(bool isOn) => controlLedAround(isOn);

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

  // Helper method to log indoor device states
  void _logIndoorDeviceState(String deviceId, String command, String floor, String room, double estimatedPower) {
    if (!_enableFirebase) return;
    
    final isOn = command == 'ON';
    
    // Log device state to Firebase
    _firebaseData.writeDeviceState(deviceId, command, metadata: {
      'floor': floor,
      'room': room,
      'type': 'light',
      'controller': 'esp32_s3_indoor',
    }).catchError((error) {
      print('⚠️ Firebase $deviceId error: $error');
      return false;
    });
    
    // Write estimated power consumption
    final actualPower = isOn ? estimatedPower : 0.0;
    final estimatedCurrent = isOn ? (estimatedPower / _currentDataInside.voltage) : 0.0;
    
    _firebaseData.writePowerConsumption(
      deviceId: deviceId,
      power: actualPower,
      voltage: _currentDataInside.voltage,
      current: estimatedCurrent,
      timestamp: DateTime.now(),
      metadata: {
        'floor': floor,
        'room': room,
        'type': 'light',
        'controller': 'esp32_s3_indoor',
        'state': command,
      },
    ).catchError((error) {
      print('⚠️ Firebase $deviceId power error: $error');
      return false;
    });
  }

  void disconnect() {
    _client?.disconnect();
    _isConnected = false;
    _connectionController.add(false);
  }

  void dispose() {
    disconnect();
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
