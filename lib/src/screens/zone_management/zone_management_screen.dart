import 'package:flutter/material.dart';
import 'package:smart_home/config/size_config.dart';
import 'package:smart_home/service/zone_management_service.dart';
import 'package:smart_home/service/mqtt_service.dart';
import 'package:smart_home/provider/getit.dart';
import 'package:smart_home/src/screens/analytics_screen/influx_analytics_screen.dart';

class ZoneManagementScreen extends StatefulWidget {
  const ZoneManagementScreen({Key? key}) : super(key: key);

  @override
  State<ZoneManagementScreen> createState() => _ZoneManagementScreenState();
}

class _ZoneManagementScreenState extends State<ZoneManagementScreen> {
  final ZoneManagementService _zoneService = getIt<ZoneManagementService>();
  final MqttService _mqttService = getIt<MqttService>();
  
  @override
  void initState() {
    super.initState();
    _zoneService.initialize(_mqttService, getIt());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý khu vực'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.analytics),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const InfluxAnalyticsScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<List<Zone>>(
        stream: _zoneService.zonesStream,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final zones = snapshot.data!;
          return SingleChildScrollView(
            padding: EdgeInsets.all(getProportionateScreenWidth(16)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildEnergyOverview(),
                SizedBox(height: getProportionateScreenHeight(24)),
                _buildQuickActions(),
                SizedBox(height: getProportionateScreenHeight(24)),
                Text(
                  'Khu vực',
                  style: Theme.of(context).textTheme.titleLarge!.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: getProportionateScreenHeight(16)),
                ...zones.map((zone) => _buildZoneCard(zone)).toList(),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildEnergyOverview() {
    return Container(
      padding: EdgeInsets.all(getProportionateScreenWidth(20)),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF4CAF50), Color(0xFF45A049)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.electrical_services,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              SizedBox(width: getProportionateScreenWidth(16)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Tổng năng lượng',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      '${_zoneService.getTotalPowerConsumption().toStringAsFixed(1)} W',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: getProportionateScreenHeight(16)),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildEnergyInfo('Thiết bị hoạt động', '${_getActiveDevicesCount()}'),
              _buildEnergyInfo('Tổng thiết bị', '${_zoneService.getAllDevices().length}'),
              _buildEnergyInfo('Hiệu suất', '85%'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEnergyInfo(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.8),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActions() {
    return Container(
      padding: EdgeInsets.all(getProportionateScreenWidth(16)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Thao tác nhanh',
            style: Theme.of(context).textTheme.titleMedium!.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: getProportionateScreenHeight(12)),
          Row(
            children: [
              Expanded(
                child: _buildQuickActionButton(
                  'Tắt tất cả',
                  Icons.power_off,
                  Colors.red,
                  () => _toggleAllDevices(false),
                ),
              ),
              SizedBox(width: getProportionateScreenWidth(12)),
              Expanded(
                child: _buildQuickActionButton(
                  'Bật tất cả',
                  Icons.power,
                  Colors.green,
                  () => _toggleAllDevices(true),
                ),
              ),
              SizedBox(width: getProportionateScreenWidth(12)),
              Expanded(
                child: _buildQuickActionButton(
                  'Thống kê',
                  Icons.analytics,
                  Colors.blue,
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const InfluxAnalyticsScreen(),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionButton(String title, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          vertical: getProportionateScreenHeight(12),
          horizontal: getProportionateScreenWidth(8),
        ),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            SizedBox(height: getProportionateScreenHeight(4)),
            Text(
              title,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildZoneCard(Zone zone) {
    final zonePower = _zoneService.getZonePowerConsumption(zone.id);
    final activeDevices = zone.devices.where((device) => device.isOn).length;
    
    return Container(
      margin: EdgeInsets.only(bottom: getProportionateScreenHeight(16)),
      padding: EdgeInsets.all(getProportionateScreenWidth(16)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  zone.icon,
                  style: const TextStyle(fontSize: 24),
                ),
              ),
              SizedBox(width: getProportionateScreenWidth(12)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      zone.name,
                      style: Theme.of(context).textTheme.titleMedium!.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '$activeDevices/${zone.devices.length} thiết bị đang hoạt động',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${zonePower.toStringAsFixed(1)} W',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.green,
                    ),
                  ),
                  Text(
                    'Năng lượng',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ],
          ),
          if (zone.devices.isNotEmpty) ...[
            SizedBox(height: getProportionateScreenHeight(16)),
            const Divider(height: 1),
            SizedBox(height: getProportionateScreenHeight(16)),
            ...zone.devices.map((device) => _buildDeviceControl(zone, device)).toList(),
          ],
        ],
      ),
    );
  }

  Widget _buildDeviceControl(Zone zone, Device device) {
    return Container(
      margin: EdgeInsets.only(bottom: getProportionateScreenHeight(8)),
      padding: EdgeInsets.symmetric(
        horizontal: getProportionateScreenWidth(12),
        vertical: getProportionateScreenHeight(8),
      ),
      decoration: BoxDecoration(
        color: device.isOn ? Colors.blue.withOpacity(0.1) : Colors.grey.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            _getDeviceIcon(device.type),
            color: device.isOn ? Colors.blue : Colors.grey,
            size: 20,
          ),
          SizedBox(width: getProportionateScreenWidth(12)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  device.name,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: device.isOn ? Colors.blue : Colors.grey[700],
                  ),
                ),
                Text(
                  '${device.powerConsumption.toStringAsFixed(0)}W',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: device.isOn,
            onChanged: (value) => _toggleDevice(zone, device, value),
            activeColor: Colors.blue,
          ),
        ],
      ),
    );
  }

  IconData _getDeviceIcon(DeviceType type) {
    switch (type) {
      case DeviceType.light:
        return Icons.lightbulb;
      case DeviceType.motor:
        return Icons.settings;
      case DeviceType.fan:
        return Icons.air;
      case DeviceType.airConditioner:
        return Icons.ac_unit;
      case DeviceType.speaker:
        return Icons.speaker;
    }
  }

  void _toggleDevice(Zone zone, Device device, bool isOn) {
    switch (device.id) {
      case 'led1':
        _mqttService.controlLed1(isOn);
        break;
      case 'led2':
        _mqttService.controlLed2(isOn);
        break;
      case 'motor':
        _mqttService.controlMotor(isOn ? 'ON' : 'OFF');
        break;
    }
    
    _zoneService.updateDeviceState(zone.id, device.id, isOn);
  }

  void _toggleAllDevices(bool isOn) {
    for (final zone in _zoneService.zones) {
      for (final device in zone.devices) {
        _toggleDevice(zone, device, isOn);
      }
    }
  }

  int _getActiveDevicesCount() {
    return _zoneService.getAllDevices().where((device) => device.isOn).length;
  }
}
