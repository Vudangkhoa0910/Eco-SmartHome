import 'package:flutter/material.dart';
import 'package:smart_home/presentation/pages/add_schedule_screen.dart';
import 'package:smart_home/service/schedule_service.dart';
import 'package:smart_home/provider/getit.dart';

class ScheduleManagementScreen extends StatefulWidget {
  const ScheduleManagementScreen({Key? key}) : super(key: key);

  @override
  State<ScheduleManagementScreen> createState() =>
      _ScheduleManagementScreenState();
}

class _ScheduleManagementScreenState extends State<ScheduleManagementScreen> {
  late ScheduleService _scheduleService;
  List<Map<String, dynamic>> schedules = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _scheduleService = getIt<ScheduleService>();
    _loadSchedules();

    // Listen to schedule changes
    _scheduleService.schedulesStream.listen((updatedSchedules) {
      if (mounted) {
        setState(() {
          schedules = updatedSchedules;
        });
      }
    });
  }

  Future<void> _loadSchedules() async {
    setState(() {
      schedules = _scheduleService.schedules;
      isLoading = false;
    });
  }

  Future<void> _toggleSchedule(int index) async {
    try {
      String scheduleId = schedules[index]['id'];
      await _scheduleService.toggleSchedule(scheduleId);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(schedules[index]['isActive']
              ? 'Lịch trình đã được bật'
              : 'Lịch trình đã được tắt'),
          duration: Duration(seconds: 1),
        ),
      );
    } catch (e) {
      print('Error toggling schedule: $e');
    }
  }

  Future<void> _deleteSchedule(int index) async {
    try {
      String scheduleName = schedules[index]['name'];
      String scheduleId = schedules[index]['id'];

      await _scheduleService.removeSchedule(scheduleId);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Đã xóa lịch trình "$scheduleName"'),
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      print('Error deleting schedule: $e');
    }
  }

  String _formatDays(List<dynamic> days) {
    if (days.isEmpty) return 'Hàng ngày';

    List<String> dayNames = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];
    List<String> selectedDays = days.map((day) => dayNames[day]).toList();

    if (selectedDays.length == 7) return 'Hàng ngày';
    return selectedDays.join(', ');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Lập lịch thiết bị'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Container(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              elevation: 4,
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(
                      Icons.schedule,
                      color: Theme.of(context).primaryColor,
                      size: 32,
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Quản lý lịch trình',
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Tạo và quản lý lịch trình tự động cho các thiết bị',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: Colors.grey[600],
                                ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AddScheduleScreen(),
                  ),
                );

                // Reload schedules if a new one was added
                if (result == true) {
                  _loadSchedules();
                }
              },
              icon: Icon(Icons.add),
              label: Text('Thêm lịch trình mới'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
                minimumSize: Size(double.infinity, 48),
              ),
            ),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Lịch trình hiện tại',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                Text(
                  '${schedules.length} lịch trình',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                ),
              ],
            ),
            SizedBox(height: 12),
            Expanded(
              child: isLoading
                  ? Center(child: CircularProgressIndicator())
                  : schedules.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.schedule_outlined,
                                size: 64,
                                color: Colors.grey[400],
                              ),
                              SizedBox(height: 16),
                              Text(
                                'Chưa có lịch trình nào',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey[600],
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Thêm lịch trình đầu tiên của bạn',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[500],
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          itemCount: schedules.length,
                          itemBuilder: (context, index) {
                            final schedule = schedules[index];
                            return _buildScheduleCard(schedule, index);
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScheduleCard(Map<String, dynamic> schedule, int index) {
    bool isActive = schedule['isActive'] ?? true;
    bool isRepeating = schedule['isRepeating'] ?? true;

    return Card(
      margin: EdgeInsets.only(bottom: 8),
      elevation: isActive ? 2 : 1,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isActive ? Colors.green : Colors.grey,
          child: Icon(
            _getDeviceIcon(schedule['deviceName']),
            color: Colors.white,
            size: 20,
          ),
        ),
        title: Text(
          schedule['name'] ?? schedule['deviceName'],
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: isActive ? Colors.black : Colors.grey[600],
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${schedule['deviceName']} - ${schedule['action']}'),
            Text(
              isRepeating
                  ? '${schedule['time']} (${_formatDays(schedule['days'] ?? [])})'
                  : '${schedule['time']} (một lần)',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Switch(
              value: isActive,
              onChanged: (value) => _toggleSchedule(index),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            IconButton(
              icon: Icon(Icons.delete_outline, color: Colors.red),
              onPressed: () => _showDeleteConfirmation(index),
              constraints: BoxConstraints(),
              padding: EdgeInsets.all(8),
            ),
          ],
        ),
        isThreeLine: true,
      ),
    );
  }

  IconData _getDeviceIcon(String deviceName) {
    if (deviceName.contains('Đèn')) return Icons.lightbulb_outline;
    if (deviceName.contains('Quạt')) return Icons.air;
    if (deviceName.contains('Điều hòa')) return Icons.ac_unit;
    if (deviceName.contains('Cổng')) return Icons.garage_outlined;
    return Icons.device_unknown;
  }

  void _showDeleteConfirmation(int index) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Xác nhận xóa'),
          content: Text(
              'Bạn có chắc chắn muốn xóa lịch trình "${schedules[index]['name']}"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Hủy'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _deleteSchedule(index);
              },
              child: Text('Xóa', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }
}
