import 'package:smart_home/config/size_config.dart';
import 'package:smart_home/view/home_screen_view_model.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:async';

class EnergyOverviewWidget extends StatefulWidget {
  const EnergyOverviewWidget({Key? key, required this.model}) : super(key: key);

  final HomeScreenViewModel model;

  @override
  _EnergyOverviewWidgetState createState() => _EnergyOverviewWidgetState();
}

class _EnergyOverviewWidgetState extends State<EnergyOverviewWidget> 
    with TickerProviderStateMixin {
  late Timer _refreshTimer;
  late AnimationController _powerAnimationController;
  late AnimationController _voltageAnimationController;
  late AnimationController _currentAnimationController;
  
  late Animation<double> _powerAnimation;
  late Animation<double> _voltageAnimation;
  late Animation<double> _currentAnimation;
  
  double _previousPower = 0.0;
  double _previousVoltage = 0.0;
  double _previousCurrent = 0.0;

  @override
  void initState() {
    super.initState();
    
    // Initialize animation controllers
    _powerAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _voltageAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _currentAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    // Initialize animations
    _powerAnimation = Tween<double>(begin: 0, end: 0).animate(
      CurvedAnimation(parent: _powerAnimationController, curve: Curves.easeInOut)
    );
    _voltageAnimation = Tween<double>(begin: 0, end: 0).animate(
      CurvedAnimation(parent: _voltageAnimationController, curve: Curves.easeInOut)
    );
    _currentAnimation = Tween<double>(begin: 0, end: 0).animate(
      CurvedAnimation(parent: _currentAnimationController, curve: Curves.easeInOut)
    );
    
    // Set initial values
    final sensorData = widget.model.sensorData;
    _previousPower = sensorData.power / 1000; // mW to W
    _previousVoltage = sensorData.voltage;
    _previousCurrent = sensorData.current;
    
    // Setup auto-refresh timer (every 1 minute)
    _refreshTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      _updateAnimations();
    });
    
    // Listen to model changes for real-time updates
    widget.model.addListener(_onModelUpdated);
  }

  @override
  void dispose() {
    _refreshTimer.cancel();
    _powerAnimationController.dispose();
    _voltageAnimationController.dispose();
    _currentAnimationController.dispose();
    widget.model.removeListener(_onModelUpdated);
    super.dispose();
  }

  void _onModelUpdated() {
    if (mounted) {
      _updateAnimations();
    }
  }

  void _updateAnimations() {
    final sensorData = widget.model.sensorData;
    final newPower = sensorData.power / 1000; // mW to W
    final newVoltage = sensorData.voltage;
    final newCurrent = sensorData.current;
    
    // Update power animation if value changed
    if ((newPower - _previousPower).abs() > 0.1) {
      _powerAnimation = Tween<double>(
        begin: _previousPower,
        end: newPower,
      ).animate(CurvedAnimation(parent: _powerAnimationController, curve: Curves.easeInOut));
      _powerAnimationController.reset();
      _powerAnimationController.forward();
      _previousPower = newPower;
    }
    
    // Update voltage animation if value changed
    if ((newVoltage - _previousVoltage).abs() > 0.01) {
      _voltageAnimation = Tween<double>(
        begin: _previousVoltage,
        end: newVoltage,
      ).animate(CurvedAnimation(parent: _voltageAnimationController, curve: Curves.easeInOut));
      _voltageAnimationController.reset();
      _voltageAnimationController.forward();
      _previousVoltage = newVoltage;
    }
    
    // Update current animation if value changed
    if ((newCurrent - _previousCurrent).abs() > 0.1) {
      _currentAnimation = Tween<double>(
        begin: _previousCurrent,
        end: newCurrent,
      ).animate(CurvedAnimation(parent: _currentAnimationController, curve: Curves.easeInOut));
      _currentAnimationController.reset();
      _currentAnimationController.forward();
      _previousCurrent = newCurrent;
    }
  }

  @override
  Widget build(BuildContext context) {
    final sensorData = widget.model.sensorData;
    final current = sensorData.current; // mA
    final voltage = sensorData.voltage; // V
    final dailyCost = widget.model.dailyCost;
    
    // Real-time device power consumption estimates with animations
    return AnimatedBuilder(
      animation: Listenable.merge([
        _powerAnimationController,
        _voltageAnimationController, 
        _currentAnimationController
      ]),
      builder: (context, child) {
        final animatedPower = _powerAnimation.value > 0 ? _powerAnimation.value : sensorData.power / 1000;
        final animatedVoltage = _voltageAnimation.value > 0 ? _voltageAnimation.value : voltage;
        final animatedCurrent = _currentAnimation.value > 0 ? _currentAnimation.value : current;
        
        final topDevices = [
          {
            'name': 'Thiết bị hiện tại', 
            'power': '${animatedPower.toStringAsFixed(1)}W'
          },
          {
            'name': 'Điện áp đo được', 
            'power': '${animatedVoltage.toStringAsFixed(2)}V'
          },
          {
            'name': 'Dòng điện đo được', 
            'power': '${animatedCurrent.toStringAsFixed(1)}mA'
          },
        ];
    
    return Container(
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
                Row(
                  children: [
                    Text(
                      'Năng lượng thực tế',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF2D3748),
                      ),
                    ),
                    SizedBox(width: 8),
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: widget.model.isMqttConnected ? Colors.green : Colors.red,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
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
                            '${animatedPower.toStringAsFixed(1)}', // Use animated value
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF2D3748),
                            ),
                          ),
                          SizedBox(width: 4),
                          Text(
                            'W hiện tại',
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
                      SizedBox(height: 2),
                      Text(
                        'Cập nhật: ${DateFormat('HH:mm:ss').format(sensorData.lastUpdated)}',
                        style: TextStyle(
                          fontSize: 10,
                          color: const Color(0xFF9E9E9E),
                          fontWeight: FontWeight.w400,
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
                        'Thông số đo được:',
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
      );
    },
    );
  }
}
