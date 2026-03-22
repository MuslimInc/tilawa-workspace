import 'dart:async';

import '../entities/download_item.dart';
import '../entities/download_progress.dart';

/// Abstract interface for download service.
abstract class DownloadServiceInterface {
  /// Stream for monitoring all download progress updates globally.
  Stream<DownloadProgress> get globalProgressStream;

  /// Get a filtered stream for a specific download by URL.
  Stream<DownloadProgress> getProgressStream(String id);

  /// Get all currently active download URLs.
  Future<List<String>> getActiveDownloadIds();

  /// Check if a download is currently active (running or enqueued).
  Future<bool> isStatusDownloadActive(String id);

  /// Get the current status of a download.
  Future<DownloadStatus?> getStatus(String id);

  /// Get the full progress details of a download (status, progress, size).
  Future<DownloadProgress?> getDownloadProgress(String id);

  /// Start a new download.
  Future<void> download({
    required String id,
    required String url,
    required String filePath,
    required String title,
    required String reciterName,
    int? reciterId,
    bool showNotification = true,
  });

  /// Cancel a download by its ID.
  Future<void> cancel(String id);

  /// Pause a download by its ID.
  Future<void> pause(String id);

  /// Resume a download by its ID.
  Future<void> resume(String id);

  /// Cancel all active downloads.
  Future<void> cancelAll();

  /// Dispose and cleanup the download service.
  Future<void> disposeService();

  /// Initialize the download service and set up update listeners.
  Future<void> initialize();
}
