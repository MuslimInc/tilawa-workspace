import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tilawa/core/di/get_it_idempotent.dart';
import 'package:tilawa/features/app_review/data/adapters/app_review_reciter_engagement_reporter.dart';
import 'package:tilawa/features/app_review/domain/services/app_review_trigger_manager.dart';
import 'package:tilawa/features/auth/domain/repositories/auth_repository.dart';
import 'package:tilawa/features/downloads/domain/usecases/cancel_downloads_for_reciter_use_case.dart';
import 'package:tilawa/features/downloads/domain/usecases/check_low_device_storage_use_case.dart';
import 'package:tilawa/features/downloads/domain/usecases/download_all_surahs_use_case.dart';
import 'package:tilawa/features/downloads/domain/usecases/get_valid_completed_downloads_use_case.dart';
import 'package:tilawa/features/downloads/domain/usecases/observe_reciter_downloads_use_case.dart';
import 'package:tilawa/features/history/domain/usecases/get_history_by_reciter_use_case.dart';
import 'package:tilawa/features/reciters/data/datasources/reciters_favorites_datasource.dart';
import 'package:tilawa/features/reciters/data/datasources/reciters_local_datasource.dart';
import 'package:tilawa/features/reciters/data/datasources/reciters_remote_datasource.dart';
import 'package:tilawa/features/reciters/data/repositories/reciters_repository_impl.dart';
import 'package:tilawa/features/reciters/domain/repositories/reciters_repository.dart';
import 'package:tilawa/features/reciters/domain/services/reciter_engagement_reporter.dart';
import 'package:tilawa/features/reciters/domain/usecases/clear_favorite_reciters_use_case.dart';
import 'package:tilawa/features/reciters/domain/usecases/get_favorite_reciters_use_case.dart';
import 'package:tilawa/features/reciters/domain/usecases/get_reciters_use_case.dart';
import 'package:tilawa/features/reciters/domain/usecases/search_reciters_use_case.dart';
import 'package:tilawa/features/reciters/domain/usecases/toggle_favorite_reciter_use_case.dart';
import 'package:tilawa/features/reciters/presentation/bloc/alphabet_scrollbar/alphabet_scrollbar_bloc.dart';
import 'package:tilawa/features/reciters/presentation/bloc/reciter_details_bloc.dart';
import 'package:tilawa/features/reciters/presentation/bloc/reciter_download_bloc.dart';
import 'package:tilawa/features/reciters/presentation/bloc/reciters_bloc.dart';
import 'package:tilawa/features/reciters/presentation/cubit/favorites_cubit.dart';
import 'package:tilawa/features/reciters/presentation/cubit/reciter_details_loader_cubit.dart';
import 'package:tilawa/features/reciters/presentation/cubit/reciters_search_cubit.dart';
import 'package:tilawa/features/surah/domain/usecases/convert_audio_entities_to_surahs_use_case.dart';
import 'package:tilawa/features/surah/domain/usecases/refresh_surah_download_status_use_case.dart';
import 'package:tilawa/shared/audio/audio_player_handler.dart';
import 'package:tilawa_core/entities/reciter_entity.dart';

/// Manual GetIt registrations for `reciters`.
class RecitersDi {
  RecitersDi._();

  static void register(GetIt getIt) {
    getIt.registerFactoryIfAbsent<AlphabetScrollbarBloc>(
      AlphabetScrollbarBloc.new,
    );
    getIt.registerLazySingletonIfAbsent<RecitersLocalDataSource>(
      () => RecitersLocalDataSourceImpl(getIt<SharedPreferencesAsync>()),
    );
    getIt.registerLazySingletonIfAbsent<RecitersRemoteDataSource>(
      () => RecitersRemoteDataSourceImpl(getIt<Dio>()),
    );
    getIt.registerLazySingletonIfAbsent<RecitersFavoritesDataSource>(
      () => RecitersFavoritesDataSourceImpl(getIt<FirebaseFirestore>()),
    );
    getIt.registerLazySingletonIfAbsent<ReciterEngagementReporter>(
      () => AppReviewReciterEngagementReporter(
        getIt<AppReviewTriggerManager>(),
      ),
    );
    getIt.registerLazySingletonIfAbsent<RecitersRepository>(
      () => RecitersRepositoryImpl(
        getIt<RecitersRemoteDataSource>(),
        getIt<RecitersLocalDataSource>(),
        getIt<RecitersFavoritesDataSource>(),
        getIt<AuthRepository>(),
        getIt<SharedPreferencesAsync>(),
        getIt<ReciterEngagementReporter>(),
      ),
    );
    getIt.registerLazySingletonIfAbsent<ClearFavoriteRecitersUseCase>(
      () => ClearFavoriteRecitersUseCase(getIt<RecitersRepository>()),
    );
    getIt.registerLazySingletonIfAbsent<GetFavoriteRecitersUseCase>(
      () => GetFavoriteRecitersUseCase(getIt<RecitersRepository>()),
    );
    getIt.registerLazySingletonIfAbsent<ToggleFavoriteReciterUseCase>(
      () => ToggleFavoriteReciterUseCase(getIt<RecitersRepository>()),
    );
    getIt.registerLazySingletonIfAbsent<GetRecitersUseCase>(
      () => GetRecitersUseCase(getIt<RecitersRepository>()),
    );
    getIt.registerFactoryIfAbsent<ReciterDetailsLoaderCubit>(
      () => ReciterDetailsLoaderCubit(getIt<RecitersRepository>()),
    );
    getIt.registerFactoryIfAbsent<SearchRecitersUseCase>(
      () => SearchRecitersUseCase(getIt<GetRecitersUseCase>()),
    );
    getIt.registerFactoryIfAbsent<FavoritesCubit>(
      () => FavoritesCubit(
        getIt<GetFavoriteRecitersUseCase>(),
        getIt<ToggleFavoriteReciterUseCase>(),
        getIt<ClearFavoriteRecitersUseCase>(),
      ),
    );
    getIt.registerLazySingletonIfAbsent<RecitersBloc>(
      () => RecitersBloc(
        getIt<GetRecitersUseCase>(),
        initialReciters: getIt<List<ReciterEntity>>(),
        catalogLanguageCode: getIt<String>(),
      ),
    );
    getIt.registerFactoryIfAbsent<RecitersSearchCubit>(
      () => RecitersSearchCubit(getIt<SearchRecitersUseCase>()),
    );
    getIt.registerFactoryIfAbsent<ReciterDownloadBloc>(
      () => ReciterDownloadBloc(
        getIt<DownloadAllSurahsUseCase>(),
        getIt<CancelDownloadsForReciterUseCase>(),
        getIt<ObserveReciterDownloadsUseCase>(),
        getIt<CheckLowDeviceStorageUseCase>(),
      ),
    );
    getIt.registerFactoryIfAbsent<ReciterDetailsBloc>(
      () => ReciterDetailsBloc(
        getIt<AudioPlayerHandler>(),
        getIt<ConvertAudioEntitiesToSurahsUseCase>(),
        getIt<RefreshSurahDownloadStatusUseCase>(),
        getIt<GetValidCompletedDownloadsUseCase>(),
        getIt<GetHistoryByReciterUseCase>(),
      ),
    );
  }
}
