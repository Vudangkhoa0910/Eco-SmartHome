import 'package:smart_home/service/navigation_service.dart';
import 'package:smart_home/service/weather_service.dart';
import 'package:smart_home/service/mqtt_unified_service.dart';
import 'package:smart_home/service/firebase_data_service.dart';
import 'package:smart_home/service/electricity_bill_service.dart';
import 'package:smart_home/service/zone_management_service.dart';
import 'package:smart_home/service/device_state_service.dart';
import 'package:smart_home/service/schedule_service.dart';
import 'package:smart_home/view/home_screen_view_model.dart';
import 'package:smart_home/view/rooms_view_model.dart';
import 'package:smart_home/view/ai_voice_view_model.dart';
import 'package:smart_home/view/analytics_view_model.dart';
import 'package:smart_home/view/profile_view_model.dart';
import 'package:get_it/get_it.dart';

GetIt getIt = GetIt.instance;

void setupLocator() {
  try {
    // Clear any existing registrations
    if (getIt.isRegistered<DeviceStateService>()) {
      getIt.unregister<DeviceStateService>();
    }

    // Services - Register as singletons to ensure single instance
    getIt.registerLazySingleton<NavigationService>(() => NavigationService());
    getIt.registerLazySingleton<WeatherService>(() => WeatherService());
    getIt.registerLazySingleton<MqttUnifiedService>(() => MqttUnifiedService());
    getIt.registerLazySingleton<FirebaseDataService>(
        () => FirebaseDataService());
    getIt.registerLazySingleton<ElectricityBillService>(
        () => ElectricityBillService());
    getIt.registerLazySingleton<ZoneManagementService>(
        () => ZoneManagementService());
    getIt.registerSingleton<ScheduleService>(ScheduleService.instance);

    // Register DeviceStateService with explicit singleton
    getIt.registerSingleton<DeviceStateService>(DeviceStateService());

    // ViewModels
    getIt.registerLazySingleton<HomeScreenViewModel>(
        () => HomeScreenViewModel());
    getIt.registerFactory<RoomsViewModel>(() => RoomsViewModel());
    getIt.registerFactory<AIVoiceViewModel>(() => AIVoiceViewModel());
    getIt.registerFactory<AnalyticsViewModel>(() => AnalyticsViewModel());
    getIt.registerFactory<ProfileViewModel>(() => ProfileViewModel());

    print(
        '✅ GetIt services registered successfully with MqttUnifiedService, DeviceStateService and ScheduleService');
    print(
        '✅ DeviceStateService registered: ${getIt.isRegistered<DeviceStateService>()}');
    print(
        '✅ ScheduleService registered: ${getIt.isRegistered<ScheduleService>()}');
  } catch (e) {
    print('❌ Error setting up locator: $e');
  }
}
