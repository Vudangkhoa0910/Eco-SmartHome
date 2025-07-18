import 'dart:convert';
import 'package:http/http.dart' as http;

class GeminiService {
  static const String _baseUrl = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent';
  static const String _apiKey = 'api;

  static Future<String> generateResponse(String question) async {
    try {
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'X-goog-api-key': _apiKey,
        },
        body: jsonEncode({
          'contents': [
            {
              'parts': [
                {
                  'text': question,
                }
              ]
            }
          ],
          'generationConfig': {
            'temperature': 0.7,
            'topK': 40,
            'topP': 0.95,
            'maxOutputTokens': 1024,
          },
          'safetySettings': [
            {
              'category': 'HARM_CATEGORY_HARASSMENT',
              'threshold': 'BLOCK_MEDIUM_AND_ABOVE'
            },
            {
              'category': 'HARM_CATEGORY_HATE_SPEECH',
              'threshold': 'BLOCK_MEDIUM_AND_ABOVE'
            },
            {
              'category': 'HARM_CATEGORY_SEXUALLY_EXPLICIT',
              'threshold': 'BLOCK_MEDIUM_AND_ABOVE'
            },
            {
              'category': 'HARM_CATEGORY_DANGEROUS_CONTENT',
              'threshold': 'BLOCK_MEDIUM_AND_ABOVE'
            }
          ]
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['candidates'] != null && data['candidates'].isNotEmpty) {
          final content = data['candidates'][0]['content'];
          if (content['parts'] != null && content['parts'].isNotEmpty) {
            return content['parts'][0]['text'] ?? 'Xin lỗi, tôi không thể trả lời câu hỏi này.';
          }
        }
        return 'Xin lỗi, tôi không thể trả lời câu hỏi này.';
      } else {
        print('Gemini API Error: ${response.statusCode} - ${response.body}');
        return 'Xin lỗi, có lỗi xảy ra khi kết nối với AI. Vui lòng thử lại sau.';
      }
    } catch (e) {
      print('Gemini Service Error: $e');
      return 'Xin lỗi, có lỗi xảy ra. Vui lòng kiểm tra kết nối mạng và thử lại.';
    }
  }

  /// Kiểm tra xem câu hỏi có phải là lệnh điều khiển nhà thông minh không
  static bool isSmartHomeCommand(String text) {
    final lowerText = text.toLowerCase();
    
    // Danh sách từ khóa liên quan đến điều khiển nhà thông minh
    final smartHomeKeywords = [
      'bật', 'tắt', 'mở', 'đóng', 'tăng', 'giảm',
      'đèn', 'quạt', 'điều hòa', 'máy lạnh', 'tivi', 'tv', 'loa',
      'camera', 'cửa', 'rèm', 'nhiệt độ', 'độ sáng', 'âm lượng',
      'phòng khách', 'phòng ngủ', 'bếp', 'phòng tắm', 'sân', 'cổng',
      'tất cả', 'toàn bộ', 'hết'
    ];

    return smartHomeKeywords.any((keyword) => lowerText.contains(keyword));
  }

  /// Cải thiện câu hỏi để gửi tới Gemini (thêm context tiếng Việt)
  static String enhanceQuestion(String question) {
    // Thêm context để Gemini hiểu đây là câu hỏi tiếng Việt
    return '''Bạn là một trợ lý AI thông minh, hãy trả lời câu hỏi sau bằng tiếng Việt một cách tự nhiên và hữu ích:

Câu hỏi: $question

Hãy trả lời ngắn gọn, dễ hiểu và phù hợp với văn hóa Việt Nam.''';
  }
}
