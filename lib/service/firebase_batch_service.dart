import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:smart_home/service/mqtt_unified_service.dart';

/// Service tối ưu hóa Firebase writes bằng cách batch operations và throttling
class FirebaseBatchService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseBatchService _instance = FirebaseBatchService._internal();
  factory FirebaseBatchService() => _instance;
  FirebaseBatchService._internal();

  // Batch operations queue
  final List<Map<String, dynamic>> _pendingWrites = [];
  Timer? _batchTimer;
  static const Duration _batchInterval = Duration(minutes: 2); // Batch every 2 minutes (was 10 seconds!)
  static const int _maxBatchSize = 5; // Reduce to 5 operations per batch (was 10)
  
  // Throttling cho reads - MUCH MORE AGGRESSIVE
  final Map<String, DateTime> _lastReadTime = {};
  static const Duration _readThrottle = Duration(minutes: 5); // Tối đa 1 read/5 minutes per query (was 1 minute!)

  /// Thêm operation vào batch queue
  void addToBatch({
    required String collection,
    required Map<String, dynamic> data,
    String? operation, // 'add', 'update', 'delete'
    String? docId,
  }) {
    _pendingWrites.add({
      'collection': collection,
      'data': data,
      'operation': operation ?? 'add',
      'docId': docId,
      'timestamp': FieldValue.serverTimestamp(),
      'created_at': DateTime.now(),
    });

    // Auto-execute if batch is full
    if (_pendingWrites.length >= _maxBatchSize) {
      _executeBatch();
    } else {
      _scheduleExecution();
    }
  }

  /// Schedule batch execution
  void _scheduleExecution() {
    _batchTimer?.cancel();
    _batchTimer = Timer(_batchInterval, () {
      if (_pendingWrites.isNotEmpty) {
        _executeBatch();
      }
    });
  }

  /// Execute batch write operations
  Future<void> _executeBatch() async {
    if (_pendingWrites.isEmpty) return;

    try {
      final batch = _firestore.batch();
      final operations = List<Map<String, dynamic>>.from(_pendingWrites);
      _pendingWrites.clear();

      print('🔥 Executing Firebase batch with ${operations.length} operations');

      for (final op in operations) {
        final collection = op['collection'] as String;
        final data = op['data'] as Map<String, dynamic>;
        final operation = op['operation'] as String;
        final docId = op['docId'] as String?;

        switch (operation) {
          case 'add':
            final docRef = _firestore.collection(collection).doc();
            batch.set(docRef, data);
            break;
          case 'update':
            if (docId != null) {
              final docRef = _firestore.collection(collection).doc(docId);
              batch.update(docRef, data);
            }
            break;
          case 'delete':
            if (docId != null) {
              final docRef = _firestore.collection(collection).doc(docId);
              batch.delete(docRef);
            }
            break;
        }
      }

      await batch.commit();
      print('✅ Firebase batch executed successfully');
    } catch (e) {
      print('❌ Firebase batch execution error: $e');
      // Re-queue failed operations for retry
      _pendingWrites.addAll(_pendingWrites);
    }
  }

  /// Optimized sensor data write with HEAVY throttling
  Future<bool> writeSensorDataOptimized(SensorData data) async {
    final queryKey = 'sensor_data_${DateTime.now().hour}'; // Group by HOUR windows (was 2-minute!)
    
    if (_shouldThrottleWrite(queryKey)) {
      print('🚫 Sensor write throttled - too frequent');
      return true; // Skip write if too frequent
    }

    // Only write if power usage is significant
    if (data.power < 10.0) {
      print('🚫 Sensor write skipped - power too low');
      return true; // Skip if power consumption too low
    }

    // Calculate energy metrics once
    final powerKw = data.power / 1000.0;
    final energyKwh = powerKw / 60.0; // Per minute
    final cost = energyKwh * 1500;

    addToBatch(
      collection: 'sensor_data_optimized',
      data: {
        'temperature': data.temperature,
        'humidity': data.humidity,
        'power': data.power,
        'voltage': data.voltage,
        'current': data.current,
        'energy_kwh': energyKwh,
        'cost': cost,
        'electricity_rate': 1500,
        'location': 'home',
        'data_interval': '2min', // Indicate this is aggregated data
      },
    );

    _lastReadTime[queryKey] = DateTime.now();
    return true;
  }

  /// Optimized device state write with HEAVY throttling
  Future<bool> writeDeviceStateOptimized(
    String device, 
    String state, {
    Map<String, dynamic>? metadata
  }) async {
    final queryKey = 'device_${device}_${DateTime.now().hour}'; // Group by HOUR windows (was 1-minute!)
    
    if (_shouldThrottleWrite(queryKey)) {
      print('🚫 Device write throttled: $device');
      return true; // Skip write if too frequent
    }

    final data = {
      'device': device,
      'state': state,
      'value': state == "ON" ? 1 : 0,
    };

    if (metadata != null) {
      data.addAll(metadata.cast<String, Object>());
    }

    addToBatch(
      collection: 'device_states_optimized',
      data: data,
    );

    _lastReadTime[queryKey] = DateTime.now();
    return true;
  }

  /// Check if should throttle write operation
  bool _shouldThrottleWrite(String queryKey) {
    final lastTime = _lastReadTime[queryKey];
    if (lastTime == null) return false;
    
    return DateTime.now().difference(lastTime) < _readThrottle;
  }

  /// Cached read with throttling
  Future<List<Map<String, dynamic>>> getCachedQuery({
    required String collection,
    required String queryKey,
    required DateTime startTime,
    required DateTime endTime,
    String? orderBy,
    bool descending = false,
    int? limit,
  }) async {
    // Check if query was made recently
    if (_shouldThrottleRead(queryKey)) {
      print('🚫 Query throttled: $queryKey');
      return [];
    }

    try {
      Query query = _firestore
          .collection(collection)
          .where('created_at', isGreaterThanOrEqualTo: startTime)
          .where('created_at', isLessThanOrEqualTo: endTime);

      if (orderBy != null) {
        query = query.orderBy(orderBy, descending: descending);
      }

      if (limit != null) {
        query = query.limit(limit);
      }

      final snapshot = await query.get();
      _lastReadTime[queryKey] = DateTime.now();

      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      print('❌ Cached query error: $e');
      return [];
    }
  }

  /// Check if should throttle read operation
  bool _shouldThrottleRead(String queryKey) {
    final lastTime = _lastReadTime[queryKey];
    if (lastTime == null) return false;
    
    return DateTime.now().difference(lastTime) < _readThrottle;
  }

  /// Get summary statistics (aggregated to reduce reads)
  Future<Map<String, dynamic>> getSummaryStats({
    required DateTime startTime,
    required DateTime endTime,
  }) async {
    final queryKey = 'summary_stats_${startTime.day}_${endTime.day}';
    
    if (_shouldThrottleRead(queryKey)) {
      print('🚫 Summary stats query throttled');
      return _getDefaultSummaryStats();
    }

    try {
      // Get aggregated data instead of raw data
      final powerData = await getCachedQuery(
        collection: 'sensor_data_optimized',
        queryKey: 'power_summary_${DateTime.now().hour}',
        startTime: startTime,
        endTime: endTime,
        limit: 50, // Limit results
      );

      final deviceData = await getCachedQuery(
        collection: 'device_states_optimized', 
        queryKey: 'device_summary_${DateTime.now().hour}',
        startTime: startTime,
        endTime: endTime,
        limit: 30, // Limit results
      );

      _lastReadTime[queryKey] = DateTime.now();

      return {
        'power_data_count': powerData.length,
        'device_data_count': deviceData.length,
        'total_power': powerData.fold<double>(0.0, (sum, item) => sum + ((item['power'] as num?)?.toDouble() ?? 0.0)),
        'total_energy': powerData.fold<double>(0.0, (sum, item) => sum + ((item['energy_kwh'] as num?)?.toDouble() ?? 0.0)),
        'last_updated': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      print('❌ Summary stats error: $e');
      return _getDefaultSummaryStats();
    }
  }

  Map<String, dynamic> _getDefaultSummaryStats() {
    return {
      'power_data_count': 0,
      'device_data_count': 0,
      'total_power': 0.0,
      'total_energy': 0.0,
      'last_updated': DateTime.now().toIso8601String(),
    };
  }

  /// Force execute pending batches
  Future<void> flush() async {
    _batchTimer?.cancel();
    await _executeBatch();
  }

  /// Clean up
  void dispose() {
    _batchTimer?.cancel();
    _pendingWrites.clear();
    _lastReadTime.clear();
  }
}
