import 'package:get_it/get_it.dart';
import 'package:quran_sessions/quran_sessions.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tilawa/core/di/get_it_idempotent.dart';
import 'package:tilawa/features/athkar/data/datasources/athkar_daily_progress_local_datasource.dart';
import 'package:tilawa/features/athkar/domain/usecases/get_athkar_by_category_use_case.dart';
import 'package:tilawa/features/athkar/domain/usecases/get_athkar_categories_use_case.dart';
import 'package:tilawa/features/history/domain/repositories/history_repository.dart';
import 'package:tilawa/features/home/data/datasources/home_daily_ayah_bookmark_store_impl.dart';
import 'package:tilawa/features/home/domain/repositories/home_daily_ayah_bookmark_store.dart';
import 'package:tilawa/features/home/domain/repositories/home_dashboard_cache.dart';
import 'package:tilawa/features/home/domain/repositories/home_dashboard_repository.dart';
import 'package:tilawa/features/home/domain/usecases/get_home_dashboard_use_case.dart';
import 'package:tilawa/features/home/domain/usecases/toggle_home_daily_ayah_bookmark_use_case.dart';
import 'package:tilawa/features/home/presentation/bloc/home_dashboard_bloc.dart';
import 'package:tilawa/features/home/presentation/cubit/home_athkar_compact_cubit.dart';
import 'package:tilawa/features/home/presentation/cubit/home_learning_cubit.dart';
import 'package:tilawa/features/home/presentation/cubit/home_listening_resume_cubit.dart';
import 'package:tilawa/features/home/presentation/cubit/home_quran_resume_cubit.dart';
import 'package:tilawa/features/home/presentation/services/home_learning_preference_store.dart';
import 'package:tilawa/features/prayer_times/domain/usecases/notify_prayer_location_updated_use_case.dart';
import 'package:tilawa/features/quran_reader/domain/usecases/get_last_read_position_use_case.dart';

/// Manual GetIt registrations for `home`.
class HomeDi {
  HomeDi._();

  static void register(GetIt getIt) {
    getIt.registerLazySingletonIfAbsent<HomeLearningPreferenceStore>(
      () => SharedPreferencesHomeLearningPreferenceStore(
        getIt<SharedPreferencesAsync>(),
      ),
    );
    getIt.registerLazySingletonIfAbsent<HomeDailyAyahBookmarkStore>(
      () => SharedPreferencesHomeDailyAyahBookmarkStore(
        getIt<SharedPreferencesAsync>(),
      ),
    );
    getIt.registerFactoryIfAbsent<ToggleHomeDailyAyahBookmarkUseCase>(
      () => ToggleHomeDailyAyahBookmarkUseCase(
        getIt<HomeDailyAyahBookmarkStore>(),
      ),
    );
    getIt.registerFactoryIfAbsent<HomeAthkarCompactCubit>(
      () => HomeAthkarCompactCubit(
        getIt<GetAthkarCategoriesUseCase>(),
        getIt<GetAthkarByCategoryUseCase>(),
        getIt<AthkarDailyProgressLocalDataSource>(),
      ),
    );
    getIt.registerFactoryIfAbsent<HomeLearningCubit>(
      () => HomeLearningCubit(
        getStudentSessions: getIt<GetStudentSessionsUseCase>(),
        getSessionAggregate: getIt<GetSessionAggregateUseCase>(),
        preferenceStore: getIt<HomeLearningPreferenceStore>(),
      ),
    );
    getIt.registerFactoryIfAbsent<HomeListeningResumeCubit>(
      () => HomeListeningResumeCubit(getIt<HistoryRepository>()),
    );
    getIt.registerFactoryIfAbsent<GetHomeDashboardUseCase>(
      () => GetHomeDashboardUseCase(
        getIt<HomeDashboardRepository>(),
        getIt<HomeDashboardCache>(),
      ),
    );
    getIt.registerFactoryIfAbsent<HomeDashboardBloc>(
      () => HomeDashboardBloc(
        getIt<GetHomeDashboardUseCase>(),
        getIt<NotifyPrayerLocationUpdatedUseCase>(),
      ),
    );
    getIt.registerFactoryIfAbsent<HomeQuranResumeCubit>(
      () => HomeQuranResumeCubit(
        getIt<GetLastReadPositionUseCase>(),
        getIt<HistoryRepository>(),
      ),
    );
  }
}
