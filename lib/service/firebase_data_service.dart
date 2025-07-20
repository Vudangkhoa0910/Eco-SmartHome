import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:smart_home/service/mqtt_service.dart';
import 'package:intl/intl.dart';

class FirebaseDataService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Collections
  static const String _sensorDataCollection = 'sensor_data';
  static const String _deviceStateCollection = 'device_states';
  static const String _powerConsumptionCollection = 'power_consumption';
  static const String _energyConsumptionCollection = 'energy_consumption';
  static const String _electricityBillCollection = 'electricity_bills';
  static const String _analyticsCollection = 'analytics';
  static const String _chatHistoryCollection = 'chat_history';
  static const String _customCommandsCollection = 'custom_commands';
  static const String _userSettingsCollection = 'user_settings';
  
  static final FirebaseDataService _instance = FirebaseDataService._internal();
  factory FirebaseDataService() => _instance;
  FirebaseDataService._internal();

  /// Write sensor data to Firestore (optimized - only 1 write per sensor reading)
  Future<bool> writeSensorData(SensorData data) async {
    try {
      // Calculate energy consumption directly in main write to avoid separate calls
      final powerKw = data.power / 1000.0; // Convert watts to kW
      final energyKwh = powerKw; // For hourly reading
      final cost = energyKwh * 1500; // 1500 VND per kWh
      
      await _firestore.collection(_sensorDataCollection).add({
        'temperature': data.temperature,
        'humidity': data.humidity,
        'power': data.power,
        'voltage': data.voltage,
        'current': data.current,
        // Include energy data in same write to reduce Firebase operations
        'energy_kwh': energyKwh,
        'cost': cost,
        'electricity_rate': 1500,
        'timestamp': FieldValue.serverTimestamp(),
        'location': 'home',
        'created_at': DateTime.now(),
      });

      print('✅ Firebase: Consolidated sensor data written successfully');
      return true;
    } catch (e) {
      print('❌ Firebase Write Exception: $e');
      return false;
    }
  }

  /// Write power consumption data (private helper)
  Future<void> _writePowerConsumptionData(SensorData data) async {
    try {
      // Calculate energy consumption (kWh) - assume this is per hour reading
      final powerKw = data.power / 1000.0; // Convert watts to kW
      final energyKwh = powerKw; // For hourly reading
      
      // Calculate cost using default rate (1.5k VND per kWh)
      final cost = energyKwh * 1500; // 1500 VND per kWh
      
      await _firestore.collection(_powerConsumptionCollection).add({
        'power': data.power,
        'voltage': data.voltage,
        'current': data.current,
        'energy_kwh': energyKwh,
        'cost': cost,
        'electricity_rate': 1500,
        'location': 'home',
        'timestamp': FieldValue.serverTimestamp(),
        'created_at': DateTime.now(),
      });
      
      print('✅ Firebase: Power consumption data written successfully');
    } catch (e) {
      print('❌ Firebase power consumption write error: $e');
    }
  }

  /// Write device state changes to Firestore
  Future<bool> writeDeviceState(String device, String state, {Map<String, dynamic>? metadata}) async {
    try {
      final data = <String, Object>{
        'device': device,
        'state': state,
        'value': state == "ON" ? 1 : 0,
        'timestamp': FieldValue.serverTimestamp(),
        'created_at': DateTime.now(),
      };

      if (metadata != null) {
        data.addAll(metadata.map((k, v) => MapEntry(k, v as Object)));
      }

      await _firestore.collection(_deviceStateCollection).add(data);
      
      print('✅ Firebase: Device state written successfully');
      return true;
    } catch (e) {
      print('❌ Firebase Device State Write Exception: $e');
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
    try {
      await _firestore.collection(_electricityBillCollection).add({
        'total_kwh': totalKwh,
        'total_cost': totalCost,
        'tier_breakdown': tierBreakdown,
        'period': Timestamp.fromDate(period),
        'location': location,
        'timestamp': FieldValue.serverTimestamp(),
        'created_at': DateTime.now(),
      });
      
      print('✅ Firebase: Electricity bill data written successfully');
      return true;
    } catch (e) {
      print('❌ Firebase electricity bill write error: $e');
      return false;
    }
  }

  /// Write energy consumption data to Firestore
  Future<bool> writeEnergyConsumption(SensorData data) async {
    try {
      // Calculate energy consumption (kWh) - assume this is per minute reading
      final powerKw = data.power / 1000.0; // Convert watts to kW
      final energyKwhPerMinute = powerKw / 60.0; // Convert to kWh per minute
      
      // Calculate cost using electricity rate tiers
      final costPerKwh = _calculateElectricityCost(energyKwhPerMinute);
      
      await _firestore.collection(_energyConsumptionCollection).add({
        'power': data.power,
        'voltage': data.voltage,
        'current': data.current,
        'energy_kwh_per_minute': energyKwhPerMinute,
        'cost_per_minute': costPerKwh,
        'location': 'home',
        'timestamp': FieldValue.serverTimestamp(),
        'created_at': DateTime.now(),
      });
      
      print('✅ Firebase: Energy consumption data written successfully');
      return true;
    } catch (e) {
      print('❌ Firebase Energy Write Exception: $e');
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

  /// Write power consumption data for a specific device
  Future<bool> writePowerConsumption({
    required String deviceId,
    required double power,
    required double voltage,
    required double current,
    required DateTime timestamp,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      // Calculate energy consumption (kWh) - assume this is per hour reading
      final powerKw = power / 1000.0; // Convert watts to kW
      final energyKwh = powerKw; // For hourly reading
      
      // Calculate cost using default rate (1.5k VND per kWh)
      final cost = energyKwh * 1500; // 1500 VND per kWh
      
      final data = <String, Object>{
        'device': deviceId,
        'power': power,
        'voltage': voltage,
        'current': current,
        'energy_kwh': energyKwh,
        'cost': cost,
        'electricity_rate': 1500,
        'location': 'home',
        'timestamp': Timestamp.fromDate(timestamp),
        'created_at': DateTime.now(),
      };

      if (metadata != null) {
        data.addAll(metadata.map((k, v) => MapEntry(k, v as Object)));
      }

      await _firestore.collection(_powerConsumptionCollection).add(data);
      
      print('✅ Firebase: Power consumption data for $deviceId written successfully');
      return true;
    } catch (e) {
      print('❌ Firebase power consumption write error: $e');
      return false;
    }
  }

  /// Get power consumption history
  Future<List<Map<String, dynamic>>> getPowerConsumptionHistory({
    required DateTime startTime,
    required DateTime endTime,
    String? location,
  }) async {
    try {
      print('🔍 Getting power consumption history');
      print('🔍 Time range: $startTime to $endTime');
      print('🔍 Location: ${location ?? 'all'}');
      
      Query query = _firestore
          .collection(_powerConsumptionCollection)
          .where('created_at', isGreaterThanOrEqualTo: startTime)
          .where('created_at', isLessThanOrEqualTo: endTime)
          .orderBy('created_at', descending: false);

      if (location != null && location.isNotEmpty) {
        query = query.where('location', isEqualTo: location);
      }

      final QuerySnapshot snapshot = await query.get();
      print('🔍 Found ${snapshot.docs.length} power consumption history records');
      
      final List<Map<String, dynamic>> result = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return data;
      }).toList();
      
      // If no power_consumption data, try sensor_data
      if (result.isEmpty) {
        print('🔍 No power_consumption history, trying sensor_data...');
        Query sensorQuery = _firestore
            .collection(_sensorDataCollection)
            .where('created_at', isGreaterThanOrEqualTo: startTime)
            .where('created_at', isLessThanOrEqualTo: endTime)
            .orderBy('created_at', descending: false);

        final QuerySnapshot sensorSnapshot = await sensorQuery.get();
        print('🔍 Found ${sensorSnapshot.docs.length} sensor history records');
        
        final List<Map<String, dynamic>> sensorResult = sensorSnapshot.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          data['id'] = doc.id;
          // Add energy_kwh field if not present
          if (!data.containsKey('energy_kwh')) {
            final power = (data['power'] as num?)?.toDouble() ?? 0.0;
            data['energy_kwh'] = power / 1000.0; // Convert W to kWh
          }
          return data;
        }).toList();
        
        return sensorResult;
      }
      
      return result;
    } catch (e) {
      print('❌ Firebase Query Exception: $e');
      return [];
    }
  }

  /// Get energy consumption by zone
  Future<Map<String, double>> getEnergyConsumptionByZone({
    required DateTime startTime,
    required DateTime endTime,
  }) async {
    try {
      final QuerySnapshot snapshot = await _firestore
          .collection(_deviceStateCollection)
          .where('created_at', isGreaterThanOrEqualTo: startTime)
          .where('created_at', isLessThanOrEqualTo: endTime)
          .get();

      final Map<String, double> result = {};
      
      for (final doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final zone = data['zone']?.toString() ?? 'unknown';
        final value = (data['value'] as num?)?.toDouble() ?? 0.0;
        
        result[zone] = (result[zone] ?? 0.0) + value;
      }
      
      return result;
    } catch (e) {
      print('❌ Firebase Zone Query Exception: $e');
      return {};
    }
  }

  /// Get total energy consumption
  Future<double> getTotalEnergyConsumption({
    required DateTime startTime,
    required DateTime endTime,
    String? location,
  }) async {
    try {
      print('🔍 Getting total energy consumption');
      print('🔍 Time range: $startTime to $endTime');
      print('🔍 Location: ${location ?? 'all'}');
      
      Query query = _firestore
          .collection(_powerConsumptionCollection)
          .where('created_at', isGreaterThanOrEqualTo: startTime)
          .where('created_at', isLessThanOrEqualTo: endTime);

      if (location != null && location.isNotEmpty) {
        query = query.where('location', isEqualTo: location);
      }

      final QuerySnapshot snapshot = await query.get();
      print('🔍 Found ${snapshot.docs.length} power consumption records');
      
      double total = 0.0;
      
      for (final doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final energyKwh = (data['energy_kwh'] as num?)?.toDouble() ?? 0.0;
        total += energyKwh;
        print('🔍 Record energy: ${energyKwh} kWh, Total so far: ${total} kWh');
      }
      
      // If no power_consumption data, try sensor_data
      if (total == 0.0) {
        print('🔍 No power_consumption data, trying sensor_data...');
        Query sensorQuery = _firestore
            .collection(_sensorDataCollection)
            .where('created_at', isGreaterThanOrEqualTo: startTime)
            .where('created_at', isLessThanOrEqualTo: endTime);

        final QuerySnapshot sensorSnapshot = await sensorQuery.get();
        print('🔍 Found ${sensorSnapshot.docs.length} sensor records');
        
        for (final doc in sensorSnapshot.docs) {
          final data = doc.data() as Map<String, dynamic>;
          final power = (data['power'] as num?)?.toDouble() ?? 0.0;
          // Convert power to energy (assuming hourly readings)
          final energyKwh = power / 1000.0; // Convert W to kWh
          total += energyKwh;
          print('🔍 Sensor power: ${power}W, Energy: ${energyKwh} kWh, Total: ${total} kWh');
        }
      }
      
      print('🔍 Final total energy: ${total} kWh');
      return total;
    } catch (e) {
      print('❌ Firebase Total Energy Query Exception: $e');
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
    try {
      DateTime effectiveEndTime = endTime ?? DateTime.now();
      DateTime effectiveStartTime;
      
      if (startTime != null) {
        effectiveStartTime = startTime;
      } else if (timeRange != null) {
        effectiveStartTime = _parseTimeRange(timeRange, effectiveEndTime);
      } else {
        effectiveStartTime = effectiveEndTime.subtract(const Duration(days: 7));
      }

      Query query = _firestore
          .collection(_deviceStateCollection)
          .where('created_at', isGreaterThanOrEqualTo: effectiveStartTime)
          .where('created_at', isLessThanOrEqualTo: effectiveEndTime);

      if (deviceId.isNotEmpty) {
        query = query.where('device', isEqualTo: deviceId);
      }

      final QuerySnapshot snapshot = await query.get();
      final Map<String, dynamic> result = {};
      final Map<String, List<double>> deviceValues = {};
      
      for (final doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final device = data['device']?.toString() ?? 'unknown';
        final value = (data['value'] as num?)?.toDouble() ?? 0.0;
        
        deviceValues.putIfAbsent(device, () => []);
        deviceValues[device]!.add(value);
      }
      
      // Calculate average for each device
      for (final entry in deviceValues.entries) {
        final device = entry.key;
        final values = entry.value;
        final avgValue = values.isNotEmpty 
            ? values.reduce((a, b) => a + b) / values.length 
            : 0.0;
        
        result[device] = {
          'usage_percentage': (avgValue * 100).toStringAsFixed(1),
          'avg_state': avgValue,
        };
      }
      
      return result;
    } catch (e) {
      print('❌ Firebase Device Stats Query Exception: $e');
      return {};
    }
  }

  /// Get sensor history data with customizable parameters
  Future<List<Map<String, dynamic>>> querySensorHistory({
    required String sensorType,
    required String timeRange,
    String aggregation = 'mean',
    String? location,
  }) async {
    try {
      final endTime = DateTime.now();
      final startTime = _parseTimeRange(timeRange, endTime);
      
      String collection;
      String field;
      
      switch(sensorType) {
        case 'temperature':
        case 'humidity':
          collection = _sensorDataCollection;
          field = sensorType;
          break;
        case 'power':
        case 'voltage':
        case 'current':
        case 'energy':
          collection = _powerConsumptionCollection;
          field = sensorType == 'energy' ? 'energy_kwh' : sensorType;
          break;
        default:
          throw Exception('Unknown sensor type: $sensorType');
      }
      
      Query query = _firestore
          .collection(collection)
          .where('created_at', isGreaterThanOrEqualTo: startTime)
          .where('created_at', isLessThanOrEqualTo: endTime)
          .orderBy('created_at', descending: false);

      if (location != null && location.isNotEmpty) {
        query = query.where('location', isEqualTo: location);
      }

      final QuerySnapshot snapshot = await query.get();
      final List<Map<String, dynamic>> result = [];
      
      for (final doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        
        // Convert Firestore data to format expected by UI
        final value = data[field];
        final timestamp = data['created_at'] as DateTime?;
        
        if (value != null && timestamp != null) {
          result.add({
            '_time': timestamp.toIso8601String(),
            '_value': value,
            '_field': field,
            '_measurement': collection,
          });
        }
      }
      
      print('🔍 Firebase Sensor history query returned ${result.length} records');
      return result;
    } catch (e) {
      print('❌ Firebase Query Exception: $e');
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
          return endTime.subtract(const Duration(days: 7));
      }
    }
    
    return endTime.subtract(const Duration(days: 7));
  }

  /// Test connection to Firebase
  Future<bool> testConnection() async {
    try {
      // Try to read from a collection to test connection
      await _firestore.collection(_sensorDataCollection).limit(1).get();
      return true;
    } catch (e) {
      print('❌ Firebase Connection Test Failed: $e');
      return false;
    }
  }

  /// Get current power consumption
  Future<double> getCurrentPowerConsumption() async {
    try {
      print('🔍 Getting current power consumption from collection: $_powerConsumptionCollection');
      
      final QuerySnapshot snapshot = await _firestore
          .collection(_powerConsumptionCollection)
          .orderBy('created_at', descending: true)
          .limit(1)
          .get();

      print('🔍 Found ${snapshot.docs.length} power consumption records');

      if (snapshot.docs.isNotEmpty) {
        final data = snapshot.docs.first.data() as Map<String, dynamic>;
        final power = (data['power'] as num?)?.toDouble() ?? 0.0;
        print('🔍 Current power: ${power}W');
        return power;
      }
      
      // Try sensor_data collection as fallback
      print('🔍 No power_consumption data, trying sensor_data collection...');
      final sensorSnapshot = await _firestore
          .collection(_sensorDataCollection)
          .orderBy('created_at', descending: true)
          .limit(1)
          .get();

      print('🔍 Found ${sensorSnapshot.docs.length} sensor records');

      if (sensorSnapshot.docs.isNotEmpty) {
        final data = sensorSnapshot.docs.first.data() as Map<String, dynamic>;
        final power = (data['power'] as num?)?.toDouble() ?? 0.0;
        print('🔍 Current power from sensor: ${power}W');
        return power;
      }
      
      print('🔍 No data found, returning 0.0');
      return 0.0;
    } catch (e) {
      print('❌ Firebase Current Power Query Exception: $e');
      return 0.0;
    }
  }

  /// Get daily energy consumption
  Future<double> getDailyEnergyConsumption({DateTime? date}) async {
    try {
      final targetDate = date ?? DateTime.now();
      final startOfDay = DateTime(targetDate.year, targetDate.month, targetDate.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));
      
      print('🔍 Getting daily energy for ${DateFormat('yyyy-MM-dd').format(targetDate)}');
      print('🔍 Time range: $startOfDay to $endOfDay');
      
      final result = await getTotalEnergyConsumption(
        startTime: startOfDay,
        endTime: endOfDay,
      );
      
      print('🔍 Daily energy result: ${result} kWh');
      return result;
    } catch (e) {
      print('❌ Error getting daily energy consumption: $e');
      return 0.0;
    }
  }

  /// Get monthly energy consumption
  Future<double> getMonthlyEnergyConsumption({DateTime? month}) async {
    final targetMonth = month ?? DateTime.now();
    final startOfMonth = DateTime(targetMonth.year, targetMonth.month, 1);
    final endOfMonth = DateTime(targetMonth.year, targetMonth.month + 1, 1);
    
    return await getTotalEnergyConsumption(
      startTime: startOfMonth,
      endTime: endOfMonth,
    );
  }

  /// Get available measurements (collections)
  Future<List<String>> getAvailableMeasurements() async {
    try {
      return [
        _sensorDataCollection,
        _deviceStateCollection,
        _powerConsumptionCollection,
        _energyConsumptionCollection,
        _electricityBillCollection,
      ];
    } catch (e) {
      print('❌ Firebase Measurements Query Exception: $e');
      return [];
    }
  }

  /// Get sample of recent data to understand structure
  Future<Map<String, dynamic>> getRecentDataSample() async {
    try {
      final measurements = [_sensorDataCollection, _deviceStateCollection, _powerConsumptionCollection, _energyConsumptionCollection];
      final Map<String, dynamic> samples = {};
      
      for (final measurement in measurements) {
        final QuerySnapshot snapshot = await _firestore
            .collection(measurement)
            .orderBy('created_at', descending: true)
            .limit(5)
            .get();

        final data = snapshot.docs.map((doc) {
          final docData = doc.data() as Map<String, dynamic>;
          docData['id'] = doc.id;
          return docData;
        }).toList();
        
        samples[measurement] = data;
        print('📊 $measurement: ${data.length} records');
      }
      
      return samples;
    } catch (e) {
      print('❌ Error getting data samples: $e');
      return {};
    }
  }

  /// Write chat message to Firestore
  Future<bool> writeChatMessage({
    required String userId,
    required String message,
    required bool isUser,
    required DateTime timestamp,
    String? response,
    String? deviceAction,
  }) async {
    try {
      final data = <String, Object>{
        'user_id': userId,
        'message': message,
        'is_user': isUser,
        'timestamp': Timestamp.fromDate(timestamp),
        'created_at': DateTime.now(),
      };

      if (response != null) {
        data['response'] = response;
      }

      if (deviceAction != null) {
        data['device_action'] = deviceAction;
      }

      await _firestore.collection(_chatHistoryCollection).add(data);
      
      print('✅ Firebase: Chat message saved successfully');
      return true;
    } catch (e) {
      print('❌ Firebase chat message write error: $e');
      return false;
    }
  }

  /// Get chat history for a user
  Future<List<Map<String, dynamic>>> getChatHistory({
    required String userId,
    int limit = 50,
    DateTime? startAfter,
  }) async {
    try {
      Query query = _firestore
          .collection(_chatHistoryCollection)
          .where('user_id', isEqualTo: userId)
          .orderBy('timestamp', descending: true)
          .limit(limit);

      if (startAfter != null) {
        query = query.startAfter([Timestamp.fromDate(startAfter)]);
      }

      final QuerySnapshot snapshot = await query.get();
      
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      print('❌ Firebase chat history query error: $e');
      return [];
    }
  }

  /// Save custom command
  Future<bool> saveCustomCommand({
    required String userId,
    required String commandText,
    required String deviceId,
    required String action,
    required String zone,
    String? description,
    List<String>? aliases,
  }) async {
    try {
      final data = <String, Object>{
        'user_id': userId,
        'command_text': commandText,
        'device_id': deviceId,
        'action': action,
        'zone': zone,
        'is_active': true,
        'created_at': DateTime.now(),
        'updated_at': DateTime.now(),
      };

      if (description != null) {
        data['description'] = description;
      }

      if (aliases != null && aliases.isNotEmpty) {
        data['aliases'] = aliases;
      }

      await _firestore.collection(_customCommandsCollection).add(data);
      
      print('✅ Firebase: Custom command saved successfully');
      return true;
    } catch (e) {
      print('❌ Firebase custom command save error: $e');
      return false;
    }
  }

  /// Get custom commands for a user
  Future<List<Map<String, dynamic>>> getCustomCommands({
    required String userId,
    String? zone,
    String? deviceId,
  }) async {
    try {
      Query query = _firestore
          .collection(_customCommandsCollection)
          .where('user_id', isEqualTo: userId)
          .where('is_active', isEqualTo: true);

      if (zone != null) {
        query = query.where('zone', isEqualTo: zone);
      }

      if (deviceId != null) {
        query = query.where('device_id', isEqualTo: deviceId);
      }

      final QuerySnapshot snapshot = await query.get();
      
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      print('❌ Firebase custom commands query error: $e');
      return [];
    }
  }

  /// Update custom command
  Future<bool> updateCustomCommand({
    required String commandId,
    String? commandText,
    String? deviceId,
    String? action,
    String? zone,
    String? description,
    List<String>? aliases,
    bool? isActive,
  }) async {
    try {
      final data = <String, Object>{
        'updated_at': DateTime.now(),
      };

      if (commandText != null) data['command_text'] = commandText;
      if (deviceId != null) data['device_id'] = deviceId;
      if (action != null) data['action'] = action;
      if (zone != null) data['zone'] = zone;
      if (description != null) data['description'] = description;
      if (aliases != null) data['aliases'] = aliases;
      if (isActive != null) data['is_active'] = isActive;

      await _firestore.collection(_customCommandsCollection).doc(commandId).update(data);
      
      print('✅ Firebase: Custom command updated successfully');
      return true;
    } catch (e) {
      print('❌ Firebase custom command update error: $e');
      return false;
    }
  }

  /// Delete custom command
  Future<bool> deleteCustomCommand(String commandId) async {
    try {
      await _firestore.collection(_customCommandsCollection).doc(commandId).update({
        'is_active': false,
        'updated_at': DateTime.now(),
      });
      
      print('✅ Firebase: Custom command deleted successfully');
      return true;
    } catch (e) {
      print('❌ Firebase custom command delete error: $e');
      return false;
    }
  }

  /// Get available zones and devices
  Future<Map<String, dynamic>> getAvailableZonesAndDevices() async {
    try {
      final QuerySnapshot deviceSnapshot = await _firestore
          .collection(_deviceStateCollection)
          .orderBy('created_at', descending: true)
          .limit(100)
          .get();

      final Set<String> zones = {};
      final Set<String> devices = {};

      for (final doc in deviceSnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final zone = data['zone']?.toString();
        final device = data['device']?.toString();

        if (zone != null && zone.isNotEmpty) {
          zones.add(zone);
        }
        if (device != null && device.isNotEmpty) {
          devices.add(device);
        }
      }

      return {
        'zones': zones.toList(),
        'devices': devices.toList(),
      };
    } catch (e) {
      print('❌ Firebase zones and devices query error: $e');
      return {
        'zones': ['entrance', 'living_room', 'bedroom', 'kitchen', 'garden'],
        'devices': ['led_gate', 'led_around', 'motor'],
      };
    }
  }

  /// Save user AI settings
  Future<bool> saveUserSettings({
    required String userId,
    required Map<String, dynamic> settings,
  }) async {
    try {
      await _firestore.collection(_userSettingsCollection).doc(userId).set({
        'settings': settings,
        'updated_at': DateTime.now(),
      }, SetOptions(merge: true));
      
      print('✅ Firebase: User settings saved successfully');
      return true;
    } catch (e) {
      print('❌ Firebase user settings save error: $e');
      return false;
    }
  }

  /// Get user AI settings
  Future<Map<String, dynamic>> getUserSettings(String userId) async {
    try {
      final DocumentSnapshot doc = await _firestore
          .collection(_userSettingsCollection)
          .doc(userId)
          .get();

      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        return data['settings'] as Map<String, dynamic>? ?? {};
      }

      return {};
    } catch (e) {
      print('❌ Firebase user settings query error: $e');
      return {};
    }
  }

  /// Search custom commands by text
  Future<List<Map<String, dynamic>>> searchCustomCommands({
    required String userId,
    required String searchText,
  }) async {
    try {
      final QuerySnapshot snapshot = await _firestore
          .collection(_customCommandsCollection)
          .where('user_id', isEqualTo: userId)
          .where('is_active', isEqualTo: true)
          .get();

      final List<Map<String, dynamic>> results = [];
      
      for (final doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        
        final commandText = data['command_text']?.toString().toLowerCase() ?? '';
        final description = data['description']?.toString().toLowerCase() ?? '';
        final aliases = data['aliases'] as List<dynamic>? ?? [];
        
        final search = searchText.toLowerCase();
        
        if (commandText.contains(search) || 
            description.contains(search) ||
            aliases.any((alias) => alias.toString().toLowerCase().contains(search))) {
          results.add(data);
        }
      }

      return results;
    } catch (e) {
      print('❌ Firebase custom commands search error: $e');
      return [];
    }
  }

  /// Clear chat history for a user
  Future<bool> clearChatHistory(String userId) async {
    try {
      final QuerySnapshot snapshot = await _firestore
          .collection(_chatHistoryCollection)
          .where('user_id', isEqualTo: userId)
          .get();

      for (final doc in snapshot.docs) {
        await doc.reference.delete();
      }
      
      print('✅ Firebase: Chat history cleared successfully');
      return true;
    } catch (e) {
      print('❌ Firebase clear chat history error: $e');
      return false;
    }
  }

  /// Generate sample data for testing analytics
  Future<bool> generateSampleAnalyticsData() async {
    try {
      print('🎯 Generating sample analytics data...');
      final now = DateTime.now();
      
      // Generate data for last 30 days
      for (int i = 0; i < 30; i++) {
        final date = now.subtract(Duration(days: i));
        
        // Generate sample power consumption data
        final power = 500.0 + (i * 10.0) + (DateTime.now().millisecond % 200);
        final voltage = 220.0 + (DateTime.now().millisecond % 20);
        final current = power / voltage;
        final energyKwh = power / 1000.0; // Convert W to kWh
        final cost = energyKwh * 1500; // 1500 VND per kWh
        
        await _firestore.collection(_powerConsumptionCollection).add({
          'power': power,
          'voltage': voltage,
          'current': current,
          'energy_kwh': energyKwh,
          'cost': cost,
          'electricity_rate': 1500,
          'location': 'home',
          'timestamp': FieldValue.serverTimestamp(),
          'created_at': date,
        });
        
        // Generate sample sensor data
        await _firestore.collection(_sensorDataCollection).add({
          'temperature': 25.0 + (i % 10),
          'humidity': 60.0 + (i % 20),
          'power': power,
          'voltage': voltage,
          'current': current,
          'energy_kwh': energyKwh,
          'cost': cost,
          'electricity_rate': 1500,
          'timestamp': FieldValue.serverTimestamp(),
          'location': 'home',
          'created_at': date,
        });
        
        // Generate sample device states
        final devices = ['led_gate', 'led_around', 'motor', 'air_conditioner', 'fan'];
        for (final device in devices) {
          await _firestore.collection(_deviceStateCollection).add({
            'device': device,
            'state': (i + devices.indexOf(device)) % 2 == 0 ? 'ON' : 'OFF',
            'value': (i + devices.indexOf(device)) % 2 == 0 ? 1 : 0,
            'timestamp': FieldValue.serverTimestamp(),
            'created_at': date,
          });
        }
        
        print('🎯 Generated data for day ${i + 1}/30');
      }
      
      print('✅ Sample analytics data generated successfully');
      return true;
    } catch (e) {
      print('❌ Error generating sample data: $e');
      return false;
    }
  }

  /// Debug method to check available data
  Future<Map<String, int>> debugCheckDataAvailability() async {
    try {
      final Map<String, int> counts = {};
      
      // Check each collection
      final collections = [
        _sensorDataCollection,
        _deviceStateCollection,
        _powerConsumptionCollection,
        _energyConsumptionCollection,
        _electricityBillCollection,
      ];
      
      for (final collection in collections) {
        final QuerySnapshot snapshot = await _firestore
            .collection(collection)
            .limit(1)
            .get();
        counts[collection] = snapshot.docs.length;
      }
      
      print('🔍 Data availability check:');
      for (final entry in counts.entries) {
        print('🔍 ${entry.key}: ${entry.value > 0 ? 'HAS DATA' : 'NO DATA'}');
      }
      
      return counts;
    } catch (e) {
      print('❌ Error checking data availability: $e');
      return {};
    }
  }
}
