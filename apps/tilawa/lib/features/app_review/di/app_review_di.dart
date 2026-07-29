import 'package:get_it/get_it.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tilawa/core/di/get_it_idempotent.dart';
import 'package:tilawa/features/app_review/data/config/app_review_store_config.dart';
import 'package:tilawa/features/app_review/data/datasources/app_review_engagement_local_datasource.dart';
import 'package:tilawa/features/app_review/data/datasources/app_review_platform_data_source.dart';
import 'package:tilawa/features/app_review/data/datasources/in_app_review_platform_data_source.dart';
import 'package:tilawa/features/app_review/data/repositories/app_review_engagement_repository_impl.dart';
import 'package:tilawa/features/app_review/data/repositories/app_review_repository_impl.dart';
import 'package:tilawa/features/app_review/domain/entities/app_review_trigger_policy.dart';
import 'package:tilawa/features/app_review/domain/repositories/app_review_engagement_repository.dart';
import 'package:tilawa/features/app_review/domain/repositories/app_review_repository.dart';
import 'package:tilawa/features/app_review/domain/services/app_review_flow_guard.dart';
import 'package:tilawa/features/app_review/domain/services/app_review_trigger_manager.dart';
import 'package:tilawa/features/app_review/domain/services/prayer_times_app_review_coordinator.dart';
import 'package:tilawa/features/app_review/domain/usecases/is_app_review_available_use_case.dart';
import 'package:tilawa/features/app_review/domain/usecases/open_app_store_listing_use_case.dart';
import 'package:tilawa/features/app_review/domain/usecases/request_app_review_use_case.dart';
import 'package:tilawa/features/app_review/presentation/cubit/app_review_cubit.dart';

/// Manual GetIt registrations for `app_review`.
class AppReviewDi {
  AppReviewDi._();

  static void register(GetIt getIt) {
    getIt.registerLazySingletonIfAbsent<AppReviewStoreConfig>(
      () => const AppReviewStoreConfig(),
    );
    getIt.registerLazySingletonIfAbsent<AppReviewFlowGuard>(
      AppReviewFlowGuard.new,
    );
    getIt.registerLazySingletonIfAbsent<PrayerTimesAppReviewCoordinator>(
      PrayerTimesAppReviewCoordinator.new,
    );
    getIt.registerLazySingletonIfAbsent<AppReviewEngagementLocalDataSource>(
      () => AppReviewEngagementLocalDataSourceImpl(
        getIt<SharedPreferencesAsync>(),
      ),
    );
    getIt.registerLazySingletonIfAbsent<AppReviewEngagementRepository>(
      () => AppReviewEngagementRepositoryImpl(
        getIt<AppReviewEngagementLocalDataSource>(),
      ),
    );
    getIt.registerLazySingletonIfAbsent<AppReviewPlatformDataSource>(
      () => InAppReviewPlatformDataSource(getIt<InAppReview>()),
    );
    getIt.registerLazySingletonIfAbsent<AppReviewRepository>(
      () => AppReviewRepositoryImpl(
        getIt<AppReviewPlatformDataSource>(),
        getIt<AppReviewStoreConfig>(),
      ),
    );
    getIt.registerLazySingletonIfAbsent<IsAppReviewAvailableUseCase>(
      () => IsAppReviewAvailableUseCase(getIt<AppReviewRepository>()),
    );
    getIt.registerLazySingletonIfAbsent<OpenAppStoreListingUseCase>(
      () => OpenAppStoreListingUseCase(getIt<AppReviewRepository>()),
    );
    getIt.registerLazySingletonIfAbsent<RequestAppReviewUseCase>(
      () => RequestAppReviewUseCase(getIt<AppReviewRepository>()),
    );
    getIt.registerFactoryIfAbsent<AppReviewCubit>(
      () => AppReviewCubit(
        getIt<IsAppReviewAvailableUseCase>(),
        getIt<RequestAppReviewUseCase>(),
        getIt<OpenAppStoreListingUseCase>(),
      ),
    );
    getIt.registerLazySingletonIfAbsent<AppReviewTriggerManager>(
      () => AppReviewTriggerManager(
        getIt<AppReviewEngagementRepository>(),
        getIt<RequestAppReviewUseCase>(),
        getIt<AppReviewFlowGuard>(),
        getIt<AppReviewTriggerPolicy>(),
      ),
    );
  }
}
