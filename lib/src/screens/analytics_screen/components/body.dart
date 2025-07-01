import 'package:flutter/material.dart';
import 'package:smart_home/config/size_config.dart';
import 'package:smart_home/view/analytics_view_model.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:intl/intl.dart';
import 'energy_overview_card.dart';
import 'device_usage_chart.dart';
import 'cost_breakdown_card.dart';

class Body extends StatelessWidget {
  final AnalyticsViewModel model;
  const Body({Key? key, required this.model}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(
        horizontal: getProportionateScreenWidth(15),
        vertical: getProportionateScreenHeight(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Time Period Selector
          _buildTimePeriodSelector(context),
          
          SizedBox(height: getProportionateScreenHeight(20)),
          
          // Energy Overview Cards
          Row(
            children: [
              Expanded(child: EnergyOverviewCard(
                title: 'Total Usage',
                value: '${model.totalEnergyUsage} kWh',
                change: '+12%',
                isIncrease: true,
                icon: Icons.bolt,
                color: const Color(0xFF6B73FF),
              )),
              SizedBox(width: getProportionateScreenWidth(10)),
              Expanded(child: EnergyOverviewCard(
                title: 'Monthly Cost',
                value: '\$${model.monthlyCost}',
                change: '-8%',
                isIncrease: false,
                icon: Icons.attach_money,
                color: const Color(0xFF4ECDC4),
              )),
            ],
          ),
          
          SizedBox(height: getProportionateScreenHeight(10)),
          
          Row(
            children: [
              Expanded(child: EnergyOverviewCard(
                title: 'Peak Usage',
                value: '${model.peakUsage} kW',
                change: '+5%',
                isIncrease: true,
                icon: Icons.trending_up,
                color: const Color(0xFFFF6B6B),
              )),
              SizedBox(width: getProportionateScreenWidth(10)),
              Expanded(child: EnergyOverviewCard(
                title: 'Efficiency',
                value: '${model.efficiency}%',
                change: '+15%',
                isIncrease: true,
                icon: Icons.eco,
                color: const Color(0xFF95E1D3),
              )),
            ],
          ),
          
          SizedBox(height: getProportionateScreenHeight(25)),
          
          // Energy Usage Chart
          _buildSectionTitle(context, 'Energy Usage Trends'),
          SizedBox(height: getProportionateScreenHeight(15)),
          
          Container(
            height: getProportionateScreenHeight(250),
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
            child: SfCartesianChart(
              primaryXAxis: CategoryAxis(),
              primaryYAxis: NumericAxis(
                numberFormat: NumberFormat.compact(),
                title: AxisTitle(text: 'kWh'),
              ),
              series: <LineSeries<ChartData, String>>[
                LineSeries<ChartData, String>(
                  dataSource: model.energyChartData,
                  xValueMapper: (ChartData data, _) => data.x,
                  yValueMapper: (ChartData data, _) => data.y,
                  color: const Color(0xFF6B73FF),
                  width: 3,
                  markerSettings: const MarkerSettings(
                    isVisible: true,
                    height: 6,
                    width: 6,
                    shape: DataMarkerType.circle,
                  ),
                ),
              ],
              tooltipBehavior: TooltipBehavior(enable: true),
            ),
          ),
          
          SizedBox(height: getProportionateScreenHeight(25)),
          
          // Device Usage
          _buildSectionTitle(context, 'Device Usage'),
          SizedBox(height: getProportionateScreenHeight(15)),
          
          DeviceUsageChart(model: model),
          
          SizedBox(height: getProportionateScreenHeight(25)),
          
          // Cost Breakdown
          _buildSectionTitle(context, 'Cost Breakdown'),
          SizedBox(height: getProportionateScreenHeight(15)),
          
          CostBreakdownCard(model: model),
          
          SizedBox(height: getProportionateScreenHeight(25)),
          
          // Recommendations
          _buildSectionTitle(context, 'Energy Saving Tips'),
          SizedBox(height: getProportionateScreenHeight(15)),
          
          ...model.recommendations.map((recommendation) => 
            _buildRecommendationCard(context, recommendation)
          ).toList(),
          
          SizedBox(height: getProportionateScreenHeight(30)),
        ],
      ),
    );
  }

  Widget _buildTimePeriodSelector(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(getProportionateScreenWidth(5)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: ['Today', 'Week', 'Month', 'Year'].map((period) {
          final isSelected = model.selectedPeriod == period;
          return Expanded(
            child: GestureDetector(
              onTap: () => model.changePeriod(period),
              child: Container(
                padding: EdgeInsets.symmetric(
                  vertical: getProportionateScreenHeight(12),
                ),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF464646) : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  period,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.displayMedium!.copyWith(
                    color: isSelected ? Colors.white : Colors.grey[600],
                    fontSize: 14,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.displayMedium!.copyWith(
        fontSize: 20,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _buildRecommendationCard(BuildContext context, Map<String, dynamic> recommendation) {
    return Container(
      margin: EdgeInsets.only(bottom: getProportionateScreenHeight(10)),
      padding: EdgeInsets.all(getProportionateScreenWidth(15)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(getProportionateScreenWidth(8)),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              recommendation['icon'],
              color: Colors.green,
              size: 20,
            ),
          ),
          SizedBox(width: getProportionateScreenWidth(12)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  recommendation['title'],
                  style: Theme.of(context).textTheme.displayMedium!.copyWith(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  recommendation['description'],
                  style: Theme.of(context).textTheme.headlineMedium!.copyWith(
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Text(
            recommendation['savings'],
            style: Theme.of(context).textTheme.displayMedium!.copyWith(
              fontSize: 14,
              color: Colors.green,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}