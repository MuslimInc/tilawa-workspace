import 'package:get_it/get_it.dart';
import 'package:hive_ce/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tilawa/core/di/get_it_idempotent.dart';
import 'package:tilawa/core/services/hive_readiness.dart';
import 'package:tilawa/features/daily_guidance/data/datasources/daily_guidance_local_data_source.dart';
import 'package:tilawa/features/daily_guidance/data/datasources/daily_guidance_seed_data_source.dart';
import 'package:tilawa/features/daily_guidance/data/repositories/daily_delivery_record_repository_impl.dart';
import 'package:tilawa/features/daily_guidance/data/repositories/daily_guidance_preferences_repository_impl.dart';
import 'package:tilawa/features/daily_guidance/data/repositories/daily_guidance_repository_impl.dart';
import 'package:tilawa/features/daily_guidance/data/services/daily_guidance_notification_service_impl.dart';
import 'package:tilawa/features/daily_guidance/domain/repositories/daily_delivery_record_repository.dart';
import 'package:tilawa/features/daily_guidance/domain/repositories/daily_guidance_preferences_repository.dart';
import 'package:tilawa/features/daily_guidance/domain/repositories/daily_guidance_repository.dart';
import 'package:tilawa/features/daily_guidance/domain/usecases/get_today_guidance_use_case.dart';
import 'package:tilawa/features/daily_guidance/domain/usecases/schedule_daily_guidance_use_case.dart';
import 'package:tilawa/features/daily_guidance/domain/usecases/select_daily_guidance_item_use_case.dart';
import 'package:tilawa/features/daily_guidance/presentation/bloc/daily_guidance_cubit.dart';
import 'package:tilawa_core/services/interfaces/notification_dispatcher_interface.dart';

/// Manual GetIt registrations for `daily_guidance`.
class DailyGuidanceDi {
  DailyGuidanceDi._();

  static void register(GetIt getIt) {
    getIt.registerLazySingletonIfAbsent<DailyGuidanceSeedDataSource>(
      DailyGuidanceSeedDataSource.new,
    );
    getIt.registerLazySingletonIfAbsent<DailyGuidancePreferencesRepository>(
      () => DailyGuidancePreferencesRepositoryImpl(
        getIt<SharedPreferencesAsync>(),
      ),
    );
    getIt.registerLazySingletonIfAbsent<DailyGuidanceLocalDataSource>(
      () => DailyGuidanceLocalDataSource(
        getIt<HiveInterface>(),
        getIt<HiveReadiness>(),
      ),
    );
    getIt.registerLazySingletonIfAbsent<DailyGuidanceRepository>(
      () => DailyGuidanceRepositoryImpl(
        getIt<DailyGuidanceLocalDataSource>(),
        getIt<DailyGuidanceSeedDataSource>(),
      ),
    );
    getIt.registerLazySingletonIfAbsent<DailyDeliveryRecordRepository>(
      () => DailyDeliveryRecordRepositoryImpl(
        getIt<DailyGuidanceLocalDataSource>(),
      ),
    );
    getIt.registerLazySingletonIfAbsent<DailyGuidanceNotificationService>(
      () => DailyGuidanceNotificationServiceImpl(
        getIt<INotificationDispatcher>(),
      ),
    );
    getIt.registerFactoryIfAbsent<ToggleDailyGuidanceUseCase>(
      () => ToggleDailyGuidanceUseCase(
        getIt<DailyGuidancePreferencesRepository>(),
        getIt<DailyGuidanceNotificationService>(),
      ),
    );
    getIt.registerFactoryIfAbsent<ScheduleDailyGuidanceUseCase>(
      () => ScheduleDailyGuidanceUseCase(
        getIt<DailyGuidancePreferencesRepository>(),
        getIt<DailyGuidanceNotificationService>(),
      ),
    );
    getIt.registerFactoryIfAbsent<GetTodayGuidanceUseCase>(
      () => GetTodayGuidanceUseCase(
        getIt<DailyGuidanceRepository>(),
        getIt<DailyDeliveryRecordRepository>(),
      ),
    );
    getIt.registerFactoryIfAbsent<SelectDailyGuidanceItemUseCase>(
      () => SelectDailyGuidanceItemUseCase(
        getIt<DailyGuidanceRepository>(),
        getIt<DailyDeliveryRecordRepository>(),
      ),
    );
    getIt.registerFactoryIfAbsent<DailyGuidanceCubit>(
      () => DailyGuidanceCubit(
        getIt<SelectDailyGuidanceItemUseCase>(),
        getIt<ToggleDailyGuidanceUseCase>(),
        getIt<DailyGuidancePreferencesRepository>(),
      ),
    );
  }
}
