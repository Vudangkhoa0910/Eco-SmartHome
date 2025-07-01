import 'package:flutter/material.dart';
import 'package:smart_home/config/size_config.dart';

class EnergyOverviewCard extends StatelessWidget {
  final String title;
  final String value;
  final String change;
  final bool isIncrease;
  final IconData icon;
  final Color color;

  const EnergyOverviewCard({
    Key? key,
    required this.title,
    required this.value,
    required this.change,
    required this.isIncrease,
    required this.icon,
    required this.color,
  }) : super(key: key);

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
              Container(
                padding: EdgeInsets.all(getProportionateScreenWidth(8)),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: getProportionateScreenWidth(8),
                  vertical: getProportionateScreenHeight(2),
                ),
                decoration: BoxDecoration(
                  color: isIncrease ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  change,
                  style: TextStyle(
                    color: isIncrease ? Colors.green : Colors.red,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: getProportionateScreenHeight(15)),
          Text(
            value,
            style: Theme.of(context).textTheme.displayLarge!.copyWith(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          SizedBox(height: getProportionateScreenHeight(2)),
          Text(
            title,
            style: Theme.of(context).textTheme.headlineMedium!.copyWith(
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
