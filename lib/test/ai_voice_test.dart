import 'package:smart_home/service/gemini_service.dart';

/// Test examples for the enhanced AI voice functionality
/// 
/// This demonstrates how the AI voice assistant now works:
/// 1. Smart home commands are processed locally
/// 2. General questions are forwarded to Gemini AI
/// 3. The system intelligently determines which type of query it is

void main() async {
  print('=== SMART HOME AI VOICE ASSISTANT TEST ===\n');

  // Test smart home command detection
  print('1. Testing Smart Home Command Detection:');
  List<String> smartHomeCommands = [
    'bật đèn phòng khách',
    'tắt quạt phòng ngủ',
    'tăng nhiệt độ điều hòa',
    'mở cửa chính',
    'đóng tất cả đèn'
  ];

  for (String command in smartHomeCommands) {
    bool isSmartHome = GeminiService.isSmartHomeCommand(command);
    print('   "$command" -> ${isSmartHome ? "Smart Home Command" : "General Question"}');
  }

  print('\n2. Testing General Questions:');
  List<String> generalQuestions = [
    'Thời tiết hôm nay thế nào?',
    'Hôm nay là thứ mấy?',
    'Kể cho tôi một câu chuyện vui',
    'Làm thế nào để nấu phở?',
    'AI là gì?'
  ];

  for (String question in generalQuestions) {
    bool isSmartHome = GeminiService.isSmartHomeCommand(question);
    print('   "$question" -> ${isSmartHome ? "Smart Home Command" : "General Question"}');
  }

  print('\n3. Testing Mixed Commands:');
  List<String> mixedCommands = [
    'bật đèn và cho tôi biết thời tiết',
    'tắt quạt, hôm nay là ngày gì?',
    'nhiệt độ phòng bao nhiêu độ?'
  ];

  for (String command in mixedCommands) {
    bool isSmartHome = GeminiService.isSmartHomeCommand(command);
    print('   "$command" -> ${isSmartHome ? "Smart Home Command" : "General Question"}');
  }

  print('\n4. Testing Gemini AI Response (requires internet):');
  try {
    String response = await GeminiService.generateResponse(
      GeminiService.enhanceQuestion('AI là gì?')
    );
    print('   Question: "AI là gì?"');
    print('   Gemini Response: "${response.substring(0, response.length > 100 ? 100 : response.length)}..."');
  } catch (e) {
    print('   Error testing Gemini: $e');
  }

  print('\n=== TEST COMPLETED ===');
}

/// How to use the enhanced AI voice assistant:
/// 
/// VOICE COMMANDS:
/// - "Bật đèn phòng khách" -> Controls smart home device
/// - "Thời tiết hôm nay thế nào?" -> Forwards to Gemini AI
/// - "Tắt tất cả đèn" -> Controls multiple smart home devices
/// - "Kể cho tôi một câu chuyện" -> Forwards to Gemini AI
/// 
/// CHAT INPUT:
/// - Type any smart home command -> Local processing
/// - Type any general question -> Gemini AI processing
/// - Mixed commands -> Intelligently routed
/// 
/// FEATURES:
/// - Voice recognition for both command types
/// - Text-to-speech for all responses
/// - Chat history saved to Firebase
/// - Intelligent command classification
/// - Fallback to Gemini for unknown commands
