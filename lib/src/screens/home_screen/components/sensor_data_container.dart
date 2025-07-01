import 'package:smart_home/config/size_config.dart';
import 'package:smart_home/view/home_screen_view_model.dart';
import 'package:smart_home/src/screens/sensor_dashboard/sensor_dashboard_screen.dart';
import 'package:flutter/material.dart';

class SensorDataContainer extends StatelessWidget {
  const SensorDataContainer({Key? key, required this.model, this.isCompact = false}) : super(key: key);

  final HomeScreenViewModel model;
  final bool isCompact;

  @override
  Widget build(BuildContext context) {
    final sensorData = model.sensorData;
    
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const SensorDashboardScreen(),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(isCompact ? 12 : 16),
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: isCompact ? 10 : 20,
              offset: Offset(0, isCompact ? 2 : 4),
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.all(getProportionateScreenWidth(isCompact ? 12 : 20)),
          child: isCompact ?
            // Compact layout
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Cảm biến',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF2D3748),
                      ),
                    ),
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: model.isMqttConnected ? Colors.green : Colors.red,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.thermostat_outlined, size: 14, color: const Color(0xFF6B73FF)),
                        const SizedBox(width: 4),
                        Text(
                          '${sensorData.temperature.toStringAsFixed(1)}°C',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF2D3748),
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Icon(Icons.water_drop_outlined, size: 14, color: const Color(0xFF00D4AA)),
                        const SizedBox(width: 4),
                        Text(
                          '${sensorData.humidity.toStringAsFixed(0)}%',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF2D3748),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ) :
            // Full layout
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Cảm biến môi trường',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF2D3748),
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: getProportionateScreenWidth(8),
                        vertical: getProportionateScreenHeight(4),
                      ),
                      decoration: BoxDecoration(
                        color: model.isMqttConnected 
                          ? Colors.green.withOpacity(0.1)
                          : Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: model.isMqttConnected ? Colors.green : Colors.red,
                              shape: BoxShape.circle,
                            ),
                          ),
                          SizedBox(width: 4),
                          Text(
                            model.isMqttConnected ? 'Hoạt động' : 'Offline',
                            style: TextStyle(
                              color: model.isMqttConnected ? Colors.green : Colors.red,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                
                SizedBox(height: getProportionateScreenHeight(16)),
                
                // Sensor readings grid
                Row(
                  children: [
                    Expanded(
                      child: _buildSensorCard(
                        icon: Icons.thermostat_outlined,
                        label: 'Nhiệt độ',
                        value: '${sensorData.temperature.toStringAsFixed(1)}°C',
                        color: const Color(0xFF6B73FF),
                        progress: (sensorData.temperature / 50).clamp(0.0, 1.0),
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: _buildSensorCard(
                        icon: Icons.water_drop_outlined,
                        label: 'Độ ẩm',
                        value: '${sensorData.humidity.toStringAsFixed(0)}%',
                        color: const Color(0xFF00BCD4),
                        progress: (sensorData.humidity / 100).clamp(0.0, 1.0),
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: _buildSensorCard(
                        icon: Icons.flash_on_outlined,
                        label: 'Nguồn',
                        value: '${sensorData.voltage.toStringAsFixed(1)}V',
                        color: const Color(0xFFFF9800),
                        progress: (sensorData.voltage / 12).clamp(0.0, 1.0),
                      ),
                    ),
                  ],
                ),
              ],
            ),
        ),
      ),
    );
  }
  
  Widget _buildSensorCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    required double progress,
  }) {
    return Container(
      padding: EdgeInsets.all(getProportionateScreenWidth(12)),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: color,
            size: 24,
          ),
          SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF2D3748),
            ),
          ),
          SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: const Color(0xFF9E9E9E),
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 8),
          // Progress indicator
          Container(
            width: double.infinity,
            height: 4,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(2),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: progress,
              child: Container(
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
