import 'dart:async';

/// Optimized Device Status Service
/// Tối ưu hóa việc lấy trạng thái thiết bị để giảm tải hệ thống
class OptimizedDeviceStatusService {
  static final OptimizedDeviceStatusService _instance = OptimizedDeviceStatusService._internal();
  factory OptimizedDeviceStatusService() => _instance;
  OptimizedDeviceStatusService._internal();

  // Cache trạng thái thiết bị
  final Map<String, bool> _deviceStates = {};
  final Map<String, DateTime> _lastUpdate = {};
  
  // Cache thời gian (5 phút)
  static const Duration _cacheValidDuration = Duration(minutes: 5);

  /// Lấy trạng thái thiết bị từ cache hoặc source
  bool getDeviceState(String deviceId, {bool? fallbackState}) {
    final cachedState = _deviceStates[deviceId];
    final lastUpdateTime = _lastUpdate[deviceId];
    
    // Kiểm tra cache còn hợp lệ không
    if (cachedState != null && lastUpdateTime != null) {
      final timeDiff = DateTime.now().difference(lastUpdateTime);
      if (timeDiff <= _cacheValidDuration) {
        return cachedState; // Sử dụng cache
      }
    }
    
    // Fallback nếu không có cache
    return fallbackState ?? false;
  }

  /// Cập nhật trạng thái thiết bị vào cache
  void updateDeviceState(String deviceId, bool state) {
    _deviceStates[deviceId] = state;
    _lastUpdate[deviceId] = DateTime.now();
  }

  /// Batch update nhiều thiết bị cùng lúc
  void updateMultipleDeviceStates(Map<String, bool> states) {
    final now = DateTime.now();
    states.forEach((deviceId, state) {
      _deviceStates[deviceId] = state;
      _lastUpdate[deviceId] = now;
    });
  }

  /// Lấy tất cả trạng thái thiết bị (cho debugging)
  Map<String, bool> getAllCachedStates() {
    return Map.from(_deviceStates);
  }

  /// Clear cache (khi cần refresh)
  void clearCache() {
    _deviceStates.clear();
    _lastUpdate.clear();
  }

  /// Kiểm tra cache có còn valid không
  bool isCacheValid(String deviceId) {
    final lastUpdateTime = _lastUpdate[deviceId];
    if (lastUpdateTime == null) return false;
    
    final timeDiff = DateTime.now().difference(lastUpdateTime);
    return timeDiff <= _cacheValidDuration;
  }

  /// Lấy thống kê cache
  Map<String, dynamic> getCacheStats() {
    final validCount = _deviceStates.keys.where((id) => isCacheValid(id)).length;
    return {
      'total_cached': _deviceStates.length,
      'valid_cached': validCount,
      'expired_cached': _deviceStates.length - validCount,
      'cache_duration_minutes': _cacheValidDuration.inMinutes,
    };
  }
}
