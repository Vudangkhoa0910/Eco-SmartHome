import 'package:http/http.dart' as http;
import 'package:smart_home/service/mqtt_unified_service.dart';

class InfluxDBService {
  static const String _baseUrl = 'https://us-east-1-1.aws.cloud2.influxdata.com';
  static const String _org = '01533c5374ba7af6';
  static const String _bucket = 'smart_home';
  static const String _token = 'f-DU9GteI3gBG_Om5k515q1z83grlzRgIv5ITPVQbq37R8jyitqKPZ12L1BkDasGw8Uf1pni27Ezu4c4kc11jw==';
  
  // Toggle to enable/disable InfluxDB (for testing)
  static const bool _enabled = true;
  
  static final InfluxDBService _instance = InfluxDBService._internal();
  factory InfluxDBService() => _instance;
  InfluxDBService._internal();

  /// Write sensor data to InfluxDB
  Future<bool> writeSensorData(SensorData data) async {
    if (!_enabled) return true;
    
    try {
      final lineProtocolData = _convertToLineProtocol(data);
      
      final response = await http.post(
        Uri.parse('$_baseUrl/api/v2/write?org=$_org&bucket=$_bucket&precision=s'),
        headers: {
          'Authorization': 'Token $_token',
          'Content-Type': 'text/plain; charset=utf-8',
          'Accept': 'application/json',
        },
        body: lineProtocolData,
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 204) {
        print('✅ InfluxDB: Sensor data written successfully');
        
        // Also write power consumption data with cost calculation
        await _writePowerConsumptionData(data);
        
        return true;
      } else {
        print('❌ InfluxDB Write Error: ${response.statusCode} - ${response.body}');
        return false;
      }
    } catch (e) {
      print('❌ InfluxDB Write Exception: $e');
      return false;
    }
  }

  /// Write power consumption data with cost calculation (private helper)
  Future<void> _writePowerConsumptionData(SensorData data) async {
    try {
      // Calculate energy consumption (kWh) - assume this is per hour reading
      final powerKw = data.power / 1000.0; // Convert watts to kW
      final energyKwh = powerKw; // For hourly reading
      
      // Calculate cost using default rate (1.5k VND per kWh)
      final cost = energyKwh * 1500; // 1500 VND per kWh
      
      final timestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      final lineProtocolData = 'power_consumption,location=home '
          'power=${data.power},voltage=${data.voltage},current=${data.current},'
          'energy_kwh=$energyKwh,cost=$cost,electricity_rate=1500 '
          '$timestamp';
      
      // Debug: Print the line protocol to check for duplicates
      print('🔍 Writing line protocol (private): $lineProtocolData');
      
      final response = await http.post(
        Uri.parse('$_baseUrl/api/v2/write?org=$_org&bucket=$_bucket&precision=s'),
        headers: {
          'Authorization': 'Token $_token',
          'Content-Type': 'text/plain; charset=utf-8',
          'Accept': 'application/json',
        },
        body: lineProtocolData,
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 204) {
        print('✅ InfluxDB: Power consumption data written successfully');
      } else {
        print('❌ InfluxDB power consumption write error: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('❌ InfluxDB power consumption write error: $e');
    }
  }

  /// Write device state changes to InfluxDB
  Future<bool> writeDeviceState(String device, String state, {Map<String, dynamic>? metadata}) async {
    if (!_enabled) return true;
    
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      final tags = metadata != null ? 
        metadata.entries.map((e) => '${e.key}=${e.value}').join(',') : '';
      
      final lineProtocol = 'device_state,device=$device${tags.isNotEmpty ? ',$tags' : ''} '
          'state="$state",value=${state == "ON" ? 1 : 0} $timestamp';
      
      final response = await http.post(
        Uri.parse('$_baseUrl/api/v2/write?org=$_org&bucket=$_bucket&precision=s'),
        headers: {
          'Authorization': 'Token $_token',
          'Content-Type': 'text/plain; charset=utf-8',
          'Accept': 'application/json',
        },
        body: lineProtocol,
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 204) {
        print('✅ InfluxDB: Device state written successfully');
        return true;
      } else {
        print('❌ InfluxDB Device State Write Error: ${response.statusCode} - ${response.body}');
        return false;
      }
    } catch (e) {
      print('❌ InfluxDB Device State Write Exception: $e');
      return false;
    }
  }

  /// Write electricity bill calculation
  Future<bool> writeElectricityBill({
    required double totalKwh,
    required double totalCost,
    required Map<String, double> tierBreakdown,
    required DateTime period,
    String location = 'home',
  }) async {
    if (!_enabled) return true;
    
    try {
      final timestamp = period.millisecondsSinceEpoch ~/ 1000;
      
      // Convert tier breakdown to line protocol format
      final tierFields = tierBreakdown.entries
          .map((e) => '${e.key.replaceAll(' ', '_')}=${e.value}')
          .join(',');
      
      final lineProtocolData = 'electricity_bill,location=$location '
          'total_kwh=$totalKwh,total_cost=$totalCost,$tierFields '
          '$timestamp';
      
      final response = await http.post(
        Uri.parse('$_baseUrl/api/v2/write?org=$_org&bucket=$_bucket&precision=s'),
        headers: {
          'Authorization': 'Token $_token',
          'Content-Type': 'text/plain; charset=utf-8',
          'Accept': 'application/json',
        },
        body: lineProtocolData,
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 204) {
        print('✅ InfluxDB: Electricity bill data written successfully');
        return true;
      } else {
        print('❌ InfluxDB electricity bill write error: ${response.statusCode} - ${response.body}');
        return false;
      }
    } catch (e) {
      print('❌ InfluxDB electricity bill write error: $e');
      return false;
    }
  }

  /// Write energy consumption data to InfluxDB
  Future<bool> writeEnergyConsumption(SensorData data) async {
    if (!_enabled) return true;
    
    try {
      // Calculate energy consumption (kWh) - assume this is per minute reading
      final powerKw = data.power / 1000.0; // Convert watts to kW
      final energyKwhPerMinute = powerKw / 60.0; // Convert to kWh per minute
      
      // Calculate cost using electricity rate tiers
      final costPerKwh = _calculateElectricityCost(energyKwhPerMinute);
      
      final timestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      final lineProtocolData = 'energy_consumption,location=home '
          'power=${data.power},voltage=${data.voltage},current=${data.current},'
          'energy_kwh_per_minute=$energyKwhPerMinute,cost_per_minute=$costPerKwh '
          '$timestamp';
      
      final response = await http.post(
        Uri.parse('$_baseUrl/api/v2/write?org=$_org&bucket=$_bucket&precision=s'),
        headers: {
          'Authorization': 'Token $_token',
          'Content-Type': 'text/plain; charset=utf-8',
          'Accept': 'application/json',
        },
        body: lineProtocolData,
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 204) {
        print('✅ InfluxDB: Energy consumption data written successfully');
        return true;
      } else {
        print('❌ InfluxDB Energy Write Error: ${response.statusCode} - ${response.body}');
        return false;
      }
    } catch (e) {
      print('❌ InfluxDB Energy Write Exception: $e');
      return false;
    }
  }

  /// Calculate electricity cost based on Vietnamese tiered pricing
  double _calculateElectricityCost(double kwhUsage) {
    // Vietnamese electricity pricing tiers (VND per kWh)
    const double tier1Rate = 1678.0; // 0-50 kWh
    const double tier2Rate = 1734.0; // 51-100 kWh
    const double tier3Rate = 2014.0; // 101-200 kWh
    const double tier4Rate = 2536.0; // 201-300 kWh
    const double tier5Rate = 2834.0; // 301-400 kWh
    const double tier6Rate = 2927.0; // >400 kWh
    
    // For small usage (per minute), use average rate
    return kwhUsage * tier2Rate; // Use tier 2 rate as average
  }

  /// Convert sensor data to InfluxDB line protocol format
  String _convertToLineProtocol(SensorData data) {
    final timestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    return 'sensor_data,location=home '
        'temperature=${data.temperature},humidity=${data.humidity},'
        'power=${data.power},voltage=${data.voltage},current=${data.current} '
        '$timestamp';
  }

  /// Write power consumption data for a specific device
  Future<bool> writePowerConsumption({
    required String deviceId,
    required double power,
    required double voltage,
    required double current,
    required DateTime timestamp,
    Map<String, dynamic>? metadata,
  }) async {
    if (!_enabled) return true;
    
    try {
      // Calculate energy consumption (kWh) - assume this is per hour reading
      final powerKw = power / 1000.0; // Convert watts to kW
      final energyKwh = powerKw; // For hourly reading
      
      // Calculate cost using default rate (1.5k VND per kWh)
      final cost = energyKwh * 1500; // 1500 VND per kWh
      
      // Process metadata for tags - exclude 'location' to avoid duplicates
      String tags = 'device=$deviceId,location=home';
      if (metadata != null && metadata.isNotEmpty) {
        // Remove any 'location' key from metadata to prevent duplicates
        final cleanMetadata = Map<String, dynamic>.from(metadata);
        cleanMetadata.remove('location'); // Ensure no location key exists
        
        final metadataTags = cleanMetadata.entries
            .where((entry) => entry.value != null)
            .map((entry) {
              // Escape special characters in tag values
              final key = entry.key.toString().replaceAll(',', '\\,').replaceAll(' ', '\\ ').replaceAll('=', '\\=');
              final value = entry.value.toString().replaceAll(',', '\\,').replaceAll(' ', '\\ ').replaceAll('=', '\\=');
              return '$key=$value';
            })
            .join(',');
        if (metadataTags.isNotEmpty) {
          tags = '$tags,$metadataTags';
        }
      }
      
      final unixTimestamp = timestamp.millisecondsSinceEpoch ~/ 1000;
      final lineProtocolData = 'power_consumption,$tags '
          'power=${power},voltage=${voltage},current=${current},'
          'energy_kwh=$energyKwh,cost=$cost,electricity_rate=1500 '
          '$unixTimestamp';
      
      // Debug: Print the line protocol to check for duplicates
      print('🔍 Writing line protocol: $lineProtocolData');
      
      final response = await http.post(
        Uri.parse('$_baseUrl/api/v2/write?org=$_org&bucket=$_bucket&precision=s'),
        headers: {
          'Authorization': 'Token $_token',
          'Content-Type': 'text/plain; charset=utf-8',
          'Accept': 'application/json',
        },
        body: lineProtocolData,
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 204) {
        print('✅ InfluxDB: Power consumption data for $deviceId written successfully');
        return true;
      } else {
        print('❌ InfluxDB power consumption write error: ${response.statusCode} - ${response.body}');
        return false;
      }
    } catch (e) {
      print('❌ InfluxDB power consumption write error: $e');
      return false;
    }
  }

  /// Get power consumption history
  Future<List<Map<String, dynamic>>> getPowerConsumptionHistory({
    required DateTime startTime,
    required DateTime endTime,
    String? location,
  }) async {
    if (!_enabled) return [];
    
    try {
      // Format datetime properly for InfluxDB (RFC3339)
      final startStr = startTime.toUtc().toIso8601String();
      final endStr = endTime.toUtc().toIso8601String();
      
      String query = '''
from(bucket: "$_bucket")
  |> range(start: $startStr, stop: $endStr)
  |> filter(fn: (r) => r._measurement == "power_consumption")
  |> filter(fn: (r) => r._field == "power" or r._field == "voltage" or r._field == "current" or r._field == "energy_kwh" or r._field == "cost")''';
      
      // Add location filter if specified
      if (location != null && location.isNotEmpty) {
        query += '\n  |> filter(fn: (r) => r.location == "$location")';
      }
      
      query += '''

  |> aggregateWindow(every: 1h, fn: mean, createEmpty: false)
  |> sort(columns: ["_time"])''';

      print('🔍 Power consumption query: $query');

      final response = await http.post(
        Uri.parse('$_baseUrl/api/v2/query?org=$_org'),
        headers: {
          'Authorization': 'Token $_token',
          'Content-Type': 'application/vnd.flux',
          'Accept': 'application/csv',
        },
        body: query,
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return _parseCsvResponse(response.body);
      } else {
        print('❌ InfluxDB Query Error: ${response.statusCode} - ${response.body}');
        return [];
      }
    } catch (e) {
      print('❌ InfluxDB Query Exception: $e');
      return [];
    }
  }

  /// Get energy consumption by zone
  Future<Map<String, double>> getEnergyConsumptionByZone({
    required DateTime startTime,
    required DateTime endTime,
  }) async {
    if (!_enabled) return {};
    
    try {
      // Format datetime properly for InfluxDB (RFC3339)
      final startStr = startTime.toUtc().toIso8601String();
      final endStr = endTime.toUtc().toIso8601String();
      
      final query = '''
from(bucket: "$_bucket")
  |> range(start: $startStr, stop: $endStr)
  |> filter(fn: (r) => r._measurement == "device_state")
  |> filter(fn: (r) => r._field == "value")
  |> group(columns: ["zone"])
  |> aggregateWindow(every: 1h, fn: mean, createEmpty: false)
  |> sum()''';

      final response = await http.post(
        Uri.parse('$_baseUrl/api/v2/query?org=$_org'),
        headers: {
          'Authorization': 'Token $_token',
          'Content-Type': 'application/vnd.flux',
          'Accept': 'application/csv',
        },
        body: query,
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = _parseCsvResponse(response.body);
        final Map<String, double> result = {};
        
        for (final row in data) {
          if (row.containsKey('zone') && row.containsKey('_value')) {
            final zone = row['zone']?.toString() ?? 'unknown';
            final value = double.tryParse(row['_value']?.toString() ?? '0') ?? 0.0;
            result[zone] = value;
          }
        }
        
        return result;
      } else {
        print('❌ InfluxDB Zone Query Error: ${response.statusCode} - ${response.body}');
        return {};
      }
    } catch (e) {
      print('❌ InfluxDB Zone Query Exception: $e');
      return {};
    }
  }

  /// Get total energy consumption
  Future<double> getTotalEnergyConsumption({
    required DateTime startTime,
    required DateTime endTime,
    String? location,
  }) async {
    if (!_enabled) return 0.0;
    
    try {
      // Format datetime properly for InfluxDB (RFC3339)
      final startStr = startTime.toUtc().toIso8601String();
      final endStr = endTime.toUtc().toIso8601String();
      
      String query = '''
from(bucket: "$_bucket")
  |> range(start: $startStr, stop: $endStr)
  |> filter(fn: (r) => r._measurement == "power_consumption")
  |> filter(fn: (r) => r._field == "energy_kwh")''';
      
      // Add location filter if specified
      if (location != null && location.isNotEmpty) {
        query += '\n  |> filter(fn: (r) => r.location == "$location")';
      }
      
      query += '\n  |> sum()';

      final response = await http.post(
        Uri.parse('$_baseUrl/api/v2/query?org=$_org'),
        headers: {
          'Authorization': 'Token $_token',
          'Content-Type': 'application/vnd.flux',
          'Accept': 'application/csv',
        },
        body: query,
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = _parseCsvResponse(response.body);
        if (data.isNotEmpty && data.first.containsKey('_value')) {
          return double.tryParse(data.first['_value']?.toString() ?? '0') ?? 0.0;
        }
        return 0.0;
      } else {
        print('❌ InfluxDB Total Energy Query Error: ${response.statusCode} - ${response.body}');
        return 0.0;
      }
    } catch (e) {
      print('❌ InfluxDB Total Energy Query Exception: $e');
      return 0.0;
    }
  }

  /// Get device statistics
  Future<Map<String, dynamic>> getDeviceStats(
    String deviceId, {
    String? timeRange,
    DateTime? startTime,
    DateTime? endTime,
  }) async {
    if (!_enabled) return {};
    
    DateTime effectiveEndTime = endTime ?? DateTime.now();
    DateTime effectiveStartTime;
    
    if (startTime != null) {
      effectiveStartTime = startTime;
    } else if (timeRange != null) {
      effectiveStartTime = _parseTimeRange(timeRange, effectiveEndTime);
    } else {
      effectiveStartTime = effectiveEndTime.subtract(const Duration(days: 7)); // Default to 7 days
    }
    
    try {
      // Format datetime properly for InfluxDB (RFC3339)
      final startStr = effectiveStartTime.toUtc().toIso8601String();
      final endStr = effectiveEndTime.toUtc().toIso8601String();
      
      String query = '''
from(bucket: "$_bucket")
  |> range(start: $startStr, stop: $endStr)
  |> filter(fn: (r) => r._measurement == "device_state")
  |> filter(fn: (r) => r._field == "value")''';
      
      // Add device filter if specified
      if (deviceId.isNotEmpty) {
        query += '\n  |> filter(fn: (r) => r.device == "$deviceId")';
      }
      
      query += '''

  |> group(columns: ["device"])
  |> mean()''';

      print('🔍 Device stats query: $query');

      final response = await http.post(
        Uri.parse('$_baseUrl/api/v2/query?org=$_org'),
        headers: {
          'Authorization': 'Token $_token',
          'Content-Type': 'application/vnd.flux',
          'Accept': 'application/csv',
        },
        body: query,
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = _parseCsvResponse(response.body);
        final Map<String, dynamic> result = {};
        
        for (final row in data) {
          if (row.containsKey('device') && row.containsKey('_value')) {
            final device = row['device']?.toString() ?? 'unknown';
            final value = double.tryParse(row['_value']?.toString() ?? '0') ?? 0.0;
            result[device] = {
              'usage_percentage': (value * 100).toStringAsFixed(1),
              'avg_state': value,
            };
          }
        }
        
        return result;
      } else {
        print('❌ InfluxDB Device Stats Query Error: ${response.statusCode} - ${response.body}');
        return {};
      }
    } catch (e) {
      print('❌ InfluxDB Device Stats Query Exception: $e');
      return {};
    }
  }

  /// Get sensor history data with customizable parameters
  Future<List<Map<String, dynamic>>> querySensorHistory({
    required String sensorType,
    required String timeRange, // e.g., '7d', '24h', '30d'
    String aggregation = 'mean',
    String? location,
  }) async {
    if (!_enabled) return [];
    
    try {
      // Parse timeRange to determine start and end times
      final endTime = DateTime.now();
      final startTime = _parseTimeRange(timeRange, endTime);
      
      final locationFilter = location != null ? ' and r.location == "$location"' : '';
      
      // Determine the measurement and field based on sensorType
      String measurement;
      String field;
      
      switch(sensorType) {
        case 'temperature':
          measurement = 'sensor_data';
          field = 'temperature';
          break;
        case 'humidity':
          measurement = 'sensor_data';
          field = 'humidity';
          break;
        case 'power':
          measurement = 'power_consumption';
          field = 'power';
          break;
        case 'voltage':
          measurement = 'power_consumption';
          field = 'voltage';
          break;
        case 'current':
          measurement = 'power_consumption';
          field = 'current';
          break;
        case 'energy':
          measurement = 'power_consumption';
          field = 'energy_kwh';
          break;
        default:
          throw Exception('Unknown sensor type: $sensorType');
      }
      
      // Calculate appropriate window based on the time range
      final window = _calculateAggregationWindow(startTime, endTime);
      
      // Format datetime properly for InfluxDB (RFC3339)
      final startStr = startTime.toUtc().toIso8601String();
      final endStr = endTime.toUtc().toIso8601String();
      
      String query = '''
from(bucket: "$_bucket")
  |> range(start: $startStr, stop: $endStr)
  |> filter(fn: (r) => r._measurement == "$measurement")
  |> filter(fn: (r) => r._field == "$field")''';
      
      // Add location filter if specified
      if (location != null && location.isNotEmpty) {
        query += '\n  |> filter(fn: (r) => r.location == "$location")';
      }
      
      query += '''

  |> aggregateWindow(every: $window, fn: $aggregation, createEmpty: false)
  |> sort(columns: ["_time"])''';

      print('🔍 Sensor history query: $query');

      final response = await http.post(
        Uri.parse('$_baseUrl/api/v2/query?org=$_org'),
        headers: {
          'Authorization': 'Token $_token',
          'Content-Type': 'application/vnd.flux',
          'Accept': 'application/csv',
        },
        body: query,
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return _parseCsvResponse(response.body);
      } else {
        print('❌ InfluxDB Query Error: ${response.statusCode} - ${response.body}');
        return [];
      }
    } catch (e) {
      print('❌ InfluxDB Query Exception: $e');
      return [];
    }
  }
  
  /// Helper method to parse time range string to DateTime
  DateTime _parseTimeRange(String timeRange, DateTime endTime) {
    final regex = RegExp(r'(\d+)([dhm])');
    final match = regex.firstMatch(timeRange);
    
    if (match != null) {
      final amount = int.parse(match.group(1)!);
      final unit = match.group(2);
      
      switch (unit) {
        case 'd':
          return endTime.subtract(Duration(days: amount));
        case 'h':
          return endTime.subtract(Duration(hours: amount));
        case 'm':
          return endTime.subtract(Duration(minutes: amount));
        default:
          return endTime.subtract(const Duration(days: 7)); // Default to 7 days
      }
    }
    
    return endTime.subtract(const Duration(days: 7)); // Default to 7 days
  }
  
  /// Calculate appropriate aggregation window based on time range
  String _calculateAggregationWindow(DateTime startTime, DateTime endTime) {
    final durationInHours = endTime.difference(startTime).inHours;
    
    if (durationInHours > 2160) { // 90 days (3 months)
      return '1w'; // 1 week window for very long time ranges
    } else if (durationInHours > 720) { // 30 days
      return '1d'; // 1 day window for long time ranges
    } else if (durationInHours > 168) { // 7 days
      return '1d'; // 1 day window for medium time ranges (changed from 6h)
    } else if (durationInHours > 48) { // 2 days
      return '1d'; // 1 day window for shorter time ranges (changed from 1h)
    } else {
      return '1d'; // 1 day window even for short ranges (changed from 15m)
    }
  }
  
  /// Parse CSV response from InfluxDB
  List<Map<String, dynamic>> _parseCsvResponse(String csvData) {
    final lines = csvData.split('\n');
    if (lines.length < 2) return [];
    
    final headers = lines[0].split(',');
    final List<Map<String, dynamic>> result = [];
    
    for (int i = 1; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.isEmpty) continue;
      
      final values = line.split(',');
      if (values.length == headers.length) {
        final Map<String, dynamic> row = {};
        for (int j = 0; j < headers.length; j++) {
          row[headers[j]] = values[j];
        }
        result.add(row);
      }
    }
    
    return result;
  }

  /// Test connection to InfluxDB
  Future<bool> testConnection() async {
    if (!_enabled) return true;
    
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/ping'),
        headers: {
          'Authorization': 'Token $_token',
        },
      ).timeout(const Duration(seconds: 5));

      return response.statusCode == 204;
    } catch (e) {
      print('❌ InfluxDB Connection Test Failed: $e');
      return false;
    }
  }

  /// Get current power consumption
  Future<double> getCurrentPowerConsumption() async {
    if (!_enabled) return 0.0;
    
    try {
      final query = '''
        from(bucket: "$_bucket")
          |> range(start: -1h)
          |> filter(fn: (r) => r._measurement == "power_consumption")
          |> filter(fn: (r) => r._field == "power")
          |> last()
      ''';

      final response = await http.post(
        Uri.parse('$_baseUrl/api/v2/query?org=$_org'),
        headers: {
          'Authorization': 'Token $_token',
          'Content-Type': 'application/vnd.flux',
          'Accept': 'application/csv',
        },
        body: query,
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = _parseCsvResponse(response.body);
        if (data.isNotEmpty && data.first.containsKey('_value')) {
          return double.tryParse(data.first['_value']?.toString() ?? '0') ?? 0.0;
        }
        return 0.0;
      } else {
        print('❌ InfluxDB Current Power Query Error: ${response.statusCode} - ${response.body}');
        return 0.0;
      }
    } catch (e) {
      print('❌ InfluxDB Current Power Query Exception: $e');
      return 0.0;
    }
  }

  /// Get daily energy consumption
  Future<double> getDailyEnergyConsumption({DateTime? date}) async {
    if (!_enabled) return 0.0;
    
    final targetDate = date ?? DateTime.now();
    final startOfDay = DateTime(targetDate.year, targetDate.month, targetDate.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    
    return await getTotalEnergyConsumption(
      startTime: startOfDay,
      endTime: endOfDay,
    );
  }

  /// Get monthly energy consumption
  Future<double> getMonthlyEnergyConsumption({DateTime? month}) async {
    if (!_enabled) return 0.0;
    
    final targetMonth = month ?? DateTime.now();
    final startOfMonth = DateTime(targetMonth.year, targetMonth.month, 1);
    final endOfMonth = DateTime(targetMonth.year, targetMonth.month + 1, 1);
    
    return await getTotalEnergyConsumption(
      startTime: startOfMonth,
      endTime: endOfMonth,
    );
  }

  /// Check what measurements are available in the database
  Future<List<String>> getAvailableMeasurements() async {
    if (!_enabled) return [];
    
    try {
      final query = '''
import "influxdata/influxdb/schema"

schema.measurements(bucket: "$_bucket")
      ''';

      final response = await http.post(
        Uri.parse('$_baseUrl/api/v2/query?org=$_org'),
        headers: {
          'Authorization': 'Token $_token',
          'Content-Type': 'application/vnd.flux',
          'Accept': 'application/csv',
        },
        body: query,
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = _parseCsvResponse(response.body);
        return data.map((row) => row['_value']?.toString() ?? '').where((m) => m.isNotEmpty).toList();
      } else {
        print('❌ InfluxDB Measurements Query Error: ${response.statusCode} - ${response.body}');
        return [];
      }
    } catch (e) {
      print('❌ InfluxDB Measurements Query Exception: $e');
      return [];
    }
  }

  /// Get sample of recent data to understand structure
  Future<Map<String, dynamic>> getRecentDataSample() async {
    if (!_enabled) return {};
    
    try {
      final measurements = ['sensor_data', 'device_state', 'power_consumption', 'energy_consumption'];
      final Map<String, dynamic> samples = {};
      
      for (final measurement in measurements) {
        final query = '''
from(bucket: "$_bucket")
  |> range(start: -24h)
  |> filter(fn: (r) => r._measurement == "$measurement")
  |> limit(n: 5)
        ''';

        final response = await http.post(
          Uri.parse('$_baseUrl/api/v2/query?org=$_org'),
          headers: {
            'Authorization': 'Token $_token',
            'Content-Type': 'application/vnd.flux',
            'Accept': 'application/csv',
          },
          body: query,
        ).timeout(const Duration(seconds: 5));

        if (response.statusCode == 200) {
          final data = _parseCsvResponse(response.body);
          samples[measurement] = data;
          print('📊 $measurement: ${data.length} records');
        }
      }
      
      return samples;
    } catch (e) {
      print('❌ Error getting data samples: $e');
      return {};
    }
  }
}