import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tilawa/core/di/injection.dart';
import 'package:tilawa/core/services/hive_readiness.dart';
import 'package:tilawa/features/auth/domain/usecases/get_current_user_use_case.dart';
import 'package:tilawa/features/history/domain/repositories/history_repository.dart';
import 'package:tilawa/features/prayer_times/domain/usecases/get_current_location_use_case.dart';
import 'package:tilawa/features/prayer_times/domain/usecases/get_location_name_use_case.dart';
import 'package:tilawa/features/prayer_times/domain/usecases/get_prayer_times_use_case.dart';
import 'package:tilawa/features/prayer_times/domain/usecases/load_prayer_settings_use_case.dart';
import 'package:tilawa/features/prayer_times/domain/usecases/save_prayer_settings_use_case.dart';
import 'package:tilawa/features/quran_reader/domain/repositories/quran_reader_repository.dart';
import 'package:tilawa/features/smart_khatma/smart_khatma.dart';
import 'package:tilawa/features/today_plan/today_plan.dart';
import 'package:tilawa_core/services/analytics_service.dart';

import '../data/datasources/home_dashboard_memory_cache.dart';
import '../data/repositories/home_dashboard_repository_impl.dart';
import '../domain/repositories/home_dashboard_cache.dart';
import '../domain/repositories/home_dashboard_repository.dart';

/// Injectable wiring for Home dashboard repository + cache.
@module
abstract class HomeScreenModule {
  @lazySingleton
  HomeDashboardCache homeDashboardCache() => HomeDashboardMemoryCache.shared;

  @lazySingleton
  HomeDashboardRepository homeDashboardRepository(
    GetCurrentUserUseCase getCurrentUser,
    LoadPrayerSettingsUseCase loadPrayerSettings,
    GetCurrentLocationUseCase getCurrentLocation,
    GetLocationNameUseCase getLocationName,
    GetPrayerTimesUseCase getPrayerTimes,
    SavePrayerSettingsUseCase savePrayerSettings,
  ) {
    return HomeDashboardRepositoryImpl(
      getCurrentUser: getCurrentUser,
      loadPrayerSettings: loadPrayerSettings,
      getCurrentLocation: getCurrentLocation,
      getLocationName: getLocationName,
      getPrayerTimes: getPrayerTimes,
      savePrayerSettings: savePrayerSettings,
    );
  }
}

/// Builds [TodayPlanBloc] with optional Smart Khatma wiring.
final class TodayPlanBlocFactory {
  const TodayPlanBlocFactory._();

  static TodayPlanBloc create() {
    final localDataSource = SharedPreferencesTodayPlanLocalDataSource(
      getIt<SharedPreferencesAsync>(),
    );
    final repository = TodayPlanRepositoryImpl(localDataSource);
    final GetKhatmaTodayTargetUseCase? getKhatmaTodayTarget =
        isSmartKhatmaEnabled()
        ? SmartKhatmaDependencies.getTodayTarget(
            SmartKhatmaDependencies.repository(),
          )
        : null;
    return TodayPlanBloc(
      GenerateTodayPlanUseCase(
        getIt<QuranReaderRepository>(),
        getIt<HistoryRepository>(),
        repository,
        getIt<HiveReadiness>(),
        getKhatmaTodayTarget,
      ),
      SetTodayPlanTaskCompletedUseCase(repository),
      getIt<AnalyticsService>(),
    )..add(const TodayPlanStarted());
  }
}
