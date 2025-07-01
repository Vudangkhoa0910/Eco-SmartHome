import 'package:smart_home/config/size_config.dart';
import 'package:smart_home/view/home_screen_view_model.dart';
import 'package:smart_home/src/screens/electricity_settings/electricity_settings_screen.dart';
import 'package:flutter/material.dart';

class ModernEnergyCard extends StatefulWidget {
  const ModernEnergyCard({Key? key, required this.model}) : super(key: key);

  final HomeScreenViewModel model;

  @override
  State<ModernEnergyCard> createState() => _ModernEnergyCardState();
}

class _ModernEnergyCardState extends State<ModernEnergyCard>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      setState(() {
        _selectedIndex = _tabController.index;
      });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            // Tab Header
            Padding(
              padding: EdgeInsets.all(getProportionateScreenWidth(20)),
              child: Row(
                children: [
                  _buildTab('Savings', 0),
                  SizedBox(width: 8),
                  _buildTab('Energy', 1),
                  const Spacer(),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: const Color(0xFF9E9E9E),
                  ),
                ],
              ),
            ),
            
            // Content
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: _selectedIndex == 0 
                  ? _buildSavingsContent()
                  : _buildEnergyContent(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTab(String title, int index) {
    final isSelected = _selectedIndex == index;
    return GestureDetector(
      onTap: () {
        _tabController.animateTo(index);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(
          horizontal: getProportionateScreenWidth(12),
          vertical: getProportionateScreenHeight(6),
        ),
        decoration: BoxDecoration(
          color: isSelected 
              ? const Color(0xFF6B73FF).withOpacity(0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isSelected 
                ? const Color(0xFF6B73FF)
                : const Color(0xFF9E9E9E),
          ),
        ),
      ),
    );
  }

  Widget _buildSavingsContent() {
    final sensorData = widget.model.sensorData;
    final powerKw = sensorData.power / 1000;
    final dailyCost = widget.model.dailyCost;
    
    return Padding(
      key: const ValueKey('savings'),
      padding: EdgeInsets.only(
        left: getProportionateScreenWidth(20),
        right: getProportionateScreenWidth(20),
        bottom: getProportionateScreenHeight(20),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.savings_outlined,
                      color: const Color(0xFF4CAF50),
                      size: 20,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Daily Savings',
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
                      '${(dailyCost * 0.15).toStringAsFixed(0)}',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF4CAF50),
                      ),
                    ),
                    SizedBox(width: 4),
                    Text(
                      'đ',
                      style: TextStyle(
                        fontSize: 16,
                        color: const Color(0xFF9E9E9E),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 4),
                Text(
                  'Compared to manual control',
                  style: TextStyle(
                    fontSize: 12,
                    color: const Color(0xFF9E9E9E),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.all(getProportionateScreenWidth(16)),
            decoration: BoxDecoration(
              color: const Color(0xFF4CAF50).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.trending_up,
                  color: const Color(0xFF4CAF50),
                  size: 32,
                ),
                SizedBox(height: 4),
                Text(
                  '15%',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF4CAF50),
                  ),
                ),
                Text(
                  'Efficiency',
                  style: TextStyle(
                    fontSize: 10,
                    color: const Color(0xFF4CAF50),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnergyContent() {
    final sensorData = widget.model.sensorData;
    final powerKw = sensorData.power / 1000;
    
    return Padding(
      key: const ValueKey('energy'),
      padding: EdgeInsets.only(
        left: getProportionateScreenWidth(20),
        right: getProportionateScreenWidth(20),
        bottom: getProportionateScreenHeight(20),
      ),
      child: Row(
        children: [
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
                      'Power Usage',
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
                SizedBox(height: 4),
                Text(
                  '${sensorData.voltage.toStringAsFixed(1)}V • ${sensorData.current.toStringAsFixed(0)}mA',
                  style: TextStyle(
                    fontSize: 12,
                    color: const Color(0xFF9E9E9E),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.all(getProportionateScreenWidth(16)),
            decoration: BoxDecoration(
              color: const Color(0xFF6B73FF).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.power,
                  color: const Color(0xFF6B73FF),
                  size: 32,
                ),
                SizedBox(height: 4),
                Text(
                  'Live',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF6B73FF),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
