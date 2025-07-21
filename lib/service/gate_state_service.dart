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

  const GateState({
    required this.level,
    required this.isMoving,
    required this.status,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'level': level,
      'isMoving': isMoving,
      'status': status.value,
      'status_description': status.description,
      'status_icon': status.icon,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'created_at': timestamp,
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

  /// Lưu trạng thái cổng (phiên bản mới - đơn giản hóa)
  Future<bool> saveGateState(GateState gateState) async {
    try {
      final data = gateState.toMap();
      data.addAll({
        'description': gateState.description,
        'icon': gateState.icon,
        'device_id': 'main_gate',
        'location': 'entrance',
        'zone': 'entrance', 
        'type': 'gate',
        'updated_at': FieldValue.serverTimestamp(),
      });

      // Use document ID 'main_gate' to avoid index issues
      await _firestore
          .collection(_gateStateCollection)
          .doc('main_gate')
          .set(data, SetOptions(merge: true));
      
      print('✅ Gate state saved successfully: ${gateState.status.description} (${gateState.level}%)');
      return true;
    } catch (e) {
      print('❌ Error saving gate state: $e');
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
  /// Lấy trạng thái cổng hiện tại (phiên bản đơn giản)
  Future<GateState> getCurrentGateState() async {
    try {
      // Simple document read - no index required
      final doc = await _firestore
          .collection(_gateStateCollection)
          .doc('main_gate')
          .get();
      
      if (doc.exists) {
        final data = doc.data()!;
        // Try new format first
        if (data.containsKey('level') && data.containsKey('status')) {
          return GateState.fromMap(data);
        }
        // Fallback to legacy format
        final percentage = data['percentage'] ?? 0;
        return GateState.withAutoStatus(
          level: percentage,
          isMoving: false,
          timestamp: (data['created_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
        );
      }
      // Return default state if no data found
      return GateState.withAutoStatus(
        level: 0,
        isMoving: false,
        timestamp: DateTime.now(),
      );
    } catch (e) {
      print('❌ Error getting current gate state: $e');
      // Return default state on error
      return GateState.withAutoStatus(
        level: 0,
        isMoving: false,
        timestamp: DateTime.now(),
      );
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
  Future<bool> setGateError(int currentLevel, {String? errorMessage}) async {
    final gateState = GateState.withAutoStatus(
      level: currentLevel,
      isMoving: false,
      forcedStatus: GateStatus.error,
    );
    
    // Lưu thêm thông tin lỗi nếu có
    final success = await saveGateState(gateState);
    if (success && errorMessage != null) {
      try {
        await _firestore
            .collection(_gateStateCollection)
            .doc('main_gate')
            .update({
          'error_message': errorMessage,
          'error_timestamp': FieldValue.serverTimestamp(),
        });
      } catch (e) {
        print('❌ Error saving error message: $e');
      }
    }
    
    return success;
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
