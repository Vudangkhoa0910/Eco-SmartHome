import 'dart:convert';
import 'package:http/http.dart' as http;

class WeatherService {
  static const String _apiKey = '2933a7cd16eb46da94f344c950b227c7';
  static const String _baseUrl = 'https://api.openweathermap.org/data/2.5';
  
  // Hà Đông, Hà Nội coordinates
  static const double _latitude = 20.9725;
  static const double _longitude = 105.7879;

  Future<WeatherData?> getCurrentWeather() async {
    try {
      final url = Uri.parse(
        '$_baseUrl/weather?lat=$_latitude&lon=$_longitude&appid=$_apiKey&units=metric&lang=vi'
      );
      
      final response = await http.get(url);
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return WeatherData.fromJson(data);
      } else {
        print('Weather API error: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Weather service error: $e');
      return null;
    }
  }

  Future<List<ForecastData>> getForecast() async {
    try {
      final url = Uri.parse(
        '$_baseUrl/forecast?lat=$_latitude&lon=$_longitude&appid=$_apiKey&units=metric&lang=vi&cnt=5'
      );
      
      final response = await http.get(url);
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List forecasts = data['list'];
        return forecasts.map((item) => ForecastData.fromJson(item)).toList();
      } else {
        print('Forecast API error: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('Forecast service error: $e');
      return [];
    }
  }
}

class WeatherData {
  final String location;
  final double temperature;
  final String description;
  final String icon;
  final int humidity;
  final double windSpeed;
  final int pressure;
  final DateTime dateTime;
  final String main;
  
  // Added missing properties that are being referenced
  final String condition;
  final double maxTemp;
  final double minTemp;
  final String locationName;
  final String iconUrl;

  WeatherData({
    required this.location,
    required this.temperature,
    required this.description,
    required this.icon,
    required this.humidity,
    required this.windSpeed,
    required this.pressure,
    required this.dateTime,
    this.main = '',
    this.condition = '',
    this.maxTemp = 0.0,
    this.minTemp = 0.0,
    this.locationName = '',
    this.iconUrl = '',
  });

  factory WeatherData.fromJson(Map<String, dynamic> json) {
    return WeatherData(
      location: json['name'] ?? 'Hà Đông, Hà Nội',
      temperature: (json['main']['temp'] as num).toDouble(),
      description: json['weather'][0]['description'] ?? '',
      icon: json['weather'][0]['icon'] ?? '01d',
      humidity: json['main']['humidity'] ?? 0,
      windSpeed: (json['wind']['speed'] as num?)?.toDouble() ?? 0.0,
      pressure: json['main']['pressure'] ?? 0,
      dateTime: DateTime.now(),
      main: json['weather'][0]['main'] ?? '',
      condition: json['weather'][0]['description'] ?? '',
      maxTemp: (json['main']['temp_max'] as num?)?.toDouble() ?? 0.0,
      minTemp: (json['main']['temp_min'] as num?)?.toDouble() ?? 0.0,
      locationName: json['name'] ?? '',
      iconUrl: 'https://openweathermap.org/img/wn/${json['weather'][0]['icon']}@2x.png',
    );
  }

  // Default weather data for offline mode
  static WeatherData get defaultData => WeatherData(
    location: 'Hà Đông, Hà Nội',
    temperature: 28.0,
    description: 'Thời tiết đẹp',
    icon: '01d',
    humidity: 65,
    windSpeed: 2.5,
    pressure: 1013,
    dateTime: DateTime.now(),
    main: 'Clear',
    condition: 'Thời tiết đẹp',
    maxTemp: 30.0,
    minTemp: 25.0,
    locationName: 'Hà Đông, Hà Nội',
    iconUrl: 'https://openweathermap.org/img/wn/01d@2x.png',
  );
}

class ForecastData {
  final DateTime dateTime;
  final double temperature;
  final String description;
  final String icon;

  ForecastData({
    required this.dateTime,
    required this.temperature,
    required this.description,
    required this.icon,
  });

  factory ForecastData.fromJson(Map<String, dynamic> json) {
    return ForecastData(
      dateTime: DateTime.fromMillisecondsSinceEpoch(json['dt'] * 1000),
      temperature: (json['main']['temp'] as num).toDouble(),
      description: json['weather'][0]['description'] ?? '',
      icon: json['weather'][0]['icon'] ?? '01d',
    );
  }
}
