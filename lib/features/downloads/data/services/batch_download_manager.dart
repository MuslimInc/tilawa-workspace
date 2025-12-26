import 'dart:async';

import 'package:injectable/injectable.dart';

import '../../../../main.dart';
import '../../domain/entities/download_item.dart';
import '../models/download_progress.dart';
import 'download_notification_service.dart';
import 'download_service_interface.dart';

/// Manages batch downloads and their notifications
@lazySingleton
class BatchDownloadManager {
  BatchDownloadManager(this._downloadService, this._notificationService);

  final DownloadServiceInterface _downloadService;
  final DownloadNotificationService _notificationService;

  // Track active batches
  final Map<String, _BatchInfo> _activeBatches = {};

  // Stream subscription for progress updates
  StreamSubscription? _progressSubscription;

  /// Start tracking a new batch
  void startBatch({
    required String batchId,
    required String title,
    required List<String> downloadIds,
  }) {
    if (downloadIds.isEmpty) {
      return;
    }

    // Create batch info
    final batchInfo = _BatchInfo(
      id: batchId,
      title: title,
      itemIds: Set.from(downloadIds),
      totalItems: downloadIds.length,
    );

    _activeBatches[batchId] = batchInfo;

    // Ensure we are listening to updates
    _ensureListening();

    logger.d(
      '[BatchDownloadManager] Started batch $batchId with ${downloadIds.length} items',
    );

    // Initial notification
    _updateNotification(batchId);
  }

  /// Cancel a batch
  Future<void> cancelBatch(String batchId) async {
    final _BatchInfo? batch = _activeBatches[batchId];
    if (batch == null) {
      return;
    }

    logger.d('[BatchDownloadManager] Cancelling batch $batchId');

    // Cancel all items (Repository usually handles this, but we can helper here or just update UI)
    // Actually, repository should cancel items. We just update notification.

    _activeBatches.remove(batchId);
    await _notificationService.cancelNotification(batchId);

    _checkCleanup();
  }

  void _ensureListening() {
    if (_progressSubscription != null) {
      return;
    }

    _progressSubscription = _downloadService.globalProgressStream.listen(
      (progress) {
        _handleProgressUpdate(progress);
      },
      onError: (e) {
        logger.e('[BatchDownloadManager] Error in progress stream: $e');
      },
    );
  }

  void _handleProgressUpdate(DownloadProgress progress) {
    if (_activeBatches.isEmpty) {
      return;
    }

    final List<String> batchesToRemove = [];

    for (final _BatchInfo batch in _activeBatches.values) {
      if (batch.itemIds.contains(progress.id)) {
        // Update item progress
        batch.updateItemProgress(progress);

        // Update notification
        _updateNotification(batch.id);

        // Check if batch is complete
        if (batch.isFinished) {
          // We might want to keep the "Completed" notification for a bit or until dismissed
          // For now, we leave it as "Completed" status in notification service
          // and remove from active tracking after a delay or immediately?
          // If we remove immediately, we stop updating.

          if (batch.isFullyCompleted) {
            batchesToRemove.add(batch.id);
          }
        }
      }
    }

    // Remove finished batches from active tracking
    batchesToRemove.forEach(_activeBatches.remove);

    _checkCleanup();
  }

  void _updateNotification(String batchId) {
    final _BatchInfo? batch = _activeBatches[batchId];
    if (batch == null) {
      return;
    }

    _notificationService.showBatchDownloadProgress(
      batchId: batch.id,
      title: batch.title,
      progress: batch.overallProgress,
      completedCount: batch.completedCount,
      totalCount: batch.totalItems,
      status: batch.status,
    );
  }

  void _checkCleanup() {
    if (_activeBatches.isEmpty) {
      _progressSubscription?.cancel();
      _progressSubscription = null;
    }
  }
}

class _BatchInfo {
  _BatchInfo({
    required this.id,
    required this.title,
    required this.itemIds,
    required this.totalItems,
  });

  final String id;
  final String title;
  final Set<String> itemIds;
  final int totalItems;

  // Progress tracking
  int completedCount = 0;
  int failedCount = 0;
  int cancelledCount = 0;
  final Map<String, int> _itemProgress = {};

  void updateItemProgress(DownloadProgress progress) {
    // track status
    if (progress.status == DownloadStatus.completed) {
      if (!_itemProgress.containsKey(progress.id) ||
          _itemProgress[progress.id] != 100) {
        _itemProgress[progress.id] = 100;
        completedCount++;
      }
    } else if (progress.status == DownloadStatus.failed) {
      // If it failed, we count it as processed
      if (!_itemProgress.containsKey(progress.id) ||
          _itemProgress[progress.id] != -1) {
        _itemProgress[progress.id] = -1; // mark as failed
        failedCount++;
      }
    } else if (progress.status == DownloadStatus.cancelled) {
      if (!_itemProgress.containsKey(progress.id) ||
          _itemProgress[progress.id] != -2) {
        _itemProgress[progress.id] = -2; // mark as cancelled
        cancelledCount++;
      }
    } else {
      // Running
      _itemProgress[progress.id] = (progress.progress * 100).toInt();
    }
  }

  int get overallProgress {
    if (totalItems == 0) {
      return 0;
    }

    double totalProgressSum = 0;

    for (final String id in itemIds) {
      final int? p = _itemProgress[id];
      if (p != null) {
        if (p == -1 || p == -2) {
          // failed or cancelled, count as 0 or 100?
          // Usually for batch progress, we might just count them as done (100) but failed.
          // Or 0. Let's say 100 explicitly so the bar fills up.
          totalProgressSum += 100;
        } else {
          totalProgressSum += p;
        }
      }
    }

    return (totalProgressSum / totalItems).floor();
  }

  DownloadStatus get status {
    if (isFinished) {
      if (failedCount > 0 && completedCount == 0) {
        return DownloadStatus.failed;
      }
      return DownloadStatus.completed;
    }
    return DownloadStatus.downloading;
  }

  bool get isFinished =>
      (completedCount + failedCount + cancelledCount) >= totalItems;

  // Helper to know if we are done-done (like all success or mix)
  bool get isFullyCompleted => isFinished;
}
