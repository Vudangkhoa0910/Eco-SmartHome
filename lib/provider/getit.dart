import 'package:smart_home/service/navigation_service.dart';
import 'package:smart_home/service/weather_service.dart';
import 'package:smart_home/service/mqtt_service.dart';
import 'package:smart_home/service/firebase_data_service.dart';
import 'package:smart_home/service/electricity_bill_service.dart';
import 'package:smart_home/service/zone_management_service.dart';
import 'package:smart_home/view/home_screen_view_model.dart';
import 'package:smart_home/view/smart_ac_view_model.dart';
import 'package:smart_home/view/smart_light_view_model.dart';
import 'package:smart_home/view/smart_speaker_view_model.dart';
import 'package:smart_home/view/smart_fan_view_model.dart';
import 'package:smart_home/view/smart_tv_view_model.dart';
import 'package:smart_home/view/rooms_view_model.dart';
import 'package:smart_home/view/ai_voice_view_model.dart';
import 'package:smart_home/view/analytics_view_model.dart';
import 'package:smart_home/view/profile_view_model.dart';
import 'package:get_it/get_it.dart';

GetIt getIt = GetIt.instance;
void setupLocator() {
  // Services
  getIt.registerLazySingleton(() => NavigationService());
  getIt.registerLazySingleton(() => WeatherService());
  getIt.registerLazySingleton(() => MqttService());
  getIt.registerLazySingleton(() => FirebaseDataService());
  getIt.registerLazySingleton(() => ElectricityBillService());
  getIt.registerLazySingleton(() => ZoneManagementService());
  
  // ViewModels
  getIt.registerFactory(() => HomeScreenViewModel());
  getIt.registerFactory(() => SmartLightViewModel());
  getIt.registerFactory(() => SmartACViewModel());
  getIt.registerFactory(() => SmartSpeakerViewModel());
  getIt.registerFactory(() => SmartFanViewModel());
  getIt.registerFactory(() => SmartTvViewModel());
  getIt.registerFactory(() => RoomsViewModel());
  getIt.registerFactory(() => AIVoiceViewModel());
  getIt.registerFactory(() => AnalyticsViewModel());
  getIt.registerFactory(() => ProfileViewModel());
}
