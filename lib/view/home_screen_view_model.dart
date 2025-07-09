import 'dart:math';
import 'dart:async';

import 'package:smart_home/provider/base_model.dart';
import 'package:smart_home/provider/getit.dart';
import 'package:smart_home/service/weather_service.dart';
import 'package:smart_home/service/mqtt_service.dart';
import 'package:smart_home/service/electricity_bill_service.dart';
import 'package:smart_home/service/zone_management_service.dart';
import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';

class HomeScreenViewModel extends BaseModel {
  //-------------SERVICES-------------//
  final WeatherService _weatherService = getIt<WeatherService>();
  final MqttService _mqttService = getIt<MqttService>();
  final ElectricityBillService _billService = getIt<ElectricityBillService>();
  final ZoneManagementService _zoneService = getIt<ZoneManagementService>();
  
  //-------------VARIABLES-------------//
  String _userName = 'Khoa'; // Default name
  int selectedIndex = 0;
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
  
  // Getters
  String get userName => _userName;
  WeatherData get currentWeather => _currentWeather ?? WeatherData.defaultData;
  List<ForecastData> get forecast => _forecast;
  bool get isLoadingWeather => _isLoadingWeather;
  SensorData get sensorData => _sensorData;
  bool get isMqttConnected => _isMqttConnected;
  String get currentTime => DateFormat('HH:mm').format(DateTime.now());
  Map<String, double> get electricityEstimation => _electricityEstimation;
  double get dailyCost => _dailyCost;
  double get monthlyCost => _monthlyCost;
  ElectricityBillService get billService => _billService;
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
    
    // Initialize zone management service
    _zoneService.initialize(_mqttService);
    
    await _loadWeatherData();
    await _connectMqtt();
    _setupMqttListeners();
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
    
    _connectionSubscription = _mqttService.connectionStream.listen((isConnected) {
      print('🔄 MQTT Connection Status Updated: $isConnected');
      _isMqttConnected = isConnected;
      notifyListeners();
    });
    
    // Force update UI after setup
    notifyListeners();
  }
  
  void _updateElectricityCalculation() {
    try {
      _electricityEstimation = _billService.getUsageEstimation(_sensorData.power);
      _dailyCost = _electricityEstimation['daily_cost'] ?? 0.0;
      _monthlyCost = _electricityEstimation['monthly_cost'] ?? 0.0;
    } catch (e) {
      print('Error calculating electricity: $e');
    }
  }
  
  // Device control methods (now connected to MQTT)
  void lightFav(){
    isLightFav = !isLightFav;
    notifyListeners();
  }
  void acFav(){
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
    _mqttService.controlMotor(isFanON ? 'ON' : 'OFF');
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
    isFanON = !isFanON;
    _mqttService.controlMotor(isFanON ? "FORWARD" : "OFF");
    notifyListeners();
  }
  
  void controlLed2(bool isOn) {
    _mqttService.controlLedAround(isOn);
  }

  ///On tapping bottom nav bar items
  void onItemTapped(int index) {
    selectedIndex = index;
    pageController.animateToPage(index,
        duration: const Duration(milliseconds: 500), curve: Curves.easeOut);
    notifyListeners();
  }
  
  // Refresh methods
  Future<void> refreshWeather() async {
    await _loadWeatherData();
  }
  
  void reconnectMqtt() {
    _connectMqtt();
  }
}
