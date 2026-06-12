import 'package:disk_space_plus/disk_space_plus.dart';
import 'package:injectable/injectable.dart';
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

@module
abstract class DownloadsModule {
  @lazySingleton
  DiskSpacePlus diskSpacePlus() => DiskSpacePlus();

  @lazySingleton
  SingleDownloadRepository singleDownloadRepository(DownloadsRepository repo) =>
      repo;

  @lazySingleton
  BatchDownloadRepository batchDownloadRepository(DownloadsRepository repo) =>
      repo;

  @lazySingleton
  DownloadQueryRepository downloadQueryRepository(DownloadsRepository repo) =>
      repo;

  @lazySingleton
  IDownloadQueueService downloadQueueService(DownloadQueueManager manager) =>
      manager;

  @lazySingleton
  IBatchDownloadService batchDownloadService(BatchDownloadManager manager) =>
      manager;

  @lazySingleton
  DownloadButtonBlocFactory downloadButtonBlocFactory(
    CheckSurahDownloadedUseCase checkSurahDownloaded,
    DownloadSurahUseCase downloadSurah,
    CancelDownloadUseCase cancelDownload,
    PauseDownloadUseCase pauseDownload,
    ResumeDownloadUseCase resumeDownload,
    ObserveDownloadProgressUseCase observeDownloadProgress,
    GetDownloadItemUseCase getDownloadItem,
    NetworkInfo networkInfo,
    CheckLowDeviceStorageUseCase checkLowDeviceStorage,
  ) =>
      DownloadButtonBlocFactory(
        checkSurahDownloaded: checkSurahDownloaded,
        downloadSurah: downloadSurah,
        cancelDownload: cancelDownload,
        pauseDownload: pauseDownload,
        resumeDownload: resumeDownload,
        observeDownloadProgress: observeDownloadProgress,
        getDownloadItem: getDownloadItem,
        networkInfo: networkInfo,
        checkLowDeviceStorage: checkLowDeviceStorage,
      );
}
