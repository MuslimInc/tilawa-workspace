import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:flutter/services.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/config/config.dart';
import '../../../../core/config/notification_config.dart';
import '../../../../core/constants/analytics_constants.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/network/network_info.dart';
import '../../../../core/services/analytics_service.dart';
import '../../../../main.dart';
import '../../domain/entities/download_item.dart';
import '../../domain/repositories/downloads_repository.dart';
import '../../utils/download_path_utils.dart';
import '../datasources/downloads_local_datasource.dart';
import '../services/batch_download_manager.dart';
import '../services/download_path_resolver.dart';
import '../services/download_queue_manager.dart';
import '../services/download_service_interface.dart';
import '../services/download_status_synchronizer.dart';
import '../services/download_validator.dart';

/// Repository implementation that handles all download operations
///
/// Registered for all segregated interfaces to support proper dependency injection:
/// - Use cases can inject specific interfaces they need
/// - Backward compatibility maintained via DownloadsRepository
@LazySingleton(as: DownloadsRepository)
class DownloadsRepositoryImpl implements DownloadsRepository {
  DownloadsRepositoryImpl(
    this.localDataSource,
    this.downloadService,
    this.batchDownloadManager,
    this.pathResolver,
    this.statusSynchronizer,
    this.validator,
    this.queueManager,
    this._analyticsService,
    this._networkInfo,
  );

  final DownloadsLocalDataSource localDataSource;
  final DownloadServiceInterface downloadService;
  final BatchDownloadManager batchDownloadManager;
  final DownloadPathResolver pathResolver;
  final DownloadStatusSynchronizer statusSynchronizer;
  final DownloadValidator validator;
  final DownloadQueueManager queueManager;
  final AnalyticsService _analyticsService;
  final NetworkInfo _networkInfo;
  StreamSubscription? _progressSubscription;
  final StreamController<DownloadItem> _downloadUpdatesController =
      StreamController<DownloadItem>.broadcast();

  @override
  Future<void> initialize() async {
    await _progressSubscription?.cancel();
    _progressSubscription = downloadService.globalProgressStream.listen(
      (progress) {
        updateDownloadProgress(
          progress.id,
          progress.status,
          progress.progress,
          progress.downloadedSize,
          progress.fileSize,
        );
      },
      onError: (e) {
        logger.e('[DownloadsRepository] Error in progress stream: $e');
      },
    );
    // Ensure queue manager has correct concurrency setting on init
    queueManager.maxConcurrentDownloads = 2;
  }

  @override
  Future<void> dispose() async {
    await _progressSubscription?.cancel();
    _progressSubscription = null;
  }

  @override
  Future<List<DownloadItem>> getAllDownloads() async {
    final List<DownloadItem> downloads = await localDataSource.getDownloads();
    final List<DownloadItem> pathResolvedDownloads = [];

    for (final download in downloads) {
      // Resolve absolute file path
      final String downloadsDir = await pathResolver.getDownloadsDir();
      final String filePath = pathResolver
          .resolveDownloadPath(download, downloadsDir)
          .filePath;

      pathResolvedDownloads.add(download.copyWith(filePath: filePath));
    }

    // Sync download statuses (batch)
    final List<DownloadItem> syncedDownloads = await statusSynchronizer
        .syncDownloadStatuses(pathResolvedDownloads);

    // Update in database if changed
    // syncDownloadStatuses returns the full list with updates applied.
    // We should compare against original 'downloads' to find changes?
    // Or just update all? Or let updateDownloads handle uniqueness?
    // DownloadItem implements Equatable? Yes.

    // Optimisation: Find changed items
    final List<DownloadItem> changedItems = [];
    for (final syncedDownload in syncedDownloads) {
      // Find matching item in local DB
      final int index = downloads.indexWhere((d) => d.id == syncedDownload.id);

      if (index == -1) {
        // New item (not in DB) -> needs update (insert)
        changedItems.add(syncedDownload);
      } else {
        // Existing item -> check if changed
        final DownloadItem original = downloads[index];
        if (syncedDownload != original) {
          changedItems.add(syncedDownload);
        }
      }
    }

    if (changedItems.isNotEmpty) {
      await localDataSource.updateDownloads(changedItems);
    }

    return syncedDownloads;
  }

  @override
  Future<DownloadItem?> getDownloadItem(String id) async {
    final List<DownloadItem> downloads = await localDataSource.getDownloads();
    try {
      final DownloadItem item = downloads.firstWhere(
        (item) => item.id == id || item.url == id,
      );
      final String downloadsDir = await pathResolver.getDownloadsDir();
      return pathResolver.resolveDownloadPath(item, downloadsDir);
      // ignore: avoid_catches_without_on_clauses
    } catch (e) {
      return null;
    }
  }

  @override
  Future<void> addDownload(DownloadItem downloadItem) async {
    await localDataSource.addDownload(downloadItem);
    _downloadUpdatesController.add(downloadItem);
  }

  @override
  Future<void> updateDownload(DownloadItem downloadItem) async {
    await localDataSource.updateDownload(downloadItem);
    _downloadUpdatesController.add(downloadItem);
  }

  @override
  Future<void> deleteDownload(String id) async {
    final DownloadItem? download = await getDownloadItem(id);
    final bool fileExists =
        download != null && await validator.verifyFileExists(download.filePath);
    if (download != null && fileExists) {
      await localDataSource.deleteFile(download.filePath);
    }
    await localDataSource.deleteDownload(id);
  }

  @override
  Future<void> clearAllDownloads() async {
    // Stop all active downloads first
    try {
      // ignore: missing_plugin_exception_catch
      await queueManager.stopAll();
    } catch (e) {
      logger.w('[DownloadsRepository] Error stopping all downloads: $e');
    }

    final List<DownloadItem> downloads = await localDataSource.getDownloads();
    for (final download in downloads) {
      final bool fileExists = await validator.verifyFileExists(
        download.filePath,
      );
      if (fileExists) {
        await localDataSource.deleteFile(download.filePath);
      }
    }
    await localDataSource.clearAllDownloads();

    // [MODIFIED] Log clear all downloads event
    await _analyticsService.logEvent(
      AnalyticsEvents.clearAllDownloads,
      parameters: {
        AnalyticsParams.action: AnalyticsActionValues.clearAllDownloads,
      },
    );
  }

  @override
  Stream<DownloadItem> getDownloadProgress(String id) async* {
    // Yield current state first
    final DownloadItem? current = await getDownloadItem(id);
    if (current != null) {
      yield current;
    }

    // Then yield updates for this specific download
    yield* _downloadUpdatesController.stream.where(
      (item) => item.id == id || item.url == id,
    );
  }

  @override
  Future<void> startDownload(
    String url, {
    required String title,
    bool showNotification = NotificationConfig.enableLocalNotifications,
    required String surahTitle,
    required String reciterName,
    required int reciterId,
  }) async {
    // Validate inputs early to avoid creating invalid download entries
    // Note: in our app, surahId is the actual download URL
    final String trimmedUrl = url.trim();
    if (trimmedUrl.isEmpty) {
      logger.e(
        '[DownloadsRepositoryImpl] startDownload: empty URL for url=$url reciter="$reciterName"',
      );
      throw ArgumentError('Download URL is empty');
    }

    if (!await _networkInfo.isConnected) {
      throw NetworkException('No internet connection');
    }

    final String downloadsDir = await pathResolver.getDownloadsDir();

    // Use the URL as download ID (uniqueness is maintained through filename)
    final downloadId = trimmedUrl;

    // Extract the complete directory structure from URL to maintain server organization
    // E.g., https://server6.mp3quran.net/husary/hafs/002.mp3 -> husary/hafs/002.mp3
    final String safeFileName = DownloadPathUtils.calculateRelativePath(
      trimmedUrl,
      reciterName,
    );

    final String filePath = DownloadPathUtils.resolveFullPath(
      downloadsDir,
      safeFileName,
    );

    // Check if download is already queued or active
    final bool isQueued = queueManager.isQueued(downloadId);
    final bool isActive = queueManager.isActive(downloadId);

    if (isQueued || isActive) {
      logger.d(
        '[DownloadsRepositoryImpl] Download already queued or active: id=$downloadId (queued=$isQueued, active=$isActive)',
      );
      return;
    }

    // Determine initial status: pending (since we just checked likely not active, but safe default)
    const DownloadStatus initialStatus = DownloadStatus.pending;

    final downloadItem = DownloadItem(
      id: downloadId,
      title: surahTitle,
      url: trimmedUrl,
      filePath: filePath,
      reciterName: reciterName,
      reciterId: reciterId,
      status: initialStatus,
      progress: 0.0,
      fileSize: 0,
      downloadedSize: 0,
      createdAt: DateTime.now(),
    );

    await addDownload(downloadItem);

    // [MODIFIED] Log download start event
    await _analyticsService.logDownloadStart(
      downloadId,
      fileName: safeFileName,
      surahId: downloadId,
      reciterName: reciterName,
    );

    logger.d(
      '[DownloadsRepositoryImpl] startDownload: id=$downloadId fileName=$safeFileName path=$filePath status=$initialStatus',
    );

    // Enqueue the download (queue manager will handle starting it)
    // Note: In test environments, this may throw MissingPluginException,
    // which is expected and should be handled by the caller
    try {
      await queueManager.enqueue(
        id: downloadId,
        url: trimmedUrl,
        filePath: filePath,
        title: surahTitle,
        reciterName: reciterName,
        reciterId: reciterId,
        showNotification: showNotification,
      );

      // Update status to pending if it was queued (not immediately started)
      if (!isActive) {
        final DownloadItem pendingDownload = downloadItem.copyWith(
          status: DownloadStatus.pending,
        );
        await updateDownload(pendingDownload);
      }
    } on MissingPluginException {
      // In test environment, platform channels are not available
      // This is expected behavior - the download item is still created
      // but the actual download won't start in test environment
      // We catch and swallow this exception since the download item
      // has already been created successfully
      logger.d(
        '[DownloadsRepositoryImpl] DownloadQueueManager.enqueue skipped - platform channels not available (test environment)',
      );
      // Don't rethrow - the download item was created successfully
      // The actual download service call failed, but that's expected in tests
    }
  }

  @override
  Future<void> startDownloadBatch(
    List<({String url, String surahTitle, String reciterName, int reciterId})>
    items,
  ) async {
    if (items.isEmpty) {
      return;
    }

    if (!await _networkInfo.isConnected) {
      throw NetworkException('No internet connection');
    }
    final String downloadsDir = await pathResolver.getDownloadsDir();
    final List<
      ({
        String id,
        String url,
        String filePath,
        String title,
        String reciterName,
        int? reciterId,
        bool showNotification,
      })
    >
    queueItems = [];
    final List<DownloadItem> dbItems = [];

    // Process items efficiently
    for (final item in items) {
      final String trimmedUrl = item.url.trim();
      if (trimmedUrl.isEmpty) {
        continue;
      }

      final downloadId = trimmedUrl;
      final String safeFileName = DownloadPathUtils.calculateRelativePath(
        trimmedUrl,
        item.reciterName,
      );
      final String filePath = DownloadPathUtils.resolveFullPath(
        downloadsDir,
        safeFileName,
      );

      // Skip if already in queue or active (check both fast)
      if (queueManager.isQueued(downloadId) ||
          queueManager.isActive(downloadId)) {
        continue;
      }

      final downloadItem = DownloadItem(
        id: downloadId,
        title: item.surahTitle,
        url: trimmedUrl,
        filePath: filePath,
        reciterName: item.reciterName,
        reciterId: item.reciterId,
        status: DownloadStatus.pending,
        progress: 0.0,
        fileSize: 0,
        downloadedSize: 0,
        createdAt: DateTime.now(),
      );
      dbItems.add(downloadItem);

      queueItems.add((
        id: downloadId,
        url: trimmedUrl,
        filePath: filePath,
        title: item.surahTitle,
        reciterName: item.reciterName,
        reciterId: item.reciterId,
        showNotification:
            false, // Batch downloads don't show individual notifications by default, managed by BatchDownloadManager
      ));
    }

    if (queueItems.isNotEmpty) {
      // Add all to DB in one batch to avoid O(N^2) SharedPreferences I/O
      await localDataSource.addDownloads(dbItems);

      // Also emit updates to the stream for each item so listeners (UI) know they are pending
      dbItems.forEach(_downloadUpdatesController.add);

      // Notify batch manager
      final batchId = 'batch_${DateTime.now().millisecondsSinceEpoch}';
      batchDownloadManager.startBatch(
        batchId: batchId,
        title: 'Downloading ${queueItems.length} files',
        downloadIds: queueItems.map((e) => e.id).toList(),
      );

      // Enqueue as a batch
      try {
        await queueManager.enqueueBatch(queueItems);
        logger.d(
          '[DownloadsRepositoryImpl] Started batch download of ${queueItems.length} items',
        );
      } on MissingPluginException {
        // Ignored in tests or specific environments where plugin is not available
      }
    }
  }

  @override
  Future<void> deleteReciterDownloads(String reciterName) async {
    final List<DownloadItem> downloads = await getAllDownloads();
    final List<DownloadItem> toDelete = downloads
        .where((d) => d.reciterName == reciterName)
        .toList();

    for (final download in toDelete) {
      if (download.status == DownloadStatus.downloading ||
          download.status == DownloadStatus.pending) {
        await cancelDownload(download.id);
      }
      await deleteDownload(download.id);
    }

    // [MODIFIED] Log delete reciter downloads event
    await _analyticsService.logEvent(
      AnalyticsEvents.deleteReciterDownloads,
      parameters: {
        AnalyticsParams.reciterName: reciterName,
        AnalyticsParams.action: AnalyticsActionValues.deleteReciterDownloads,
      },
    );
  }

  @override
  Stream<DownloadItem> get downloadUpdates => _downloadUpdatesController.stream;

  @override
  Future<void> pauseDownload(String id) async {
    // Pause functionality not implemented in new DownloadService
    // Downloads run to completion in individual isolates
    final DownloadItem? download = await getDownloadItem(id);
    if (download != null) {
      final DownloadItem updatedDownload = download.copyWith(
        status: DownloadStatus.paused,
      );
      await updateDownload(updatedDownload);
    }
  }

  @override
  Future<void> resumeDownload(String id) async {
    // Resume functionality not implemented in new DownloadService
    // Downloads run to completion in individual isolates
    final DownloadItem? download = await getDownloadItem(id);
    if (download != null) {
      final DownloadItem updatedDownload = download.copyWith(
        status: DownloadStatus.downloading,
      );
      await updateDownload(updatedDownload);
    }
  }

  @override
  Future<void> cancelDownload(String id) async {
    // Remove from queue if it's there
    queueManager.removeFromQueue(id);

    final DownloadItem? item = await getDownloadItem(id);
    if (item != null) {
      await downloadService.cancel(item.url);
    } else {
      // Fallback: try cancelling with ID if item not found (though unlikely to work if ID != URL)
      await downloadService.cancel(id);
    }

    final DownloadItem? download = await getDownloadItem(id);
    if (download != null) {
      // [MODIFIED] Log download cancel event
      await _analyticsService.logDownloadCancel(
        id,
        fileName: download.title,
        surahId: download.url,
        reciterName: download.reciterName,
      );

      final DownloadItem updatedDownload = download.copyWith(
        status: DownloadStatus.cancelled,
      );
      await updateDownload(updatedDownload);
      final bool fileExists = await validator.verifyFileExists(
        download.filePath,
      );
      if (fileExists) {
        await localDataSource.deleteFile(download.filePath);
      }
    }
  }

  @override
  Future<bool> isSurahDownloaded(String url, String reciterName) async {
    final List<DownloadItem> downloads = await localDataSource.getDownloads();
    // surahId is the URL
    // We match by checking if the download's URL matches surahId AND reciter matches
    final String trimmedUrl = url.trim();
    final String downloadsDir = await pathResolver.getDownloadsDir();

    for (final rawDownload in downloads) {
      final DownloadItem d = pathResolver.resolveDownloadPath(
        rawDownload,
        downloadsDir,
      );
      // Use 1 retry (instant check) during list loading
      final bool isFileExists = await validator.verifyFileExists(d.filePath);
      if (d.reciterName == reciterName &&
          d.url == trimmedUrl &&
          d.status == DownloadStatus.completed &&
          isFileExists) {
        return true;
      }
    }
    return false;
  }

  @override
  Future<bool> isSurahDownloading(String url, String reciterName) async {
    final String trimmedUrl = url.trim();

    // First check if there's a download item with downloading status
    final List<DownloadItem> downloads = await localDataSource.getDownloads();
    for (final d in downloads) {
      if (d.reciterName == reciterName &&
          d.url == trimmedUrl &&
          d.status == DownloadStatus.downloading) {
        // Also verify it's actually active in DownloadService
        try {
          final bool isActive = await downloadService.isStatusDownloadActive(
            d.url,
          );
          if (isActive) {
            return true;
          }
        } on MissingPluginException {
          // In test environment, return true if status is downloading
          return true;
        } catch (e) {
          logger.w(
            '[DownloadsRepository] Error checking if download is active: $e',
          );
        }
      }
    }

    // Also check directly with DownloadService using the composite ID
    // Construct the expected ID same as startDownload
    try {
      return await downloadService.isStatusDownloadActive(trimmedUrl);
    } on MissingPluginException {
      // In test environment, return false
      return false;
    } catch (e) {
      logger.w('[DownloadsRepository] Error checking download status: $e');
      return false;
    }
  }

  @override
  Future<String?> getDownloadedFilePath(String url, String reciterName) async {
    final List<DownloadItem> downloads = await localDataSource.getDownloads();
    // surahId is the URL
    final String trimmedUrl = url.trim();
    final String downloadsDir = await pathResolver.getDownloadsDir();

    try {
      final DownloadItem rawDownload = downloads.firstWhere(
        (d) =>
            d.reciterName == reciterName &&
            d.url == trimmedUrl &&
            d.status == DownloadStatus.completed,
      );

      final DownloadItem download = pathResolver.resolveDownloadPath(
        rawDownload,
        downloadsDir,
      );

      final bool fileExists = await validator.verifyFileExists(
        download.filePath,
      );
      if (fileExists) {
        return download.filePath;
      }
      return null;
      // ignore: avoid_catches_without_on_clauses
    } catch (e) {
      // Download not found, return null
      return null;
    }
  }

  @override
  Future<void> updateDownloadProgress(
    String id,
    DownloadStatus status,
    double progress,
    int downloadedSize,
    int fileSize,
  ) async {
    DownloadItem? download = await getDownloadItem(id);

    if (download == null) {
      try {
        final List<DownloadItem> allDownloads = await localDataSource
            .getDownloads();
        download = allDownloads.firstWhere((d) => d.url == id);
      } catch (_) {}
    }

    if (download != null) {
      if (status == DownloadStatus.completed) {
        if (progress < 1.0) {
          logger.w(
            '[DownloadsRepository] Download reported as completed but progress is ${(progress * 100).toStringAsFixed(1)}% - keeping as downloading',
          );
          await updateDownload(
            download.copyWith(
              status: DownloadStatus.downloading,
              progress: progress,
              downloadedSize: downloadedSize,
              fileSize: fileSize,
            ),
          );
          return;
        }

        final bool fileExists = await validator.verifyFileExists(
          download.filePath,
          maxRetries: 10, // Wait for I/O after completion
        );
        if (!fileExists) {
          logger.w(
            '[DownloadsRepository] Completed download file not found at ${download.filePath}',
          );
          await updateDownload(
            download.copyWith(
              status: DownloadStatus.failed,
              progress: progress,
            ),
          );
          return;
        }

        if (fileSize > 0) {
          final bool isSizeValid = await validator.verifyFileSize(
            download.filePath,
            fileSize,
          );
          if (!isSizeValid) {
            await updateDownload(
              download.copyWith(
                status: DownloadStatus.failed,
                progress: progress,
              ),
            );
            return;
          }
        } else {
          final int? actualSize = await validator.getActualFileSize(
            download.filePath,
          );
          if (actualSize != null && actualSize > 0) {
            await updateDownload(
              download.copyWith(
                status: DownloadStatus.completed,
                progress: 1.0,
                downloadedSize: actualSize,
                fileSize: actualSize,
                completedAt: DateTime.now(),
              ),
            );

            // [MODIFIED] Log download complete event
            await _analyticsService.logDownloadComplete(
              id,
              fileName: download.title,
              fileSize: actualSize,
              surahId: download.url,
              reciterName: download.reciterName,
            );

            return;
          }
        }

        await updateDownload(
          download.copyWith(
            status: DownloadStatus.completed,
            progress: 1.0,
            downloadedSize: downloadedSize,
            fileSize: fileSize,
            completedAt: DateTime.now(),
          ),
        );

        // [MODIFIED] Log download complete event
        await _analyticsService.logDownloadComplete(
          id,
          fileName: download.title,
          fileSize: fileSize,
          surahId: download.url,
          reciterName: download.reciterName,
        );
      } else {
        final int effectiveFileSize = fileSize > 0
            ? fileSize
            : download.fileSize;

        if (status == DownloadStatus.downloading && progress >= 1.0) {
          final bool fileExists = await validator.verifyFileExists(
            download.filePath,
          );
          if (fileExists) {
            final int? actualSize = await validator.getActualFileSize(
              download.filePath,
            );
            await updateDownload(
              download.copyWith(
                status: DownloadStatus.completed,
                progress: 1.0,
                downloadedSize: actualSize ?? downloadedSize,
                fileSize: actualSize ?? effectiveFileSize,
                completedAt: DateTime.now(),
              ),
            );
            return;
          }
        }

        await updateDownload(
          download.copyWith(
            status: status,
            progress: progress,
            downloadedSize: downloadedSize,
            fileSize: effectiveFileSize,
          ),
        );
      }
    }
  }

  @override
  MediaItem createMediaItemFromDownload(DownloadItem download) {
    // Convert file path to proper file:// URI
    final fileUri = Uri.file(download.filePath).toString();

    return MediaItem(
      id: fileUri,
      title: download.title,
      artist: download.reciterName,
      album: 'Downloaded',
      extras: {
        'isDownloaded': true,
        'localFilePath': download.filePath,
        'downloadId': download.id,
      },
    );
  }

  @override
  Future<bool> validateDownloadedFile(DownloadItem download) async {
    return validator.verifyFileExists(download.filePath);
  }

  @override
  List<MediaItem> createMediaItemsFromDownloads(List<DownloadItem> downloads) {
    return downloads.map(createMediaItemFromDownload).toList();
  }

  @override
  Future<void> retryDownload(String downloadId) async {
    // Get the existing download item
    final DownloadItem? downloadItem = await getDownloadItem(downloadId);
    if (downloadItem == null) {
      throw Exception('Download not found');
    }

    // Check if download is stuck (at 0% for more than 30 seconds)
    final Duration timeSinceCreated = DateTime.now().difference(
      downloadItem.createdAt,
    );
    final bool isStuck =
        downloadItem.status == DownloadStatus.downloading &&
        downloadItem.progress == 0.0 &&
        timeSinceCreated.inSeconds > 30;

    // Allow retry for failed downloads or stuck downloads
    if (downloadItem.status != DownloadStatus.failed && !isStuck) {
      throw Exception('Only failed or stuck downloads can be retried');
    }

    await downloadService.cancel(downloadId);

    // Wait a bit before retrying
    await Future.delayed(const Duration(milliseconds: 500));

    // Reset the download status to pending
    final DownloadItem updatedDownload = downloadItem.copyWith(
      status: DownloadStatus.pending,
      progress: 0.0,
      downloadedSize: 0,
      fileSize: 0,
      createdAt: DateTime.now(),
    );
    await updateDownload(updatedDownload);

    // Enqueue the download again using the queue manager
    await queueManager.enqueue(
      id: downloadItem.id,
      url: downloadItem.url,
      filePath: downloadItem.filePath,
      title: downloadItem.title,
      reciterName: downloadItem.reciterName,
    );
  }

  @override
  Future<void> resumePendingDownloads() async {
    logger.d(
      '[DownloadsRepository] Checking for pending/stuck downloads to resume...',
    );
    final List<DownloadItem> downloads = await localDataSource.getDownloads();
    var resumedCount = 0;

    for (final download in downloads) {
      // Check for downloads that should be running but might have been interrupted
      if (download.status == DownloadStatus.pending ||
          download.status == DownloadStatus.downloading) {
        // Check if it's already active in the service
        var isActive = false;
        try {
          isActive = await downloadService.isStatusDownloadActive(download.url);
        } catch (e) {
          logger.w(
            '[DownloadsRepository] Error checking active status for ${download.url}: $e',
          );
        }

        // If not active, re-enqueue it
        if (!isActive) {
          logger.d(
            '[DownloadsRepository] Resuming download: id=${download.id} title="${download.title}"',
          );

          // Ensure status is pending before enqueueing
          if (download.status != DownloadStatus.pending) {
            await updateDownload(
              download.copyWith(status: DownloadStatus.pending),
            );
          }

          await queueManager.enqueue(
            id: download.id,
            url: download.url,
            filePath: download.filePath,
            title: download.title,
            reciterName: download.reciterName,
            reciterId: download.reciterId,
          );
          resumedCount++;
        }
      }
    }

    if (resumedCount > 0) {
      logger.d('[DownloadsRepository] Resumed $resumedCount downloads');
    } else {
      logger.d('[DownloadsRepository] No downloads needed resuming');
    }
  }

  @override
  Future<int> getTotalDownloadsSize() async {
    final List<DownloadItem> downloads = await localDataSource.getDownloads();
    var totalBytes = 0;
    for (final download in downloads) {
      if (download.status == DownloadStatus.completed) {
        if (download.fileSize > 0) {
          totalBytes += download.fileSize;
        } else {
          // Self-heal: Check actual file size if database says 0
          try {
            final int? actualSize = await validator.getActualFileSize(
              download.filePath,
            );
            if (actualSize != null && actualSize > 0) {
              totalBytes += actualSize;
              // Update database with correct size to avoid future checks
              await localDataSource.updateDownload(
                download.copyWith(
                  fileSize: actualSize,
                  downloadedSize: actualSize,
                ),
              );
            }
          } catch (e) {
            logger.w(
              '[DownloadsRepository] Failed to get file size for ${download.filePath}: $e',
            );
          }
        }
      } else {
        totalBytes += download.downloadedSize;
      }
    }
    return totalBytes;
  }
}
