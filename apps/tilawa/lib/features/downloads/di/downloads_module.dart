import 'package:injectable/injectable.dart';

import '../data/services/batch_download_manager.dart';
import '../data/services/download_queue_manager.dart';
import '../domain/repositories/batch_download_repository.dart';
import '../domain/repositories/download_query_repository.dart';
import '../domain/repositories/downloads_repository.dart';
import '../domain/repositories/single_download_repository.dart';
import '../domain/services/batch_download_service_interface.dart';
import '../domain/services/download_queue_service_interface.dart';

@module
abstract class DownloadsModule {
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
}
