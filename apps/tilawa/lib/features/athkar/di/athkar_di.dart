import 'package:flutter/services.dart';
import 'package:get_it/get_it.dart';
import 'package:hive_ce/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tilawa/core/di/get_it_idempotent.dart';
import 'package:tilawa/core/services/hive_readiness.dart';
import 'package:tilawa/core/services/navigation_service.dart';
import 'package:tilawa/core/services/tasbeeh_reminder_notification_service.dart';
import 'package:tilawa/features/athkar/data/datasources/athkar_daily_progress_local_datasource.dart';
import 'package:tilawa/features/athkar/data/datasources/athkar_local_datasource.dart';
import 'package:tilawa/features/athkar/data/datasources/pinned_athkar_local_datasource.dart';
import 'package:tilawa/features/athkar/data/datasources/tasbeeh_layout_preference_local_datasource.dart';
import 'package:tilawa/features/athkar/data/datasources/tasbeeh_local_datasource.dart';
import 'package:tilawa/features/athkar/data/repositories/athkar_repository_impl.dart';
import 'package:tilawa/features/athkar/data/repositories/pinned_athkar_repository_impl.dart';
import 'package:tilawa/features/athkar/data/repositories/tasbeeh_layout_preference_repository_impl.dart';
import 'package:tilawa/features/athkar/data/repositories/tasbeeh_repository_impl.dart';
import 'package:tilawa/features/athkar/domain/policies/tasbeeh_target_reached_policy.dart';
import 'package:tilawa/features/athkar/domain/repositories/athkar_repository.dart';
import 'package:tilawa/features/athkar/domain/repositories/pinned_athkar_repository.dart';
import 'package:tilawa/features/athkar/domain/repositories/tasbeeh_layout_preference_repository.dart';
import 'package:tilawa/features/athkar/domain/repositories/tasbeeh_repository.dart';
import 'package:tilawa/features/athkar/domain/services/tasbeeh_reminder_scheduler.dart';
import 'package:tilawa/features/athkar/domain/services/tasbeeh_target_feedback_service.dart';
import 'package:tilawa/features/athkar/domain/usecases/clear_all_saved_tasbeeh_use_case.dart';
import 'package:tilawa/features/athkar/domain/usecases/delete_tasbeeh_dhikr_use_case.dart';
import 'package:tilawa/features/athkar/domain/usecases/get_athkar_by_category_use_case.dart';
import 'package:tilawa/features/athkar/domain/usecases/get_athkar_categories_use_case.dart';
import 'package:tilawa/features/athkar/domain/usecases/get_pinned_athkar_preference_use_case.dart';
import 'package:tilawa/features/athkar/domain/usecases/get_saved_tasbeeh_use_case.dart';
import 'package:tilawa/features/athkar/domain/usecases/get_tasbeeh_layout_mode_use_case.dart';
import 'package:tilawa/features/athkar/domain/usecases/increment_tasbeeh_count_use_case.dart';
import 'package:tilawa/features/athkar/domain/usecases/reset_tasbeeh_count_use_case.dart';
import 'package:tilawa/features/athkar/domain/usecases/save_custom_tasbeeh_use_case.dart';
import 'package:tilawa/features/athkar/domain/usecases/save_pinned_athkar_category_ids_use_case.dart';
import 'package:tilawa/features/athkar/domain/usecases/set_tasbeeh_layout_mode_use_case.dart';
import 'package:tilawa/features/athkar/domain/usecases/set_tasbeeh_reminder_use_case.dart';
import 'package:tilawa/features/athkar/domain/usecases/set_tasbeeh_target_count_use_case.dart';
import 'package:tilawa/features/athkar/presentation/cubit/athkar_cubit.dart';
import 'package:tilawa/features/athkar/presentation/cubit/pinned_athkar_cubit.dart';
import 'package:tilawa/features/athkar/presentation/cubit/tasbeeh_cubit.dart';
import 'package:tilawa/features/athkar/presentation/services/haptic_tasbeeh_target_feedback_service.dart';
import 'package:tilawa_core/services/analytics_service.dart';
import 'package:tilawa_core/services/interfaces/notification_dispatcher_interface.dart';

/// Manual GetIt registrations for `athkar`.
class AthkarDi {
  AthkarDi._();

  static void register(GetIt getIt) {
    getIt.registerLazySingletonIfAbsent<TasbeehTargetReachedPolicy>(
      () => const TasbeehTargetReachedPolicy(),
    );
    getIt.registerLazySingletonIfAbsent<AthkarDailyProgressLocalDataSource>(
      () => AthkarDailyProgressLocalDataSourceImpl(
        getIt<SharedPreferencesAsync>(),
      ),
    );
    getIt.registerLazySingletonIfAbsent<TasbeehLocalDataSource>(
      () => TasbeehLocalDataSourceImpl(
        getIt<HiveInterface>(),
        getIt<HiveReadiness>(),
      ),
    );
    getIt.registerLazySingletonIfAbsent<PinnedAthkarLocalDataSource>(
      () => PinnedAthkarLocalDataSourceImpl(
        getIt<SharedPreferencesAsync>(),
      ),
    );
    getIt.registerLazySingletonIfAbsent<TasbeehLayoutPreferenceLocalDataSource>(
      () => TasbeehLayoutPreferenceLocalDataSourceImpl(
        getIt<SharedPreferencesAsync>(),
      ),
    );
    getIt.registerLazySingletonIfAbsent<TasbeehTargetFeedbackService>(
      HapticTasbeehTargetFeedbackService.new,
    );
    getIt.registerLazySingletonIfAbsent<AthkarLocalDataSource>(
      () => AthkarLocalDataSourceImpl(assetBundle: getIt<AssetBundle>()),
    );
    getIt.registerLazySingletonIfAbsent<TasbeehReminderScheduler>(
      () => TasbeehReminderNotificationService(
        getIt<SharedPreferencesAsync>(),
        getIt<INotificationDispatcher>(),
        getIt<NavigationService>(),
      ),
    );
    getIt.registerLazySingletonIfAbsent<PinnedAthkarRepository>(
      () => PinnedAthkarRepositoryImpl(
        getIt<PinnedAthkarLocalDataSource>(),
      ),
    );
    getIt.registerLazySingletonIfAbsent<AthkarRepository>(
      () => AthkarRepositoryImpl(
        getIt<AthkarLocalDataSource>(),
        getIt<AnalyticsService>(),
      ),
    );
    getIt.registerLazySingletonIfAbsent<GetAthkarByCategoryUseCase>(
      () => GetAthkarByCategoryUseCase(getIt<AthkarRepository>()),
    );
    getIt.registerLazySingletonIfAbsent<GetAthkarCategoriesUseCase>(
      () => GetAthkarCategoriesUseCase(getIt<AthkarRepository>()),
    );
    getIt.registerLazySingletonIfAbsent<TasbeehRepository>(
      () => TasbeehRepositoryImpl(getIt<TasbeehLocalDataSource>()),
    );
    getIt.registerFactoryIfAbsent<AthkarCubit>(
      () => AthkarCubit(
        getIt<GetAthkarCategoriesUseCase>(),
        getIt<GetAthkarByCategoryUseCase>(),
        getIt<AthkarDailyProgressLocalDataSource>(),
      ),
    );
    getIt.registerLazySingletonIfAbsent<GetPinnedAthkarPreferenceUseCase>(
      () => GetPinnedAthkarPreferenceUseCase(
        getIt<PinnedAthkarRepository>(),
      ),
    );
    getIt.registerLazySingletonIfAbsent<SavePinnedAthkarCategoryIdsUseCase>(
      () => SavePinnedAthkarCategoryIdsUseCase(
        getIt<PinnedAthkarRepository>(),
      ),
    );
    getIt.registerLazySingletonIfAbsent<TasbeehLayoutPreferenceRepository>(
      () => TasbeehLayoutPreferenceRepositoryImpl(
        getIt<TasbeehLayoutPreferenceLocalDataSource>(),
      ),
    );
    getIt.registerLazySingletonIfAbsent<ClearAllSavedTasbeehUseCase>(
      () => ClearAllSavedTasbeehUseCase(getIt<TasbeehRepository>()),
    );
    getIt.registerLazySingletonIfAbsent<DeleteTasbeehDhikrUseCase>(
      () => DeleteTasbeehDhikrUseCase(getIt<TasbeehRepository>()),
    );
    getIt.registerLazySingletonIfAbsent<GetSavedTasbeehUseCase>(
      () => GetSavedTasbeehUseCase(getIt<TasbeehRepository>()),
    );
    getIt.registerLazySingletonIfAbsent<IncrementTasbeehCountUseCase>(
      () => IncrementTasbeehCountUseCase(getIt<TasbeehRepository>()),
    );
    getIt.registerLazySingletonIfAbsent<ResetTasbeehCountUseCase>(
      () => ResetTasbeehCountUseCase(getIt<TasbeehRepository>()),
    );
    getIt.registerLazySingletonIfAbsent<SaveCustomTasbeehUseCase>(
      () => SaveCustomTasbeehUseCase(getIt<TasbeehRepository>()),
    );
    getIt.registerLazySingletonIfAbsent<SetTasbeehReminderUseCase>(
      () => SetTasbeehReminderUseCase(getIt<TasbeehRepository>()),
    );
    getIt.registerLazySingletonIfAbsent<SetTasbeehTargetCountUseCase>(
      () => SetTasbeehTargetCountUseCase(getIt<TasbeehRepository>()),
    );
    getIt.registerFactoryIfAbsent<PinnedAthkarCubit>(
      () => PinnedAthkarCubit(
        getIt<GetAthkarCategoriesUseCase>(),
        getIt<GetPinnedAthkarPreferenceUseCase>(),
        getIt<SavePinnedAthkarCategoryIdsUseCase>(),
      ),
    );
    getIt.registerLazySingletonIfAbsent<GetTasbeehLayoutModeUseCase>(
      () => GetTasbeehLayoutModeUseCase(
        getIt<TasbeehLayoutPreferenceRepository>(),
      ),
    );
    getIt.registerLazySingletonIfAbsent<SetTasbeehLayoutModeUseCase>(
      () => SetTasbeehLayoutModeUseCase(
        getIt<TasbeehLayoutPreferenceRepository>(),
      ),
    );
    getIt.registerFactoryIfAbsent<TasbeehCubit>(
      () => TasbeehCubit(
        getIt<GetSavedTasbeehUseCase>(),
        getIt<SaveCustomTasbeehUseCase>(),
        getIt<IncrementTasbeehCountUseCase>(),
        getIt<ResetTasbeehCountUseCase>(),
        getIt<SetTasbeehTargetCountUseCase>(),
        getIt<DeleteTasbeehDhikrUseCase>(),
        getIt<ClearAllSavedTasbeehUseCase>(),
        getIt<GetTasbeehLayoutModeUseCase>(),
        getIt<SetTasbeehLayoutModeUseCase>(),
        getIt<SetTasbeehReminderUseCase>(),
        getIt<TasbeehReminderScheduler>(),
        getIt<TasbeehTargetFeedbackService>(),
        targetReachedPolicy: getIt<TasbeehTargetReachedPolicy>(),
      ),
    );
  }
}
