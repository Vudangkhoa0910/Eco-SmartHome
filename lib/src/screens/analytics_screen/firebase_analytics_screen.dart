import 'package:flutter/material.dart';
import 'package:smart_home/config/size_config.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:smart_home/service/firebase_data_service.dart';

class ChartData {
  final DateTime time;
  final double value;

  ChartData(this.time, this.value);
}

class DeviceUsageData {
  final String device;
  final double value;
  final Color color;

  DeviceUsageData(this.device, this.value, this.color);
}

class EnergyBarData {
  final String day;
  final double usage;
  final double saved;

  EnergyBarData(this.day, this.usage, this.saved);
}

class FirebaseAnalyticsScreen extends StatefulWidget {
  const FirebaseAnalyticsScreen({Key? key}) : super(key: key);

  @override
  State<FirebaseAnalyticsScreen> createState() =>
      _FirebaseAnalyticsScreenState();
}

class _FirebaseAnalyticsScreenState extends State<FirebaseAnalyticsScreen> {
  bool _isLoading = true;
  bool _aiEnergyModeEnabled = true;

  // Firebase data variables
  final FirebaseDataService _firebaseService = FirebaseDataService();
  double _currentPowerConsumption = 0.0;
  double _dailyEnergyConsumption = 0.0;
  double _monthlyEnergyConsumption = 0.0;
  double _monthlyCost = 0.0;
  List<EnergyBarData> _dailyUsageData = [];
  List<DeviceUsageData> _deviceUsageData = [];
  Map<String, dynamic> _deviceStats = {};

  @override
  void initState() {
    super.initState();
    _loadAnalyticsData();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _loadAnalyticsData() async {
    if (!mounted) return;

    setState(() => _isLoading = true);

    try {
      // Load real data from Firebase with timeout
      await Future.wait([
        _loadCurrentPowerConsumption(),
        _loadDailyEnergyConsumption(),
        _loadMonthlyEnergyConsumption(),
        _loadDailyUsageData(),
        _loadDeviceUsageData(),
        _loadDeviceStats(),
      ]).timeout(const Duration(seconds: 10));

      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      print('❌ Analytics Error: $e');
      if (!mounted) return;

      // Set fallback values on error
      setState(() {
        _isLoading = false;
        _currentPowerConsumption = 0.0;
        _dailyEnergyConsumption = 0.0;
        _monthlyEnergyConsumption = 0.0;
        _monthlyCost = 0.0;
      });
    }
  }

  Future<void> _loadCurrentPowerConsumption() async {
    try {
      _currentPowerConsumption =
          await _firebaseService.getCurrentPowerConsumption();
    } catch (e) {
      print('❌ Error loading current power: $e');
      _currentPowerConsumption = 0.0;
    }
  }

  Future<void> _loadDailyEnergyConsumption() async {
    try {
      _dailyEnergyConsumption =
          await _firebaseService.getDailyEnergyConsumption();
    } catch (e) {
      print('❌ Error loading daily energy: $e');
      _dailyEnergyConsumption = 0.0;
    }
  }

  Future<void> _loadMonthlyEnergyConsumption() async {
    try {
      _monthlyEnergyConsumption =
          await _firebaseService.getMonthlyEnergyConsumption();
      // Calculate cost (1500 VND per kWh as default)
      _monthlyCost = _monthlyEnergyConsumption * 1500;
    } catch (e) {
      print('❌ Error loading monthly energy: $e');
      _monthlyEnergyConsumption = 0.0;
      _monthlyCost = 0.0;
    }
  }

  Future<void> _loadDailyUsageData() async {
    try {
      final endDate = DateTime.now();
      final startDate = endDate.subtract(const Duration(days: 7));

      final powerHistory = await _firebaseService.getPowerConsumptionHistory(
        startTime: startDate,
        endTime: endDate,
      );

      // Group data by day and calculate averages
      final Map<String, List<double>> dailyPower = {};
      final Map<String, List<double>> dailySaved = {};

      for (final data in powerHistory) {
        final timestampRaw = data['created_at'];
        DateTime? timestamp;

        // Handle both Timestamp and DateTime types
        if (timestampRaw is DateTime) {
          timestamp = timestampRaw;
        } else if (timestampRaw != null) {
          try {
            // Firebase Timestamp - convert to DateTime
            if (timestampRaw.runtimeType.toString().contains('Timestamp')) {
              timestamp = (timestampRaw as dynamic).toDate() as DateTime?;
            }
          } catch (e) {
            print('❌ Error converting timestamp: $e');
            continue; // Skip this entry if conversion fails
          }
        }

        if (timestamp != null) {
          final dayKey = '${timestamp.month}/${timestamp.day}';
          final power = (data['power'] as num?)?.toDouble() ?? 0.0;
          final energyKwh = (data['energy_kwh'] as num?)?.toDouble() ?? 0.0;

          dailyPower.putIfAbsent(dayKey, () => []);
          dailyPower[dayKey]!.add(power / 1000); // Convert to kW

          // Assume AI saving is 30% of actual usage
          dailySaved.putIfAbsent(dayKey, () => []);
          dailySaved[dayKey]!.add(energyKwh * 0.3);
        }
      }

      _dailyUsageData = [];
      final today = DateTime.now();
      for (int i = 6; i >= 0; i--) {
        final date = today.subtract(Duration(days: i));
        final dayKey = '${date.month}/${date.day}';
        final displayKey = i == 0 ? 'Hôm nay' : (i == 1 ? 'Hôm qua' : dayKey);

        final avgPower = dailyPower[dayKey]?.isNotEmpty == true
            ? dailyPower[dayKey]!.reduce((a, b) => a + b) /
                dailyPower[dayKey]!.length
            : (15 + i * 2).toDouble(); // Demo data fallback

        final avgSaved = dailySaved[dayKey]?.isNotEmpty == true
            ? dailySaved[dayKey]!.reduce((a, b) => a + b) /
                dailySaved[dayKey]!.length
            : (5 + i).toDouble(); // Demo data fallback

        _dailyUsageData.add(EnergyBarData(displayKey, avgPower, avgSaved));
      }
    } catch (e) {
      print('❌ Error loading daily usage data: $e');
      // Fallback to demo data
      _dailyUsageData = [
        EnergyBarData('8/14', 15, 5),
        EnergyBarData('15', 25, 8),
        EnergyBarData('16', 12, 4),
        EnergyBarData('17', 18, 6),
        EnergyBarData('18', 20, 7),
        EnergyBarData('19', 14, 5),
        EnergyBarData('Hôm nay', 22, 8),
      ];
    }
  }

  Future<void> _loadDeviceUsageData() async {
    try {
      _deviceStats = await _firebaseService.getDeviceStats('');

      // Convert to DeviceUsageData format
      _deviceUsageData = [];
      final colors = [
        Colors.blue[300]!,
        Colors.blue[600]!,
        Colors.cyan,
        Colors.purple,
        Colors.green
      ];
      int colorIndex = 0;

      for (final entry in _deviceStats.entries) {
        final deviceName = entry.key;
        final stats = entry.value as Map<String, dynamic>;
        final usagePercent =
            double.tryParse(stats['usage_percentage']?.toString() ?? '0') ??
                0.0;

        _deviceUsageData.add(DeviceUsageData(
          deviceName,
          usagePercent,
          colors[colorIndex % colors.length],
        ));
        colorIndex++;
      }

      // Add some demo devices if no real data
      if (_deviceUsageData.isEmpty) {
        _deviceUsageData = [
          DeviceUsageData('Máy điều hòa', 120, Colors.blue[300]!),
          DeviceUsageData('Family Hub', 95, Colors.blue[600]!),
          DeviceUsageData('TV', 78, Colors.cyan),
          DeviceUsageData('Khác', 50, Colors.grey),
        ];
      }
    } catch (e) {
      print('❌ Error loading device usage data: $e');
      // Fallback to demo data
      _deviceUsageData = [
        DeviceUsageData('Máy điều hòa', 120, Colors.blue[300]!),
        DeviceUsageData('Family Hub', 95, Colors.blue[600]!),
        DeviceUsageData('TV', 78, Colors.cyan),
        DeviceUsageData('Khác', 50, Colors.grey),
      ];
    }
  }

  Future<void> _loadDeviceStats() async {
    try {
      _deviceStats = await _firebaseService.getDeviceStats('', timeRange: '7d');
    } catch (e) {
      print('❌ Error loading device stats: $e');
      _deviceStats = {};
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: _isLoading ? _buildLoadingScreen() : _buildContent(),
      ),
    );
  }

  Widget _buildLoadingScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor:
                AlwaysStoppedAnimation<Color>(Theme.of(context).primaryColor),
          ),
          SizedBox(height: getProportionateScreenHeight(16)),
          Text(
            'Đang tải dữ liệu...',
            style: TextStyle(
              fontSize: getProportionateScreenWidth(14),
              color: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.color
                  ?.withValues(alpha: 0.7),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return RefreshIndicator(
      onRefresh: _loadAnalyticsData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.all(getProportionateScreenWidth(16)),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: MediaQuery.of(context).size.height -
                AppBar().preferredSize.height -
                MediaQuery.of(context).padding.top -
                getProportionateScreenWidth(32), // Padding
          ),
          child: Column(
            children: [
              _buildAIEnergyModeCard(),
              SizedBox(height: getProportionateScreenHeight(12)),
              _buildMonthlyCostCard(),
              SizedBox(height: getProportionateScreenHeight(12)),
              _buildDailyUsageCard(),
              SizedBox(height: getProportionateScreenHeight(12)),
              _buildDeviceUsageCard(),
              SizedBox(height: getProportionateScreenHeight(12)),
              _buildEnergyConsumptionCard(),
              SizedBox(height: getProportionateScreenHeight(12)),
              _buildSmartMeterCard(),
              SizedBox(height: getProportionateScreenHeight(12)),
              _buildSolarPowerCard(),
              SizedBox(
                  height: getProportionateScreenHeight(
                      16)), // Extra padding at bottom
            ],
          ),
        ),
      ),
    );
  }

  // AI Energy Mode Card
  Widget _buildAIEnergyModeCard() {
    return Container(
      padding: EdgeInsets.all(getProportionateScreenWidth(16)),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.black.withValues(alpha: 0.3)
                : Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.teal.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.auto_awesome,
              color: Colors.teal,
              size: 20,
            ),
          ),
          SizedBox(width: getProportionateScreenWidth(12)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Chế độ AI',
                  style: TextStyle(
                    color: Theme.of(context).textTheme.titleLarge?.color,
                    fontSize: getProportionateScreenWidth(16),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  _currentPowerConsumption > 0
                      ? 'Hiện tại: ${_currentPowerConsumption.toStringAsFixed(1)}W'
                      : 'Đang tiết kiệm',
                  style: TextStyle(
                    color: Colors.blue[300],
                    fontSize: getProportionateScreenWidth(14),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: _aiEnergyModeEnabled,
            onChanged: (value) {
              setState(() {
                _aiEnergyModeEnabled = value;
              });
            },
            activeColor: Colors.blue,
            inactiveThumbColor: Colors.grey,
            inactiveTrackColor: Theme.of(context).brightness == Brightness.dark
                ? Colors.grey[800]
                : Colors.grey[300],
          ),
        ],
      ),
    );
  }

  // Monthly Cost Card
  Widget _buildMonthlyCostCard() {
    return Container(
      padding: EdgeInsets.all(getProportionateScreenWidth(16)),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.black.withValues(alpha: 0.3)
                : Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Chi phí điện tháng này',
            style: TextStyle(
              color: Theme.of(context).textTheme.titleLarge?.color,
              fontSize: getProportionateScreenWidth(14),
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: getProportionateScreenHeight(16)),
          Row(
            children: [
              Flexible(
                child: Text(
                  '${(_monthlyCost > 0 ? _monthlyCost : 551338).toStringAsFixed(0)}',
                  style: TextStyle(
                    color: Theme.of(context).textTheme.titleLarge?.color,
                    fontSize: getProportionateScreenWidth(14),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              SizedBox(width: getProportionateScreenWidth(4)),
              Text(
                'đ',
                style: TextStyle(
                  color: Theme.of(context).textTheme.titleLarge?.color,
                  fontSize: getProportionateScreenWidth(12),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          SizedBox(height: getProportionateScreenHeight(8)),
          Row(
            children: [
              Icon(Icons.auto_awesome, color: Colors.teal, size: 16),
              SizedBox(width: getProportionateScreenWidth(4)),
              Flexible(
                child: Text(
                  'Tiết kiệm 178.877đ với AI',
                  style: TextStyle(
                    color: Colors.teal,
                    fontSize: getProportionateScreenWidth(10),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: getProportionateScreenHeight(16)),
          Divider(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.grey[700]
                  : Colors.grey[300],
              height: 1),
          SizedBox(height: getProportionateScreenHeight(16)),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ước tính cả tháng',
                      style: TextStyle(
                        color: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.color
                            ?.withValues(alpha: 0.7),
                        fontSize: getProportionateScreenWidth(10),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      'Tháng trước',
                      style: TextStyle(
                        color: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.color
                            ?.withValues(alpha: 0.7),
                        fontSize: getProportionateScreenWidth(10),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${(_monthlyCost > 0 ? (_monthlyCost * 1.65).toStringAsFixed(0) : '909.710')} đ',
                      style: TextStyle(
                        color: Theme.of(context).textTheme.titleLarge?.color,
                        fontSize: getProportionateScreenWidth(10),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      '${(_monthlyCost > 0 ? (_monthlyCost * 1.1).toStringAsFixed(0) : '606.474')} đ',
                      style: TextStyle(
                        color: Theme.of(context).textTheme.titleLarge?.color,
                        fontSize: getProportionateScreenWidth(10),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Daily Usage Card with Bar Chart
  Widget _buildDailyUsageCard() {
    return Container(
      padding: EdgeInsets.all(getProportionateScreenWidth(16)),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.black.withValues(alpha: 0.3)
                : Colors.black.withValues(alpha: 0.1),
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
                'Sử dụng năng lượng',
                style: TextStyle(
                  color: Theme.of(context).textTheme.titleLarge?.color,
                  fontSize: getProportionateScreenWidth(13),
                  fontWeight: FontWeight.w600,
                ),
              ),
              Icon(Icons.chevron_right,
                  color: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.color
                      ?.withValues(alpha: 0.7)),
            ],
          ),
          SizedBox(height: getProportionateScreenHeight(16)),
          Text(
            '${(_monthlyEnergyConsumption > 0 ? _monthlyEnergyConsumption.toStringAsFixed(2) : '293.89')} kWh',
            style: TextStyle(
              color: Theme.of(context).textTheme.titleLarge?.color,
              fontSize: getProportionateScreenWidth(16),
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            'Tiêu thụ ít hơn ${(_monthlyEnergyConsumption > 0 ? (_monthlyEnergyConsumption * 0.1).toStringAsFixed(2) : '29.39')} kWh so với cùng kỳ tháng trước.',
            style: TextStyle(
              color: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.color
                  ?.withValues(alpha: 0.7),
              fontSize: getProportionateScreenWidth(10),
            ),
          ),
          SizedBox(height: getProportionateScreenHeight(20)),
          Container(
            height: getProportionateScreenHeight(120),
            child: SfCartesianChart(
              backgroundColor: Colors.transparent,
              plotAreaBorderWidth: 0,
              primaryXAxis: CategoryAxis(
                axisLine: AxisLine(width: 0),
                majorTickLines: MajorTickLines(size: 0),
                labelStyle: TextStyle(
                  color: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.color
                      ?.withValues(alpha: 0.7),
                  fontSize: getProportionateScreenWidth(10),
                ),
              ),
              primaryYAxis: NumericAxis(
                isVisible: false,
                minimum: 0,
                maximum: 30,
              ),
              series: <CartesianSeries>[
                ColumnSeries<EnergyBarData, String>(
                  dataSource: _dailyUsageData,
                  xValueMapper: (EnergyBarData data, _) => data.day,
                  yValueMapper: (EnergyBarData data, _) => data.usage,
                  color: Colors.blue,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(4),
                    topRight: Radius.circular(4),
                  ),
                ),
                ColumnSeries<EnergyBarData, String>(
                  dataSource: _dailyUsageData,
                  xValueMapper: (EnergyBarData data, _) => data.day,
                  yValueMapper: (EnergyBarData data, _) => data.saved,
                  color: Colors.teal,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(4),
                    topRight: Radius.circular(4),
                  ),
                ),
              ],
            ),
          ),
          Row(
            children: [
              Text(
                '1',
                style: TextStyle(
                    color: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.color
                        ?.withValues(alpha: 0.7),
                    fontSize: getProportionateScreenWidth(12)),
              ),
              Spacer(),
              Text(
                'Hôm nay',
                style: TextStyle(
                    color: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.color
                        ?.withValues(alpha: 0.7),
                    fontSize: getProportionateScreenWidth(12)),
              ),
              Spacer(),
              Text(
                '31',
                style: TextStyle(
                    color: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.color
                        ?.withValues(alpha: 0.7),
                    fontSize: getProportionateScreenWidth(12)),
              ),
            ],
          ),
          SizedBox(height: getProportionateScreenHeight(8)),
          Row(
            children: [
              Flexible(
                child: Text(
                  '— tháng 7',
                  style: TextStyle(
                      color: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.color
                          ?.withValues(alpha: 0.7),
                      fontSize: getProportionateScreenWidth(12)),
                ),
              ),
              SizedBox(width: getProportionateScreenWidth(16)),
              Flexible(
                child: Text(
                  '— tháng 8',
                  style: TextStyle(
                      color: Colors.blue,
                      fontSize: getProportionateScreenWidth(12)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Device Usage Card with Donut Chart
  Widget _buildDeviceUsageCard() {
    return Container(
      padding: EdgeInsets.all(getProportionateScreenWidth(16)),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.black.withValues(alpha: 0.3)
                : Colors.black.withValues(alpha: 0.1),
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
              Expanded(
                child: Text(
                  'Mức sử dụng năng lượng thiết bị',
                  style: TextStyle(
                    color: Theme.of(context).textTheme.titleLarge?.color,
                    fontSize: getProportionateScreenWidth(13),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              SizedBox(width: getProportionateScreenWidth(8)),
              Icon(Icons.chevron_right,
                  color: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.color
                      ?.withValues(alpha: 0.7)),
            ],
          ),
          SizedBox(height: getProportionateScreenHeight(8)),
          Text(
            'Tiết kiệm 24.5% với AI',
            style: TextStyle(
              color: Theme.of(context).textTheme.titleLarge?.color,
              fontSize: getProportionateScreenWidth(11),
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            'Máy điều hòa tiêu thụ nhiều năng lượng nhất',
            style: TextStyle(
              color: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.color
                  ?.withValues(alpha: 0.7),
              fontSize: getProportionateScreenWidth(9),
            ),
          ),
          SizedBox(height: getProportionateScreenHeight(20)),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.electric_bolt, color: Colors.blue, size: 16),
                        SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            'Tổng mức sử dụng',
                            style: TextStyle(
                              color: Colors.blue,
                              fontSize: getProportionateScreenWidth(11),
                            ),
                          ),
                        ),
                      ],
                    ),
                    Text(
                      '${(_dailyEnergyConsumption > 0 ? _dailyEnergyConsumption.toStringAsFixed(2) : '293.89')} kWh',
                      style: TextStyle(
                        color: Theme.of(context).textTheme.titleLarge?.color,
                        fontSize: getProportionateScreenWidth(14),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: getProportionateScreenHeight(12)),
                    Row(
                      children: [
                        Icon(Icons.auto_awesome, color: Colors.teal, size: 16),
                        SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            'Khoản tiết kiệm',
                            style: TextStyle(
                              color: Colors.teal,
                              fontSize: getProportionateScreenWidth(10),
                            ),
                          ),
                        ),
                      ],
                    ),
                    Text(
                      '${((_dailyEnergyConsumption > 0 ? _dailyEnergyConsumption : 95.35) * 0.3).toStringAsFixed(2)} kWh',
                      style: TextStyle(
                        color: Theme.of(context).textTheme.titleLarge?.color,
                        fontSize: getProportionateScreenWidth(14),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: getProportionateScreenWidth(100),
                height: getProportionateScreenWidth(100),
                child: SfCircularChart(
                  backgroundColor: Colors.transparent,
                  series: <CircularSeries>[
                    DoughnutSeries<DeviceUsageData, String>(
                      dataSource: _deviceUsageData,
                      xValueMapper: (DeviceUsageData data, _) => data.device,
                      yValueMapper: (DeviceUsageData data, _) => data.value,
                      pointColorMapper: (DeviceUsageData data, _) => data.color,
                      innerRadius: '60%',
                      radius: '80%',
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: getProportionateScreenHeight(20)),
          // Show real device data or demo data
          ..._buildDeviceUsageItems(),
          SizedBox(height: getProportionateScreenHeight(16)),
          Center(
            child: Text(
              'Xem tất cả',
              style: TextStyle(
                color: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.color
                    ?.withValues(alpha: 0.7),
                fontSize: getProportionateScreenWidth(14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildDeviceUsageItems() {
    if (_deviceUsageData.isEmpty) {
      return [
        _buildDeviceUsageItem('Máy điều hòa trong phòng', '34.98 kWh',
            '14.25 kWh', Colors.blue, Colors.teal),
        SizedBox(height: getProportionateScreenHeight(8)),
        _buildDeviceUsageItem(
            'Family Hub', '27.41 kWh', '7.52 kWh', Colors.blue, Colors.teal),
        SizedBox(height: getProportionateScreenHeight(8)),
        _buildDeviceUsageItem(
            'TV', '25.23 kWh', '8.78 kWh', Colors.blue, Colors.teal),
      ];
    }

    final items = <Widget>[];
    for (int i = 0; i < _deviceUsageData.length && i < 3; i++) {
      final device = _deviceUsageData[i];
      final usage = '${device.value.toStringAsFixed(2)} kWh';
      final saved = '${(device.value * 0.3).toStringAsFixed(2)} kWh';

      if (i > 0) items.add(SizedBox(height: getProportionateScreenHeight(8)));
      items.add(_buildDeviceUsageItem(
        device.device,
        usage,
        saved,
        device.color,
        Colors.teal,
      ));
    }
    return items;
  }

  Widget _buildDeviceUsageItem(String deviceName, String usage, String saved,
      Color usageColor, Color savedColor) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: usageColor,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        SizedBox(width: getProportionateScreenWidth(8)),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                deviceName,
                style: TextStyle(
                  color: Theme.of(context).textTheme.titleLarge?.color,
                  fontSize: getProportionateScreenWidth(11),
                ),
              ),
              Text(
                '$usage | $saved',
                style: TextStyle(
                  color: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.color
                      ?.withValues(alpha: 0.7),
                  fontSize: getProportionateScreenWidth(9),
                ),
              ),
            ],
          ),
        ),
        Flexible(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: getProportionateScreenWidth(40),
                height: 6,
                decoration: BoxDecoration(
                  color: usageColor,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              SizedBox(width: 3),
              Container(
                width: getProportionateScreenWidth(12),
                height: 6,
                decoration: BoxDecoration(
                  color: savedColor,
                  borderRadius: BorderRadius.circular(3),
                  border: Border.all(color: savedColor, width: 1),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Energy Consumption Recommendation Card
  Widget _buildEnergyConsumptionCard() {
    return Container(
      padding: EdgeInsets.all(getProportionateScreenWidth(16)),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.black.withValues(alpha: 0.3)
                : Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Phân tích mức tiêu thụ năng lượng',
                  style: TextStyle(
                    color: Theme.of(context).textTheme.titleLarge?.color,
                    fontSize: getProportionateScreenWidth(15),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: getProportionateScreenHeight(8)),
                Text(
                  'Xem kiểu tiêu thụ năng lượng của Virtual Home.',
                  style: TextStyle(
                    color: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.color
                        ?.withValues(alpha: 0.7),
                    fontSize: getProportionateScreenWidth(11),
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: getProportionateScreenWidth(60),
            height: getProportionateScreenWidth(60),
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Stack(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.grey[300]
                        : Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Icon(Icons.bar_chart, color: Colors.white, size: 12),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Smart Meter Card
  Widget _buildSmartMeterCard() {
    return Container(
      padding: EdgeInsets.all(getProportionateScreenWidth(16)),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.black.withValues(alpha: 0.3)
                : Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Đồng hồ thông minh',
                  style: TextStyle(
                    color: Theme.of(context).textTheme.titleLarge?.color,
                    fontSize: getProportionateScreenWidth(15),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: getProportionateScreenHeight(8)),
                Text(
                  'Kiểm tra tổng mức tiêu thụ năng lượng trong nhà.',
                  style: TextStyle(
                    color: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.color
                        ?.withValues(alpha: 0.7),
                    fontSize: getProportionateScreenWidth(11),
                  ),
                ),
              ],
            ),
          ),
          Row(
            children: [
              Container(
                width: getProportionateScreenWidth(40),
                height: getProportionateScreenWidth(50),
                decoration: BoxDecoration(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.grey[600]
                      : Colors.grey[400],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 20,
                      height: 2,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white
                          : Colors.grey[800],
                    ),
                    SizedBox(height: 4),
                    Container(
                      width: 15,
                      height: 2,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white
                          : Colors.grey[800],
                    ),
                    SizedBox(height: 4),
                    Container(
                      width: 20,
                      height: 2,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white
                          : Colors.grey[800],
                    ),
                  ],
                ),
              ),
              SizedBox(width: 8),
              Container(
                width: getProportionateScreenWidth(30),
                height: getProportionateScreenWidth(30),
                decoration: BoxDecoration(
                  color: Colors.blue,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(Icons.electric_bolt, color: Colors.white, size: 16),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Solar Power Card
  Widget _buildSolarPowerCard() {
    return Container(
      padding: EdgeInsets.all(getProportionateScreenWidth(16)),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.black.withValues(alpha: 0.3)
                : Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tấm năng lượng mặt trời',
                  style: TextStyle(
                    color: Theme.of(context).textTheme.titleLarge?.color,
                    fontSize: getProportionateScreenWidth(15),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: getProportionateScreenHeight(8)),
                Text(
                  'Hiện thực hóa ngôi nhà cân bằng khí thải.',
                  style: TextStyle(
                    color: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.color
                        ?.withValues(alpha: 0.7),
                    fontSize: getProportionateScreenWidth(11),
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: getProportionateScreenWidth(60),
            height: getProportionateScreenWidth(60),
            decoration: BoxDecoration(
              color: Colors.blue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Stack(
              children: [
                Positioned(
                  bottom: 0,
                  left: 8,
                  right: 8,
                  child: Container(
                    height: 30,
                    decoration: BoxDecoration(
                      color: Colors.blue[300],
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.grey[300]
                          : Colors.white,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.cloud_download,
                        color: Colors.teal, size: 12),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
