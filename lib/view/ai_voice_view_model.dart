import 'package:flutter/material.dart';
import 'package:smart_home/provider/base_model.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:smart_home/service/firebase_data_service.dart';
import 'package:smart_home/service/mqtt_service.dart';
import 'package:smart_home/service/navigation_service.dart';
import 'package:smart_home/service/gemini_service.dart';
import 'package:smart_home/view/rooms_view_model.dart';
import 'package:smart_home/provider/getit.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:smart_home/core/permission_helper.dart';

class AIVoiceViewModel extends BaseModel with WidgetsBindingObserver {
  bool _isListening = false;
  bool _isProcessing = false;
  bool _showChatBox = false;
  bool _isInitializing = false;
  String _recognizedText = '';
  String _aiResponse = '';
  List<String> _commandHistory = [];
  List<Map<String, dynamic>> _chatMessages = [];
  List<Map<String, dynamic>> _customCommands = [];

  // Firebase services
  final FirebaseDataService _firebaseData = getIt<FirebaseDataService>();
  final MqttService _mqttService = getIt<MqttService>();
  final RoomsViewModel _roomsViewModel = getIt<RoomsViewModel>();

  // Current user
  String? _currentUserId;

  // Available zones and devices
  Map<String, dynamic> _availableZonesAndDevices = {};

  // Speech recognition và TTS
  final SpeechToText _speechToText = SpeechToText();
  final FlutterTts _flutterTts = FlutterTts();
  bool _speechEnabled = false;

  // Chat controller
  final TextEditingController _chatController = TextEditingController();

  // Mapping các lệnh tiếng Việt với thiết bị thực tế
  final Map<String, Map<String, dynamic>> _deviceCommands = {
    // Đèn - kết nối với MQTT thực tế
    'đèn cổng': {
      'type': 'light', 
      'mqtt_id': 'led_gate', 
      'device': 'Đèn cổng',
      'room_id': '1',
      'device_id': '1'
    },
    'đèn xung quanh': {
      'type': 'light', 
      'mqtt_id': 'led_around', 
      'device': 'Đèn xung quanh',
      'room_id': '1',
      'device_id': '2'
    },
    'đèn phòng khách': {
      'type': 'light',
      'mqtt_id': 'led_living',
      'device': 'Đèn phòng khách',
      'room_id': '1',
      'device_id': '1'
    },
    'đèn phòng ngủ': {
      'type': 'light',
      'mqtt_id': 'led_bedroom',
      'device': 'Đèn phòng ngủ',
      'room_id': '2',
      'device_id': '4'
    },
    'đèn bếp': {
      'type': 'light',
      'mqtt_id': 'led_kitchen',
      'device': 'Đèn bếp',
      'room_id': '3',
      'device_id': '6'
    },
    'tất cả đèn': {
      'type': 'light_all',
      'mqtt_id': 'all_lights',
      'device': 'Tất cả đèn'
    },

    // Quạt
    'quạt phòng khách': {
      'type': 'fan',
      'mqtt_id': 'fan_living',
      'device': 'Quạt phòng khách',
      'room_id': '1',
      'device_id': '3'
    },
    'quạt phòng ngủ': {
      'type': 'fan',
      'mqtt_id': 'fan_bedroom',
      'device': 'Quạt phòng ngủ',
      'room_id': '2',
      'device_id': '5'
    },
    'quạt bếp': {
      'type': 'fan',
      'mqtt_id': 'fan_kitchen',
      'device': 'Quạt bếp',
      'room_id': '3',
      'device_id': '7'
    },

    // TV
    'tivi': {
      'type': 'tv',
      'mqtt_id': 'tv_main',
      'device': 'TV',
      'room_id': '1',
      'device_id': '2'
    },
    'tv': {
      'type': 'tv',
      'mqtt_id': 'tv_main',
      'device': 'TV',
      'room_id': '1',
      'device_id': '2'
    },

    // Motor/Cửa - More alternatives for gate
    'cửa': {
      'type': 'motor',
      'mqtt_id': 'motor_main',
      'device': 'Cửa chính'
    },
    'cổng': {
      'type': 'motor',
      'mqtt_id': 'motor_gate',
      'device': 'Cổng'
    },
    'motor': {
      'type': 'motor',
      'mqtt_id': 'motor_gate',
      'device': 'Motor cổng'
    },
    'motor cổng': {
      'type': 'motor',
      'mqtt_id': 'motor_gate',
      'device': 'Motor cổng'
    },
  };

  // Các từ khóa hành động
  final List<String> _onKeywords = ['mở', 'bật', 'khởi động', 'sáng', 'mởi', 'mờ'];
  final List<String> _offKeywords = ['tắt', 'đóng', 'ngắt', 'tối', 'đống'];
  final List<String> _adjustKeywords = [
    'chỉnh',
    'điều chỉnh',
    'đặt',
    'tăng',
    'giảm'
  ];

  bool get isListening => _isListening;
  bool get isProcessing => _isProcessing;
  bool get showChatBox => _showChatBox;
  bool get isInitializing => _isInitializing;
  String get recognizedText => _recognizedText;
  String get aiResponse => _aiResponse;
  List<String> get commandHistory => _commandHistory;
  List<Map<String, dynamic>> get chatMessages => _chatMessages;
  List<Map<String, dynamic>> get customCommands => _customCommands;
  Map<String, dynamic> get availableZonesAndDevices =>
      _availableZonesAndDevices;
  TextEditingController get chatController => _chatController;
  bool get speechEnabled => _speechEnabled;

  // Lifecycle methods for WidgetsBindingObserver
  @override
  void didChangeMetrics() {
    // Handle metrics change
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Handle app lifecycle state changes
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      // Stop listening when app goes to background
      if (_isListening) {
        stopListening();
      }
    }
  }

  @override
  void didHaveMemoryPressure() {
    // Handle memory pressure
  }

  void initialize() async {
    _isInitializing = true;
    notifyListeners();

    // Add this observer to listen for lifecycle changes
    WidgetsBinding.instance.addObserver(this);
    // Get current user
    _currentUserId = FirebaseAuth.instance.currentUser?.uid;

    // Request microphone permission first
    await _requestPermission();

    // Initialize speech recognition
    await _initSpeech();

    // Initialize TTS
    await _initializeTts();

    // ===== MQTT CONNECTION - FIX FOR DEVICE CONTROL =====
    // Connect MQTT service to enable device control
    await _connectMqttService();

    // Load user data
    await _loadUserData();

    print('AI Voice Assistant initialized - Speech enabled: $_speechEnabled');

    _isInitializing = false;
    notifyListeners(); // Notify listeners after initialization
  }

  /// Connect MQTT service for device control
  Future<void> _connectMqttService() async {
    try {
      print('🔌 AI Voice: Connecting to MQTT service...');
      await _mqttService.connect();
      print('✅ AI Voice: MQTT service connected successfully');
    } catch (e) {
      print('❌ AI Voice: Failed to connect MQTT service: $e');
    }
  }

  Future<void> _loadUserData() async {
    if (_currentUserId == null) return;

    try {
      // Load chat history
      final chatHistory = await _firebaseData.getChatHistory(
        userId: _currentUserId!,
        limit: 50,
      );

      _chatMessages = chatHistory
          .map((msg) => {
                'message': msg['message'],
                'isUser': msg['is_user'],
                'timestamp': (msg['timestamp'] as Timestamp).toDate(),
                'response': msg['response'],
              })
          .toList();

      // Load custom commands
      _customCommands = await _firebaseData.getCustomCommands(
        userId: _currentUserId!,
      );

      // Load available zones and devices
      _availableZonesAndDevices =
          await _firebaseData.getAvailableZonesAndDevices();

      notifyListeners();
    } catch (e) {
      print('Error loading user data: $e');
    }
  }

  // Initialize speech recognition (theo code tham khảo)
  Future<bool> _initSpeech() async {
    try {
      print('=== INIT SPEECH (New Logic) ===');

      _speechEnabled = await _speechToText.initialize(
        onStatus: (status) {
          print('Speech status: $status');
          if (status == 'done' || status == 'notListening') {
            _isListening = false;
            notifyListeners();
          }
        },
        onError: (errorNotification) {
          print('Speech error: ${errorNotification.errorMsg}');
          _isListening = false;
          notifyListeners();
        },
        debugLogging: true,
      );

      print('Speech initialized: $_speechEnabled');
      notifyListeners();
      return _speechEnabled;
    } catch (e) {
      print('Speech initialization error: $e');
      _speechEnabled = false;
      notifyListeners();
      return false;
    }
  }

  // Request microphone permission (theo code tham khảo)
  Future<void> _requestPermission() async {
    var status = await Permission.microphone.status;
    print('Current permission status: $status');

    if (status.isDenied) {
      print('Requesting microphone permission...');
      final result = await Permission.microphone.request();
      print('Permission request result: $result');
    }
  }

  Future<void> _initializeTts() async {
    try {
      await _flutterTts.setLanguage('vi-VN');
      await _flutterTts.setPitch(1.0);
      await _flutterTts.setSpeechRate(0.5);
      await _flutterTts.setVolume(1.0);

      print('TTS initialized successfully');
    } catch (e) {
      print('Failed to initialize TTS: $e');
    }
  }

  void toggleListening() {
    if (_isListening) {
      stopListening();
    } else {
      startListening();
    }
  }

  // Start listening (theo code tham khảo)
  Future<void> startListening() async {
    print('=== Start Listening (New Logic) ===');

    if (!_speechEnabled) {
      print('Speech not enabled, trying to initialize...');
      _speechEnabled = await _initSpeech();
      if (!_speechEnabled) {
        print('Failed to initialize speech, requesting permission...');
        await _requestPermission();
        _speechEnabled = await _initSpeech();

        if (!_speechEnabled) {
          print('Speech still not available after permission request');
          return;
        }
      }
    }

    if (!_isListening) {
      _isListening = true;
      _recognizedText = '';
      _aiResponse = '';
      notifyListeners();

      try {
        await _speechToText.listen(
          onResult: (result) {
            _recognizedText = result.recognizedWords;
            print('Recognized: $_recognizedText');
            notifyListeners();
          },
          listenFor: const Duration(seconds: 30),
          pauseFor: const Duration(seconds: 3),
          partialResults: true,
          localeId: 'vi-VN',
          cancelOnError: false,
          listenMode: ListenMode.deviceDefault,
        );

        print('Started listening successfully');
      } catch (e) {
        print('Listen error: $e');
        _isListening = false;
        notifyListeners();
      }
    }
  }

  // Stop listening (theo code tham khảo)
  Future<void> stopListening() async {
    if (_isListening) {
      _isListening = false;
      notifyListeners();
      await _speechToText.stop();

      print('Stopped listening');

      // Process command if recognized text is available
      if (_recognizedText.isNotEmpty) {
        _processCommand(_recognizedText);
      }
    }
  }

  void _processCommand(String command) async {
    if (command.trim().isEmpty) return;

    _isProcessing = true;
    _isListening = false;
    notifyListeners();

    // Simulate processing delay
    await Future.delayed(const Duration(milliseconds: 500));

    _isProcessing = false;

    // Try to match with custom commands first
    final customResponse = await _processCustomCommand(command);

    if (customResponse != null) {
      _aiResponse = customResponse;
    } else {
      // Check if it's a smart home command
      if (GeminiService.isSmartHomeCommand(command)) {
        _aiResponse = _processVietnameseCommand(command);
      } else {
        // Forward to Gemini for general questions
        _aiResponse = await _processGeneralQuestion(command);
      }
    }

    _commandHistory.insert(0, command);
    if (_commandHistory.length > 10) {
      _commandHistory.removeAt(10);
    }

    // Save to Firebase
    await _saveChatMessage(command, _aiResponse, isUser: false);

    // Speak the response
    await _speakResponse(_aiResponse);

    notifyListeners();
  }

  /// Xử lý câu hỏi tổng quát bằng Gemini AI
  Future<String> _processGeneralQuestion(String question) async {
    try {
      // Enhance the question with Vietnamese context
      final enhancedQuestion = GeminiService.enhanceQuestion(question);
      
      // Get response from Gemini
      final geminiResponse = await GeminiService.generateResponse(enhancedQuestion);
      
      return geminiResponse;
    } catch (e) {
      print('Error processing general question: $e');
      return 'Xin lỗi, tôi không thể trả lời câu hỏi này lúc này. Vui lòng thử lại sau.';
    }
  }

  Future<String?> _processCustomCommand(String command) async {
    if (_currentUserId == null) return null;

    try {
      // Search for matching custom commands
      final matchingCommands = await _firebaseData.searchCustomCommands(
        userId: _currentUserId!,
        searchText: command,
      );

      if (matchingCommands.isNotEmpty) {
        final customCommand = matchingCommands.first;
        final deviceId = customCommand['device_id'];
        final action = customCommand['action'];
        final zone = customCommand['zone'];

        // Execute the command
        await _executeDeviceCommand(deviceId, action);

        return 'Đã thực hiện lệnh tùy chỉnh: ${customCommand['description'] ?? customCommand['command_text']} trong khu vực $zone! ✅';
      }

      return null;
    } catch (e) {
      print('Error processing custom command: $e');
      return null;
    }
  }

  Future<void> _executeDeviceCommand(String deviceId, String action) async {
    try {
      print('🎯 AI Voice: Executing device command - Device: $deviceId, Action: $action');
      
      // Check MQTT connection status first
      if (!_mqttService.isConnected) {
        print('⚠️ AI Voice: MQTT not connected, attempting to reconnect...');
        await _connectMqttService();
        
        // Wait a bit for connection to establish
        await Future.delayed(const Duration(milliseconds: 500));
      }
      
      final bool isOn = action.toLowerCase() == 'on';
      
      switch (deviceId) {
        case 'led_gate':
          print('💡 AI Voice: Controlling gate LED - ${isOn ? 'ON' : 'OFF'}');
          _mqttService.controlLedGate(isOn);
          break;
        case 'led_around':
          print('💡 AI Voice: Controlling around LED - ${isOn ? 'ON' : 'OFF'}');
          _mqttService.controlLedAround(isOn);
          break;
        case 'motor_main':
        case 'motor_gate':
          // Motor commands: OPEN, CLOSE, STOP
          String motorCommand;
          if (action.toLowerCase() == 'on' || action.toLowerCase() == 'open') {
            motorCommand = 'OPEN';
          } else if (action.toLowerCase() == 'off' || action.toLowerCase() == 'close') {
            motorCommand = 'CLOSE';
          } else {
            motorCommand = 'STOP';
          }
          print('🚪 AI Voice: Controlling motor - $motorCommand');
          _mqttService.controlMotor(motorCommand);
          
          // Also try controlling gate by level for percentage-based control
          if (action.toLowerCase() == 'on' || action.toLowerCase() == 'open') {
            print('🚪 AI Voice: Also setting gate level to 100%');
            await _mqttService.publishGateControl(100);
          } else if (action.toLowerCase() == 'off' || action.toLowerCase() == 'close') {
            print('🚪 AI Voice: Also setting gate level to 0%');
            await _mqttService.publishGateControl(0);
          }
          break;
        default:
          print('❌ AI Voice: Unknown device: $deviceId');
      }
      
      print('✅ AI Voice: Device command executed successfully');
    } catch (e) {
      print('❌ AI Voice: Error executing device command: $e');
    }
  }

  /// Điều khiển thiết bị thông qua voice command
  Future<void> _controlDeviceByVoice(String deviceKey, String action) async {
    try {
      print('🗣️ AI Voice: Processing voice command - Device: $deviceKey, Action: $action');
      
      if (!_deviceCommands.containsKey(deviceKey)) {
        print('❌ AI Voice: Device key not found: $deviceKey');
        return;
      }

      final deviceInfo = _deviceCommands[deviceKey]!;
      final mqttId = deviceInfo['mqtt_id'];
      final roomId = deviceInfo['room_id'];
      final deviceId = deviceInfo['device_id'];
      final deviceName = deviceInfo['device'];

      print('📋 AI Voice: Device info - MQTT ID: $mqttId, Room: $roomId, Device: $deviceId, Name: $deviceName');

      // Điều khiển thông qua MQTT
      await _executeDeviceCommand(mqttId, action);

      // Cập nhật UI thông qua RoomsViewModel (nếu có room_id và device_id)
      if (roomId != null && deviceId != null) {
        if (action.toLowerCase() == 'toggle') {
          _roomsViewModel.toggleDevice(roomId, deviceId);
          print('🔄 AI Voice: Toggled device in UI - Room: $roomId, Device: $deviceId');
        } else {
          // Cập nhật trạng thái thiết bị trong UI
          _updateDeviceStateInUI(roomId, deviceId, action.toLowerCase() == 'on');
          print('🔄 AI Voice: Updated device state in UI - Room: $roomId, Device: $deviceId, State: ${action.toLowerCase() == 'on'}');
        }
      }
    } catch (e) {
      print('❌ AI Voice: Error controlling device by voice: $e');
    }
  }

  /// Cập nhật trạng thái thiết bị trong UI
  void _updateDeviceStateInUI(String roomId, String deviceId, bool isOn) {
    try {
      for (var room in _roomsViewModel.rooms) {
        if (room.id == roomId) {
          for (var device in room.devices) {
            if (device.id == deviceId) {
              device.isOn = isOn;
              _roomsViewModel.notifyListeners();
              return;
            }
          }
        }
      }
    } catch (e) {
      print('Error updating device state in UI: $e');
    }
  }

  void executeQuickCommand(String command) async {
    _recognizedText = command;
    _isProcessing = true;
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 500));

    _isProcessing = false;

    // Try to match with custom commands first
    final customResponse = await _processCustomCommand(command);

    if (customResponse != null) {
      _aiResponse = customResponse;
    } else {
      // Check if it's a smart home command
      if (GeminiService.isSmartHomeCommand(command)) {
        _aiResponse = _processVietnameseCommand(command);
      } else {
        // Forward to Gemini for general questions
        _aiResponse = await _processGeneralQuestion(command);
      }
    }

    _commandHistory.insert(0, command);
    if (_commandHistory.length > 10) {
      _commandHistory.removeAt(10);
    }

    // Save to Firebase
    await _saveChatMessage(command, _aiResponse, isUser: false);

    // Speak the response
    await _speakResponse(_aiResponse);

    notifyListeners();
  }

  Future<void> _speakResponse(String text) async {
    try {
      // Remove emojis and special characters for better TTS
      String cleanText = text.replaceAll(RegExp(r'[^\w\s\u00C0-\u1EF9]'), '');
      await _flutterTts.speak(cleanText);
    } catch (e) {
      print('Error speaking response: $e');
    }
  }

  String _processVietnameseCommand(String command) {
    final lowerCommand = command.toLowerCase();
    print('🇻🇳 AI Voice: Processing Vietnamese command: "$command"');

    // Phân tích lệnh
    String action = '';
    String device = '';
    String? temperature;

    // Xác định hành động
    for (String keyword in _onKeywords) {
      if (lowerCommand.contains(keyword)) {
        action = 'on';
        print('✅ AI Voice: Found ON keyword: $keyword');
        break;
      }
    }

    if (action.isEmpty) {
      for (String keyword in _offKeywords) {
        if (lowerCommand.contains(keyword)) {
          action = 'off';
          print('✅ AI Voice: Found OFF keyword: $keyword');
          break;
        }
      }
    }

    if (action.isEmpty) {
      for (String keyword in _adjustKeywords) {
        if (lowerCommand.contains(keyword)) {
          action = 'adjust';
          print('✅ AI Voice: Found ADJUST keyword: $keyword');
          break;
        }
      }
    }

    // Xác định thiết bị
    for (String deviceKey in _deviceCommands.keys) {
      if (lowerCommand.contains(deviceKey)) {
        device = deviceKey;
        print('✅ AI Voice: Found device: $deviceKey');
        break;
      }
    }

    // Debug log: show analysis result
    print('📊 AI Voice: Command analysis - Action: "$action", Device: "$device"');

    // Xác định nhiệt độ nếu có
    final tempRegex = RegExp(r'(\d+)\s*độ');
    final tempMatch = tempRegex.firstMatch(lowerCommand);
    if (tempMatch != null) {
      temperature = tempMatch.group(1);
      action = 'adjust';
      print('🌡️ AI Voice: Found temperature: ${temperature}°C');
    }

    // Xử lý lệnh đặc biệt
    if (lowerCommand.contains('chế độ đi ngủ') ||
        lowerCommand.contains('good night')) {
      print('🌙 AI Voice: Executing night mode');
      _executeNightMode();
      return _handleNightMode();
    }

    if (lowerCommand.contains('chế độ ra về') ||
        lowerCommand.contains('về nhà')) {
      print('🏡 AI Voice: Executing home mode');
      _executeHomeMode();
      return _handleHomeMode();
    }

    if (lowerCommand.contains('chế độ tiết kiệm') ||
        lowerCommand.contains('tiết kiệm năng lượng')) {
      print('🍃 AI Voice: Executing eco mode');
      _executeEcoMode();
      return _handleEcoMode();
    }

    // Xử lý lệnh thông thường
    if (device.isNotEmpty && _deviceCommands.containsKey(device)) {
      final deviceInfo = _deviceCommands[device]!;
      final deviceName = deviceInfo['device'];

      print('🎯 AI Voice: Executing device control - Device: $deviceName, Action: $action');

      // Thực thi lệnh điều khiển thiết bị
      _controlDeviceByVoice(device, action);

      switch (action) {
        case 'on':
          return 'Đã bật $deviceName thành công! ✅';
        case 'off':
          return 'Đã tắt $deviceName thành công! ✅';
        case 'adjust':
          if (temperature != null) {
            return 'Đã đặt $deviceName ở nhiệt độ ${temperature}°C! 🌡️';
          } else {
            return 'Đã điều chỉnh $deviceName theo yêu cầu! ⚙️';
          }
        default:
          return 'Đã thực hiện lệnh cho $deviceName! ✅';
      }
    }

    // Lệnh không nhận diện được
    print('❌ AI Voice: Command not recognized - Action: "$action", Device: "$device"');
    return 'Xin lỗi, tôi không hiểu lệnh này. Vui lòng thử lại với các lệnh như "Mở đèn phòng khách" hoặc "Tắt quạt phòng ngủ". 🤔';
  }

  String _handleNightMode() {
    return '''Đã kích hoạt chế độ đi ngủ! 🌙
• Tắt tất cả đèn trừ đèn ngủ
• Giảm nhiệt độ điều hòa xuống 24°C  
• Tắt TV và loa
• Kích hoạt camera an ninh
Chúc bạn ngủ ngon! 😴''';
  }

  String _handleHomeMode() {
    return '''Chào mừng bạn về nhà! 🏡
• Bật đèn phòng khách và hành lang
• Đặt điều hòa ở 26°C
• Bật quạt phòng khách
• Mở cổng tự động
Chúc bạn một buổi tối vui vẻ! 😊''';
  }

  String _handleEcoMode() {
    return '''Đã kích hoạt chế độ tiết kiệm năng lượng! 🍃
• Giảm độ sáng đèn xuống 70%
• Đặt điều hòa ở 27°C
• Tắt các thiết bị không cần thiết
• Ước tính tiết kiệm 30% điện năng
Cảm ơn bạn đã bảo vệ môi trường! 🌱''';
  }

  /// Thực thi chế độ đi ngủ
  void _executeNightMode() {
    try {
      print('🌙 AI Voice: Executing night mode...');
      // Tắt hầu hết đèn, chỉ giữ đèn ngủ
      _controlDeviceByVoice('đèn phòng khách', 'off');
      _controlDeviceByVoice('đèn bếp', 'off');
      _controlDeviceByVoice('đèn cổng', 'off');
      _controlDeviceByVoice('đèn xung quanh', 'off');
      
      // Bật đèn phòng ngủ với độ sáng thấp
      _controlDeviceByVoice('đèn phòng ngủ', 'on');
      
      // Tắt TV và thiết bị giải trí
      _controlDeviceByVoice('tivi', 'off');
      
      print('✅ AI Voice: Night mode executed successfully');
    } catch (e) {
      print('❌ AI Voice: Error executing night mode: $e');
    }
  }

  /// Thực thi chế độ về nhà
  void _executeHomeMode() {
    try {
      print('🏡 AI Voice: Executing home mode...');
      // Bật đèn chính
      _controlDeviceByVoice('đèn phòng khách', 'on');
      _controlDeviceByVoice('đèn cổng', 'on');
      _controlDeviceByVoice('đèn xung quanh', 'on');
      
      // Bật quạt phòng khách
      _controlDeviceByVoice('quạt phòng khách', 'on');
      
      // Mở cổng (nếu có)
      _controlDeviceByVoice('cổng', 'on');
      
      print('✅ AI Voice: Home mode executed successfully');
    } catch (e) {
      print('❌ AI Voice: Error executing home mode: $e');
    }
  }

  /// Thực thi chế độ tiết kiệm năng lượng
  void _executeEcoMode() {
    try {
      print('🍃 AI Voice: Executing eco mode...');
      // Tắt các thiết bị không cần thiết
      _controlDeviceByVoice('tivi', 'off');
      _controlDeviceByVoice('đèn xung quanh', 'off');
      _controlDeviceByVoice('đèn bếp', 'off');
      
      // Giảm quạt
      _controlDeviceByVoice('quạt phòng khách', 'off');
      _controlDeviceByVoice('quạt phòng ngủ', 'off');
      
      print('✅ AI Voice: Eco mode executed successfully');
    } catch (e) {
      print('❌ AI Voice: Error executing eco mode: $e');
    }
  }

  void showSettings(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: const BoxDecoration(
          color: Color(0xFF2E3440),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: DefaultTabController(
          length: 3,
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  color: Color(0xFF3B4252),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Cài đặt AI Voice',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close, color: Colors.white),
                    ),
                  ],
                ),
              ),

              // Tab Bar
              Container(
                color: const Color(0xFF3B4252),
                child: const TabBar(
                  indicatorColor: Colors.blue,
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.white54,
                  tabs: [
                    Tab(text: 'Lịch sử'),
                    Tab(text: 'Lệnh tùy chỉnh'),
                    Tab(text: 'Cài đặt'),
                  ],
                ),
              ),

              // Tab Content
              Expanded(
                child: TabBarView(
                  children: [
                    _buildHistoryTab(context),
                    _buildCustomCommandsTab(context),
                    _buildSettingsTab(context),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHistoryTab(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Command History
          Row(
            children: [
              const Text(
                'Lịch sử lệnh:',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white70,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: clearHistory,
                child: const Text(
                  'Xóa tất cả',
                  style: TextStyle(color: Colors.red, fontSize: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          Expanded(
            flex: 1,
            child: _commandHistory.isEmpty
                ? const Center(
                    child: Text(
                      'Chưa có lệnh nào được thực hiện',
                      style: TextStyle(color: Colors.white54),
                    ),
                  )
                : ListView.builder(
                    itemCount: _commandHistory.length,
                    itemBuilder: (context, index) {
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.history,
                                color: Colors.white54, size: 16),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _commandHistory[index],
                                style: const TextStyle(color: Colors.white70),
                              ),
                            ),
                            IconButton(
                              onPressed: () {
                                Navigator.pop(context);
                                executeQuickCommand(_commandHistory[index]);
                              },
                              icon: const Icon(Icons.replay,
                                  color: Colors.blue, size: 16),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),

          const SizedBox(height: 20),

          // Chat History
          Row(
            children: [
              const Text(
                'Lịch sử chat:',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white70,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: clearChatMessages,
                child: const Text(
                  'Xóa tất cả',
                  style: TextStyle(color: Colors.red, fontSize: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          Expanded(
            flex: 1,
            child: _chatMessages.isEmpty
                ? const Center(
                    child: Text(
                      'Chưa có tin nhắn nào',
                      style: TextStyle(color: Colors.white54),
                    ),
                  )
                : ListView.builder(
                    itemCount: _chatMessages.length,
                    itemBuilder: (context, index) {
                      final message = _chatMessages[index];
                      final isUser = message['isUser'] as bool;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isUser
                              ? Colors.blue.withOpacity(0.1)
                              : Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              isUser ? Icons.person : Icons.smart_toy,
                              color: isUser ? Colors.blue : Colors.green,
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    message['message'],
                                    style:
                                        const TextStyle(color: Colors.white70),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${message['timestamp']?.toString().split(' ')[1].substring(0, 5) ?? ''}',
                                    style: const TextStyle(
                                      color: Colors.white38,
                                      fontSize: 10,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomCommandsTab(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Lệnh tùy chỉnh của bạn:',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white70,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  // Show custom commands manager
                },
                child: const Text(
                  'Quản lý',
                  style: TextStyle(color: Colors.blue, fontSize: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Expanded(
            child: _customCommands.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.voice_over_off,
                            size: 48, color: Colors.white24),
                        SizedBox(height: 16),
                        Text(
                          'Chưa có lệnh tùy chỉnh nào',
                          style: TextStyle(color: Colors.white54),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Thêm lệnh tùy chỉnh để điều khiển\nthiết bị theo cách riêng của bạn',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.white38, fontSize: 12),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: _customCommands.length,
                    itemBuilder: (context, index) {
                      final command = _customCommands[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    command['command_text'] ?? '',
                                    style: const TextStyle(
                                      color: Colors.blue,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                const Spacer(),
                                IconButton(
                                  onPressed: () {
                                    Navigator.pop(context);
                                    executeQuickCommand(
                                        command['command_text'] ?? '');
                                  },
                                  icon: const Icon(Icons.play_arrow,
                                      color: Colors.green, size: 16),
                                ),
                              ],
                            ),
                            if (command['description'] != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  command['description'],
                                  style: const TextStyle(
                                      color: Colors.white54, fontSize: 12),
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsTab(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Voice Settings
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.mic, color: Colors.white70),
                  title: const Text('Độ nhạy micro',
                      style: TextStyle(color: Colors.white)),
                  trailing:
                      const Text('Cao', style: TextStyle(color: Colors.blue)),
                  onTap: () {},
                ),
                const Divider(color: Colors.white24),
                ListTile(
                  leading: const Icon(Icons.language, color: Colors.white70),
                  title: const Text('Ngôn ngữ',
                      style: TextStyle(color: Colors.white)),
                  trailing: const Text('Tiếng Việt',
                      style: TextStyle(color: Colors.blue)),
                  onTap: () {},
                ),
                const Divider(color: Colors.white24),
                ListTile(
                  leading: const Icon(Icons.volume_up, color: Colors.white70),
                  title: const Text('Âm lượng phản hồi',
                      style: TextStyle(color: Colors.white)),
                  trailing: const Text('Trung bình',
                      style: TextStyle(color: Colors.blue)),
                  onTap: () {},
                ),
                const Divider(color: Colors.white24),
                ListTile(
                  leading: Icon(
                    _speechEnabled ? Icons.mic : Icons.mic_off,
                    color: _speechEnabled ? Colors.green : Colors.red,
                  ),
                  title: const Text('Trạng thái nhận diện giọng nói',
                      style: TextStyle(color: Colors.white)),
                  trailing: Text(
                    _speechEnabled ? 'Hoạt động' : 'Không khả dụng',
                    style: TextStyle(
                        color: _speechEnabled ? Colors.green : Colors.red),
                  ),
                  onTap: () async {
                    if (!_speechEnabled) {
                      await _initSpeech();
                    } else {
                      // Test speech recognition
                      if (_speechToText.isAvailable) {
                        _showTestSpeechDialog(context);
                      }
                    }
                  },
                ),
                const Divider(color: Colors.white24),
                ListTile(
                  leading: const Icon(Icons.camera_alt, color: Colors.white70),
                  title: const Text('Quyền Camera',
                      style: TextStyle(color: Colors.white)),
                  trailing: FutureBuilder<PermissionStatus>(
                    future: Permission.camera.status,
                    builder: (context, snapshot) {
                      if (snapshot.hasData) {
                        final isGranted = snapshot.data!.isGranted;
                        return Text(
                          isGranted ? 'Đã cấp' : 'Chưa cấp',
                          style: TextStyle(
                              color: isGranted ? Colors.green : Colors.red),
                        );
                      }
                      return const Text('Đang kiểm tra...',
                          style: TextStyle(color: Colors.grey));
                    },
                  ),
                  onTap: () async {
                    final granted =
                        await PermissionHelper.requestCameraPermission();
                    if (!granted) {
                      await PermissionHelper.showPermissionDialog(
                          context, 'Camera');
                    }
                    // Refresh UI after permission change
                    Future.delayed(const Duration(milliseconds: 500), () {
                      (context as Element).markNeedsBuild();
                    });
                  },
                ),
                const Divider(color: Colors.white24),
                ListTile(
                  leading: const Icon(Icons.mic, color: Colors.white70),
                  title: const Text('Quyền Microphone',
                      style: TextStyle(color: Colors.white)),
                  trailing: FutureBuilder<PermissionStatus>(
                    future: Permission.microphone.status,
                    builder: (context, snapshot) {
                      if (snapshot.hasData) {
                        final isGranted = snapshot.data!.isGranted;
                        return Text(
                          isGranted ? 'Đã cấp' : 'Chưa cấp',
                          style: TextStyle(
                              color: isGranted ? Colors.green : Colors.red),
                        );
                      }
                      return const Text('Đang kiểm tra...',
                          style: TextStyle(color: Colors.grey));
                    },
                  ),
                  onTap: () async {
                    final granted =
                        await PermissionHelper.requestMicrophonePermission();
                    if (!granted) {
                      await PermissionHelper.showPermissionDialog(
                          context, 'Microphone');
                    }
                    // Refresh UI after permission change
                    Future.delayed(const Duration(milliseconds: 500), () {
                      (context as Element).markNeedsBuild();
                    });
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Statistics
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Thống kê:',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        'Lệnh đã thực hiện',
                        _commandHistory.length.toString(),
                        Icons.history,
                        Colors.blue,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatCard(
                        'Tin nhắn chat',
                        _chatMessages.length.toString(),
                        Icons.chat,
                        Colors.green,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        'Lệnh tùy chỉnh',
                        _customCommands.length.toString(),
                        Icons.tune,
                        Colors.orange,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatCard(
                        'Thiết bị kết nối',
                        _availableZonesAndDevices.length.toString(),
                        Icons.device_hub,
                        Colors.purple,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 10,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // Helper method để xóa lịch sử
  void clearHistory() {
    _commandHistory.clear();
    notifyListeners();
  }

  // Chat Box Functions
  void toggleChatBox() {
    _showChatBox = !_showChatBox;
    notifyListeners();
  }

  void sendChatMessage(String message) async {
    if (message.trim().isEmpty) return;

    // Add user message
    _chatMessages.insert(0, {
      'message': message,
      'isUser': true,
      'timestamp': DateTime.now(),
    });

    _chatController.clear();
    notifyListeners();

    // Save user message to Firebase
    await _saveChatMessage(message, null, isUser: true);

    // Process and respond
    await Future.delayed(const Duration(milliseconds: 500));

    // Try to match with custom commands first
    final customResponse = await _processCustomCommand(message);
    String response;

    if (customResponse != null) {
      response = customResponse;
    } else {
      // Check if it's a smart home command
      if (GeminiService.isSmartHomeCommand(message)) {
        response = _processVietnameseCommand(message);
      } else {
        // Forward to Gemini for general questions
        response = await _processGeneralQuestion(message);
      }
    }

    // Add AI response
    _chatMessages.insert(0, {
      'message': response,
      'isUser': false,
      'timestamp': DateTime.now(),
    });

    // Keep only 50 messages
    if (_chatMessages.length > 50) {
      _chatMessages.removeRange(50, _chatMessages.length);
    }

    // Save AI response to Firebase
    await _saveChatMessage(response, null, isUser: false);

    // Speak the response
    await _speakResponse(response);

    notifyListeners();
  }

  Future<void> _saveChatMessage(String message, String? response,
      {required bool isUser}) async {
    if (_currentUserId == null) return;

    // HEAVY THROTTLING for chat saves - only save important messages
    if (!isUser && (response == null || response.length < 10)) {
      return; // Skip saving short or empty AI responses
    }

    // Only save user messages if they're substantial commands
    if (isUser && message.length < 5) {
      return; // Skip saving very short user messages
    }

    try {
      await _firebaseData.writeChatMessage(
        userId: _currentUserId!,
        message: message,
        isUser: isUser,
        timestamp: DateTime.now(),
        response: response,
      );
    } catch (e) {
      print('Error saving chat message: $e');
    }
  }

  void clearChatMessages() async {
    _chatMessages.clear();
    notifyListeners();

    // Clear chat history from Firebase for current user
    if (_currentUserId != null) {
      await _firebaseData.clearChatHistory(_currentUserId!);
    }
  }

  // Custom Command Management
  Future<void> addCustomCommand({
    required String commandText,
    required String deviceId,
    required String action,
    required String zone,
    String? description,
    List<String>? aliases,
  }) async {
    if (_currentUserId == null) return;

    try {
      final success = await _firebaseData.saveCustomCommand(
        userId: _currentUserId!,
        commandText: commandText,
        deviceId: deviceId,
        action: action,
        zone: zone,
        description: description,
        aliases: aliases,
      );

      if (success) {
        // Reload custom commands
        _customCommands = await _firebaseData.getCustomCommands(
          userId: _currentUserId!,
        );
        notifyListeners();
      }
    } catch (e) {
      print('Error adding custom command: $e');
    }
  }

  Future<void> updateCustomCommand({
    required String commandId,
    String? commandText,
    String? deviceId,
    String? action,
    String? zone,
    String? description,
    List<String>? aliases,
    bool? isActive,
  }) async {
    if (_currentUserId == null) return;

    try {
      final success = await _firebaseData.updateCustomCommand(
        commandId: commandId,
        commandText: commandText,
        deviceId: deviceId,
        action: action,
        zone: zone,
        description: description,
        aliases: aliases,
        isActive: isActive,
      );

      if (success) {
        // Reload custom commands
        _customCommands = await _firebaseData.getCustomCommands(
          userId: _currentUserId!,
        );
        notifyListeners();
      }
    } catch (e) {
      print('Error updating custom command: $e');
    }
  }

  Future<void> deleteCustomCommand(String commandId) async {
    if (_currentUserId == null) return;

    try {
      final success = await _firebaseData.deleteCustomCommand(commandId);

      if (success) {
        // Reload custom commands
        _customCommands = await _firebaseData.getCustomCommands(
          userId: _currentUserId!,
        );
        notifyListeners();
      }
    } catch (e) {
      print('Error deleting custom command: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getCustomCommandsByZone(
      String zone) async {
    if (_currentUserId == null) return [];

    try {
      return await _firebaseData.getCustomCommands(
        userId: _currentUserId!,
        zone: zone,
      );
    } catch (e) {
      print('Error getting custom commands by zone: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> searchCustomCommands(
      String searchText) async {
    if (_currentUserId == null) return [];

    try {
      return await _firebaseData.searchCustomCommands(
        userId: _currentUserId!,
        searchText: searchText,
      );
    } catch (e) {
      print('Error searching custom commands: $e');
      return [];
    }
  }

  @override
  void dispose() {
    // Remove observer to prevent memory leaks
    WidgetsBinding.instance.removeObserver(this);

    // Cleanup text controller
    _chatController.dispose();
    
    // Stop speech recognition if active
    if (_isListening) {
      _speechToText.cancel();
    }
    
    // Cleanup TTS
    _flutterTts.stop();
    
    print('🧹 AI Voice: Disposed resources and cleaned up');
    
    super.dispose();
  }

  void _showTestSpeechDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Test nhận diện giọng nói'),
        content: const Text(
            'Nhận diện giọng nói đã được kích hoạt. Bạn có thể thử nói "Mở đèn phòng khách" hoặc "Tắt quạt phòng ngủ".'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Đóng'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              toggleListening();
            },
            child: const Text('Thử ngay'),
          ),
        ],
      ),
    );
  }

  void _showSettingsDialog() {
    BuildContext? context = getActiveContext();
    if (context != null) {
      showDialog(
        context: context,
        builder: (BuildContext dialogContext) => AlertDialog(
          title: const Text('Cần cấp quyền Microphone'),
          content: const Text(
            'Quyền microphone đã bị từ chối vĩnh viễn. Để sử dụng chức năng nhận diện giọng nói, '
            'bạn cần vào Cài đặt > Quyền riêng tư & Bảo mật > Microphone và bật quyền cho ứng dụng KhoaSmart.\n\n'
            'Sau khi cấp quyền, vui lòng quay lại ứng dụng.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Để sau'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                try {
                  await openAppSettings();
                } catch (e) {
                  print('Error opening app settings: $e');
                }
              },
              child: const Text('Mở Cài đặt'),
            ),
          ],
        ),
      );
    } else {
      print('No context available to show settings dialog');
    }
  }

  // Get context from NavigationService instead of static GlobalKey
  BuildContext? getActiveContext() {
    return getIt<NavigationService>().navigatorKey.currentContext;
  }

  // Manual permission request that can be called from UI
  Future<bool> requestMicrophonePermission() async {
    try {
      print('=== Manual Microphone Permission Request ===');

      // Check current status first
      final currentStatus = await Permission.microphone.status;
      print('Current microphone permission status: $currentStatus');

      if (currentStatus.isGranted) {
        print('Permission already granted, reinitializing speech...');
        await _initSpeech();
        return _speechEnabled;
      }

      if (currentStatus.isPermanentlyDenied) {
        print('Permission permanently denied, need to go to settings');
        _showSettingsDialog();
        return false;
      }

      print('Requesting microphone permission...');
      final permission = await Permission.microphone.request();
      print('Permission request result: $permission');

      if (permission.isGranted) {
        print('Permission granted! Reinitializing speech...');
        // Add small delay to ensure permission is fully processed
        await Future.delayed(const Duration(milliseconds: 500));
        await _initSpeech();
        print('Speech enabled after manual request: $_speechEnabled');

        // Force UI update
        notifyListeners();
        return _speechEnabled;
      } else if (permission.isPermanentlyDenied) {
        print('Permission permanently denied after request');
        _showSettingsDialog();
        return false;
      } else {
        print('Permission denied but not permanently');
        return false;
      }
    } catch (e) {
      print('Error requesting microphone permission: $e');
      return false;
    }
  }

  // Force re-initialize speech (useful after permission granted)
  Future<void> forceInitializeSpeech() async {
    await _initSpeech();
  }
}
