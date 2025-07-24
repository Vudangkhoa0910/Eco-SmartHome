import 'package:flutter/material.dart';
import 'package:smart_home/config/size_config.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:smart_home/service/firebase_data_service.dart';
import 'package:smart_home/service/ai_analytics_service.dart';
import 'package:smart_home/src/screens/analytics_screen/components/ai_insights_card.dart';
import 'package:smart_home/src/screens/analytics_screen/components/energy_optimization_card.dart';
import 'package:smart_home/src/screens/analytics_screen/components/ai_report_dialog.dart';
import 'package:smart_home/src/screens/analytics_screen/ai_analytics_detail_screen.dart';

class ChartData {
  final DateTime time;
  final double value;

  ChartData(this.time, this.value);
}

// Time Range enum for analytics
enum AnalyticsTimeRange {
  oneMonth('1 tháng', 1),
  threeMonths('3 tháng', 3),
  sixMonths('6 tháng', 6),
  oneYear('1 năm', 12);

  const AnalyticsTimeRange(this.label, this.months);
  final String label;
  final int months;
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

class _FirebaseAnalyticsScreenState extends State<FirebaseAnalyticsScreen>
    with AutomaticKeepAliveClientMixin {
  bool _isLoading = true;
  bool _isRefreshing = false;
  bool _aiEnergyModeEnabled = true;
  bool _isLoadingAIInsights = false;

  // AI Analytics data
  Map<String, dynamic> _aiInsights = {};
  Map<String, dynamic> _aiTrends = {};

  // Month selection and time range
  DateTime _selectedMonth = DateTime.now();
  AnalyticsTimeRange _selectedTimeRange = AnalyticsTimeRange.oneMonth;

  // Cache management - Tăng thời gian cache
  final Map<String, Map<String, dynamic>> _cache = {};
  static const int _cacheValidityMinutes = 20; // Tăng từ 5 lên 20 phút

  // Firebase data variables
  final FirebaseDataService _firebaseService = FirebaseDataService();
  double _currentPowerConsumption = 0.0;
  double _dailyEnergyConsumption = 0.0;
  double _monthlyEnergyConsumption = 0.0;
  double _monthlyCost = 0.0;
  List<EnergyBarData> _dailyUsageData = [];
  List<DeviceUsageData> _deviceUsageData = [];
  Map<String, dynamic> _deviceStats = {};

  // Cache để tránh load lại dữ liệu không cần thiết
  bool _dataLoaded = false;
  DateTime? _lastDataLoadTime;
  static const int _cacheValidMinutes = 15; // Tăng cache time từ 5 lên 15 phút

  @override
  bool get wantKeepAlive => true; // Keep state alive when switching pages

  @override
  void initState() {
    super.initState();
    // Ensure selected month is normalized to first day of month
    _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month, 1);
    _checkDataAndLoad();
  }

  // Check if data exists, generate sample data if needed, then load
  Future<void> _checkDataAndLoad() async {
    try {
      print('🔍 Checking data availability...');
      
      // Check if we have data
      final dataAvailability = await _firebaseService.debugCheckDataAvailability();
      
      bool hasData = false;
      for (final count in dataAvailability.values) {
        if (count > 0) {
          hasData = true;
          break;
        }
      }
      
      // If no data exists, generate sample data
      if (!hasData) {
        print('🎯 No data found, generating sample data...');
        setState(() {
          _isLoading = true;
        });
        
        final success = await _firebaseService.generateSampleAnalyticsData();
        if (success) {
          print('✅ Sample data generated successfully');
        } else {
          print('❌ Failed to generate sample data');
        }
      } else {
        print('✅ Data exists, proceeding with normal load...');
      }
      
      // Now load the analytics data
      await _loadAnalyticsDataIfNeeded();
    } catch (e) {
      print('❌ Error in _checkDataAndLoad: $e');
      await _loadAnalyticsDataIfNeeded();
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  // Check if data needs to be loaded (cache logic)
  bool _needsDataReload() {
    if (!_dataLoaded) return true;
    if (_lastDataLoadTime == null) return true;

    final now = DateTime.now();
    final timeSinceLastLoad = now.difference(_lastDataLoadTime!);
    return timeSinceLastLoad.inMinutes > _cacheValidMinutes;
  }

  // Load data only if needed (not cached or expired)
  Future<void> _loadAnalyticsDataIfNeeded() async {
    if (!_needsDataReload()) {
      // Data is still fresh, just update loading state
      if (mounted) {
        setState(() => _isLoading = false);
      }
      return;
    }

    await _loadAnalyticsData();
  }

  // Load data only - don't reload entire page
  Future<void> _loadAnalyticsData() async {
    if (!mounted) return;

    setState(() => _isLoading = true);

    try {
      print('🔄 Starting analytics data load...');
      
      // Load real data from Firebase with timeout
      await Future.wait([
        _loadCurrentPowerConsumption(),
        _loadDailyEnergyConsumption(),
        _loadMonthlyEnergyConsumption(),
        _loadDailyUsageData(),
        _loadDeviceUsageData(),
        _loadDeviceStats(),
      ]).timeout(const Duration(seconds: 10));

      // Load AI insights after data is loaded
      if (_aiEnergyModeEnabled) {
        _loadAIInsights();
      }

      if (!mounted) return;

      print('🔄 Data load completed, updating UI...');
      print('🔄 Current power: ${_currentPowerConsumption}W');
      print('🔄 Daily energy: ${_dailyEnergyConsumption} kWh');
      print('🔄 Monthly energy: ${_monthlyEnergyConsumption} kWh');
      print('🔄 Monthly cost: ${_monthlyCost} VND');
      print('🔄 Device data: ${_deviceUsageData.length} devices');

      setState(() {
        _isLoading = false;
        _dataLoaded = true;
        _lastDataLoadTime = DateTime.now();
      });
      
      print('🔄 UI updated successfully');
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
        _dataLoaded = true; // Mark as loaded even on error to prevent infinite loading
        _lastDataLoadTime = DateTime.now();
      });
    }
  }

  // Cache helper methods
  bool _isCacheValid(String key) {
    final cacheEntry = _cache[key];
    if (cacheEntry == null || cacheEntry['timestamp'] == null) return false;

    final cacheTime = cacheEntry['timestamp'] as DateTime;
    final now = DateTime.now();
    final ageMinutes = now.difference(cacheTime).inMinutes;

    return ageMinutes < _cacheValidityMinutes;
  }

  void _setCacheData(String key, dynamic data) {
    _cache[key] = {
      'data': data,
      'timestamp': DateTime.now(),
    };
  }

  T? _getCacheData<T>(String key) {
    if (_isCacheValid(key)) {
      return _cache[key]!['data'] as T?;
    }
    return null;
  }

  void _clearCache() {
    _cache.clear();
    print('🗑️ Cache cleared');
  }

  // Refresh data for selected month without rebuilding entire page
  Future<void> _refreshDataForMonth(DateTime month) async {
    if (!mounted) return;

    print('🔄 Refreshing data for month: ${_formatMonthYear(month)}');
    print(
        '🔄 Previous values - Monthly: $_monthlyEnergyConsumption kWh, Cost: $_monthlyCost VND');

    setState(() {
      _isRefreshing = true;
      _selectedMonth = month;

      // Clear cache for new month
      _clearCache();

      // Force clear ALL cache and data
      _dataLoaded = false;
      _lastDataLoadTime = null;

      // Reset all data variables to force UI update
      _monthlyEnergyConsumption = 0.0;
      _monthlyCost = 0.0;
      _dailyUsageData = [];
      _deviceUsageData = [];
      _deviceStats = {};
    });

    print('🔄 Data reset to 0, starting data load...');

    try {
      // Load data for selected month with forced refresh
      await Future.wait([
        _loadMonthlyEnergyConsumption(),
        _loadDailyUsageData(),
        _loadDeviceUsageData(),
        _loadDeviceStats(),
      ]).timeout(const Duration(seconds: 10));

      if (!mounted) return;

      print(
          '🔄 Data loaded - Monthly: $_monthlyEnergyConsumption kWh, Cost: $_monthlyCost VND');
      print('🔄 Daily usage data length: ${_dailyUsageData.length}');

      setState(() {
        _isRefreshing = false;
        _dataLoaded = true;
        _lastDataLoadTime = DateTime.now();
      });

      print('🔄 Final setState completed - UI should update now');
    } catch (e) {
      print('❌ Analytics Refresh Error: $e');
      if (!mounted) return;

      setState(() {
        _isRefreshing = false;
        _dataLoaded = true;
        _lastDataLoadTime = DateTime.now();
      });
    }
  }

  Future<void> _loadCurrentPowerConsumption() async {
    try {
      print('📊 Loading current power consumption...');
      _currentPowerConsumption =
          await _firebaseService.getCurrentPowerConsumption();
      print('📊 Current power loaded: ${_currentPowerConsumption}W');
    } catch (e) {
      print('❌ Error loading current power: $e');
      _currentPowerConsumption = 0.0;
    }
  }

  Future<void> _loadDailyEnergyConsumption() async {
    try {
      print('📊 Loading daily energy consumption...');
      _dailyEnergyConsumption =
          await _firebaseService.getDailyEnergyConsumption();
      print('📊 Daily energy loaded: ${_dailyEnergyConsumption} kWh');
    } catch (e) {
      print('❌ Error loading daily energy: $e');
      _dailyEnergyConsumption = 0.0;
    }
  }

  Future<void> _loadMonthlyEnergyConsumption() async {
    // Check cache first
    final cacheKey = 'monthly_${_selectedMonth.year}_${_selectedMonth.month}';
    final cachedData = _getCacheData<Map<String, double>>(cacheKey);

    if (cachedData != null) {
      print('📋 Using cached monthly data for ${_formatMonthYear(_selectedMonth)}');
      _monthlyEnergyConsumption = cachedData['consumption'] ?? 0.0;
      _monthlyCost = cachedData['cost'] ?? 0.0;
      print('📋 Cached monthly: ${_monthlyEnergyConsumption} kWh, Cost: ${_monthlyCost} VND');
      return;
    }

    try {
      // Use selected month for data query
      final startDate = DateTime(_selectedMonth.year, _selectedMonth.month, 1);
      final endDate =
          DateTime(_selectedMonth.year, _selectedMonth.month + 1, 0);

      print('📊 Loading monthly data for ${_formatMonthYear(_selectedMonth)}');
      print('📊 Date range: $startDate to $endDate');

      // Query data for selected month
      final monthlyData = await _firebaseService.getPowerConsumptionHistory(
        startTime: startDate,
        endTime: endDate,
      );

      print('📊 Found ${monthlyData.length} records for this month');

      // Calculate monthly consumption from daily data
      double totalConsumption = 0.0;
      for (final data in monthlyData) {
        final energyKwh = (data['energy_kwh'] as num?)?.toDouble() ?? 0.0;
        totalConsumption += energyKwh;
        print('📊 Daily energy: $energyKwh kWh');
      }

      print('📊 Total monthly consumption: $totalConsumption kWh');

      _monthlyEnergyConsumption = totalConsumption;
      _monthlyCost = _monthlyEnergyConsumption * 1500; // Calculate cost

      // Cache the result
      _setCacheData(cacheKey, {
        'consumption': _monthlyEnergyConsumption,
        'cost': _monthlyCost,
      });

      print('📊 Final monthly consumption: $_monthlyEnergyConsumption kWh');
      print('📊 Final monthly cost: $_monthlyCost VND');
      print('💾 Cached monthly data for ${_formatMonthYear(_selectedMonth)}');
    } catch (e) {
      print('❌ Error loading monthly energy: $e');
      _monthlyEnergyConsumption = 0.0;
      _monthlyCost = 0.0;
    }
  }

  Future<void> _loadDailyUsageData() async {
    // Check cache first
    final cacheKey = 'daily_${_selectedMonth.year}_${_selectedMonth.month}';
    final cachedData = _getCacheData<List<EnergyBarData>>(cacheKey);

    if (cachedData != null) {
      print(
          '📋 Using cached daily usage data for ${_formatMonthYear(_selectedMonth)}');
      _dailyUsageData = cachedData;
      return;
    }

    try {
      // Use selected month for daily usage data
      final endDate = DateTime(_selectedMonth.year, _selectedMonth.month + 1,
          0); // Last day of month
      final startDate = DateTime(
          _selectedMonth.year, _selectedMonth.month, 1); // First day of month

      print('📈 Loading daily usage for ${_formatMonthYear(_selectedMonth)}');
      print('📈 Date range: $startDate to $endDate');

      final powerHistory = await _firebaseService.getPowerConsumptionHistory(
        startTime: startDate,
        endTime: endDate,
      );

      print('📈 Found ${powerHistory.length} daily records');

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

      print('📈 Processed daily data for ${dailyPower.keys.length} days');

      _dailyUsageData = [];

      // Generate data for selected month - show last 7 days of the month or recent days
      final isCurrentMonth = _selectedMonth.year == DateTime.now().year &&
          _selectedMonth.month == DateTime.now().month;
      final referenceDate = isCurrentMonth
          ? DateTime.now()
          : DateTime(_selectedMonth.year, _selectedMonth.month + 1,
              0); // Last day of selected month

      for (int i = 6; i >= 0; i--) {
        final date = referenceDate.subtract(Duration(days: i));
        final dayKey = '${date.month}/${date.day}';

        // Display format
        String displayKey;
        if (isCurrentMonth && i == 0) {
          displayKey = 'Hôm nay';
        } else if (isCurrentMonth && i == 1) {
          displayKey = 'Hôm qua';
        } else {
          displayKey = '${date.day}/${date.month}';
        }

        // Only show real data, no fallback
        final avgPower = dailyPower[dayKey]?.isNotEmpty == true
            ? dailyPower[dayKey]!.reduce((a, b) => a + b) /
                dailyPower[dayKey]!.length
            : 0.0; // Show 0 if no data

        final avgSaved = dailySaved[dayKey]?.isNotEmpty == true
            ? dailySaved[dayKey]!.reduce((a, b) => a + b) /
                dailySaved[dayKey]!.length
            : 0.0; // Show 0 if no data

        print(
            '📈 Day $displayKey ($dayKey): Power=${avgPower.toStringAsFixed(2)}, Saved=${avgSaved.toStringAsFixed(2)}');

        _dailyUsageData.add(EnergyBarData(displayKey, avgPower, avgSaved));
      }

      // Cache the successful result
      _setCacheData(cacheKey, _dailyUsageData);
      print(
          '💾 Cached daily usage data for ${_formatMonthYear(_selectedMonth)}');
    } catch (e) {
      print('❌ Error loading daily usage data: $e');
      // Set empty data instead of demo data
      _dailyUsageData = [];
      for (int i = 6; i >= 0; i--) {
        final date = DateTime.now().subtract(Duration(days: i));
        String displayKey;
        if (i == 0) {
          displayKey = 'Hôm nay';
        } else if (i == 1) {
          displayKey = 'Hôm qua';
        } else {
          displayKey = '${date.day}/${date.month}';
        }
        _dailyUsageData.add(EnergyBarData(displayKey, 0.0, 0.0));
      }
    }
  }

  Future<void> _loadDeviceUsageData() async {
    try {
      print('📊 Loading device usage data...');
      _deviceStats = await _firebaseService.getDeviceStats('');
      print('📊 Device stats loaded: ${_deviceStats.keys.length} devices');

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

        print('📊 Device $deviceName: ${usagePercent}%');

        _deviceUsageData.add(DeviceUsageData(
          deviceName,
          usagePercent,
          colors[colorIndex % colors.length],
        ));
        colorIndex++;
      }

      print('📊 Device usage data processed: ${_deviceUsageData.length} devices');

      // If no real data, leave empty instead of demo data
      if (_deviceUsageData.isEmpty) {
        print('📊 No device usage data available');
        _deviceUsageData = [];
      }
    } catch (e) {
      print('❌ Error loading device usage data: $e');
      // Leave empty instead of demo data
      _deviceUsageData = [];
    }
  }

  Future<void> _loadDeviceStats() async {
    try {
      print('📊 Loading device stats...');
      _deviceStats = await _firebaseService.getDeviceStats('', timeRange: '7d');
      print('📊 Device stats loaded: ${_deviceStats.keys.length} devices');
    } catch (e) {
      print('❌ Error loading device stats: $e');
      _deviceStats = {};
    }
  }

  // 🤖 AI Analytics Methods
  Future<void> _loadAIInsights() async {
    if (!_aiEnergyModeEnabled) return;
    
    setState(() => _isLoadingAIInsights = true);
    
    try {
      print('🤖 Loading AI insights...');
      
      // Prepare device usage data for AI
      final deviceUsageForAI = _deviceUsageData.map((device) => {
        'device': device.device,
        'value': device.value,
      }).toList();
      
      // Prepare daily usage data for AI
      final dailyUsageForAI = _dailyUsageData.map((data) => {
        'day': data.day,
        'usage': data.usage,
      }).toList();
      
      // Generate AI insights
      final insights = await AIAnalyticsService.generateEnergyInsights(
        currentPower: _currentPowerConsumption,
        dailyConsumption: _dailyEnergyConsumption,
        monthlyConsumption: _monthlyEnergyConsumption,
        monthlyCost: _monthlyCost,
        deviceUsage: deviceUsageForAI,
        dailyUsage: dailyUsageForAI,
      );
      
      // Analyze trends
      final trends = await AIAnalyticsService.analyzeTrends(
        dailyUsage: dailyUsageForAI,
        currentMonthConsumption: _monthlyEnergyConsumption,
      );
      
      if (mounted) {
        setState(() {
          _aiInsights = insights;
          _aiTrends = trends;
          _isLoadingAIInsights = false;
        });
      }
      
      print('🤖 AI insights loaded successfully');
    } catch (e) {
      print('❌ Error loading AI insights: $e');
      if (mounted) {
        setState(() => _isLoadingAIInsights = false);
      }
    }
  }

  void _refreshAIInsights() async {
    if (!_aiEnergyModeEnabled) return;
    
    await _loadAIInsights();
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Đã làm mới AI insights'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _showAIReportDialog() {
    // Option 1: Show dialog (existing functionality)
    showDialog(
      context: context,
      builder: (context) => AIReportDialog(
        insights: _aiInsights,
        deviceStats: _deviceStats,
        monthlyConsumption: _monthlyEnergyConsumption,
        monthlyCost: _monthlyCost,
      ),
    );
  }

  void _navigateToAIDetailScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AIAnalyticsDetailScreen(),
      ),
    );
  }

  void _toggleAIMode(bool enabled) {
    setState(() {
      _aiEnergyModeEnabled = enabled;
    });
    
    if (enabled) {
      _loadAIInsights();
    } else {
      setState(() {
        _aiInsights = {};
        _aiTrends = {};
        _isLoadingAIInsights = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
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
      onRefresh: () async {
        // Force reload by clearing cache
        print('🔄 Pull-to-refresh triggered');
        _clearCache();
        _dataLoaded = false;
        _lastDataLoadTime = null;
        await _loadAnalyticsData();
        
        // Show success message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Dữ liệu đã được làm mới'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 1),
            ),
          );
        }
      },
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
              _buildMonthSelector(),
              SizedBox(height: getProportionateScreenHeight(16)),
              
              // ========================
              // PHẦN 1: THỐNG KÊ NĂNG LƯỢNG - EXPANDABLE
              // ========================
              _buildExpandableSection(
                title: "Thống kê năng lượng",
                icon: Icons.analytics,
                color: Colors.blue,
                initiallyExpanded: true,
                children: [
                  _buildMonthlyCostCard(),
                  SizedBox(height: getProportionateScreenHeight(6)),
                  _buildDailyUsageCard(),
                  SizedBox(height: getProportionateScreenHeight(6)),
                  _buildDeviceUsageCard(),
                ],
              ),
              
              SizedBox(height: getProportionateScreenHeight(8)),
              
              // ========================
              // PHẦN 2: AI PHÂN TÍCH & TỐI ƯU - EXPANDABLE
              // ========================
              _buildExpandableSection(
                title: "AI Phân tích & Tối ưu",
                icon: Icons.psychology,
                color: Colors.teal,
                initiallyExpanded: false,
                children: [
                  _buildAIEnergyModeCard(),
                  
                  // AI Insights Card - hiển thị khi AI mode được bật
                  if (_aiEnergyModeEnabled && _aiInsights.isNotEmpty) ...[
                    SizedBox(height: getProportionateScreenHeight(6)),
                    _buildCompactAIInsights(),
                  ],
                  
                  // Energy Optimization Card - hiển thị gợi ý tối ưu từ AI
                  if (_aiEnergyModeEnabled && _aiInsights.containsKey('device_optimization')) ...[
                    SizedBox(height: getProportionateScreenHeight(6)),
                    _buildCompactOptimizationCard(),
                  ],
                ],
              ),
              
              SizedBox(height: getProportionateScreenHeight(20)), // Extra padding at bottom
            ],
          ),
        ),
      ),
    );
  }

  // Modern Time Range Selector Widget - Compact Layout
  Widget _buildMonthSelector() {
    return Container(
      padding: EdgeInsets.all(getProportionateScreenWidth(8)),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).primaryColor.withOpacity(0.06),
            Theme.of(context).primaryColor.withOpacity(0.02),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).primaryColor.withOpacity(0.12),
          width: 0.8,
        ),
      ),
      child: Row(
        children: [
          // Month Selector Section - Compact
          Expanded(
            flex: 5,
            child: GestureDetector(
              onTap: _showMonthPicker,
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: getProportionateScreenWidth(8),
                  vertical: getProportionateScreenHeight(6),
                ),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Theme.of(context).primaryColor.withOpacity(0.15),
                    width: 0.5,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      color: Theme.of(context).primaryColor,
                      size: 14,
                    ),
                    SizedBox(width: getProportionateScreenWidth(4)),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Tháng',
                            style: TextStyle(
                              color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.6),
                              fontSize: getProportionateScreenWidth(7),
                              fontWeight: FontWeight.w500,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            _formatMonthYearShort(_selectedMonth),
                            style: TextStyle(
                              color: Theme.of(context).textTheme.titleMedium?.color,
                              fontSize: getProportionateScreenWidth(9),
                              fontWeight: FontWeight.w600,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          SizedBox(width: getProportionateScreenWidth(6)),
          
          // Time Range Selector Section - Compact
          Expanded(
            flex: 5,
            child: GestureDetector(
              onTap: _showTimeRangePicker,
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: getProportionateScreenWidth(8),
                  vertical: getProportionateScreenHeight(6),
                ),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.teal.withOpacity(0.15),
                    width: 0.5,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.timelapse,
                      color: Colors.teal,
                      size: 14,
                    ),
                    SizedBox(width: getProportionateScreenWidth(4)),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Khoảng',
                            style: TextStyle(
                              color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.6),
                              fontSize: getProportionateScreenWidth(7),
                              fontWeight: FontWeight.w500,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            _selectedTimeRange.label,
                            style: TextStyle(
                              color: Theme.of(context).textTheme.titleMedium?.color,
                              fontSize: getProportionateScreenWidth(9),
                              fontWeight: FontWeight.w600,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          SizedBox(width: getProportionateScreenWidth(6)),
          
          // Refresh Button - More compact
          GestureDetector(
            onTap: _isRefreshing ? null : () async {
              print('🔄 Manual refresh triggered');
              _clearCache();
              _dataLoaded = false;
              _lastDataLoadTime = null;
              setState(() => _isRefreshing = true);
              
              try {
                await _loadAnalyticsData();
                
                if (mounted) {
                  setState(() => _isRefreshing = false);
                  
                  // Show success message
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Dữ liệu đã được cập nhật'),
                      backgroundColor: Colors.green,
                      duration: Duration(seconds: 2),
                    ),
                  );
                }
              } catch (e) {
                print('❌ Refresh error: $e');
                if (mounted) {
                  setState(() => _isRefreshing = false);
                  
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Lỗi khi cập nhật dữ liệu'),
                      backgroundColor: Colors.red,
                      duration: Duration(seconds: 2),
                    ),
                  );
                }
              }
            },
            child: Container(
              padding: EdgeInsets.all(getProportionateScreenWidth(8)),
              decoration: BoxDecoration(
                gradient: _isRefreshing 
                    ? null 
                    : LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.blue.withOpacity(0.8),
                          Colors.blue.withOpacity(0.6),
                        ],
                      ),
                color: _isRefreshing ? Theme.of(context).disabledColor : null,
                borderRadius: BorderRadius.circular(8),
                boxShadow: !_isRefreshing ? [
                  BoxShadow(
                    color: Colors.blue.withOpacity(0.15),
                    blurRadius: 3,
                    offset: const Offset(0, 1),
                  ),
                ] : null,
              ),
              child: _isRefreshing
                  ? SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Icon(
                      Icons.refresh_rounded,
                      color: Colors.white,
                      size: 14,
                    ),
            ),
          ),
        ],
      ),
    );
  }

  // Show time range picker dialog  
  Future<void> _showTimeRangePicker() async {
    final AnalyticsTimeRange? selected = await showDialog<AnalyticsTimeRange>(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Container(
            padding: EdgeInsets.all(16),
            constraints: BoxConstraints(
              maxWidth: 320,
              maxHeight: MediaQuery.of(context).size.height * 0.7,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      color: Colors.teal,
                      size: 20,
                    ),
                    SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        'Khoảng thống kê',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).textTheme.titleLarge?.color,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12),
                Flexible(
                  child: SingleChildScrollView(
                    child: Column(
                      children: AnalyticsTimeRange.values.map((range) {
                        final isSelected = range == _selectedTimeRange;
                        return Container(
                          margin: EdgeInsets.only(bottom: 6),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(8),
                            onTap: () => Navigator.of(context).pop(range),
                            child: Container(
                              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: isSelected 
                                    ? Colors.teal.withOpacity(0.1)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: isSelected 
                                      ? Colors.teal.withOpacity(0.3)
                                      : Colors.transparent,
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    isSelected ? Icons.check_circle : Icons.circle_outlined,
                                    color: isSelected ? Colors.teal : Colors.grey,
                                    size: 16,
                                  ),
                                  SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      range.label,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                                        color: isSelected 
                                            ? Colors.teal 
                                            : Theme.of(context).textTheme.bodyMedium?.color,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
                SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(
                        'Hủy',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );

    if (selected != null && selected != _selectedTimeRange) {
      setState(() {
        _selectedTimeRange = selected;
      });
      
      // Reload data with new time range
      await _refreshDataForTimeRange();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đã chuyển sang khoảng ${selected.label}'),
            backgroundColor: Colors.teal,
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  // Show month picker dialog with month-only selection
  Future<void> _showMonthPicker() async {
    final DateTime? picked = await showMonthYearPicker(
      context: context,
      initialDate: _selectedMonth,
      firstDate: DateTime(2024, 1),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      final selectedMonth = DateTime(picked.year, picked.month, 1);
      if (selectedMonth != DateTime(_selectedMonth.year, _selectedMonth.month, 1)) {
        await _refreshDataForMonth(selectedMonth);
      }
    }
  }

  // Custom Month Year Picker
  Future<DateTime?> showMonthYearPicker({
    required BuildContext context,
    required DateTime initialDate,
    required DateTime firstDate,
    required DateTime lastDate,
  }) async {
    return await showDialog<DateTime>(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.calendar_month_outlined,
                      color: Theme.of(context).primaryColor,
                      size: 24,
                    ),
                    SizedBox(width: 12),
                    Text(
                      'Chọn tháng',
                      style: TextStyle(
                        fontSize: getProportionateScreenWidth(16),
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).textTheme.titleLarge?.color,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 20),
                Container(
                  height: 300,
                  child: MonthYearPickerGrid(
                    initialDate: initialDate,
                    firstDate: firstDate,
                    lastDate: lastDate,
                    onSelected: (DateTime selected) {
                      Navigator.of(context).pop(selected);
                    },
                  ),
                ),
                SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(
                        'Hủy',
                        style: TextStyle(
                          color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // New method to refresh data for time range
  Future<void> _refreshDataForTimeRange() async {
    print('🔄 Refreshing data for time range: ${_selectedTimeRange.label}');
    
    setState(() {
      _isRefreshing = true;
      _clearCache();
      _dataLoaded = false;
      _lastDataLoadTime = null;
    });

    try {
      await _loadAnalyticsData();
      
      if (mounted) {
        setState(() => _isRefreshing = false);
      }
    } catch (e) {
      print('❌ Error refreshing for time range: $e');
      if (mounted) {
        setState(() => _isRefreshing = false);
      }
    }
  }

  // Show month picker dialog - LEGACY VERSION FOR REFERENCE
  Future<void> _showMonthPickerLegacy() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedMonth,
      firstDate: DateTime(2024, 1, 1),
      lastDate: DateTime.now(),
      selectableDayPredicate: (DateTime day) {
        // Cho phép chọn bất kỳ ngày nào
        return true;
      },
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.fromSeed(
              seedColor: Theme.of(context).primaryColor,
              brightness: Theme.of(context).brightness,
            ),
          ),
          child: child!,
        );
      },
      helpText: 'Chọn tháng để xem thống kê',
      cancelText: 'Hủy',
      confirmText: 'Chọn',
    );

    if (picked != null) {
      // Lấy tháng từ ngày được chọn
      final selectedMonth = DateTime(picked.year, picked.month, 1);
      if (selectedMonth != DateTime(_selectedMonth.year, _selectedMonth.month, 1)) {
        await _refreshDataForMonth(selectedMonth);
      }
    }
  }

  // Format month year for display
  String _formatMonthYear(DateTime date) {
    final months = [
      'Tháng 1',
      'Tháng 2',
      'Tháng 3',
      'Tháng 4',
      'Tháng 5',
      'Tháng 6',
      'Tháng 7',
      'Tháng 8',
      'Tháng 9',
      'Tháng 10',
      'Tháng 11',
      'Tháng 12'
    ];
    return '${months[date.month - 1]} ${date.year}';
  }

  // Format month year for compact display
  String _formatMonthYearShort(DateTime date) {
    final months = [
      'T1', 'T2', 'T3', 'T4', 'T5', 'T6',
      'T7', 'T8', 'T9', 'T10', 'T11', 'T12'
    ];
    return '${months[date.month - 1]}/${date.year}';
  }

  // AI Energy Mode Card
  Widget _buildSection({
    required String title,
    required IconData icon,
    required Color color,
    required List<Widget> children,
  }) {
    return Container(
      padding: EdgeInsets.all(getProportionateScreenHeight(6)),
      decoration: BoxDecoration(
        color: color.withOpacity(0.03),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.12), width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 12),
              SizedBox(width: 3),
              Text(
                title,
                style: TextStyle(
                  fontSize: getProportionateScreenWidth(10),
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
          SizedBox(height: getProportionateScreenHeight(4)),
          ...children,
        ],
      ),
    );
  }

  Widget _buildAIEnergyModeCard() {
    return Container(
      padding: EdgeInsets.all(getProportionateScreenHeight(8)),
      decoration: BoxDecoration(
        gradient: _aiEnergyModeEnabled
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.teal.withOpacity(0.08),
                  Colors.blue.withOpacity(0.08),
                ],
              )
            : null,
        color: _aiEnergyModeEnabled ? null : Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(8),
        border: _aiEnergyModeEnabled
            ? Border.all(color: Colors.teal.withOpacity(0.25), width: 0.8)
            : null,
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.black.withOpacity(0.2)
                : Colors.black.withOpacity(0.06),
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        children: [
          // Main AI Mode Row
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.teal.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(
                  Icons.psychology,
                  color: Colors.teal,
                  size: 14,
                ),
              ),
              SizedBox(width: getProportionateScreenWidth(6)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'AI Analytics & Tối ưu',
                      style: TextStyle(
                        color: Theme.of(context).textTheme.titleLarge?.color,
                        fontSize: getProportionateScreenWidth(11),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: getProportionateScreenHeight(1)),
                    Text(
                      _aiEnergyModeEnabled
                          ? _isLoadingAIInsights
                              ? 'Đang phân tích...'
                              : _aiInsights.isNotEmpty
                                  ? 'AI đang theo dõi'
                                  : 'Chờ dữ liệu'
                          : 'Bật để sử dụng AI',
                      style: TextStyle(
                        color: _aiEnergyModeEnabled
                            ? Colors.blue[300]
                            : Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.color
                                ?.withOpacity(0.7),
                        fontSize: getProportionateScreenWidth(8),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Transform.scale(
                scale: 0.8,
                child: Switch(
                  value: _aiEnergyModeEnabled,
                  onChanged: _toggleAIMode,
                  activeColor: Colors.teal,
                  inactiveThumbColor: Colors.grey[400],
                  inactiveTrackColor: Theme.of(context).brightness == Brightness.dark
                      ? Colors.grey[700]
                      : Colors.grey[300],
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ],
          ),

          // AI Status Information when enabled
          if (_aiEnergyModeEnabled) ...[
            SizedBox(height: getProportionateScreenHeight(6)),
            Container(
              padding: EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.grey[800]?.withOpacity(0.4)
                    : Colors.white.withOpacity(0.6),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Column(
                children: [
                  // Current Power and Energy Info
                  Row(
                    children: [
                      Expanded(
                        child: _buildAIInfoItem(
                          Icons.flash_on,
                          'Công suất',
                          _currentPowerConsumption > 0
                              ? '${_currentPowerConsumption.toStringAsFixed(1)}W'
                              : '--',
                          Colors.orange,
                        ),
                      ),
                      Container(
                        height: 16,
                        width: 0.5,
                        color: Theme.of(context).dividerColor,
                      ),
                      Expanded(
                        child: _buildAIInfoItem(
                          Icons.battery_charging_full,
                          'Hôm nay',
                          _dailyEnergyConsumption > 0
                              ? '${_dailyEnergyConsumption.toStringAsFixed(1)} kWh'
                              : '--',
                          Colors.green,
                        ),
                      ),
                    ],
                  ),
                  
                  SizedBox(height: 6),
                  
                  // AI Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _isLoadingAIInsights ? null : _refreshAIInsights,
                          icon: _isLoadingAIInsights
                              ? SizedBox(
                                  width: 10,
                                  height: 10,
                                  child: CircularProgressIndicator(strokeWidth: 1.5),
                                )
                              : Icon(Icons.refresh, size: 12),
                          label: Text(
                            'Làm mới',
                            style: TextStyle(fontSize: getProportionateScreenWidth(8)),
                          ),
                          style: OutlinedButton.styleFrom(
                            padding: EdgeInsets.symmetric(vertical: 4),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 4),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _aiInsights.isNotEmpty ? _showAIReportDialog : null,
                          icon: Icon(Icons.analytics, size: 12),
                          label: Text(
                            'Chi tiết',
                            style: TextStyle(fontSize: getProportionateScreenWidth(8)),
                          ),
                          style: ElevatedButton.styleFrom(
                            padding: EdgeInsets.symmetric(vertical: 4),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAIInfoItem(IconData icon, String label, String value, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 12),
        SizedBox(height: 1),
        Text(
          label,
          style: TextStyle(
            fontSize: getProportionateScreenWidth(7),
            color: Theme.of(context)
                .textTheme
                .bodySmall
                ?.color
                ?.withOpacity(0.7),
          ),
        ),
        SizedBox(height: 1),
        Text(
          value,
          style: TextStyle(
            fontSize: getProportionateScreenWidth(9),
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }

  // Monthly Cost Card - Compact version with real data
  Widget _buildMonthlyCostCard() {
    final totalUsage = _deviceUsageData.fold(0.0, (sum, device) => sum + device.value);
    final totalSavings = totalUsage * 0.25; // 25% savings from AI optimization
    
    return Container(
      padding: EdgeInsets.all(getProportionateScreenWidth(10)),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.black.withValues(alpha: 0.2)
                : Colors.black.withValues(alpha: 0.08),
            blurRadius: 4,
            offset: const Offset(0, 1),
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
                'Chi phí ${_formatMonthYear(_selectedMonth)}',
                style: TextStyle(
                  color: Theme.of(context).textTheme.titleLarge?.color,
                  fontSize: getProportionateScreenWidth(11),
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (_isRefreshing)
                SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(
                    strokeWidth: 1.5,
                    valueColor: AlwaysStoppedAnimation<Color>(
                        Theme.of(context).primaryColor),
                  ),
                ),
            ],
          ),
          SizedBox(height: getProportionateScreenHeight(8)),
          
          // Main cost display
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${(_monthlyCost > 0 ? _monthlyCost.toStringAsFixed(0) : '0')}',
                style: TextStyle(
                  color: Theme.of(context).textTheme.titleLarge?.color,
                  fontSize: getProportionateScreenWidth(16),
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(width: getProportionateScreenWidth(2)),
              Text(
                'đ',
                style: TextStyle(
                  color: Theme.of(context).textTheme.titleLarge?.color,
                  fontSize: getProportionateScreenWidth(11),
                  fontWeight: FontWeight.w500,
                ),
              ),
              Spacer(),
              Text(
                '${_monthlyEnergyConsumption.toStringAsFixed(1)} kWh',
                style: TextStyle(
                  color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
                  fontSize: getProportionateScreenWidth(9),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          
          SizedBox(height: getProportionateScreenHeight(6)),
          
          // Savings info
          if (totalSavings > 0) ...[
            Row(
              children: [
                Icon(Icons.savings, color: Colors.green, size: 12),
                SizedBox(width: getProportionateScreenWidth(3)),
                Text(
                  'Tiết kiệm ${(totalSavings * 1500).toStringAsFixed(0)}đ với AI',
                  style: TextStyle(
                    color: Colors.green,
                    fontSize: getProportionateScreenWidth(8),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ] else ...[
            Text(
              'Chưa có dữ liệu tiết kiệm',
              style: TextStyle(
                color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.5),
                fontSize: getProportionateScreenWidth(8),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // Daily Usage Card with Bar Chart - Compact version
  Widget _buildDailyUsageCard() {
    final hasData = _dailyUsageData.isNotEmpty && _dailyUsageData.any((data) => data.usage > 0);
    final totalUsage = _dailyUsageData.fold(0.0, (sum, data) => sum + data.usage);
    final totalSaved = _dailyUsageData.fold(0.0, (sum, data) => sum + data.saved);
    
    return Container(
      padding: EdgeInsets.all(getProportionateScreenWidth(10)),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.black.withValues(alpha: 0.2)
                : Colors.black.withValues(alpha: 0.08),
            blurRadius: 4,
            offset: const Offset(0, 1),
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
                  'Sử dụng năng lượng hàng ngày',
                  style: TextStyle(
                    color: Theme.of(context).textTheme.titleLarge?.color,
                    fontSize: getProportionateScreenWidth(10),
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (hasData)
                Text(
                  '${totalUsage.toStringAsFixed(1)} kWh',
                  style: TextStyle(
                    color: Colors.blue,
                    fontSize: getProportionateScreenWidth(9),
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),
          SizedBox(height: getProportionateScreenHeight(8)),
          
          if (hasData) ...[
            // Chart section
            Container(
              height: getProportionateScreenHeight(80),
              child: SfCartesianChart(
                backgroundColor: Colors.transparent,
                plotAreaBorderWidth: 0,
                margin: EdgeInsets.zero,
                primaryXAxis: CategoryAxis(
                  axisLine: AxisLine(width: 0),
                  majorTickLines: MajorTickLines(size: 0),
                  labelStyle: TextStyle(
                    color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
                    fontSize: getProportionateScreenWidth(7),
                  ),
                  majorGridLines: MajorGridLines(width: 0),
                ),
                primaryYAxis: NumericAxis(
                  isVisible: false,
                  minimum: 0,
                  maximum: _dailyUsageData.isNotEmpty 
                      ? _dailyUsageData.map((d) => d.usage).reduce((a, b) => a > b ? a : b) * 1.2
                      : 10,
                ),
                series: <CartesianSeries>[
                  ColumnSeries<EnergyBarData, String>(
                    dataSource: _dailyUsageData,
                    xValueMapper: (EnergyBarData data, _) => data.day,
                    yValueMapper: (EnergyBarData data, _) => data.usage,
                    color: Colors.blue.withValues(alpha: 0.8),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(2),
                      topRight: Radius.circular(2),
                    ),
                    width: 0.6,
                  ),
                  ColumnSeries<EnergyBarData, String>(
                    dataSource: _dailyUsageData,
                    xValueMapper: (EnergyBarData data, _) => data.day,
                    yValueMapper: (EnergyBarData data, _) => data.saved,
                    color: Colors.teal.withValues(alpha: 0.8),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(2),
                      topRight: Radius.circular(2),
                    ),
                    width: 0.6,
                  ),
                ],
              ),
            ),
            
            SizedBox(height: getProportionateScreenHeight(6)),
            
            // Legend
            Row(
              children: [
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: Colors.blue,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    SizedBox(width: 4),
                    Text(
                      'Tiêu thụ',
                      style: TextStyle(
                        color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
                        fontSize: getProportionateScreenWidth(7),
                      ),
                    ),
                  ],
                ),
                SizedBox(width: 12),
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: Colors.teal,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    SizedBox(width: 4),
                    Text(
                      'Tiết kiệm',
                      style: TextStyle(
                        color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
                        fontSize: getProportionateScreenWidth(7),
                      ),
                    ),
                  ],
                ),
                Spacer(),
                if (totalSaved > 0)
                  Text(
                    'Tiết kiệm ${totalSaved.toStringAsFixed(1)} kWh',
                    style: TextStyle(
                      color: Colors.teal,
                      fontSize: getProportionateScreenWidth(8),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
              ],
            ),
          ] else ...[
            Container(
              height: getProportionateScreenHeight(60),
              child: Center(
                child: Text(
                  'Chưa có dữ liệu tiêu thụ năng lượng',
                  style: TextStyle(
                    color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.5),
                    fontSize: getProportionateScreenWidth(8),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // Device Usage Card - Compact version with real data
  Widget _buildDeviceUsageCard() {
    final totalUsage = _deviceUsageData.fold(0.0, (sum, device) => sum + device.value);
    final totalSavings = totalUsage * 0.25;
    final savingsPercent = totalUsage > 0 ? (totalSavings / totalUsage * 100) : 0.0;
    
    return Container(
      padding: EdgeInsets.all(getProportionateScreenWidth(10)),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.black.withValues(alpha: 0.2)
                : Colors.black.withValues(alpha: 0.08),
            blurRadius: 4,
            offset: const Offset(0, 1),
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
                  'Thiết bị tiêu thụ năng lượng',
                  style: TextStyle(
                    color: Theme.of(context).textTheme.titleLarge?.color,
                    fontSize: getProportionateScreenWidth(11),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: getProportionateScreenHeight(8)),
          
          if (_deviceUsageData.isNotEmpty) ...[
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Total usage
                      Row(
                        children: [
                          Icon(Icons.electric_bolt, color: Colors.blue, size: 12),
                          SizedBox(width: 3),
                          Text(
                            'Tổng mức sử dụng',
                            style: TextStyle(
                              color: Colors.blue,
                              fontSize: getProportionateScreenWidth(8),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 2),
                      Text(
                        '${totalUsage.toStringAsFixed(1)} kWh',
                        style: TextStyle(
                          color: Theme.of(context).textTheme.titleLarge?.color,
                          fontSize: getProportionateScreenWidth(12),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: getProportionateScreenHeight(6)),
                      
                      // Savings
                      Row(
                        children: [
                          Icon(Icons.savings, color: Colors.green, size: 12),
                          SizedBox(width: 3),
                          Text(
                            'Tiết kiệm',
                            style: TextStyle(
                              color: Colors.green,
                              fontSize: getProportionateScreenWidth(8),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 2),
                      Text(
                        '${totalSavings.toStringAsFixed(1)} kWh (${savingsPercent.toStringAsFixed(1)}%)',
                        style: TextStyle(
                          color: Colors.green,
                          fontSize: getProportionateScreenWidth(10),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Donut chart
                Container(
                  width: getProportionateScreenWidth(70),
                  height: getProportionateScreenWidth(70),
                  child: SfCircularChart(
                    backgroundColor: Colors.transparent,
                    margin: EdgeInsets.zero,
                    series: <CircularSeries>[
                      DoughnutSeries<DeviceUsageData, String>(
                        dataSource: _deviceUsageData.take(5).toList(), // Top 5 devices
                        xValueMapper: (DeviceUsageData data, _) => data.device,
                        yValueMapper: (DeviceUsageData data, _) => data.value,
                        pointColorMapper: (DeviceUsageData data, _) => data.color,
                        innerRadius: '50%',
                        radius: '90%',
                        strokeWidth: 1,
                        strokeColor: Theme.of(context).cardColor,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            SizedBox(height: getProportionateScreenHeight(8)),
            
            // Device list
            ..._buildDeviceUsageItems(),
          ] else ...[
            Container(
              height: getProportionateScreenHeight(60),
              child: Center(
                child: Text(
                  'Chưa có dữ liệu thiết bị',
                  style: TextStyle(
                    color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.5),
                    fontSize: getProportionateScreenWidth(8),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  List<Widget> _buildDeviceUsageItems() {
    if (_deviceUsageData.isEmpty) return [];

    final items = <Widget>[];
    final topDevices = _deviceUsageData.take(3).toList(); // Show top 3 devices
    
    for (int i = 0; i < topDevices.length; i++) {
      final device = topDevices[i];
      final usage = device.value.toStringAsFixed(1);
      final percent = _deviceUsageData.fold(0.0, (sum, d) => sum + d.value) > 0
          ? (device.value / _deviceUsageData.fold(0.0, (sum, d) => sum + d.value) * 100)
          : 0.0;

      if (i > 0) items.add(SizedBox(height: getProportionateScreenHeight(4)));
      items.add(_buildDeviceUsageItem(
        device.device,
        usage,
        percent,
        device.color,
      ));
    }
    
    if (_deviceUsageData.length > 3) {
      items.add(SizedBox(height: getProportionateScreenHeight(4)));
      items.add(
        Text(
          '...và ${_deviceUsageData.length - 3} thiết bị khác',
          style: TextStyle(
            color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.5),
            fontSize: getProportionateScreenWidth(7),
            fontStyle: FontStyle.italic,
          ),
        ),
      );
    }
    
    return items;
  }

  Widget _buildDeviceUsageItem(String deviceName, String usage, double percent, Color color) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        SizedBox(width: getProportionateScreenWidth(6)),
        Expanded(
          child: Text(
            deviceName,
            style: TextStyle(
              color: Theme.of(context).textTheme.bodyMedium?.color,
              fontSize: getProportionateScreenWidth(8),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Text(
          '${usage} kWh',
          style: TextStyle(
            color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
            fontSize: getProportionateScreenWidth(7),
          ),
        ),
        SizedBox(width: 4),
        Text(
          '${percent.toStringAsFixed(1)}%',
          style: TextStyle(
            color: color,
            fontSize: getProportionateScreenWidth(7),
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
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

  // ========================
  // EXPANDABLE SECTION WIDGET
  // ========================
  Widget _buildExpandableSection({
    required String title,
    required IconData icon,
    required Color color,
    required List<Widget> children,
    bool initiallyExpanded = true,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: getProportionateScreenHeight(4)),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.black.withOpacity(0.15)
                : Colors.black.withOpacity(0.05),
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: initiallyExpanded,
          tilePadding: EdgeInsets.symmetric(
            horizontal: getProportionateScreenWidth(12),
            vertical: getProportionateScreenHeight(2),
          ),
          childrenPadding: EdgeInsets.fromLTRB(
            getProportionateScreenWidth(12),
            0,
            getProportionateScreenWidth(12),
            getProportionateScreenHeight(8),
          ),
          title: Row(
            children: [
              Icon(icon, color: color, size: 16),
              SizedBox(width: getProportionateScreenWidth(6)),
              Text(
                title,
                style: TextStyle(
                  fontSize: getProportionateScreenWidth(12),
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
          iconColor: color,
          collapsedIconColor: color,
          children: children,
        ),
      ),
    );
  }

  // ========================
  // COMPACT AI INSIGHTS CARD
  // ========================
  Widget _buildCompactAIInsights() {
    return Container(
      padding: EdgeInsets.all(getProportionateScreenHeight(8)),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.blue.withOpacity(0.05),
            Colors.purple.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.withOpacity(0.15), width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lightbulb, color: Colors.amber, size: 14),
              SizedBox(width: 4),
              Text(
                'AI Insights',
                style: TextStyle(
                  fontSize: getProportionateScreenWidth(10),
                  fontWeight: FontWeight.w600,
                  color: Colors.blue[700],
                ),
              ),
              Spacer(),
              TextButton(
                onPressed: _showAIReportDialog,
                style: TextButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  'Xem chi tiết',
                  style: TextStyle(
                    fontSize: getProportionateScreenWidth(8),
                    color: Colors.blue[600],
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: getProportionateScreenHeight(4)),
          if (_aiInsights.containsKey('summary'))
            Text(
              _aiInsights['summary']?.toString().split('.').first ?? '',
              style: TextStyle(
                fontSize: getProportionateScreenWidth(9),
                color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.8),
                height: 1.2,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
        ],
      ),
    );
  }

  // ========================
  // COMPACT OPTIMIZATION CARD
  // ========================
  Widget _buildCompactOptimizationCard() {
    final optimizations = _aiInsights['device_optimization'] as List<dynamic>? ?? [];
    if (optimizations.isEmpty) return SizedBox.shrink();
    
    return Container(
      padding: EdgeInsets.all(getProportionateScreenWidth(8)),
      decoration: BoxDecoration(
        color: Colors.green.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green.withValues(alpha: 0.2), width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.eco, color: Colors.green, size: 12),
              SizedBox(width: 4),
              Text(
                'Tối ưu năng lượng',
                style: TextStyle(
                  fontSize: getProportionateScreenWidth(9),
                  fontWeight: FontWeight.w600,
                  color: Colors.green[700],
                ),
              ),
              Spacer(),
              Text(
                '${optimizations.length} gợi ý',
                style: TextStyle(
                  fontSize: getProportionateScreenWidth(7),
                  color: Colors.green[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          SizedBox(height: getProportionateScreenHeight(4)),
          ...optimizations.take(2).map<Widget>((opt) => Padding(
            padding: EdgeInsets.only(bottom: 2),
            child: Row(
              children: [
                Icon(Icons.chevron_right, size: 10, color: Colors.green[600]),
                SizedBox(width: 2),
                Expanded(
                  child: Text(
                    opt['suggestion']?.toString() ?? '',
                    style: TextStyle(
                      fontSize: getProportionateScreenWidth(7),
                      color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.8),
                      height: 1.2,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          )).toList(),
          if (optimizations.length > 2)
            Padding(
              padding: EdgeInsets.only(top: 2),
              child: Text(
                '... và ${optimizations.length - 2} gợi ý khác',
                style: TextStyle(
                  fontSize: getProportionateScreenWidth(7),
                  color: Colors.green[600],
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
        ],
      ),
    );
  }

}

// Custom Month Year Picker Grid Widget
class MonthYearPickerGrid extends StatefulWidget {
  final DateTime initialDate;
  final DateTime firstDate;
  final DateTime lastDate;
  final Function(DateTime) onSelected;

  const MonthYearPickerGrid({
    Key? key,
    required this.initialDate,
    required this.firstDate,
    required this.lastDate,
    required this.onSelected,
  }) : super(key: key);

  @override
  State<MonthYearPickerGrid> createState() => _MonthYearPickerGridState();
}

class _MonthYearPickerGridState extends State<MonthYearPickerGrid> {
  late int selectedYear;
  late int selectedMonth;

  @override
  void initState() {
    super.initState();
    selectedYear = widget.initialDate.year;
    selectedMonth = widget.initialDate.month;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Year selector
        Container(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                onPressed: selectedYear > widget.firstDate.year
                    ? () => setState(() => selectedYear--)
                    : null,
                icon: Icon(
                  Icons.chevron_left,
                  color: selectedYear > widget.firstDate.year
                      ? Theme.of(context).primaryColor
                      : Theme.of(context).disabledColor,
                ),
              ),
              Text(
                '$selectedYear',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).primaryColor,
                ),
              ),
              IconButton(
                onPressed: selectedYear < widget.lastDate.year
                    ? () => setState(() => selectedYear++)
                    : null,
                icon: Icon(
                  Icons.chevron_right,
                  color: selectedYear < widget.lastDate.year
                      ? Theme.of(context).primaryColor
                      : Theme.of(context).disabledColor,
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 16),
        
        // Month grid
        Expanded(
          child: GridView.builder(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              childAspectRatio: 2,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: 12,
            itemBuilder: (context, index) {
              final month = index + 1;
              final date = DateTime(selectedYear, month);
              final isEnabled = !date.isBefore(DateTime(widget.firstDate.year, widget.firstDate.month)) &&
                               !date.isAfter(DateTime(widget.lastDate.year, widget.lastDate.month));
              final isSelected = month == selectedMonth && selectedYear == widget.initialDate.year;
              
              final monthNames = [
                'T1', 'T2', 'T3', 'T4', 'T5', 'T6',
                'T7', 'T8', 'T9', 'T10', 'T11', 'T12'
              ];

              return Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: isEnabled 
                      ? () => widget.onSelected(DateTime(selectedYear, month, 1))
                      : null,
                  child: Container(
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Theme.of(context).primaryColor.withOpacity(0.2)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSelected
                            ? Theme.of(context).primaryColor
                            : Theme.of(context).dividerColor.withOpacity(0.3),
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        monthNames[index],
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                          color: isEnabled
                              ? (isSelected 
                                  ? Theme.of(context).primaryColor
                                  : Theme.of(context).textTheme.bodyMedium?.color)
                              : Theme.of(context).disabledColor,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
