import 'package:flutter/services.dart';
import 'package:injectable/injectable.dart';

import 'package:tilawa/core/logging/app_logger.dart';
import '../../domain/entities/download_item.dart';
import 'download_queue_manager.dart';
import 'download_recovery_service.dart';
import 'download_service_interface.dart';

/// Service responsible for synchronizing local download state with the platform's
/// active downloads and the download queue.
@LazySingleton()
class DownloadStatusSynchronizer {
  DownloadStatusSynchronizer(
    this._downloadService,
    this._recoveryService,
    this._downloadQueueManager,
  );

  final DownloadServiceInterface _downloadService;
  final DownloadRecoveryService _recoveryService;
  final DownloadQueueManager _downloadQueueManager;

  /// Synchronizes a list of downloads with the current state of the download service
  /// and queue manager.
  ///
  /// This method:
  /// 1. Updates statuses for actively running downloads
  /// 2. Updates statuses for queued downloads
  /// 3. Detects and recovers orphaned/stuck downloads
  Future<List<DownloadItem>> syncDownloadStatuses(
    List<DownloadItem> downloads,
  ) async {
    // Sync status with active downloads in DownloadService and queue manager
    // This ensures that downloads that are actively downloading or queued show the correct status
    List<String> activeDownloadIds;
    try {
      activeDownloadIds = await _downloadService.getActiveDownloadIds();
    } on MissingPluginException {
      // In test environment, platform channels are not available
      // Skip status syncing and return downloads as-is (or maybe just queue sync)
      logger.d(
        '[DownloadStatusSynchronizer] Skipping active status sync - platform channels not available (test environment)',
      );
      activeDownloadIds = [];
    } catch (e) {
      // Any other error - log and continue without syncing active status
      logger.w(
        '[DownloadStatusSynchronizer] Error getting active downloads: $e',
      );
      activeDownloadIds = [];
    }

    // Get queued download IDs from queue manager
    final Set<String> queuedIds = {};
    try {
      for (final download in downloads) {
        if (_downloadQueueManager.isQueued(download.id)) {
          queuedIds.add(download.id);
        }
      }
    } catch (e) {
      logger.w('[DownloadStatusSynchronizer] Error checking queue status: $e');
    }

    final updatedDownloads = <DownloadItem>[];

    for (final download in downloads) {
      final bool isActive = activeDownloadIds.contains(download.url);
      final bool isQueued = queuedIds.contains(download.id);

      // Update status for queued downloads
      if (isQueued && download.status != DownloadStatus.pending) {
        final DownloadItem updatedDownload = download.copyWith(
          status: DownloadStatus.pending,
        );
        updatedDownloads.add(updatedDownload);

        continue;
      }

      // Check for orphaned pending downloads (Pending in DB, but not in queue and not active)
      if (download.status == DownloadStatus.pending && !isQueued && !isActive) {
        final DownloadItem recovered = await _recoveryService
            .handleOrphanedDownload(
              download,
              isQueued: isQueued,
              isActive: isActive,
            );

        updatedDownloads.add(recovered);
        continue;
      }

      if (isActive) {
        // active in platform
        if (download.status != DownloadStatus.downloading) {
          final DownloadItem updatedDownload = download.copyWith(
            status: DownloadStatus.downloading,
          );
          updatedDownloads.add(updatedDownload);
        } else {
          // Check if stuck
          final DownloadItem recovered = await _recoveryService
              .handleStuckDownload(download);

          updatedDownloads.add(recovered);
        }
      } else {
        // NOT active in platform surface (getActiveDownloadIds)
        // Check background status or verify completion
        final DownloadItem recovered = await _recoveryService
            .checkBackgroundStatus(download);

        updatedDownloads.add(recovered);
      }
    }

    return updatedDownloads;
  }
}
