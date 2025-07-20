import 'package:flutter/material.dart';
import 'package:smart_home/config/size_config.dart';
import 'package:smart_home/service/mqtt_service.dart';
import 'package:smart_home/service/gate_state_service.dart';
import 'package:smart_home/provider/getit.dart';

class GateDeviceControlWidget extends StatefulWidget {
  final String deviceName;
  final Color deviceColor;
  final VoidCallback? onTap;

  const GateDeviceControlWidget({
    Key? key,
    required this.deviceName,
    required this.deviceColor,
    this.onTap,
  }) : super(key: key);

  @override
  State<GateDeviceControlWidget> createState() => _GateDeviceControlWidgetState();
}

class _GateDeviceControlWidgetState extends State<GateDeviceControlWidget> {
  final MqttService _mqttService = getIt<MqttService>();
  final GateStateService _gateService = GateStateService();
  
  int _currentLevel = 0;
  bool _isMoving = false;
  bool _isInitialized = false;
  String _statusText = 'Đang kết nối...';

  @override
  void initState() {
    super.initState();
    _initializeWidget();
  }

  Future<void> _initializeWidget() async {
    try {
      // Load trạng thái hiện tại từ Firebase
      await _loadCurrentGateState();
      
      // Listen to MQTT gate status stream
      _listenToGateState();
      
      setState(() {
        _isInitialized = true;
        _statusText = _getGateDescription(_currentLevel);
      });

      // Request current status từ ESP32
      await _mqttService.publishGateControl(0, shouldRequestStatus: true);
    } catch (e) {
      print('Error initializing gate widget: $e');
      setState(() {
        _statusText = 'Lỗi kết nối';
        _isInitialized = true;
      });
    }
  }

  Future<void> _loadCurrentGateState() async {
    try {
      final currentState = await _gateService.getCurrentGateState();
      if (currentState != null && mounted) {
        setState(() {
          _currentLevel = currentState.level;
          _isMoving = currentState.isMoving;
        });
        print('✅ Loaded gate state: Level=${currentState.level}%, Moving=${currentState.isMoving}');
      } else {
        print('⚠️ No current gate state found, using default');
        setState(() {
          _currentLevel = 0;
          _isMoving = false;
        });
      }
    } catch (e) {
      print('❌ Error loading gate state: $e');
      setState(() {
        _currentLevel = 0;
        _isMoving = false;
      });
    }
  }

  void _listenToGateState() {
    _mqttService.gateStatusStream.listen((status) {
      if (mounted) {
        setState(() {
          _currentLevel = status['level'] ?? 0;
          _isMoving = status['isMoving'] ?? false;
          _statusText = _getGateDescription(_currentLevel);
        });
      }
    });
  }

  String _getGateDescription(int level) {
    if (_isMoving) return 'Đang di chuyển...';
    
    switch (level) {
      case 0: return 'Đóng hoàn toàn';
      case 33: return 'Mở 33% - Người đi bộ';
      case 66: return 'Mở 66% - Xe máy';
      case 100: return 'Mở hoàn toàn';
      default: 
        // Handle values based on ranges
        if (level <= 0) return 'Đóng hoàn toàn';
        if (level <= 33) return 'Mở $level% - Người đi bộ';
        if (level <= 66) return 'Mở $level% - Xe máy';
        return 'Mở $level%';
    }
  }

  String _getGateIcon(int level) {
    if (_isMoving) return '↻';
    if (level <= 0) return '━';
    if (level <= 33) return '╱';
    if (level <= 66) return '∕';
    return '┃';
  }

  Color _getGateColor(int level) {
    if (_isMoving) return Colors.orange;
    if (level <= 0) return Colors.red;
    if (level <= 33) return Colors.orange;
    if (level <= 66) return Colors.blue;
    return Colors.green;
  }

  void _showGateControlDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Row(
                children: [
                  Icon(
                    Icons.garage_outlined,
                    color: widget.deviceColor,
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.deviceName,
                      style: TextStyle(fontSize: 18),
                    ),
                  ),
                ],
              ),
              content: Container(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Current Status
                    Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _getGateColor(_currentLevel).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: _getGateColor(_currentLevel).withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Text(
                            _getGateIcon(_currentLevel),
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w300,
                              color: _getGateColor(_currentLevel),
                            ),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Trạng thái: $_currentLevel%',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                Text(
                                  _statusText,
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (_isMoving)
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  _getGateColor(_currentLevel),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    
                    SizedBox(height: 20),
                    
                    // Level Control Buttons
                    Text(
                      'Chọn mức độ mở cổng:',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    SizedBox(height: 16),
                    
                    // Modern level buttons
                    Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: _buildModernLevelButton(
                                context,
                                'Đóng cổng',
                                '0%',
                                0,
                                Colors.red,
                                setDialogState,
                              ),
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: _buildModernLevelButton(
                                context,
                                'Người đi bộ',
                                '33%',
                                33,
                                Colors.orange,
                                setDialogState,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _buildModernLevelButton(
                                context,
                                'Xe máy',
                                '66%',
                                66,
                                Colors.blue,
                                setDialogState,
                              ),
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: _buildModernLevelButton(
                                context,
                                'Mở hoàn toàn',
                                '100%',
                                100,
                                Colors.green,
                                setDialogState,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    
                    SizedBox(height: 16),
                    
                    // Emergency Stop Button
                    if (_isMoving)
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () => _stopGate(setDialogState),
                          icon: Icon(Icons.stop, color: Colors.white),
                          label: Text(
                            'DỪNG KHẨN CẤP',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            padding: EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text('Đóng'),
                ),
                if (!_isMoving)
                  ElevatedButton.icon(
                    onPressed: () => _refreshStatus(setDialogState),
                    icon: Icon(Icons.refresh, size: 16),
                    label: Text('Cập nhật'),
                  ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildModernLevelButton(
    BuildContext context,
    String title,
    String percentage,
    int level,
    Color color,
    StateSetter setDialogState,
  ) {
    final isSelected = _currentLevel == level;
    final isDisabled = _isMoving;
    
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: isSelected 
                ? color.withOpacity(0.3) 
                : Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isDisabled ? null : () => _controlGate(level, setDialogState),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: EdgeInsets.symmetric(vertical: 16, horizontal: 12),
            decoration: BoxDecoration(
              gradient: isSelected
                  ? LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        color,
                        color.withOpacity(0.8),
                      ],
                    )
                  : LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.white,
                        Colors.grey[50]!,
                      ],
                    ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected 
                    ? color.withOpacity(0.8) 
                    : (isDisabled ? Colors.grey[300]! : color.withOpacity(0.3)),
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Percentage indicator
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isSelected 
                        ? Colors.white.withOpacity(0.2) 
                        : color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    percentage,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: isSelected 
                          ? Colors.white 
                          : (isDisabled ? Colors.grey[400] : color),
                    ),
                  ),
                ),
                SizedBox(height: 8),
                // Title
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isSelected 
                        ? Colors.white 
                        : (isDisabled ? Colors.grey[400] : Colors.grey[700]),
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                
                // Selection indicator
                if (isSelected) ...[
                  SizedBox(height: 8),
                  Container(
                    width: 20,
                    height: 3,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLevelButton(
    BuildContext context,
    String label,
    int level,
    Color color,
    StateSetter setDialogState,
  ) {
    final isSelected = _currentLevel == level;
    final isDisabled = _isMoving;
    
    return ElevatedButton(
      onPressed: isDisabled
          ? null
          : () => _controlGate(level, setDialogState),
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected 
            ? color 
            : (isDisabled ? Colors.grey[300] : color.withOpacity(0.1)),
        foregroundColor: isSelected 
            ? Colors.white 
            : (isDisabled ? Colors.grey[500] : color),
        padding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  void _controlGate(int targetLevel, StateSetter setDialogState) async {
    if (_isMoving || targetLevel == _currentLevel) return;

    setDialogState(() {
      _isMoving = true;
      _statusText = 'Đang di chuyển đến $targetLevel%...';
    });

    setState(() {
      _isMoving = true;
      _statusText = 'Đang di chuyển đến $targetLevel%...';
    });

    try {
      // Send MQTT command
      await _mqttService.publishGateControl(targetLevel);
      
      // Save state to Firebase
      await _gateService.saveGateState(GateState(
        level: targetLevel,
        isMoving: true,
        timestamp: DateTime.now(),
      ));
      
      print('🚪 Gate control command sent: $targetLevel%');
    } catch (e) {
      print('❌ Error controlling gate: $e');
      setDialogState(() {
        _isMoving = false;
        _statusText = 'Lỗi điều khiển cổng';
      });
      setState(() {
        _isMoving = false;
        _statusText = 'Lỗi điều khiển cổng';
      });
    }

    // Timeout sau 15 giây
    Future.delayed(const Duration(seconds: 15), () {
      if (mounted && _isMoving) {
        setDialogState(() {
          _isMoving = false;
          _statusText = 'Hết thời gian chờ - Kiểm tra kết nối';
        });
        setState(() {
          _isMoving = false;
          _statusText = 'Hết thời gian chờ - Kiểm tra kết nối';
        });
      }
    });
  }

  void _stopGate(StateSetter setDialogState) async {
    try {
      await _mqttService.publishGateControl(-1); // -1 = stop command
      setDialogState(() {
        _isMoving = false;
        _statusText = 'Đã dừng tại $_currentLevel%';
      });
      setState(() {
        _isMoving = false;
        _statusText = 'Đã dừng tại $_currentLevel%';
      });
    } catch (e) {
      print('❌ Error stopping gate: $e');
    }
  }

  void _refreshStatus(StateSetter setDialogState) async {
    setDialogState(() {
      _statusText = 'Đang cập nhật...';
    });
    setState(() {
      _statusText = 'Đang cập nhật...';
    });

    try {
      await _mqttService.publishGateControl(0, shouldRequestStatus: true);
      await _loadCurrentGateState();
    } catch (e) {
      print('❌ Error refreshing gate status: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return GestureDetector(
        onTap: widget.onTap,
        child: Container(
          padding: EdgeInsets.all(getProportionateScreenWidth(8)),
          decoration: BoxDecoration(
            color: Colors.grey.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.grey.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              SizedBox(height: getProportionateScreenHeight(4)),
              Text(
                widget.deviceName,
                style: Theme.of(context).textTheme.bodySmall!.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[700],
                      fontSize: 11,
                    ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: getProportionateScreenHeight(2)),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: getProportionateScreenWidth(4),
                  vertical: getProportionateScreenHeight(1),
                ),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'Đang tải',
                  style: TextStyle(
                    color: Colors.orange,
                    fontSize: 8,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: _showGateControlDialog,
      child: Container(
        padding: EdgeInsets.all(getProportionateScreenWidth(8)),
        decoration: BoxDecoration(
          color: _getGateColor(_currentLevel).withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _getGateColor(_currentLevel).withOpacity(0.5),
            width: _isMoving ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Device Icon với hiệu ứng
            Container(
              padding: EdgeInsets.all(getProportionateScreenWidth(6)),
              decoration: BoxDecoration(
                color: _getGateColor(_currentLevel).withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Stack(
                children: [
                  Icon(
                    Icons.garage_outlined,
                    color: _getGateColor(_currentLevel),
                    size: 18,
                  ),
                  if (_isMoving)
                    Positioned(
                      right: -2,
                      top: -2,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: Colors.orange,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            SizedBox(height: getProportionateScreenHeight(4)),

            // Device Name
            Text(
              widget.deviceName,
              style: Theme.of(context).textTheme.bodySmall!.copyWith(
                    fontWeight: FontWeight.w600,
                    color: _getGateColor(_currentLevel),
                    fontSize: 11,
                  ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),

            SizedBox(height: getProportionateScreenHeight(2)),

            // Gate Level Indicator
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: getProportionateScreenWidth(4),
                vertical: getProportionateScreenHeight(1),
              ),
              decoration: BoxDecoration(
                color: _getGateColor(_currentLevel).withOpacity(0.2),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                _isMoving ? 'Di chuyển' : '$_currentLevel%',
                style: TextStyle(
                  color: _getGateColor(_currentLevel),
                  fontSize: 8,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),

            SizedBox(height: getProportionateScreenHeight(1)),

            // Status description
            Text(
              _getGateDescription(_currentLevel),
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 7,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}
