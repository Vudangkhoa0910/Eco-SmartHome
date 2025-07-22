import 'package:cloud_firestore/cloud_firestore.dart';

/// Trạng thái hoạt động của cổng
enum GateStatus {
  opening('opening', 'Đang mở', '🔓⬆️'),
  closing('closing', 'Đang đóng', '🔒⬇️'),
  open('open', 'Đã mở', '🔓'),
  closed('closed', 'Đã đóng', '🔒'),
  stopped('stopped', 'Đã dừng', '⏹️'),
  error('error', 'Lỗi', '❌');

  const GateStatus(this.value, this.description, this.icon);
  final String value;
  final String description;
  final String icon;

  static GateStatus fromString(String value) {
    for (final status in GateStatus.values) {
      if (status.value == value) return status;
    }
    return GateStatus.closed; // Default
  }
}

/// Model cho trạng thái cổng
class GateState {
  final int level;
  final bool isMoving;
  final GateStatus status;
  final DateTime timestamp;
  
  // Simplified fields for command-based logic
  final String? lastCommand;        // Last command sent to gate ('OPEN_TO_75', 'CLOSE', etc.)
  final String? direction;          // 'opening', 'closing', null
  final int? targetLevel;           // Target level for current operation (0-100)

  const GateState({
    required this.level,
    required this.isMoving,
    required this.status,
    required this.timestamp,
    this.lastCommand,
    this.direction,
    this.targetLevel,
  });

  Map<String, dynamic> toMap() {
    return {
      // Core gate state
      'level': level,
      'isMoving': isMoving,
      'status': status.value,
      // 🚨 timestamp removed - no longer needed since we don't write to Firebase
      
      // Command tracking for debugging (local state only)
      'last_command': lastCommand,
      'direction': direction,
      'target_level': targetLevel,
    };
  }

  factory GateState.fromMap(Map<String, dynamic> map) {
    return GateState(
      level: map['level'] ?? 0,
      isMoving: map['isMoving'] ?? false,
      status: GateStatus.fromString(map['status'] ?? 'closed'),
      timestamp: map['timestamp'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(map['timestamp'])
          : DateTime.now(),
      
      // Simplified fields for command-based logic
      lastCommand: map['last_command'],
      direction: map['direction'],
      targetLevel: map['target_level'],
    );
  }

  String get description {
    // Ưu tiên hiển thị status description nếu có
    if (isMoving) {
      return status.description;
    }
    
    // Hiển thị mô tả theo level khi không di chuyển
    switch (level) {
      case 0: return 'Đóng hoàn toàn - ${status.description}';
      case 25: return 'Mở 1/4 - Người đi bộ';
      case 50: return 'Mở 1/2 - Xe máy';
      case 75: return 'Mở 3/4 - Xe hơi nhỏ';
      case 100: return 'Mở hoàn toàn - Xe tải';
      default: return 'Mở $level% - ${status.description}';
    }
  }

  String get icon {
    // Ưu tiên icon của status khi đang di chuyển
    if (isMoving) return status.icon;
    
    // Icon theo level khi không di chuyển
    if (level <= 0) return '🔒';
    if (level <= 25) return '🚶';
    if (level <= 50) return '🏍️';
    if (level <= 75) return '🚗';
    return '🚛';
  }

  /// Phương thức tiện ích để tạo GateState với status tự động
  factory GateState.withAutoStatus({
    required int level,
    required bool isMoving,
    DateTime? timestamp,
    GateStatus? forcedStatus,
    String? lastCommand,
    String? direction,
    int? targetLevel,
  }) {
    GateStatus status;
    
    if (forcedStatus != null) {
      status = forcedStatus;
    } else if (isMoving) {
      // Xác định status dựa trên level khi đang di chuyển
      status = level > 50 ? GateStatus.opening : GateStatus.closing;
    } else {
      // Xác định status khi không di chuyển
      status = level > 0 ? GateStatus.open : GateStatus.closed;
    }

    return GateState(
      level: level,
      isMoving: isMoving,
      status: status,
      timestamp: timestamp ?? DateTime.now(),
      lastCommand: lastCommand,
      direction: direction,
      targetLevel: targetLevel,
    );
  }

  // Simplified utility methods for command-based logic
  
  /// Check if gate has reached target level
  bool get hasReachedTarget {
    if (targetLevel == null) return true;
    return level == targetLevel;
  }
  
  /// Create a copy with updated fields
  GateState copyWith({
    int? level,
    bool? isMoving,
    GateStatus? status,
    DateTime? timestamp,
    String? lastCommand,
    String? direction,
    int? targetLevel,
  }) {
    return GateState(
      level: level ?? this.level,
      isMoving: isMoving ?? this.isMoving,
      status: status ?? this.status,
      timestamp: timestamp ?? this.timestamp,
      lastCommand: lastCommand ?? this.lastCommand,
      direction: direction ?? this.direction,
      targetLevel: targetLevel ?? this.targetLevel,
    );
  }
}

/// Các mức độ mở cổng (deprecated - dùng cho tương thích)
enum GateLevel {
  closed(0, 'Đóng', '🔒'),
  partial33(33, 'Mở 1/3', '🔓'),
  partial66(66, 'Mở 2/3', '🔓'),
  open(100, 'Mở hoàn toàn', '🔓✅');

  const GateLevel(this.percentage, this.description, this.icon);
  final int percentage;
  final String description;
  final String icon;
}

/// Service quản lý trạng thái cổng
class GateStateService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _gateStateCollection = 'gate_states';
  
  static final GateStateService _instance = GateStateService._internal();
  factory GateStateService() => _instance;
  GateStateService._internal();
  
  // Cache mechanism - 🚨 OPTIMIZED: Minimal Firebase reads, rely on MQTT for real-time
  GateState? _cachedState;
  DateTime? _lastCacheTime;
  static const Duration _cacheTimeout = Duration(hours: 1);  // 🚨 CRITICAL: 1 hour cache to minimize Firebase reads

  /// Lưu trạng thái cổng với cache - 🚨 FIREBASE WRITES DISABLED
  Future<bool> saveGateState(GateState gateState) async {
    try {
      // Update cache immediately for responsive UI
      _cachedState = gateState;
      _lastCacheTime = DateTime.now();
      
      // 🚨 FIREBASE WRITES COMPLETELY DISABLED - Only use cache for real-time UI
      print('📋 Gate state cached: ${gateState.status.description} (${gateState.level}%) - Firebase write DISABLED');
      return true;
    } catch (e) {
      print('❌ Error caching gate state: $e');
      return false;
    }
  }

  /// Lưu trạng thái cổng (deprecated - để tương thích)
  Future<bool> saveGateStateLegacy({
    required String deviceId,
    required GateLevel level,
    String? location,
  }) async {
    final gateState = GateState.withAutoStatus(
      level: level.percentage,
      isMoving: false,
    );
    return saveGateState(gateState);
  }

  /// Send gate command with proper direction logic
  Future<bool> sendGateCommand({
    required String command,
    required int targetLevel,
    String? direction,
  }) async {
    try {
      // Get current state to determine proper status
      final currentState = await getCurrentGateState();
      final currentLevel = currentState.level;
      
      // Determine status based on direction logic
      GateStatus status;
      if (direction == 'opening') {
        status = GateStatus.opening;
      } else if (direction == 'closing') {
        status = GateStatus.closing;
      } else {
        // No direction = no movement needed or stop command
        status = targetLevel > 0 ? GateStatus.open : GateStatus.closed;
      }
      
      final gateState = GateState(
        level: currentLevel, // Keep current level initially
        isMoving: direction != null, // Moving if has direction
        status: status,
        timestamp: DateTime.now(),
        lastCommand: command,
        direction: direction,
        targetLevel: targetLevel,
      );
      
      print('🚪 Sending gate command: $command → Target: $targetLevel%, Direction: $direction');
      return saveGateState(gateState);
    } catch (e) {
      print('❌ Error sending gate command: $e');
      return false;
    }
  }

  /// Update operation progress during movement
  Future<bool> updateOperationProgress({
    required int currentLevel,
  }) async {
    try {
      final currentState = await getCurrentGateState();
      
      // Check if target reached
      if (currentState.targetLevel != null && 
          currentLevel == currentState.targetLevel) {
        // Auto-complete operation when target is reached
        print('🎯 Target reached: $currentLevel% - Auto completing operation');
        return completeOperation(finalLevel: currentLevel, success: true);
      }
      
      // Keep existing command tracking but update level
      final gateState = currentState.copyWith(
        level: currentLevel,
        isMoving: true,
        timestamp: DateTime.now(),
      );
      
      return saveGateState(gateState);
    } catch (e) {
      print('❌ Error updating operation progress: $e');
      return false;
    }
  }
  
  /// Complete operation and set final state
  Future<bool> completeOperation({
    required int finalLevel,
    bool success = true,
  }) async {
    try {
      final currentState = await getCurrentGateState();
      
      // Keep all command fields, only update movement and status
      final gateState = currentState.copyWith(
        level: finalLevel,
        isMoving: false,  // Stop movement
        status: success 
            ? (finalLevel > 0 ? GateStatus.open : GateStatus.closed)
            : GateStatus.error,
        timestamp: DateTime.now(),
        // Keep all command tracking: lastCommand, direction, targetLevel
      );
      
      print('✅ Operation completed: Level=$finalLevel%, Status=${gateState.status.value}');
      return saveGateState(gateState);
    } catch (e) {
      print('❌ Error completing operation: $e');
      return false;
    }
  }

  /// Lấy trạng thái cổng hiện tại với cache - 🚨 OPTIMIZED to minimize Firebase reads
  Future<GateState> getCurrentGateState() async {
    try {
      // 🚨 PRIORITY 1: Return cached state if available (even if "expired" - MQTT keeps it current)
      if (_cachedState != null) {
        final cacheAge = _lastCacheTime != null ? DateTime.now().difference(_lastCacheTime!) : Duration.zero;
        print('📋 Using cached gate state (age: ${cacheAge.inMinutes}min ${cacheAge.inSeconds % 60}s)');
        return _cachedState!;
      }
      
      // 🚨 PRIORITY 2: Only read Firebase if absolutely no cache (app startup only)
      print('🔄 RARE: Loading gate state from Firebase (no cache available)...');
      final doc = await _firestore
          .collection(_gateStateCollection)
          .doc('main_gate')
          .get();
      
      GateState state;
      if (doc.exists) {
        final data = doc.data()!;
        // Try new format first
        if (data.containsKey('level') && data.containsKey('status')) {
          state = GateState.fromMap(data);
        } else {
          // Fallback to legacy format
          final percentage = data['percentage'] ?? 0;
          state = GateState.withAutoStatus(
            level: percentage,
            isMoving: false,
            timestamp: (data['created_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
          );
        }
      } else {
        // Return default state if no data found
        state = GateState.withAutoStatus(
          level: 0,
          isMoving: false,
        );
      }
      
      // Update cache
      _cachedState = state;
      _lastCacheTime = DateTime.now();
      
      print('📡 Firebase read completed - cache updated for 1 hour');
      return state;
    } catch (e) {
      print('❌ Error getting current gate state: $e');
      
      // Fallback to cache even if expired, or return default
      if (_cachedState != null) {
        print('🔄 Using stale cache as fallback');
        return _cachedState!;
      }
      
      return GateState.withAutoStatus(level: 0, isMoving: false);
    }
  }

  /// Lấy trạng thái cổng hiện tại (deprecated - để tương thích)
  Future<GateLevel?> getCurrentGateStateLegacy(String deviceId) async {
    try {
      final QuerySnapshot snapshot = await _firestore
          .collection(_gateStateCollection)
          .where('device_id', isEqualTo: deviceId)
          .orderBy('created_at', descending: true)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        final data = snapshot.docs.first.data() as Map<String, dynamic>;
        final levelName = data['level'] as String?;
        
        // Tìm GateLevel từ tên
        for (final level in GateLevel.values) {
          if (level.name == levelName) {
            return level;
          }
        }
      }
      
      return GateLevel.closed; // Mặc định là đóng
    } catch (e) {
      print('❌ Firebase gate state query error: $e');
      return GateLevel.closed;
    }
  }

  /// Lấy lịch sử trạng thái cổng
  Future<List<Map<String, dynamic>>> getGateHistory({
    required String deviceId,
    required DateTime startTime,
    required DateTime endTime,
  }) async {
    try {
      final QuerySnapshot snapshot = await _firestore
          .collection(_gateStateCollection)
          .where('device_id', isEqualTo: deviceId)
          .where('created_at', isGreaterThanOrEqualTo: startTime)
          .where('created_at', isLessThanOrEqualTo: endTime)
          .orderBy('created_at', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      print('❌ Firebase gate history query error: $e');
      return [];
    }
  }

  /// Stream theo dõi trạng thái cổng real-time
  Stream<GateLevel> watchGateState(String deviceId) {
    return _firestore
        .collection(_gateStateCollection)
        .where('device_id', isEqualTo: deviceId)
        .orderBy('created_at', descending: true)
        .limit(1)
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isNotEmpty) {
        final data = snapshot.docs.first.data();
        final levelName = data['level'] as String?;
        
        for (final level in GateLevel.values) {
          if (level.name == levelName) {
            return level;
          }
        }
      }
      return GateLevel.closed;
    });
  }

  /// Tính toán thống kê sử dụng cổng
  Future<Map<String, dynamic>> getGateUsageStats({
    required String deviceId,
    required DateTime startTime,
    required DateTime endTime,
  }) async {
    try {
      final history = await getGateHistory(
        deviceId: deviceId,
        startTime: startTime,
        endTime: endTime,
      );

      final Map<String, int> levelCounts = {};
      int totalOperations = history.length;

      for (final record in history) {
        final level = record['level'] as String? ?? 'closed';
        levelCounts[level] = (levelCounts[level] ?? 0) + 1;
      }

      return {
        'total_operations': totalOperations,
        'level_distribution': levelCounts,
        'most_used_level': levelCounts.entries
            .fold<MapEntry<String, int>?>(
              null, 
              (prev, curr) => prev == null || curr.value > prev.value ? curr : prev
            )?.key ?? 'closed',
        'period_start': startTime.toIso8601String(),
        'period_end': endTime.toIso8601String(),
      };
    } catch (e) {
      print('❌ Gate usage stats error: $e');
      return {
        'total_operations': 0,
        'level_distribution': {},
        'most_used_level': 'closed',
      };
    }
  }

  /// Di chuyển cổng theo phần trăm tương đối (so với trạng thái hiện tại)
  Future<_GateMoveResult> moveGateRelative(int relativePercent) async {
    try {
      final current = await getCurrentGateState();
      int newLevel = (current.level + relativePercent).clamp(0, 100);
      if (newLevel == current.level) {
        return _GateMoveResult(
          success: false,
          targetLevel: current.level,
          message: 'Cổng đã ở mức $newLevel%',
        );
      }
      return _GateMoveResult(
        success: true,
        targetLevel: newLevel,
        message: 'Di chuyển cổng đến $newLevel%',
      );
    } catch (e) {
      return _GateMoveResult(
        success: false,
        targetLevel: 0,
        message: 'Lỗi khi lấy trạng thái cổng: $e',
      );
    }
  }
  
  /// Di chuyển cổng đến phần trăm tuyệt đối
  Future<_GateMoveResult> moveGateAbsolute(int targetPercent) async {
    try {
      final current = await getCurrentGateState();
      int newLevel = targetPercent.clamp(0, 100);
      if (newLevel == current.level) {
        return _GateMoveResult(
          success: false,
          targetLevel: current.level,
          message: 'Cổng đã ở mức $newLevel%',
        );
      }
      return _GateMoveResult(
        success: true,
        targetLevel: newLevel,
        message: 'Di chuyển cổng đến $newLevel%',
      );
    } catch (e) {
      return _GateMoveResult(
        success: false,
        targetLevel: 0,
        message: 'Lỗi khi lấy trạng thái cổng: $e',
      );
    }
  }

  /// Cập nhật trạng thái cổng đang mở
  Future<bool> setGateOpening(int currentLevel) async {
    final gateState = GateState.withAutoStatus(
      level: currentLevel,
      isMoving: true,
      forcedStatus: GateStatus.opening,
    );
    return saveGateState(gateState);
  }

  /// Cập nhật trạng thái cổng đang đóng
  Future<bool> setGateClosing(int currentLevel) async {
    final gateState = GateState.withAutoStatus(
      level: currentLevel,
      isMoving: true,
      forcedStatus: GateStatus.closing,
    );
    return saveGateState(gateState);
  }

  /// Cập nhật trạng thái cổng đã mở hoàn tất
  Future<bool> setGateOpened(int finalLevel) async {
    final gateState = GateState.withAutoStatus(
      level: finalLevel,
      isMoving: false,
      forcedStatus: finalLevel > 0 ? GateStatus.open : GateStatus.closed,
    );
    return saveGateState(gateState);
  }

  /// Cập nhật trạng thái cổng đã đóng hoàn tất
  Future<bool> setGateClosed() async {
    final gateState = GateState.withAutoStatus(
      level: 0,
      isMoving: false,
      forcedStatus: GateStatus.closed,
    );
    return saveGateState(gateState);
  }

  /// Cập nhật trạng thái cổng bị dừng
  Future<bool> setGateStopped(int currentLevel) async {
    final gateState = GateState.withAutoStatus(
      level: currentLevel,
      isMoving: false,
      forcedStatus: GateStatus.stopped,
    );
    return saveGateState(gateState);
  }

  /// Cập nhật trạng thái cổng gặp lỗi
  Future<bool> setGateError(int currentLevel) async {
    final gateState = GateState.withAutoStatus(
      level: currentLevel,
      isMoving: false,
      forcedStatus: GateStatus.error,
    );
    
    return saveGateState(gateState);
  }
  
  /// Get current level from state
  Future<int> getCurrentLevel() async {
    final currentState = await getCurrentGateState();
    return currentState.level;
  }
}

/// Kết quả di chuyển cổng
class _GateMoveResult {
  final bool success;
  final int targetLevel;
  final String message;
  _GateMoveResult({
    required this.success,
    required this.targetLevel,
    required this.message,
  });
}
