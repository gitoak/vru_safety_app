import 'package:get_it/get_it.dart';
import 'package:vru_safety_app/data/services/vibrations_service.dart';
import 'package:vru_safety_app/presentation/blocs/danger_zone/danger_zone_bloc.dart';
import 'package:vru_safety_app/presentation/blocs/navigation/navigation_bloc.dart';

// Core services
import '../../data/services/location_service.dart';
import '../../data/services/audio_service.dart';
import '../../data/services/notification_service.dart';

// Data services
import '../../data/services/graphhopper_api_service.dart';
import '../../data/services/danger_zone_api_service.dart';
import '../../data/services/nominatim_api_service.dart';
import '../../data/services/danger_zone_service.dart';
import '../../data/services/routing_service.dart';

// Repositories
import '../../domain/repositories/danger_zone_repository.dart';
import '../../domain/repositories/routing_repository.dart';
import '../../domain/repositories/location_repository.dart';
import '../../data/repositories/danger_zone_repository_impl.dart';
import '../../data/repositories/routing_repository_impl.dart';
import '../../data/repositories/location_repository_impl.dart';

// BLoCs (only working ones for now)
import '../../presentation/blocs/panic/panic_bloc.dart';
import '../../presentation/blocs/settings/settings_bloc.dart';
import '../../presentation/blocs/onboarding/onboarding_bloc.dart';

final GetIt serviceLocator = GetIt.instance;

/// Sets up dependency injection for the application.
Future<void> setupServiceLocator() async {
  // Register core services
  serviceLocator.registerLazySingleton<LocationService>(() => LocationService());
  serviceLocator.registerLazySingleton<AudioService>(() => AudioService());
  serviceLocator.registerLazySingleton<NotificationService>(() => NotificationService());
  serviceLocator.registerLazySingleton<VibrationService>(() => VibrationService());

  // Register data services
  serviceLocator.registerLazySingleton<GraphHopperApiService>(() => GraphHopperApiService());
  serviceLocator.registerLazySingleton<DangerZoneApiService>(() => DangerZoneApiService());
  serviceLocator.registerLazySingleton<NominatimApiService>(() => NominatimApiService());
  serviceLocator.registerLazySingleton<DangerZoneService>(() => DangerZoneService(
    apiService: serviceLocator<DangerZoneApiService>(),
  ));
  serviceLocator.registerLazySingleton<RoutingService>(() => RoutingService(
    graphHopperService: serviceLocator<GraphHopperApiService>(),
  ));

  // Register repositories
  serviceLocator.registerLazySingleton<DangerZoneRepository>(() => DangerZoneRepositoryImpl(
    apiService: serviceLocator<DangerZoneApiService>(),
  ));
  serviceLocator.registerLazySingleton<RoutingRepository>(() => RoutingRepositoryImpl(
    apiService: serviceLocator<GraphHopperApiService>(),
    routingService: serviceLocator<RoutingService>(),
  ));
  serviceLocator.registerLazySingleton<LocationRepository>(() => LocationRepositoryImpl(
    locationService: serviceLocator<LocationService>(),
  ));

  // Register BLoCs as factories (new instance each time)
  serviceLocator.registerFactory<NavigationBloc>(() => NavigationBloc(
    routingRepository: serviceLocator<RoutingRepository>(),
    locationRepository: serviceLocator<LocationRepository>(),
    dangerZoneRepository: serviceLocator<DangerZoneRepository>(),
  ));
  
  serviceLocator.registerFactory<DangerZoneBloc>(() => DangerZoneBloc(
    dangerZoneRepository: serviceLocator<DangerZoneRepository>(),
    locationRepository: serviceLocator<LocationRepository>(),
  ));
  
  serviceLocator.registerFactory<PanicBloc>(() => PanicBloc(
    locationRepository: serviceLocator<LocationRepository>(),
    notificationService: serviceLocator<NotificationService>(),
    audioService: serviceLocator<AudioService>(),
    vibrationService: serviceLocator<VibrationService>(),
  ));
  
  serviceLocator.registerFactory<SettingsBloc>(() => SettingsBloc());
  
  serviceLocator.registerFactory<OnboardingBloc>(() => OnboardingBloc());
}

/// Resets the service locator (useful for testing).
void resetServiceLocator() {
  serviceLocator.reset();
}
