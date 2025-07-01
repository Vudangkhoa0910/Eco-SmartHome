import 'package:flutter/material.dart';
import 'package:smart_home/config/size_config.dart';
import 'package:smart_home/provider/getit.dart';
import 'package:smart_home/service/electricity_bill_service.dart';

class ElectricitySettingsScreen extends StatefulWidget {
  static String routeName = '/electricity-settings';
  
  const ElectricitySettingsScreen({Key? key}) : super(key: key);

  @override
  State<ElectricitySettingsScreen> createState() => _ElectricitySettingsScreenState();
}

class _ElectricitySettingsScreenState extends State<ElectricitySettingsScreen> {
  final ElectricityBillService _billService = getIt<ElectricityBillService>();
  final TextEditingController _testKwhController = TextEditingController(text: '150');
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text(
          'Cài đặt giá điện',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(getProportionateScreenWidth(16)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTierSelector(),
            SizedBox(height: getProportionateScreenHeight(20)),
            _buildCurrentTierInfo(),
            SizedBox(height: getProportionateScreenHeight(20)),
            _buildBillCalculator(),
            SizedBox(height: getProportionateScreenHeight(20)),
            _buildTierBreakdown(),
          ],
        ),
      ),
    );
  }

  Widget _buildTierSelector() {
    return Container(
      padding: EdgeInsets.all(getProportionateScreenWidth(16)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Loại hình sử dụng điện',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: getProportionateScreenHeight(12)),
          ..._billService.allTiers.entries.map((entry) {
            final isSelected = _billService.currentTierType == entry.key;
            return Container(
              margin: EdgeInsets.only(bottom: getProportionateScreenHeight(8)),
              child: ListTile(
                title: Text(entry.value.name),
                subtitle: Text(_getTierDescription(entry.key)),
                leading: Radio<String>(
                  value: entry.key,
                  groupValue: _billService.currentTierType,
                  onChanged: (value) {
                    setState(() {
                      _billService.setTierType(value!);
                    });
                  },
                ),
                tileColor: isSelected ? Colors.blue[50] : Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(
                    color: isSelected ? Colors.blue : Colors.grey[300]!,
                  ),
                ),
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildCurrentTierInfo() {
    final currentTier = _billService.currentTier;
    
    return Container(
      padding: EdgeInsets.all(getProportionateScreenWidth(16)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Bảng giá hiện tại: ${currentTier.name}',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: getProportionateScreenHeight(12)),
          ...currentTier.tiers.map((tier) {
            return Padding(
              padding: EdgeInsets.symmetric(vertical: getProportionateScreenHeight(4)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${tier.from.toInt()} - ${tier.to == double.infinity ? '∞' : tier.to.toInt()} kWh',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  Text(
                    '${tier.rate.toStringAsFixed(0)} đ/kWh',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Colors.green[700],
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildBillCalculator() {
    return Container(
      padding: EdgeInsets.all(getProportionateScreenWidth(16)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tính toán hóa đơn',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: getProportionateScreenHeight(12)),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _testKwhController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Số kWh tiêu thụ',
                    border: OutlineInputBorder(),
                    suffixText: 'kWh',
                  ),
                  onChanged: (value) {
                    setState(() {});
                  },
                ),
              ),
              SizedBox(width: getProportionateScreenWidth(12)),
              ElevatedButton(
                onPressed: () {
                  setState(() {});
                },
                child: const Text('Tính'),
              ),
            ],
          ),
          SizedBox(height: getProportionateScreenHeight(12)),
          _buildCalculationResult(),
        ],
      ),
    );
  }

  Widget _buildCalculationResult() {
    final kwh = double.tryParse(_testKwhController.text) ?? 0;
    if (kwh <= 0) return const SizedBox();
    
    final bill = _billService.calculateBill(kwh);
    
    return Container(
      padding: EdgeInsets.all(getProportionateScreenWidth(12)),
      decoration: BoxDecoration(
        color: Colors.green[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green[200]!),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Tổng tiền điện:',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '${bill.totalCost.toStringAsFixed(0)} đ',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Colors.green[700],
                ),
              ),
            ],
          ),
          SizedBox(height: getProportionateScreenHeight(4)),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Giá trung bình:'),
              Text('${bill.averageRate.toStringAsFixed(0)} đ/kWh'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTierBreakdown() {
    final kwh = double.tryParse(_testKwhController.text) ?? 0;
    if (kwh <= 0) return const SizedBox();
    
    final bill = _billService.calculateBill(kwh);
    
    return Container(
      padding: EdgeInsets.all(getProportionateScreenWidth(16)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Chi tiết theo bậc',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: getProportionateScreenHeight(12)),
          ...bill.tierUsages.entries.map((entry) {
            final usage = entry.value;
            return Container(
              margin: EdgeInsets.only(bottom: getProportionateScreenHeight(8)),
              padding: EdgeInsets.all(getProportionateScreenWidth(12)),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Bậc ${entry.key}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '${usage.rate.toStringAsFixed(0)} đ/kWh',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                  SizedBox(height: getProportionateScreenHeight(4)),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('${usage.kwh.toStringAsFixed(1)} kWh'),
                      Text(
                        '${usage.cost.toStringAsFixed(0)} đ',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.green[700],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  String _getTierDescription(String tierType) {
    switch (tierType) {
      case 'residential':
        return 'Sử dụng sinh hoạt - Bậc thang 6 mức giá';
      case 'business':
        return 'Kinh doanh dịch vụ - Giá cố định';
      case 'industrial':
        return 'Sản xuất công nghiệp - Giá ưu đãi';
      default:
        return '';
    }
  }

  @override
  void dispose() {
    _testKwhController.dispose();
    super.dispose();
  }
}
