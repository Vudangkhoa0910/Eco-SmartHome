import 'package:flutter/material.dart';
import 'package:smart_home/provider/base_model.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:smart_home/service/firebase_data_service.dart';
import 'package:smart_home/service/mqtt_service.dart';
import 'package:smart_home/provider/getit.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AIVoiceViewModel extends BaseModel {
  bool _isListening = false;
  bool _isProcessing = false;
  bool _showChatBox = false;
  String _recognizedText = '';
  String _aiResponse = '';
  List<String> _commandHistory = [];
  List<Map<String, dynamic>> _chatMessages = [];
  List<Map<String, dynamic>> _customCommands = [];
  
  // Firebase services
  final FirebaseDataService _firebaseData = getIt<FirebaseDataService>();
  final MqttService _mqttService = getIt<MqttService>();
  
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

  // Mapping các lệnh tiếng Việt với thiết bị
  final Map<String, Map<String, dynamic>> _deviceCommands = {
    // Đèn
    'đèn cổng': {'type': 'light', 'location': 'gate', 'device': 'Đèn cổng'},
    'đèn phòng khách': {'type': 'light', 'location': 'living_room', 'device': 'Đèn phòng khách'},
    'đèn phòng ngủ': {'type': 'light', 'location': 'bedroom', 'device': 'Đèn phòng ngủ'},
    'đèn bếp': {'type': 'light', 'location': 'kitchen', 'device': 'Đèn bếp'},
    'đèn phòng tắm': {'type': 'light', 'location': 'bathroom', 'device': 'Đèn phòng tắm'},
    'đèn sân': {'type': 'light', 'location': 'yard', 'device': 'Đèn sân'},
    'tất cả đèn': {'type': 'light', 'location': 'all', 'device': 'Tất cả đèn'},
    
    // Quạt
    'quạt phòng khách': {'type': 'fan', 'location': 'living_room', 'device': 'Quạt phòng khách'},
    'quạt phòng ngủ': {'type': 'fan', 'location': 'bedroom', 'device': 'Quạt phòng ngủ'},
    'quạt trần': {'type': 'fan', 'location': 'ceiling', 'device': 'Quạt trần'},
    
    // Điều hòa
    'điều hòa': {'type': 'ac', 'location': 'main', 'device': 'Điều hòa'},
    'máy lạnh': {'type': 'ac', 'location': 'main', 'device': 'Máy lạnh'},
    'điều hòa phòng khách': {'type': 'ac', 'location': 'living_room', 'device': 'Điều hòa phòng khách'},
    'điều hòa phòng ngủ': {'type': 'ac', 'location': 'bedroom', 'device': 'Điều hòa phòng ngủ'},
    
    // TV & Giải trí
    'tivi': {'type': 'tv', 'location': 'main', 'device': 'TV'},
    'tv': {'type': 'tv', 'location': 'main', 'device': 'TV'},
    'loa': {'type': 'speaker', 'location': 'main', 'device': 'Loa'},
    
    // Khác
    'camera': {'type': 'camera', 'location': 'security', 'device': 'Camera an ninh'},
    'cửa': {'type': 'door', 'location': 'main', 'device': 'Cửa chính'},
    'cổng': {'type': 'gate', 'location': 'entrance', 'device': 'Cổng'},
  };

  // Các từ khóa hành động
  final List<String> _onKeywords = ['mở', 'bật', 'khởi động', 'sáng'];
  final List<String> _offKeywords = ['tắt', 'đóng', 'ngắt', 'tối'];
  final List<String> _adjustKeywords = ['chỉnh', 'điều chỉnh', 'đặt', 'tăng', 'giảm'];

  bool get isListening => _isListening;
  bool get isProcessing => _isProcessing;
  bool get showChatBox => _showChatBox;
  String get recognizedText => _recognizedText;
  String get aiResponse => _aiResponse;
  List<String> get commandHistory => _commandHistory;
  List<Map<String, dynamic>> get chatMessages => _chatMessages;
  List<Map<String, dynamic>> get customCommands => _customCommands;
  Map<String, dynamic> get availableZonesAndDevices => _availableZonesAndDevices;
  TextEditingController get chatController => _chatController;
  bool get speechEnabled => _speechEnabled;

  void initialize() async {
    // Get current user
    _currentUserId = FirebaseAuth.instance.currentUser?.uid;
    
    // Initialize speech recognition
    await _initializeSpeech();
    
    // Initialize TTS
    await _initializeTts();
    
    // Load user data
    await _loadUserData();
    
    print('AI Voice Assistant initialized - Speech enabled: $_speechEnabled');
  }
  
  Future<void> _loadUserData() async {
    if (_currentUserId == null) return;
    
    try {
      // Load chat history
      final chatHistory = await _firebaseData.getChatHistory(
        userId: _currentUserId!,
        limit: 50,
      );
      
      _chatMessages = chatHistory.map((msg) => {
        'message': msg['message'],
        'isUser': msg['is_user'],
        'timestamp': (msg['timestamp'] as Timestamp).toDate(),
        'response': msg['response'],
      }).toList();
      
      // Load custom commands
      _customCommands = await _firebaseData.getCustomCommands(
        userId: _currentUserId!,
      );
      
      // Load available zones and devices
      _availableZonesAndDevices = await _firebaseData.getAvailableZonesAndDevices();
      
      notifyListeners();
    } catch (e) {
      print('Error loading user data: $e');
    }
  }
  
  Future<void> _initializeSpeech() async {
    try {
      // Request microphone permission
      var status = await Permission.microphone.request();
      if (status != PermissionStatus.granted) {
        print('Microphone permission denied');
        return;
      }
      
      _speechEnabled = await _speechToText.initialize(
        onStatus: (status) {
          print('Speech recognition status: $status');
          if (status == 'done' || status == 'notListening') {
            _isListening = false;
            notifyListeners();
          }
        },
        onError: (error) {
          print('Speech recognition error: $error');
          _isListening = false;
          notifyListeners();
        },
      );
      
      print('Speech recognition initialized: $_speechEnabled');
    } catch (e) {
      print('Failed to initialize speech recognition: $e');
      _speechEnabled = false;
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

  void startListening() async {
    if (!_speechEnabled) {
      print('Speech recognition not enabled');
      return;
    }
    
    _isListening = true;
    _recognizedText = '';
    _aiResponse = '';
    notifyListeners();
    
    try {
      await _speechToText.listen(
        onResult: (result) {
          _recognizedText = result.recognizedWords;
          notifyListeners();
          
          // Nếu người dùng dừng nói, xử lý lệnh
          if (result.finalResult) {
            _processCommand(_recognizedText);
          }
        },
        listenFor: const Duration(seconds: 10),
        pauseFor: const Duration(seconds: 3),
        cancelOnError: true,
        partialResults: true,
        localeId: 'vi_VN',
      );
    } catch (e) {
      print('Error starting speech recognition: $e');
      _isListening = false;
      notifyListeners();
    }
  }

  void stopListening() async {
    if (_speechToText.isListening) {
      await _speechToText.stop();
    }
    _isListening = false;
    notifyListeners();
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
      _aiResponse = _processVietnameseCommand(command);
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
      switch (deviceId) {
        case 'led_gate':
          _mqttService.controlLedGate(action.toLowerCase() == 'on');
          break;
        case 'led_around':
          _mqttService.controlLedAround(action.toLowerCase() == 'on');
          break;
        case 'motor':
          _mqttService.controlMotor(action.toUpperCase());
          break;
        default:
          print('Unknown device: $deviceId');
      }
    } catch (e) {
      print('Error executing device command: $e');
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
      _aiResponse = _processVietnameseCommand(command);
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
    
    // Phân tích lệnh
    String action = '';
    String device = '';
    String? temperature;
    
    // Xác định hành động
    for (String keyword in _onKeywords) {
      if (lowerCommand.contains(keyword)) {
        action = 'on';
        break;
      }
    }
    
    if (action.isEmpty) {
      for (String keyword in _offKeywords) {
        if (lowerCommand.contains(keyword)) {
          action = 'off';
          break;
        }
      }
    }
    
    if (action.isEmpty) {
      for (String keyword in _adjustKeywords) {
        if (lowerCommand.contains(keyword)) {
          action = 'adjust';
          break;
        }
      }
    }
    
    // Xác định thiết bị
    for (String deviceKey in _deviceCommands.keys) {
      if (lowerCommand.contains(deviceKey)) {
        device = deviceKey;
        break;
      }
    }
    
    // Xác định nhiệt độ nếu có
    final tempRegex = RegExp(r'(\d+)\s*độ');
    final tempMatch = tempRegex.firstMatch(lowerCommand);
    if (tempMatch != null) {
      temperature = tempMatch.group(1);
      action = 'adjust';
    }
    
    // Xử lý lệnh đặc biệt
    if (lowerCommand.contains('chế độ đi ngủ') || lowerCommand.contains('good night')) {
      return _handleNightMode();
    }
    
    if (lowerCommand.contains('chế độ ra về') || lowerCommand.contains('về nhà')) {
      return _handleHomeMode();
    }
    
    if (lowerCommand.contains('chế độ tiết kiệm') || lowerCommand.contains('tiết kiệm năng lượng')) {
      return _handleEcoMode();
    }
    
    // Xử lý lệnh thông thường
    if (device.isNotEmpty && _deviceCommands.containsKey(device)) {
      final deviceInfo = _deviceCommands[device]!;
      final deviceName = deviceInfo['device'];
      
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
                            const Icon(Icons.history, color: Colors.white54, size: 16),
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
                              icon: const Icon(Icons.replay, color: Colors.blue, size: 16),
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
                                    style: const TextStyle(color: Colors.white70),
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
                        Icon(Icons.voice_over_off, size: 48, color: Colors.white24),
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
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
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
                                    executeQuickCommand(command['command_text'] ?? '');
                                  },
                                  icon: const Icon(Icons.play_arrow, color: Colors.green, size: 16),
                                ),
                              ],
                            ),
                            if (command['description'] != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  command['description'],
                                  style: const TextStyle(color: Colors.white54, fontSize: 12),
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
                  title: const Text('Độ nhạy micro', style: TextStyle(color: Colors.white)),
                  trailing: const Text('Cao', style: TextStyle(color: Colors.blue)),
                  onTap: () {},
                ),
                const Divider(color: Colors.white24),
                ListTile(
                  leading: const Icon(Icons.language, color: Colors.white70),
                  title: const Text('Ngôn ngữ', style: TextStyle(color: Colors.white)),
                  trailing: const Text('Tiếng Việt', style: TextStyle(color: Colors.blue)),
                  onTap: () {},
                ),
                const Divider(color: Colors.white24),
                ListTile(
                  leading: const Icon(Icons.volume_up, color: Colors.white70),
                  title: const Text('Âm lượng phản hồi', style: TextStyle(color: Colors.white)),
                  trailing: const Text('Trung bình', style: TextStyle(color: Colors.blue)),
                  onTap: () {},
                ),
                const Divider(color: Colors.white24),
                ListTile(
                  leading: Icon(
                    _speechEnabled ? Icons.mic : Icons.mic_off,
                    color: _speechEnabled ? Colors.green : Colors.red,
                  ),
                  title: const Text('Trạng thái nhận diện giọng nói', style: TextStyle(color: Colors.white)),
                  trailing: Text(
                    _speechEnabled ? 'Hoạt động' : 'Không khả dụng',
                    style: TextStyle(color: _speechEnabled ? Colors.green : Colors.red),
                  ),
                  onTap: () {},
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

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
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
      response = _processVietnameseCommand(message);
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

  Future<void> _saveChatMessage(String message, String? response, {required bool isUser}) async {
    if (_currentUserId == null) return;
    
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

  Future<List<Map<String, dynamic>>> getCustomCommandsByZone(String zone) async {
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

  Future<List<Map<String, dynamic>>> searchCustomCommands(String searchText) async {
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
    _chatController.dispose();
    _speechToText.cancel();
    _flutterTts.stop();
    super.dispose();
  }
}
