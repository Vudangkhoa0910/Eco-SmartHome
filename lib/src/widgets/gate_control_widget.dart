import 'package:flutter/material.dart';
import 'package:smart_home/service/mqtt_service.dart';
import 'package:smart_home/service/gate_state_service.dart';

class GateControlWidget extends StatefulWidget {
  const GateControlWidget({Key? key}) : super(key: key);

  @override
  State<GateControlWidget> createState() => _GateControlWidgetState();
}

class _GateControlWidgetState extends State<GateControlWidget> {
  final MqttService _mqttService = MqttService();
  final GateStateService _gateService = GateStateService();
  int _currentLevel = 0;
  bool _isMoving = false;
  bool _isInitialized = false;
  String _statusText = 'Đang kết nối...';

  @override
  void initState() {
    super.initState();
    _initializeGateControl();
  }

  Future<void> _initializeGateControl() async {
    // Khởi tạo MQTT service trước
    try {
      await _mqttService.connect();
      await _loadCurrentGateState();
      _listenToGateState();
      _listenToMqttConnection();
      
      setState(() {
        _isInitialized = true;
        _statusText = _getGateDescription(_currentLevel);
      });
    } catch (e) {
      print('Error initializing gate control: $e');
      setState(() {
        _statusText = 'Lỗi kết nối';
      });
    }
  }

  Future<void> _loadCurrentGateState() async {
    try {
      // Load state từ Firebase
      final currentState = await _gateService.getCurrentGateState();
      setState(() {
        _currentLevel = currentState.level;
        _isMoving = currentState.isMoving;
      });
      
      // Publish current state request để get real-time từ ESP32
      await _mqttService.publishGateControl(0, shouldRequestStatus: true);
    } catch (e) {
      print('Error loading gate state: $e');
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

  void _listenToMqttConnection() {
    _mqttService.connectionStatusStream.listen((isConnected) {
      if (mounted && !isConnected) {
        setState(() {
          _statusText = 'Mất kết nối MQTT';
        });
      }
    });
  }

  void _controlGate(int targetLevel) {
    if (_isMoving || targetLevel == _currentLevel) return;
    
    setState(() {
      _isMoving = true;
      _statusText = 'Đang di chuyển đến $targetLevel%...';
    });
    
    // Gửi command qua MQTT
    _mqttService.publishGateControl(targetLevel);
    
    // Save state to Firebase
    _gateService.saveGateState(GateState(
      level: targetLevel,
      isMoving: true,
      status: GateStatus.opening,
      timestamp: DateTime.now(),
    ));
    
    // Timeout sau 10 giây nếu không nhận được response
    Future.delayed(const Duration(seconds: 10), () {
      if (mounted && _isMoving) {
        setState(() {
          _isMoving = false;
          _statusText = 'Hết thời gian chờ - Vui lòng kiểm tra kết nối';
        });
      }
    });
  }

  void _stopGate() {
    _mqttService.publishGateControl(-1); // -1 = stop command
    setState(() {
      _isMoving = false;
      _statusText = 'Đã dừng tại $_currentLevel%';
    });
  }

  void _refreshStatus() {
    _mqttService.publishGateControl(0, shouldRequestStatus: true);
    setState(() {
      _statusText = 'Đang cập nhật trạng thái...';
    });
  }

  String _getGateDescription(int level) {
    if (_isMoving) return 'Đang di chuyển...';
    
    switch (level) {
      case 0:
        return 'Đóng hoàn toàn';
      case 25:
        return 'Mở 1/4 - Người đi bộ';
      case 50:
        return 'Mở 1/2 - Xe máy';
      case 75:
        return 'Mở 3/4 - Xe hơi nhỏ';
      case 100:
        return 'Mở hoàn toàn - Xe tải';
      default:
        return 'Mở $level%';
    }
  }

  Color _getLevelColor(int level) {
    if (level <= 0) return Colors.red;
    if (level <= 25) return Colors.orange;
    if (level <= 50) return Colors.blue;
    if (level <= 75) return Colors.lightGreen;
    return Colors.green;
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return Card(
        elevation: 4,
        margin: const EdgeInsets.all(8),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text(_statusText),
            ],
          ),
        ),
      );
    }

    return Card(
      elevation: 4,
      margin: const EdgeInsets.all(8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header với status real-time
            Row(
              children: [
                Icon(
                  _currentLevel == 0 ? Icons.lock : Icons.lock_open,
                  color: _currentLevel == 0 ? Colors.red : Colors.green,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Cổng chính',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _isMoving ? Colors.orange : Colors.green,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _statusText,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (_isMoving)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),
            
            const SizedBox(height: 20),
            
            // Slider để chọn mức độ mở (0-100%)
            Text(
              'Chọn mức độ mở: $_currentLevel%',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 12),
            
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: _getLevelColor(_currentLevel),
                thumbColor: _getLevelColor(_currentLevel),
                overlayColor: _getLevelColor(_currentLevel).withOpacity(0.32),
                valueIndicatorColor: _getLevelColor(_currentLevel),
                valueIndicatorTextStyle: TextStyle(color: Colors.white),
              ),
              child: Slider(
                value: _currentLevel.toDouble(),
                min: 0,
                max: 100,
                divisions: 4, // 0, 25, 50, 75, 100
                label: _getGateDescription(_currentLevel),
                onChanged: _isMoving ? null : (value) {
                  setState(() {
                    _currentLevel = value.round();
                  });
                },
                onChangeEnd: _isMoving ? null : (value) {
                  _controlGate(value.round());
                },
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Quick action buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildQuickButton('🔒 Đóng', 0, color: Colors.red),
                _buildQuickButton('🚶 1/4', 25, color: Colors.orange),
                _buildQuickButton('🏍️ 1/2', 50, color: Colors.blue),
                _buildQuickButton('🚗 Mở', 100, color: Colors.green),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Control buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isMoving ? _stopGate : null,
                    icon: const Icon(Icons.stop, size: 16),
                    label: const Text('Dừng'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red[100],
                      foregroundColor: Colors.red[700],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isMoving ? null : _refreshStatus,
                    icon: const Icon(Icons.refresh, size: 16),
                    label: const Text('Cập nhật'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[100],
                      foregroundColor: Colors.blue[700],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickButton(String label, int level, {required Color color}) {
    final isSelected = _currentLevel == level;
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2),
        child: ElevatedButton(
          onPressed: _isMoving ? null : () => _controlGate(level),
          style: ElevatedButton.styleFrom(
            backgroundColor: isSelected ? color : color.withOpacity(0.2),
            foregroundColor: isSelected ? Colors.white : color,
            padding: EdgeInsets.symmetric(vertical: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
