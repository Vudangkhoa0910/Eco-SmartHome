import 'package:flutter/material.dart';
import 'package:smart_home/config/size_config.dart';
import 'package:smart_home/view/analytics_view_model.dart';

class CostBreakdownCard extends StatelessWidget {
  final AnalyticsViewModel model;
  
  const CostBreakdownCard({Key? key, required this.model}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Monthly Cost',
                style: Theme.of(context).textTheme.displayMedium!.copyWith(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '\$${model.monthlyCost}',
                style: Theme.of(context).textTheme.displayMedium!.copyWith(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF6B73FF),
                ),
              ),
            ],
          ),
          SizedBox(height: getProportionateScreenHeight(15)),
          ..._getCostBreakdown().map((item) => _buildCostItem(context, item)),
        ],
      ),
    );
  }

  Widget _buildCostItem(BuildContext context, Map<String, dynamic> item) {
    return Padding(
      padding: EdgeInsets.only(bottom: getProportionateScreenHeight(8)),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: item['color'],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          SizedBox(width: getProportionateScreenWidth(10)),
          Expanded(
            child: Text(
              item['device'],
              style: Theme.of(context).textTheme.headlineMedium!.copyWith(
                fontSize: 14,
              ),
            ),
          ),
          Text(
            '\$${item['cost']}',
            style: Theme.of(context).textTheme.displayMedium!.copyWith(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> _getCostBreakdown() {
    return [
      {'device': 'Air Conditioning', 'cost': '31.32', 'color': const Color(0xFF6B73FF)},
      {'device': 'Lighting', 'cost': '22.37', 'color': const Color(0xFF4ECDC4)},
      {'device': 'TV & Entertainment', 'cost': '17.90', 'color': const Color(0xFFFF6B6B)},
      {'device': 'Fans', 'cost': '13.42', 'color': const Color(0xFFFFD93D)},
      {'device': 'Other Devices', 'cost': '4.49', 'color': const Color(0xFF95E1D3)},
    ];
  }
}
