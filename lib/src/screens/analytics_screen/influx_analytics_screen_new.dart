import 'package:flutter/material.dart';
import 'package:smart_home/config/size_config.dart';
import 'package:smart_home/service/influxdb_service.dart';
import 'package:smart_home/provider/getit.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

class ChartData {
  final DateTime time;
  final double value;
  
  ChartData(this.time, this.value);
}

class InfluxAnalyticsScreen extends StatefulWidget {
  const InfluxAnalyticsScreen({Key? key}) : super(key: key);

  @override
  State<InfluxAnalyticsScreen> createState() => _InfluxAnalyticsScreenState();
}

class _InfluxAnalyticsScreenState extends State<InfluxAnalyticsScreen> {
  final InfluxDBService _influxDB = getIt<InfluxDBService>();
  
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
      final tempFuture = _influxDB.querySensorHistory(
        timeRange: _selectedTimeRange,
        sensorType: 'temperature',
        aggregation: 'mean',
      );
      
      final powerFuture = _influxDB.querySensorHistory(
        timeRange: _selectedTimeRange,
        sensorType: 'power',
        aggregation: 'mean',
      );
      
      final led1StatsFuture = _influxDB.getDeviceStats('led1', timeRange: _selectedTimeRange);
      final led2StatsFuture = _influxDB.getDeviceStats('led2', timeRange: _selectedTimeRange);
      final motorStatsFuture = _influxDB.getDeviceStats('motor', timeRange: _selectedTimeRange);
      
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
    return Container(
      color: const Color(0xFFF8F9FA),
      child: RefreshIndicator(
        onRefresh: _loadAnalyticsData,
        color: const Color(0xFF2196F3),
        child: SingleChildScrollView(
          padding: EdgeInsets.all(getProportionateScreenWidth(20)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTimeRangeSelector(),
              SizedBox(height: getProportionateScreenHeight(20)),
              _buildDeviceUsageCards(),
              SizedBox(height: getProportionateScreenHeight(24)),
              _buildEnvironmentalCharts(),
              SizedBox(height: getProportionateScreenHeight(24)),
              _buildPowerChart(),
              SizedBox(height: getProportionateScreenHeight(24)),
              _buildDeviceUsageDetails(),
              SizedBox(height: getProportionateScreenHeight(100)),
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Khoảng thời gian',
            style: TextStyle(
              fontSize: getProportionateScreenWidth(16),
              fontWeight: FontWeight.w600,
              color: const Color(0xFF212121),
            ),
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
                            : const Color(0xFFF5F5F5),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _getTimeRangeLabel(range),
                        style: TextStyle(
                          color: _selectedTimeRange == range 
                              ? Colors.white
                              : const Color(0xFF757575),
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

  Widget _buildDeviceUsageCards() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tình trạng thiết bị',
          style: TextStyle(
            fontSize: getProportionateScreenWidth(18),
            fontWeight: FontWeight.w600,
            color: const Color(0xFF212121),
          ),
        ),
        SizedBox(height: getProportionateScreenHeight(12)),
        Row(
          children: [
            Expanded(child: _buildUsageCard('LED 1', _led1Stats, const Color(0xFFFF9800))),
            SizedBox(width: getProportionateScreenWidth(12)),
            Expanded(child: _buildUsageCard('LED 2', _led2Stats, const Color(0xFF2196F3))),
            SizedBox(width: getProportionateScreenWidth(12)),
            Expanded(child: _buildUsageCard('Motor', _motorStats, const Color(0xFF4CAF50))),
          ],
        ),
      ],
    );
  }

  Widget _buildUsageCard(String deviceName, Map<String, dynamic>? stats, Color color) {
    if (_isLoading) {
      return _buildSkeletonCard();
    }
    
    final usagePercentage = stats != null ? 
      double.tryParse(stats['usage_percentage']?.toString() ?? '0') ?? 0 : 0;
    
    return Container(
      padding: EdgeInsets.all(getProportionateScreenWidth(16)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
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
                child: Container(
                  width: 4,
                  height: 4,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              SizedBox(width: getProportionateScreenWidth(8)),
              Expanded(
                child: Text(
                  deviceName,
                  style: TextStyle(
                    fontSize: getProportionateScreenWidth(12),
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF212121),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: getProportionateScreenHeight(12)),
          Text(
            '${usagePercentage.toStringAsFixed(1)}%',
            style: TextStyle(
              fontSize: getProportionateScreenWidth(18),
              fontWeight: FontWeight.w600,
              color: const Color(0xFF212121),
            ),
          ),
          SizedBox(height: getProportionateScreenHeight(4)),
          Text(
            'Thời gian hoạt động',
            style: TextStyle(
              fontSize: getProportionateScreenWidth(10),
              color: const Color(0xFF757575),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSkeletonCard() {
    return Container(
      padding: EdgeInsets.all(getProportionateScreenWidth(16)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
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
                  color: const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Container(
                  width: 4,
                  height: 4,
                  decoration: const BoxDecoration(
                    color: Color(0xFFE0E0E0),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              SizedBox(width: getProportionateScreenWidth(8)),
              Container(
                width: getProportionateScreenWidth(40),
                height: 12,
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ],
          ),
          SizedBox(height: getProportionateScreenHeight(12)),
          Container(
            width: getProportionateScreenWidth(30),
            height: 18,
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(6),
            ),
          ),
          SizedBox(height: getProportionateScreenHeight(4)),
          Container(
            width: getProportionateScreenWidth(60),
            height: 10,
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnvironmentalCharts() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Môi trường',
          style: TextStyle(
            fontSize: getProportionateScreenWidth(18),
            fontWeight: FontWeight.w600,
            color: const Color(0xFF212121),
          ),
        ),
        SizedBox(height: getProportionateScreenHeight(12)),
        Row(
          children: [
            Expanded(
              child: _buildSensorChart(
                title: 'Nhiệt độ',
                data: _temperatureData,
                unit: '°C',
                color: const Color(0xFFFF9800),
              ),
            ),
            SizedBox(width: getProportionateScreenWidth(12)),
            Expanded(
              child: _buildSensorChart(
                title: 'Độ ẩm',
                data: _temperatureData?.map((e) => {
                  'time': e['time'],
                  'value': (e['value'] as double?) != null ? 
                    60 + (e['value'] as double) * 0.5 : 60
                }).toList(),
                unit: '%',
                color: const Color(0xFF2196F3),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPowerChart() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tiêu thụ điện năng',
          style: TextStyle(
            fontSize: getProportionateScreenWidth(18),
            fontWeight: FontWeight.w600,
            color: const Color(0xFF212121),
          ),
        ),
        SizedBox(height: getProportionateScreenHeight(12)),
        _buildSensorChart(
          title: 'Công suất tiêu thụ',
          data: _powerData,
          unit: 'W',
          color: const Color(0xFF9C27B0),
        ),
      ],
    );
  }

  Widget _buildSensorChart({
    required String title,
    required List<Map<String, dynamic>>? data,
    required String unit,
    required Color color,
  }) {
    if (data == null || data.isEmpty) {
      return _buildEmptyChart(title);
    }

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
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
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
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF757575),
                ),
              ),
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
          SizedBox(height: getProportionateScreenHeight(8)),
          if (chartData.isNotEmpty) ...[
            Text(
              '${chartData.last.value.toStringAsFixed(1)} $unit',
              style: TextStyle(
                color: const Color(0xFF212121),
                fontWeight: FontWeight.w600,
                fontSize: getProportionateScreenWidth(20),
              ),
            ),
            SizedBox(height: getProportionateScreenHeight(4)),
            Text(
              '${chartData.length} điểm dữ liệu',
              style: TextStyle(
                color: const Color(0xFF757575),
                fontSize: getProportionateScreenWidth(12),
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: getProportionateScreenHeight(16)),
            SizedBox(
              height: 120,
              child: SfCartesianChart(
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
                    color: color.withValues(alpha: 0.3),
                    borderColor: color,
                    borderWidth: 2,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyChart(String title) {
    return Container(
      padding: EdgeInsets.all(getProportionateScreenWidth(16)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: getProportionateScreenWidth(14),
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF757575),
                ),
              ),
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: Color(0xFFE0E0E0),
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
          SizedBox(height: getProportionateScreenHeight(24)),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF8F9FA),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.analytics_outlined,
                  size: 32,
                  color: const Color(0xFFBDBDBD),
                ),
                SizedBox(height: getProportionateScreenHeight(8)),
                Text(
                  'Chưa có dữ liệu',
                  style: TextStyle(
                    color: const Color(0xFFBDBDBD),
                    fontSize: getProportionateScreenWidth(12),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: getProportionateScreenHeight(24)),
        ],
      ),
    );
  }

  Widget _buildDeviceUsageDetails() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Chi tiết sử dụng thiết bị',
          style: TextStyle(
            fontSize: getProportionateScreenWidth(18),
            fontWeight: FontWeight.w600,
            color: const Color(0xFF212121),
          ),
        ),
        SizedBox(height: getProportionateScreenHeight(12)),
        if (_led1Stats != null) _buildDetailCard('LED 1 (Living Room)', _led1Stats!, const Color(0xFFFF9800)),
        if (_led2Stats != null) _buildDetailCard('LED 2 (Living Room)', _led2Stats!, const Color(0xFF2196F3)),
        if (_motorStats != null) _buildDetailCard('Motor (Bedroom)', _motorStats!, const Color(0xFF4CAF50)),
      ],
    );
  }

  Widget _buildDetailCard(String title, Map<String, dynamic> stats, Color color) {
    return Container(
      margin: EdgeInsets.only(bottom: getProportionateScreenHeight(12)),
      padding: EdgeInsets.all(getProportionateScreenWidth(20)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
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
                child: Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              SizedBox(width: getProportionateScreenWidth(12)),
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: getProportionateScreenWidth(16),
                  color: const Color(0xFF212121),
                ),
              ),
            ],
          ),
          SizedBox(height: getProportionateScreenHeight(16)),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  'Tỷ lệ sử dụng',
                  '${stats['usagePercentage'] ?? 0}%',
                  const Color(0xFF2196F3),
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  'Thời gian bật',
                  '${stats['onHours'] ?? 0} giờ',
                  const Color(0xFF4CAF50),
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  'Số lần bật',
                  '${stats['switchCount'] ?? 0}',
                  const Color(0xFFFF9800),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: getProportionateScreenWidth(18),
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
        SizedBox(height: getProportionateScreenHeight(4)),
        Text(
          label,
          style: TextStyle(
            fontSize: getProportionateScreenWidth(12),
            color: const Color(0xFF757575),
          ),
          textAlign: TextAlign.center,
        ),
      ],
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
}
