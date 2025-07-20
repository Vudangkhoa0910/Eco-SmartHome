/// Firebase Optimization Configuration
/// Tối ưu hóa Firebase usage để giảm chi phí reads/writes
class FirebaseOptimizationConfig {
  
  // Write throttling settings
  static const Duration sensorWriteInterval = Duration(minutes: 5);
  static const Duration deviceWriteInterval = Duration(seconds: 30);
  static const Duration chatMessageThrottle = Duration(seconds: 10);
  
  // Read throttling settings  
  static const Duration queryThrottle = Duration(minutes: 5);
  static const Duration analyticsRefresh = Duration(minutes: 10);
  
  // Batch settings
  static const Duration batchInterval = Duration(minutes: 2);
  static const int maxBatchSize = 5;
  
  // Power thresholds for logging
  static const double minPowerToLog = 10.0; // Only log power > 10W
  static const double significantPowerChange = 50.0; // Log if power changes > 50W
  
  // Message filtering
  static const int minMessageLength = 5; // Don't save messages < 5 chars
  static const int minResponseLength = 10; // Don't save responses < 10 chars
  
  // Query limits
  static const int maxQueryResults = 50; // Limit query results
  static const int maxChatHistory = 20; // Limit chat history
  
  // Cache settings
  static const Duration cacheTimeout = Duration(minutes: 15);
  static const int maxCacheEntries = 100;
  
  /// Check if power value is significant enough to log
  static bool shouldLogPower(double power) {
    return power >= minPowerToLog;
  }
  
  /// Check if power change is significant 
  static bool isPowerChangeSignificant(double oldPower, double newPower) {
    return (newPower - oldPower).abs() >= significantPowerChange;
  }
  
  /// Check if message is worth saving
  static bool shouldSaveMessage(String message, {bool isUser = true}) {
    final minLength = isUser ? minMessageLength : minResponseLength;
    return message.trim().length >= minLength;
  }
  
  /// Get optimized query limit based on type
  static int getQueryLimit(String queryType) {
    switch (queryType) {
      case 'chat_history':
        return maxChatHistory;
      case 'analytics':
        return maxQueryResults;
      case 'device_history':
        return 30;
      default:
        return maxQueryResults;
    }
  }
}
