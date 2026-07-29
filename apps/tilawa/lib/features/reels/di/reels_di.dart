import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tilawa/core/di/get_it_idempotent.dart';
import 'package:tilawa/features/reels/data/datasources/reels_local_datasource.dart';
import 'package:tilawa/features/reels/data/datasources/reels_remote_datasource.dart';
import 'package:tilawa/features/reels/data/repositories/reels_repository_impl.dart';
import 'package:tilawa/features/reels/data/services/reels_analytics.dart';
import 'package:tilawa/features/reels/domain/repositories/reels_repository.dart';
import 'package:tilawa/features/reels/domain/usecases/get_reel_categories_use_case.dart';
import 'package:tilawa/features/reels/domain/usecases/get_reels_use_case.dart';
import 'package:tilawa/features/reels/domain/usecases/get_saved_reels_use_case.dart';
import 'package:tilawa/features/reels/domain/usecases/react_to_reel_use_case.dart';
import 'package:tilawa/features/reels/domain/usecases/record_reel_view_use_case.dart';
import 'package:tilawa/features/reels/domain/usecases/save_reel_use_case.dart';
import 'package:tilawa/features/reels/domain/usecases/share_reel_use_case.dart';
import 'package:tilawa/features/reels/presentation/cubit/reels_cubit.dart';
import 'package:tilawa/features/reels/presentation/cubit/saved_reels_cubit.dart';
import 'package:tilawa_core/services/analytics_service.dart';

/// Manual GetIt registrations for `reels`.
class ReelsDi {
  ReelsDi._();

  static void register(GetIt getIt) {
    getIt.registerLazySingletonIfAbsent<ReelsRemoteDataSource>(
      () => ReelsRemoteDataSourceImpl(getIt<Dio>()),
    );
    getIt.registerLazySingletonIfAbsent<ReelsLocalDataSource>(
      () => ReelsLocalDataSourceImpl(getIt<SharedPreferencesAsync>()),
    );
    getIt.registerLazySingletonIfAbsent<ReelsAnalytics>(
      () => ReelsAnalytics(getIt<AnalyticsService>()),
    );
    getIt.registerLazySingletonIfAbsent<ReelsRepository>(
      () => ReelsRepositoryImpl(
        getIt<ReelsRemoteDataSource>(),
        getIt<ReelsLocalDataSource>(),
        getIt<Dio>(),
        getIt<ReelsAnalytics>(),
      ),
    );
    getIt.registerLazySingletonIfAbsent<GetReelCategoriesUseCase>(
      () => GetReelCategoriesUseCase(getIt<ReelsRepository>()),
    );
    getIt.registerLazySingletonIfAbsent<GetReelsUseCase>(
      () => GetReelsUseCase(getIt<ReelsRepository>()),
    );
    getIt.registerLazySingletonIfAbsent<GetSavedReelsUseCase>(
      () => GetSavedReelsUseCase(getIt<ReelsRepository>()),
    );
    getIt.registerLazySingletonIfAbsent<ReactToReelUseCase>(
      () => ReactToReelUseCase(getIt<ReelsRepository>()),
    );
    getIt.registerLazySingletonIfAbsent<RecordReelViewUseCase>(
      () => RecordReelViewUseCase(getIt<ReelsRepository>()),
    );
    getIt.registerLazySingletonIfAbsent<SaveReelUseCase>(
      () => SaveReelUseCase(getIt<ReelsRepository>()),
    );
    getIt.registerLazySingletonIfAbsent<RemoveSavedReelUseCase>(
      () => RemoveSavedReelUseCase(getIt<ReelsRepository>()),
    );
    getIt.registerLazySingletonIfAbsent<ShareReelUseCase>(
      () => ShareReelUseCase(getIt<ReelsRepository>()),
    );
    getIt.registerFactoryIfAbsent<SavedReelsCubit>(
      () => SavedReelsCubit(
        getIt<GetSavedReelsUseCase>(),
        getIt<RemoveSavedReelUseCase>(),
      ),
    );
    getIt.registerFactoryIfAbsent<ReelsCubit>(
      () => ReelsCubit(
        getIt<GetReelsUseCase>(),
        getIt<GetReelCategoriesUseCase>(),
        getIt<SaveReelUseCase>(),
        getIt<RemoveSavedReelUseCase>(),
        getIt<ReactToReelUseCase>(),
        getIt<ShareReelUseCase>(),
        getIt<RecordReelViewUseCase>(),
      ),
    );
  }
}
