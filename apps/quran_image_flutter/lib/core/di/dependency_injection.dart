import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/data.dart';
import '../../domain/domain.dart';

/// Global service locator instance
final GetIt sl = GetIt.instance;

/// Initializes the dependency injection container.
///
/// Registers all repositories and use cases as lazy singletons.
/// Must be called before running the app.
Future<void> initDependencies() async {
  // Persistence
  sl.registerLazySingleton<SharedPreferencesAsync>(() => SharedPreferencesAsync());

  // Repositories
  sl.registerLazySingleton<PageRepository>(() => InMemoryPageRepository());

  sl.registerLazySingleton<NavigationVisibilityRepository>(
    () => InMemoryNavigationVisibilityRepository(),
  );

  sl.registerLazySingleton<LastVisitedPageRepository>(
    () => SharedPreferencesLastVisitedPageRepository(sl<SharedPreferencesAsync>()),
  );

  // Use Cases
  sl.registerLazySingleton<GetLastVisitedPageUseCase>(
    () => GetLastVisitedPageUseCase(sl<LastVisitedPageRepository>()),
  );

  sl.registerLazySingleton<SaveLastVisitedPageUseCase>(
    () => SaveLastVisitedPageUseCase(sl<LastVisitedPageRepository>()),
  );
}
