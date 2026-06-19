import 'package:dartz_plus/dartz_plus.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tilawa/features/athkar/domain/entities/athkar_category.dart';
import 'package:tilawa/features/athkar/domain/entities/athkar_item.dart';
import 'package:tilawa/features/athkar/domain/entities/pinned_athkar_preference.dart';
import 'package:tilawa/features/athkar/domain/repositories/athkar_repository.dart';
import 'package:tilawa/features/athkar/domain/repositories/pinned_athkar_repository.dart';
import 'package:tilawa/features/athkar/domain/usecases/get_athkar_by_category_use_case.dart';
import 'package:tilawa/features/athkar/domain/usecases/get_athkar_categories_use_case.dart';
import 'package:tilawa/features/athkar/domain/usecases/get_pinned_athkar_preference_use_case.dart';
import 'package:tilawa/features/athkar/domain/usecases/save_pinned_athkar_category_ids_use_case.dart';
import 'package:tilawa/features/athkar/presentation/cubit/athkar_cubit.dart';
import 'package:tilawa/features/athkar/presentation/cubit/pinned_athkar_cubit.dart';
import 'package:tilawa/features/auth/domain/entities/auth_result.dart';
import 'package:tilawa/features/auth/domain/entities/user_entity.dart';
import 'package:tilawa/features/auth/domain/repositories/auth_repository.dart';
import 'package:tilawa/features/auth/domain/usecases/get_current_user_use_case.dart';
import 'package:tilawa/features/home/domain/entities/home_layout_mode.dart';
import 'package:tilawa/features/home/domain/repositories/home_layout_preference_repository.dart';
import 'package:tilawa/features/home/domain/usecases/get_home_layout_mode_use_case.dart';
import 'package:tilawa/features/home/domain/usecases/set_home_layout_mode_use_case.dart';
import 'package:tilawa/features/home/presentation/cubit/home_layout_cubit.dart';
import 'package:tilawa/features/home/presentation/cubit/home_quran_resume_cubit.dart';
import 'package:tilawa/features/prayer_times/application/prayer_location_update_notifier.dart';
import 'package:tilawa/features/prayer_times/domain/entities/entities.dart';
import 'package:tilawa/features/prayer_times/domain/repositories/prayer_times_repository.dart';
import 'package:tilawa/features/prayer_times/domain/usecases/get_current_location_use_case.dart';
import 'package:tilawa/features/prayer_times/domain/usecases/get_location_name_use_case.dart';
import 'package:tilawa/features/prayer_times/domain/usecases/get_prayer_times_use_case.dart';
import 'package:tilawa/features/prayer_times/domain/usecases/load_prayer_settings_use_case.dart';
import 'package:tilawa/features/prayer_times/domain/usecases/notify_prayer_location_updated_use_case.dart';
import 'package:tilawa/features/prayer_times/domain/usecases/save_prayer_settings_use_case.dart';
import 'package:tilawa/features/qibla/presentation/bloc/qibla_bloc.dart';
import 'package:tilawa/features/quran_reader/domain/usecases/get_last_read_position_use_case.dart';
import 'package:tilawa_core/core.dart';

class _MockQiblaBloc extends Mock implements QiblaBloc {}

class _FakeAuthRepository implements AuthRepository {
  @override
  Stream<UserEntity?> get authStateChanges => const Stream.empty();

  @override
  UserEntity? get currentUser => null;

  @override
  Future<void> deleteAccount() async {}

  @override
  Future<void> prepareGoogleSignIn() async {}

  @override
  Future<AuthResult> signInWithGoogle() async => const AuthResult.cancelled();

  @override
  Future<void> signOut() async {}
}

class _FakePrayerTimesRepository implements PrayerTimesRepository {
  @override
  Future<PrayerTimeEntity> getPrayerTimes({
    required double latitude,
    required double longitude,
    required DateTime date,
    required PrayerSettingsEntity settings,
  }) async {
    return PrayerTimeEntity(
      date: date,
      fajr: DateTime(date.year, date.month, date.day, 4),
      sunrise: DateTime(date.year, date.month, date.day, 5, 30),
      dhuhr: DateTime(date.year, date.month, date.day, 12),
      asr: DateTime(date.year, date.month, date.day, 15, 30),
      maghrib: DateTime(date.year, date.month, date.day, 18, 45),
      isha: DateTime(date.year, date.month, date.day, 20, 10),
      midnight: DateTime(date.year, date.month, date.day, 23, 40),
      lastThird: DateTime(date.year, date.month, date.day, 2),
      locationName: 'Cairo',
      latitude: latitude,
      longitude: longitude,
    );
  }

  @override
  Future<String?> getLocationName({
    required double latitude,
    required double longitude,
    String? localeIdentifier,
  }) async => 'Cairo';

  @override
  Future<LocationResult> getCurrentLocation({
    bool forceRefresh = false,
    String? localeIdentifier,
  }) async {
    return LocationResult(
      latitude: 30.0444,
      longitude: 31.2357,
      locationName: 'Cairo',
      countryCode: 'EG',
    );
  }

  @override
  Future<bool> hasLocationPermission() async => false;

  @override
  Future<PrayerSettingsEntity> loadSettings() async {
    return const PrayerSettingsEntity();
  }

  @override
  Future<bool> requestLocationPermission({
    bool allowOpenSettings = false,
  }) async => false;

  @override
  Future<void> saveSettings(PrayerSettingsEntity settings) async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeAthkarRepository implements AthkarRepository {
  @override
  ResultFuture<List<AthkarCategory>> getCategories() async {
    return const Right([]);
  }

  @override
  ResultFuture<List<AthkarItem>> getAthkarByCategory(int categoryId) async {
    return const Right([]);
  }
}

class _FakePinnedAthkarRepository implements PinnedAthkarRepository {
  @override
  ResultFuture<PinnedAthkarPreference> getPreference() async {
    return const Right(
      PinnedAthkarPreference(categoryIds: [1, 2], isCustomized: false),
    );
  }

  @override
  ResultVoid saveCategoryIds(List<int> categoryIds) async {
    return const Right(null);
  }
}

/// Minimal [GetIt] registrations so main-tab scopes mount in widget tests.
void registerHomeScreenScopeGetIt(GetIt getIt) {
  registerFallbackValue(const CheckLocationService());
  final prayerRepository = _FakePrayerTimesRepository();
  final athkarRepository = _FakeAthkarRepository();

  getIt.registerSingleton<PrayerLocationUpdateNotifier>(
    PrayerLocationUpdateNotifier(),
  );
  getIt.registerSingleton<GetCurrentUserUseCase>(
    GetCurrentUserUseCase(_FakeAuthRepository()),
  );
  getIt.registerSingleton<LoadPrayerSettingsUseCase>(
    LoadPrayerSettingsUseCase(prayerRepository),
  );
  getIt.registerSingleton<GetCurrentLocationUseCase>(
    GetCurrentLocationUseCase(prayerRepository),
  );
  getIt.registerSingleton<GetLocationNameUseCase>(
    GetLocationNameUseCase(prayerRepository),
  );
  getIt.registerSingleton<GetPrayerTimesUseCase>(
    GetPrayerTimesUseCase(prayerRepository),
  );
  getIt.registerSingleton<SavePrayerSettingsUseCase>(
    SavePrayerSettingsUseCase(prayerRepository),
  );
  getIt.registerSingleton<NotifyPrayerLocationUpdatedUseCase>(
    NotifyPrayerLocationUpdatedUseCase(
      getIt<PrayerLocationUpdateNotifier>(),
    ),
  );
  getIt.registerFactory<PinnedAthkarCubit>(
    () => PinnedAthkarCubit(
      GetAthkarCategoriesUseCase(athkarRepository),
      GetPinnedAthkarPreferenceUseCase(_FakePinnedAthkarRepository()),
      SavePinnedAthkarCategoryIdsUseCase(_FakePinnedAthkarRepository()),
    ),
  );
  getIt.registerFactory<HomeLayoutCubit>(
    () => HomeLayoutCubit(
      GetHomeLayoutModeUseCase(_FakeHomeLayoutPreferenceRepository()),
      SetHomeLayoutModeUseCase(_FakeHomeLayoutPreferenceRepository()),
    ),
  );
  getIt.registerFactory<HomeQuranResumeCubit>(
    () => HomeQuranResumeCubit(_FakeGetLastReadPositionUseCase()),
  );
  getIt.registerFactory<AthkarCubit>(
    () => AthkarCubit(
      GetAthkarCategoriesUseCase(athkarRepository),
      GetAthkarByCategoryUseCase(athkarRepository),
    ),
  );
  getIt.registerFactory<QiblaBloc>(() {
    final mock = _MockQiblaBloc();
    when(() => mock.close()).thenAnswer((_) async {});
    when(() => mock.state).thenReturn(const QiblaState());
    when(() => mock.stream).thenAnswer((_) => const Stream.empty());
    when(() => mock.add(any())).thenReturn(null);
    when(() => mock.isClosed).thenReturn(false);
    return mock;
  });
}

class _FakeGetLastReadPositionUseCase implements GetLastReadPositionUseCase {
  @override
  Future<Either<Failure, ({int? surahNumber, int? ayahNumber, int? page})>>
  call() async {
    return const Right((surahNumber: null, ayahNumber: null, page: null));
  }
}

class _FakeHomeLayoutPreferenceRepository
    implements HomeLayoutPreferenceRepository {
  @override
  Future<HomeLayoutMode> getLayoutMode() async => HomeLayoutMode.list;

  @override
  Future<void> setLayoutMode(HomeLayoutMode mode) async {}
}
