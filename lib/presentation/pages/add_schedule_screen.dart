import 'package:flutter/material.dart';
import 'package:smart_home/domain/entities/house_structure.dart';
import 'package:smart_home/service/schedule_service.dart';
import 'package:smart_home/provider/getit.dart';

class AddScheduleScreen extends StatefulWidget {
  const AddScheduleScreen({Key? key}) : super(key: key);

  @override
  State<AddScheduleScreen> createState() => _AddScheduleScreenState();
}

class _AddScheduleScreenState extends State<AddScheduleScreen> {
  // Form state
  SmartDevice? selectedDevice;
  String selectedAction = 'on';
  TimeOfDay selectedTime = TimeOfDay.now();
  List<int> selectedDays = [];
  bool isRepeating = true;
  String scheduleName = '';

  // Data
  List<HouseFloor> houseStructure = HouseData.getHouseStructure();
  List<String> weekDays = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];

  // Actions based on device type
  Map<String, List<Map<String, String>>> deviceActions = {
    'light': [
      {'value': 'on', 'label': 'Bật'},
      {'value': 'off', 'label': 'Tắt'},
    ],
    'fan': [
      {'value': 'on', 'label': 'Bật'},
      {'value': 'off', 'label': 'Tắt'},
    ],
    'air_conditioner': [
      {'value': 'on', 'label': 'Bật'},
      {'value': 'off', 'label': 'Tắt'},
    ],
    'gate': [
      {'value': 'open', 'label': 'Mở'},
      {'value': 'close', 'label': 'Đóng'},
    ],
  };

  // Get all devices from all floors and rooms
  List<SmartDevice> getAllDevices() {
    List<SmartDevice> allDevices = [];
    for (var floor in houseStructure) {
      for (var room in floor.rooms) {
        allDevices.addAll(room.devices);
      }
    }
    return allDevices;
  }

  @override
  void initState() {
    super.initState();
    // Set default selected days to today
    selectedDays = [DateTime.now().weekday - 1];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Thêm lịch trình'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: _canSaveSchedule() ? _saveSchedule : null,
            child: Text(
              'Lưu',
              style: TextStyle(
                color: _canSaveSchedule() ? Colors.white : Colors.white54,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            // Device Selection
            Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Thiết bị & Hành động',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: DropdownButtonFormField<SmartDevice>(
                            value: selectedDevice,
                            decoration: InputDecoration(
                              labelText: 'Chọn thiết bị',
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                            ),
                            items: getAllDevices().map((device) {
                              return DropdownMenuItem<SmartDevice>(
                                value: device,
                                child: Text(
                                  device.name,
                                  style: TextStyle(fontSize: 14),
                                ),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                selectedDevice = value;
                                selectedAction =
                                    _getAvailableActions().isNotEmpty
                                        ? _getAvailableActions().first['value']!
                                        : 'on';
                              });
                            },
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: selectedAction,
                            decoration: InputDecoration(
                              labelText: 'Hành động',
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                            ),
                            items: _getAvailableActions().map((action) {
                              return DropdownMenuItem<String>(
                                value: action['value'],
                                child: Text(action['label']!,
                                    style: TextStyle(fontSize: 14)),
                              );
                            }).toList(),
                            onChanged: selectedDevice != null
                                ? (value) {
                                    setState(() {
                                      selectedAction = value!;
                                    });
                                  }
                                : null,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: 16),

            // Time & Repeat
            Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Thời gian & Lặp lại',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: _selectTime,
                            child: Container(
                              padding: EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.access_time, size: 20),
                                  SizedBox(width: 8),
                                  Text(selectedTime.format(context)),
                                ],
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 12),
                        Switch(
                          value: isRepeating,
                          onChanged: (value) {
                            setState(() {
                              isRepeating = value;
                            });
                          },
                        ),
                        Text('Lặp lại'),
                      ],
                    ),
                    if (isRepeating) ...[
                      SizedBox(height: 12),
                      Text('Chọn ngày:', style: TextStyle(fontSize: 14)),
                      SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: weekDays.asMap().entries.map((entry) {
                          int index = entry.key;
                          String day = entry.value;
                          bool isSelected = selectedDays.contains(index);

                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                if (isSelected) {
                                  selectedDays.remove(index);
                                } else {
                                  selectedDays.add(index);
                                }
                              });
                            },
                            child: Container(
                              width: 35,
                              height: 35,
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? Theme.of(context).primaryColor
                                    : Colors.grey[200],
                                borderRadius: BorderRadius.circular(18),
                              ),
                              child: Center(
                                child: Text(
                                  day,
                                  style: TextStyle(
                                    color: isSelected
                                        ? Colors.white
                                        : Colors.black,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            SizedBox(height: 16),

            // Schedule Name (Optional)
            Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tên lịch trình (tùy chọn)',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),
                    TextField(
                      onChanged: (value) {
                        setState(() {
                          scheduleName = value;
                        });
                      },
                      decoration: InputDecoration(
                        hintText: 'VD: Tắt đèn ban đêm',
                        border: OutlineInputBorder(),
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            if (_canSaveSchedule()) ...[
              SizedBox(height: 16),
              // Preview
              Card(
                color: Colors.blue[50],
                child: Padding(
                  padding: EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${selectedDevice?.name} sẽ ${_getActionLabel()} lúc ${selectedTime.format(context)}${_getRepeatText()}',
                          style: TextStyle(
                            color: Colors.blue[800],
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // Helper methods
  List<Map<String, String>> _getAvailableActions() {
    if (selectedDevice == null) return [];
    return deviceActions[selectedDevice!.type] ??
        [
          {'value': 'on', 'label': 'Bật'},
          {'value': 'off', 'label': 'Tắt'},
        ];
  }

  String _getActionLabel() {
    List<Map<String, String>> actions = _getAvailableActions();
    return actions.firstWhere(
      (action) => action['value'] == selectedAction,
      orElse: () => {'value': selectedAction, 'label': selectedAction},
    )['label']!;
  }

  String _getRepeatText() {
    if (!isRepeating) return ' (một lần)';
    if (selectedDays.length == 7) return ' (hàng ngày)';
    if (selectedDays.isEmpty) return '';

    List<String> dayNames = selectedDays.map((day) => weekDays[day]).toList();
    return ' (${dayNames.join(', ')})';
  }

  bool _canSaveSchedule() {
    return selectedDevice != null &&
        (isRepeating ? selectedDays.isNotEmpty : true);
  }

  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: selectedTime,
    );
    if (picked != null) {
      setState(() {
        selectedTime = picked;
      });
    }
  }

  Future<void> _saveSchedule() async {
    try {
      // Generate schedule name if not provided
      String finalScheduleName = scheduleName.isEmpty
          ? '${selectedDevice?.name} - ${_getActionLabel()}'
          : scheduleName;

      // Create schedule data
      Map<String, dynamic> scheduleData = {
        'id': 'schedule_${DateTime.now().millisecondsSinceEpoch}',
        'name': finalScheduleName,
        'deviceName': selectedDevice!.name,
        'deviceId': _getDeviceId(selectedDevice!),
        'mqttTopic': selectedDevice!.mqttTopic,
        'action': selectedAction,
        'time':
            '${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}',
        'isRepeating': isRepeating,
        'days': selectedDays,
        'isActive': true,
        'createdAt': DateTime.now().toIso8601String(),
      };

      // Save using ScheduleService
      ScheduleService scheduleService = getIt<ScheduleService>();
      await scheduleService.addSchedule(scheduleData);

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lịch trình "$finalScheduleName" đã được lưu!'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );

      // Return to previous screen
      Navigator.pop(context, true); // Return true to indicate success
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi khi lưu lịch trình: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Generate device ID based on MQTT topic
  String _getDeviceId(SmartDevice device) {
    String topic = device.mqttTopic;
    if (topic.contains('/')) {
      return topic.split('/').last;
    }
    return topic;
  }
}
