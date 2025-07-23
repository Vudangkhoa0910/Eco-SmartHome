import 'dart:math';
import 'dart:async';

import 'package:smart_home/provider/base_model.dart';
import 'package:smart_home/provider/getit.dart';
import 'package:smart_home/service/weather_service.dart';
import 'package:smart_home/service/mqtt_unified_service.dart';
import 'package:smart_home/service/electricity_bill_service.dart';
import 'package:smart_home/service/zone_management_service.dart';
import 'package:smart_home/service/gate_state_service.dart';
import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class HomeScreenViewModel extends BaseModel {
  //-------------SERVICES-------------//
  final WeatherService _weatherService = getIt<WeatherService>();
  final MqttUnifiedService _mqttService = getIt<MqttUnifiedService>();
  final ElectricityBillService _billService = getIt<ElectricityBillService>();
  final ZoneManagementService _zoneService = getIt<ZoneManagementService>();
  final GateStateService _gateService = GateStateService();

  //-------------VARIABLES-------------//
  String _userName = 'Đang tải...'; // Default name while loading
  int _selectedIndex = 0;
  int randomNumber = 1;
  final PageController pageController = PageController();
  bool isLightOn = true;
  bool isACON = false;
  bool isSpeakerON = false;
  bool isFanON = false;
  bool isLightFav = false;
  bool isACFav = false;
  bool isSpeakerFav = false;
  bool isFanFav = false;

  // Indoor device states for ESP32-S3
  // Floor 1 devices
  bool isKitchenLightOn = false;
  bool isLivingRoomLightOn = false;
  bool isBedroomLightOn = false;
  
  // Floor 2 devices
  bool isCornerBedroomLightOn = false;
  bool isYardBedroomLightOn = false;
  bool isWorshipRoomLightOn = false;
  bool isHallwayLightOn = false;
  bool isBalconyLightOn = false;

  // Quạt và điều hòa states
  bool isFanLivingRoomOn = false;        // Quạt tầng 1 phòng khách
  bool isACLivingRoomOn = false;         // Điều hòa tầng 1 phòng khách
  bool isACBedroom1On = false;           // Điều hòa tầng 2 phòng ngủ 1
  bool isACBedroom2On = false;           // Điều hòa tầng 2 phòng ngủ 2

  // Gate state management
  int _currentGateLevel = 0;
  bool _isGateMoving = false;
  String _gateStatusText = 'Đang tải...';
  StreamSubscription? _gateStatusSubscription;
  StreamSubscription? _indoorDeviceStatusSubscription;

  // Weather data
  WeatherData? _currentWeather;
  List<ForecastData> _forecast = [];
  bool _isLoadingWeather = false;

  // MQTT data
  SensorData _sensorData = SensorData.defaultData();
  bool _isMqttConnected = false;
  StreamSubscription? _sensorSubscription;
  StreamSubscription? _connectionSubscription;

  // Electricity calculation
  Map<String, double> _electricityEstimation = {};
  double _dailyCost = 0.0;
  double _monthlyCost = 0.0;

  // Constructor - Load user data immediately
  HomeScreenViewModel() {
    _loadUserData();
    _initializeGateState();
  }

  // Getters
  String get userName => _userName;
  int get selectedIndex => _selectedIndex;
  set selectedIndex(int value) {
    _selectedIndex = value;
    notifyListeners();
  }

  WeatherData get currentWeather => _currentWeather ?? WeatherData.defaultData;
  List<ForecastData> get forecast => _forecast;
  bool get isLoadingWeather => _isLoadingWeather;
  SensorData get sensorData => _sensorData;
  bool get isMqttConnected => _isMqttConnected;
  String get currentTime => DateFormat('HH:mm').format(DateTime.now());
  Map<String, double> get electricityEstimation => _electricityEstimation;
  double get dailyCost => _dailyCost;
  double get monthlyCost => _monthlyCost;

  // Gate state getters
  int get currentGateLevel => _currentGateLevel;
  bool get isGateMoving => _isGateMoving;
  String get gateStatusText => _gateStatusText;
  ElectricityBillService get billService => _billService;
  MqttUnifiedService get mqttServiceSimple => _mqttService; // Compatibility getter
  String get currentDate {
    try {
      // Sử dụng locale en_US đã được initialize
      return DateFormat('dd/MM/yyyy - EEEE', 'en_US').format(DateTime.now());
    } catch (e) {
      // Fallback không có locale
      try {
        return DateFormat('dd/MM/yyyy - EEEE').format(DateTime.now());
      } catch (e2) {
        // Fallback cuối cùng với format đơn giản
        return DateFormat('dd/MM/yyyy').format(DateTime.now());
      }
    }
  }

  @override
  void dispose() {
    _sensorSubscription?.cancel();
    _connectionSubscription?.cancel();
    _gateStatusSubscription?.cancel();
    _indoorDeviceStatusSubscription?.cancel();
    super.dispose();
  }

  void generateRandomNumber() {
    randomNumber = Random().nextInt(8);
    notifyListeners();
  }

  Future<void> initializeServices() async {
    // Initialize date formatting
    try {
      await initializeDateFormatting('en_US', null);
    } catch (e) {
      print('Failed to initialize date formatting: $e');
    }

    // Load user data from Firebase
    await _loadUserData();

    // Initialize zone management service
    _zoneService.initialize(_mqttService);

    await _loadWeatherData();
    await _connectMqtt();
    _setupMqttListeners();
  }

  /// Load user data from Firebase
  Future<void> _loadUserData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // Load user document from Firestore
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (userDoc.exists) {
          final userData = userDoc.data() as Map<String, dynamic>;
          _userName = userData['displayName'] ??
              user.displayName ??
              userData['name'] ??
              'Người dùng';
        } else {
          // If no document exists, use Firebase Auth data
          _userName = user.displayName ?? 'Người dùng';
        }
      } else {
        // No user logged in
        _userName = 'Chưa đăng nhập';
      }
    } catch (e) {
      print('Error loading user data: $e');
      // Keep default loading message if error occurs
      _userName = 'Lỗi tải dữ liệu';
    }

    notifyListeners();
  }

  Future<void> _loadWeatherData() async {
    _isLoadingWeather = true;
    notifyListeners();

    try {
      final weather = await _weatherService.getCurrentWeather();
      final forecasts = await _weatherService.getForecast();

      if (weather != null) {
        _currentWeather = weather;
      }
      _forecast = forecasts;
    } catch (e) {
      print('Error loading weather: $e');
      // Keep default values
    } finally {
      _isLoadingWeather = false;
      notifyListeners();
    }
  }

  Future<void> _connectMqtt() async {
    try {
      await _mqttService.connect();
    } catch (e) {
      print('Error connecting MQTT: $e');
    }
  }

  void _setupMqttListeners() {
    // Set initial connection status from service
    _isMqttConnected = _mqttService.isConnected;

    _sensorSubscription = _mqttService.sensorDataStream.listen((data) {
      _sensorData = data;
      // If we're receiving sensor data, we're definitely connected
      if (!_isMqttConnected) {
        _isMqttConnected = true;
        print('🔄 MQTT Connection Status Updated via sensor data: true');
      }
      _updateElectricityCalculation();
      notifyListeners();
    });

    _connectionSubscription =
        _mqttService.connectionStream.listen((isConnected) {
      print('🔄 MQTT Connection Status Updated: $isConnected');
      _isMqttConnected = isConnected;
      notifyListeners();
    });

    // Listen to indoor device status from ESP32-S3
    _indoorDeviceStatusSubscription = 
        _mqttService.indoorDeviceStatusStream.listen((deviceStates) {
      _updateIndoorDeviceStates(deviceStates);
    });

    // Listen to device state changes for UI synchronization
    _mqttService.deviceStateStream.listen((deviceStates) {
      _synchronizeDeviceStates(deviceStates);
    });

    // Force update UI after setup
    notifyListeners();
  }

  void _updateElectricityCalculation() {
    try {
      _electricityEstimation =
          _billService.getUsageEstimation(_sensorData.power);
      _dailyCost = _electricityEstimation['daily_cost'] ?? 0.0;
      _monthlyCost = _electricityEstimation['monthly_cost'] ?? 0.0;
    } catch (e) {
      print('Error calculating electricity: $e');
    }
  }

  void _updateIndoorDeviceStates(Map<String, bool> deviceStates) {
    try {
      // Update states based on ESP32-S3 reported states
      deviceStates.forEach((deviceKey, isOn) {
        switch (deviceKey) {
          case 'kitchen_light':
            isKitchenLightOn = isOn;
            break;
          case 'living_room_light':
            isLivingRoomLightOn = isOn;
            break;
          case 'bedroom_light':
            isBedroomLightOn = isOn;
            break;
          case 'corner_bedroom_light':
            isCornerBedroomLightOn = isOn;
            break;
          case 'yard_bedroom_light':
            isYardBedroomLightOn = isOn;
            break;
          case 'worship_room_light':
            isWorshipRoomLightOn = isOn;
            break;
          case 'hallway_light':
            isHallwayLightOn = isOn;
            break;
          case 'balcony_light':
            isBalconyLightOn = isOn;
            break;
          // Quạt và điều hòa
          case 'fan_living_room':
            isFanLivingRoomOn = isOn;
            break;
          case 'ac_living_room':
            isACLivingRoomOn = isOn;
            break;
          case 'ac_bedroom1':
            isACBedroom1On = isOn;
            break;
          case 'ac_bedroom2':
            isACBedroom2On = isOn;
            break;
        }
      });
      
      notifyListeners();
      print('🏠 Updated indoor device states from ESP32-S3: ${deviceStates.length} devices');
    } catch (e) {
      print('❌ Error updating indoor device states: $e');
    }
  }

  /// Synchronize UI variables with actual device states from MQTT
  void _synchronizeDeviceStates(Map<String, bool> deviceStates) {
    try {
      deviceStates.forEach((deviceKey, isOn) {
        switch (deviceKey) {
          case 'led_gate':
            isLightOn = isOn;
            break;
          case 'led_around':
            // FIXED: Sync LED Around state with isACON variable
            isACON = isOn;
            break;
          case 'yard_main_light':
            isFanON = isOn; // Fan variable used for yard main light
            break;
        }
      });
      
      notifyListeners();
      print('🔄 Synchronized device states: LED Gate=$isLightOn, LED Around=$isACON, Yard Main Light=$isFanON');
    } catch (e) {
      print('❌ Error synchronizing device states: $e');
    }
  }

  // Device control methods (now connected to MQTT)
  void lightFav() {
    isLightFav = !isLightFav;
    notifyListeners();
  }

  void acFav() {
    isACFav = !isACFav;
    notifyListeners();
  }

  void speakerFav() {
    isSpeakerFav = !isSpeakerFav;
    notifyListeners();
  }

  void fanFav() {
    isFanFav = !isFanFav;
    notifyListeners();
  }

  void acSwitch() {
    isACON = !isACON;
    // Here you could send MQTT command for AC
    notifyListeners();
  }

  void speakerSwitch() {
    isSpeakerON = !isSpeakerON;
    // Here you could send MQTT command for Speaker
    notifyListeners();
  }

  void fanSwitch() {
    isFanON = !isFanON;
    // 🔧 FIX: Sử dụng method riêng cho đèn sân chính thay vì controlMotor
    _mqttService.controlYardMainLight(isFanON);
    notifyListeners();
  }

  void lightSwitch() {
    isLightOn = !isLightOn;
    _mqttService.controlLedGate(isLightOn);
    notifyListeners();
  }

  // Control methods for LED and Motor
  void toggleLed1() {
    isLightOn = !isLightOn;
    _mqttService.controlLedGate(isLightOn);
    notifyListeners();
  }

  void toggleLed2() {
    isACON = !isACON; // Use AC variable for LED2
    _mqttService.controlLedAround(isACON);
    notifyListeners();
  }

  void toggleMotor() {
    // DEPRECATED: Use controlGateLevel() or Gate Control Widget instead
    // This method is kept for legacy UI compatibility only
    print('⚠️ toggleMotor() is deprecated - use Gate Control Widget for multi-level control');
    
    // Don't send any MQTT commands to avoid conflicts with gate_level topic
    // Just update UI state for legacy compatibility
    isFanON = !isFanON;
    notifyListeners();
    
    // Show warning to user
    print('💡 Please use the Gate Control Widget for proper gate control');
  }

  void controlLed2(bool isOn) {
    _mqttService.controlLedAround(isOn);
  }

  ///On tapping bottom nav bar items
  void onItemTapped(int index) {
    if (index == 2) {
      // AI Voice control - do nothing on tap, only handle special actions
      return;
    }

    selectedIndex = index;
    // map nav index to page index (skip AI voice at nav 2)
    final pageIndex = index > 2 ? index - 1 : index;
    // Directly jump to the page without intermediate animation to avoid overlap
    pageController.jumpToPage(pageIndex);
    notifyListeners();
  }

  // Refresh methods
  Future<void> refreshWeather() async {
    await _loadWeatherData();
  }

  void reconnectMqtt() {
    _connectMqtt();
  }

  // ========== ESP32-S3 Indoor Device Controls ==========
  
  // Floor 1 Controls
  void toggleKitchenLight() {
    isKitchenLightOn = !isKitchenLightOn;
    notifyListeners();
  }

  void toggleLivingRoomLight() {
    isLivingRoomLightOn = !isLivingRoomLightOn;
    notifyListeners();
  }

  void toggleBedroomLight() {
    isBedroomLightOn = !isBedroomLightOn;
    notifyListeners();
  }

  // Floor 2 Controls
  void toggleCornerBedroomLight() {
    isCornerBedroomLightOn = !isCornerBedroomLightOn;
    notifyListeners();
  }

  void toggleYardBedroomLight() {
    isYardBedroomLightOn = !isYardBedroomLightOn;
    notifyListeners();
  }

  void toggleWorshipRoomLight() {
    isWorshipRoomLightOn = !isWorshipRoomLightOn;
    notifyListeners();
  }

  void toggleHallwayLight() {
    isHallwayLightOn = !isHallwayLightOn;
    notifyListeners();
  }

  void toggleBalconyLight() {
    isBalconyLightOn = !isBalconyLightOn;
    notifyListeners();
  }

  // Direct control methods (for external calls)
  void setKitchenLight(bool isOn) {
    isKitchenLightOn = isOn;
    notifyListeners();
  }

  void setLivingRoomLight(bool isOn) {
    isLivingRoomLightOn = isOn;
    notifyListeners();
  }

  void setBedroomLight(bool isOn) {
    isBedroomLightOn = isOn;
    notifyListeners();
  }

  void setCornerBedroomLight(bool isOn) {
    isCornerBedroomLightOn = isOn;
    notifyListeners();
  }

  void setYardBedroomLight(bool isOn) {
    isYardBedroomLightOn = isOn;
    notifyListeners();
  }

  void setWorshipRoomLight(bool isOn) {
    isWorshipRoomLightOn = isOn;
    notifyListeners();
  }

  void setHallwayLight(bool isOn) {
    isHallwayLightOn = isOn;
    notifyListeners();
  }

  void setBalconyLight(bool isOn) {
    isBalconyLightOn = isOn;
    notifyListeners();
  }

  // ========== QUẠT VÀ ĐIỀU HÒA CONTROLS ==========
  
  // Quạt tầng 1 phòng khách
  void toggleFanLivingRoom() {
    isFanLivingRoomOn = !isFanLivingRoomOn;
    _mqttService.publishFanLivingRoomCommand(isFanLivingRoomOn ? 'ON' : 'OFF');
    notifyListeners();
  }

  void setFanLivingRoom(bool isOn) {
    isFanLivingRoomOn = isOn;
    notifyListeners();
  }

  // Điều hòa tầng 1 phòng khách
  void toggleACLivingRoom() {
    isACLivingRoomOn = !isACLivingRoomOn;
    _mqttService.publishACLivingRoomCommand(isACLivingRoomOn ? 'ON' : 'OFF');
    notifyListeners();
  }

  void setACLivingRoom(bool isOn) {
    isACLivingRoomOn = isOn;
    notifyListeners();
  }

  // Điều hòa tầng 2 phòng ngủ 1
  void toggleACBedroom1() {
    isACBedroom1On = !isACBedroom1On;
    _mqttService.publishACBedroom1Command(isACBedroom1On ? 'ON' : 'OFF');
    notifyListeners();
  }

  void setACBedroom1(bool isOn) {
    isACBedroom1On = isOn;
    notifyListeners();
  }

  // Điều hòa tầng 2 phòng ngủ 2
  void toggleACBedroom2() {
    isACBedroom2On = !isACBedroom2On;
    _mqttService.publishACBedroom2Command(isACBedroom2On ? 'ON' : 'OFF');
    notifyListeners();
  }

  void setACBedroom2(bool isOn) {
    isACBedroom2On = isOn;
    notifyListeners();
  }

  // ========== GATE STATE MANAGEMENT ==========
  
  Future<void> _initializeGateState() async {
    try {
      // Load current gate state từ Firebase
      await _loadCurrentGateState();
      
      // Listen to MQTT gate status stream
      _gateStatusSubscription = _mqttService.gateStatusStream.listen((status) {
        _currentGateLevel = status['level'] ?? 0;
        _isGateMoving = status['isMoving'] ?? false;
        _gateStatusText = _getGateDescription(_currentGateLevel);
        notifyListeners();
      });
      
      
      // Request current status từ ESP32 without sending control command
      _mqttService.publishDeviceCommand('khoasmarthome/status_request', 'GATE_STATUS');
      } catch (e) {
      print('❌ Error initializing gate state: $e');
      _gateStatusText = 'Lỗi kết nối cổng';
      notifyListeners();
    }
  }

  Future<void> _loadCurrentGateState() async {
    try {
      final currentState = await _gateService.getCurrentGateState();
      _currentGateLevel = currentState.level;
      _isGateMoving = currentState.isMoving;
      _gateStatusText = _getGateDescription(_currentGateLevel);
      notifyListeners();
    } catch (e) {
      print('❌ Error loading gate state: $e');
      _gateStatusText = 'Lỗi tải trạng thái';
      notifyListeners();
    }
  }

  String _getGateDescription(int level) {
    if (_isGateMoving) return 'Đang di chuyển...';
    
    switch (level) {
      case 0: return 'Đóng hoàn toàn';
      case 25: return 'Mở 1/4 - Người đi bộ';
      case 50: return 'Mở 1/2 - Xe máy';
      case 75: return 'Mở 3/4 - Xe hơi nhỏ';
      case 100: return 'Mở hoàn toàn - Xe tải';
      default: return 'Mở $level%';
    }
  }

  Future<void> controlGateLevel(int targetLevel) async {
    if (_isGateMoving || targetLevel == _currentGateLevel) return;
    
    try {
      _isGateMoving = true;
      _gateStatusText = 'Đang di chuyển đến $targetLevel%...';
      notifyListeners();
      
      // Send MQTT command
      await _mqttService.publishGateControl(targetLevel);
      
      // Save state to Firebase
      await _gateService.saveGateState(GateState.withAutoStatus(
        level: targetLevel,
        isMoving: true,
        timestamp: DateTime.now(),
      ));
      
      print('🚪 Gate control initiated: $targetLevel%');
    } catch (e) {
      print('❌ Error controlling gate: $e');
      _isGateMoving = false;
      _gateStatusText = 'Lỗi điều khiển cổng';
      notifyListeners();
    }
  }

  Future<void> stopGate() async {
    try {
      await _mqttService.publishGateControl(-1); // -1 = stop command
      _isGateMoving = false;
      _gateStatusText = 'Đã dừng tại $_currentGateLevel%';
      notifyListeners();
    } catch (e) {
      print('❌ Error stopping gate: $e');
    }
  }

  Future<void> refreshGateStatus() async {
    try {
      _gateStatusText = 'Đang cập nhật...';
      notifyListeners();
      
      _mqttService.publishDeviceCommand('khoasmarthome/status_request', 'GATE_STATUS');
      await _loadCurrentGateState();
    } catch (e) {
      print('❌ Error refreshing gate status: $e');
      _gateStatusText = 'Lỗi cập nhật';
      notifyListeners();
    }
  }
}
