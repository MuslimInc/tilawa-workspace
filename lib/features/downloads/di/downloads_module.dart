import 'package:injectable/injectable.dart';

import '../domain/repositories/batch_download_repository.dart';
import '../domain/repositories/download_query_repository.dart';
import '../domain/repositories/downloads_repository.dart';
import '../domain/repositories/single_download_repository.dart';

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
}
