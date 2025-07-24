import 'package:flutter/material.dart';
import 'package:smart_home/config/size_config.dart';

class EnergyOptimizationCard extends StatelessWidget {
  final List<Map<String, dynamic>> deviceOptimization;
  final VoidCallback? onOptimizeAll;

  const EnergyOptimizationCard({
    Key? key,
    required this.deviceOptimization,
    this.onOptimizeAll,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(getProportionateScreenWidth(16)),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.black.withOpacity(0.3)
                : Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.settings_suggest,
                  color: Colors.blue,
                  size: 24,
                ),
              ),
              SizedBox(width: getProportionateScreenWidth(12)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tối ưu hóa thiết bị',
                      style: TextStyle(
                        fontSize: getProportionateScreenWidth(16),
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).textTheme.titleLarge?.color,
                      ),
                    ),
                    Text(
                      'Gợi ý cải thiện hiệu suất',
                      style: TextStyle(
                        fontSize: getProportionateScreenWidth(12),
                        color: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.color
                            ?.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
              if (onOptimizeAll != null)
                TextButton(
                  onPressed: onOptimizeAll,
                  child: Text(
                    'Tối ưu tất cả',
                    style: TextStyle(
                      fontSize: getProportionateScreenWidth(12),
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                ),
            ],
          ),
          
          SizedBox(height: getProportionateScreenHeight(16)),
          
          // Device optimization list
          if (deviceOptimization.isEmpty) 
            _buildEmptyState(context)
          else
            Column(
              children: deviceOptimization.map<Widget>((device) => 
                _buildDeviceOptimizationItem(context, device)
              ).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(20),
      child: Column(
        children: [
          Icon(
            Icons.eco,
            size: 48,
            color: Colors.green.withOpacity(0.5),
          ),
          SizedBox(height: 8),
          Text(
            'Hệ thống đang hoạt động tối ưu',
            style: TextStyle(
              fontSize: getProportionateScreenWidth(14),
              fontWeight: FontWeight.w600,
              color: Theme.of(context).textTheme.titleMedium?.color,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Không có gợi ý tối ưu nào trong thời điểm này',
            style: TextStyle(
              fontSize: getProportionateScreenWidth(12),
              color: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.color
                  ?.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildDeviceOptimizationItem(BuildContext context, Map<String, dynamic> device) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? Colors.grey[800]
            : Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _getImpactColor(device['impact'] ?? '').withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Device header
          Row(
            children: [
              Icon(
                _getDeviceIcon(device['device'] ?? ''),
                size: 20,
                color: Theme.of(context).primaryColor,
              ),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  device['device'] ?? 'Thiết bị không xác định',
                  style: TextStyle(
                    fontSize: getProportionateScreenWidth(14),
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).textTheme.titleMedium?.color,
                  ),
                ),
              ),
              // Impact badge
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getImpactColor(device['impact'] ?? '').withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  device['impact'] ?? '',
                  style: TextStyle(
                    fontSize: getProportionateScreenWidth(10),
                    fontWeight: FontWeight.w600,
                    color: _getImpactColor(device['impact'] ?? ''),
                  ),
                ),
              ),
            ],
          ),
          
          SizedBox(height: 8),
          
          // Current usage
          if (device['current_usage'] != null)
            Row(
              children: [
                Icon(
                  Icons.power,
                  size: 14,
                  color: Colors.orange,
                ),
                SizedBox(width: 4),
                Text(
                  'Hiện tại: ${device['current_usage']}',
                  style: TextStyle(
                    fontSize: getProportionateScreenWidth(11),
                    color: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.color
                        ?.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          
          SizedBox(height: 6),
          
          // Optimization suggestion
          if (device['optimization'] != null)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.lightbulb_outline,
                  size: 14,
                  color: Colors.green,
                ),
                SizedBox(width: 4),
                Expanded(
                  child: Text(
                    'Gợi ý: ${device['optimization']}',
                    style: TextStyle(
                      fontSize: getProportionateScreenWidth(11),
                      color: Colors.green[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          
          SizedBox(height: 8),
          
          // Action buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _showDeviceDetails(context, device),
                  icon: Icon(Icons.info_outline, size: 16),
                  label: Text(
                    'Chi tiết',
                    style: TextStyle(fontSize: getProportionateScreenWidth(11)),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _applyOptimization(context, device),
                  icon: Icon(Icons.check, size: 16),
                  label: Text(
                    'Áp dụng',
                    style: TextStyle(fontSize: getProportionateScreenWidth(11)),
                  ),
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
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

  Color _getImpactColor(String impact) {
    switch (impact.toLowerCase()) {
      case 'cao':
      case 'high':
        return Colors.red;
      case 'trung bình':
      case 'medium':
        return Colors.orange;
      case 'thấp':
      case 'low':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  IconData _getDeviceIcon(String deviceName) {
    final name = deviceName.toLowerCase();
    if (name.contains('điều hòa') || name.contains('ac')) return Icons.ac_unit;
    if (name.contains('quạt') || name.contains('fan')) return Icons.wind_power;
    if (name.contains('đèn') || name.contains('light')) return Icons.lightbulb;
    if (name.contains('tivi') || name.contains('tv')) return Icons.tv;
    if (name.contains('máy giặt')) return Icons.local_laundry_service;
    if (name.contains('tủ lạnh')) return Icons.kitchen;
    return Icons.electrical_services;
  }

  void _showDeviceDetails(BuildContext context, Map<String, dynamic> device) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(_getDeviceIcon(device['device'] ?? '')),
            SizedBox(width: 8),
            Expanded(child: Text(device['device'] ?? '')),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (device['current_usage'] != null) ...[
              Text('Mức tiêu thụ hiện tại:'),
              Text(
                device['current_usage'],
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 12),
            ],
            if (device['optimization'] != null) ...[
              Text('Gợi ý tối ưu hóa:'),
              Text(
                device['optimization'],
                style: TextStyle(color: Colors.green[700]),
              ),
              SizedBox(height: 12),
            ],
            if (device['impact'] != null) ...[
              Text('Mức độ tác động:'),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getImpactColor(device['impact']).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  device['impact'],
                  style: TextStyle(
                    color: _getImpactColor(device['impact']),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Đóng'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _applyOptimization(context, device);
            },
            child: Text('Áp dụng'),
          ),
        ],
      ),
    );
  }

  void _applyOptimization(BuildContext context, Map<String, dynamic> device) {
    // TODO: Implement actual optimization logic
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Đã áp dụng tối ưu cho ${device['device']}'),
        backgroundColor: Colors.green,
        action: SnackBarAction(
          label: 'Hoàn tác',
          textColor: Colors.white,
          onPressed: () {
            // TODO: Implement undo logic
          },
        ),
      ),
    );
  }
}
