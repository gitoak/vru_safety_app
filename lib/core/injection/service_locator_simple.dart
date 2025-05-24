import 'package:get_it/get_it.dart';

// BLoCs
import '../../presentation/blocs/panic/panic_bloc.dart';
import '../../presentation/blocs/settings/settings_bloc.dart';
import '../../presentation/blocs/onboarding/onboarding_bloc.dart';
import '../../presentation/blocs/navigation/navigation_bloc.dart';

// Repositories
import '../../domain/repositories/location_repository.dart';
import '../../domain/repositories/routing_repository.dart';
import '../../domain/repositories/danger_zone_repository.dart';
import '../../data/repositories/location_repository_impl.dart';
import '../../data/repositories/routing_repository_impl.dart';
import '../../data/repositories/danger_zone_repository_impl.dart';

// Services
import '../../data/services/location_service.dart';
import '../../data/services/routing_service.dart';
import '../../data/services/danger_zone_api_service.dart';

final GetIt serviceLocator = GetIt.instance;

/// Sets up dependency injection for the application.
/// This registers all necessary services, repositories, and BLoCs.
Future<void> setupServiceLocator() async {  // Register Services as singletons
  serviceLocator.registerLazySingleton<LocationService>(() => LocationService());
  serviceLocator.registerLazySingleton<RoutingService>(() => RoutingService());
  serviceLocator.registerLazySingleton<DangerZoneApiService>(() => DangerZoneApiService());

  // Register Repositories as singletons
  serviceLocator.registerLazySingleton<LocationRepository>(
    () => LocationRepositoryImpl(locationService: serviceLocator()),
  );
  serviceLocator.registerLazySingleton<RoutingRepository>(
    () => RoutingRepositoryImpl(routingService: serviceLocator()),
  );  serviceLocator.registerLazySingleton<DangerZoneRepository>(
    () => DangerZoneRepositoryImpl(apiService: serviceLocator()),
  );

  // Register BLoCs as factories (new instance each time)
  serviceLocator.registerFactory<PanicBloc>(() => PanicBloc());
  serviceLocator.registerFactory<SettingsBloc>(() => SettingsBloc());
  serviceLocator.registerFactory<OnboardingBloc>(() => OnboardingBloc());
  serviceLocator.registerFactory<NavigationBloc>(
    () => NavigationBloc(
      locationRepository: serviceLocator(),
      routingRepository: serviceLocator(),
      dangerZoneRepository: serviceLocator(),
    ),
  );
}

/// Resets the service locator (useful for testing).
void resetServiceLocator() {
  serviceLocator.reset();
}
