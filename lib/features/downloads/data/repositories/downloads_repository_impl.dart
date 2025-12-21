import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:flutter/services.dart';
import 'package:injectable/injectable.dart';

import '../../../../main.dart';
import '../../domain/entities/download_item.dart';
import '../../domain/repositories/downloads_repository.dart';
import '../../utils/download_path_utils.dart';
import '../datasources/downloads_local_datasource.dart';
import '../services/batch_download_manager.dart';
import '../services/download_path_resolver.dart';
import '../services/download_queue_manager.dart';
import '../services/download_service.dart';
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
    this.validator,
    this.statusSynchronizer,
  );

  final DownloadsLocalDataSource localDataSource;
  final DownloadService downloadService;
  final BatchDownloadManager batchDownloadManager;
  final DownloadPathResolver pathResolver;
  final DownloadValidator validator;
  final DownloadStatusSynchronizer statusSynchronizer;
  StreamSubscription? _progressSubscription;
  final StreamController<DownloadItem> _downloadUpdatesController =
      StreamController<DownloadItem>.broadcast();

  @override
  Future<void> initialize() async {
    _progressSubscription?.cancel();
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
    DownloadQueueManager.instance.setMaxConcurrentDownloads(2);
  }

  @override
  Future<Map<String, Map<String, List<DownloadItem>>>>
  getDownloadsByReciter() async {
    final List<DownloadItem> rawDownloads = await localDataSource
        .getDownloads();
    final String downloadsDir = await pathResolver.getDownloadsDir();

    // Resolve paths for all downloads
    final List<DownloadItem> downloads = rawDownloads
        .map((item) => pathResolver.resolveDownloadPath(item, downloadsDir))
        .toList();

    // Synchronize statuses using the new service
    final List<DownloadItem> updatedDownloads = await statusSynchronizer
        .syncDownloadStatuses(downloads);

    // Identify if any changes occurred during sync
    var hasChanges = updatedDownloads.length != downloads.length;
    if (!hasChanges) {
      for (var i = 0; i < downloads.length; i++) {
        if (updatedDownloads[i] != downloads[i]) {
          hasChanges = true;
          break;
        }
      }
    }

    // Save updated downloads if there were any changes
    if (hasChanges) {
      final List<DownloadItem> changedItems = [];
      if (updatedDownloads.length == downloads.length) {
        for (var i = 0; i < updatedDownloads.length; i++) {
          if (updatedDownloads[i] != downloads[i]) {
            changedItems.add(updatedDownloads[i]);
          }
        }
      } else {
        changedItems.addAll(updatedDownloads);
      }

      if (changedItems.isNotEmpty) {
        await localDataSource.updateDownloads(changedItems);
      }
    }

    return _groupDownloadsByReciter(updatedDownloads);
  }

  /// Groups downloads by reciter name and then by narrative
  Map<String, Map<String, List<DownloadItem>>> _groupDownloadsByReciter(
    List<DownloadItem> downloads,
  ) {
    final Map<String, Map<String, List<DownloadItem>>> grouped = {};

    for (final download in downloads) {
      final String reciterName = download.reciterName;
      final String narrative = DownloadPathUtils.extractNarrativeFromPath(
        download.filePath,
      );

      // Ensure reciter group exists
      if (!grouped.containsKey(reciterName)) {
        grouped[reciterName] = {};
      }

      // Ensure narrative group exists within reciter
      if (!grouped[reciterName]!.containsKey(narrative)) {
        grouped[reciterName]![narrative] = [];
      }

      // Add download to appropriate narrative group
      grouped[reciterName]![narrative]!.add(download);
    }

    return grouped;
  }

  @override
  Future<List<DownloadItem>> getDownloadsForReciter(String reciterName) async {
    final List<DownloadItem> rawDownloads = await localDataSource
        .getDownloads();
    final String downloadsDir = await pathResolver.getDownloadsDir();

    return rawDownloads
        .where((d) => d.reciterName == reciterName)
        .map((item) => pathResolver.resolveDownloadPath(item, downloadsDir))
        .toList();
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
  Future<void> deleteDownloadsForReciter(String reciterName) async {
    // Cancel any active downloads first
    await cancelDownloadsForReciter(reciterName);

    final List<DownloadItem> downloads = await getDownloadsForReciter(
      reciterName,
    );
    for (final download in downloads) {
      await deleteDownload(download.id);
    }
  }

  @override
  Future<void> cancelDownloadsForReciter(String reciterName) async {
    final List<DownloadItem> downloads = await getDownloadsForReciter(
      reciterName,
    );
    final List<DownloadItem> toCancel = downloads
        .where(
          (d) =>
              d.status == DownloadStatus.downloading ||
              d.status == DownloadStatus.pending,
        )
        .toList();

    if (toCancel.isEmpty) return;

    final List<DownloadItem> updatedItems = [];

    for (final item in toCancel) {
      // Remove from queue
      DownloadQueueManager.instance.removeFromQueue(item.id);

      // Cancel in download service
      try {
        await downloadService.cancel(item.url);
      } catch (e) {
        logger.w(
          '[DownloadsRepository] Error canceling download ${item.id}: $e',
        );
      }

      // Delete partial file if exists
      final bool fileExists = await validator.verifyFileExists(item.filePath);
      if (fileExists) {
        await localDataSource.deleteFile(item.filePath);
      }

      final DownloadItem updatedItem = item.copyWith(
        status: DownloadStatus.cancelled,
      );
      updatedItems.add(updatedItem);
    }

    if (updatedItems.isNotEmpty) {
      await localDataSource.updateDownloads(updatedItems);
      for (final item in updatedItems) {
        _downloadUpdatesController.add(item);
      }
    }
  }

  @override
  Future<void> clearAllDownloads() async {
    // Stop all active downloads first
    try {
      // ignore: missing_plugin_exception_catch
      await DownloadQueueManager.instance.stopAll();
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
    bool showNotification = true,
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
    final bool isQueued = DownloadQueueManager.instance.isQueued(downloadId);
    final bool isActive = DownloadQueueManager.instance.isActive(downloadId);

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

    logger.d(
      '[DownloadsRepositoryImpl] startDownload: id=$downloadId fileName=$safeFileName path=$filePath status=$initialStatus',
    );

    // Enqueue the download (queue manager will handle starting it)
    // Note: In test environments, this may throw MissingPluginException,
    // which is expected and should be handled by the caller
    try {
      await DownloadQueueManager.instance.enqueue(
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
    if (items.isEmpty) return;
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
      if (trimmedUrl.isEmpty) continue;

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
      if (DownloadQueueManager.instance.isQueued(downloadId) ||
          DownloadQueueManager.instance.isActive(downloadId)) {
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
      for (final item in dbItems) {
        _downloadUpdatesController.add(item);
      }

      // Notify batch manager
      final batchId = 'batch_${DateTime.now().millisecondsSinceEpoch}';
      batchDownloadManager.startBatch(
        batchId: batchId,
        title: 'Downloading ${queueItems.length} files',
        downloadIds: queueItems.map((e) => e.id).toList(),
      );

      // Enqueue as a batch
      try {
        await DownloadQueueManager.instance.enqueueBatch(queueItems);
        logger.d(
          '[DownloadsRepositoryImpl] Started batch download of ${queueItems.length} items',
        );
      } on MissingPluginException {
        logger.d(
          '[DownloadsRepositoryImpl] enqueueBatch skipped (test environment)',
        );
      }
    }
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
    DownloadQueueManager.instance.removeFromQueue(id);

    final DownloadItem? item = await getDownloadItem(id);
    if (item != null) {
      await downloadService.cancel(item.url);
    } else {
      // Fallback: try cancelling with ID if item not found (though unlikely to work if ID != URL)
      await downloadService.cancel(id);
    }

    final DownloadItem? download = await getDownloadItem(id);
    if (download != null) {
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
  Future<List<DownloadItem>> getValidCompletedDownloads(
    String reciterName,
  ) async {
    final List<DownloadItem> downloads = await getDownloadsForReciter(
      reciterName,
    );
    final validDownloads = <DownloadItem>[];

    for (final download in downloads) {
      if (download.status == DownloadStatus.completed) {
        final bool fileExists = await validateDownloadedFile(download);
        if (fileExists) {
          validDownloads.add(download);
        }
      }
    }

    return validDownloads;
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

    // Cancel the existing task if it exists
    try {
      await DownloadService.cancelDownload(downloadId);
    } catch (e) {
      // Ignore errors when canceling (task might not exist)
      logger.d('[DownloadsRepository] Error canceling download for retry: $e');
    }

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
    await DownloadQueueManager.instance.enqueue(
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
          isActive = await DownloadService.isDownloadActive(download.url);
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

          try {
            await DownloadQueueManager.instance.enqueue(
              id: download.id,
              url: download.url,
              filePath: download.filePath,
              title: download.title,
              reciterName: download.reciterName,
              reciterId: download.reciterId,
            );
            resumedCount++;
          } catch (e) {
            logger.e(
              '[DownloadsRepository] Failed to resume download ${download.id}: $e',
            );
          }
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
