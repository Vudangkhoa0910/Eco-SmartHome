import 'package:flutter/material.dart';
import 'package:smart_home/config/size_config.dart';
import 'package:smart_home/view/home_screen_view_model.dart';
import 'package:smart_home/provider/getit.dart';

class SensorDashboardScreen extends StatelessWidget {
  const SensorDashboardScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('Tổng quan năng lượng'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        centerTitle: true,
      ),
      body: StreamBuilder<void>(
        stream: Stream.periodic(const Duration(seconds: 2)),
        builder: (context, snapshot) {
          final model = getIt<HomeScreenViewModel>();
          return SingleChildScrollView(
            padding: EdgeInsets.all(getProportionateScreenWidth(20)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Connection Status
                _buildConnectionStatus(context, model),
                SizedBox(height: getProportionateScreenHeight(20)),
                
                // Environmental Sensors Section
                _buildSectionTitle('🌡️ Cảm biến môi trường'),
                SizedBox(height: getProportionateScreenHeight(12)),
                Row(
                  children: [
                    Expanded(
                      child: _buildSensorCard(
                        context,
                        'Nhiệt độ',
                        '${model.sensorData.temperature.toStringAsFixed(1)}°C',
                        Icons.thermostat,
                        Colors.orange,
                      ),
                    ),
                    SizedBox(width: getProportionateScreenWidth(12)),
                    Expanded(
                      child: _buildSensorCard(
                        context,
                        'Độ ẩm',
                        '${model.sensorData.humidity.toStringAsFixed(0)}%',
                        Icons.water_drop,
                        Colors.blue,
                      ),
                    ),
                  ],
                ),
                
                SizedBox(height: getProportionateScreenHeight(20)),
                
                // Power Consumption Section
                _buildPowerConsumptionSection(context, model),
                
                SizedBox(height: getProportionateScreenHeight(20)),
                
                // Energy Statistics Section
                _buildEnergyStatsSection(context, model),
                
                SizedBox(height: getProportionateScreenHeight(20)),
                
                // Data Analysis Section  
                _buildDataAnalysisSection(context, model),
                
                SizedBox(height: getProportionateScreenHeight(100)),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildConnectionStatus(BuildContext context, HomeScreenViewModel model) {
    // Check if we're receiving recent data to determine real connection status
    final isReallyConnected = model.isMqttConnected || 
      (model.sensorData.temperature > 0 || model.sensorData.humidity > 0 || model.sensorData.power > 0);
    
    return Container(
      padding: EdgeInsets.all(getProportionateScreenWidth(16)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isReallyConnected ? const Color(0xFF4CAF50) : const Color(0xFFE57373),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isReallyConnected ? const Color(0xFF4CAF50).withOpacity(0.1) : const Color(0xFFE57373).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              isReallyConnected ? Icons.wifi : Icons.wifi_off,
              color: isReallyConnected ? const Color(0xFF4CAF50) : const Color(0xFFE57373),
              size: 20,
            ),
          ),
          SizedBox(width: getProportionateScreenWidth(12)),
          Expanded(
            child: Text(
              isReallyConnected ? 'Kết nối MQTT thành công' : 'Mất kết nối MQTT',
              style: TextStyle(
                color: const Color(0xFF424242),
                fontWeight: FontWeight.w500,
                fontSize: getProportionateScreenWidth(14),
              ),
            ),
          ),
          if (isReallyConnected)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF4CAF50),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Trực tuyến',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: getProportionateScreenWidth(11),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSensorCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: EdgeInsets.all(getProportionateScreenWidth(16)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            spreadRadius: 0,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              size: 28,
              color: color,
            ),
          ),
          SizedBox(height: getProportionateScreenHeight(12)),
          Text(
            value,
            style: TextStyle(
              fontSize: getProportionateScreenWidth(18),
              fontWeight: FontWeight.w600,
              color: const Color(0xFF212121),
            ),
          ),
          SizedBox(height: getProportionateScreenHeight(4)),
          Text(
            title,
            style: TextStyle(
              fontSize: getProportionateScreenWidth(12),
              color: const Color(0xFF757575),
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: EdgeInsets.only(left: getProportionateScreenWidth(4)),
      child: Text(
        title,
        style: TextStyle(
          fontSize: getProportionateScreenWidth(16),
          fontWeight: FontWeight.w600,
          color: const Color(0xFF212121),
        ),
      ),
    );
  }

  Widget _buildPowerConsumptionSection(BuildContext context, HomeScreenViewModel model) {
    final sensorData = model.sensorData;
    final powerKw = sensorData.power / 1000;
    
    return Container(
      padding: EdgeInsets.all(getProportionateScreenWidth(20)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
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
                'Tiêu thụ điện',
                style: TextStyle(
                  color: const Color(0xFF212121),
                  fontSize: getProportionateScreenWidth(16),
                  fontWeight: FontWeight.w600,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF9800).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.power,
                  color: Color(0xFFFF9800),
                  size: 20,
                ),
              ),
            ],
          ),
          SizedBox(height: getProportionateScreenHeight(16)),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                powerKw.toStringAsFixed(3),
                style: TextStyle(
                  color: const Color(0xFF212121),
                  fontSize: getProportionateScreenWidth(32),
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(width: getProportionateScreenWidth(6)),
              Text(
                'kW',
                style: TextStyle(
                  color: const Color(0xFF757575),
                  fontSize: getProportionateScreenWidth(16),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${sensorData.voltage.toStringAsFixed(1)}V',
                    style: TextStyle(
                      color: const Color(0xFF757575),
                      fontSize: getProportionateScreenWidth(14),
                    ),
                  ),
                  Text(
                    '${sensorData.current.toStringAsFixed(0)}mA',
                    style: TextStyle(
                      color: const Color(0xFF757575),
                      fontSize: getProportionateScreenWidth(14),
                    ),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: getProportionateScreenHeight(8)),
          Text(
            '${sensorData.power.toStringAsFixed(2)} W',
            style: TextStyle(
              color: const Color(0xFF757575),
              fontSize: getProportionateScreenWidth(14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnergyStatsSection(BuildContext context, HomeScreenViewModel model) {
    final sensorData = model.sensorData;
    final efficiency = sensorData.voltage > 0 ? ((sensorData.voltage / 5.0) * 100).clamp(0, 100) : 0.0;
    final dailyCost = model.dailyCost;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('📊 Thống kê năng lượng'),
        SizedBox(height: getProportionateScreenHeight(12)),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Hiệu suất',
                '${efficiency.round()}%',
                Icons.trending_up,
                efficiency > 70 ? const Color(0xFF4CAF50) : const Color(0xFFFF9800),
              ),
            ),
            SizedBox(width: getProportionateScreenWidth(12)),
            Expanded(
              child: _buildStatCard(
                'Chi phí/ngày',
                '${dailyCost.toStringAsFixed(0)} đ',
                Icons.account_balance_wallet,
                const Color(0xFF4CAF50),
              ),
            ),
          ],
        ),
        SizedBox(height: getProportionateScreenHeight(12)),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Điện áp',
                '${sensorData.voltage.toStringAsFixed(1)}V',
                Icons.electrical_services,
                const Color(0xFF2196F3),
              ),
            ),
            SizedBox(width: getProportionateScreenWidth(12)),
            Expanded(
              child: _buildStatCard(
                'Dòng điện',
                '${sensorData.current.toStringAsFixed(0)}mA',
                Icons.bolt,
                const Color(0xFFFF9800),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(getProportionateScreenWidth(16)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
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
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
          SizedBox(height: getProportionateScreenHeight(12)),
          Text(
            value,
            style: TextStyle(
              fontSize: getProportionateScreenWidth(18),
              fontWeight: FontWeight.w600,
              color: const Color(0xFF212121),
            ),
          ),
          SizedBox(height: getProportionateScreenHeight(4)),
          Text(
            title,
            style: TextStyle(
              fontSize: getProportionateScreenWidth(12),
              color: const Color(0xFF757575),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDataAnalysisSection(BuildContext context, HomeScreenViewModel model) {
    final sensorData = model.sensorData;
    final powerFactor = sensorData.voltage > 0 && sensorData.current > 0 
        ? (sensorData.power / (sensorData.voltage * sensorData.current / 1000)).clamp(0, 1)
        : 0.0;
    final energyToday = (sensorData.power * 24) / 1000; // kWh estimate
    final monthlyCost = model.dailyCost * 30;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('📈 Phân tích dữ liệu'),
        SizedBox(height: getProportionateScreenHeight(12)),
        
        // Quick overview cards
        Container(
          padding: EdgeInsets.all(getProportionateScreenWidth(16)),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: _buildAnalysisItem(
                      'Hệ số công suất',
                      '${(powerFactor * 100).toStringAsFixed(1)}%',
                      Icons.analytics,
                      powerFactor > 0.8 ? const Color(0xFF4CAF50) : const Color(0xFFFF9800),
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 40,
                    color: const Color(0xFFE0E0E0),
                  ),
                  Expanded(
                    child: _buildAnalysisItem(
                      'Năng lượng/ngày (ước tính)',
                      '${energyToday.toStringAsFixed(2)} kWh',
                      Icons.battery_charging_full,
                      const Color(0xFF2196F3),
                    ),
                  ),
                ],
              ),
              Divider(color: const Color(0xFFE0E0E0), height: 24),
              Row(
                children: [
                  Expanded(
                    child: _buildAnalysisItem(
                      'Chi phí tháng (ước tính)',
                      '${monthlyCost.toStringAsFixed(0)} đ',
                      Icons.receipt_long,
                      const Color(0xFF4CAF50),
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 40,
                    color: const Color(0xFFE0E0E0),
                  ),
                  Expanded(
                    child: _buildAnalysisItem(
                      'Trạng thái hệ thống',
                      sensorData.power > 100 ? 'Hoạt động' : 'Chờ',
                      Icons.power_settings_new,
                      sensorData.power > 100 ? const Color(0xFF4CAF50) : const Color(0xFF757575),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        
        SizedBox(height: getProportionateScreenHeight(12)),
        
        // Trend indicators
        Row(
          children: [
            Expanded(
              child: _buildTrendCard(
                'Xu hướng công suất',
                sensorData.power > 200 ? 'Tăng' : sensorData.power > 50 ? 'Ổn định' : 'Giảm',
                sensorData.power > 200 ? Icons.trending_up : 
                sensorData.power > 50 ? Icons.trending_flat : Icons.trending_down,
                sensorData.power > 200 ? const Color(0xFFE53935) : 
                sensorData.power > 50 ? const Color(0xFF4CAF50) : const Color(0xFF2196F3),
              ),
            ),
            SizedBox(width: getProportionateScreenWidth(12)),
            Expanded(
              child: _buildTrendCard(
                'Hiệu quả sử dụng',
                powerFactor > 0.8 ? 'Tốt' : powerFactor > 0.6 ? 'Trung bình' : 'Cần cải thiện',
                powerFactor > 0.8 ? Icons.thumb_up : 
                powerFactor > 0.6 ? Icons.horizontal_rule : Icons.thumb_down,
                powerFactor > 0.8 ? const Color(0xFF4CAF50) : 
                powerFactor > 0.6 ? const Color(0xFFFF9800) : const Color(0xFFE53935),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAnalysisItem(String title, String value, IconData icon, Color color) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: getProportionateScreenWidth(8)),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          SizedBox(height: getProportionateScreenHeight(8)),
          Text(
            value,
            style: TextStyle(
              fontSize: getProportionateScreenWidth(14),
              fontWeight: FontWeight.w600,
              color: const Color(0xFF212121),
            ),
          ),
          SizedBox(height: getProportionateScreenHeight(4)),
          Text(
            title,
            style: TextStyle(
              fontSize: getProportionateScreenWidth(11),
              color: const Color(0xFF757575),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildTrendCard(String title, String status, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(getProportionateScreenWidth(16)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(icon, color: color, size: 16),
              ),
              const Spacer(),
              Container(
                width: 4,
                height: 4,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
          SizedBox(height: getProportionateScreenHeight(12)),
          Text(
            status,
            style: TextStyle(
              fontSize: getProportionateScreenWidth(14),
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
          SizedBox(height: getProportionateScreenHeight(4)),
          Text(
            title,
            style: TextStyle(
              fontSize: getProportionateScreenWidth(11),
              color: const Color(0xFF757575),
            ),
          ),
        ],
      ),
    );
  }
}
