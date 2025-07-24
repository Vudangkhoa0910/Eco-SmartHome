import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_home/service/mqtt_unified_service.dart';
import 'package:smart_home/provider/getit.dart';

class ScheduleService {
  static ScheduleService? _instance;
  static ScheduleService get instance {
    _instance ??= ScheduleService._internal();
    return _instance!;
  }

  ScheduleService._internal();

  MqttUnifiedService? _mqttService;

  List<Map<String, dynamic>> _schedules = [];
  Timer? _executionTimer;

  // Stream để notify UI về thay đổi schedules
  final StreamController<List<Map<String, dynamic>>> _schedulesController =
      StreamController<List<Map<String, dynamic>>>.broadcast();

  Stream<List<Map<String, dynamic>>> get schedulesStream =>
      _schedulesController.stream;
  List<Map<String, dynamic>> get schedules => List.unmodifiable(_schedules);

  /// Khởi tạo service - load schedules và bắt đầu timer
  Future<void> initialize() async {
    try {
      // Lấy MQTT service sau khi getIt đã được setup
      _mqttService = getIt<MqttUnifiedService>();
      print('📅 ScheduleService: MQTT service obtained');

      await _loadSchedules();
      _startExecutionTimer();
      print(
          '📅 ScheduleService: Initialized with ${_schedules.length} schedules');

      // Log tất cả schedules hiện tại
      for (var schedule in _schedules) {
        print(
            '📅 Schedule: ${schedule['name']} - ${schedule['deviceName']} at ${schedule['time']} (Active: ${schedule['isActive']})');
      }
    } catch (e) {
      print('❌ ScheduleService: Error during initialization: $e');
    }
  }

  /// Bắt đầu timer kiểm tra execution mỗi 30 giây (để test dễ hơn)
  void _startExecutionTimer() {
    _executionTimer?.cancel();

    // Kiểm tra mỗi 30 giây để test dễ hơn (có thể thay về 1 phút sau)
    _executionTimer = Timer.periodic(Duration(seconds: 30), (timer) {
      _checkAndExecuteSchedules();
    });

    print(
        '📅 ScheduleService: Execution timer started (check every 30 seconds)');
  }

  /// Kiểm tra và thực thi schedules đến hạn
  void _checkAndExecuteSchedules() {
    DateTime now = DateTime.now();
    String currentTime =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    int currentWeekday = now.weekday - 1; // Convert to 0-6 (Monday = 0)

    print(
        '📅 ScheduleService: Checking schedules at $currentTime (weekday: $currentWeekday)');
    print('📅 ScheduleService: Total schedules: ${_schedules.length}');

    List<Map<String, dynamic>> schedulesToRemove = [];

    for (var schedule in _schedules) {
      print(
          '📅 Checking schedule: ${schedule['name']} - Time: ${schedule['time']} - Active: ${schedule['isActive']}');

      if (!schedule['isActive']) {
        print('  ⏭️ Schedule inactive, skipping');
        continue; // Skip inactive schedules
      }

      // Check if time matches
      if (schedule['time'] != currentTime) {
        print('  ⏰ Time mismatch: ${schedule['time']} != $currentTime');
        continue;
      }

      bool shouldExecute = false;

      if (schedule['isRepeating']) {
        // For repeating schedules, check if today is in selected days
        List<dynamic> days = schedule['days'] ?? [];
        print(
            '  📅 Repeating schedule - Days: $days, Current weekday: $currentWeekday');
        if (days.contains(currentWeekday)) {
          shouldExecute = true;
          print('  ✅ Should execute (weekday match)');
        } else {
          print('  ❌ Should not execute (weekday mismatch)');
        }
      } else {
        // For one-time schedules, check if it's the right date
        String? createdAt = schedule['createdAt'];
        if (createdAt != null) {
          DateTime createdDate = DateTime.parse(createdAt);
          DateTime scheduleDate =
              DateTime(createdDate.year, createdDate.month, createdDate.day);
          DateTime today = DateTime(now.year, now.month, now.day);

          print(
              '  📅 One-time schedule - Schedule date: $scheduleDate, Today: $today');

          if (scheduleDate.isAtSameMomentAs(today)) {
            shouldExecute = true;
            // Mark for removal after execution
            schedulesToRemove.add(schedule);
            print('  ✅ Should execute (date match)');
          } else {
            print('  ❌ Should not execute (date mismatch)');
          }
        }
      }

      if (shouldExecute) {
        print(
            '🎯 ScheduleService: EXECUTING schedule "${schedule['name']}" - ${schedule['deviceName']} ${schedule['action']}');
        _executeSchedule(schedule);
      }
    }

    // Remove executed one-time schedules
    if (schedulesToRemove.isNotEmpty) {
      _removeExecutedSchedules(schedulesToRemove);
    }
  }

  /// Thực thi schedule bằng cách gửi MQTT command
  void _executeSchedule(Map<String, dynamic> schedule) {
    try {
      if (_mqttService == null) {
        print('❌ ScheduleService: MQTT service not initialized');
        return;
      }

      String deviceName = schedule['deviceName'];
      String action = schedule['action'];
      String mqttTopic = schedule['mqttTopic'];

      print('📅 ScheduleService: Executing schedule for $deviceName');
      print('📅 ScheduleService: Action: $action');
      print('📅 ScheduleService: MQTT Topic: $mqttTopic');

      // Convert action to MQTT command based on device type and current system
      String command = _getCommandForAction(deviceName, action);

      print('📅 ScheduleService: Sending MQTT command...');
      print('📅 ScheduleService: Topic: $mqttTopic');
      print('📅 ScheduleService: Command: $command');

      // Gửi command qua MQTT service
      _mqttService!.publishDeviceCommand(mqttTopic, command);

      print('📅 ScheduleService: ✅ MQTT command sent successfully!');
      print('📅 ScheduleService: Device $deviceName should now be $action');
    } catch (e) {
      print(
          '📅 ScheduleService: ❌ Error executing schedule ${schedule['id']}: $e');
      print('📅 ScheduleService: Failed device: ${schedule['deviceName']}');
      print('📅 ScheduleService: Failed action: ${schedule['action']}');
    }
  }

  /// Convert action to MQTT command based on current system format
  String _getCommandForAction(String deviceName, String action) {
    // For most devices (lights, fans, AC), use ON/OFF format
    if (action == 'on') {
      return 'ON';
    } else if (action == 'off') {
      return 'OFF';
    }

    // For gate control, use open/close
    if (deviceName.contains('Cổng điện') || deviceName.contains('cổng')) {
      if (action == 'open') {
        return '100'; // Full open
      } else if (action == 'close') {
        return '0'; // Full close
      }
    }

    // Default: return action as is
    return action.toUpperCase();
  }

  /// Load schedules from SharedPreferences
  Future<void> _loadSchedules() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      List<String> savedSchedules = prefs.getStringList('schedules') ?? [];

      _schedules = savedSchedules.map((scheduleJson) {
        return Map<String, dynamic>.from(jsonDecode(scheduleJson));
      }).toList();

      // Remove expired one-time schedules
      DateTime now = DateTime.now();
      _schedules.removeWhere((schedule) {
        if (schedule['isRepeating']) return false;

        String? createdAt = schedule['createdAt'];
        if (createdAt != null) {
          DateTime createdDate = DateTime.parse(createdAt);
          DateTime scheduleDate =
              DateTime(createdDate.year, createdDate.month, createdDate.day);
          DateTime today = DateTime(now.year, now.month, now.day);

          return scheduleDate.isBefore(today);
        }
        return false;
      });

      _schedulesController.add(_schedules);
      print(
          '📅 ScheduleService: Loaded ${_schedules.length} schedules from cache');
    } catch (e) {
      print('📅 ScheduleService: Error loading schedules: $e');
      _schedules = [];
    }
  }

  /// Save schedules to SharedPreferences
  Future<void> _saveSchedules() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      List<String> schedulesJson =
          _schedules.map((s) => jsonEncode(s)).toList();
      await prefs.setStringList('schedules', schedulesJson);
      print(
          '📅 ScheduleService: Saved ${_schedules.length} schedules to cache');
    } catch (e) {
      print('📅 ScheduleService: Error saving schedules: $e');
    }
  }

  /// Remove executed one-time schedules
  Future<void> _removeExecutedSchedules(
      List<Map<String, dynamic>> schedulesToRemove) async {
    for (var schedule in schedulesToRemove) {
      _schedules.removeWhere((s) => s['id'] == schedule['id']);
      print(
          '📅 ScheduleService: Removed executed one-time schedule: ${schedule['name']}');
    }

    await _saveSchedules();
    _schedulesController.add(_schedules);
  }

  /// Add new schedule
  Future<void> addSchedule(Map<String, dynamic> schedule) async {
    _schedules.add(schedule);
    await _saveSchedules();
    _schedulesController.add(_schedules);
    print('📅 ScheduleService: Added schedule ${schedule['id']}');
  }

  /// Remove schedule
  Future<void> removeSchedule(String scheduleId) async {
    _schedules.removeWhere((schedule) => schedule['id'] == scheduleId);
    await _saveSchedules();
    _schedulesController.add(_schedules);
    print('📅 ScheduleService: Removed schedule $scheduleId');
  }

  /// Toggle schedule active/inactive
  Future<void> toggleSchedule(String scheduleId) async {
    int index = _schedules.indexWhere((s) => s['id'] == scheduleId);
    if (index != -1) {
      _schedules[index]['isActive'] = !_schedules[index]['isActive'];
      await _saveSchedules();
      _schedulesController.add(_schedules);
      print('📅 ScheduleService: Toggled schedule $scheduleId');
    }
  }

  /// Get active schedules
  List<Map<String, dynamic>> getActiveSchedules() {
    return _schedules.where((s) => s['isActive'] == true).toList();
  }

  /// Get schedules for specific device
  List<Map<String, dynamic>> getSchedulesForDevice(String deviceName) {
    return _schedules.where((s) => s['deviceName'] == deviceName).toList();
  }

  /// Clear all schedules
  Future<void> clearAllSchedules() async {
    _schedules.clear();
    await _saveSchedules();
    _schedulesController.add(_schedules);
    print('📅 ScheduleService: Cleared all schedules');
  }

  /// Force check schedules now (for testing)
  void forceCheckSchedules() {
    print('📅 ScheduleService: Force checking schedules...');
    _checkAndExecuteSchedules();
  }

  /// Test schedule execution (for debugging)
  void testScheduleExecution(String scheduleId) {
    var schedule = _schedules.firstWhere((s) => s['id'] == scheduleId);
    print(
        '📅 ScheduleService: Testing execution for schedule: ${schedule['name']}');
    _executeSchedule(schedule);
  }

  /// Force execute a schedule immediately (for testing)
  void forceExecuteSchedule(String scheduleId) {
    try {
      var schedule = _schedules.firstWhere((s) => s['id'] == scheduleId);
      print(
          '📅 ScheduleService: FORCE executing schedule: ${schedule['name']}');
      _executeSchedule(schedule);
    } catch (e) {
      print('❌ ScheduleService: Schedule not found: $scheduleId');
    }
  }

  /// Debug: Print all current schedules
  void debugPrintSchedules() {
    print('📅 ScheduleService: === ALL SCHEDULES ===');
    for (var schedule in _schedules) {
      print('  - ${schedule['name']} (${schedule['deviceName']})');
      print('    Time: ${schedule['time']}');
      print('    Days: ${schedule['days']}');
      print('    Active: ${schedule['isActive']}');
      print('    Topic: ${schedule['mqttTopic']}');
      print('    Action: ${schedule['action']}');
      print('    ---');
    }
    print('📅 ScheduleService: === END SCHEDULES ===');
  }

  /// Get next execution time for a schedule
  String getNextExecutionTime(Map<String, dynamic> schedule) {
    if (!schedule['isRepeating']) {
      return 'Một lần';
    }

    DateTime now = DateTime.now();
    int currentWeekday = now.weekday - 1;
    List<dynamic> days = schedule['days'] ?? [];
    String scheduleTime = schedule['time'];

    // Find next execution day
    for (int i = 0; i < 7; i++) {
      int checkDay = (currentWeekday + i) % 7;
      if (days.contains(checkDay)) {
        if (i == 0) {
          // Today - check if time has passed
          String currentTime =
              '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
          if (scheduleTime.compareTo(currentTime) > 0) {
            return 'Hôm nay lúc $scheduleTime';
          }
        } else {
          List<String> dayNames = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];
          return '${dayNames[checkDay]} lúc $scheduleTime';
        }
      }
    }

    return 'Không xác định';
  }

  /// Cleanup resources
  void dispose() {
    _executionTimer?.cancel();
    _schedulesController.close();
  }
}
