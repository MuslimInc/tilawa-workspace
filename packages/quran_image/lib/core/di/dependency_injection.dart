import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/data.dart';
import '../../domain/domain.dart';

/// Global service locator instance.
final GetIt sl = GetIt.instance;

/// Initialises the dependency injection container.
///
/// Registers all repositories and use cases as lazy singletons.
/// Must be called before running the app.
Future<void> initDependencies() async {
  // Persistence
  sl.registerLazySingleton<SharedPreferencesAsync>(SharedPreferencesAsync.new);

  // Repositories
  sl.registerLazySingleton<PageRepository>(
    InMemoryPageRepository.new,
    dispose: (repo) => (repo as InMemoryPageRepository).dispose(),
  );

  sl.registerLazySingleton<NavigationVisibilityRepository>(
    InMemoryNavigationVisibilityRepository.new,
    dispose: (repo) =>
        (repo as InMemoryNavigationVisibilityRepository).dispose(),
  );

  sl.registerLazySingleton<LastVisitedPageRepository>(
    () => SharedPreferencesLastVisitedPageRepository(
      sl<SharedPreferencesAsync>(),
    ),
  );

  // Verse Marker Repository
  sl.registerLazySingleton<AssetVerseMarkerRepository>(
    AssetVerseMarkerRepository.new,
    dispose: (repo) => repo.dispose(),
  );
  sl.registerLazySingleton<VerseMarkerRepository>(
    () => sl<AssetVerseMarkerRepository>(),
  );

  // Surah Header Repository
  sl.registerLazySingleton<SurahHeaderRepository>(
    StaticSurahHeaderRepository.new,
  );

  // Quran Image Cache Repository
  sl.registerLazySingleton<QuranImageCacheRepository>(
    CloudflareQuranImageCacheRepository.new,
  );

  sl.registerLazySingleton<DecodedQuranImageCache>(
    FlutterDecodedQuranImageCache.new,
  );

  sl.registerFactory<QuranImagePrewarmer>(
    () => QuranImagePrewarmService(
      imageCacheRepository: sl<QuranImageCacheRepository>(),
      decodedImageCache: sl<DecodedQuranImageCache>(),
    ),
  );

  // Use Cases
  sl.registerLazySingleton<GetLastVisitedPageUseCase>(
    () => GetLastVisitedPageUseCase(sl<LastVisitedPageRepository>()),
  );

  sl.registerLazySingleton<PrepareQuranImageCacheUseCase>(
    () => PrepareQuranImageCacheUseCase(sl<QuranImageCacheRepository>()),
  );

  sl.registerLazySingleton<SaveLastVisitedPageUseCase>(
    () => SaveLastVisitedPageUseCase(sl<LastVisitedPageRepository>()),
  );
}
