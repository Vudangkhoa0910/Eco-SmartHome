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

class _FirebaseAnalyticsScreenState extends State<FirebaseAnalyticsScreen>
    with AutomaticKeepAliveClientMixin {
  bool _isLoading = true;
  bool _isRefreshing = false;
  bool _aiEnergyModeEnabled = true;

  // Month selection
  DateTime _selectedMonth = DateTime.now();

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
    _loadAnalyticsDataIfNeeded();
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
        _dataLoaded = true;
        _lastDataLoadTime = DateTime.now();
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
        _dataLoaded =
            true; // Mark as loaded even on error to prevent infinite loading
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
    // Check cache first
    final cacheKey = 'monthly_${_selectedMonth.year}_${_selectedMonth.month}';
    final cachedData = _getCacheData<Map<String, double>>(cacheKey);

    if (cachedData != null) {
      print(
          '📋 Using cached monthly data for ${_formatMonthYear(_selectedMonth)}');
      _monthlyEnergyConsumption = cachedData['consumption'] ?? 0.0;
      _monthlyCost = cachedData['cost'] ?? 0.0;
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

      _monthlyEnergyConsumption = totalConsumption > 0
          ? totalConsumption
          : 0.0; // Show 0 instead of fallback to avoid confusion

      // Calculate cost (1500 VND per kWh as default)
      _monthlyCost = _monthlyEnergyConsumption * 1500;

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

      // If no real data, leave empty instead of demo data
      if (_deviceUsageData.isEmpty) {
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
      _deviceStats = await _firebaseService.getDeviceStats('', timeRange: '7d');
    } catch (e) {
      print('❌ Error loading device stats: $e');
      _deviceStats = {};
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
        _dataLoaded = false;
        _lastDataLoadTime = null;
        await _loadAnalyticsData();
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
              SizedBox(height: getProportionateScreenHeight(12)),
              _buildAIEnergyModeCard(),
              SizedBox(height: getProportionateScreenHeight(12)),
              _buildMonthlyCostCard(),
              SizedBox(height: getProportionateScreenHeight(12)),
              _buildDailyUsageCard(),
              SizedBox(height: getProportionateScreenHeight(12)),
              _buildDeviceUsageCard(),
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

  // Month Selector Widget
  Widget _buildMonthSelector() {
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
          Icon(
            Icons.calendar_month,
            color: Theme.of(context).primaryColor,
            size: 20,
          ),
          SizedBox(width: getProportionateScreenWidth(12)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Chọn tháng thống kê',
                  style: TextStyle(
                    color: Theme.of(context).textTheme.titleLarge?.color,
                    fontSize: getProportionateScreenWidth(14),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: getProportionateScreenHeight(4)),
                GestureDetector(
                  onTap: () => _showMonthPicker(),
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: getProportionateScreenWidth(12),
                      vertical: getProportionateScreenHeight(8),
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Theme.of(context).dividerColor,
                        width: 1,
                      ),
                      borderRadius: BorderRadius.circular(8),
                      color: Theme.of(context).cardColor,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _formatMonthYear(_selectedMonth),
                          style: TextStyle(
                            color: Theme.of(context).textTheme.bodyMedium?.color,
                            fontSize: getProportionateScreenWidth(12),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Icon(
                          Icons.calendar_today,
                          color: Theme.of(context).primaryColor,
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (_isRefreshing)
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(
                    Theme.of(context).primaryColor),
              ),
            ),
        ],
      ),
    );
  }



  // Show month picker dialog
  Future<void> _showMonthPicker() async {
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
        _refreshDataForMonth(selectedMonth);
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
                      : 'Chưa có dữ liệu',
                  style: TextStyle(
                    color: _currentPowerConsumption > 0
                        ? Colors.blue[300]
                        : Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.color
                            ?.withValues(alpha: 0.7),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Chi phí điện ${_formatMonthYear(_selectedMonth)}',
                style: TextStyle(
                  color: Theme.of(context).textTheme.titleLarge?.color,
                  fontSize: getProportionateScreenWidth(14),
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (_isRefreshing)
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                        Theme.of(context).primaryColor),
                  ),
                ),
            ],
          ),
          SizedBox(height: getProportionateScreenHeight(16)),
          Row(
            children: [
              Flexible(
                child: Text(
                  '${(_monthlyCost > 0 ? _monthlyCost.toStringAsFixed(0) : '0')}',
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
                  _monthlyCost > 0
                      ? 'Tiết kiệm ${(_monthlyCost * 0.3).toStringAsFixed(0)}đ với AI'
                      : 'Chưa có dữ liệu tiết kiệm',
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
                      '${(_monthlyCost > 0 ? (_monthlyCost * 1.65).toStringAsFixed(0) : '0')} đ',
                      style: TextStyle(
                        color: Theme.of(context).textTheme.titleLarge?.color,
                        fontSize: getProportionateScreenWidth(10),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      '${(_monthlyCost > 0 ? (_monthlyCost * 1.1).toStringAsFixed(0) : '0')} đ',
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
            '${(_monthlyEnergyConsumption > 0 ? _monthlyEnergyConsumption.toStringAsFixed(2) : '0.00')} kWh',
            style: TextStyle(
              color: Theme.of(context).textTheme.titleLarge?.color,
              fontSize: getProportionateScreenWidth(16),
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            _monthlyEnergyConsumption > 0
                ? 'Tiêu thụ ít hơn ${(_monthlyEnergyConsumption * 0.1).toStringAsFixed(2)} kWh so với cùng kỳ tháng trước.'
                : 'Chưa có dữ liệu tiêu thụ năng lượng cho tháng này.',
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
                      '${(_dailyEnergyConsumption > 0 ? _dailyEnergyConsumption.toStringAsFixed(2) : '0.00')} kWh',
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
                      '${((_dailyEnergyConsumption > 0 ? _dailyEnergyConsumption : 0.0) * 0.3).toStringAsFixed(2)} kWh',
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
        Center(
          child: Padding(
            padding: EdgeInsets.symmetric(
                vertical: getProportionateScreenHeight(20)),
            child: Text(
              'Chưa có dữ liệu thiết bị',
              style: TextStyle(
                color: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.color
                    ?.withValues(alpha: 0.7),
                fontSize: getProportionateScreenWidth(12),
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ),
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
