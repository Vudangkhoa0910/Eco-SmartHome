import 'package:smart_home/config/size_config.dart';
import 'package:smart_home/src/screens/home_screen/components/weather_container.dart';
import 'package:smart_home/src/screens/home_screen/components/sensor_data_container.dart';
import 'package:smart_home/src/screens/home_screen/components/energy_overview_widget.dart';
import 'package:smart_home/src/screens/set_event_screen/set_event_screen.dart';
import 'package:smart_home/view/home_screen_view_model.dart';
import 'package:flutter/material.dart';

import 'add_device_widget.dart';
import 'dark_container.dart';

class Body extends StatelessWidget {
  final HomeScreenViewModel model;
  const Body({Key? key, required this.model}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: getProportionateScreenWidth(7),
          vertical: getProportionateScreenHeight(7),
        ),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
        ),
        child: Column(
          children: [
            // Compact Environmental Data Row - Đầu tiên
            Container(
              margin: EdgeInsets.only(
                left: getProportionateScreenWidth(8),
                right: getProportionateScreenWidth(8),
                bottom: getProportionateScreenHeight(8),
              ),
              child: Row(
                children: [
                  // Compact Weather
                  Expanded(
                    flex: 1,
                    child: Container(
                      height: getProportionateScreenHeight(60),
                      child: WeatherContainer(model: model, isCompact: true),
                    ),
                  ),
                  SizedBox(width: getProportionateScreenWidth(8)),
                  // Compact Sensor Data
                  Expanded(
                    flex: 1,
                    child: Container(
                      height: getProportionateScreenHeight(60),
                      child: SensorDataContainer(model: model, isCompact: true),
                    ),
                  ),
                ],
              ),
            ),
            
            // Quick Controls Section - Thứ hai
            Container(
              margin: EdgeInsets.symmetric(
                horizontal: getProportionateScreenWidth(8),
                vertical: getProportionateScreenHeight(5),
              ),
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Điều khiển nhanh',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF2D3748),
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: getProportionateScreenWidth(8),
                          vertical: getProportionateScreenHeight(4),
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? const Color(0xFF6B73FF).withOpacity(0.2)
                              : const Color(0xFF6B73FF).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '4 thiết bị',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF6B73FF),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: getProportionateScreenHeight(12)),
                  // Main Device Controls - Compact Grid
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: getProportionateScreenHeight(105),
                          child: DarkContainer(
                            itsOn: model.isLightOn,
                            switchButton: model.lightSwitch,
                            onTap: () {
                              // Navigation removed - functionality disabled
                            },
                            iconAsset: 'assets/icons/svg/light.svg',
                            device: 'Đèn',
                            deviceCount: '4 bóng',
                            switchFav: model.lightFav,
                            isFav: model.isLightFav,
                          ),
                        ),
                      ),
                      SizedBox(width: getProportionateScreenWidth(8)),
                      Expanded(
                        child: Container(
                          height: getProportionateScreenHeight(105),
                          child: DarkContainer(
                            itsOn: model.isACON,
                            switchButton: model.acSwitch,
                            onTap: () {
                              // Navigation removed - functionality disabled
                            },
                            iconAsset: 'assets/icons/svg/ac.svg',
                            device: 'Điều hòa',
                            deviceCount: '4 thiết bị',
                            switchFav: model.acFav,
                            isFav: model.isACFav,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: getProportionateScreenHeight(8)),
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: getProportionateScreenHeight(105),
                          child: DarkContainer(
                            itsOn: model.isSpeakerON,
                            switchButton: model.speakerSwitch,
                            onTap: () {
                              // Navigation removed - functionality disabled
                            },
                            iconAsset: 'assets/icons/svg/speaker.svg',
                            device: 'Loa',
                            deviceCount: '1 thiết bị',
                            switchFav: model.speakerFav,
                            isFav: model.isSpeakerFav,
                          ),
                        ),
                      ),
                      SizedBox(width: getProportionateScreenWidth(8)),
                      Expanded(
                        child: Container(
                          height: getProportionateScreenHeight(105),
                          child: DarkContainer(
                            itsOn: model.isFanON,
                            switchButton: model.fanSwitch,
                            onTap: () {
                              // Navigation removed - functionality disabled
                            },
                            iconAsset: 'assets/icons/svg/fan.svg',
                            device: 'Quạt',
                            deviceCount: '2 thiết bị',
                            switchFav: model.fanFav,
                            isFav: model.isFanFav,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            // Add New Device - Prominent position
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: getProportionateScreenWidth(8),
                vertical: getProportionateScreenHeight(4),
              ),
              child: const AddNewDevice(),
            ),
            
            // Energy Overview - New widget
            Container(
              margin: EdgeInsets.symmetric(
                horizontal: getProportionateScreenWidth(8),
                vertical: getProportionateScreenHeight(4),
              ),
              child: EnergyOverviewWidget(model: model),
            ),
            
            // Navigation Buttons
            Container(
              margin: EdgeInsets.symmetric(
                horizontal: getProportionateScreenWidth(8),
                vertical: getProportionateScreenHeight(8),
              ),
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: getProportionateScreenHeight(45),
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.of(context).pushNamed(SetEventScreen.routeName);
                      },
                      icon: const Icon(Icons.schedule, color: Colors.white, size: 18),
                      label: const Text(
                        'Thiết lập sự kiện',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6B73FF),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: getProportionateScreenHeight(8)),
                  SizedBox(
                    width: double.infinity,
                    height: getProportionateScreenHeight(45),
                    child: ElevatedButton.icon(
                      onPressed: () {
                        // Navigation removed - functionality disabled
                      },
                      icon: const Icon(Icons.tv, color: Colors.white, size: 18),
                      label: const Text(
                        'Smart TV',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4CAF50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
