import 'package:smart_home/config/size_config.dart';
import 'package:smart_home/view/home_screen_view_model.dart';
import 'package:smart_home/src/screens/electricity_settings/electricity_settings_screen.dart';
import 'package:flutter/material.dart';

class SavingsContainer extends StatelessWidget {
  const SavingsContainer({Key? key, required this.model, this.isCompact = false}) : super(key: key);

  final HomeScreenViewModel model;
  final bool isCompact;

  @override
  Widget build(BuildContext context) {
    final sensorData = model.sensorData;
    final powerKw = sensorData.power / 1000; // Convert mW to kW
    final efficiency = sensorData.voltage > 0 ? ((sensorData.voltage / 5.0) * 100).clamp(0, 100) : 0.0;
    final dailyCost = model.dailyCost;
    
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const ElectricitySettingsScreen(),
          ),
        );
      },
      child: Container(
        padding: EdgeInsets.all(getProportionateScreenWidth(isCompact ? 12 : 20)),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(isCompact ? 12 : 16),
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: isCompact ? 8 : 12,
              offset: Offset(0, isCompact ? 2 : 3),
            ),
          ],
        ),
        child: isCompact ?
          // Compact layout
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tiết kiệm',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF6B73FF),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${dailyCost.toStringAsFixed(0)}k VND',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF2D3748),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.trending_up,
                  color: const Color(0xFF10B981),
                  size: 16,
                ),
              ),
            ],
          ) :
          // Full layout
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with tab indicator
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: getProportionateScreenWidth(12),
                      vertical: getProportionateScreenHeight(6),
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6B73FF).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Tiết kiệm',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF6B73FF),
                      ),
                    ),
                  ),
                  SizedBox(width: 8),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: getProportionateScreenWidth(12),
                      vertical: getProportionateScreenHeight(6),
                    ),
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Năng lượng',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF9E9E9E),
                      ),
                    ),
                  ),
                ],
              ),
              
              SizedBox(height: getProportionateScreenHeight(16)),
            
            // Main content
            Row(
              children: [
                // Power consumption
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.flash_on,
                            color: const Color(0xFF6B73FF),
                            size: 20,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Sử dụng điện',
                            style: TextStyle(
                              fontSize: 14,
                              color: const Color(0xFF9E9E9E),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            powerKw.toStringAsFixed(3),
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF2D3748),
                            ),
                          ),
                          SizedBox(width: 4),
                          Text(
                            'kW',
                            style: TextStyle(
                              fontSize: 16,
                              color: const Color(0xFF9E9E9E),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      Text(
                        '≈ ${dailyCost.toStringAsFixed(0)}đ / ngày',
                        style: TextStyle(
                          fontSize: 12,
                          color: const Color(0xFF4CAF50),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Efficiency indicator
                Container(
                  padding: EdgeInsets.all(getProportionateScreenWidth(16)),
                  decoration: BoxDecoration(
                    color: efficiency > 70 
                        ? const Color(0xFF4CAF50).withOpacity(0.1)
                        : const Color(0xFFFF9800).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: efficiency > 70 
                              ? const Color(0xFF4CAF50)
                              : const Color(0xFFFF9800),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            '${efficiency.round()}%',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Hiệu suất',
                        style: TextStyle(
                          fontSize: 10,
                          color: efficiency > 70 
                              ? const Color(0xFF4CAF50)
                              : const Color(0xFFFF9800),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
