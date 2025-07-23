import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../service/device_manager_service.dart';
import '../../../../view/home_screen_view_model.dart';

/// OPTIMIZED Active Devices Widget
/// - Không cần real-time updates
/// - Check đơn giản để giảm tải
/// - Lấy chi tiết trạng thái tất cả thiết bị
class ActiveDevicesWidgetOptimized extends StatefulWidget {
  final HomeScreenViewModel model;
  
  const ActiveDevicesWidgetOptimized({
    super.key, 
    required this.model,
  });

  @override
  State<ActiveDevicesWidgetOptimized> createState() => _ActiveDevicesWidgetOptimizedState();
}

class _ActiveDevicesWidgetOptimizedState extends State<ActiveDevicesWidgetOptimized> {
  List<Map<String, dynamic>> _cachedDevices = [];
  bool _isLoading = true;
  DateTime? _lastUpdate;
  
  // Tối ưu: Chỉ refresh khi cần thiết (30 giây)
  static const Duration _refreshInterval = Duration(seconds: 30);

  @override
  void initState() {
    super.initState();
    _loadDevicesOnce();
  }

  /// Load devices một lần duy nhất khi khởi tạo
  Future<void> _loadDevicesOnce() async {
    try {
      final devices = await _getAllDevicesSimple();
      if (mounted) {
        setState(() {
          _cachedDevices = devices;
          _isLoading = false;
          _lastUpdate = DateTime.now();
        });
      }
    } catch (e) {
      print('Error loading devices: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// Refresh manual hoặc khi cần thiết
  Future<void> _refreshDevices() async {
    if (!mounted) return;
    
    // Kiểm tra xem có cần refresh không (sau 30 giây)
    if (_lastUpdate != null && 
        DateTime.now().difference(_lastUpdate!) < _refreshInterval) {
      return; // Không cần refresh quá sớm
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // OPTIMIZED: Clear cache trước khi refresh để có dữ liệu mới
      widget.model.mqttServiceSimple.optimizedStatusService.clearCache();
      
      final devices = await _getAllDevicesSimple();
      if (mounted) {
        setState(() {
          _cachedDevices = devices;
          _isLoading = false;
          _lastUpdate = DateTime.now();
        });
      }
    } catch (e) {
      print('Error refreshing devices: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// Lấy tất cả thiết bị với logic đơn giản
  Future<List<Map<String, dynamic>>> _getAllDevicesSimple() async {
    final List<Map<String, dynamic>> devices = [];

    try {
      // 1. ESP32 Outdoor Devices - Fixed states
      final outdoorDevices = [
        {
          'name': 'LED Cổng',
          'type': 'light',
          'topic': 'khoasmarthome/led_gate',
          'state': _getSimpleDeviceState('led_gate'),
          'category': 'outdoor',
          'isControllable': true,
        },
        {
          'name': 'LED Sân',
          'type': 'light', 
          'topic': 'khoasmarthome/led_around',
          'state': _getSimpleDeviceState('led_around'),
          'category': 'outdoor',
          'isControllable': true,
        },
        {
          'name': 'Cổng Tự Động',
          'type': 'gate',
          'topic': 'khoasmarthome/motor',
          'state': widget.model.currentGateLevel > 0,
          'category': 'outdoor',
          'isControllable': true,
          'details': '${widget.model.currentGateLevel}% mở',
        },
      ];

      devices.addAll(outdoorDevices);

      // 2. ESP32-S3 Indoor Devices - Tầng 1
      final floor1Devices = [
        {
          'name': 'Đèn Bếp',
          'type': 'light',
          'topic': 'inside/kitchen_light',
          'state': widget.model.isKitchenLightOn,
          'category': 'floor1',
          'isControllable': true,
        },
        {
          'name': 'Đèn Phòng Khách',
          'type': 'light',
          'topic': 'inside/living_room_light', 
          'state': widget.model.isLivingRoomLightOn,
          'category': 'floor1',
          'isControllable': true,
        },
        {
          'name': 'Đèn Phòng Ngủ',
          'type': 'light',
          'topic': 'inside/bedroom_light',
          'state': widget.model.isBedroomLightOn,
          'category': 'floor1',
          'isControllable': true,
        },
        {
          'name': 'Quạt Phòng Khách',
          'type': 'fan',
          'topic': 'inside/fan_living_room',
          'state': widget.model.isFanLivingRoomOn,
          'category': 'floor1',
          'isControllable': true,
        },
        {
          'name': 'Điều Hòa PK',
          'type': 'air_conditioner',
          'topic': 'inside/ac_living_room',
          'state': widget.model.isACLivingRoomOn,
          'category': 'floor1',
          'isControllable': true,
        },
      ];

      devices.addAll(floor1Devices);

      // 3. ESP32-S3 Indoor Devices - Tầng 2
      final floor2Devices = [
        {
          'name': 'Đèn PN Góc',
          'type': 'light',
          'topic': 'inside/corner_bedroom_light',
          'state': widget.model.isCornerBedroomLightOn,
          'category': 'floor2',
          'isControllable': true,
        },
        {
          'name': 'Đèn PN Sân',
          'type': 'light',
          'topic': 'inside/yard_bedroom_light',
          'state': widget.model.isYardBedroomLightOn,
          'category': 'floor2',
          'isControllable': true,
        },
        {
          'name': 'Đèn Phòng Thờ',
          'type': 'light',
          'topic': 'inside/worship_room_light',
          'state': widget.model.isWorshipRoomLightOn,
          'category': 'floor2',
          'isControllable': true,
        },
        {
          'name': 'Đèn Hành Lang',
          'type': 'light',
          'topic': 'inside/hallway_light',
          'state': widget.model.isHallwayLightOn,
          'category': 'floor2',
          'isControllable': true,
        },
        {
          'name': 'Đèn Ban Công',
          'type': 'light',
          'topic': 'inside/balcony_light',
          'state': widget.model.isBalconyLightOn,
          'category': 'floor2',
          'isControllable': true,
        },
        {
          'name': 'Điều Hòa PN1',
          'type': 'air_conditioner',
          'topic': 'inside/ac_bedroom1',
          'state': widget.model.isACBedroom1On,
          'category': 'floor2',
          'isControllable': true,
        },
        {
          'name': 'Điều Hòa PN2',
          'type': 'air_conditioner',
          'topic': 'inside/ac_bedroom2',
          'state': widget.model.isACBedroom2On,
          'category': 'floor2',
          'isControllable': true,
        },
      ];

      devices.addAll(floor2Devices);

      // 4. User Added Devices (if any)
      try {
        final deviceManager = DeviceManagerService();
        final userDevices = await deviceManager.getUserDevices();
        for (final userDevice in userDevices) {
          devices.add({
            'name': userDevice.device.name,
            'type': userDevice.device.type,
            'topic': userDevice.device.mqttTopic,
            'state': userDevice.device.isOn,
            'category': 'user',
            'isControllable': true,
            'isUserDevice': true,
          });
        }
      } catch (e) {
        print('Error loading user devices: $e');
      }

    } catch (e) {
      print('Error in _getAllDevicesSimple: $e');
    }

    return devices;
  }

  /// Lấy trạng thái thiết bị đơn giản (không real-time)
  bool _getSimpleDeviceState(String deviceId) {
    try {
      // OPTIMIZED: Sử dụng cached service trước, fallback to DeviceStateService
      final optimizedService = widget.model.mqttServiceSimple.optimizedStatusService;
      final fallbackService = widget.model.mqttServiceSimple.deviceStateService;
      
      // Thử lấy từ optimized cache trước
      final cachedState = optimizedService.getDeviceState(deviceId);
      if (optimizedService.isCacheValid(deviceId)) {
        return cachedState;
      }
      
      // Fallback to DeviceStateService và cập nhật cache
      final actualState = fallbackService.getDeviceState(deviceId);
      optimizedService.updateDeviceState(deviceId, actualState);
      return actualState;
    } catch (e) {
      print('Error getting device state for $deviceId: $e');
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header với nút refresh - FIXED: Đơn giản hóa
          Row(
            children: [
              Icon(
                Icons.devices,
                color: Colors.blue[600],
                size: 18,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Thiết Bị Hoạt Động',
                  style: TextStyle(
                    color: Colors.grey[800],
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              // Compact controls
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Thời gian cập nhật
                  if (_lastUpdate != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _formatLastUpdate(),
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  const SizedBox(width: 4),
                  // Nút refresh
                  GestureDetector(
                    onTap: _refreshDevices,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.refresh,
                        color: Colors.blue[600],
                        size: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          
          const SizedBox(height: 12),

          // Loading state - FIXED: Đơn giản hóa
          if (_isLoading)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.blue[600]!),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Đang tải...',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else if (_cachedDevices.isEmpty)
            // Empty state - FIXED: Clean hơn
            Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Icon(
                      Icons.devices_other_outlined,
                      color: Colors.grey[400],
                      size: 24,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Không có thiết bị nào',
                      style: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            // Device list - FIXED: Gọn gàng hơn
            Column(
              children: [
                // Summary statistics - FIXED: Compact hơn
                _buildDeviceSummary(),
                const SizedBox(height: 12),
                
                // Device categories - FIXED: Spacing tốt hơn
                ..._buildDeviceCategories(),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildDeviceSummary() {
    final activeCount = _cachedDevices.where((d) => d['state'] == true).length;
    final totalCount = _cachedDevices.length;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.blue[100]!,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.blue[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.analytics_outlined,
              color: Colors.blue[600],
              size: 14,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '$activeCount/$totalCount thiết bị hoạt động',
              style: TextStyle(
                color: Colors.grey[700],
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: activeCount > 0 ? Colors.green[500] : Colors.grey[400],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              totalCount > 0 ? '${((activeCount / totalCount) * 100).toInt()}%' : '0%',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildDeviceCategories() {
    final categories = <String, List<Map<String, dynamic>>>{};
    
    // Group devices by category
    for (final device in _cachedDevices) {
      final category = device['category'] ?? 'other';
      categories[category] ??= [];
      categories[category]!.add(device);
    }

    final widgets = <Widget>[];

    // Category order and names
    final categoryOrder = {
      'outdoor': 'Ngoài Trời',
      'floor1': 'Tầng 1',
      'floor2': 'Tầng 2', 
      'user': 'Thiết Bị Tùy Chỉnh',
      'other': 'Khác',
    };

    for (final categoryKey in categoryOrder.keys) {
      final devices = categories[categoryKey];
      if (devices == null || devices.isEmpty) continue;

      widgets.add(_buildCategorySection(
        categoryOrder[categoryKey]!,
        devices,
      ));
      widgets.add(const SizedBox(height: 12));
    }

    return widgets;
  }

  Widget _buildCategorySection(String title, List<Map<String, dynamic>> devices) {
    final activeDevices = devices.where((d) => d['state'] == true).toList();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Category header - FIXED: Đơn giản hóa và tránh overflow
        Row(
          children: [
            Container(
              width: 3,
              height: 14,
              decoration: BoxDecoration(
                color: Colors.blue[400],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: Colors.grey[700],
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${activeDevices.length}/${devices.length}',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 8),
        
        // Devices in this category - FIXED: Chỉ hiển thị active devices để gọn
        if (activeDevices.isNotEmpty)
          ...activeDevices.take(3).map((device) => _buildDeviceItem(device)) // Limit 3 items
        else
          Padding(
            padding: const EdgeInsets.only(left: 16),
            child: Text(
              'Không có thiết bị nào hoạt động',
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 11,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        
        // Show more indicator if there are more than 3 active devices
        if (activeDevices.length > 3)
          Padding(
            padding: const EdgeInsets.only(left: 16, top: 4),
            child: Text(
              '+${activeDevices.length - 3} thiết bị khác',
              style: TextStyle(
                color: Colors.blue[600],
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildDeviceItem(Map<String, dynamic> device) {
    final isOn = device['state'] == true;
    final deviceType = device['type'] ?? 'unknown';
    final deviceName = device['name'] ?? 'Unknown Device';
    final details = device['details'];

    return Container(
      margin: const EdgeInsets.only(bottom: 4, left: 16),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isOn 
          ? Colors.green[50]
          : Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isOn 
            ? Colors.green[200]!
            : Colors.grey[200]!,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // Device icon - FIXED: Smaller và clean
          Icon(
            _getDeviceIcon(deviceType),
            color: isOn ? Colors.green[600] : Colors.grey[500],
            size: 14,
          ),
          const SizedBox(width: 8),
          
          // Device info - FIXED: Tránh overflow
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  deviceName,
                  style: TextStyle(
                    color: Colors.grey[700],
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                if (details != null)
                  Text(
                    details,
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 10,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          
          // Status indicator - FIXED: Smaller
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: isOn ? Colors.green[500] : Colors.grey[400],
              borderRadius: BorderRadius.circular(3),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getDeviceIcon(String deviceType) {
    switch (deviceType.toLowerCase()) {
      case 'light':
        return Icons.lightbulb_outline;
      case 'fan':
        return Icons.air;
      case 'air_conditioner':
        return Icons.ac_unit;
      case 'gate':
        return Icons.garage_outlined;
      case 'motor':
        return Icons.settings;
      case 'speaker':
        return Icons.speaker;
      case 'tv':
        return Icons.tv;
      default:
        return Icons.device_unknown;
    }
  }

  String _formatLastUpdate() {
    if (_lastUpdate == null) return '';
    
    final now = DateTime.now();
    final diff = now.difference(_lastUpdate!);
    
    if (diff.inMinutes < 1) {
      return 'Vừa cập nhật';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes}p';
    } else {
      return '${diff.inHours}h';
    }
  }

  @override
  void dispose() {
    // Không cần dispose timer vì không có timer
    super.dispose();
  }
}
