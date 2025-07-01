import 'package:flutter/material.dart';
import 'package:smart_home/provider/base_model.dart';

class AnalyticsViewModel extends BaseModel {
  String _selectedPeriod = 'Week';
  double _totalEnergyUsage = 156.8;
  double _monthlyCost = 89.50;
  double _peakUsage = 3.2;
  int _efficiency = 87;
  
  List<ChartData> _energyChartData = [];
  List<Map<String, dynamic>> _recommendations = [];

  String get selectedPeriod => _selectedPeriod;
  double get totalEnergyUsage => _totalEnergyUsage;
  double get monthlyCost => _monthlyCost;
  double get peakUsage => _peakUsage;
  int get efficiency => _efficiency;
  List<ChartData> get energyChartData => _energyChartData;
  List<Map<String, dynamic>> get recommendations => _recommendations;

  void loadAnalytics() {
    _generateChartData();
    _generateRecommendations();
    notifyListeners();
  }

  void _generateChartData() {
    _energyChartData = [
      ChartData('Mon', 15.2),
      ChartData('Tue', 18.5),
      ChartData('Wed', 22.1),
      ChartData('Thu', 19.8),
      ChartData('Fri', 25.3),
      ChartData('Sat', 28.9),
      ChartData('Sun', 27.0),
    ];
  }

  void _generateRecommendations() {
    _recommendations = [
      {
        'title': 'Use Smart Scheduling',
        'description': 'Schedule AC to turn off 30 minutes before you leave',
        'savings': 'Save \$12/month',
        'icon': Icons.schedule,
      },
      {
        'title': 'Optimize Lighting',
        'description': 'Switch to LED bulbs in remaining rooms',
        'savings': 'Save \$8/month',
        'icon': Icons.lightbulb,
      },
      {
        'title': 'Smart Thermostat',
        'description': 'Upgrade to smart thermostat for better control',
        'savings': 'Save \$25/month',
        'icon': Icons.thermostat,
      },
    ];
  }

  void changePeriod(String period) {
    _selectedPeriod = period;
    _updateDataForPeriod(period);
    notifyListeners();
  }

  void _updateDataForPeriod(String period) {
    switch (period) {
      case 'Today':
        _totalEnergyUsage = 8.2;
        _energyChartData = [
          ChartData('6AM', 1.2),
          ChartData('9AM', 2.1),
          ChartData('12PM', 3.5),
          ChartData('3PM', 4.2),
          ChartData('6PM', 5.8),
          ChartData('9PM', 4.1),
        ];
        break;
      case 'Month':
        _totalEnergyUsage = 680.5;
        _energyChartData = [
          ChartData('Week 1', 150.2),
          ChartData('Week 2', 165.8),
          ChartData('Week 3', 180.1),
          ChartData('Week 4', 184.4),
        ];
        break;
      case 'Year':
        _totalEnergyUsage = 8200.0;
        _energyChartData = [
          ChartData('Jan', 720.0),
          ChartData('Feb', 650.0),
          ChartData('Mar', 680.0),
          ChartData('Apr', 590.0),
          ChartData('May', 720.0),
          ChartData('Jun', 850.0),
        ];
        break;
      default: // Week
        _generateChartData();
    }
  }

  void showFilterOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Filter Options',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.home),
              title: const Text('By Room'),
              onTap: () {},
            ),
            ListTile(
              leading: const Icon(Icons.devices),
              title: const Text('By Device Type'),
              onTap: () {},
            ),
            ListTile(
              leading: const Icon(Icons.access_time),
              title: const Text('By Time of Day'),
              onTap: () {},
            ),
          ],
        ),
      ),
    );
  }
}

class ChartData {
  ChartData(this.x, this.y);
  final String x;
  final double y;
}
