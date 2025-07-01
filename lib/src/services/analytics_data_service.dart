import 'package:smart_home/service/influxdb_service.dart';
import 'package:smart_home/provider/getit.dart';

class AnalyticsDataService {
  static final InfluxDBService _influxDB = getIt<InfluxDBService>();
  
  /// Test database connection and data availability
  static Future<Map<String, dynamic>> testDataAvailability() async {
    final Map<String, dynamic> result = {
      'connection': false,
      'powerData': false,
      'deviceStats': false,
      'errors': <String>[],
    };
    
    try {
      // Test connection
      final connectionTest = await _influxDB.testConnection();
      result['connection'] = connectionTest;
      
      if (!connectionTest) {
        result['errors'].add('Không thể kết nối InfluxDB');
        return result;
      }
      
      // Test power data
      try {
        final powerData = await _influxDB.querySensorHistory(
          timeRange: '24h',
          sensorType: 'power',
          aggregation: 'mean',
        );
        result['powerData'] = powerData.isNotEmpty;
        if (powerData.isEmpty) {
          result['errors'].add('Không có dữ liệu tiêu thụ điện');
        }
      } catch (e) {
        result['errors'].add('Lỗi truy vấn dữ liệu điện: $e');
      }
      
      // Test device stats
      try {
        final deviceStats = await _influxDB.getDeviceStats('', timeRange: '24h');
        result['deviceStats'] = deviceStats.isNotEmpty;
        if (deviceStats.isEmpty) {
          result['errors'].add('Không có dữ liệu thống kê thiết bị');
        }
      } catch (e) {
        result['errors'].add('Lỗi truy vấn thiết bị: $e');
      }
      
    } catch (e) {
      result['errors'].add('Lỗi kết nối: $e');
    }
    
    return result;
  }
  
  /// Get sample data for testing
  static Future<Map<String, dynamic>> getSampleData(String timeRange) async {
    try {
      final powerDataFuture = _influxDB.querySensorHistory(
        timeRange: timeRange,
        sensorType: 'power',
        aggregation: 'mean',
      );
      
      final deviceStatsFuture = _influxDB.getDeviceStats('', timeRange: timeRange);
      
      final results = await Future.wait([powerDataFuture, deviceStatsFuture]);
      
      return {
        'powerData': results[0],
        'deviceStats': results[1],
        'success': true,
      };
    } catch (e) {
      return {
        'powerData': [],
        'deviceStats': {},
        'success': false,
        'error': e.toString(),
      };
    }
  }
  
  /// Create realistic mock data for development
  static Map<String, dynamic> createMockDeviceStats() {
    return {
      'led1': {
        'usage_percentage': '65.5',
        'avg_state': 0.655,
        'on_hours': 15.7,
        'switch_count': 23,
      },
      'led2': {
        'usage_percentage': '42.3',
        'avg_state': 0.423,
        'on_hours': 10.2,
        'switch_count': 18,
      },
      'motor': {
        'usage_percentage': '78.1',
        'avg_state': 0.781,
        'on_hours': 18.7,
        'switch_count': 12,
      },
    };
  }
  
  /// Create mock power consumption data
  static List<Map<String, dynamic>> createMockPowerData(String timeRange) {
    final now = DateTime.now();
    final List<Map<String, dynamic>> mockData = [];
    
    int dataPoints;
    Duration interval;
    
    switch (timeRange) {
      case '1h':
        dataPoints = 12;
        interval = const Duration(minutes: 5);
        break;
      case '6h':
        dataPoints = 24;
        interval = const Duration(minutes: 15);
        break;
      case '24h':
        dataPoints = 24;
        interval = const Duration(hours: 1);
        break;
      case '7d':
        dataPoints = 28;
        interval = const Duration(hours: 6);
        break;
      case '30d':
        dataPoints = 30;
        interval = const Duration(days: 1);
        break;
      default:
        dataPoints = 24;
        interval = const Duration(hours: 1);
    }
    
    // Simulate realistic power consumption patterns
    for (int i = dataPoints - 1; i >= 0; i--) {
      final time = now.subtract(interval * i);
      
      // Base consumption with daily patterns
      final hour = time.hour;
      double basePower;
      
      if (hour >= 6 && hour <= 8) {
        basePower = 65.0; // Morning peak
      } else if (hour >= 18 && hour <= 22) {
        basePower = 85.0; // Evening peak
      } else if (hour >= 22 || hour <= 6) {
        basePower = 25.0; // Night time
      } else {
        basePower = 45.0; // Day time
      }
      
      // Add some randomness
      final variation = 15.0;
      final randomFactor = 0.8 + (i % 10) * 0.04; // 0.8 to 1.2
      final finalPower = basePower + (variation * randomFactor);
      
      mockData.add({
        '_time': time.toIso8601String(),
        '_value': finalPower.toStringAsFixed(2),
        '_field': 'power',
        '_measurement': 'power_consumption',
      });
    }
    
    return mockData;
  }
}
