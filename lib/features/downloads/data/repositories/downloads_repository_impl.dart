import 'dart:io';

import 'package:audio_service/audio_service.dart';
import 'package:flutter/services.dart';
import 'package:injectable/injectable.dart';
import 'package:path/path.dart' as path;

import '../../../../main.dart';
import '../../domain/entities/download_item.dart';
import '../../domain/repositories/downloads_repository.dart';
import '../datasources/downloads_local_datasource.dart';
import '../services/download_queue_manager.dart';
import '../services/download_service.dart';

@LazySingleton(as: DownloadsRepository)
class DownloadsRepositoryImpl implements DownloadsRepository {
  DownloadsRepositoryImpl(this.localDataSource);

  final DownloadsLocalDataSource localDataSource;

  // Cache for the downloads directory to avoid repeated async calls
  String? _cachedDownloadsDir;

  Future<String> _getDownloadsDir() async {
    if (_cachedDownloadsDir != null) return _cachedDownloadsDir!;
    _cachedDownloadsDir = await localDataSource.getDownloadsDirectory();
    return _cachedDownloadsDir!;
  }

  /// Resolves the file path for a download item dynamically.
  /// This fixes issues where absolute paths persist in DB but become invalid
  /// when the app's container path changes (e.g. on iOS/Simulators after relaunch).
  DownloadItem _resolveDownloadPath(DownloadItem item, String downloadsDir) {
    if (item.filePath.isEmpty) return item;

    final String fileName = path.basename(item.filePath);
    final String resolvedPath = path.join(downloadsDir, fileName);

    // Only update if the path has actually changed
    if (resolvedPath != item.filePath) {
      return item.copyWith(filePath: resolvedPath);
    }
    return item;
  }

  @override
  Future<Map<String, List<DownloadItem>>> getDownloadsByReciter() async {
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
      activeDownloadIds = await DownloadService.activeDownloadIds;
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
        logger.w(
          '[DownloadsRepository] Found orphaned pending download: id=${download.id} isQueued=$isQueued isActive=$isActive - Re-enqueueing',
        );

        // Re-enqueue (auto-resume)
        try {
          await DownloadQueueManager.instance.enqueue(
            id: download.id,
            url: download.url,
            filePath: download.filePath,
            title: download.title,
            reciterName: download.reciterName,
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
              actualStatus = await DownloadService.getDownloadStatus(
                download.url,
              );
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
                  await DownloadService.cancelDownload(download.url);
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
          backgroundStatus = await DownloadService.getDownloadStatus(
            download.url,
          );
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
            final bool fileExists = await localDataSource.isFileExists(
              download.filePath,
            );

            if (!fileExists) {
              logger.w(
                '[DownloadsRepository] Download reported as completed but file not found: id=${download.id} - keeping as downloading',
              );
              updatedDownloads.add(download);
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
                    'expected=${download.fileSize} actual=$actualFileSize - keeping as downloading',
                  );
                  updatedDownloads.add(download);
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
                  await DownloadService.cancelDownload(download.url);
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
      for (final download in updatedDownloads) {
        await localDataSource.updateDownload(download);
      }
    }

    return _groupDownloadsByReciter(
      updatedDownloads.isEmpty ? downloads : updatedDownloads,
    );
  }

  /// Groups downloads by reciter name
  Map<String, List<DownloadItem>> _groupDownloadsByReciter(
    List<DownloadItem> downloads,
  ) {
    final Map<String, List<DownloadItem>> grouped = {};
    for (final download in downloads) {
      if (!grouped.containsKey(download.reciterName)) {
        grouped[download.reciterName] = [];
      }
      grouped[download.reciterName]!.add(download);
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
  }

  @override
  Future<void> updateDownload(DownloadItem downloadItem) async {
    await localDataSource.updateDownload(downloadItem);
  }

  @override
  Future<void> deleteDownload(String id) async {
    final DownloadItem? download = await getDownloadItem(id);
    if (download != null &&
        await localDataSource.isFileExists(download.filePath)) {
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
  Future<void> clearAllDownloads() async {
    final List<DownloadItem> downloads = await localDataSource.getDownloads();
    for (final download in downloads) {
      if (await localDataSource.isFileExists(download.filePath)) {
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
    String surahId,
    String surahTitle,
    String reciterName,
  ) async {
    // Validate inputs early to avoid creating invalid download entries
    // Note: in our app, surahId is the actual download URL
    final String trimmedUrl = surahId.trim();
    if (trimmedUrl.isEmpty) {
      logger.e(
        '[DownloadsRepositoryImpl] startDownload: empty URL for surahId=$surahId reciter="$reciterName"',
      );
      throw ArgumentError('Download URL is empty');
    }

    final String downloadsDir = await localDataSource.getDownloadsDirectory();

    // Use the URL as download ID (uniqueness is maintained through filename)
    final downloadId = trimmedUrl;

    // Extract the complete directory structure from URL to maintain server organization
    // E.g., https://server6.mp3quran.net/husary/hafs/002.mp3 -> husary/hafs/002.mp3
    // E.g., https://server6.mp3quran.net/earawi/002.mp3 -> earawi/002.mp3
    String safeFileName;
    try {
      final Uri parsed = Uri.parse(trimmedUrl);
      final List<String> pathSegments = parsed.pathSegments;

      if (pathSegments.length >= 2) {
        // URL has folder structure and filename
        // Join all path segments to preserve reciter/narrative/file structure
        // For example: ['husary', 'hafs', '002.mp3'] -> 'husary/hafs/002.mp3'
        safeFileName = path.joinAll(pathSegments);
      } else if (pathSegments.isNotEmpty) {
        // URL only has filename, create folder from reciter name
        final String sanitizedReciter = reciterName.replaceAll(' ', '_');
        safeFileName = path.join(sanitizedReciter, pathSegments.last);
      } else {
        // Fallback: create folder from reciter name
        final String sanitizedReciter = reciterName.replaceAll(' ', '_');
        safeFileName = path.join(sanitizedReciter, '$surahId.mp3');
      }
    } catch (_) {
      // Fallback if URL parsing fails
      final String sanitizedReciter = reciterName.replaceAll(' ', '_');
      safeFileName = path.join(sanitizedReciter, '$surahId.mp3');
    }

    // Final guard to ensure we have an extension
    if (path.extension(safeFileName).isEmpty) {
      safeFileName = '$safeFileName.mp3';
    }

    final String filePath = path.join(downloadsDir, safeFileName);

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
      await DownloadService.cancelDownload(item.url);
    } else {
      // Fallback: try cancelling with ID if item not found (though unlikely to work if ID != URL)
      await DownloadService.cancelDownload(id);
    }

    final DownloadItem? download = await getDownloadItem(id);
    if (download != null) {
      final DownloadItem updatedDownload = download.copyWith(
        status: DownloadStatus.cancelled,
      );
      await updateDownload(updatedDownload);
      if (await localDataSource.isFileExists(download.filePath)) {
        await localDataSource.deleteFile(download.filePath);
      }
    }
  }

  @override
  Future<bool> isSurahDownloaded(String surahId, String reciterName) async {
    final List<DownloadItem> downloads = await localDataSource.getDownloads();
    // surahId is the URL
    // We match by checking if the download's URL matches surahId AND reciter matches
    final String trimmedUrl = surahId.trim();
    final String downloadsDir = await _getDownloadsDir();

    for (final rawDownload in downloads) {
      final DownloadItem d = _resolveDownloadPath(rawDownload, downloadsDir);
      final bool isFileExists = await localDataSource.isFileExists(d.filePath);
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
  Future<bool> isSurahDownloading(String surahId, String reciterName) async {
    final String trimmedUrl = surahId.trim();

    // First check if there's a download item with downloading status
    final List<DownloadItem> downloads = await localDataSource.getDownloads();
    for (final d in downloads) {
      if (d.reciterName == reciterName &&
          d.url == trimmedUrl &&
          d.status == DownloadStatus.downloading) {
        // Also verify it's actually active in DownloadService
        try {
          final bool isActive = await DownloadService.isDownloadActive(d.url);
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
      return await DownloadService.isDownloadActive(trimmedUrl);
    } on MissingPluginException {
      // In test environment, return false
      return false;
    } catch (e) {
      logger.w('[DownloadsRepository] Error checking download status: $e');
      return false;
    }
  }

  @override
  Future<String?> getDownloadedFilePath(
    String surahId,
    String reciterName,
  ) async {
    final List<DownloadItem> downloads = await localDataSource.getDownloads();
    // surahId is the URL
    final String trimmedUrl = surahId.trim();
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

      if (await localDataSource.isFileExists(download.filePath)) {
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

        // Verify file actually exists
        final bool fileExists = await localDataSource.isFileExists(
          download.filePath,
        );

        if (!fileExists) {
          logger.w(
            '[DownloadsRepository] Download reported as completed but file not found at ${download.filePath} - keeping as downloading',
          );
          // File doesn't exist yet, keep as downloading
          final DownloadItem updatedDownload = download.copyWith(
            status: DownloadStatus.downloading,
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
                'expected=$fileSize actual=$actualFileSize diff=$sizeDiff - keeping as downloading',
              );
              // File size doesn't match, keep as downloading
              final DownloadItem updatedDownload = download.copyWith(
                status: DownloadStatus.downloading,
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
        // For non-completed statuses, update normally
        final DownloadItem updatedDownload = download.copyWith(
          status: status,
          progress: progress,
          downloadedSize: downloadedSize,
          fileSize: fileSize,
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
}
