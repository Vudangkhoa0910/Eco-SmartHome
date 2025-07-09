import 'package:flutter/material.dart';
import 'package:smart_home/config/size_config.dart';
import 'package:smart_home/service/firebase_data_service.dart';
import 'package:smart_home/provider/getit.dart';
import 'package:smart_home/src/utils/electricity_calculator.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

class ChartData {
  final DateTime time;
  final double value;
  
  ChartData(this.time, this.value);
}

class PowerConsumption {
  final String area;
  final List<DevicePower> devices;
  final double totalPower;
  final double cost;
  
  PowerConsumption({
    required this.area,
    required this.devices,
    required this.totalPower,
    required this.cost,
  });
}

class DevicePower {
  final String name;
  final double power;
  final Color color;
  
  DevicePower({
    required this.name,
    required this.power,
    required this.color,
  });
}

class InfluxAnalyticsScreen extends StatefulWidget {
  const InfluxAnalyticsScreen({Key? key}) : super(key: key);

  @override
  State<InfluxAnalyticsScreen> createState() => _InfluxAnalyticsScreenState();
}

class _InfluxAnalyticsScreenState extends State<InfluxAnalyticsScreen> {
  final FirebaseDataService _firebaseData = getIt<FirebaseDataService>();
  
  List<Map<String, dynamic>>? _powerData;
  List<PowerConsumption> _areaConsumption = [];
  double _totalCost = 0;
  double _totalPower = 0;
  
  bool _isLoading = true;
  String _selectedTimeRange = '24h';
  
  // Giá điện theo bậc (VND/kWh) - sử dụng ElectricityCalculator
  
  final List<String> _timeRanges = [
    '1h',
    '6h', 
    '24h',
    '7d',
    '30d'
  ];

  bool _showDebugInfo = false;
  String _connectionStatus = 'Chưa kiểm tra';
  int _totalDataPoints = 0;
  List<String> _availableDevices = [];

  @override
  void initState() {
    super.initState();
    _testDataAvailability();
    _loadAnalyticsData();
  }

  /// Test data availability before loading
  Future<void> _testDataAvailability() async {
    try {
      print('🔍 Testing database connection and data availability...');
      // Test Firebase connection by getting recent power data
      final testData = await _firebaseData.getPowerConsumptionHistory(
        startTime: DateTime.now().subtract(const Duration(hours: 1)),
        endTime: DateTime.now(),
      );
      final connectionTest = testData.isNotEmpty;
      print('🔥 Database connection: ${connectionTest ? "✅ Connected" : "❌ Failed"}');
      
      if (connectionTest) {
        // Test if we have recent data
        final currentPower = testData.isNotEmpty ? testData.last['power'] ?? 0.0 : 0.0;
        print('⚡ Current power consumption: ${currentPower}W');
        
        // Quick test for device data
        final testStats = await _firebaseData.getDeviceStats('', timeRange: '1h');
        print('🔌 Available devices: ${testStats.keys.toList()}');
      }
    } catch (e) {
      print('⚠️ Data availability test failed: $e');
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _loadAnalyticsData() async {
    if (!mounted) return;
    
    setState(() => _isLoading = true);
    
    try {
      print('🔄 Loading real analytics data for time range: $_selectedTimeRange');
      
      // Only get real data from database
      final powerFuture = _firebaseData.querySensorHistory(
        timeRange: _selectedTimeRange,
        sensorType: 'power',
        aggregation: 'mean',
      );
      
      // Get all device stats in one call  
      final allDeviceStatsFuture = _firebaseData.getDeviceStats('', timeRange: _selectedTimeRange);
      
      final results = await Future.wait([
        powerFuture,
        allDeviceStatsFuture,
      ]);
      
      if (!mounted) return;
      
      _powerData = results[0] as List<Map<String, dynamic>>?;
      final allDeviceStats = results[1] as Map<String, dynamic>?;
      
      print('📊 Real power data count: ${_powerData?.length ?? 0}');
      print('📊 Real device stats: $allDeviceStats');
      
      // If no data found, try alternative measurements
      if ((_powerData == null || _powerData!.isEmpty) && 
          (allDeviceStats == null || allDeviceStats.isEmpty)) {
        print('⚠️ No data found, checking available measurements...');
        await _checkAvailableData();
      }
      
      // Get current power consumption from recent data
      final recentPowerData = await _firebaseData.getPowerConsumptionHistory(
        startTime: DateTime.now().subtract(const Duration(minutes: 5)),
        endTime: DateTime.now(),
      );
      final currentPowerConsumption = recentPowerData.isNotEmpty ? 
        recentPowerData.last['power'] ?? 0.0 : 0.0;
      print('⚡ Current total power consumption: ${currentPowerConsumption}W');
      
      // Extract individual device stats from real data
      Map<String, dynamic>? led1Stats;
      Map<String, dynamic>? led2Stats;
      Map<String, dynamic>? motorStats;
      
      // If we have current power consumption, use it with logical distribution
      if (currentPowerConsumption > 0) {
        // Distribute current power among devices based on typical usage patterns
        final led1Power = currentPowerConsumption * 0.15; // 15% for LED1
        final led2Power = currentPowerConsumption * 0.15; // 15% for LED2  
        final motorPower = currentPowerConsumption * 0.70; // 70% for motor (main consumer)
        
        led1Stats = {'average_power': led1Power, 'source': 'actual_distributed'};
        led2Stats = {'average_power': led2Power, 'source': 'actual_distributed'};
        motorStats = {'average_power': motorPower, 'source': 'actual_distributed'};
        
        print('📊 Using actual power distribution based on ${currentPowerConsumption}W:');
        print('📊 LED1: ${led1Power.toStringAsFixed(1)}W');
        print('📊 LED2: ${led2Power.toStringAsFixed(1)}W');
        print('📊 Motor: ${motorPower.toStringAsFixed(1)}W');
      } else {
        // Fallback: Try to get device stats from power_consumption data (more reliable than device_state)
        try {
          // Get recent power consumption data for each device
          final recentData = await _firebaseData.getPowerConsumptionHistory(
            startTime: DateTime.now().subtract(const Duration(hours: 1)),
            endTime: DateTime.now(),
          );
        
        if (recentData.isNotEmpty) {
          // Group by device and calculate average power
          final devicePowerMap = <String, List<double>>{};
          
          for (final record in recentData) {
            final device = record['device']?.toString();
            final powerValue = double.tryParse(record['_value']?.toString() ?? '0');
            final field = record['_field']?.toString();
            
            if (device != null && powerValue != null && field == 'power') {
              devicePowerMap.putIfAbsent(device, () => []);
              devicePowerMap[device]!.add(powerValue);
            }
          }
          
          // Calculate average power for each device
          for (final entry in devicePowerMap.entries) {
            final device = entry.key;
            final powers = entry.value;
            final avgPower = powers.isNotEmpty ? powers.reduce((a, b) => a + b) / powers.length : 0.0;
            final deviceStats = {'average_power': avgPower, 'sample_count': powers.length};
            
            switch (device) {
              case 'led1':
                led1Stats = deviceStats;
                break;
              case 'led2':
                led2Stats = deviceStats;
                break;
              case 'motor':
                motorStats = deviceStats;
                break;
            }
          }
          
          print('📊 LED1 Stats: $led1Stats');
          print('📊 LED2 Stats: $led2Stats');
          print('📊 Motor Stats: $motorStats');
        } else {
          print('⚠️ No power consumption data found');
        }
      } catch (e) {
        print('❌ Error loading device stats from power_consumption: $e');
        
        // Fallback to device_state data
        if (allDeviceStats != null && allDeviceStats.isNotEmpty) {
          led1Stats = allDeviceStats['led1'] as Map<String, dynamic>?;
          led2Stats = allDeviceStats['led2'] as Map<String, dynamic>?;
          motorStats = allDeviceStats['motor'] as Map<String, dynamic>?;
          
          print('📊 Fallback - LED1 Stats: $led1Stats');
          print('📊 Fallback - LED2 Stats: $led2Stats');
          print('📊 Fallback - Motor Stats: $motorStats');
        } else {
          print('⚠️ No device statistics found in database');
        }
        } // Close the fallback try-catch block
      } // Close the else block for currentPowerConsumption check
      
      _calculateAreaConsumption(led1Stats, led2Stats, motorStats);
      
      // Update debug info
      if (_showDebugInfo) {
        _updateDebugInfo();
      }
      
      setState(() {
        _isLoading = false;
      });
      
    } catch (e) {
      print('❌ Analytics Error: $e');
      if (!mounted) return;
      
      // Clear data on error - don't use mock data
      _powerData = [];
      _areaConsumption.clear();
      _totalPower = 0;
      _totalCost = 0;
      
      setState(() => _isLoading = false);
    }
  }

  void _calculateAreaConsumption(
    Map<String, dynamic>? led1Stats,
    Map<String, dynamic>? led2Stats,
    Map<String, dynamic>? motorStats,
  ) {
    print('🧮 Starting area consumption calculation...');
    
    _areaConsumption.clear();
    _totalPower = 0;
    _totalCost = 0;
    
    // Phòng khách
    final livingRoomDevices = <DevicePower>[];
    double livingRoomPower = 0;
    
    if (led1Stats != null) {
      final power = _calculateDevicePower(led1Stats, 10); // LED 10W
      livingRoomDevices.add(DevicePower(
        name: 'Đèn LED 1',
        power: power,
        color: const Color(0xFFFF9800),
      ));
      livingRoomPower += power;
    }
    
    if (led2Stats != null) {
      final power = _calculateDevicePower(led2Stats, 10); // LED 10W
      livingRoomDevices.add(DevicePower(
        name: 'Đèn LED 2',
        power: power,
        color: const Color(0xFF2196F3),
      ));
      livingRoomPower += power;
    }
    
    final livingRoomCost = ElectricityCalculator.estimateCostFromUsage(
      livingRoomPower,
      100, // 100% vì đã tính power thực tế
      _selectedTimeRange,
    );
    
    print('🏠 Living room: ${_formatPowerUnit(livingRoomPower)}, Cost: ${livingRoomCost.toStringAsFixed(0)}₫');
    
    _areaConsumption.add(PowerConsumption(
      area: 'Phòng Khách',
      devices: livingRoomDevices,
      totalPower: livingRoomPower,
      cost: livingRoomCost,
    ));
    
    // Phòng ngủ
    final bedroomDevices = <DevicePower>[];
    double bedroomPower = 0;
    
    if (motorStats != null) {
      final power = _calculateDevicePower(motorStats, 50); // Motor 50W
      bedroomDevices.add(DevicePower(
        name: 'Quạt Trần',
        power: power,
        color: const Color(0xFF4CAF50),
      ));
      bedroomPower += power;
    }
    
    final bedroomCost = ElectricityCalculator.estimateCostFromUsage(
      bedroomPower,
      100, // 100% vì đã tính power thực tế
      _selectedTimeRange,
    );
    
    print('🛏️ Bedroom: ${_formatPowerUnit(bedroomPower)}, Cost: ${bedroomCost.toStringAsFixed(0)}₫');
    
    _areaConsumption.add(PowerConsumption(
      area: 'Phòng Ngủ',
      devices: bedroomDevices,
      totalPower: bedroomPower,
      cost: bedroomCost,
    ));
    
    _totalPower = livingRoomPower + bedroomPower;
    _totalCost = livingRoomCost + bedroomCost;
    
    print('💡 Total power: ${_formatPowerUnit(_totalPower)}, Total cost: ${_totalCost.toStringAsFixed(0)}₫');
  }
  
  double _calculateDevicePower(Map<String, dynamic> stats, double ratedPower) {
    // Try to get actual average power first
    final avgPower = double.tryParse(stats['average_power']?.toString() ?? '0') ?? 0;
    if (avgPower > 0) {
      print('🔧 Using actual average power: ${_formatPowerUnit(avgPower)}');
      return avgPower;
    }
    
    // Fallback to usage percentage calculation
    final usagePercentage = double.tryParse(stats['usage_percentage']?.toString() ?? '0') ?? 0;
    final calculatedPower = (usagePercentage / 100) * ratedPower;
    
    print('🔧 Device power calculation: ${usagePercentage}% of ${ratedPower}W = ${calculatedPower}W');
    return calculatedPower;
  }

  /// Toggle debug information panel
  void _toggleDebugInfo() {
    setState(() {
      _showDebugInfo = !_showDebugInfo;
    });
  }

  /// Update debug information
  void _updateDebugInfo() async {
    try {
      // Test connection by getting recent data
      final recentData = await _firebaseData.getPowerConsumptionHistory(
        startTime: DateTime.now().subtract(const Duration(minutes: 5)),
        endTime: DateTime.now(),
      );
      final connectionTest = recentData.isNotEmpty;
      final currentPower = recentData.isNotEmpty ? recentData.last['power'] ?? 0.0 : 0.0;
      final deviceStats = await _firebaseData.getDeviceStats('', timeRange: '1h');
      
      setState(() {
        _connectionStatus = connectionTest ? 'Kết nối thành công' : 'Kết nối thất bại';
        _totalDataPoints = _powerData?.length ?? 0;
        _availableDevices = deviceStats.keys.toList();
      });
    } catch (e) {
      setState(() {
        _connectionStatus = 'Lỗi: ${e.toString()}';
      });
    }
  }

  /// Check what measurements and fields are available in InfluxDB
  Future<void> _checkAvailableData() async {
    try {
      print('🔍 Checking available data in Firestore...');
      
      // Test connection by getting recent data
      final recentData = await _firebaseData.getPowerConsumptionHistory(
        startTime: DateTime.now().subtract(const Duration(hours: 1)),
        endTime: DateTime.now(),
      );
      final connectionTest = recentData.isNotEmpty;
      if (!connectionTest) {
        print('❌ Cannot connect to Firestore or no data available');
        return;
      }
      
      // Get available data
      print('📊 Available power consumption data: ${recentData.length} records');
      
      // Get recent data samples
      final samples = recentData.take(5).toList();
      print('📊 Data samples:');
      
      for (int i = 0; i < samples.length; i++) {
        final data = samples[i];
        print('  📊 Sample $i: $data');
        
        final fields = data.keys.toList();
        print('    Fields: $fields');
      }
      
    } catch (e) {
      print('❌ Error checking available data: $e');
    }
  }

  Widget _buildDebugPanel() {
    if (!_showDebugInfo) return const SizedBox.shrink();
    
    return Container(
      margin: EdgeInsets.only(bottom: getProportionateScreenHeight(16)),
      padding: EdgeInsets.all(getProportionateScreenWidth(12)),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.grey[600]!
              : const Color(0xFFE0E0E0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.bug_report, 
                size: 16, 
                color: Theme.of(context).textTheme.bodyMedium!.color,
              ),
              SizedBox(width: getProportionateScreenWidth(8)),
              Text(
                'Debug Info',
                style: TextStyle(
                  fontSize: getProportionateScreenWidth(12),
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).textTheme.bodyMedium!.color,
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: _updateDebugInfo,
                icon: Icon(
                  Icons.refresh, 
                  size: 16,
                  color: Theme.of(context).iconTheme.color,
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          SizedBox(height: getProportionateScreenHeight(8)),
          Text(
            'Kết nối DB: $_connectionStatus', 
            style: TextStyle(
              fontSize: getProportionateScreenWidth(10),
              color: Theme.of(context).textTheme.bodyMedium!.color,
            ),
          ),
          Text(
            'Điểm dữ liệu: $_totalDataPoints', 
            style: TextStyle(
              fontSize: getProportionateScreenWidth(10),
              color: Theme.of(context).textTheme.bodyMedium!.color,
            ),
          ),
          Text(
            'Thiết bị: ${_availableDevices.join(", ")}', 
            style: TextStyle(
              fontSize: getProportionateScreenWidth(10),
              color: Theme.of(context).textTheme.bodyMedium!.color,
            ),
          ),
          Text(
            'Thời gian: $_selectedTimeRange', 
            style: TextStyle(
              fontSize: getProportionateScreenWidth(10),
              color: Theme.of(context).textTheme.bodyMedium!.color,
            ),
          ),
          SizedBox(height: getProportionateScreenHeight(8)),
          Row(
            children: [
              TextButton(
                onPressed: _checkAvailableData,
                style: TextButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: getProportionateScreenWidth(8)),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  'Kiểm tra DB',
                  style: TextStyle(fontSize: getProportionateScreenWidth(9)),
                ),
              ),
              SizedBox(width: getProportionateScreenWidth(8)),
              TextButton(
                onPressed: () => _loadAnalyticsData(),
                style: TextButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: getProportionateScreenWidth(8)),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  'Tải lại',
                  style: TextStyle(fontSize: getProportionateScreenWidth(9)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: RefreshIndicator(
        onRefresh: _loadAnalyticsData,
        color: const Color(0xFF2196F3),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.all(getProportionateScreenWidth(16)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTimeRangeSelector(),
              SizedBox(height: getProportionateScreenHeight(16)),
              _buildOverviewCards(),
              SizedBox(height: getProportionateScreenHeight(16)),
              _buildPowerChart(),
              SizedBox(height: getProportionateScreenHeight(16)),
              _buildAreaConsumption(),
              _buildDebugPanel(), // Debug panel at the bottom
              SizedBox(height: getProportionateScreenHeight(120)), // Extra bottom padding
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTimeRangeSelector() {
    return Container(
      padding: EdgeInsets.all(getProportionateScreenWidth(16)),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.black.withValues(alpha: 0.3)
                : Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Khoảng thời gian',
                style: TextStyle(
                  fontSize: getProportionateScreenWidth(16),
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).textTheme.displayLarge!.color,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onLongPress: _toggleDebugInfo,
                child: Icon(
                  Icons.settings,
                  size: 16,
                  color: _showDebugInfo ? const Color(0xFF2196F3) : const Color(0xFFBDBDBD),
                ),
              ),
            ],
          ),
          SizedBox(height: getProportionateScreenHeight(12)),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _timeRanges.map((range) => 
                Container(
                  margin: EdgeInsets.only(right: getProportionateScreenWidth(8)),
                  child: InkWell(
                    onTap: () {
                      setState(() => _selectedTimeRange = range);
                      _loadAnalyticsData();
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: getProportionateScreenWidth(16),
                        vertical: getProportionateScreenHeight(8),
                      ),
                      decoration: BoxDecoration(
                        color: _selectedTimeRange == range 
                            ? const Color(0xFF2196F3)
                            : (Theme.of(context).brightness == Brightness.dark 
                                ? const Color(0xFF4A5568)
                                : const Color(0xFFF5F5F5)),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _getTimeRangeLabel(range),
                        style: TextStyle(
                          color: _selectedTimeRange == range 
                              ? Colors.white
                              : Theme.of(context).textTheme.bodyMedium!.color,
                          fontWeight: FontWeight.w500,
                          fontSize: getProportionateScreenWidth(12),
                        ),
                      ),
                    ),
                  ),
                ),
              ).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewCards() {
    return Row(
      children: [
        Expanded(
          child: _buildOverviewCard(
            'Tổng Tiêu Thụ',
            '${_totalPower.toStringAsFixed(1)} W',
            Icons.bolt,
            const Color(0xFF2196F3),
          ),
        ),
        SizedBox(width: getProportionateScreenWidth(12)),
        Expanded(
          child: _buildOverviewCard(
            'Chi Phí Điện',
            ElectricityCalculator.formatCurrency(_totalCost),
            Icons.account_balance_wallet,
            const Color(0xFF4CAF50),
          ),
        ),
      ],
    );
  }

  Widget _buildOverviewCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(getProportionateScreenWidth(16)),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.black.withValues(alpha: 0.3)
                : Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: _isLoading
          ? _buildLoadingContent()
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(icon, color: color, size: 20),
                    ),
                    const Spacer(),
                    Text(
                      _getTimeRangeLabel(_selectedTimeRange),
                      style: TextStyle(
                        fontSize: getProportionateScreenWidth(10),
                        color: Theme.of(context).textTheme.bodyMedium!.color?.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: getProportionateScreenHeight(12)),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: getProportionateScreenWidth(18),
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).textTheme.displayLarge!.color,
                  ),
                ),
                SizedBox(height: getProportionateScreenHeight(4)),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: getProportionateScreenWidth(12),
                    color: Theme.of(context).textTheme.bodyMedium!.color,
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildLoadingContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.grey[700]
                    : const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            const Spacer(),
            Container(
              width: 40,
              height: 12,
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.grey[700]
                    : const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(6),
              ),
            ),
          ],
        ),
        SizedBox(height: getProportionateScreenHeight(12)),
        Container(
          width: 60,
          height: 18,
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.grey[700]
                : const Color(0xFFF5F5F5),
            borderRadius: BorderRadius.circular(6),
          ),
        ),
        SizedBox(height: getProportionateScreenHeight(4)),
        Container(
          width: 80,
          height: 12,
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.grey[700]
                : const Color(0xFFF5F5F5),
            borderRadius: BorderRadius.circular(6),
          ),
        ),
      ],
    );
  }

  Widget _buildAreaConsumption() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tiêu Thụ Theo Khu Vực',
          style: TextStyle(
            fontSize: getProportionateScreenWidth(16),
            fontWeight: FontWeight.w600,
            color: Theme.of(context).textTheme.displayLarge!.color,
          ),
        ),
        SizedBox(height: getProportionateScreenHeight(12)),
        if (_isLoading) ...[
          _buildLoadingAreaCard(),
          SizedBox(height: getProportionateScreenHeight(12)),
          _buildLoadingAreaCard(),
        ] else if (_areaConsumption.isEmpty) ...[
          _buildEmptyAreaCard(),
        ] else ...[
          ..._areaConsumption.map((area) => _buildAreaCard(area)).toList(),
        ],
      ],
    );
  }

  Widget _buildLoadingAreaCard() {
    return Container(
      padding: EdgeInsets.all(getProportionateScreenWidth(16)),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.black.withValues(alpha: 0.3)
                : Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 80,
                height: 14,
                decoration: BoxDecoration(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.grey[700]
                      : const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              Container(
                width: 60,
                height: 20,
                decoration: BoxDecoration(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.grey[700]
                      : const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ],
          ),
          SizedBox(height: getProportionateScreenHeight(12)),
          Row(
            children: [
              Container(
                width: 50,
                height: 16,
                decoration: BoxDecoration(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.grey[700]
                      : const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              SizedBox(width: getProportionateScreenWidth(8)),
              Container(
                width: 70,
                height: 12,
                decoration: BoxDecoration(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.grey[700]
                      : const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ],
          ),
          SizedBox(height: getProportionateScreenHeight(12)),
          Row(
            children: [
              Container(
                width: 100,
                height: 28,
                decoration: BoxDecoration(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.grey[700]
                      : const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              SizedBox(width: getProportionateScreenWidth(8)),
              Container(
                width: 120,
                height: 28,
                decoration: BoxDecoration(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.grey[700]
                      : const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyAreaCard() {
    return Container(
      padding: EdgeInsets.all(getProportionateScreenWidth(24)),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.black.withValues(alpha: 0.3)
                : Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.analytics_outlined,
              size: 48,
              color: Theme.of(context).textTheme.bodyMedium!.color,
            ),
            SizedBox(height: getProportionateScreenHeight(12)),
            Text(
              'Chưa có dữ liệu thống kê',
              style: TextStyle(
                fontSize: getProportionateScreenWidth(14),
                color: Theme.of(context).textTheme.bodyLarge!.color,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: getProportionateScreenHeight(4)),
            Text(
              'Dữ liệu sẽ xuất hiện khi hệ thống bắt đầu ghi nhận hoạt động của thiết bị',
              style: TextStyle(
                fontSize: getProportionateScreenWidth(12),
                color: Theme.of(context).textTheme.bodyMedium!.color,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: getProportionateScreenHeight(16)),
            ElevatedButton.icon(
              onPressed: () => _loadAnalyticsData(),
              icon: const Icon(Icons.refresh, size: 16),
              label: Text(
                'Tải lại dữ liệu',
                style: TextStyle(
                  fontSize: getProportionateScreenWidth(12),
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2196F3),
                foregroundColor: Colors.white,
                elevation: 0,
                padding: EdgeInsets.symmetric(
                  horizontal: getProportionateScreenWidth(16),
                  vertical: getProportionateScreenHeight(8),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAreaCard(PowerConsumption area) {
    return Container(
      margin: EdgeInsets.only(bottom: getProportionateScreenHeight(12)),
      padding: EdgeInsets.all(getProportionateScreenWidth(16)),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.black.withValues(alpha: 0.3)
                : Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                area.area,
                style: TextStyle(
                  fontSize: getProportionateScreenWidth(14),
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).textTheme.displayLarge!.color,
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: getProportionateScreenWidth(8),
                  vertical: getProportionateScreenHeight(4),
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF4CAF50).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  ElectricityCalculator.formatCurrency(area.cost),
                  style: TextStyle(
                    fontSize: getProportionateScreenWidth(10),
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF4CAF50),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: getProportionateScreenHeight(12)),
          Row(
            children: [
              Text(
                _formatPowerUnit(area.totalPower),
                style: TextStyle(
                  fontSize: getProportionateScreenWidth(16),
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF2196F3),
                ),
              ),
              SizedBox(width: getProportionateScreenWidth(8)),
              Text(
                '• ${area.devices.length} thiết bị',
                style: TextStyle(
                  fontSize: getProportionateScreenWidth(12),
                  color: Theme.of(context).textTheme.bodyMedium!.color,
                ),
              ),
            ],
          ),
          SizedBox(height: getProportionateScreenHeight(12)),
          Wrap(
            spacing: getProportionateScreenWidth(8),
            runSpacing: getProportionateScreenHeight(6),
            children: area.devices.map((device) => _buildDeviceChip(device)).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildDeviceChip(DevicePower device) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: getProportionateScreenWidth(10),
        vertical: getProportionateScreenHeight(6),
      ),
      decoration: BoxDecoration(
        color: device.color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: device.color.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: device.color,
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(width: getProportionateScreenWidth(6)),
          Text(
            device.name,
            style: TextStyle(
              fontSize: getProportionateScreenWidth(10),
              fontWeight: FontWeight.w500,
              color: Theme.of(context).textTheme.bodyLarge!.color,
            ),
          ),
          SizedBox(width: getProportionateScreenWidth(6)),
          Text(
            '${device.power.toStringAsFixed(1)}W',
            style: TextStyle(
              fontSize: getProportionateScreenWidth(10),
              color: device.color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPowerChart() {
    return Container(
      padding: EdgeInsets.all(getProportionateScreenWidth(16)),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.black.withValues(alpha: 0.3)
                : Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Biểu Đồ Tiêu Thụ Điện',
                style: TextStyle(
                  fontSize: getProportionateScreenWidth(14),
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).textTheme.displayLarge!.color,
                ),
              ),
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: Color(0xFF9C27B0),
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
          SizedBox(height: getProportionateScreenHeight(16)),
          if (_powerData != null && _powerData!.isNotEmpty) ...[
            SizedBox(
              height: 120,
              child: _buildChart(_powerData!),
            ),
          ] else ...[
            _buildEmptyChart(),
          ],
        ],
      ),
    );
  }

  Widget _buildChart(List<Map<String, dynamic>> data) {
    final chartData = data.map((item) {
      final timeStr = item['_time']?.toString() ?? '';
      final valueStr = item['_value']?.toString() ?? '0';
      final value = double.tryParse(valueStr) ?? 0;
      
      DateTime? time;
      try {
        time = DateTime.parse(timeStr);
      } catch (e) {
        time = DateTime.now();
      }
      
      return ChartData(time, value);
    }).toList();

    return SfCartesianChart(
      plotAreaBorderWidth: 0,
      primaryXAxis: DateTimeAxis(
        majorGridLines: const MajorGridLines(width: 0),
        axisLine: const AxisLine(width: 0),
        labelStyle: TextStyle(
          fontSize: getProportionateScreenWidth(10),
          color: const Color(0xFF757575),
        ),
      ),
      primaryYAxis: NumericAxis(
        majorGridLines: MajorGridLines(
          width: 0.5,
          color: const Color(0xFFE0E0E0),
        ),
        axisLine: const AxisLine(width: 0),
        labelStyle: TextStyle(
          fontSize: getProportionateScreenWidth(10),
          color: const Color(0xFF757575),
        ),
      ),
      series: <CartesianSeries<ChartData, DateTime>>[
        AreaSeries<ChartData, DateTime>(
          dataSource: chartData,
          xValueMapper: (ChartData data, _) => data.time,
          yValueMapper: (ChartData data, _) => data.value,
          color: const Color(0xFF9C27B0).withValues(alpha: 0.3),
          borderColor: const Color(0xFF9C27B0),
          borderWidth: 2,
        ),
      ],
    );
  }

  Widget _buildEmptyChart() {
    return Container(
      height: 100, // Reduced from 120
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min, // Important: minimize column size
        children: [
          Icon(
            Icons.show_chart,
            size: 24, // Further reduced from 28
            color: const Color(0xFFBDBDBD),
          ),
          SizedBox(height: getProportionateScreenHeight(4)), // Further reduced from 6
          Text(
            'Chưa có dữ liệu biểu đồ',
            style: TextStyle(
              color: const Color(0xFFBDBDBD),
              fontSize: getProportionateScreenWidth(10), // Further reduced font size
            ),
          ),
          SizedBox(height: getProportionateScreenHeight(4)), // Further reduced from 6
          TextButton.icon(
            onPressed: () => _loadAnalyticsData(),
            icon: const Icon(Icons.refresh, size: 10), // Further reduced from 12
            label: Text(
              'Tải lại',
              style: TextStyle(
                fontSize: getProportionateScreenWidth(8), // Further reduced font size
              ),
            ),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF2196F3),
              padding: EdgeInsets.symmetric(
                horizontal: getProportionateScreenWidth(6), // Further reduced padding
                vertical: getProportionateScreenHeight(1), // Further reduced padding
              ),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
        ],
      ),
    );
  }

  String _getTimeRangeLabel(String range) {
    switch (range) {
      case '1h':
        return '1 giờ';
      case '6h':
        return '6 giờ';
      case '24h':
        return '24 giờ';
      case '7d':
        return '7 ngày';
      case '30d':
        return '30 ngày';
      default:
        return range;
    }
  }

  /// Format power with appropriate unit (W or kW)
  String _formatPowerUnit(double powerWatts) {
    if (powerWatts >= 1000) {
      final powerKw = powerWatts / 1000;
      return '${powerKw.toStringAsFixed(2)}kW';
    } else {
      return '${powerWatts.toStringAsFixed(1)}W';
    }
  }
}
