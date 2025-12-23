import 'package:flutter/services.dart';
import 'package:injectable/injectable.dart';

import '../../../../main.dart';
import '../../domain/entities/download_item.dart';
import 'download_queue_manager.dart';
import 'download_service.dart';
import 'download_validator.dart';

/// Service responsible for recovering downloads from inconsistent states.
///
/// Handles:
/// - Orphaned pending downloads (app killed while pending)
/// - Stuck downloads (0% progress for too long)
/// - Background download verification
@LazySingleton()
class DownloadRecoveryService {
  DownloadRecoveryService(
    this._downloadService,
    this._validator,
    this._downloadQueueManager,
  );

  final DownloadService _downloadService;
  final DownloadValidator _validator;
  final DownloadQueueManager _downloadQueueManager;

  /// Handle a download that is marked as pending/downloading in DB
  /// but is NOT in the active queue or active list of DownloadService.
  Future<DownloadItem> handleOrphanedDownload(
    DownloadItem download, {
    required bool isQueued,
    required bool isActive,
  }) async {
    // Verify if it's really pending or if we missed a completion
    DownloadStatus? actualStatus;
    try {
      actualStatus = await _downloadService.getStatus(download.url);
    } catch (e) {
      logger.w(
        '[DownloadRecoveryService] Error checking status for orphaned download: $e',
      );
    }

    if (actualStatus == DownloadStatus.completed) {
      // It's completed! Check file existence to be sure
      final bool fileExists = await _validator.verifyFileExists(
        download.filePath,
      );
      if (fileExists) {
        logger.i(
          '[DownloadRecoveryService] Found orphaned pending download that is actually completed: id=${download.id} - Updating DB',
        );
        return download.copyWith(
          status: DownloadStatus.completed,
          progress: 1.0,
          completedAt: DateTime.now(),
        );
      }
    }

    if (actualStatus == DownloadStatus.downloading ||
        actualStatus == DownloadStatus.pending) {
      logger.i(
        '[DownloadRecoveryService] Found orphaned pending download that is already active in platform: id=${download.id} status=$actualStatus - Tracking in manager',
      );
      // Don't re-enqueue, just ensure the manager knows about it
      await _downloadQueueManager.enqueue(
        id: download.id,
        url: download.url,
        filePath: download.filePath,
        title: download.title,
        reciterName: download.reciterName,
        reciterId: download.reciterId,
      );
      return download;
    }

    logger.w(
      '[DownloadRecoveryService] Found orphaned pending download: id=${download.id} isQueued=$isQueued isActive=$isActive actualStatus=$actualStatus - Re-enqueueing',
    );

    // Re-enqueue (auto-resume)
    try {
      await _downloadQueueManager.enqueue(
        id: download.id,
        url: download.url,
        filePath: download.filePath,
        title: download.title,
        reciterName: download.reciterName,
        reciterId: download.reciterId,
      );
      // Keep as pending in the list
      return download;
    } catch (e) {
      logger.e(
        '[DownloadRecoveryService] Failed to re-enqueue orphaned download: id=${download.id} error=$e',
      );
      return download;
    }
  }

  /// Handle a download that is marked as active but might be stuck.
  Future<DownloadItem> handleStuckDownload(DownloadItem download) async {
    // Check if download is stuck at 0% for too long even though it's active
    final Duration timeSinceCreated = DateTime.now().difference(
      download.createdAt,
    );
    final bool isStuck =
        download.progress == 0.0 && timeSinceCreated.inSeconds > 30;

    if (!isStuck) {
      return download;
    }

    // Check the actual task status
    DownloadStatus? actualStatus;
    try {
      actualStatus = await _downloadService.getStatus(download.url);
    } on MissingPluginException {
      actualStatus = null;
    } catch (e) {
      logger.w(
        '[DownloadRecoveryService] Error getting status for stuck active download: $e',
      );
      actualStatus = null;
    }

    // If task is pending/enqueued but not running, retry it
    if (actualStatus == DownloadStatus.pending) {
      logger.w(
        '[DownloadRecoveryService] Active download stuck at 0% with pending status: id=${download.id} title="${download.title}" - retrying',
      );
      try {
        // Cancel the existing task
        try {
          await _downloadService.cancel(download.url);
        } catch (e) {
          logger.d(
            '[DownloadRecoveryService] Error canceling stuck active download: $e',
          );
        }

        // Remove from queue if it's there
        _downloadQueueManager.removeFromQueue(download.id);

        // Wait a bit before retrying
        await Future.delayed(const Duration(milliseconds: 500));

        // Retry the download using queue manager
        await _downloadQueueManager.enqueue(
          id: download.id,
          url: download.url,
          filePath: download.filePath,
          title: download.title,
          reciterName: download.reciterName,
        );

        // Update the download item with new timestamp
        return download.copyWith(createdAt: DateTime.now(), progress: 0.0);
      } catch (e) {
        // If retry fails, mark as failed
        logger.e(
          '[DownloadRecoveryService] Failed to retry stuck active download: id=${download.id} error=$e',
        );
        return download.copyWith(status: DownloadStatus.failed);
      }
    }

    return download;
  }

  /// Check status of a download that is NOT active in local service
  /// but might be running in background downloader.
  Future<DownloadItem> checkBackgroundStatus(DownloadItem download) async {
    // Download is NOT active in DownloadService
    // Check if it's actually still downloading in background_downloader
    DownloadStatus? backgroundStatus;
    try {
      backgroundStatus = await _downloadService.getStatus(download.url);
    } on MissingPluginException {
      // In test environment, skip status check
      backgroundStatus = null;
    } catch (e) {
      // Any other error - log and continue
      logger.w(
        '[DownloadRecoveryService] Error getting download status for ${download.id}: $e',
      );
      backgroundStatus = null;
    }

    if (backgroundStatus == DownloadStatus.downloading) {
      // Download is still active in background, update status
      if (download.status != DownloadStatus.downloading) {
        return download.copyWith(status: DownloadStatus.downloading);
      }
      return download;
    } else if (download.status == DownloadStatus.downloading) {
      // Was downloading but not active anymore - check if it completed or failed
      if (backgroundStatus == DownloadStatus.completed) {
        return _verifyCompletedDownload(download);
      } else if (backgroundStatus == DownloadStatus.failed) {
        // Download failed in background
        logger.w(
          '[DownloadRecoveryService] Download failed in background: id=${download.id} title="${download.title}"',
        );
        return download.copyWith(status: DownloadStatus.failed);
      } else {
        // Check if download is stuck at 0% for too long (more than 30 seconds)
        final Duration timeSinceCreated = DateTime.now().difference(
          download.createdAt,
        );
        final bool isStuck =
            download.progress == 0.0 &&
            timeSinceCreated.inSeconds > 30 &&
            (backgroundStatus == null ||
                backgroundStatus == DownloadStatus.pending);

        if (isStuck) {
          return _retryStuckBackgroundDownload(download);
        }
      }
    }
    return download;
  }

  Future<DownloadItem> _verifyCompletedDownload(DownloadItem download) async {
    // Download reported as completed - verify before marking as such
    // Check if file exists
    final bool fileExists = await _validator.verifyFileExists(
      download.filePath,
    );

    if (!fileExists) {
      logger.w(
        '[DownloadRecoveryService] Download reported as completed but file not found: id=${download.id} - marking as failed',
      );
      return download.copyWith(status: DownloadStatus.failed);
    }

    // Verify file size if we have it
    if (download.fileSize > 0) {
      try {
        final int? actualFileSize = await _validator.getActualFileSize(
          download.filePath,
        );

        if (actualFileSize == null) {
          throw Exception('File exists but size is null');
        }

        final int tolerance = (download.fileSize * 0.05)
            .round(); // Increased to 5% tolerance
        final int sizeDiff = (actualFileSize - download.fileSize).abs();

        if (sizeDiff > tolerance) {
          logger.w(
            '[DownloadRecoveryService] Download reported as completed but file size mismatch: '
            'expected=${download.fileSize} actual=$actualFileSize (diff=$sizeDiff, tolerance=$tolerance) - marking as failed',
          );
          return download.copyWith(status: DownloadStatus.failed);
        }
      } catch (e) {
        logger.e(
          '[DownloadRecoveryService] Error verifying file size: $e - keeping as downloading',
        );
        // If error verifying, maybe keep as is to be safe?
        // Original code kept it as downloading. logic: updatedDownloads.add(download); continue;
        return download;
      }
    }

    // All checks passed - mark as completed
    logger.d(
      '[DownloadRecoveryService] Download verified and marked as completed in sync: id=${download.id}',
    );
    return download.copyWith(
      status: DownloadStatus.completed,
      progress: 1.0,
      completedAt: DateTime.now(),
    );
  }

  Future<DownloadItem> _retryStuckBackgroundDownload(
    DownloadItem download,
  ) async {
    // Download is stuck - retry it
    logger.w(
      '[DownloadRecoveryService] Stuck background download: id=${download.id} title="${download.title}" - retrying',
    );
    try {
      // Cancel the existing task if it exists
      try {
        await _downloadService.cancel(download.url);
      } catch (e) {
        // Ignore errors when canceling (task might not exist)
        logger.d(
          '[DownloadRecoveryService] Error canceling stuck download: $e',
        );
      }

      // Remove from queue if it's there
      _downloadQueueManager.removeFromQueue(download.id);

      // Wait a bit before retrying
      await Future.delayed(const Duration(milliseconds: 500));

      // Retry the download using queue manager
      await _downloadQueueManager.enqueue(
        id: download.id,
        url: download.url,
        filePath: download.filePath,
        title: download.title,
        reciterName: download.reciterName,
        reciterId: download.reciterId,
      );

      // Update the download item with new timestamp
      return download.copyWith(createdAt: DateTime.now(), progress: 0.0);
    } catch (e) {
      // If retry fails, mark as failed
      logger.e(
        '[DownloadRecoveryService] Failed to retry stuck download: id=${download.id} error=$e',
      );
      return download.copyWith(status: DownloadStatus.failed);
    }
  }
}
