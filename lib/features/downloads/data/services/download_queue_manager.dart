import 'dart:async';

import 'package:clock/clock.dart';
import 'package:flutter/foundation.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/utils/toast_utils.dart';
import '../../../../main.dart';
import '../../domain/entities/download_item.dart';
import 'download_service.dart';

/// Manages a queue of pending downloads and controls concurrency
class DownloadQueueManager {
  DownloadQueueManager._();
  static DownloadQueueManager instance = DownloadQueueManager._();

  final DownloadService _downloadService = getIt<DownloadService>();

  /// Reset the instance for testing
  @visibleForTesting
  static void reset() {
    instance.dispose();
    instance = DownloadQueueManager._();
  }

  // Maximum number of concurrent downloads
  // Maximum number of concurrent downloads
  int _maxConcurrentDownloads = 2; // Default to 2

  /// Set the maximum number of concurrent downloads
  void setMaxConcurrentDownloads(int count) {
    if (count < 1) return;
    _maxConcurrentDownloads = count;
    logger.d(
      '[DownloadQueueManager] Max concurrent downloads set to $_maxConcurrentDownloads',
    );
    // Trigger queue processing to potentially start more downloads
    if (_activeDownloads.length < _maxConcurrentDownloads) {
      unawaited(_processQueue());
    }
  }

  /// Get the maximum number of concurrent downloads
  int get maxConcurrentDownloads => _maxConcurrentDownloads;

  // Queue of pending downloads
  final List<QueuedDownload> _queue = [];

  // Currently active downloads (running or enqueued in DownloadService)
  final Set<String> _activeDownloads = {};

  // Track URLs of active downloads to map IDs to URLs for sync
  final Map<String, String> _activeDownloadUrls = {};

  // Track last activity time for each active download to detect stuck ones
  final Map<String, DateTime> _lastActivityTime = {};

  // Stream controller for queue updates
  final StreamController<QueueUpdate> _queueUpdateController =
      StreamController<QueueUpdate>.broadcast();

  StreamSubscription<DownloadProgress>? _progressSubscription;
  Timer? _syncTimer;
  bool _isInitialized = false;

  /// Initialize the queue manager and listen to download progress
  Future<void> initialize() async {
    if (_isInitialized) {
      return;
    }

    // Listen to download progress to know when downloads complete
    _progressSubscription = DownloadService.globalProgressStream.listen((
      progress,
    ) {
      _handleDownloadProgress(progress);
    });

    // Periodically sync active downloads with DownloadService
    // This ensures we don't have stale entries in _activeDownloads
    // Reduced to 5 seconds for more responsive queue processing
    _syncTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      _syncActiveDownloads().then((_) {
        // After syncing, check if we should process queue
        if (_activeDownloads.length < maxConcurrentDownloads &&
            _queue.isNotEmpty) {
          unawaited(
            _processQueue().catchError((e) {
              logger.e(
                '[DownloadQueueManager] Error in periodic queue processing: $e',
              );
            }),
          );
        }
      });
    });

    _isInitialized = true;
    logger.d('[DownloadQueueManager] Initialized');
  }

  /// Add a download to the queue
  Future<void> enqueue({
    required String id,
    required String url,
    required String filePath,
    required String title,
    required String reciterName,
  }) async {
    await initialize();

    // Check if already in queue or active
    if (_isInQueue(id) || _activeDownloads.contains(id)) {
      logger.d(
        '[DownloadQueueManager] Download already queued or active: id=$id',
      );
      return;
    }

    final queuedDownload = QueuedDownload(
      id: id,
      url: url,
      filePath: filePath,
      title: title,
      reciterName: reciterName,
      enqueuedAt: clock.now(),
    );

    _queue.add(queuedDownload);
    _notifyQueueUpdate();

    logger.d(
      '[DownloadQueueManager] Enqueued download: id=$id title="$title" queuePosition=${_queue.length}',
    );

    // Try to process the queue
    await _processQueue();
  }

  /// Remove a download from the queue
  void removeFromQueue(String id) {
    _queue.removeWhere((download) => download.id == id);
    _notifyQueueUpdate();
    logger.d('[DownloadQueueManager] Removed from queue: id=$id');
  }

  /// Check if a download is in the queue
  bool _isInQueue(String id) {
    return _queue.any((download) => download.id == id);
  }

  /// Get queue position for a download (0-based, -1 if not in queue)
  int getQueuePosition(String id) {
    final int index = _queue.indexWhere((download) => download.id == id);
    return index >= 0 ? index + 1 : -1;
  }

  /// Get the number of downloads in queue
  int get queueLength => _queue.length;

  /// Get the number of active downloads
  int get activeDownloadsCount => _activeDownloads.length;

  /// Check if a download is queued
  bool isQueued(String id) {
    return _isInQueue(id);
  }

  /// Check if a download is active (running or enqueued in DownloadService)
  bool isActive(String id) {
    return _activeDownloads.contains(id);
  }

  /// Process the queue - start downloads up to the max concurrent limit
  Future<void> _processQueue() async {
    // First, sync active downloads to ensure we have accurate count
    await _syncActiveDownloads();

    // Check actual running downloads from DownloadService
    int actualRunningCount;
    try {
      final List<String> actualActiveIds = await _downloadService
          .getActiveDownloadIds();
      // Filter to only count downloads that are actually running (not just enqueued)
      actualRunningCount = 0;

      // Use a Set to avoid counting duplicate URLs multiple times
      final Set<String> processedUrls = {};

      for (final id in actualActiveIds) {
        // Skip if we already processed this URL (since DownloadService returns URLs as IDs)
        if (processedUrls.contains(id)) {
          continue;
        }
        processedUrls.add(id);

        final DownloadStatus? status = await _downloadService.getStatus(id);
        if (status == DownloadStatus.downloading ||
            status == DownloadStatus.pending) {
          actualRunningCount++;
        }
      }
    } catch (e) {
      // If we can't get actual count, fall back to our internal tracking
      logger.w(
        '[DownloadQueueManager] Error getting actual running count: $e - using internal count',
      );
      actualRunningCount = _activeDownloads.length;
    }

    // Don't process if we're already at max capacity
    if (actualRunningCount >= maxConcurrentDownloads) {
      logger.d(
        '[DownloadQueueManager] Queue processing skipped: at max capacity (actualRunning=$actualRunningCount internal=${_activeDownloads.length}/$maxConcurrentDownloads) queueLength=${_queue.length}',
      );
      return;
    }

    if (_queue.isEmpty) {
      logger.d('[DownloadQueueManager] Queue is empty, nothing to process');
      return;
    }

    if (_activeDownloads.isNotEmpty) {
      logger.t(
        '[Downloading Queue] Active downloads: ${_activeDownloads.join(', ')}',
      );
    }

    // Process queue while we have capacity
    // Use actualRunningCount to determine capacity, not just _activeDownloads
    while (actualRunningCount < maxConcurrentDownloads && _queue.isNotEmpty) {
      // Peek at the first item
      final QueuedDownload queuedDownload = _queue.first;

      try {
        logger.d(
          '[Downloading Queue] Starting download: id=${queuedDownload.id} title="${queuedDownload.title}" reciter="${queuedDownload.reciterName}" activeCount=${_activeDownloads.length}',
        );

        // Start the download
        // DownloadService will emit progress updates when the download actually starts
        await DownloadService.startDownload(
          id: queuedDownload.id,
          url: queuedDownload.url,
          filePath: queuedDownload.filePath,
          title: queuedDownload.title,
          reciterName: queuedDownload.reciterName,
        );

        // Check the actual download status - only mark as active if it's running
        // If it's just enqueued, don't mark as active yet - wait for it to start
        DownloadStatus? actualStatus;
        // Increased retries to 10 and delay to 500ms (total 5s) to allow slower devices to register task
        for (var i = 0; i < 10; i++) {
          try {
            actualStatus = await DownloadService.getDownloadStatus(
              queuedDownload.url,
            );
            if (actualStatus != null) {
              break;
            }
            // If null, wait a bit and retry (race condition protection)
            if (i < 9) {
              await Future.delayed(const Duration(milliseconds: 500));
            }
          } catch (e) {
            logger.w('[Downloading Queue] Error checking status: $e');
          }
        }

        try {
          if (actualStatus == DownloadStatus.downloading) {
            // Only mark as active if it's actually running (not just enqueued)
            _activeDownloads.add(queuedDownload.id);
            _activeDownloadUrls[queuedDownload.id] =
                queuedDownload.url; // successful map url
            _lastActivityTime[queuedDownload.id] = clock
                .now(); // Initialize activity
            actualRunningCount++; // Increment our running count
            _queue.removeAt(0); // Successfully started, remove from queue
            _notifyQueueUpdate();

            // Notify user
            ToastUtils.showToast(
              msg: 'Starting download: ${queuedDownload.title}',
            );

            logger.d(
              '[Downloading Queue] Download is running: id=${queuedDownload.id} actualRunning=$actualRunningCount internal=${_activeDownloads.length} remainingQueue=${_queue.length}',
            );
          } else if (actualStatus == DownloadStatus.pending) {
            // Download is enqueued - mark as active so we don't flood the service
            _activeDownloads.add(queuedDownload.id);
            _activeDownloadUrls[queuedDownload.id] = queuedDownload.url;
            _lastActivityTime[queuedDownload.id] = clock
                .now(); // Initialize activity
            actualRunningCount++;
            _queue.removeAt(0); // Successfully enqueued, remove from queue
            _notifyQueueUpdate();

            logger.d(
              '[Downloading Queue] Download enqueued: id=${queuedDownload.id} status=$actualStatus - marking as active',
            );
          } else if (actualStatus == DownloadStatus.completed) {
            // Download already completed - skip it
            _queue.removeAt(0);
            _notifyQueueUpdate();

            logger.d(
              '[Downloading Queue] Download already completed: id=${queuedDownload.id} - skipping',
            );
          } else {
            // Download might be failed or in some other state (null means start failed)
            logger.e(
              '[Downloading Queue] Download failed to start (status=$actualStatus): id=${queuedDownload.id} - REMOVING from queue to prevent infinite loop',
            );
            // Remove from queue to prevent infinite retry loop
            _queue.removeAt(0);
            _notifyQueueUpdate();

            // Break the loop to avoid immediate processing of next item if this one failed badly
            break;
          }
        } catch (e) {
          // If status check fails, log but continue
          // The download might still start, and we'll get a progress update
          logger.w(
            '[Downloading Queue] Error checking download status: id=${queuedDownload.id} error=$e',
          );
          // If we can't verify status, assume it failed to be safe and don't remove from queue
          break;
        }
      } catch (e) {
        // If start fails, don't mark as active
        logger.e(
          '[Downloading Queue] Failed to start download: id=${queuedDownload.id} title="${queuedDownload.title}" error=$e activeCount=${_activeDownloads.length} remainingQueue=${_queue.length}',
        );
        // Break loop
        break;
      }
    }

    logger.d(
      '[Downloading Queue] Queue processing complete: actualRunning=$actualRunningCount internal=${_activeDownloads.length} queueLength=${_queue.length}',
    );
  }

  /// Handle download progress updates
  void _handleDownloadProgress(DownloadProgress progress) {
    // When a download starts running, mark it as active if not already marked
    if (progress.status == DownloadStatus.downloading) {
      if (!_activeDownloads.contains(progress.id)) {
        _activeDownloads.add(progress.id);
        // If we don't have the URL yet, assume progress.id IS the URL (since DownloadService usually emits URL)
        if (!_activeDownloadUrls.containsKey(progress.id)) {
          _activeDownloadUrls[progress.id] = progress.id;
        }
        logger.d(
          '[Downloading Queue] Download started running: id=${progress.id} activeCount=${_activeDownloads.length}',
        );
      }
      // Update activity time
      _lastActivityTime[progress.id] = clock.now();
    }

    // When a download completes or fails, remove it from active and process queue
    if (progress.status == DownloadStatus.completed ||
        progress.status == DownloadStatus.failed ||
        progress.status == DownloadStatus.cancelled) {
      // Try to remove using the ID we received (could be ID or URL)
      bool wasActive = _activeDownloads.remove(progress.id);

      // If not found directly, check if it's a URL for a tracked Composite ID
      if (!wasActive) {
        try {
          // Find key (Composite ID) where value (URL) matches progress.id
          final String compositeId = _activeDownloadUrls.entries
              .firstWhere(
                (entry) => entry.value == progress.id,
                orElse: () => const MapEntry('', ''),
              )
              .key;

          if (compositeId.isNotEmpty) {
            wasActive = _activeDownloads.remove(compositeId);
            // Also remove the entry from map since we found it
            _activeDownloadUrls.remove(compositeId);
          }
        } catch (e) {
          // Ignore error in lookup
        }
      }

      _activeDownloadUrls.remove(progress.id);
      _lastActivityTime.remove(progress.id); // Cleanup activity tracking
      logger.d(
        '[Downloading Queue] Download finished: id=${progress.id} status=${progress.status} wasActive=$wasActive activeCount=${_activeDownloads.length} queueLength=${_queue.length}',
      );

      // Immediately sync active downloads to ensure we have accurate count
      // Then process queue to start next download
      _syncActiveDownloads()
          .then((_) {
            // After syncing, process queue
            return _processQueue();
          })
          .catchError((error) {
            logger.e(
              '[Downloading Queue] Error syncing/processing queue after download completion: $error',
            );
            // Still try to process queue even if sync fails
            _processQueue().catchError((e) {
              logger.e('[Downloading Queue] Error processing queue: $e');
            });
          });
    }
  }

  /// Notify listeners of queue updates
  void _notifyQueueUpdate() {
    _queueUpdateController.add(
      QueueUpdate(
        queueLength: _queue.length,
        activeCount: _activeDownloads.length,
        queuedIds: _queue.map((d) => d.id).toList(),
        activeIds: _activeDownloads.toList(),
      ),
    );
  }

  /// Stream of queue updates
  Stream<QueueUpdate> get queueUpdates => _queueUpdateController.stream;

  /// Clear the queue
  void clearQueue() {
    _queue.clear();
    _notifyQueueUpdate();
    logger.d('[Downloading Queue] Queue cleared');
  }

  /// Sync active downloads with DownloadService to remove stale entries
  Future<void> _syncActiveDownloads() async {
    if (_activeDownloads.isEmpty) {
      return;
    }

    try {
      final List<String> actualActiveIds =
          await DownloadService.activeDownloadIds;
      final Set<String> actualActiveSet = actualActiveIds.toSet();

      // Find downloads that are marked as active but are no longer actually active
      // We check if the URL associated with the active ID is present in actualActiveSet
      final List<String> staleIds = _activeDownloads.where((id) {
        final String? url = _activeDownloadUrls[id];
        // If we have a URL, check against that. If not (fallback), check ID.
        if (url != null) {
          return !actualActiveSet.contains(url);
        }
        return !actualActiveSet.contains(id);
      }).toList();

      if (staleIds.isNotEmpty) {
        logger.d(
          '[Downloading Queue] Found ${staleIds.length} stale active downloads received update before event: $staleIds',
        );
        staleIds.forEach(_activeDownloads.remove);
        staleIds.forEach(_activeDownloadUrls.remove);
        staleIds.forEach(_lastActivityTime.remove);
        logger.d(
          '[Downloading Queue] Removed stale downloads. activeCount=${_activeDownloads.length} queueLength=${_queue.length}',
        );

        // Process queue to start next downloads
        unawaited(
          _processQueue().catchError((error) {
            logger.e(
              '[DownloadQueueManager] Error processing queue after sync: $error',
            );
          }),
        );
      }

      // Also add any active downloads that we missed
      // These are URLs from DownloadService that we don't have tracking for
      for (final url in actualActiveIds) {
        // Check if this URL is already tracked by ANY active ID
        final bool isTracked =
            _activeDownloadUrls.values.contains(url) ||
            _activeDownloads.contains(url);

        if (!isTracked) {
          _activeDownloads.add(url);
          _activeDownloadUrls[url] = url; // Map URL to itself
          _lastActivityTime[url] = clock
              .now(); // Initialize activity for rediscovered item
          logger.d(
            '[DownloadQueueManager] Added missing active download: $url. activeCount=${_activeDownloads.length}',
          );
        }
      }

      // watchdog: Check for stuck downloads (no activity for > 30 seconds)
      final DateTime now = clock.now();
      final List<String> stuckIds = [];

      for (final String id in _activeDownloads) {
        final DateTime? lastActivity = _lastActivityTime[id];
        if (lastActivity != null &&
            now.difference(lastActivity).inSeconds > 30) {
          stuckIds.add(id);
        }
      }

      for (final id in stuckIds) {
        logger.w(
          '[Downloading Queue] Watchdog: Download $id appears stuck (no activity for 30s). Cancelling.',
        );

        // Cancel the stuck download using its URL
        final String cancelId = _activeDownloadUrls[id] ?? id;
        await DownloadService.cancelDownload(cancelId);

        // Remove from tracking
        _activeDownloads.remove(id);
        _activeDownloadUrls.remove(id);
        _lastActivityTime.remove(id);

        // Note: Cancellation will eventually trigger _handleDownloadProgress
        // with status.cancelled, which will safely try to process the queue again.
        // But we proactively remove it here to unblock immediately if the callback is delayed.
      }

      if (stuckIds.isNotEmpty) {
        _notifyQueueUpdate();
        // Force process queue to fill the freed slots
        unawaited(
          _processQueue().catchError((e) {
            logger.e(
              '[DownloadQueueManager] Error processing queue after watchdog cleanup: $e',
            );
          }),
        );
      }
    } catch (e) {
      // If sync fails (e.g., in test environment), just log and continue
      logger.d('[DownloadQueueManager] Error syncing active downloads: $e');
    }
  }

  /// Dispose resources
  void dispose() {
    _progressSubscription?.cancel();
    _syncTimer?.cancel();
    _queueUpdateController.close();
    _queue.clear();
    _queue.clear();
    _activeDownloads.clear();
    _activeDownloadUrls.clear();
    _lastActivityTime.clear();
    _isInitialized = false;
    logger.d('[DownloadQueueManager] Disposed');
  }
}

/// Represents a download in the queue
class QueuedDownload {
  const QueuedDownload({
    required this.id,
    required this.url,
    required this.filePath,
    required this.title,
    required this.reciterName,
    required this.enqueuedAt,
  });

  final String id;
  final String url;
  final String filePath;
  final String title;
  final String reciterName;
  final DateTime enqueuedAt;
}

/// Represents a queue update event
class QueueUpdate {
  const QueueUpdate({
    required this.queueLength,
    required this.activeCount,
    required this.queuedIds,
    required this.activeIds,
  });

  final int queueLength;
  final int activeCount;
  final List<String> queuedIds;
  final List<String> activeIds;
}
