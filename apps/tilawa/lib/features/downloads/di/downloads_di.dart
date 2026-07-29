import 'package:disk_space_plus/disk_space_plus.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tilawa/core/di/get_it_idempotent.dart';
import 'package:tilawa/core/services/navigation_service.dart';
import 'package:tilawa/features/downloads/data/datasources/downloads_local_datasource.dart';
import 'package:tilawa/features/downloads/data/repositories/downloads_repository_impl.dart';
import 'package:tilawa/features/downloads/data/services/batch_download_manager.dart';
import 'package:tilawa/features/downloads/data/services/device_storage_service_impl.dart';
import 'package:tilawa/features/downloads/data/services/download_notification_service.dart';
import 'package:tilawa/features/downloads/data/services/download_path_resolver.dart';
import 'package:tilawa/features/downloads/data/services/download_queue_manager.dart';
import 'package:tilawa/features/downloads/data/services/download_recovery_service.dart';
import 'package:tilawa/features/downloads/data/services/download_service_impl.dart';
import 'package:tilawa/features/downloads/data/services/download_service_interface.dart';
import 'package:tilawa/features/downloads/data/services/download_status_synchronizer.dart';
import 'package:tilawa/features/downloads/data/services/download_validator.dart';
import 'package:tilawa/features/downloads/data/services/downloads_initialization_service.dart';
import 'package:tilawa/features/downloads/data/services/flutter_downloader_wrapper.dart';
import 'package:tilawa/features/downloads/data/services/helpers/download_file_helper.dart';
import 'package:tilawa/features/downloads/data/services/helpers/download_isolate_manager.dart';
import 'package:tilawa/features/downloads/data/services/helpers/download_status_mapper.dart';
import 'package:tilawa/features/downloads/domain/repositories/batch_download_repository.dart';
import 'package:tilawa/features/downloads/domain/repositories/downloads_repository.dart';
import 'package:tilawa/features/downloads/domain/repositories/single_download_repository.dart';
import 'package:tilawa/features/downloads/domain/services/batch_download_service_interface.dart';
import 'package:tilawa/features/downloads/domain/services/completed_download_file_validator.dart';
import 'package:tilawa/features/downloads/domain/services/device_storage_service.dart';
import 'package:tilawa/features/downloads/domain/services/download_notification_navigator.dart';
import 'package:tilawa/features/downloads/domain/services/download_notification_service_interface.dart';
import 'package:tilawa/features/downloads/domain/services/download_queue_service_interface.dart';
import 'package:tilawa/features/downloads/domain/services/download_service_interface.dart';
import 'package:tilawa/features/downloads/domain/services/downloads_initializer.dart';
import 'package:tilawa/features/downloads/domain/usecases/cancel_download_use_case.dart';
import 'package:tilawa/features/downloads/domain/usecases/cancel_downloads_for_reciter_use_case.dart';
import 'package:tilawa/features/downloads/domain/usecases/check_download_access_use_case.dart';
import 'package:tilawa/features/downloads/domain/usecases/check_low_device_storage_use_case.dart';
import 'package:tilawa/features/downloads/domain/usecases/check_surah_downloaded_use_case.dart';
import 'package:tilawa/features/downloads/domain/usecases/clear_all_downloads_use_case.dart';
import 'package:tilawa/features/downloads/domain/usecases/delete_download_use_case.dart';
import 'package:tilawa/features/downloads/domain/usecases/delete_reciter_downloads_use_case.dart';
import 'package:tilawa/features/downloads/domain/usecases/download_all_surahs_use_case.dart';
import 'package:tilawa/features/downloads/domain/usecases/download_surah_use_case.dart';
import 'package:tilawa/features/downloads/domain/usecases/get_download_item_use_case.dart';
import 'package:tilawa/features/downloads/domain/usecases/get_download_status_use_case.dart';
import 'package:tilawa/features/downloads/domain/usecases/get_downloads_by_reciter_use_case.dart';
import 'package:tilawa/features/downloads/domain/usecases/get_total_downloads_size_use_case.dart';
import 'package:tilawa/features/downloads/domain/usecases/get_valid_completed_downloads_use_case.dart';
import 'package:tilawa/features/downloads/domain/usecases/observe_download_progress_use_case.dart';
import 'package:tilawa/features/downloads/domain/usecases/observe_global_download_progress_use_case.dart';
import 'package:tilawa/features/downloads/domain/usecases/observe_reciter_downloads_use_case.dart';
import 'package:tilawa/features/downloads/domain/usecases/pause_download_use_case.dart';
import 'package:tilawa/features/downloads/domain/usecases/play_all_downloads_use_case.dart';
import 'package:tilawa/features/downloads/domain/usecases/play_download_use_case.dart';
import 'package:tilawa/features/downloads/domain/usecases/remove_from_download_queue_use_case.dart';
import 'package:tilawa/features/downloads/domain/usecases/resume_download_use_case.dart';
import 'package:tilawa/features/downloads/domain/usecases/retry_download_use_case.dart';
import 'package:tilawa/features/downloads/domain/usecases/validate_downloaded_file_use_case.dart';
import 'package:tilawa/features/downloads/presentation/bloc/downloads_bloc.dart';
import 'package:tilawa/features/downloads/presentation/services/download_notification_navigator_impl.dart';
import 'package:tilawa/features/reciters/domain/repositories/reciters_repository.dart';
import 'package:tilawa/shared/audio/audio_player_handler.dart';
import 'package:tilawa_core/network/network_info.dart';
import 'package:tilawa_core/services/interfaces/notification_dispatcher_interface.dart';

/// Manual GetIt registrations for `downloads`.
class DownloadsDi {
  DownloadsDi._();

  static void register(GetIt getIt) {
    getIt.registerLazySingletonIfAbsent<FlutterDownloaderWrapper>(
      FlutterDownloaderWrapper.new,
    );
    getIt.registerLazySingletonIfAbsent<DownloadFileHelper>(
      DownloadFileHelper.new,
    );
    getIt.registerLazySingletonIfAbsent<DownloadIsolateManager>(
      DownloadIsolateManager.new,
    );
    getIt.registerLazySingletonIfAbsent<DownloadStatusMapper>(
      DownloadStatusMapper.new,
    );
    getIt.registerLazySingletonIfAbsent<CheckDownloadAccessUseCase>(
      () => const CheckDownloadAccessUseCase(),
    );
    getIt.registerLazySingletonIfAbsent<DownloadServiceInterface>(
      () => DownloadServiceImpl(
        getIt<FlutterDownloaderWrapper>(),
        getIt<DownloadFileHelper>(),
        getIt<DownloadStatusMapper>(),
        getIt<DownloadIsolateManager>(),
      ),
    );
    getIt.registerLazySingletonIfAbsent<DownloadsLocalDataSource>(
      () => DownloadsLocalDataSourceImpl(
        getIt<SharedPreferencesAsync>(),
      ),
    );
    getIt.registerLazySingletonIfAbsent<DownloadPathResolver>(
      () => DownloadPathResolver(getIt<DownloadsLocalDataSource>()),
    );
    getIt.registerLazySingletonIfAbsent<DownloadValidator>(
      () => DownloadValidator(getIt<DownloadsLocalDataSource>()),
    );
    getIt.registerLazySingletonIfAbsent<DeviceStorageService>(
      () => DeviceStorageServiceImpl(getIt<DiskSpacePlus>()),
    );
    getIt.registerLazySingletonIfAbsent<GetDownloadStatusUseCase>(
      () => GetDownloadStatusUseCase(getIt<DownloadServiceInterface>()),
    );
    getIt.registerLazySingletonIfAbsent<ObserveGlobalDownloadProgressUseCase>(
      () => ObserveGlobalDownloadProgressUseCase(
        getIt<DownloadServiceInterface>(),
      ),
    );
    getIt.registerFactoryIfAbsent<CheckLowDeviceStorageUseCase>(
      () => CheckLowDeviceStorageUseCase(getIt<DeviceStorageService>()),
    );
    getIt.registerLazySingletonIfAbsent<DownloadNotificationNavigator>(
      () => DownloadNotificationNavigatorImpl(
        getIt<RecitersRepository>(),
        getIt<NavigationService>(),
      ),
    );
    getIt.registerLazySingletonIfAbsent<IDownloadNotificationService>(
      () => DownloadNotificationService(
        getIt<DownloadNotificationNavigator>(),
        getIt<INotificationDispatcher>(),
      ),
    );
    getIt.registerLazySingletonIfAbsent<BatchDownloadManager>(
      () => BatchDownloadManager(
        getIt<DownloadServiceInterface>(),
        getIt<IDownloadNotificationService>(),
        getIt<SharedPreferencesAsync>(),
      ),
    );
    getIt.registerLazySingletonIfAbsent<DownloadQueueManager>(
      () => DownloadQueueManager(
        getIt<DownloadServiceInterface>(),
        getIt<IDownloadNotificationService>(),
      ),
    );
    getIt.registerLazySingletonIfAbsent<DownloadRecoveryService>(
      () => DownloadRecoveryService(
        getIt<DownloadServiceInterface>(),
        getIt<DownloadValidator>(),
        getIt<DownloadQueueManager>(),
      ),
    );
    getIt.registerLazySingletonIfAbsent<DownloadStatusSynchronizer>(
      () => DownloadStatusSynchronizer(
        getIt<DownloadServiceInterface>(),
        getIt<DownloadRecoveryService>(),
        getIt<DownloadQueueManager>(),
      ),
    );
    getIt.registerLazySingletonIfAbsent<DownloadsRepository>(
      () => DownloadsRepositoryImpl(
        getIt<DownloadsLocalDataSource>(),
        getIt<DownloadServiceInterface>(),
        getIt<BatchDownloadManager>(),
        getIt<DownloadPathResolver>(),
        getIt<DownloadStatusSynchronizer>(),
        getIt<DownloadValidator>(),
        getIt<DownloadQueueManager>(),
        getIt<NetworkInfo>(),
      ),
    );
    getIt.registerLazySingletonIfAbsent<DownloadsInitializer>(
      () => DownloadsInitializationService(
        getIt<DownloadsRepository>(),
        getIt<IDownloadNotificationService>(),
        getIt<BatchDownloadManager>(),
        getIt<DownloadQueueManager>(),
        getIt<SharedPreferencesAsync>(),
      ),
    );
    getIt.registerLazySingletonIfAbsent<DownloadSurahUseCase>(
      () => DownloadSurahUseCase(getIt<SingleDownloadRepository>()),
    );
    getIt.registerFactoryIfAbsent<ObserveDownloadProgressUseCase>(
      () => ObserveDownloadProgressUseCase(
        getIt<SingleDownloadRepository>(),
      ),
    );
    getIt.registerFactoryIfAbsent<ObserveReciterDownloadsUseCase>(
      () => ObserveReciterDownloadsUseCase(
        getIt<SingleDownloadRepository>(),
      ),
    );
    getIt.registerLazySingletonIfAbsent<RemoveFromDownloadQueueUseCase>(
      () => RemoveFromDownloadQueueUseCase(
        getIt<IDownloadQueueService>(),
      ),
    );
    getIt.registerLazySingletonIfAbsent<DownloadAllSurahsUseCase>(
      () => DownloadAllSurahsUseCase(getIt<BatchDownloadRepository>()),
    );
    getIt.registerFactoryIfAbsent<CancelDownloadsForReciterUseCase>(
      () => CancelDownloadsForReciterUseCase(
        getIt<DownloadsRepository>(),
        getIt<RecitersRepository>(),
        getIt<IBatchDownloadService>(),
        getIt<IDownloadQueueService>(),
      ),
    );
    getIt.registerLazySingletonIfAbsent<GetTotalDownloadsSizeUseCase>(
      () => GetTotalDownloadsSizeUseCase(getIt<DownloadsRepository>()),
    );
    getIt.registerLazySingletonIfAbsent<GetDownloadItemUseCase>(
      () => GetDownloadItemUseCase(getIt<DownloadsRepository>()),
    );
    getIt.registerLazySingletonIfAbsent<PauseDownloadUseCase>(
      () => PauseDownloadUseCase(getIt<DownloadsRepository>()),
    );
    getIt.registerLazySingletonIfAbsent<ResumeDownloadUseCase>(
      () => ResumeDownloadUseCase(getIt<DownloadsRepository>()),
    );
    getIt.registerLazySingletonIfAbsent<RetryDownloadUseCase>(
      () => RetryDownloadUseCase(getIt<DownloadsRepository>()),
    );
    getIt.registerLazySingletonIfAbsent<ValidateDownloadedFileUseCase>(
      () => ValidateDownloadedFileUseCase(getIt<DownloadsRepository>()),
    );
    getIt.registerLazySingletonIfAbsent<CheckSurahDownloadedUseCase>(
      () => CheckSurahDownloadedUseCase(getIt<DownloadsRepository>()),
    );
    getIt.registerLazySingletonIfAbsent<ClearAllDownloadsUseCase>(
      () => ClearAllDownloadsUseCase(getIt<DownloadsRepository>()),
    );
    getIt.registerLazySingletonIfAbsent<DeleteDownloadUseCase>(
      () => DeleteDownloadUseCase(getIt<DownloadsRepository>()),
    );
    getIt.registerFactoryIfAbsent<CompletedDownloadFileValidator>(
      () => CompletedDownloadFileValidator(getIt<DownloadsRepository>()),
    );
    getIt.registerFactoryIfAbsent<CancelDownloadUseCase>(
      () => CancelDownloadUseCase(getIt<DownloadsRepository>()),
    );
    getIt.registerFactoryIfAbsent<DeleteReciterDownloadsUseCase>(
      () => DeleteReciterDownloadsUseCase(getIt<DownloadsRepository>()),
    );
    getIt.registerFactoryIfAbsent<GetDownloadsByReciterUseCase>(
      () => GetDownloadsByReciterUseCase(
        getIt<DownloadsRepository>(),
        getIt<RecitersRepository>(),
        getIt<CompletedDownloadFileValidator>(),
      ),
    );
    getIt.registerFactoryIfAbsent<GetValidCompletedDownloadsUseCase>(
      () => GetValidCompletedDownloadsUseCase(
        getIt<DownloadsRepository>(),
        getIt<RecitersRepository>(),
        getIt<CompletedDownloadFileValidator>(),
      ),
    );
    getIt.registerLazySingletonIfAbsent<PlayAllDownloadsUseCase>(
      () => PlayAllDownloadsUseCase(getIt<AudioPlayerHandler>()),
    );
    getIt.registerLazySingletonIfAbsent<PlayDownloadUseCase>(
      () => PlayDownloadUseCase(getIt<AudioPlayerHandler>()),
    );
    getIt.registerFactoryIfAbsent<DownloadsBloc>(
      () => DownloadsBloc(
        getDownloadsByReciter: getIt<GetDownloadsByReciterUseCase>(),
        downloadSurah: getIt<DownloadSurahUseCase>(),
        deleteDownload: getIt<DeleteDownloadUseCase>(),
        deleteReciterDownloads: getIt<DeleteReciterDownloadsUseCase>(),
        clearAllDownloads: getIt<ClearAllDownloadsUseCase>(),
        getTotalDownloadsSize: getIt<GetTotalDownloadsSizeUseCase>(),
        checkSurahDownloaded: getIt<CheckSurahDownloadedUseCase>(),
        validateDownloadedFile: getIt<ValidateDownloadedFileUseCase>(),
        getValidCompletedDownloads: getIt<GetValidCompletedDownloadsUseCase>(),
        checkDownloadAccess: getIt<CheckDownloadAccessUseCase>(),
        playDownload: getIt<PlayDownloadUseCase>(),
        playAllDownloads: getIt<PlayAllDownloadsUseCase>(),
        retryDownload: getIt<RetryDownloadUseCase>(),
        getDownloadItem: getIt<GetDownloadItemUseCase>(),
        cancelDownload: getIt<CancelDownloadUseCase>(),
        observeGlobalDownloadProgress:
            getIt<ObserveGlobalDownloadProgressUseCase>(),
        getDownloadStatus: getIt<GetDownloadStatusUseCase>(),
        removeFromDownloadQueue: getIt<RemoveFromDownloadQueueUseCase>(),
      ),
    );
  }
}
