import 'dart:async';

import '../../../../main.dart';
import '../../domain/entities/download_item.dart';
import 'download_service.dart';

/// Manages a queue of pending downloads and controls concurrency
class DownloadQueueManager {
  DownloadQueueManager._();
  static final DownloadQueueManager instance = DownloadQueueManager._();

  // Maximum number of concurrent downloads
  static const int maxConcurrentDownloads = 2;

  // Queue of pending downloads
  final List<QueuedDownload> _queue = [];

  // Currently active downloads (running or enqueued in DownloadService)
  final Set<String> _activeDownloads = {};

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
      enqueuedAt: DateTime.now(),
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
      final List<String> actualActiveIds =
          await DownloadService.activeDownloadIds;
      // Filter to only count downloads that are actually running (not just enqueued)
      actualRunningCount = 0;
      for (final id in actualActiveIds) {
        final DownloadStatus? status = await DownloadService.getDownloadStatus(
          id,
        );
        if (status == DownloadStatus.downloading) {
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

    logger.d(
      '[DownloadQueueManager] Processing queue: actualRunning=$actualRunningCount internal=${_activeDownloads.length}/$maxConcurrentDownloads queueLength=${_queue.length}',
    );

    // Process queue while we have capacity
    // Use actualRunningCount to determine capacity, not just _activeDownloads
    while (actualRunningCount < maxConcurrentDownloads && _queue.isNotEmpty) {
      final QueuedDownload queuedDownload = _queue.removeAt(0);
      _notifyQueueUpdate();

      try {
        logger.d(
          '[DownloadQueueManager] Starting download: id=${queuedDownload.id} title="${queuedDownload.title}" reciter="${queuedDownload.reciterName}" activeCount=${_activeDownloads.length}',
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
        try {
          final DownloadStatus? actualStatus =
              await DownloadService.getDownloadStatus(queuedDownload.id);

          if (actualStatus == DownloadStatus.downloading) {
            // Only mark as active if it's actually running (not just enqueued)
            _activeDownloads.add(queuedDownload.id);
            actualRunningCount++; // Increment our running count
            logger.d(
              '[DownloadQueueManager] Download is running: id=${queuedDownload.id} actualRunning=$actualRunningCount internal=${_activeDownloads.length} remainingQueue=${_queue.length}',
            );
          } else if (actualStatus == DownloadStatus.pending) {
            // Download was enqueued but not running yet - don't mark as active
            // It will be marked as active when we receive the "running" status update
            logger.d(
              '[DownloadQueueManager] Download enqueued but not running yet: id=${queuedDownload.id} status=$actualStatus - will mark active when it starts',
            );
            // Don't mark as active - it will be added when we get the running status
            // Continue processing queue since this one isn't taking up a slot yet
          } else if (actualStatus == DownloadStatus.completed) {
            // Download already completed - skip it
            logger.d(
              '[DownloadQueueManager] Download already completed: id=${queuedDownload.id} - skipping',
            );
          } else {
            // Download might be failed or in some other state
            logger.d(
              '[DownloadQueueManager] Download in state: id=${queuedDownload.id} status=$actualStatus - not marking as active',
            );
          }
        } catch (e) {
          // If status check fails, log but continue
          // The download might still start, and we'll get a progress update
          logger.w(
            '[DownloadQueueManager] Error checking download status: id=${queuedDownload.id} error=$e',
          );
        }
      } catch (e) {
        // If start fails, don't mark as active
        logger.e(
          '[DownloadQueueManager] Failed to start download: id=${queuedDownload.id} title="${queuedDownload.title}" error=$e activeCount=${_activeDownloads.length} remainingQueue=${_queue.length}',
        );
        // Continue processing queue to try next download
      }
    }

    logger.d(
      '[DownloadQueueManager] Queue processing complete: actualRunning=$actualRunningCount internal=${_activeDownloads.length} queueLength=${_queue.length}',
    );
  }

  /// Handle download progress updates
  void _handleDownloadProgress(DownloadProgress progress) {
    // When a download starts running, mark it as active if not already marked
    if (progress.status == DownloadStatus.downloading) {
      if (!_activeDownloads.contains(progress.id)) {
        _activeDownloads.add(progress.id);
        logger.d(
          '[DownloadQueueManager] Download started running: id=${progress.id} activeCount=${_activeDownloads.length}',
        );
      }
    }

    // When a download completes or fails, remove it from active and process queue
    if (progress.status == DownloadStatus.completed ||
        progress.status == DownloadStatus.failed ||
        progress.status == DownloadStatus.cancelled) {
      final bool wasActive = _activeDownloads.remove(progress.id);
      logger.d(
        '[DownloadQueueManager] Download finished: id=${progress.id} status=${progress.status} wasActive=$wasActive activeCount=${_activeDownloads.length} queueLength=${_queue.length}',
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
              '[DownloadQueueManager] Error syncing/processing queue after download completion: $error',
            );
            // Still try to process queue even if sync fails
            _processQueue().catchError((e) {
              logger.e('[DownloadQueueManager] Error processing queue: $e');
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
    logger.d('[DownloadQueueManager] Queue cleared');
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
      final List<String> staleIds = _activeDownloads
          .where((id) => !actualActiveSet.contains(id))
          .toList();

      if (staleIds.isNotEmpty) {
        logger.w(
          '[DownloadQueueManager] Found ${staleIds.length} stale active downloads: $staleIds',
        );
        staleIds.forEach(_activeDownloads.remove);
        logger.d(
          '[DownloadQueueManager] Removed stale downloads. activeCount=${_activeDownloads.length} queueLength=${_queue.length}',
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
    _activeDownloads.clear();
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
