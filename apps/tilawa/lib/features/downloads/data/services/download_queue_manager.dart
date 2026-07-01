import 'dart:async';
import 'dart:ui';

import 'package:clock/clock.dart';
import 'package:flutter/foundation.dart';
import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';
import 'package:tilawa_core/config/language_config.dart';

import '../../../../l10n/generated/app_localizations.dart';
import 'package:tilawa/core/logging/app_logger.dart';
import '../../domain/entities/download_item.dart';
import '../../domain/services/download_notification_service_interface.dart';
import '../../domain/services/download_queue_service_interface.dart';
import '../models/download_progress.dart';
import 'download_service_interface.dart';

/// Manages a queue of pending downloads and controls concurrency
@LazySingleton()
class DownloadQueueManager implements IDownloadQueueService {
  DownloadQueueManager(this._downloadService, this._notificationService);

  final DownloadServiceInterface _downloadService;
  final IDownloadNotificationService _notificationService;

  // Maximum number of concurrent downloads
  int _maxConcurrentDownloads = 2; // Default to 2

  /// Set the maximum number of concurrent downloads
  @override
  set maxConcurrentDownloads(int count) {
    if (count < 1) {
      return;
    }
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
  @override
  int get maxConcurrentDownloads => _maxConcurrentDownloads;

  // Current locale for localized notification messages
  Locale locale = Locale(LanguageConfig.defaultLanguageCode);

  // Queue of pending downloads
  final List<QueuedDownload> _queue = [];

  // Currently active downloads (running or enqueued in DownloadService)
  final Set<String> _activeDownloads = {};

  // Track URLs of active downloads to map IDs to URLs for sync
  final Map<String, String> _activeDownloadUrls = {};

  // Track download metadata (title, reciter, reciterId, showNotification) for notifications
  final Map<
    String,
    ({String title, String reciterName, int? reciterId, bool showNotification})
  >
  _downloadMetadata = {};

  // Track last activity time for each active download to detect stuck ones
  final Map<String, DateTime> _lastActivityTime = {};

  // Last platform-reported progress (0.0–1.0) per active download
  final Map<String, double> _lastKnownProgress = {};

  /// How often we reconcile with [DownloadServiceInterface.getActiveDownloadIds].
  static const Duration _syncInterval = Duration(seconds: 30);

  /// Running downloads with no stream updates must be idle this long before
  /// cancellation, after verifying the platform task is not advancing.
  static const Duration _runningStuckTimeout = Duration(minutes: 2);

  /// Enqueued downloads may wait longer before the server starts sending data.
  static const Duration _enqueuedStuckTimeout = Duration(minutes: 5);

  // Stream controller for queue updates
  final StreamController<QueueUpdate> _queueUpdateController =
      StreamController<QueueUpdate>.broadcast();

  StreamSubscription<DownloadProgress>? _progressSubscription;
  Timer? _syncTimer;
  bool _isInitialized = false;
  bool _isDisposed = false;
  bool _isProcessingQueue = false;
  bool _isSyncing = false;

  /// Initialize the queue manager and listen to download progress
  Future<void> initialize() async {
    if (_isInitialized) {
      return;
    }

    // Listen to download progress to know when downloads complete
    _progressSubscription = _downloadService.globalProgressStream.listen(
      (progress) {
        _handleDownloadProgress(progress);
      },
      onError: (Object error) {
        logger.e('[DownloadQueueManager] Error in progress stream: $error');
      },
    );

    // Initial sync
    await _syncActiveDownloads();

    // Periodically sync active downloads with DownloadService
    // This ensures we don't have stale entries in _activeDownloads
    // Raised to 30 seconds since the primary event source is now the stream
    _syncTimer = Timer.periodic(_syncInterval, (_) {
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
    int? reciterId,
    bool showNotification = false,
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
      reciterId: reciterId,
      showNotification: showNotification,
      enqueuedAt: clock.now(),
    );

    _queue.add(queuedDownload);
    _downloadMetadata[id] = (
      title: title,
      reciterName: reciterName,
      reciterId: reciterId,
      showNotification: showNotification,
    );
    _notifyQueueUpdate();

    logger.d(
      '[DownloadQueueManager] Enqueued download: id=$id title="$title" queuePosition=${_queue.length}',
    );

    // Try to process the queue
    await _processQueue();
  }

  /// Restore queue metadata for a platform task that survived process restart.
  ///
  /// Does not re-enqueue; used when [resumePendingDownloads] finds an active
  /// download so notification progress can reconcile with the same ID.
  Future<void> trackInFlightDownload({
    required String id,
    required String url,
    required String title,
    required String reciterName,
    int? reciterId,
    bool showNotification = false,
  }) async {
    await initialize();

    if (_downloadMetadata.containsKey(id)) {
      return;
    }

    _downloadMetadata[id] = (
      title: title,
      reciterName: reciterName,
      reciterId: reciterId,
      showNotification: showNotification,
    );
    _activeDownloadUrls[id] = url;
    _activeDownloads.add(id);
    _lastActivityTime[id] = clock.now();

    logger.d(
      '[DownloadQueueManager] Tracked in-flight download after restart: id=$id',
    );
  }

  /// Add multiple downloads to the queue efficiently
  Future<void> enqueueBatch(
    List<
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
    items,
  ) async {
    await initialize();

    var addedCount = 0;
    for (final item in items) {
      // Check if already in queue or active
      if (_isInQueue(item.id) || _activeDownloads.contains(item.id)) {
        continue;
      }

      final queuedDownload = QueuedDownload(
        id: item.id,
        url: item.url,
        filePath: item.filePath,
        title: item.title,
        reciterName: item.reciterName,
        reciterId: item.reciterId,
        showNotification: item.showNotification,
        enqueuedAt: clock.now(),
      );

      _queue.add(queuedDownload);
      _downloadMetadata[item.id] = (
        title: item.title,
        reciterName: item.reciterName,
        reciterId: item.reciterId,
        showNotification: item.showNotification,
      );
      addedCount++;
    }

    if (addedCount > 0) {
      _notifyQueueUpdate();
      logger.d(
        '[DownloadQueueManager] Enqueued batch of $addedCount downloads. New queue length: ${_queue.length}',
      );
      // Process queue once for the whole batch
      await _processQueue();
    }
  }

  /// Remove a download from the queue
  @override
  void removeFromQueue(String id) {
    _queue.removeWhere((download) => download.id == id);
    _downloadMetadata.remove(id);
    _notifyQueueUpdate();
    logger.d('[DownloadQueueManager] Removed from queue: id=$id');
  }

  /// Check if a download is in the queue
  bool _isInQueue(String id) {
    return _queue.any((download) => download.id == id);
  }

  /// Get queue position for a download (1-based, -1 if not in queue)
  @override
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
    if (_isProcessingQueue || _isDisposed) {
      return;
    }

    _isProcessingQueue = true;
    try {
      // First, sync active downloads to ensure we have accurate count
      await _syncActiveDownloads();

      // Check actual running downloads from DownloadService
      int actualRunningCount;
      try {
        final List<String> actualActiveIds = await _downloadService
            .getActiveDownloadIds();
        // Filter to only count downloads that are actually running (not just enqueued)
        actualRunningCount = 0;

        // Use a Set of normalized URLs to avoid counting duplicate URLs multiple times
        final Set<String> processedUrls = {};

        for (final id in actualActiveIds) {
          final String norm = _normalizeUrlString(id);

          // Skip if we already processed this normalized URL
          if (processedUrls.contains(norm)) {
            continue;
          }
          processedUrls.add(norm);

          final DownloadStatus? status = await _downloadService.getStatus(id);
          if (status == DownloadStatus.downloading ||
              status == DownloadStatus.pending) {
            actualRunningCount++;
          }
        }
      } catch (e) {
        if (_isDisposed) {
          return;
        }
        // If we can't get actual running count, it's safer to stop processing for now
        // to avoid exceeding maxConcurrentDownloads or starting redundant tasks.
        logger.w(
          '[DownloadQueueManager] Error getting actual running count: $e - skipping queue processing until next attempt',
        );
        return;
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
          // Immediately mark as active so that any background events during await
          // (like immediate completion) are properly handled by _handleDownloadProgress.
          _activeDownloads.add(queuedDownload.id);
          _activeDownloadUrls[queuedDownload.id] = queuedDownload.url;
          _lastActivityTime[queuedDownload.id] = clock.now();
          _lastKnownProgress[queuedDownload.id] = 0;
          actualRunningCount++;

          // Start the download
          // DownloadService will emit progress updates when the download actually starts
          await _downloadService.download(
            id: queuedDownload.id,
            url: queuedDownload.url,
            filePath: queuedDownload.filePath,
            title: queuedDownload.title,
            reciterName: queuedDownload.reciterName,
            reciterId: queuedDownload.reciterId,
            showNotification: queuedDownload.showNotification,
          );

          // Check if disposed after await
          if (_isDisposed) {
            return;
          }

          if (_queue.isNotEmpty && _queue.first.id == queuedDownload.id) {
            _queue.removeAt(0); // Successfully dispatched, remove from queue
          }

          _notifyQueueUpdate();
        } catch (e) {
          // If start fails, don't mark as active
          _activeDownloads.remove(queuedDownload.id);
          _activeDownloadUrls.remove(queuedDownload.id);
          _lastActivityTime.remove(queuedDownload.id);
          _lastKnownProgress.remove(queuedDownload.id);
          actualRunningCount--;

          logger.e(
            '[Downloading Queue] Failed to start download: id=${queuedDownload.id} title="${queuedDownload.title}" error=$e activeCount=${_activeDownloads.length} remainingQueue=${_queue.length}',
          );

          // Ensure UI is not stuck in pending, catching any platform exceptions
          try {
            await _downloadService.cancel(queuedDownload.id);
          } catch (cancelError) {
            logger.w(
              '[Downloading Queue] Error cancelling failed download: id=${queuedDownload.id} error=$cancelError',
            );
          }

          // Remove from queue?
          if (_queue.isNotEmpty && _queue.first.id == queuedDownload.id) {
            _queue.removeAt(0);
            _notifyQueueUpdate();
          }

          // Break loop
          break;
        }
      }

      logger.d(
        '[Downloading Queue] Queue processing complete: actualRunning=$actualRunningCount internal=${_activeDownloads.length} queueLength=${_queue.length}',
      );
    } finally {
      _isProcessingQueue = false;
    }
  }

  /// Normalize a URL/ID string for comparison.
  ///
  /// This trims whitespace and attempts to parse as a URI, normalizing duplicate
  /// slashes in the path. If parsing fails, returns the trimmed input.
  String _normalizeUrlString(String? input) {
    if (input == null) {
      return '';
    }
    final String trimmed = input.trim();
    try {
      final Uri uri = Uri.parse(trimmed);
      final String normalizedPath = uri.path.replaceAll(RegExp('/+'), '/');
      final Uri normalized = uri.replace(path: normalizedPath);
      return normalized.toString();
    } catch (_) {
      return trimmed;
    }
  }

  /// Find metadata for a download by matching against active download URLs
  ({String title, String reciterName, int? reciterId, bool showNotification})?
  _findMetadataByUrl(String url) {
    final String normalizedUrl = _normalizeUrlString(url);
    for (final MapEntry<String, String> entry in _activeDownloadUrls.entries) {
      if (_normalizeUrlString(entry.value) == normalizedUrl) {
        return _downloadMetadata[entry.key];
      }
    }
    return null;
  }

  /// Resolve a stable notification/download key for progress events.
  ///
  /// Progress events may use a URL variant while metadata is keyed by enqueue id.
  String _resolveNotificationDownloadId(String progressId) {
    if (_downloadMetadata.containsKey(progressId)) {
      return progressId;
    }

    final String normalizedProgressId = _normalizeUrlString(progressId);

    for (final MapEntry<String, String> entry in _activeDownloadUrls.entries) {
      if (_normalizeUrlString(entry.key) == normalizedProgressId ||
          _normalizeUrlString(entry.value) == normalizedProgressId) {
        return entry.key;
      }
    }

    for (final String key in _downloadMetadata.keys) {
      if (_normalizeUrlString(key) == normalizedProgressId) {
        return key;
      }
    }

    return progressId;
  }

  /// Handle download progress updates
  void _handleDownloadProgress(DownloadProgress progress) {
    // Find metadata for this download (could be by ID or URL)
    final ({
      String reciterName,
      String title,
      int? reciterId,
      bool showNotification,
    })?
    metadata =
        _downloadMetadata[progress.id] ?? _findMetadataByUrl(progress.id);

    final String notificationDownloadId = _resolveNotificationDownloadId(
      progress.id,
    );

    // Show notification only if requested (usually for individual downloads, not batches)
    if (metadata != null && metadata.showNotification) {
      // Get localized strings based on current locale
      final AppLocalizations l10n = lookupAppLocalizations(locale);
      final int progressPercent = progress.status == DownloadStatus.completed
          ? 100
          : (progress.progress * 100).round();

      unawaited(
        _notificationService.showDownloadProgress(
          downloadId: notificationDownloadId,
          title: metadata.title,
          reciterName: metadata.reciterName,
          reciterId: metadata.reciterId,
          progress: progressPercent,
          status: progress.status,
          pendingMessage: l10n.notificationWaitingToStart,
          progressMessage: l10n.notificationDownloadingProgress(
            progressPercent,
          ),
          completeMessage: l10n.notificationDownloadComplete,
          failedMessage: l10n.notificationDownloadFailed,
        ),
      );
    } else if (progress.status == DownloadStatus.completed ||
        progress.status == DownloadStatus.failed ||
        progress.status == DownloadStatus.cancelled) {
      // Clear any orphaned progress notification when metadata was already removed.
      unawaited(
        _notificationService.cancelNotification(notificationDownloadId),
      );
    }

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
      _lastKnownProgress[progress.id] = progress.progress;
    }

    // When a download completes or fails, remove it from active and process queue
    if (progress.status == DownloadStatus.completed ||
        progress.status == DownloadStatus.failed ||
        progress.status == DownloadStatus.cancelled) {
      // Try to remove using the ID we received (could be ID or URL)
      bool wasActive = _activeDownloads.remove(progress.id);

      // If not found directly, check for keys where the URL/value matches (normalized)
      if (!wasActive) {
        try {
          final String normalizedProgressId = _normalizeUrlString(progress.id);

          // Try direct value match (normalized)
          final String compositeId = _activeDownloadUrls.entries
              .firstWhere(
                (entry) =>
                    _normalizeUrlString(entry.value) == normalizedProgressId,
                orElse: () => const MapEntry('', ''),
              )
              .key;

          if (compositeId.isNotEmpty) {
            wasActive = _activeDownloads.remove(compositeId);
            _activeDownloadUrls.remove(compositeId);
            _lastActivityTime.remove(compositeId);
            _lastKnownProgress.remove(compositeId);
          }
        } catch (e) {
          // Ignore error in lookup
        }
      }

      // Also remove any entries keyed by the progress.id (or its normalized form)
      final String normProgress = _normalizeUrlString(progress.id);
      final List<String> keysToRemove = _activeDownloadUrls.entries
          .where(
            (e) =>
                _normalizeUrlString(e.key) == normProgress ||
                _normalizeUrlString(e.value) == normProgress,
          )
          .map((e) => e.key)
          .toList();

      for (final key in keysToRemove) {
        _activeDownloadUrls.remove(key);
        _activeDownloads.remove(key);
        _lastActivityTime.remove(key);
        _lastKnownProgress.remove(key);
        wasActive = true;
      }

      // Cleanup any direct keys matching the raw progress.id
      _activeDownloadUrls.remove(progress.id);
      _lastActivityTime.remove(progress.id); // Cleanup activity tracking
      _lastKnownProgress.remove(progress.id);
      _downloadMetadata.remove(progress.id); // Cleanup notification metadata

      // Also cleanup metadata for normalized keys
      keysToRemove.forEach(_downloadMetadata.remove);

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
    if (_isDisposed || _queueUpdateController.isClosed) {
      return;
    }
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
    // Remove metadata for items that were queued but never became active.
    for (final item in _queue) {
      _downloadMetadata.remove(item.id);
    }
    _queue.clear();
    _notifyQueueUpdate();
    logger.d('[Downloading Queue] Queue cleared');
  }

  /// Atomically remove all queued (not yet active) downloads for a reciter.
  ///
  /// Must be called synchronously before any async cancel work so that
  /// [_processQueue] — which is triggered by completed/cancelled events —
  /// cannot pick up new items for this reciter while the cancel loop is
  /// running.
  @override
  void dequeueForReciter(String reciterName) {
    final String normalizedName = reciterName.toLowerCase();
    final List<String> removedIds = _queue
        .where((item) => item.reciterName.toLowerCase() == normalizedName)
        .map((item) => item.id)
        .toList();

    if (removedIds.isEmpty) {
      return;
    }

    _queue.removeWhere(
      (item) => item.reciterName.toLowerCase() == normalizedName,
    );

    // Clean up metadata for dequeued items — they will never become active
    // and so _handleDownloadProgress will never remove their entries.
    for (final id in removedIds) {
      _downloadMetadata.remove(id);
    }

    _notifyQueueUpdate();
    logger.d(
      '[DownloadQueueManager] Dequeued ${removedIds.length} items for reciter "$reciterName"',
    );
  }

  /// Stop all downloads and clear the queue
  Future<void> stopAll() async {
    _queue.clear();

    // Cancel through service (this handles platform cancel + progress emission)
    await _downloadService.cancelAll();

    // Clear local state
    _activeDownloads.clear();
    _activeDownloadUrls.clear();
    _downloadMetadata.clear();
    _lastActivityTime.clear();
    _lastKnownProgress.clear();

    // Hide any batch notifications
    await _notificationService.cancelAllNotifications();

    _notifyQueueUpdate();
    logger.d('[DownloadQueueManager] Stopped all downloads and cleared queue');
  }

  /// Sync active downloads with DownloadService to remove stale entries
  /// Sync active downloads with DownloadService to remove stale entries
  Future<void> _syncActiveDownloads() async {
    if (_isSyncing || _isDisposed) {
      return;
    }
    _isSyncing = true;
    try {
      final List<String> actualActiveIds = await _downloadService
          .getActiveDownloadIds();

      if (_isDisposed) {
        return;
      }

      final Set<String> actualActiveSet = actualActiveIds
          .map(_normalizeUrlString)
          .toSet();

      // Find downloads that are marked as active but are no longer actually active
      // We normalize both sides for robust comparison (IDs or URLs)
      final List<String> staleIds = _activeDownloads.where((id) {
        final String? url = _activeDownloadUrls[id];
        final String key = _normalizeUrlString(url ?? id);
        return !actualActiveSet.contains(key);
      }).toList();

      if (staleIds.isNotEmpty) {
        logger.d(
          '[Downloading Queue] Found ${staleIds.length} stale active downloads received update before event: $staleIds',
        );
        // Fix: Ensure we also cleanup any stuck notifications for these stale downloads
        for (final id in staleIds) {
          // Check if we have metadata for this download (meaning we might have shown a notification)
          // Use ID or URL for lookup
          final normalizedId = _normalizeUrlString(id);

          String? metadataKey;
          if (_downloadMetadata.containsKey(id)) {
            metadataKey = id;
          } else {
            // Try to find by URL
            try {
              metadataKey = _downloadMetadata.keys.firstWhere(
                (k) => _normalizeUrlString(k) == normalizedId,
                orElse: () => '',
              );
            } catch (_) {}
          }

          if (metadataKey != null && metadataKey.isNotEmpty) {
            final meta = _downloadMetadata[metadataKey];
            if (meta != null && meta.showNotification) {
              logger.d(
                '[Downloading Queue] Cancelling stuck notification for stale download: $id',
              );
              _notificationService.cancelNotification(
                _resolveNotificationDownloadId(metadataKey),
              );
            }
            _downloadMetadata.remove(metadataKey);
          }

          // Fallback: also try to remove by the stale ID itself directly just in case
          if (metadataKey != id) {
            _downloadMetadata.remove(id);
            _notificationService.cancelNotification(
              _resolveNotificationDownloadId(id),
            );
          }
        }

        staleIds.forEach(_activeDownloads.remove);
        staleIds.forEach(_activeDownloadUrls.remove);
        staleIds.forEach(_lastActivityTime.remove);
        staleIds.forEach(_lastKnownProgress.remove);
        logger.d(
          '[Downloading Queue] Removed stale downloads and cleaned up notifications. activeCount=${_activeDownloads.length} queueLength=${_queue.length}',
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
        final String norm = _normalizeUrlString(url);
        // Check if this URL is already tracked by ANY active ID (normalized)
        final bool isTracked =
            _activeDownloadUrls.values
                .map(_normalizeUrlString)
                .contains(norm) ||
            _activeDownloads.map(_normalizeUrlString).contains(norm);

        if (!isTracked) {
          // Use the normalized key for internal tracking to avoid duplicates
          _activeDownloads.add(norm);
          _activeDownloadUrls[norm] = url; // Map normalized -> original url
          _lastActivityTime[norm] = clock.now(); // Initialize activity
          _lastKnownProgress.putIfAbsent(norm, () => 0);
          logger.d(
            '[DownloadQueueManager] Added missing active download: $url (normalized: $norm). activeCount=${_activeDownloads.length}',
          );
        }
      }

      // Watchdog: cancel only when the platform task is idle past the timeout.
      final DateTime now = clock.now();
      final List<String> stuckIds = [];

      for (final String id in Set<String>.from(_activeDownloads)) {
        final String lookupId = _activeDownloadUrls[id] ?? id;
        final bool shouldCancel = await _shouldCancelStuckDownload(
          trackingId: id,
          lookupId: lookupId,
          actualActiveSet: actualActiveSet,
          now: now,
        );
        if (shouldCancel) {
          stuckIds.add(id);
        }
      }

      for (final id in stuckIds) {
        logger.d(
          '[Downloading Queue] Watchdog: Download $id appears stuck '
          '(no progress for ${_runningStuckTimeout.inSeconds}s). Cancelling.',
        );

        // Cancel the stuck download using its URL, catching platform exceptions
        final String cancelId = _activeDownloadUrls[id] ?? id;
        try {
          await _downloadService.cancel(cancelId);
        } catch (e) {
          logger.w(
            '[Downloading Queue] Error cancelling stuck download $cancelId: $e',
          );
        }

        if (_isDisposed) {
          return;
        }

        // Remove from tracking
        _activeDownloads.remove(id);
        _activeDownloadUrls.remove(id);
        _lastActivityTime.remove(id);
        _lastKnownProgress.remove(id);

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
      logger.w('[DownloadQueueManager] Error syncing active downloads: $e');
    } finally {
      _isSyncing = false;
    }
  }

  /// Returns true when a tracked download should be cancelled as stuck.
  @visibleForTesting
  Future<bool> shouldCancelStuckDownloadForTest({
    required String trackingId,
    required String lookupId,
    required Set<String> actualActiveSet,
    required DateTime now,
  }) {
    return _shouldCancelStuckDownload(
      trackingId: trackingId,
      lookupId: lookupId,
      actualActiveSet: actualActiveSet,
      now: now,
    );
  }

  Future<bool> _shouldCancelStuckDownload({
    required String trackingId,
    required String lookupId,
    required Set<String> actualActiveSet,
    required DateTime now,
  }) async {
    final DateTime? lastActivity = _lastActivityTime[trackingId];
    if (lastActivity == null) {
      return false;
    }

    final Duration elapsed = now.difference(lastActivity);
    final String normalizedLookup = _normalizeUrlString(lookupId);

    if (!actualActiveSet.contains(normalizedLookup)) {
      return elapsed >= _runningStuckTimeout;
    }

    final DownloadProgress? platformProgress = await _downloadService
        .getDownloadProgress(lookupId);
    if (platformProgress == null) {
      return elapsed >= _runningStuckTimeout;
    }

    if (platformProgress.status == DownloadStatus.paused) {
      return false;
    }

    final double lastProgress = _lastKnownProgress[trackingId] ?? -1;
    if (platformProgress.progress > lastProgress) {
      _lastKnownProgress[trackingId] = platformProgress.progress;
      _lastActivityTime[trackingId] = now;
      return false;
    }

    final Duration timeout = platformProgress.status == DownloadStatus.pending
        ? _enqueuedStuckTimeout
        : _runningStuckTimeout;
    return elapsed >= timeout;
  }

  /// Dispose resources
  void dispose() {
    _isDisposed = true;
    _progressSubscription?.cancel();
    _syncTimer?.cancel();
    _queueUpdateController.close();
    _queue.clear();
    _activeDownloads.clear();
    _activeDownloadUrls.clear();
    _lastActivityTime.clear();
    _lastKnownProgress.clear();
    _isInitialized = false;
    logger.d('[DownloadQueueManager] Disposed');
  }
}

/// Represents a download in the queue
class QueuedDownload extends Equatable {
  const QueuedDownload({
    required this.id,
    required this.url,
    required this.filePath,
    required this.title,
    required this.reciterName,
    this.reciterId,
    this.showNotification = false,
    required this.enqueuedAt,
  });

  final String id;
  final String url;
  final String filePath;
  final String title;
  final String reciterName;
  final int? reciterId;
  final bool showNotification;
  final DateTime enqueuedAt;

  @override
  List<Object?> get props => [
    id,
    url,
    filePath,
    title,
    reciterName,
    reciterId,
    showNotification,
    enqueuedAt,
  ];
}

/// Represents a queue update event
class QueueUpdate extends Equatable {
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

  @override
  List<Object?> get props => [queueLength, activeCount, queuedIds, activeIds];
}
