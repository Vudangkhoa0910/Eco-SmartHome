import 'package:smart_home/config/size_config.dart';
import 'package:smart_home/view/home_screen_view_model.dart';
import 'package:flutter/material.dart';

class WeatherContainer extends StatelessWidget {
  const WeatherContainer({Key? key, required this.model, this.isCompact = false}) : super(key: key);

  final HomeScreenViewModel model;
  final bool isCompact;

  @override
  Widget build(BuildContext context) {
    final weather = model.currentWeather;
    final isLoading = model.isLoadingWeather;
    
    return Container(
      height: isCompact ? getProportionateScreenHeight(80) : getProportionateScreenHeight(140),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(isCompact ? 12 : 20),
        gradient: const LinearGradient(
          colors: [Color(0xFF6B73FF), Color(0xFF9C88FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6B73FF).withValues(alpha: 0.3),
            blurRadius: isCompact ? 10 : 25,
            offset: Offset(0, isCompact ? 4.0 : 8.0),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Stack(
        children: [
          // Background pattern
          Positioned(
            top: -20,
            right: -20,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.1),
              ),
            ),
          ),
          Positioned(
            bottom: -30,
            right: 20,
            child: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.05),
              ),
            ),
          ),
          
          // Content
          Padding(
            padding: EdgeInsets.all(getProportionateScreenWidth(isCompact ? 8 : 16)),
            child: isCompact ? 
              // Compact layout
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Hà Đông',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 9,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        SizedBox(height: 2),
                        if (isLoading)
                          SizedBox(
                            height: 16,
                            width: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        else
                          Text(
                            '${weather.temperature.round()}°C',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (!isLoading)
                    Icon(
                      Icons.wb_sunny_outlined,
                      color: Colors.white.withOpacity(0.8),
                      size: 24,
                    ),
                ],
              ) :
              // Full layout  
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          weather.location.isEmpty ? 'Hà Đông, Hà Nội' : weather.location,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                        const SizedBox(height: 4),
                        if (isLoading)
                          const CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          )
                        else
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${weather.temperature.round()}°',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 36,
                                  fontWeight: FontWeight.w700,
                                  height: 1.0,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  'C',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.8),
                                    fontSize: 16,
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        const SizedBox(height: 4),
                        Text(
                          weather.description.isEmpty ? 'Thời tiết đẹp' : weather.description,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 12,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.water_drop_outlined,
                                  color: Colors.white.withOpacity(0.8),
                                  size: 12,
                                ),
                                const SizedBox(width: 2),
                                Text(
                                  '${weather.humidity}%',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.8),
                                    fontSize: 10,
                                  ),
                                ),
                              ],
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.air,
                                  color: Colors.white.withOpacity(0.8),
                                  size: 12,
                                ),
                                const SizedBox(width: 2),
                                Text(
                                  '${weather.windSpeed.toStringAsFixed(0)}km/h',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.8),
                                    fontSize: 10,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  
                  Expanded(
                    flex: 1,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (!isLoading)
                          Icon(
                            _getWeatherIcon(weather.icon),
                            size: 48,
                            color: Colors.white,
                          ),
                        const SizedBox(height: 8),
                        // MQTT Connection Status
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: getProportionateScreenWidth(6),
                            vertical: getProportionateScreenHeight(2),
                          ),
                          decoration: BoxDecoration(
                            color: model.isMqttConnected 
                              ? Colors.green.withOpacity(0.2)
                              : Colors.red.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: model.isMqttConnected ? Colors.green : Colors.red,
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 4,
                                height: 4,
                                decoration: BoxDecoration(
                                  color: model.isMqttConnected ? Colors.green : Colors.red,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 3),
                              Text(
                                model.isMqttConnected ? 'IoT' : 'Off',
                                style: TextStyle(
                                  color: model.isMqttConnected ? Colors.green : Colors.red,
                                  fontSize: 8,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
          ),
        ],
      ),
    );
  }

  IconData _getWeatherIcon(String iconCode) {
    switch (iconCode) {
      case '01d':
      case '01n':
        return Icons.wb_sunny;
      case '02d':
      case '02n':
      case '03d':
      case '03n':
        return Icons.wb_cloudy;
      case '04d':
      case '04n':
        return Icons.cloud;
      case '09d':
      case '09n':
      case '10d':
      case '10n':
        return Icons.grain;
      case '11d':
      case '11n':
        return Icons.flash_on;
      case '13d':
      case '13n':
        return Icons.ac_unit;
      case '50d':
      case '50n':
        return Icons.blur_on;
      default:
        return Icons.wb_sunny;
    }
  }
}
