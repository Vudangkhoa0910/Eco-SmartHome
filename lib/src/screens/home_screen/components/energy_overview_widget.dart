import 'package:smart_home/config/size_config.dart';
import 'package:smart_home/view/home_screen_view_model.dart';
import 'package:smart_home/src/screens/energy_dashboard/energy_dashboard_screen.dart';
import 'package:flutter/material.dart';

class EnergyOverviewWidget extends StatelessWidget {
  const EnergyOverviewWidget({Key? key, required this.model}) : super(key: key);

  final HomeScreenViewModel model;

  @override
  Widget build(BuildContext context) {
    final sensorData = model.sensorData;
    final powerKw = sensorData.power / 1000; // Convert mW to kW
    final dailyCost = model.dailyCost;
    
    // Mock data for top consuming devices
    final topDevices = [
      {'name': 'Điều hòa', 'power': '1.2kW'},
      {'name': 'Tủ lạnh', 'power': '0.8kW'},
      {'name': 'Đèn LED', 'power': '0.3kW'},
    ];
    
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const EnergyDashboardScreen(),
          ),
        );
      },
      child: Container(
        padding: EdgeInsets.all(getProportionateScreenWidth(16)),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
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
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Năng lượng hôm nay',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF2D3748),
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: Colors.grey[400],
                  size: 20,
                ),
              ],
            ),
            
            SizedBox(height: getProportionateScreenHeight(12)),
            
            // Power consumption summary
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            powerKw.toStringAsFixed(2),
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF2D3748),
                            ),
                          ),
                          SizedBox(width: 4),
                          Text(
                            'kW/ngày',
                            style: TextStyle(
                              fontSize: 12,
                              color: const Color(0xFF9E9E9E),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 4),
                      Text(
                        '≈ ${dailyCost.toStringAsFixed(0)}đ hôm nay',
                        style: TextStyle(
                          fontSize: 12,
                          color: const Color(0xFF4CAF50),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Top consuming devices
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Thiết bị tốn nhiều nhất:',
                        style: TextStyle(
                          fontSize: 11,
                          color: const Color(0xFF9E9E9E),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: 6),
                      ...topDevices.map((device) => Padding(
                        padding: const EdgeInsets.only(bottom: 3),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              device['name']!,
                              style: TextStyle(
                                fontSize: 10,
                                color: const Color(0xFF2D3748),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              device['power']!,
                              style: TextStyle(
                                fontSize: 10,
                                color: const Color(0xFF6B73FF),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      )).toList(),
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
