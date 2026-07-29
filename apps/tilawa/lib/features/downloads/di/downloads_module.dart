import 'package:disk_space_plus/disk_space_plus.dart';
import 'package:get_it/get_it.dart';
import 'package:tilawa/core/di/get_it_idempotent.dart';
import 'package:tilawa_core/network/network_info.dart';

import '../data/services/batch_download_manager.dart';
import '../data/services/download_queue_manager.dart';
import '../domain/repositories/batch_download_repository.dart';
import '../domain/repositories/download_query_repository.dart';
import '../domain/repositories/downloads_repository.dart';
import '../domain/repositories/single_download_repository.dart';
import '../domain/services/batch_download_service_interface.dart';
import '../domain/services/download_queue_service_interface.dart';
import '../domain/usecases/usecases.dart';
import '../presentation/bloc/download_button/download_button_bloc_factory.dart';

class DownloadsModule {
  DownloadsModule._();

  static void register(GetIt getIt) {
    getIt.registerLazySingletonIfAbsent<DiskSpacePlus>(DiskSpacePlus.new);
    getIt.registerLazySingletonIfAbsent<SingleDownloadRepository>(
      () => getIt<DownloadsRepository>(),
    );
    getIt.registerLazySingletonIfAbsent<BatchDownloadRepository>(
      () => getIt<DownloadsRepository>(),
    );
    getIt.registerLazySingletonIfAbsent<DownloadQueryRepository>(
      () => getIt<DownloadsRepository>(),
    );
    getIt.registerLazySingletonIfAbsent<IDownloadQueueService>(
      () => getIt<DownloadQueueManager>(),
    );
    getIt.registerLazySingletonIfAbsent<IBatchDownloadService>(
      () => getIt<BatchDownloadManager>(),
    );
    getIt.registerLazySingletonIfAbsent<DownloadButtonBlocFactory>(
      () => DownloadButtonBlocFactory(
        checkSurahDownloaded: getIt<CheckSurahDownloadedUseCase>(),
        downloadSurah: getIt<DownloadSurahUseCase>(),
        cancelDownload: getIt<CancelDownloadUseCase>(),
        pauseDownload: getIt<PauseDownloadUseCase>(),
        resumeDownload: getIt<ResumeDownloadUseCase>(),
        observeDownloadProgress: getIt<ObserveDownloadProgressUseCase>(),
        getDownloadItem: getIt<GetDownloadItemUseCase>(),
        networkInfo: getIt<NetworkInfo>(),
        checkLowDeviceStorage: getIt<CheckLowDeviceStorageUseCase>(),
      ),
    );
  }
}
