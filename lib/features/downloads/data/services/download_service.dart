import 'dart:async';
import 'dart:io';

import 'package:background_downloader/background_downloader.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:muzakri/features/downloads/domain/entities/download_item.dart';
import 'package:muzakri/main.dart';
import 'package:path/path.dart' as path;

class DownloadService {
  static final StreamController<DownloadProgress> _globalProgressController =
      StreamController<DownloadProgress>.broadcast();
  static StreamSubscription<TaskUpdate>? _updatesSubscription;
  static bool _initialized = false;
  // Track task statuses from updates
  static final Map<String, TaskStatus> _taskStatuses = {};

  static FileDownloader? _fileDownloaderOverride;

  @visibleForTesting
  static set fileDownloaderOverride(FileDownloader? value) {
    _fileDownloaderOverride = value;
  }

  static FileDownloader _getFileDownloader() {
    return _fileDownloaderOverride ?? FileDownloader();
  }

  /// Initialize the download service and set up update listeners
  static Future<void> _initialize() async {
    // Cancel existing subscription if any (important for tests where mocks are replaced)
    // This ensures the stream subscription uses the current fileDownloader instance
    if (_initialized && _updatesSubscription != null) {
      await _updatesSubscription?.cancel();
      _updatesSubscription = null;
      _initialized = false;
    }

    if (_initialized) {
      // Already initialized and subscription is still active
      return;
    }

    try {
      // Configure notifications for download progress
      // This shows a notification with progress bar when app is closed
      // Note: FileDownloader() may throw MissingPluginException in test environments
      // The exception can be thrown synchronously during construction or
      // asynchronously during initialization
      FileDownloader fileDownloader;
      try {
        fileDownloader = _getFileDownloader();
        // Wait a bit to catch any async exceptions from initialization
        // await Future.delayed(Duration.zero);
      } on MissingPluginException {
        // Exception thrown during FileDownloader() construction
        logger.d(
          '[DownloadService] FileDownloader construction failed - platform channels not available (test environment)',
        );
        rethrow;
      }

      // Configure notifications - this may also throw if initialization happens here
      try {
        fileDownloader.configureNotification(
          running: TaskNotification('Downloading', 'file: {filename}'),
          complete: TaskNotification('Download Complete', 'file: {filename}'),
          error: TaskNotification('Download Failed', 'file: {filename}'),
          paused: TaskNotification('Download Paused', 'file: {filename}'),
          progressBar: true, // Enable progress bar in notification
        );
      } on MissingPluginException {
        logger.d(
          '[DownloadService] configureNotification failed - platform channels not available (test environment)',
        );
        rethrow;
      }

      // Listen to all download updates
      // Cancel existing subscription if any (for test scenarios)
      await _updatesSubscription?.cancel();
      try {
        _updatesSubscription = fileDownloader.updates.listen((update) {
          _handleTaskUpdate(update);
        });
      } on MissingPluginException {
        logger.d(
          '[DownloadService] updates.listen failed - platform channels not available (test environment)',
        );
        rethrow;
      }

      _initialized = true;
      logger.d(
        '[DownloadService] Initialized with background_downloader and notifications',
      );
    } on MissingPluginException catch (e) {
      // In test environment, platform channels are not available
      // Don't mark as initialized, and re-throw so callers can handle it
      _initialized = false;
      logger.d(
        '[DownloadService] Initialization skipped - platform channels not available (test environment): $e',
      );
      rethrow;
    } catch (e) {
      // Catch any other exceptions during initialization
      _initialized = false;
      logger.w('[DownloadService] Error during initialization: $e');
      // Check if it's a MissingPluginException wrapped in another exception
      if (e.toString().contains('MissingPluginException') ||
          e.toString().contains('getApplicationSupportDirectory')) {
        logger.d(
          '[DownloadService] Initialization failed due to platform channels not available (test environment)',
        );
        throw MissingPluginException(
          'Platform channels not available (test environment)',
        );
      }
      rethrow;
    }
  }

  /// Handle task updates from background_downloader
  static void _handleTaskUpdate(TaskUpdate update) {
    final taskId = update.task.taskId;
    DownloadProgress? progress;

    if (update is TaskStatusUpdate) {
      // Track status
      _taskStatuses[taskId] = update.status;
      progress = DownloadProgress(
        id: taskId,
        status: _mapTaskStatusToDownloadStatus(update.status),
        progress: 0.0,
        downloadedSize: 0,
        fileSize: 0,
      );
    } else if (update is TaskProgressUpdate) {
      final taskProgress = update.progress;
      final expectedFileSize = update.expectedFileSize;
      final receivedBytes = (taskProgress * expectedFileSize).round();

      progress = DownloadProgress(
        id: taskId,
        status: DownloadStatus.downloading,
        progress: taskProgress,
        downloadedSize: receivedBytes,
        fileSize: expectedFileSize,
      );
    }

    if (progress != null) {
      _globalProgressController.add(progress);
      if (progress.progress == 0.0 || progress.progress == 1.0) {
        logger.d(
          '[DownloadService] progress: id=${progress.id} status=${progress.status} progress=${progress.progress}',
        );
      }
    }
  }

  /// Map background_downloader TaskStatus to DownloadStatus
  static DownloadStatus _mapTaskStatusToDownloadStatus(TaskStatus status) {
    return switch (status) {
      TaskStatus.enqueued => DownloadStatus.pending,
      TaskStatus.running => DownloadStatus.downloading,
      TaskStatus.complete => DownloadStatus.completed,
      TaskStatus.failed => DownloadStatus.failed,
      TaskStatus.canceled => DownloadStatus.cancelled,
      TaskStatus.paused => DownloadStatus.paused,
      TaskStatus.notFound => DownloadStatus.failed,
      TaskStatus.waitingToRetry => DownloadStatus.pending,
    };
  }

  /// Start downloading a file in background
  /// Downloads will continue even when app is closed or terminated
  /// Downloads will automatically resume from the last downloaded position
  /// if the download was interrupted (network issue, app closed, etc.)
  static Future<void> startDownload({
    required String id,
    required String url,
    required String filePath,
    required String title,
    required String reciterName,
  }) async {
    try {
      await _initialize();
    } on MissingPluginException {
      // In test environment, platform channels are not available
      // Re-throw so callers can handle it
      rethrow;
    }

    // Check if download is already active
    // Note: FileDownloader() may throw MissingPluginException in test environments
    FileDownloader? fileDownloader;
    try {
      fileDownloader = _getFileDownloader();
    } on MissingPluginException {
      // In test environment, re-throw so callers can handle it
      rethrow;
    }
    final existingTask = await fileDownloader.taskForId(id);
    if (existingTask != null) {
      // Check if task is running or enqueued
      final status = _taskStatuses[id];
      if (status == TaskStatus.running || status == TaskStatus.enqueued) {
        logger.d(
          '[DownloadService] startDownload skipped: id=$id already active',
        );
        return;
      }
    }

    // Check if a partial file exists (for resume capability)
    final file = File(filePath);
    final partialFile = File('$filePath.partial');
    final hasPartialFile = await partialFile.exists();
    final hasCompleteFile = await file.exists();

    if (hasCompleteFile) {
      logger.d('[DownloadService] File already exists: id=$id path=$filePath');
      return;
    }

    if (hasPartialFile) {
      logger.d(
        '[DownloadService] Partial file found, will resume download: id=$id path=$filePath',
      );
    }

    logger.d(
      '[DownloadService] startDownload: id=$id title="$title" reciter="$reciterName" url=$url path=$filePath',
    );

    // Extract directory and filename from filePath
    // background_downloader needs relative path from baseDirectory
    final filename = path.basename(filePath);

    // Get the relative directory path from applicationDocuments
    // filePath is typically: /path/to/app/documents/downloads/filename.mp3
    // We need: downloads (relative to applicationDocuments)
    String relativeDirectory = 'downloads';
    final dirname = path.dirname(filePath);
    if (dirname.contains('downloads')) {
      // Extract 'downloads' or the subdirectory after 'downloads'
      final parts = dirname.split(path.separator);
      final downloadsIndex = parts.indexWhere((p) => p == 'downloads');
      if (downloadsIndex != -1 && downloadsIndex < parts.length - 1) {
        relativeDirectory = parts.sublist(downloadsIndex).join(path.separator);
      } else if (downloadsIndex != -1) {
        relativeDirectory = 'downloads';
      }
    }

    // Create download task with resume support
    // background_downloader automatically resumes from partial files
    // if a partial file exists and the server supports HTTP Range requests
    final task = DownloadTask(
      url: url,
      filename: filename,
      directory: relativeDirectory,
      baseDirectory: BaseDirectory.applicationDocuments,
      updates: Updates.statusAndProgress,
      retries: 3,
      requiresWiFi: false,
      allowPause: true,
      taskId: id,
      // Add metadata for notification (as JSON string)
      metaData: '{"title":"$title","reciterName":"$reciterName"}',
      // Enable resume capability - background_downloader will automatically
      // resume from the last downloaded position if a partial file exists
      // and the server supports HTTP Range requests
    );

    // Enqueue the download task
    // This starts the download immediately as a foreground service
    // If a partial file exists, it will automatically resume from where it left off
    // The notification is shown right away, which helps prevent Android
    // from killing the process when the app is terminated
    // Note: There may be a brief delay (5-10 seconds) when app is force-stopped
    // as Android needs to restart the background service
    try {
      await fileDownloader.enqueue(task);
    } on MissingPluginException {
      // In test environment, re-throw so callers can handle it
      rethrow;
    }

    logger.d(
      '[DownloadService] task enqueued: id=$id (will resume if partial file exists)',
    );
  }

  /// Listen to download progress of a specific download ID
  static Stream<DownloadProgress> progressStream(String id) {
    return _globalProgressController.stream.where(
      (progress) => progress.id == id,
    );
  }

  /// Listen to all download progress updates
  static Stream<DownloadProgress> get globalProgressStream =>
      _globalProgressController.stream;

  /// Get all active download task IDs
  static Future<List<String>> get activeDownloadIds async {
    await _initialize();
    final allTasks = await _getFileDownloader().allTasks();
    final activeIds = <String>[];

    for (final task in allTasks) {
      final status = _taskStatuses[task.taskId];
      if (status == TaskStatus.running ||
          status == TaskStatus.enqueued ||
          status == TaskStatus.waitingToRetry) {
        activeIds.add(task.taskId);
      }
    }

    return activeIds;
  }

  /// Check if a download is active
  static Future<bool> isDownloadActive(String id) async {
    try {
      await _initialize();
    } on MissingPluginException {
      // In test environment, platform channels are not available
      // Return false (download not active) so downloads can proceed
      logger.d(
        '[DownloadService] isDownloadActive skipped - platform channels not available (test environment)',
      );
      return false;
    } catch (e) {
      // Any other error - log and return false
      logger.w('[DownloadService] Error initializing for isDownloadActive: $e');
      return false;
    }

    final status = _taskStatuses[id];
    if (status == null) {
      // If not tracked, check if task exists
      try {
        final task = await _getFileDownloader().taskForId(id);
        return task != null;
      } on MissingPluginException {
        // In test environment, return false
        logger.d(
          '[DownloadService] taskForId skipped - platform channels not available (test environment)',
        );
        return false;
      } catch (e) {
        logger.w('[DownloadService] Error checking task: $e');
        return false;
      }
    }
    return status == TaskStatus.running ||
        status == TaskStatus.enqueued ||
        status == TaskStatus.waitingToRetry;
  }

  /// Dispose all downloads and cleanup
  static Future<void> dispose() async {
    logger.d('[DownloadService] dispose: cleaning up');
    await _updatesSubscription?.cancel();
    await _globalProgressController.close();
    _initialized = false;
    logger.d('[DownloadService] dispose: done');
  }

  /// Cancel a download
  static Future<void> cancelDownload(String id) async {
    await _initialize();
    logger.d('[DownloadService] cancelDownload: id=$id');
    await _getFileDownloader().cancelTaskWithId(id);
  }

  /// Pause a download
  static Future<void> pauseDownload(String id) async {
    await _initialize();
    logger.d('[DownloadService] pauseDownload: id=$id');
    final task = await _getFileDownloader().taskForId(id);
    if (task != null && task is DownloadTask) {
      await _getFileDownloader().pause(task);
    }
  }

  /// Resume a paused download
  static Future<void> resumeDownload(String id) async {
    await _initialize();
    logger.d('[DownloadService] resumeDownload: id=$id');
    final task = await _getFileDownloader().taskForId(id);
    if (task != null && task is DownloadTask) {
      await _getFileDownloader().resume(task);
    }
  }

  /// Get download status for a specific ID
  static Future<DownloadStatus?> getDownloadStatus(String id) async {
    await _initialize();
    final status = _taskStatuses[id];
    if (status == null) {
      // If not tracked, check if task exists
      final task = await _getFileDownloader().taskForId(id);
      if (task == null) return null;
      // Default to pending if we don't have status yet
      return DownloadStatus.pending;
    }
    return _mapTaskStatusToDownloadStatus(status);
  }

  /// Get download progress for a specific ID
  static Future<DownloadProgress?> getDownloadProgress(String id) async {
    await _initialize();
    final task = await _getFileDownloader().taskForId(id);
    if (task == null) return null;

    final status = _taskStatuses[id] ?? TaskStatus.notFound;

    // Get progress from task updates if available
    // Note: Real progress comes from TaskProgressUpdate events in the stream
    double progress = 0.0;
    int fileSize = 0;
    int downloadedSize = 0;

    return DownloadProgress(
      id: id,
      status: _mapTaskStatusToDownloadStatus(status),
      progress: progress,
      downloadedSize: downloadedSize,
      fileSize: fileSize,
    );
  }
}

/// Helper class to throttle progress updates
/// This class is testable and encapsulates the throttling logic
/// Made public for testing purposes
/// Note: With background_downloader, throttling is handled by the package itself,
/// but this class is kept for testing and potential future use
class ProgressThrottler {
  int _lastSentBytes = 0;
  DateTime? _lastProgressUpdateTime;

  /// Determines if a progress update should be sent based on throttling rules:
  /// - At least 100ms since last update, OR
  /// - Progress changed by at least 1%, OR
  /// - Initial update (received == 0), OR
  /// - Final update (received == total)
  bool shouldSendUpdate({
    required int received,
    required int total,
    required double progress,
  }) {
    final now = DateTime.now();
    final timeSinceLastUpdate = _lastProgressUpdateTime != null
        ? now.difference(_lastProgressUpdateTime!)
        : const Duration(seconds: 1);
    final bytesSinceLastUpdate = received - _lastSentBytes;
    final progressSinceLastUpdate = total > 0
        ? bytesSinceLastUpdate / total
        : 0.0;

    final shouldSend =
        timeSinceLastUpdate.inMilliseconds >= 100 || // At least 100ms
        progressSinceLastUpdate >= 0.01 || // Or 1% change
        received == 0 || // Always send initial
        received == total; // Always send final

    return shouldSend;
  }

  /// Determines if a progress update should be sent when file size is unknown
  /// Updates are throttled to at most every 100ms
  bool shouldSendUpdateUnknownSize({required int received}) {
    final now = DateTime.now();
    final timeSinceLastUpdate = _lastProgressUpdateTime != null
        ? now.difference(_lastProgressUpdateTime!)
        : const Duration(seconds: 1);

    return timeSinceLastUpdate.inMilliseconds >= 100 || received == 0;
  }

  /// Records that an update was sent (updates internal state)
  void recordUpdate({required int received}) {
    _lastSentBytes = received;
    _lastProgressUpdateTime = DateTime.now();
  }

  /// Resets the throttler state (useful for testing)
  void reset() {
    _lastSentBytes = 0;
    _lastProgressUpdateTime = null;
  }
}

@immutable
class DownloadProgress extends Equatable {
  final String id;
  final DownloadStatus status;
  final double progress;
  final int downloadedSize;
  final int fileSize;

  const DownloadProgress({
    required this.id,
    required this.status,
    required this.progress,
    required this.downloadedSize,
    required this.fileSize,
  });

  @override
  List<Object?> get props => [id, status, progress, downloadedSize, fileSize];
}
