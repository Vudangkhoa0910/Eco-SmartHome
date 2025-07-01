import 'package:flutter/material.dart';
import 'package:smart_home/provider/base_model.dart';

class AIVoiceViewModel extends BaseModel {
  bool _isListening = false;
  bool _isProcessing = false;
  String _recognizedText = '';
  String _aiResponse = '';
  List<String> _commandHistory = [];

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
  String get recognizedText => _recognizedText;
  String get aiResponse => _aiResponse;
  List<String> get commandHistory => _commandHistory;

  void initialize() {
    // Initialize speech recognition and AI services
    print('AI Voice Assistant initialized');
  }

  void toggleListening() {
    if (_isListening) {
      stopListening();
    } else {
      startListening();
    }
  }

  void startListening() {
    _isListening = true;
    _recognizedText = '';
    _aiResponse = '';
    notifyListeners();
    
    // Simulate voice recognition với các mẫu tiếng Việt
    final sampleCommands = [
      'Mở đèn phòng khách',
      'Tắt đèn bếp',
      'Bật quạt phòng ngủ',
      'Đặt điều hòa 25 độ',
      'Tắt tất cả đèn',
      'Mở đèn cổng',
      'Bật tivi',
      'Chế độ đi ngủ',
    ];
    
    Future.delayed(const Duration(seconds: 3), () {
      _isListening = false;
      _isProcessing = true;
      notifyListeners();
      
      // Random select a command for demo
      final randomCommand = sampleCommands[DateTime.now().millisecond % sampleCommands.length];
      
      Future.delayed(const Duration(seconds: 2), () {
        _isProcessing = false;
        _recognizedText = randomCommand;
        _aiResponse = _processVietnameseCommand(randomCommand);
        _commandHistory.insert(0, randomCommand);
        if (_commandHistory.length > 10) {
          _commandHistory.removeAt(10);
        }
        notifyListeners();
      });
    });
  }

  void stopListening() {
    _isListening = false;
    notifyListeners();
  }

  void executeQuickCommand(String command) {
    _recognizedText = command;
    _isProcessing = true;
    notifyListeners();
    
    Future.delayed(const Duration(seconds: 1), () {
      _isProcessing = false;
      _aiResponse = _processVietnameseCommand(command);
      _commandHistory.insert(0, command);
      if (_commandHistory.length > 10) {
        _commandHistory.removeAt(10);
      }
      notifyListeners();
    });
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
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: Color(0xFF2E3440),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Cài đặt giọng nói',
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
              const SizedBox(height: 20),
              
              // Lịch sử lệnh
              const Text(
                'Lịch sử lệnh gần đây:',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 10),
              Expanded(
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
              
              // Cài đặt
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
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper method để xóa lịch sử
  void clearHistory() {
    _commandHistory.clear();
    notifyListeners();
  }
}
