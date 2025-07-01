import 'package:flutter/material.dart';
import 'package:smart_home/config/size_config.dart';
import 'package:smart_home/view/analytics_view_model.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

class DeviceUsageChart extends StatelessWidget {
  final AnalyticsViewModel model;
  
  const DeviceUsageChart({Key? key, required this.model}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: getProportionateScreenHeight(200),
      padding: EdgeInsets.all(getProportionateScreenWidth(15)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SfCircularChart(
        title: ChartTitle(text: 'Device Usage Distribution'),
        legend: Legend(
          isVisible: true,
          position: LegendPosition.right,
          textStyle: const TextStyle(fontSize: 12),
        ),
        series: <PieSeries<DeviceUsageData, String>>[
          PieSeries<DeviceUsageData, String>(
            dataSource: _getDeviceUsageData(),
            xValueMapper: (DeviceUsageData data, _) => data.device,
            yValueMapper: (DeviceUsageData data, _) => data.usage,
            dataLabelSettings: const DataLabelSettings(
              isVisible: true,
              labelPosition: ChartDataLabelPosition.outside,
            ),
            pointColorMapper: (DeviceUsageData data, _) => data.color,
          ),
        ],
      ),
    );
  }

  List<DeviceUsageData> _getDeviceUsageData() {
    return [
      DeviceUsageData('AC', 35, const Color(0xFF6B73FF)),
      DeviceUsageData('Lights', 25, const Color(0xFF4ECDC4)),
      DeviceUsageData('TV', 20, const Color(0xFFFF6B6B)),
      DeviceUsageData('Fan', 15, const Color(0xFFFFD93D)),
      DeviceUsageData('Other', 5, const Color(0xFF95E1D3)),
    ];
  }
}

class DeviceUsageData {
  DeviceUsageData(this.device, this.usage, this.color);
  final String device;
  final double usage;
  final Color color;
}
