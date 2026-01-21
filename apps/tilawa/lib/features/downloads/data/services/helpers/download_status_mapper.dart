import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:injectable/injectable.dart';

import '../../../domain/entities/download_item.dart';

@lazySingleton
class DownloadStatusMapper {
  /// Map FlutterDownloader task status to app-level status.
  DownloadStatus mapTaskStatusToDownloadStatus(DownloadTaskStatus status) {
    return switch (status) {
      DownloadTaskStatus.enqueued => DownloadStatus.pending,
      DownloadTaskStatus.running => DownloadStatus.downloading,
      DownloadTaskStatus.complete => DownloadStatus.completed,
      DownloadTaskStatus.failed => DownloadStatus.failed,
      DownloadTaskStatus.canceled => DownloadStatus.cancelled,
      DownloadTaskStatus.paused => DownloadStatus.paused,
      _ => DownloadStatus.failed,
    };
  }
}
