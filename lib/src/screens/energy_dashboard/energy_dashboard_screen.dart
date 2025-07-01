import 'package:flutter/material.dart';
import 'package:smart_home/config/size_config.dart';
import 'package:smart_home/service/influxdb_service.dart';
import 'package:smart_home/provider/getit.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

class EnergyDashboardScreen extends StatefulWidget {
  const EnergyDashboardScreen({Key? key}) : super(key: key);

  @override
  State<EnergyDashboardScreen> createState() => _EnergyDashboardScreenState();
}

class _EnergyDashboardScreenState extends State<EnergyDashboardScreen> {
  final InfluxDBService _influxDB = getIt<InfluxDBService>();
  
  List<Map<String, dynamic>>? _energyData;
  List<Map<String, dynamic>>? _powerData;
  Map<String, double>? _zoneConsumption;
  bool _isLoading = true;
  String _selectedTimeRange = '-24h';
  
  final List<String> _timeRanges = [
    '-1h',
    '-6h', 
    '-24h',
    '-7d',
    '-30d'
  ];

  @override
  void initState() {
    super.initState();
    _loadEnergyData();
  }

  Future<void> _loadEnergyData() async {
    setState(() => _isLoading = true);
    
    try {
      final endTime = DateTime.now();
      final startTime = _parseTimeRange(_selectedTimeRange, endTime);
      
      final results = await Future.wait([
        _influxDB.querySensorHistory(
          sensorType: 'energy',
          timeRange: _selectedTimeRange,
          aggregation: 'sum',
        ),
        _influxDB.querySensorHistory(
          sensorType: 'power',
          timeRange: _selectedTimeRange,
          aggregation: 'mean',
        ),
        _influxDB.getEnergyConsumptionByZone(
          startTime: startTime,
          endTime: endTime,
        ),
      ]);
      
      setState(() {
        _energyData = results[0] as List<Map<String, dynamic>>?;
        _powerData = results[1] as List<Map<String, dynamic>>?;
        _zoneConsumption = results[2] as Map<String, double>?;
        _isLoading = false;
      });
      
    } catch (e) {
      print('❌ Energy Dashboard Error: $e');
      setState(() => _isLoading = false);
    }
  }

  DateTime _parseTimeRange(String timeRange, DateTime endTime) {
    switch (timeRange) {
      case '1h':
        return endTime.subtract(const Duration(hours: 1));
      case '6h':
        return endTime.subtract(const Duration(hours: 6));
      case '24h':
        return endTime.subtract(const Duration(hours: 24));
      case '7d':
        return endTime.subtract(const Duration(days: 7));
      case '30d':
        return endTime.subtract(const Duration(days: 30));
      default:
        return endTime.subtract(const Duration(hours: 24));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bảng điều khiển năng lượng'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              setState(() => _selectedTimeRange = value);
              _loadEnergyData();
            },
            itemBuilder: (context) => _timeRanges.map((range) => 
              PopupMenuItem(
                value: range,
                child: Text(_getTimeRangeLabel(range)),
              ),
            ).toList(),
            child: Container(
              margin: const EdgeInsets.only(right: 16),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _getTimeRangeLabel(_selectedTimeRange),
                    style: const TextStyle(color: Colors.green, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.arrow_drop_down, color: Colors.green),
                ],
              ),
            ),
          ),
        ],
      ),
      body: _isLoading ? 
        const Center(child: CircularProgressIndicator()) :
        RefreshIndicator(
          onRefresh: _loadEnergyData,
          child: SingleChildScrollView(
            padding: EdgeInsets.all(getProportionateScreenWidth(16)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildEnergyOverview(),
                
                SizedBox(height: getProportionateScreenHeight(24)),
                
                _buildEnergyChart(),
                
                SizedBox(height: getProportionateScreenHeight(24)),
                
                _buildPowerChart(),
                
                SizedBox(height: getProportionateScreenHeight(24)),
                
                _buildZoneConsumption(),
                
                SizedBox(height: getProportionateScreenHeight(24)),
                
                _buildDataLocationsInfo(),
                
                SizedBox(height: getProportionateScreenHeight(100)),
              ],
            ),
          ),
        ),
    );
  }

  Widget _buildEnergyOverview() {
    final currentPower = _energyData?.isNotEmpty == true ? 
      double.tryParse(_energyData!.last['power']?.toString() ?? '0') ?? 0 : 0;
    final currentEfficiency = _energyData?.isNotEmpty == true ? 
      double.tryParse(_energyData!.last['efficiency']?.toString() ?? '0') ?? 0 : 0;
    final estimatedCost = _energyData?.isNotEmpty == true ? 
      double.tryParse(_energyData!.last['estimated_cost_per_hour']?.toString() ?? '0') ?? 0 : 0;
    
    return Container(
      padding: EdgeInsets.all(getProportionateScreenWidth(20)),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF4CAF50), Color(0xFF2E7D32)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '🔋 Tình trạng năng lượng',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: getProportionateScreenHeight(16)),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildEnergyMetric('Công suất hiện tại', '${currentPower.toStringAsFixed(1)} W'),
              _buildEnergyMetric('Hiệu suất', '${currentEfficiency.toStringAsFixed(1)}%'),
              _buildEnergyMetric('Chi phí/giờ', '≈${estimatedCost.toStringAsFixed(0)} đ'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEnergyMetric(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.8),
            fontSize: 11,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildEnergyChart() {
    if (_energyData == null || _energyData!.isEmpty) {
      return _buildEmptyChart('Biểu đồ năng lượng tiêu thụ');
    }

    final chartData = _energyData!.map((item) {
      final timeStr = item['_time']?.toString() ?? '';
      final powerStr = item['power']?.toString() ?? '0';
      final power = double.tryParse(powerStr) ?? 0;
      
      DateTime time;
      try {
        time = DateTime.parse(timeStr);
      } catch (e) {
        time = DateTime.now();
      }
      
      return ChartData(time, power);
    }).toList();

    return _buildChart(
      title: '⚡ Năng lượng tiêu thụ theo thời gian',
      data: chartData,
      unit: 'W',
      color: Colors.orange,
    );
  }

  Widget _buildPowerChart() {
    if (_powerData == null || _powerData!.isEmpty) {
      return _buildEmptyChart('Biểu đồ hiệu suất năng lượng');
    }

    final chartData = _powerData!.map((item) {
      final timeStr = item['_time']?.toString() ?? '';
      final efficiencyStr = item['efficiency']?.toString() ?? '0';
      final efficiency = double.tryParse(efficiencyStr) ?? 0;
      
      DateTime time;
      try {
        time = DateTime.parse(timeStr);
      } catch (e) {
        time = DateTime.now();
      }
      
      return ChartData(time, efficiency);
    }).toList();

    return _buildChart(
      title: '📊 Hiệu suất năng lượng',
      data: chartData,
      unit: '%',
      color: Colors.blue,
    );
  }

  Widget _buildChart({
    required String title,
    required List<ChartData> data,
    required String unit,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.all(getProportionateScreenWidth(16)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium!.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: getProportionateScreenHeight(16)),
          SizedBox(
            height: 200,
            child: SfCartesianChart(
              primaryXAxis: DateTimeAxis(),
              primaryYAxis: NumericAxis(
                labelFormat: '{value}$unit',
              ),
              series: <CartesianSeries<ChartData, DateTime>>[
                LineSeries<ChartData, DateTime>(
                  dataSource: data,
                  xValueMapper: (ChartData data, _) => data.time,
                  yValueMapper: (ChartData data, _) => data.value,
                  color: color,
                  width: 2,
                ),
              ],
              tooltipBehavior: TooltipBehavior(enable: true),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildZoneConsumption() {
    if (_zoneConsumption == null || _zoneConsumption!.isEmpty) {
      return Container(
        padding: EdgeInsets.all(getProportionateScreenWidth(16)),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Text(
              '🏠 Tiêu thụ theo khu vực',
              style: Theme.of(context).textTheme.titleMedium!.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 40),
            Icon(
              Icons.location_off,
              size: 48,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Chưa có dữ liệu khu vực',
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 40),
          ],
        ),
      );
    }

    return Container(
      padding: EdgeInsets.all(getProportionateScreenWidth(16)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '🏠 Tiêu thụ theo khu vực',
            style: Theme.of(context).textTheme.titleMedium!.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: getProportionateScreenHeight(16)),
          ..._zoneConsumption!.entries.map((entry) => 
            _buildZoneItem(entry.key, entry.value)
          ).toList(),
        ],
      ),
    );
  }

  Widget _buildZoneItem(String zone, double consumption) {
    return Container(
      margin: EdgeInsets.only(bottom: getProportionateScreenHeight(8)),
      padding: EdgeInsets.all(getProportionateScreenWidth(12)),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            zone,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            '${consumption.toStringAsFixed(1)} Wh',
            style: const TextStyle(
              color: Colors.blue,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDataLocationsInfo() {
    return Container(
      padding: EdgeInsets.all(getProportionateScreenWidth(16)),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blue.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: Colors.blue, size: 20),
              SizedBox(width: getProportionateScreenWidth(8)),
              Text(
                'Vị trí lưu trữ dữ liệu',
                style: TextStyle(
                  color: Colors.blue,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          SizedBox(height: getProportionateScreenHeight(12)),
          _buildDataLocationItem(
            '📊 Sensor Data', 
            'measurement: sensor_data',
            'Nhiệt độ, độ ẩm, điện áp, dòng điện, công suất'
          ),
          _buildDataLocationItem(
            '⚡ Energy Consumption', 
            'measurement: energy_consumption',
            'Dữ liệu tiêu thụ năng lượng chi tiết với hiệu suất & chi phí'
          ),
          _buildDataLocationItem(
            '🔌 Power Consumption', 
            'measurement: power_consumption',
            'Dữ liệu công suất theo từng thiết bị và khu vực'
          ),
          _buildDataLocationItem(
            '🏠 Device State', 
            'measurement: device_state',
            'Trạng thái ON/OFF của các thiết bị'
          ),
        ],
      ),
    );
  }

  Widget _buildDataLocationItem(String title, String measurement, String description) {
    return Container(
      margin: EdgeInsets.only(bottom: getProportionateScreenHeight(8)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
          Text(
            measurement,
            style: TextStyle(
              color: Colors.blue[700],
              fontSize: 12,
              fontFamily: 'monospace',
            ),
          ),
          Text(
            description,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 11,
            ),
          ),
          SizedBox(height: getProportionateScreenHeight(4)),
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
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium!.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 40),
          Icon(
            Icons.show_chart,
            size: 48,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Chưa có dữ liệu',
            style: TextStyle(color: Colors.grey[600]),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  String _getTimeRangeLabel(String range) {
    switch (range) {
      case '-1h': return '1 giờ';
      case '-6h': return '6 giờ';
      case '-24h': return '24 giờ';
      case '-7d': return '7 ngày';
      case '-30d': return '30 ngày';
      default: return range;
    }
  }
}

class ChartData {
  final DateTime time;
  final double value;
  
  ChartData(this.time, this.value);
}
