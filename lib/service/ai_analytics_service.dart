import 'dart:convert';
import 'package:smart_home/service/gemini_service.dart';
import 'package:smart_home/service/firebase_data_service.dart';

class AIAnalyticsService {
  static final FirebaseDataService _firebaseService = FirebaseDataService();

  /// Clean AI response from special characters and format nicely
  static String _cleanAIResponse(String response) {
    return response
        .replaceAll(RegExp(r'[*#@>]'), '') // Remove *, #, @, >
        .replaceAll(RegExp(r'--+'), '') // Remove multiple dashes
        .replaceAll(RegExp(r'__+'), '') // Remove multiple underscores  
        .replaceAll(RegExp(r'==+'), '') // Remove multiple equals
        .replaceAll(RegExp(r'\n\s*\n\s*\n'), '\n\n') // Max 2 line breaks
        .replaceAll(RegExp(r'[ \t]+'), ' ') // Clean extra spaces
        .trim();
  }

  /// Phân tích dữ liệu năng lượng và đưa ra insights thông minh
  static Future<Map<String, dynamic>> generateEnergyInsights({
    required double currentPower,
    required double dailyConsumption,
    required double monthlyConsumption,
    required double monthlyCost,
    required List<Map<String, dynamic>> deviceUsage,
    required List<Map<String, dynamic>> dailyUsage,
  }) async {
    try {
      // Tạo context dữ liệu cho AI
      final String dataContext = _buildEnergyDataContext(
        currentPower: currentPower,
        dailyConsumption: dailyConsumption,
        monthlyConsumption: monthlyConsumption,
        monthlyCost: monthlyCost,
        deviceUsage: deviceUsage,
        dailyUsage: dailyUsage,
      );

      // Prompt chuyên dụng cho phân tích năng lượng
      final String prompt = '''
Bạn là chuyên gia phân tích năng lượng thông minh cho hệ thống nhà thông minh. 
Hãy phân tích dữ liệu sau và đưa ra báo cáo JSON chi tiết:

DỮLIỆU NĂNG LƯỢNG:
$dataContext

Hãy phân tích và trả về JSON với cấu trúc sau:
{
  "summary": {
    "status": "tốt|bình thường|cần chú ý|cảnh báo",
    "score": 0-100,
    "message": "Tóm tắt ngắn gọn tình hình tiêu thụ"
  },
  "insights": [
    {
      "type": "tiết_kiệm|cảnh_báo|tối_ưu|thông_tin",
      "title": "Tiêu đề insight",
      "description": "Mô tả chi tiết",
      "priority": "cao|trung_bình|thấp"
    }
  ],
  "recommendations": [
    {
      "action": "Hành động cụ thể",
      "reason": "Lý do",
      "savings": "Ước tính tiết kiệm (VND/tháng)",
      "difficulty": "dễ|trung_bình|khó"
    }
  ],
  "predictions": {
    "monthly_cost_trend": "tăng|giảm|ổn_định",
    "estimated_monthly_bill": "Ước tính hóa đơn tháng này",
    "potential_savings": "Tiềm năng tiết kiệm hàng tháng"
  },
  "device_optimization": [
    {
      "device": "Tên thiết bị",
      "current_usage": "Mức tiêu thụ hiện tại",
      "optimization": "Gợi ý tối ưu",
      "impact": "Mức độ tác động"
    }
  ]
}

QUAN TRỌNG: 
- Viết báo cáo ngắn gọn, MỖI PHẦN TỐI ĐA 5-7 DÒNG
- KHÔNG sử dụng ký hiệu đặc biệt (*, #, @, >, --, __, ==)
- CHỈ sử dụng dấu đầu dòng • cho danh sách
- Sử dụng tiếng Việt tự nhiên, thân thiện
- Ưu tiên tính thực tế và khả thi
''';

      final response = await GeminiService.generateResponse(prompt);
      
      // Parse JSON response
      return _parseAIResponse(response);
    } catch (e) {
      print('❌ AI Analytics Error: $e');
      return _getDefaultInsights();
    }
  }

  /// Tạo context dữ liệu năng lượng cho AI
  static String _buildEnergyDataContext({
    required double currentPower,
    required double dailyConsumption,
    required double monthlyConsumption,
    required double monthlyCost,
    required List<Map<String, dynamic>> deviceUsage,
    required List<Map<String, dynamic>> dailyUsage,
  }) {
    final buffer = StringBuffer();
    
    buffer.writeln('TIÊU THỤ HIỆN TẠI:');
    buffer.writeln('- Công suất: ${currentPower.toStringAsFixed(1)}W');
    buffer.writeln('- Hôm nay: ${dailyConsumption.toStringAsFixed(2)} kWh');
    buffer.writeln('- Tháng này: ${monthlyConsumption.toStringAsFixed(2)} kWh');
    buffer.writeln('- Chi phí tháng: ${monthlyCost.toStringAsFixed(0)} VND');
    buffer.writeln();
    
    buffer.writeln('THIẾT BỊ TIÊU THỤ:');
    for (final device in deviceUsage) {
      buffer.writeln('- ${device['device']}: ${device['value']}%');
    }
    buffer.writeln();
    
    buffer.writeln('TIÊU THỤ THEO NGÀY (7 ngày gần nhất):');
    for (final day in dailyUsage.take(7)) {
      buffer.writeln('- ${day['day']}: ${day['usage']} kWh');
    }
    
    return buffer.toString();
  }

  /// Parse AI response và validate JSON
  static Map<String, dynamic> _parseAIResponse(String response) {
    try {
      // Tìm JSON trong response
      final jsonStart = response.indexOf('{');
      final jsonEnd = response.lastIndexOf('}');
      
      if (jsonStart != -1 && jsonEnd != -1 && jsonEnd > jsonStart) {
        final jsonString = response.substring(jsonStart, jsonEnd + 1);
        final parsed = jsonDecode(jsonString);
        
        // Validate structure
        if (parsed is Map<String, dynamic> &&
            parsed.containsKey('summary') &&
            parsed.containsKey('insights') &&
            parsed.containsKey('recommendations')) {
          return parsed;
        }
      }
      
      // Fallback to default if parsing fails
      print('⚠️ AI response parsing failed, using default insights');
      return _getDefaultInsights();
    } catch (e) {
      print('❌ JSON parsing error: $e');
      return _getDefaultInsights();
    }
  }

  /// Default insights khi AI không khả dụng
  static Map<String, dynamic> _getDefaultInsights() {
    return {
      'summary': {
        'status': 'bình thường',
        'score': 75,
        'message': 'Hệ thống hoạt động ổn định'
      },
      'insights': [
        {
          'type': 'thông_tin',
          'title': 'Hệ thống đang hoạt động',
          'description': 'Các thiết bị trong nhà đang vận hành bình thường',
          'priority': 'thấp'
        }
      ],
      'recommendations': [
        {
          'action': 'Theo dõi tiêu thụ năng lượng thường xuyên',
          'reason': 'Giúp phát hiện sớm các thiết bị tiêu thụ bất thường',
          'savings': '50,000 VND/tháng',
          'difficulty': 'dễ'
        }
      ],
      'predictions': {
        'monthly_cost_trend': 'ổn_định',
        'estimated_monthly_bill': 'Đang tính toán...',
        'potential_savings': '100,000 VND/tháng'
      },
      'device_optimization': [
        {
          'device': 'Điều hòa',
          'current_usage': 'Bình thường',
          'optimization': 'Điều chỉnh nhiệt độ 26°C',
          'impact': 'Tiết kiệm 15-20%'
        }
      ]
    };
  }

  /// Tạo báo cáo tối ưu hóa năng lượng chi tiết
  static Future<String> generateOptimizationReport({
    required Map<String, dynamic> deviceStats,
    required double monthlyConsumption,
    required double monthlyCost,
  }) async {
    try {
      final prompt = '''
Bạn là chuyên gia tối ưu hóa năng lượng. Hãy tạo báo cáo chi tiết về cách tối ưu hóa hệ thống nhà thông minh:

THÔNG TIN THIẾT BỊ:
${_buildDeviceStatsContext(deviceStats)}

TIÊU THỤ THÁNG: ${monthlyConsumption.toStringAsFixed(2)} kWh
CHI PHÍ THÁNG: ${monthlyCost.toStringAsFixed(0)} VND

Hãy tạo báo cáo tối ưu hóa ngắn gọn:

QUAN TRỌNG: 
- Viết báo cáo đơn giản, KHÔNG sử dụng emoji, ký hiệu đặc biệt (*, #, @, -, >)
- CHỈ sử dụng dấu đầu dòng • và ngôn ngữ tiếng Việt tự nhiên
- Đưa ra gợi ý cụ thể, ngắn gọn, dễ hiểu
- Tối đa 5-7 dòng cho mỗi phần
- Ưu tiên tính thực tế và dễ thực hiện
''';

      final response = await GeminiService.generateResponse(prompt);
      return _cleanAIResponse(response);
    } catch (e) {
      print('❌ Optimization Report Error: $e');
      return _getDefaultOptimizationReport();
    }
  }



  /// Xây dựng context thống kê thiết bị
  static String _buildDeviceStatsContext(Map<String, dynamic> deviceStats) {
    final buffer = StringBuffer();
    
    deviceStats.forEach((device, stats) {
      buffer.writeln('$device:');
      buffer.writeln('  - Thời gian bật: ${stats['onTime'] ?? 0} phút');
      buffer.writeln('  - Số lần bật/tắt: ${stats['toggleCount'] ?? 0}');
      buffer.writeln('  - Mức tiêu thụ: ${stats['consumption'] ?? 0} W');
      buffer.writeln();
    });
    
    return buffer.toString();
  }

  /// Báo cáo tối ưu mặc định
  static String _getDefaultOptimizationReport() {
    return '''
BÁO CÁO TỐI ƯU HÓA NĂNG LƯỢNG

HIỆN TRẠNG:
Hệ thống hoạt động ổn định, tiêu thụ trong ngưỡng bình thường.

CẢI THIỆN:
• Điều chỉnh nhiệt độ điều hòa 26°C để tiết kiệm điện
• Tắt đèn không cần thiết khi ra khỏi phòng
• Sử dụng timer tự động cho các thiết bị

KẾ HOẠCH:
• Tuần 1: Điều chỉnh nhiệt độ và thói quen sử dụng đèn
• Tuần 2: Cài đặt timer cho quạt và đèn LED
• Tuần 3: Theo dõi và tối ưu giờ cao điểm

TIẾT KIỆM DỰ KIẾN:
• Ngay: 50,000 - 80,000 VND/tháng
• Sau 1 tháng: 100,000 - 150,000 VND/tháng

ƯU TIÊN:
1. Điều chỉnh nhiệt độ điều hòa (dễ làm, hiệu quả cao)
2. Timer thiết bị (trung bình, tiết kiệm tốt)
3. Thay đổi thói quen sử dụng (dễ làm, lâu dài)
''';
  }

  /// Phân tích xu hướng tiêu thụ và dự đoán
  static Future<Map<String, dynamic>> analyzeTrends({
    required List<Map<String, dynamic>> dailyUsage,
    required double currentMonthConsumption,
  }) async {
    try {
      final trendsData = _buildTrendsContext(dailyUsage, currentMonthConsumption);
      
      final prompt = '''
Bạn là chuyên gia phân tích dữ liệu năng lượng. Hãy phân tích xu hướng và đưa ra dự đoán:

$trendsData

Trả về JSON với cấu trúc:
{
  "trend_analysis": {
    "direction": "tăng|giảm|ổn_định",
    "percentage_change": "phần trăm thay đổi so với trung bình",
    "peak_days": ["các ngày tiêu thụ cao"],
    "low_days": ["các ngày tiêu thụ thấp"]
  },
  "predictions": {
    "next_week": "dự đoán tuần tới",
    "monthly_forecast": "dự báo cuối tháng",
    "cost_estimate": "ước tính chi phí"
  },
  "patterns": [
    {
      "pattern": "mô tả pattern",
      "frequency": "tần suất",
      "impact": "tác động"
    }
  ]
}
''';

      final response = await GeminiService.generateResponse(prompt);
      return _parseAIResponse(response);
    } catch (e) {
      print('❌ Trends Analysis Error: $e');
      return _getDefaultTrends();
    }
  }

  static String _buildTrendsContext(List<Map<String, dynamic>> dailyUsage, double currentMonth) {
    final buffer = StringBuffer();
    buffer.writeln('DỮ LIỆU TIÊU THỤ HÀNG NGÀY:');
    
    for (final day in dailyUsage) {
      buffer.writeln('${day['day']}: ${day['usage']} kWh');
    }
    
    buffer.writeln('\nTIÊU THỤ THÁNG HIỆN TẠI: ${currentMonth.toStringAsFixed(2)} kWh');
    
    return buffer.toString();
  }

  static Map<String, dynamic> _getDefaultTrends() {
    return {
      'trend_analysis': {
        'direction': 'ổn_định',
        'percentage_change': '0%',
        'peak_days': ['Thứ 7', 'Chủ nhật'],
        'low_days': ['Thứ 2', 'Thứ 3']
      },
      'predictions': {
        'next_week': 'Ổn định như tuần trước',
        'monthly_forecast': 'Dự kiến trong ngưỡng bình thường',
        'cost_estimate': 'Khoảng 500,000 VND'
      },
      'patterns': [
        {
          'pattern': 'Tiêu thụ cao vào cuối tuần',
          'frequency': 'Hàng tuần',
          'impact': 'Trung bình'
        }
      ]
    };
  }
}
