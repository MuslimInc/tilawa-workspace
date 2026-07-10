import 'package:dartz_plus/dartz_plus.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';
import 'package:quran_sessions/quran_sessions.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tilawa/features/athkar/data/datasources/athkar_daily_progress_local_datasource.dart';
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
import 'package:tilawa/features/history/domain/entities/history_entity.dart';
import 'package:tilawa/features/history/domain/repositories/history_repository.dart';
import 'package:tilawa/features/home/presentation/cubit/home_athkar_compact_cubit.dart';
import 'package:tilawa/features/home/presentation/cubit/home_listening_resume_cubit.dart';
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
import 'package:tilawa/features/settings/domain/services/teacher_capability_refresh_notifier.dart';
import 'package:tilawa_core/core.dart';

class _MockQiblaBloc extends Mock implements QiblaBloc {}

class _MockGetCurrentUserTeacherCapabilityUseCase extends Mock
    implements GetCurrentUserTeacherCapabilityUseCase {}

class _MockTeacherCapabilityRefreshNotifier extends Mock
    implements TeacherCapabilityRefreshNotifier {}

class _MockAuthSessionProvider extends Mock implements AuthSessionProvider {}

class _MockSharedPreferencesAsync extends Mock
    implements SharedPreferencesAsync {}

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
  Future<AuthResult> signInWithEmailPassword({
    required String email,
    required String password,
  }) async => const AuthResult.failure(message: 'not-implemented');

  @override
  Future<AuthResult> registerWithEmailPassword({
    required String email,
    required String password,
  }) async => const AuthResult.failure(message: 'not-implemented');

  @override
  Future<void> signOut() async {}

  @override
  Future<bool> hasAdminClaim() async => false;
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
  final mockPrefs = _MockSharedPreferencesAsync();
  when(() => mockPrefs.getString(any())).thenAnswer((_) async => null);
  when(() => mockPrefs.setString(any(), any())).thenAnswer((_) async => true);
  getIt.registerSingleton<SharedPreferencesAsync>(mockPrefs);

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
  getIt.registerFactory<HomeQuranResumeCubit>(
    () => HomeQuranResumeCubit(
      _FakeGetLastReadPositionUseCase(),
      _FakeHistoryRepository(),
    ),
  );
  getIt.registerFactory<HomeListeningResumeCubit>(
    () => HomeListeningResumeCubit(_FakeHistoryRepository()),
  );
  getIt.registerFactory<HomeAthkarCompactCubit>(
    () => HomeAthkarCompactCubit(
      GetAthkarCategoriesUseCase(athkarRepository),
      GetAthkarByCategoryUseCase(athkarRepository),
      _FakeAthkarDailyProgressLocalDataSource(),
    ),
  );
  getIt.registerFactory<AthkarCubit>(
    () => AthkarCubit(
      GetAthkarCategoriesUseCase(athkarRepository),
      GetAthkarByCategoryUseCase(athkarRepository),
      _FakeAthkarDailyProgressLocalDataSource(),
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

  if (!getIt.isRegistered<AuthSessionProvider>()) {
    final mock = _MockAuthSessionProvider();
    when(() => mock.currentUserId).thenReturn('test_user');
    getIt.registerSingleton<AuthSessionProvider>(mock);
  }
  if (!getIt.isRegistered<GetCurrentUserTeacherCapabilityUseCase>()) {
    final mock = _MockGetCurrentUserTeacherCapabilityUseCase();
    when(() => mock.call(any())).thenAnswer(
      (_) async =>
          const Right(TeacherCapability(state: TeacherCapabilityState.none)),
    );
    getIt.registerSingleton<GetCurrentUserTeacherCapabilityUseCase>(mock);
  }
  if (!getIt.isRegistered<TeacherCapabilityRefreshNotifier>()) {
    final mock = _MockTeacherCapabilityRefreshNotifier();
    when(
      () => mock.onApplicationReviewed,
    ).thenAnswer((_) => const Stream.empty());
    getIt.registerSingleton<TeacherCapabilityRefreshNotifier>(mock);
  }
}

class _FakeGetLastReadPositionUseCase implements GetLastReadPositionUseCase {
  @override
  Future<Either<Failure, ({int? surahNumber, int? ayahNumber, int? page})>>
  call() async {
    return const Right((surahNumber: null, ayahNumber: null, page: null));
  }
}

class _FakeHistoryRepository implements HistoryRepository {
  @override
  Future<List<HistoryEntity>> getRecentHistory({int limit = 20}) async => [];

  @override
  Future<List<HistoryEntity>> getAllHistory() async => [];

  @override
  Future<HistoryEntity> addOrUpdateHistory({
    required int surahId,
    required String surahName,
    required String surahNameEn,
    required String reciterId,
    required String reciterName,
    required int moshafId,
    required String moshafName,
    required int lastPositionMs,
    required int durationMs,
    required String audioUrl,
    String? artworkUrl,
    bool completed = false,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<void> deleteAllHistory() async {}

  @override
  Future<void> deleteHistory(String id) async {}

  @override
  Future<HistoryEntity?> getHistoryById(String id) async => null;

  @override
  Future<List<HistoryEntity>> getHistoryByDateRange({
    required DateTime startDate,
    required DateTime endDate,
  }) async => [];

  @override
  Future<List<HistoryEntity>> getHistoryByReciter(String reciterId) async => [];

  @override
  Future<HistoryEntity?> updateLastPosition({
    required String id,
    required int lastPositionMs,
    bool? completed,
  }) async => null;

  @override
  Future<void> deleteHistoryOlderThan(DateTime date) async {}

  @override
  Future<List<HistoryEntity>> searchHistory(String query) async => [];

  @override
  Future<int> getHistoryCount() async => 0;

  @override
  Future<int> getTotalListeningTime() async => 0;

  @override
  Future<List<HistoryEntity>> getMostPlayedSurahs({int limit = 10}) async => [];

  @override
  Future<bool> hasBeenPlayed({
    required int surahId,
    required String reciterId,
    required int moshafId,
  }) async => false;
}

class _FakeAthkarDailyProgressLocalDataSource
    implements AthkarDailyProgressLocalDataSource {
  @override
  Future<Map<int, int>> loadCounts({
    required int categoryId,
    required String dateKey,
  }) async => const {};

  @override
  Future<void> saveCounts({
    required int categoryId,
    required String dateKey,
    required Map<int, int> remainingCounts,
  }) async {}
}
