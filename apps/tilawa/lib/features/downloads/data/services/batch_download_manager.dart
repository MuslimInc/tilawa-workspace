import 'dart:async';
import 'dart:convert';

import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../main.dart';
import '../../domain/entities/download_item.dart';
import '../../domain/services/download_notification_service_interface.dart';
import '../models/download_progress.dart';
import 'download_service_interface.dart';

/// Manages batch downloads and their notifications
@lazySingleton
class BatchDownloadManager {
  BatchDownloadManager(
    this._downloadService,
    this._notificationService,
    this._prefs,
  );

  final DownloadServiceInterface _downloadService;
  final IDownloadNotificationService _notificationService;
  final SharedPreferencesAsync _prefs;

  static const String _storageKey = 'batch_downloads_data';

  // Track active batches
  final Map<String, _BatchInfo> _activeBatches = {};
  // Reverse map for O(1) lookups during progress updates
  final Map<String, String> _downloadIdToBatchId = {};
  bool _isDisposed = false;

  // Stream subscription for progress updates
  StreamSubscription? _progressSubscription;

  /// Initialize and restore any persisted batches
  Future<void> initialize() async {
    try {
      final String? data = await _prefs.getString(_storageKey);
      if (data == null || data.isEmpty) {
        return;
      }

      final Map<String, dynamic> decoded = jsonDecode(data);
      for (final entry in decoded.entries) {
        final String batchId = entry.key;
        final _BatchInfo batchInfo = _BatchInfo.fromJson(
          entry.value as Map<String, dynamic>,
        );

        // Fetch initial state for each item in the batch
        for (final itemId in batchInfo.itemIds) {
          _downloadIdToBatchId[itemId] = batchId;
          final DownloadProgress? progress = await _downloadService
              .getDownloadProgress(itemId);
          if (progress != null) {
            batchInfo.updateItemProgress(progress);
          }
        }

        _activeBatches[batchId] = batchInfo;
        logger.i('[BatchDownloadManager] Restored batch: $batchId');

        // Resume notification if not finished
        if (!batchInfo.isFinished) {
          _updateNotification(batchId);
        }
      }

      if (_activeBatches.isNotEmpty) {
        _ensureListening();
      }
    } catch (e) {
      logger.e('[BatchDownloadManager] Error during initialization: $e');
    }
  }

  /// Persist current active batches
  Future<void> _persistBatches() async {
    try {
      if (_activeBatches.isEmpty) {
        await _prefs.remove(_storageKey);
        return;
      }

      final Map<String, dynamic> data = _activeBatches.map(
        (key, value) => MapEntry(key, value.toJson()),
      );
      await _prefs.setString(_storageKey, jsonEncode(data));
    } catch (e) {
      logger.e('[BatchDownloadManager] Error persisting batches: $e');
    }
  }

  /// Start tracking a new batch
  void startBatch({
    required String batchId,
    required String title,
    required List<String> downloadIds,
    String? reciterName,
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
      reciterName: reciterName,
    );

    _activeBatches[batchId] = batchInfo;
    for (final id in downloadIds) {
      _downloadIdToBatchId[id] = batchId;
    }

    // Ensure we are listening to updates
    _ensureListening();

    logger.d(
      '[BatchDownloadManager] Started batch $batchId with ${downloadIds.length} items',
    );

    // Initial notification
    _updateNotification(batchId);
    _persistBatches();
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

    for (final id in batch.itemIds) {
      _downloadIdToBatchId.remove(id);
    }
    _activeBatches.remove(batchId);
    await _notificationService.cancelNotification(batchId);

    await _persistBatches();
    _checkCleanup();
  }

  /// Cancel all active batches for a specific reciter
  /// Used when user pauses/cancels downloads for a specific reciter
  Future<void> cancelBatchesForReciter(String reciterName) async {
    if (_activeBatches.isEmpty) {
      return;
    }

    // Find batches belonging to this reciter
    final List<String> batchIdsToCancel = _activeBatches.entries
        .where((entry) => entry.value.reciterName == reciterName)
        .map((entry) => entry.key)
        .toList();

    if (batchIdsToCancel.isEmpty) {
      logger.d(
        '[BatchDownloadManager] No batches found for reciter: $reciterName',
      );
      return;
    }

    logger.d(
      '[BatchDownloadManager] Cancelling ${batchIdsToCancel.length} batches for reciter: $reciterName',
    );

    // Cancel each batch notification and remove from tracking
    for (final String batchId in batchIdsToCancel) {
      await _notificationService.cancelNotification(batchId);
      final batch = _activeBatches[batchId];
      if (batch != null) {
        for (final id in batch.itemIds) {
          _downloadIdToBatchId.remove(id);
        }
      }
      _activeBatches.remove(batchId);
    }

    await _persistBatches();
    _checkCleanup();
  }

  /// Cancel all active batches and their notifications
  /// Used when user pauses/cancels all downloads
  Future<void> cancelAllBatches() async {
    if (_activeBatches.isEmpty) {
      return;
    }

    logger.d(
      '[BatchDownloadManager] Cancelling all ${_activeBatches.length} active batches',
    );

    // Get all batch IDs first to avoid modifying map while iterating
    final List<String> batchIds = _activeBatches.keys.toList();

    // Cancel each batch notification
    for (final String batchId in batchIds) {
      await _notificationService.cancelNotification(batchId);
    }

    // Clear all active batches
    _activeBatches.clear();
    _downloadIdToBatchId.clear();

    await _persistBatches();
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

    final String? batchId = _downloadIdToBatchId[progress.id];
    if (batchId == null) {
      return;
    }

    final _BatchInfo? batch = _activeBatches[batchId];
    if (batch == null) {
      // Clean up orphaned ID
      _downloadIdToBatchId.remove(progress.id);
      return;
    }

    // Update item progress and check if notification is needed
    final bool didChange = batch.updateItemProgress(progress);

    if (didChange) {
      // Update notification
      _updateNotification(batch.id);
    }

    // Check if batch is complete
    if (batch.isFinished && batch.isFullyCompleted) {
      Future.delayed(const Duration(seconds: 5), () {
        if (_isDisposed) return;
        _activeBatches.remove(batch.id);
        for (final id in batch.itemIds) {
          _downloadIdToBatchId.remove(id);
        }
        _persistBatches();
        _checkCleanup();
      });
    }

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

  Future<void> dispose() async {
    _isDisposed = true;
    _progressSubscription?.cancel();
    _progressSubscription = null;
    _activeBatches.clear();
  }
}

class _BatchInfo {
  _BatchInfo({
    required this.id,
    required this.title,
    required this.itemIds,
    required this.totalItems,
    this.reciterName,
  });

  final String id;
  final String title;
  final Set<String> itemIds;
  final int totalItems;
  final String? reciterName;

  // Progress tracking
  int completedCount = 0;
  int failedCount = 0;
  int cancelledCount = 0;
  final Map<String, int> _itemProgress = {};

  bool updateItemProgress(DownloadProgress progress) {
    // track status
    if (progress.status == DownloadStatus.completed) {
      if (!_itemProgress.containsKey(progress.id) ||
          _itemProgress[progress.id] != 100) {
        _itemProgress[progress.id] = 100;
        completedCount++;
        return true;
      }
    } else if (progress.status == DownloadStatus.failed) {
      // If it failed, we count it as processed
      if (!_itemProgress.containsKey(progress.id) ||
          _itemProgress[progress.id] != -1) {
        _itemProgress[progress.id] = -1; // mark as failed
        failedCount++;
        return true;
      }
    } else if (progress.status == DownloadStatus.cancelled) {
      if (!_itemProgress.containsKey(progress.id) ||
          _itemProgress[progress.id] != -2) {
        _itemProgress[progress.id] = -2; // mark as cancelled
        cancelledCount++;
        return true;
      }
    } else {
      // Running
      final int newProgress = (progress.progress * 100).toInt();
      if (!_itemProgress.containsKey(progress.id) ||
          _itemProgress[progress.id] != newProgress) {
        _itemProgress[progress.id] = newProgress;
        return true;
      }
    }
    return false;
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

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'item_ids': itemIds.toList(),
    'reciter_name': reciterName,
    'total_items': totalItems,
  };

  factory _BatchInfo.fromJson(Map<String, dynamic> json) {
    return _BatchInfo(
      id: json['id'] as String,
      title: json['title'] as String,
      itemIds: Set.from(json['item_ids'] as List),
      totalItems: json['total_items'] as int,
      reciterName: json['reciter_name'] as String?,
    );
  }
}
