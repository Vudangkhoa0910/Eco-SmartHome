import 'package:flutter/material.dart';
import 'package:smart_home/config/size_config.dart';
import 'package:smart_home/service/firebase_data_service.dart';
import 'package:smart_home/provider/getit.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

class ChartData {
  final DateTime time;
  final double value;
  
  ChartData(this.time, this.value);
}

class FirebaseAnalyticsScreen extends StatefulWidget {
  const FirebaseAnalyticsScreen({Key? key}) : super(key: key);

  @override
  State<FirebaseAnalyticsScreen> createState() => _FirebaseAnalyticsScreenState();
}

class _FirebaseAnalyticsScreenState extends State<FirebaseAnalyticsScreen> {
  final FirebaseDataService _firebaseData = getIt<FirebaseDataService>();
  
  List<Map<String, dynamic>>? _temperatureData;
  List<Map<String, dynamic>>? _powerData;
  Map<String, dynamic>? _led1Stats;
  Map<String, dynamic>? _led2Stats;
  Map<String, dynamic>? _motorStats;
  
  bool _isLoading = true;
  String _selectedTimeRange = '24h';
  
  final List<String> _timeRanges = [
    '1h',
    '6h', 
    '24h',
    '7d',
    '30d'
  ];

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
      final tempFuture = _firebaseData.querySensorHistory(
        timeRange: _selectedTimeRange,
        sensorType: 'temperature',
        aggregation: 'mean',
      );
      
      final powerFuture = _firebaseData.querySensorHistory(
        timeRange: _selectedTimeRange,
        sensorType: 'power',
        aggregation: 'mean',
      );
      
      final led1StatsFuture = _firebaseData.getDeviceStats('led_gate', timeRange: _selectedTimeRange);
      final led2StatsFuture = _firebaseData.getDeviceStats('led_around', timeRange: _selectedTimeRange);
      final motorStatsFuture = _firebaseData.getDeviceStats('motor', timeRange: _selectedTimeRange);
      
      final results = await Future.wait([
        tempFuture,
        powerFuture,
        led1StatsFuture,
        led2StatsFuture,
        motorStatsFuture,
      ]);
      
      if (!mounted) return;
      
      setState(() {
        _temperatureData = results[0] as List<Map<String, dynamic>>?;
        _powerData = results[1] as List<Map<String, dynamic>>?;
        _led1Stats = results[2] as Map<String, dynamic>?;
        _led2Stats = results[3] as Map<String, dynamic>?;
        _motorStats = results[4] as Map<String, dynamic>?;
        _isLoading = false;
      });
      
    } catch (e) {
      print('❌ Analytics Error: $e');
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: _isLoading ? _buildLoadingScreen() : _buildContent(),
    );
  }

  Widget _buildLoadingScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(
              Theme.of(context).primaryColor,
            ),
          ),
          SizedBox(height: getProportionateScreenHeight(16)),
          Text(
            'Đang tải dữ liệu phân tích...',
            style: TextStyle(
              fontSize: getProportionateScreenWidth(14),
              color: Theme.of(context).textTheme.bodyMedium!.color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Container(
            padding: EdgeInsets.all(getProportionateScreenWidth(16)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                SizedBox(height: getProportionateScreenHeight(20)),
                _buildTimeRangeSelector(),
                SizedBox(height: getProportionateScreenHeight(20)),
                _buildStatsOverview(),
                SizedBox(height: getProportionateScreenHeight(20)),
                _buildChartsSection(),
                SizedBox(height: getProportionateScreenHeight(20)),
                _buildDeviceStatsSection(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Phân Tích Thông Minh',
                style: TextStyle(
                  fontSize: getProportionateScreenWidth(24),
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).textTheme.displayLarge!.color,
                ),
              ),
              SizedBox(height: getProportionateScreenHeight(4)),
              Text(
                'Dữ liệu từ Firebase Firestore',
                style: TextStyle(
                  fontSize: getProportionateScreenWidth(14),
                  color: Theme.of(context).textTheme.bodyMedium!.color?.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: EdgeInsets.all(getProportionateScreenWidth(12)),
          decoration: BoxDecoration(
            color: Colors.green.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            Icons.cloud_done,
            color: Colors.green,
            size: getProportionateScreenWidth(24),
          ),
        ),
      ],
    );
  }

  Widget _buildTimeRangeSelector() {
    return Container(
      height: getProportionateScreenHeight(40),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _timeRanges.length,
        itemBuilder: (context, index) {
          final timeRange = _timeRanges[index];
          final isSelected = timeRange == _selectedTimeRange;
          
          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedTimeRange = timeRange;
              });
              _loadAnalyticsData();
            },
            child: Container(
              margin: EdgeInsets.only(right: getProportionateScreenWidth(8)),
              padding: EdgeInsets.symmetric(
                horizontal: getProportionateScreenWidth(16),
                vertical: getProportionateScreenHeight(8),
              ),
              decoration: BoxDecoration(
                color: isSelected 
                    ? Theme.of(context).primaryColor 
                    : Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected 
                      ? Theme.of(context).primaryColor 
                      : Colors.grey.withValues(alpha: 0.3),
                ),
              ),
              child: Text(
                _getTimeRangeLabel(timeRange),
                style: TextStyle(
                  fontSize: getProportionateScreenWidth(12),
                  fontWeight: FontWeight.w500,
                  color: isSelected 
                      ? Colors.white 
                      : Theme.of(context).textTheme.bodyMedium!.color,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatsOverview() {
    return Row(
      children: [
        Expanded(
          child: _buildOverviewCard(
            title: 'Tiêu Thụ Điện',
            value: _getCurrentPowerValue(),
            unit: 'W',
            icon: Icons.electric_bolt,
            color: Colors.orange,
          ),
        ),
        SizedBox(width: getProportionateScreenWidth(12)),
        Expanded(
          child: _buildOverviewCard(
            title: 'Nhiệt Độ',
            value: _getCurrentTemperatureValue(),
            unit: '°C',
            icon: Icons.thermostat,
            color: Colors.blue,
          ),
        ),
      ],
    );
  }

  Widget _buildOverviewCard({
    required String title,
    required String value,
    required String unit,
    required IconData icon,
    required Color color,
  }) {
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
            '$value $unit',
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
              color: Theme.of(context).textTheme.bodyMedium!.color?.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChartsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Biểu Đồ Theo Dõi',
          style: TextStyle(
            fontSize: getProportionateScreenWidth(18),
            fontWeight: FontWeight.w600,
            color: Theme.of(context).textTheme.displayLarge!.color,
          ),
        ),
        SizedBox(height: getProportionateScreenHeight(16)),
        _buildChart(
          'Công Suất Tiêu Thụ (W)', 
          _powerData ?? [], 
          Colors.orange,
          Icons.electric_bolt,
        ),
        SizedBox(height: getProportionateScreenHeight(16)),
        _buildChart(
          'Nhiệt Độ (°C)', 
          _temperatureData ?? [], 
          Colors.blue,
          Icons.thermostat,
        ),
      ],
    );
  }

  Widget _buildChart(String title, List<Map<String, dynamic>> data, Color color, IconData icon) {
    // Convert Firebase data to chart data
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: getProportionateScreenWidth(14),
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).textTheme.displayLarge!.color,
                ),
              ),
              Icon(icon, color: color, size: 20),
            ],
          ),
          SizedBox(height: getProportionateScreenHeight(16)),
          SizedBox(
            height: getProportionateScreenHeight(200),
            child: chartData.isEmpty
                ? Center(
                    child: Text(
                      'Không có dữ liệu',
                      style: TextStyle(
                        color: Theme.of(context).textTheme.bodyMedium!.color?.withValues(alpha: 0.6),
                      ),
                    ),
                  )
                : SfCartesianChart(
                    primaryXAxis: DateTimeAxis(
                      axisLabelFormatter: (axisLabelRenderArgs) {
                        final DateTime date = DateTime.fromMillisecondsSinceEpoch(
                          axisLabelRenderArgs.value.toInt(),
                        );
                        return ChartAxisLabel(
                          '${date.hour}:${date.minute.toString().padLeft(2, '0')}',
                          TextStyle(
                            fontSize: getProportionateScreenWidth(10),
                            color: Theme.of(context).textTheme.bodyMedium!.color?.withValues(alpha: 0.7),
                          ),
                        );
                      },
                    ),
                    primaryYAxis: NumericAxis(
                      axisLabelFormatter: (axisLabelRenderArgs) {
                        return ChartAxisLabel(
                          axisLabelRenderArgs.value.toStringAsFixed(1),
                          TextStyle(
                            fontSize: getProportionateScreenWidth(10),
                            color: Theme.of(context).textTheme.bodyMedium!.color?.withValues(alpha: 0.7),
                          ),
                        );
                      },
                    ),
                    series: <CartesianSeries>[
                      LineSeries<ChartData, DateTime>(
                        dataSource: chartData,
                        xValueMapper: (ChartData data, _) => data.time,
                        yValueMapper: (ChartData data, _) => data.value,
                        color: color,
                        width: 2,
                        markerSettings: MarkerSettings(
                          isVisible: true,
                          color: color,
                          borderColor: Colors.white,
                          borderWidth: 2,
                          height: 4,
                          width: 4,
                        ),
                      ),
                    ],
                    plotAreaBorderWidth: 0,
                    borderWidth: 0,
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeviceStatsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Thống Kê Thiết Bị',
          style: TextStyle(
            fontSize: getProportionateScreenWidth(18),
            fontWeight: FontWeight.w600,
            color: Theme.of(context).textTheme.displayLarge!.color,
          ),
        ),
        SizedBox(height: getProportionateScreenHeight(16)),
        _buildDeviceStatsCard('Đèn Cổng', _led1Stats?['led_gate'], Colors.amber, Icons.lightbulb),
        SizedBox(height: getProportionateScreenHeight(12)),
        _buildDeviceStatsCard('Đèn Xung Quanh', _led2Stats?['led_around'], Colors.green, Icons.lightbulb_outline),
        SizedBox(height: getProportionateScreenHeight(12)),
        _buildDeviceStatsCard('Motor', _motorStats?['motor'], Colors.purple, Icons.settings),
      ],
    );
  }

  Widget _buildDeviceStatsCard(String deviceName, Map<String, dynamic>? stats, Color color, IconData icon) {
    final usagePercentage = stats != null ? 
      double.tryParse(stats['usage_percentage']?.toString() ?? '0') ?? 0 : 0;
    
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
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(icon, color: color, size: 16),
              ),
              SizedBox(width: getProportionateScreenWidth(8)),
              Text(
                deviceName,
                style: TextStyle(
                  fontSize: getProportionateScreenWidth(14),
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).textTheme.displayLarge!.color,
                ),
              ),
              const Spacer(),
              Text(
                '${usagePercentage.toStringAsFixed(1)}%',
                style: TextStyle(
                  fontSize: getProportionateScreenWidth(12),
                  fontWeight: FontWeight.w500,
                  color: color,
                ),
              ),
            ],
          ),
          SizedBox(height: getProportionateScreenHeight(8)),
          LinearProgressIndicator(
            value: usagePercentage / 100,
            backgroundColor: Colors.grey.withValues(alpha: 0.2),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ],
      ),
    );
  }

  String _getCurrentPowerValue() {
    if (_powerData != null && _powerData!.isNotEmpty) {
      final lastValue = _powerData!.last['_value']?.toString() ?? '0';
      final power = double.tryParse(lastValue) ?? 0;
      return power.toStringAsFixed(1);
    }
    return '0.0';
  }

  String _getCurrentTemperatureValue() {
    if (_temperatureData != null && _temperatureData!.isNotEmpty) {
      final lastValue = _temperatureData!.last['_value']?.toString() ?? '0';
      final temp = double.tryParse(lastValue) ?? 0;
      return temp.toStringAsFixed(1);
    }
    return '0.0';
  }

  String _getTimeRangeLabel(String range) {
    switch (range) {
      case '1h':
        return '1 Giờ';
      case '6h':
        return '6 Giờ';
      case '24h':
        return '24 Giờ';
      case '7d':
        return '7 Ngày';
      case '30d':
        return '30 Ngày';
      default:
        return range;
    }
  }
}
