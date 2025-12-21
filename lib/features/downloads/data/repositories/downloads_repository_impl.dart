import 'dart:async';
import 'dart:io';

import 'package:audio_service/audio_service.dart';
import 'package:flutter/services.dart';
import 'package:injectable/injectable.dart';

import '../../../../main.dart';
import '../../domain/entities/download_item.dart';
import '../../domain/repositories/batch_download_repository.dart';
import '../../domain/repositories/download_query_repository.dart';
import '../../domain/repositories/downloads_repository.dart';
import '../../domain/repositories/single_download_repository.dart';
import '../../utils/download_path_utils.dart';
import '../datasources/downloads_local_datasource.dart';
import '../services/batch_download_manager.dart';
import '../services/download_queue_manager.dart';
import '../services/download_service.dart';

/// Repository implementation that handles all download operations
///
/// Registered for all segregated interfaces to support proper dependency injection:
/// - Use cases can inject specific interfaces they need
/// - Backward compatibility maintained via DownloadsRepository
@LazySingleton(as: DownloadsRepository)
@LazySingleton(as: SingleDownloadRepository)
@LazySingleton(as: BatchDownloadRepository)
@LazySingleton(as: DownloadQueryRepository)
class DownloadsRepositoryImpl implements DownloadsRepository {
  DownloadsRepositoryImpl(
    this.localDataSource,
    this.downloadService,
    this.batchDownloadManager,
  );

  final DownloadsLocalDataSource localDataSource;
  final DownloadService downloadService;
  final BatchDownloadManager batchDownloadManager;
  StreamSubscription? _progressSubscription;
  final StreamController<DownloadItem> _downloadUpdatesController =
      StreamController<DownloadItem>.broadcast();

  // Cache for the downloads directory to avoid repeated async calls
  String? _cachedDownloadsDir;

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

  Future<String> _getDownloadsDir() async {
    if (_cachedDownloadsDir != null) {
      return _cachedDownloadsDir!;
    }
    _cachedDownloadsDir = await localDataSource.getDownloadsDirectory();
    return _cachedDownloadsDir!;
  }

  /// Resolves the file path for a download item dynamically.
  /// This fixes issues where absolute paths persist in DB but become invalid
  /// when the app's container path changes, while preserving the subdirectory structure.
  DownloadItem _resolveDownloadPath(DownloadItem item, String downloadsDir) {
    if (item.filePath.isEmpty) {
      return item;
    }

    // Recalculate relative path to ensure structure is preserved
    final String relativePath = DownloadPathUtils.calculateRelativePath(
      item.url,
      item.reciterName,
    );
    final String resolvedPath = DownloadPathUtils.resolveFullPath(
      downloadsDir,
      relativePath,
    );

    // Only update if the path has actually changed
    if (resolvedPath != item.filePath) {
      return item.copyWith(filePath: resolvedPath);
    }
    return item;
  }

  @override
  Future<Map<String, Map<String, List<DownloadItem>>>>
  getDownloadsByReciter() async {
    final List<DownloadItem> rawDownloads = await localDataSource
        .getDownloads();
    final String downloadsDir = await _getDownloadsDir();

    // Resolve paths for all downloads
    final List<DownloadItem> downloads = rawDownloads
        .map((item) => _resolveDownloadPath(item, downloadsDir))
        .toList();

    // Sync status with active downloads in DownloadService and queue manager
    // This ensures that downloads that are actively downloading or queued show the correct status
    // Note: In test environments, this may throw MissingPluginException,
    // so we handle it gracefully
    List<String> activeDownloadIds;
    try {
      activeDownloadIds = await downloadService.getActiveDownloadIds();
    } on MissingPluginException {
      // In test environment, platform channels are not available
      // Skip status syncing and return downloads as-is
      logger.d(
        '[DownloadsRepository] Skipping status sync - platform channels not available (test environment)',
      );
      return _groupDownloadsByReciter(downloads);
    } catch (e) {
      // Any other error - log and continue without syncing
      logger.w('[DownloadsRepository] Error getting active downloads: $e');
      return _groupDownloadsByReciter(downloads);
    }

    // Get queued download IDs from queue manager
    final Set<String> queuedIds = {};
    try {
      for (final download in downloads) {
        if (DownloadQueueManager.instance.isQueued(download.id)) {
          queuedIds.add(download.id);
        }
      }
    } catch (e) {
      logger.w('[DownloadsRepository] Error checking queue status: $e');
    }

    final updatedDownloads = <DownloadItem>[];
    var hasChanges = false;

    for (final download in downloads) {
      final bool isActive = activeDownloadIds.contains(download.url);
      final bool isQueued = queuedIds.contains(download.id);

      // Update status for queued downloads
      if (isQueued && download.status != DownloadStatus.pending) {
        final DownloadItem updatedDownload = download.copyWith(
          status: DownloadStatus.pending,
        );
        updatedDownloads.add(updatedDownload);
        hasChanges = true;
        continue;
      }

      // Check for orphaned pending downloads (Pending in DB, but not in queue and not active)
      // This happens if app was killed while pending, or if queue manager lost track
      if (download.status == DownloadStatus.pending && !isQueued && !isActive) {
        // Verify if it's really pending or if we missed a completion
        DownloadStatus? actualStatus;
        try {
          actualStatus = await downloadService.getStatus(download.url);
        } catch (e) {
          logger.w(
            '[DownloadsRepository] Error checking status for orphaned download: $e',
          );
        }

        if (actualStatus == DownloadStatus.completed) {
          // It's completed! Check file existence to be sure
          final bool fileExists = localDataSource.isFileExists(
            download.filePath,
          );
          if (fileExists) {
            logger.i(
              '[DownloadsRepository] Found orphaned pending download that is actually completed: id=${download.id} - Updating DB',
            );
            final DownloadItem updatedDownload = download.copyWith(
              status: DownloadStatus.completed,
              progress: 1.0,
              completedAt: DateTime.now(),
            );
            updatedDownloads.add(updatedDownload);
            hasChanges = true;
            continue;
          }
        }

        logger.w(
          '[DownloadsRepository] Found orphaned pending download: id=${download.id} isQueued=$isQueued isActive=$isActive actualStatus=$actualStatus - Re-enqueueing',
        );

        // Re-enqueue (auto-resume)
        try {
          await DownloadQueueManager.instance.enqueue(
            id: download.id,
            url: download.url,
            filePath: download.filePath,
            title: download.title,
            reciterName: download.reciterName,
            reciterId: download.reciterId,
          );
          // Keep as pending in the list
          updatedDownloads.add(download);
          // No need to set hasChanges unless we changed the item itself, but enqueue might trigger updates later
          continue;
        } catch (e) {
          logger.e(
            '[DownloadsRepository] Failed to re-enqueue orphaned download: $e',
          );
          // Fallthrough to regular processing
        }
      }

      if (isActive) {
        // If download is active in DownloadService but status is not downloading,
        // update it to downloading
        if (download.status != DownloadStatus.downloading) {
          final DownloadItem updatedDownload = download.copyWith(
            status: DownloadStatus.downloading,
          );
          updatedDownloads.add(updatedDownload);
          hasChanges = true;
        } else {
          // Check if download is stuck at 0% for too long even though it's active
          final Duration timeSinceCreated = DateTime.now().difference(
            download.createdAt,
          );
          final bool isStuck =
              download.progress == 0.0 && timeSinceCreated.inSeconds > 30;

          if (isStuck) {
            // Check the actual task status
            DownloadStatus? actualStatus;
            try {
              actualStatus = await downloadService.getStatus(download.url);
            } on MissingPluginException {
              actualStatus = null;
            } catch (e) {
              logger.w(
                '[DownloadsRepository] Error getting status for stuck active download: $e',
              );
              actualStatus = null;
            }

            // If task is pending/enqueued but not running, retry it
            if (actualStatus == DownloadStatus.pending) {
              logger.w(
                '[DownloadsRepository] Active download stuck at 0% with pending status: id=${download.id} title="${download.title}" - retrying',
              );
              try {
                // Cancel the existing task
                try {
                  await downloadService.cancel(download.url);
                } catch (e) {
                  logger.d(
                    '[DownloadsRepository] Error canceling stuck active download: $e',
                  );
                }

                // Remove from queue if it's there
                DownloadQueueManager.instance.removeFromQueue(download.id);

                // Wait a bit before retrying
                await Future.delayed(const Duration(milliseconds: 500));

                // Retry the download using queue manager
                await DownloadQueueManager.instance.enqueue(
                  id: download.id,
                  url: download.url,
                  filePath: download.filePath,
                  title: download.title,
                  reciterName: download.reciterName,
                );

                // Update the download item with new timestamp
                final DownloadItem updatedDownload = download.copyWith(
                  createdAt: DateTime.now(),
                  progress: 0.0,
                );
                updatedDownloads.add(updatedDownload);
                hasChanges = true;
              } catch (e) {
                // If retry fails, mark as failed
                logger.e(
                  '[DownloadsRepository] Failed to retry stuck active download: id=${download.id} error=$e',
                );
                final DownloadItem updatedDownload = download.copyWith(
                  status: DownloadStatus.failed,
                );
                updatedDownloads.add(updatedDownload);
                hasChanges = true;
              }
            } else {
              // Still active and not pending, keep as is
              updatedDownloads.add(download);
            }
          } else {
            updatedDownloads.add(download);
          }
        }
      } else {
        // Download is NOT active in DownloadService
        // Check if it's actually still downloading in background_downloader
        // (background downloads continue even when app is closed)
        DownloadStatus? backgroundStatus;
        try {
          backgroundStatus = await downloadService.getStatus(download.url);
        } on MissingPluginException {
          // In test environment, skip status check
          backgroundStatus = null;
        } catch (e) {
          // Any other error - log and continue
          logger.w(
            '[DownloadsRepository] Error getting download status for ${download.id}: $e',
          );
          backgroundStatus = null;
        }

        if (backgroundStatus == DownloadStatus.downloading) {
          // Download is still active in background, update status
          if (download.status != DownloadStatus.downloading) {
            final DownloadItem updatedDownload = download.copyWith(
              status: DownloadStatus.downloading,
            );
            updatedDownloads.add(updatedDownload);
            hasChanges = true;
          } else {
            updatedDownloads.add(download);
          }
        } else if (download.status == DownloadStatus.downloading) {
          // Was downloading but not active anymore - check if it completed or failed
          if (backgroundStatus == DownloadStatus.completed) {
            // Download reported as completed - verify before marking as such
            // Check if file exists
            final bool fileExists = localDataSource.isFileExists(
              download.filePath,
            );

            if (!fileExists) {
              logger.w(
                '[DownloadsRepository] Download reported as completed but file not found: id=${download.id} - marking as failed',
              );
              final DownloadItem failedDownload = download.copyWith(
                status: DownloadStatus.failed,
              );
              updatedDownloads.add(failedDownload);
              hasChanges = true;
              continue;
            }

            // Verify file size if we have it
            if (download.fileSize > 0) {
              try {
                final file = File(download.filePath);
                final int actualFileSize = await file.length();
                final int tolerance = (download.fileSize * 0.01).round();
                final int sizeDiff = (actualFileSize - download.fileSize).abs();

                if (sizeDiff > tolerance) {
                  logger.w(
                    '[DownloadsRepository] Download reported as completed but file size mismatch: '
                    'expected=${download.fileSize} actual=$actualFileSize - marking as failed',
                  );
                  final DownloadItem failedDownload = download.copyWith(
                    status: DownloadStatus.failed,
                  );
                  updatedDownloads.add(failedDownload);
                  hasChanges = true;
                  continue;
                }
              } catch (e) {
                logger.e(
                  '[DownloadsRepository] Error verifying file size: $e - keeping as downloading',
                );
                updatedDownloads.add(download);
                continue;
              }
            }

            // All checks passed - mark as completed
            logger.d(
              '[DownloadsRepository] Download verified and marked as completed in sync: id=${download.id}',
            );
            final DownloadItem updatedDownload = download.copyWith(
              status: DownloadStatus.completed,
              progress: 1.0,
              completedAt: DateTime.now(),
            );
            updatedDownloads.add(updatedDownload);
            hasChanges = true;
          } else if (backgroundStatus == DownloadStatus.failed) {
            // Download failed in background
            logger.w(
              '[DownloadsRepository] Download failed in background: id=${download.id} title="${download.title}"',
            );
            final DownloadItem updatedDownload = download.copyWith(
              status: DownloadStatus.failed,
            );
            updatedDownloads.add(updatedDownload);
            hasChanges = true;
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
              // Download is stuck - retry it
              logger.w(
                '[DownloadsRepository] Download stuck at 0%: id=${download.id} title="${download.title}" - retrying',
              );
              try {
                // Cancel the existing task if it exists
                try {
                  await downloadService.cancel(download.url);
                } catch (e) {
                  // Ignore errors when canceling (task might not exist)
                  logger.d(
                    '[DownloadsRepository] Error canceling stuck download: $e',
                  );
                }

                // Remove from queue if it's there
                DownloadQueueManager.instance.removeFromQueue(download.id);

                // Wait a bit before retrying
                await Future.delayed(const Duration(milliseconds: 500));

                // Retry the download using queue manager
                await DownloadQueueManager.instance.enqueue(
                  id: download.id,
                  url: download.url,
                  filePath: download.filePath,
                  title: download.title,
                  reciterName: download.reciterName,
                  reciterId: download.reciterId,
                );

                // Update the download item with new timestamp
                final DownloadItem updatedDownload = download.copyWith(
                  createdAt: DateTime.now(),
                  progress: 0.0,
                );
                updatedDownloads.add(updatedDownload);
                hasChanges = true;
              } catch (e) {
                // If retry fails, mark as failed
                logger.e(
                  '[DownloadsRepository] Failed to retry stuck download: id=${download.id} error=$e',
                );
                final DownloadItem updatedDownload = download.copyWith(
                  status: DownloadStatus.failed,
                );
                updatedDownloads.add(updatedDownload);
                hasChanges = true;
              }
            } else {
              // Status unknown or null - keep as is for now
              updatedDownloads.add(download);
            }
          }
        } else {
          updatedDownloads.add(download);
        }
      }
    }

    // Save updated downloads if there were any changes
    if (hasChanges) {
      await localDataSource.updateDownloads(updatedDownloads);
    }

    return _groupDownloadsByReciter(
      updatedDownloads.isEmpty ? downloads : updatedDownloads,
    );
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
    final String downloadsDir = await _getDownloadsDir();

    return rawDownloads
        .where((d) => d.reciterName == reciterName)
        .map((item) => _resolveDownloadPath(item, downloadsDir))
        .toList();
  }

  @override
  Future<DownloadItem?> getDownloadItem(String id) async {
    final List<DownloadItem> downloads = await localDataSource.getDownloads();
    try {
      final DownloadItem item = downloads.firstWhere((d) => d.id == id);
      final String downloadsDir = await _getDownloadsDir();
      return _resolveDownloadPath(item, downloadsDir);
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
    if (download != null && localDataSource.isFileExists(download.filePath)) {
      await localDataSource.deleteFile(download.filePath);
    }
    await localDataSource.deleteDownload(id);
  }

  @override
  Future<void> deleteDownloadsForReciter(String reciterName) async {
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
      if (localDataSource.isFileExists(item.filePath)) {
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
    final List<DownloadItem> downloads = await localDataSource.getDownloads();
    for (final download in downloads) {
      if (localDataSource.isFileExists(download.filePath)) {
        await localDataSource.deleteFile(download.filePath);
      }
    }
    await localDataSource.clearAllDownloads();
  }

  @override
  Stream<DownloadItem> getDownloadProgress(String id) async* {
    // This would typically be implemented with a download manager
    // For now, we'll simulate progress updates
    final DownloadItem? download = await getDownloadItem(id);
    if (download != null) {
      yield download;
    }
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

    final String downloadsDir = await localDataSource.getDownloadsDirectory();

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
    final String downloadsDir = await localDataSource.getDownloadsDirectory();
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
      // Add to DB explicitly
      await addDownload(downloadItem);

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
      if (localDataSource.isFileExists(download.filePath)) {
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
    final String downloadsDir = await _getDownloadsDir();

    for (final rawDownload in downloads) {
      final DownloadItem d = _resolveDownloadPath(rawDownload, downloadsDir);
      final bool isFileExists = localDataSource.isFileExists(d.filePath);
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
    final String downloadsDir = await _getDownloadsDir();

    try {
      final DownloadItem rawDownload = downloads.firstWhere(
        (d) =>
            d.reciterName == reciterName &&
            d.url == trimmedUrl &&
            d.status == DownloadStatus.completed,
      );

      final DownloadItem download = _resolveDownloadPath(
        rawDownload,
        downloadsDir,
      );

      if (localDataSource.isFileExists(download.filePath)) {
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

    // If not found by exact ID, it might be that DownloadService is reporting the URL
    // instead of the composite ID (e.g. after app restart or if mapping was lost).
    // Try to find the download by matching the URL.
    if (download == null) {
      try {
        final List<DownloadItem> allDownloads = await localDataSource
            .getDownloads();
        // Find a download where key url matches the ID reported by service
        // We prioritize active downloads if there are multiple matches (rare)
        download = allDownloads.firstWhere((d) => d.url == id);
      } catch (_) {
        // Still not found, ignore update
      }
    }

    if (download != null) {
      // Special handling for completed status:
      // Only mark as completed if:
      // 1. Progress is 100% (1.0)
      // 2. File actually exists on disk
      // 3. File size matches expected size (if available)
      if (status == DownloadStatus.completed) {
        // Verify progress is actually 100%
        if (progress < 1.0) {
          logger.w(
            '[DownloadsRepository] Download reported as completed but progress is ${(progress * 100).toStringAsFixed(1)}% - keeping as downloading',
          );
          // Keep status as downloading until progress reaches 100%
          final DownloadItem updatedDownload = download.copyWith(
            status: DownloadStatus.downloading,
            progress: progress,
            downloadedSize: downloadedSize,
            fileSize: fileSize,
          );
          await updateDownload(updatedDownload);
          return;
        }

        // Verify file actually exists with retry mechanism
        // Sometimes the file system has not fully committed the move from temp to final path
        var fileExists = false;
        // Increase retries to 10 (approx 5 seconds) to account for slower IO/devices
        for (var i = 0; i < 10; i++) {
          fileExists = localDataSource.isFileExists(download.filePath);
          if (fileExists) {
            break;
          }
          // Wait a bit before retrying
          if (i < 9) {
            await Future.delayed(const Duration(milliseconds: 500));
          }
        }

        if (!fileExists) {
          logger.w(
            '[DownloadsRepository] Download reported as completed but file not found at ${download.filePath} after retries - marking as failed',
          );

          // Diagnostic: List contents of the parent directory to see what's there
          try {
            final String parentDirPath = DownloadPathUtils.getDirectoryName(
              download.filePath,
            );
            final parentDir = Directory(parentDirPath);
            if (parentDir.existsSync()) {
              final List<FileSystemEntity> contents = await parentDir
                  .list()
                  .toList();
              final String fileNames = contents
                  .map((e) => e.path.split(Platform.pathSeparator).last)
                  .join(', ');
              logger.d(
                '[DownloadsRepository] Contents of $parentDirPath: [$fileNames]',
              );
            } else {
              logger.w(
                '[DownloadsRepository] Parent directory does not exist: $parentDirPath',
              );
            }
          } catch (e) {
            logger.e(
              '[DownloadsRepository] Failed to list directory contents: $e',
            );
          }

          // File doesn't exist yet, mark as failed
          final DownloadItem updatedDownload = download.copyWith(
            status: DownloadStatus.failed,
            progress: progress,
            downloadedSize: downloadedSize,
            fileSize: fileSize,
          );
          await updateDownload(updatedDownload);
          return;
        }

        // Verify file size if available
        if (fileSize > 0) {
          try {
            final file = File(download.filePath);
            final int actualFileSize = await file.length();

            // Allow some tolerance (1%) for file size differences due to metadata
            final int tolerance = (fileSize * 0.01).round();
            final int sizeDiff = (actualFileSize - fileSize).abs();

            if (sizeDiff > tolerance) {
              logger.w(
                '[DownloadsRepository] Download reported as completed but file size mismatch: '
                'expected=$fileSize actual=$actualFileSize diff=$sizeDiff - marking as failed',
              );
              // File size doesn't match, mark as failed
              final DownloadItem updatedDownload = download.copyWith(
                status: DownloadStatus.failed,
                progress: progress,
                downloadedSize: downloadedSize,
                fileSize: fileSize,
              );
              await updateDownload(updatedDownload);
              return;
            }
          } catch (e) {
            logger.e(
              '[DownloadsRepository] Error verifying file size for completed download: $e',
            );
            // If we can't verify, keep as downloading to be safe
            final DownloadItem updatedDownload = download.copyWith(
              status: DownloadStatus.downloading,
              progress: progress,
              downloadedSize: downloadedSize,
              fileSize: fileSize,
            );
            await updateDownload(updatedDownload);
            return;
          }
        } else {
          // File size is 0 or unknown - try to get it from disk since we are completed
          try {
            final file = File(download.filePath);
            // ignore: avoid_slow_async_io
            if (await file.exists()) {
              final int actualFileSize = await file.length();
              if (actualFileSize > 0) {
                // Update the file size with the actual size on disk
                final DownloadItem updatedDownload = download.copyWith(
                  status: DownloadStatus.completed,
                  progress: 1.0,
                  downloadedSize: actualFileSize,
                  fileSize: actualFileSize,
                  completedAt: DateTime.now(),
                );
                await updateDownload(updatedDownload);
                return;
              }
            }
          } catch (e) {
            logger.w(
              '[DownloadsRepository] Failed to update file size from disk: $e',
            );
          }
        }

        // All checks passed - mark as completed
        logger.d(
          '[DownloadsRepository] Download verified and marked as completed: '
          'id=${download.id} file=${download.filePath} size=$fileSize',
        );
        final DownloadItem updatedDownload = download.copyWith(
          status: DownloadStatus.completed,
          progress: 1.0, // Ensure progress is exactly 1.0
          downloadedSize: downloadedSize,
          fileSize: fileSize,
          completedAt: DateTime.now(),
        );
        await updateDownload(updatedDownload);
      } else {
        // Use existing file size if incoming is 0 (DownloadService often sends 0)
        final int effectiveFileSize = fileSize > 0
            ? fileSize
            : download.fileSize;

        // Special check: if downloading and progress is at 100%, check if we should mark as completed
        // This handles cases where FlutterDownloader might be stuck or late in sending completion event
        if (status == DownloadStatus.downloading && progress >= 1.0) {
          final bool fileExists = localDataSource.isFileExists(
            download.filePath,
          );
          if (fileExists) {
            // If file exists and we are at 100%, trust it is completed
            logger.d(
              '[DownloadsRepository] Download at 100% with downloading status - auto-marking as completed: id=${download.id}',
            );

            // Try to get actual file size from disk if current size is invalid
            var finalFileSize = effectiveFileSize;
            if (finalFileSize <= 0) {
              try {
                final file = File(download.filePath);
                // ignore: avoid_slow_async_io
                final int actualSize = await file.length();
                if (actualSize > 0) {
                  finalFileSize = actualSize;
                }
              } catch (e) {
                // Ignore error, keep existing size
              }
            }

            final DownloadItem updatedDownload = download.copyWith(
              status: DownloadStatus.completed,
              progress: 1.0,
              downloadedSize: finalFileSize > 0
                  ? finalFileSize
                  : downloadedSize,
              fileSize: finalFileSize,
              completedAt: DateTime.now(),
            );
            await updateDownload(updatedDownload);
            return;
          }
        }

        // For non-completed statuses, update normally
        final DownloadItem updatedDownload = download.copyWith(
          status: status,
          progress: progress,
          downloadedSize: downloadedSize,
          fileSize: effectiveFileSize,
        );
        await updateDownload(updatedDownload);
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
    try {
      final file = File(download.filePath);
      return file.existsSync();
    } catch (e) {
      return false;
    }
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
            final file = File(download.filePath);
            if (file.existsSync()) {
              final int actualSize = await file.length();
              if (actualSize > 0) {
                totalBytes += actualSize;
                // Update database with correct size to avoid future checks
                await localDataSource.updateDownload(
                  download.copyWith(
                    fileSize: actualSize,
                    downloadedSize: actualSize,
                  ),
                );
              }
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
