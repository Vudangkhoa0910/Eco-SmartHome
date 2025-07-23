import 'package:flutter/material.dart';
import 'package:smart_home/config/size_config.dart';
import 'package:smart_home/service/ai_analytics_service.dart';
import 'package:smart_home/service/firebase_data_service.dart';
import 'package:smart_home/src/screens/analytics_screen/components/ai_insights_card.dart';
import 'package:smart_home/src/screens/analytics_screen/components/energy_optimization_card.dart';
import 'package:smart_home/src/screens/analytics_screen/components/ai_chat_widget.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:intl/intl.dart';

class AIAnalyticsDetailScreen extends StatefulWidget {
  static String routeName = '/ai-analytics-detail-screen';
  
  const AIAnalyticsDetailScreen({Key? key}) : super(key: key);

  @override
  State<AIAnalyticsDetailScreen> createState() => _AIAnalyticsDetailScreenState();
}

class _AIAnalyticsDetailScreenState extends State<AIAnalyticsDetailScreen> {
  bool _isLoading = true;
  Map<String, dynamic> _aiInsights = {};
  Map<String, dynamic> _aiTrends = {};
  Map<String, dynamic> _deviceStats = {};
  String _optimizationReport = '';
  
  // Firebase data
  final FirebaseDataService _firebaseService = FirebaseDataService();
  double _currentPowerConsumption = 0.0;
  double _dailyEnergyConsumption = 0.0;
  double _monthlyEnergyConsumption = 0.0;
  double _monthlyCost = 0.0;
  List<Map<String, dynamic>> _deviceUsageData = [];
  List<Map<String, dynamic>> _dailyUsageData = [];

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  Future<void> _loadAllData() async {
    setState(() => _isLoading = true);
    
    try {
      // Load Firebase data first
      await _loadFirebaseData();
      
      // Then generate AI insights
      await _generateAIInsights();
      
      setState(() => _isLoading = false);
    } catch (e) {
      print('❌ Error loading AI analytics data: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadFirebaseData() async {
    // Load basic analytics data
    _currentPowerConsumption = await _firebaseService.getCurrentPowerConsumption();
    _dailyEnergyConsumption = await _firebaseService.getDailyEnergyConsumption();
    _monthlyEnergyConsumption = await _firebaseService.getMonthlyEnergyConsumption();
    _monthlyCost = _monthlyEnergyConsumption * 2927; // VND per kWh
    
    // Load device and daily usage data using existing methods
    await _loadDeviceUsageData();
    await _loadDailyUsageData();
    
    // Load device statistics
    _deviceStats = await _firebaseService.getDeviceStats('', timeRange: '7d');
  }

  Future<void> _loadDeviceUsageData() async {
    try {
      print('📊 Loading device usage data...');
      final deviceStatsData = await _firebaseService.getDeviceStats('');
      print('📊 Device stats loaded: ${deviceStatsData.keys.length} devices');

      // Convert to format expected by AI
      _deviceUsageData = [];
      deviceStatsData.forEach((device, stats) {
        final usage = stats['usage_percentage'] ?? 0.0;
        _deviceUsageData.add({
          'device': device,
          'value': usage,
        });
      });
      
      print('📊 Device usage data processed: ${_deviceUsageData.length} devices');
    } catch (e) {
      print('❌ Error loading device usage data: $e');
      _deviceUsageData = [];
    }
  }

  Future<void> _loadDailyUsageData() async {
    try {
      print('📈 Loading daily usage data...');
      
      // Get last 7 days of power consumption
      final endDate = DateTime.now();
      final startDate = endDate.subtract(Duration(days: 7));
      
      final powerHistory = await _firebaseService.getPowerConsumptionHistory(
        startTime: startDate,
        endTime: endDate,
      );

      print('📈 Found ${powerHistory.length} daily records');

      // Group data by day and calculate averages
      final Map<String, List<double>> dailyPower = {};

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
          final dayKey = DateFormat('MM/dd').format(timestamp);
          final energyKwh = (data['energy_kwh'] as num?)?.toDouble() ?? 0.0;

          dailyPower.putIfAbsent(dayKey, () => []);
          dailyPower[dayKey]!.add(energyKwh);
        }
      }

      // Convert to format expected by AI
      _dailyUsageData = [];
      dailyPower.forEach((day, values) {
        final avgUsage = values.isNotEmpty ? values.reduce((a, b) => a + b) / values.length : 0.0;
        _dailyUsageData.add({
          'day': day,
          'usage': avgUsage,
        });
      });

      // Sort by date
      _dailyUsageData.sort((a, b) => a['day'].compareTo(b['day']));
      
      print('📈 Daily usage data processed: ${_dailyUsageData.length} days');
    } catch (e) {
      print('❌ Error loading daily usage data: $e');
      _dailyUsageData = [];
    }
  }

  Future<void> _generateAIInsights() async {
    try {
      // Generate comprehensive AI insights
      _aiInsights = await AIAnalyticsService.generateEnergyInsights(
        currentPower: _currentPowerConsumption,
        dailyConsumption: _dailyEnergyConsumption,
        monthlyConsumption: _monthlyEnergyConsumption,
        monthlyCost: _monthlyCost,
        deviceUsage: _deviceUsageData,
        dailyUsage: _dailyUsageData,
      );
      
      // Analyze trends
      _aiTrends = await AIAnalyticsService.analyzeTrends(
        dailyUsage: _dailyUsageData,
        currentMonthConsumption: _monthlyEnergyConsumption,
      );
      
      // Generate optimization report
      _optimizationReport = await AIAnalyticsService.generateOptimizationReport(
        deviceStats: _deviceStats,
        monthlyConsumption: _monthlyEnergyConsumption,
        monthlyCost: _monthlyCost,
      );
      
    } catch (e) {
      print('❌ Error generating AI insights: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('AI Analytics Chi Tiết'),
        elevation: 0,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        actions: [
          IconButton(
            icon: Icon(Icons.chat_bubble_outline),
            onPressed: _showAIChatDialog,
            tooltip: 'Chat với AI',
          ),
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _isLoading ? null : _loadAllData,
          ),
        ],
      ),
      body: _isLoading ? _buildLoadingScreen() : _buildContent(),
    );
  }

  Widget _buildLoadingScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).primaryColor),
          ),
          SizedBox(height: 16),
          Text(
            'Đang phân tích dữ liệu với AI...',
            style: TextStyle(
              fontSize: 16,
              color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Có thể mất vài giây để tạo insights chính xác',
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.5),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // AI Summary Dashboard
          _buildAISummaryDashboard(),
          
          SizedBox(height: 20),
          
          // AI Insights Card
          if (_aiInsights.isNotEmpty)
            AIInsightsCard(
              insights: _aiInsights,
              onViewDetails: null, // Already in detail screen
            ),
          
          SizedBox(height: 20),
          
          // Energy Optimization
          if (_aiInsights.containsKey('device_optimization'))
            EnergyOptimizationCard(
              deviceOptimization: List<Map<String, dynamic>>.from(
                _aiInsights['device_optimization'] ?? []
              ),
              onOptimizeAll: _applyAllOptimizations,
            ),
          
          SizedBox(height: 20),
          
          // Trends Analysis
          if (_aiTrends.isNotEmpty) _buildTrendsAnalysis(),
          
          SizedBox(height: 20),
          
          // Detailed Optimization Report
          _buildOptimizationReport(),
          
          SizedBox(height: 20),
          
          // Energy Usage Chart with AI annotations
          _buildAIEnergyChart(),
          
          SizedBox(height: 40), // Extra padding at bottom
        ],
      ),
    );
  }

  Widget _buildAISummaryDashboard() {
    final summary = _aiInsights['summary'] ?? {};
    final predictions = _aiInsights['predictions'] ?? {};
    
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).primaryColor.withOpacity(0.1),
            Theme.of(context).primaryColor.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).primaryColor.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.dashboard,
                color: Theme.of(context).primaryColor,
                size: 28,
              ),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'AI Analytics Dashboard',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).textTheme.titleLarge?.color,
                  ),
                ),
              ),
              if (summary['score'] != null)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getScoreColor(summary['score']).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Score: ${summary['score']}/100',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: _getScoreColor(summary['score']),
                    ),
                  ),
                ),
            ],
          ),
          
          SizedBox(height: 16),
          
          // Key metrics row
          Row(
            children: [
              Expanded(child: _buildMetricCard('Công suất hiện tại', '${_currentPowerConsumption.toStringAsFixed(1)}W', Icons.flash_on, Colors.orange)),
              SizedBox(width: 12),
              Expanded(child: _buildMetricCard('Tiêu thụ hôm nay', '${_dailyEnergyConsumption.toStringAsFixed(2)} kWh', Icons.battery_charging_full, Colors.green)),
            ],
          ),
          
          SizedBox(height: 12),
          
          Row(
            children: [
              Expanded(child: _buildMetricCard('Chi phí tháng', '${_monthlyCost.toStringAsFixed(0)} VND', Icons.attach_money, Colors.red)),
              SizedBox(width: 12),
              Expanded(child: _buildMetricCard('Xu hướng', predictions['monthly_cost_trend'] ?? 'Đang phân tích', Icons.trending_up, Colors.blue)),
            ],
          ),
          
          if (summary['message'] != null) ...[
            SizedBox(height: 16),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor.withOpacity(0.5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.lightbulb_outline, color: Colors.amber, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      summary['message'],
                      style: TextStyle(
                        fontSize: 14,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMetricCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor.withOpacity(0.7),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 11,
              color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildTrendsAnalysis() {
    final trends = _aiTrends['trend_analysis'] ?? {};
    final predictions = _aiTrends['predictions'] ?? {};
    final patterns = _aiTrends['patterns'] ?? [];
    
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.black.withOpacity(0.3)
                : Colors.black.withOpacity(0.1),
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
              Icon(Icons.trending_up, color: Colors.purple),
              SizedBox(width: 8),
              Text(
                'Phân tích xu hướng',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          
          SizedBox(height: 16),
          
          if (trends.isNotEmpty) ...[
            _buildTrendItem('Xu hướng', trends['direction'] ?? '', Icons.timeline),
            _buildTrendItem('Thay đổi', trends['percentage_change'] ?? '', Icons.percent),
            _buildTrendItem('Ngày cao điểm', (trends['peak_days'] as List?)?.join(', ') ?? '', Icons.arrow_upward),
            _buildTrendItem('Ngày thấp điểm', (trends['low_days'] as List?)?.join(', ') ?? '', Icons.arrow_downward),
          ],
          
          if (predictions.isNotEmpty) ...[
            SizedBox(height: 12),
            Text(
              'Dự đoán',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 8),
            _buildTrendItem('Tuần tới', predictions['next_week'] ?? '', Icons.calendar_view_week),
            _buildTrendItem('Cuối tháng', predictions['monthly_forecast'] ?? '', Icons.calendar_month),
            _buildTrendItem('Chi phí ước tính', predictions['cost_estimate'] ?? '', Icons.attach_money),
          ],
          
          if (patterns.isNotEmpty) ...[
            SizedBox(height: 12),
            Text(
              'Patterns phát hiện',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 8),
            ...patterns.map<Widget>((pattern) => _buildPatternItem(pattern)),
          ],
        ],
      ),
    );
  }

  Widget _buildTrendItem(String label, String value, IconData icon) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey[600]),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              '$label: ',
              style: TextStyle(fontSize: 14),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPatternItem(Map<String, dynamic> pattern) {
    return Container(
      margin: EdgeInsets.only(bottom: 8),
      padding: EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.purple.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            pattern['pattern'] ?? '',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
          ),
          SizedBox(height: 4),
          Row(
            children: [
              Text(
                'Tần suất: ${pattern['frequency'] ?? ''}',
                style: TextStyle(fontSize: 11, color: Colors.grey[600]),
              ),
              SizedBox(width: 16),
              Text(
                'Tác động: ${pattern['impact'] ?? ''}',
                style: TextStyle(fontSize: 11, color: Colors.grey[600]),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOptimizationReport() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.black.withOpacity(0.3)
                : Colors.black.withOpacity(0.1),
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
              Icon(Icons.description, color: Colors.green),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Báo cáo tối ưu hóa chi tiết',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                icon: Icon(Icons.refresh),
                onPressed: () async {
                  setState(() => _isLoading = true);
                  await _generateAIInsights();
                  setState(() => _isLoading = false);
                },
              ),
            ],
          ),
          
          SizedBox(height: 16),
          
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.grey[800]
                  : Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              _optimizationReport.isNotEmpty 
                  ? _optimizationReport 
                  : 'Đang tạo báo cáo tối ưu hóa...',
              style: TextStyle(
                fontSize: 14,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAIEnergyChart() {
    if (_dailyUsageData.isEmpty) return SizedBox.shrink();
    
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.black.withOpacity(0.3)
                : Colors.black.withOpacity(0.1),
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
              Icon(Icons.show_chart, color: Colors.blue),
              SizedBox(width: 8),
              Text(
                'Biểu đồ tiêu thụ với AI Analysis',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          
          SizedBox(height: 16),
          
          Container(
            height: 200,
            child: SfCartesianChart(
              primaryXAxis: CategoryAxis(),
              primaryYAxis: NumericAxis(
                title: AxisTitle(text: 'kWh'),
              ),
              title: ChartTitle(text: 'Xu hướng tiêu thụ 7 ngày gần nhất'),
              legend: Legend(isVisible: true),
              tooltipBehavior: TooltipBehavior(enable: true),
              series: <CartesianSeries<Map<String, dynamic>, String>>[
                LineSeries<Map<String, dynamic>, String>(
                  dataSource: _dailyUsageData.take(7).toList(),
                  xValueMapper: (data, _) => data['day'] ?? '',
                  yValueMapper: (data, _) => data['usage'] ?? 0.0,
                  name: 'Tiêu thụ thực tế',
                  color: Colors.blue,
                  markerSettings: MarkerSettings(isVisible: true),
                ),
                // Add average line
                LineSeries<Map<String, dynamic>, String>(
                  dataSource: _dailyUsageData.take(7).map((data) => {
                    'day': data['day'],
                    'usage': _calculateAverage(),
                  }).toList(),
                  xValueMapper: (data, _) => data['day'] ?? '',
                  yValueMapper: (data, _) => data['usage'] ?? 0.0,
                  name: 'Trung bình',
                  color: Colors.orange,
                  dashArray: [5, 5],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  double _calculateAverage() {
    if (_dailyUsageData.isEmpty) return 0.0;
    final total = _dailyUsageData.fold(0.0, (sum, data) => sum + (data['usage'] ?? 0.0));
    return total / _dailyUsageData.length;
  }

  Color _getScoreColor(int score) {
    if (score >= 80) return Colors.green;
    if (score >= 60) return Colors.orange;
    return Colors.red;
  }

  void _applyAllOptimizations() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Đang áp dụng tất cả tối ưu hóa được đề xuất...'),
        backgroundColor: Colors.green,
        action: SnackBarAction(
          label: 'Xem tiến trình',
          onPressed: () {
            // TODO: Navigate to optimization progress screen
          },
        ),
      ),
    );
  }

  void _showAIChatDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        insetPadding: EdgeInsets.all(16),
        child: AIChatWidget(
          currentData: {
            'currentPower': _currentPowerConsumption,
            'dailyEnergy': _dailyEnergyConsumption,
            'monthlyEnergy': _monthlyEnergyConsumption,
            'deviceCount': _deviceUsageData.length,
            'insights': _aiInsights,
            'trends': _aiTrends,
          },
        ),
      ),
    );
  }
}
