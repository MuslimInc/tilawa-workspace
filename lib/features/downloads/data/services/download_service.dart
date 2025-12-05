import 'dart:async';
import 'dart:io';

import 'package:background_downloader/background_downloader.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as path;

import '../../../../main.dart';
import '../../domain/entities/download_item.dart';

class DownloadService {
  static final StreamController<DownloadProgress> _globalProgressController =
      StreamController<DownloadProgress>.broadcast();
  static StreamSubscription<TaskUpdate>? _updatesSubscription;
  static bool _initialized = false;
  // Track task statuses from updates
  static final Map<String, TaskStatus> _taskStatuses = {};
  // Track when tasks were enqueued to detect stuck tasks
  static final Map<String, DateTime> _taskEnqueuedAt = {};
  // Lock to prevent concurrent initialization
  static Completer<void>? _initializationCompleter;
  // Reuse a single FileDownloader instance to avoid stream issues
  static FileDownloader? _fileDownloaderInstance;

  static FileDownloader? _fileDownloaderOverride;

  // Queue Management
  static const int _maxConcurrentDownloads = 3;
  static final List<DownloadTask> _pendingTasks = [];
  static final Set<String> _activeTaskIds = {};

  @visibleForTesting
  static FileDownloader? get fileDownloaderOverride => _fileDownloaderOverride;

  @visibleForTesting
  static set fileDownloaderOverride(FileDownloader? value) {
    _fileDownloaderOverride = value;
    // Reset instance when override changes
    _fileDownloaderInstance = null;
  }

  static FileDownloader _getFileDownloader() {
    if (_fileDownloaderOverride != null) {
      return _fileDownloaderOverride!;
    }
    // Reuse the same instance to avoid stream subscription issues
    _fileDownloaderInstance ??= FileDownloader();
    return _fileDownloaderInstance!;
  }

  /// Initialize the download service and set up update listeners
  static Future<void> _initialize() async {
    // If initialization is already in progress, wait for it to complete
    if (_initializationCompleter != null) {
      return _initializationCompleter!.future;
    }

    // If already initialized, return immediately
    if (_initialized) {
      return;
    }

    // Create a completer to track this initialization
    _initializationCompleter = Completer<void>();

    try {
      // Cancel existing subscription if any (important for tests where mocks are replaced)
      // This ensures the stream subscription uses the current fileDownloader instance
      if (_updatesSubscription != null) {
        await _updatesSubscription?.cancel();
        _updatesSubscription = null;
      }
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
          running: const TaskNotification('Downloading', 'file: {filename}'),
          complete: const TaskNotification(
            'Download Complete',
            'file: {filename}',
          ),
          error: const TaskNotification('Download Failed', 'file: {filename}'),
          paused: const TaskNotification('Download Paused', 'file: {filename}'),
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

      // Check for and handle stuck tasks on initialization
      // Skip in test environments to avoid delays and platform channel issues
      try {
        await _checkAndHandleStuckTasks(fileDownloader);
      } on MissingPluginException {
        // In test environment, skip stuck task check
        logger.d(
          '[DownloadService] Skipping stuck task check - platform channels not available (test environment)',
        );
      } catch (e) {
        // Log but don't fail initialization if stuck task check fails
        logger.w('[DownloadService] Error checking stuck tasks: $e');
      }

      _initialized = true;
      logger.d(
        '[DownloadService] Initialized with background_downloader and notifications',
      );
      _initializationCompleter?.complete();
    } on MissingPluginException catch (e) {
      // In test environment, platform channels are not available
      // Don't mark as initialized, and re-throw so callers can handle it
      _initialized = false;
      logger.d(
        '[DownloadService] Initialization skipped - platform channels not available (test environment): $e',
      );
      _initializationCompleter?.completeError(e);
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
        final exception = MissingPluginException(
          'Platform channels not available (test environment)',
        );
        _initializationCompleter?.completeError(exception);
        throw exception;
      }
      _initializationCompleter?.completeError(e);
      rethrow;
    } finally {
      // Clear the completer after initialization completes (success or failure)
      _initializationCompleter = null;
    }
  }

  /// Check for and handle stuck tasks (enqueued for too long)
  static Future<void> _checkAndHandleStuckTasks(
    FileDownloader fileDownloader,
  ) async {
    try {
      // First check if we can access allTasks - if not, we're in test environment
      final List<Task> allTasks;
      try {
        allTasks = await fileDownloader.allTasks();
      } on MissingPluginException {
        // In test environment, skip stuck task check
        logger.d(
          '[DownloadService] Skipping stuck task check - platform channels not available (test environment)',
        );
        return;
      } catch (e) {
        // Any other error - log and skip
        logger.w('[DownloadService] Error getting all tasks: $e');
        return;
      }

      // If no tasks, skip the check (likely test environment or no downloads)
      if (allTasks.isEmpty) {
        return;
      }

      // Sync _activeTaskIds with actual running tasks
      _activeTaskIds.clear();
      for (final task in allTasks) {
        // We assume tasks found here are active/running/enqueued
        // You might want to check status more carefully if possible,
        // but allTasks usually returns active tasks.
        _activeTaskIds.add(task.taskId);
      }

      // Wait a bit for the updates stream to populate task statuses
      // Only do this if we successfully got tasks (not in test environment)
      await Future.delayed(const Duration(milliseconds: 500));

      final now = DateTime.now();

      for (final task in allTasks) {
        // Get status from cache (populated by updates stream)
        final TaskStatus? status = _taskStatuses[task.taskId];

        // If task is enqueued, check if it's stuck
        if (status == TaskStatus.enqueued) {
          final DateTime? enqueuedAt = _taskEnqueuedAt[task.taskId];

          // If we don't have a timestamp, assume it might be stuck (app restarted)
          // Set timestamp to make it appear stuck so it gets canceled
          if (enqueuedAt == null) {
            _taskEnqueuedAt[task.taskId] = now.subtract(
              const Duration(seconds: 35),
            );
            logger.w(
              '[DownloadService] Found enqueued task without timestamp (likely from app restart): id=${task.taskId} - marking as potentially stuck',
            );
          }

          final Duration timeEnqueued = now.difference(
            _taskEnqueuedAt[task.taskId]!,
          );
          if (timeEnqueued.inSeconds > 30) {
            // Task is stuck - cancel it
            logger.w(
              '[DownloadService] Found stuck task (enqueued for ${timeEnqueued.inSeconds}s): id=${task.taskId} - canceling',
            );
            try {
              await fileDownloader.cancelTaskWithId(task.taskId);
              _taskStatuses.remove(task.taskId);
              _taskEnqueuedAt.remove(task.taskId);
              _activeTaskIds.remove(task.taskId);
            } catch (e) {
              logger.w(
                '[DownloadService] Error canceling stuck task ${task.taskId}: $e',
              );
            }
          }
        }
      }
      // After cleaning up stuck tasks, process queue to fill any slots
      await _processQueue();
    } on MissingPluginException {
      // In test environment, skip stuck task check
      logger.d(
        '[DownloadService] Skipping stuck task check - platform channels not available (test environment)',
      );
    } catch (e) {
      logger.w('[DownloadService] Error checking stuck tasks: $e');
    }
  }

  /// Handle task updates from background_downloader
  static void _handleTaskUpdate(TaskUpdate update) {
    final String taskId = update.task.taskId;
    DownloadProgress? progress;

    if (update is TaskStatusUpdate) {
      // Track status
      final TaskStatus previousStatus =
          _taskStatuses[taskId] ?? TaskStatus.notFound;
      _taskStatuses[taskId] = update.status;

      // Track when task transitions to enqueued
      if (update.status == TaskStatus.enqueued &&
          previousStatus != TaskStatus.enqueued) {
        _taskEnqueuedAt[taskId] = DateTime.now();
        logger.d('[DownloadService] Task enqueued: id=$taskId');
      }

      // Clear enqueued timestamp when task starts running or completes
      if (update.status == TaskStatus.running ||
          update.status == TaskStatus.complete ||
          update.status == TaskStatus.failed ||
          update.status == TaskStatus.canceled) {
        _taskEnqueuedAt.remove(taskId);
      }

      // Update active tasks tracking
      if (update.status == TaskStatus.running ||
          update.status == TaskStatus.enqueued) {
        _activeTaskIds.add(taskId);
      } else if (update.status == TaskStatus.complete ||
          update.status == TaskStatus.failed ||
          update.status == TaskStatus.canceled ||
          update.status == TaskStatus.notFound) {
        _activeTaskIds.remove(taskId);
        // Task finished, try to start next one
        _processQueue();
      }

      progress = DownloadProgress(
        id: taskId,
        status: _mapTaskStatusToDownloadStatus(update.status),
        progress: 0.0,
        downloadedSize: 0,
        fileSize: 0,
      );
    } else if (update is TaskProgressUpdate) {
      final double taskProgress = update.progress;
      final int expectedFileSize = update.expectedFileSize;
      final int receivedBytes = (taskProgress * expectedFileSize).round();

      // Clear enqueued timestamp when progress starts
      _taskEnqueuedAt.remove(taskId);

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

  /// Process the download queue to start pending tasks if slots are available
  static Future<void> _processQueue() async {
    if (_pendingTasks.isEmpty) {
      return;
    }

    // Check how many are currently active
    // We double check with _activeTaskIds which is maintained by status updates
    // and potentially by allTasks() check.
    if (_activeTaskIds.length >= _maxConcurrentDownloads) {
      logger.d(
        '[DownloadService] Queue full (${_activeTaskIds.length}/$_maxConcurrentDownloads active), ${_pendingTasks.length} pending',
      );
      return;
    }

    // Start tasks until we reach max concurrent or run out of pending tasks
    while (_pendingTasks.isNotEmpty &&
        _activeTaskIds.length < _maxConcurrentDownloads) {
      final DownloadTask task = _pendingTasks.removeAt(0);
      logger.d(
        '[DownloadService] Dequeuing task: id=${task.taskId}, starting download',
      );

      try {
        final FileDownloader fileDownloader = _getFileDownloader();
        await fileDownloader.enqueue(task);
        _activeTaskIds.add(task.taskId);
        _taskEnqueuedAt[task.taskId] = DateTime.now();
        // Also update status to pending/enqueued immediately so UI reflects it
        _taskStatuses[task.taskId] = TaskStatus.enqueued;
        _globalProgressController.add(
          DownloadProgress(
            id: task.taskId,
            status: DownloadStatus.pending,
            progress: 0.0,
            downloadedSize: 0,
            fileSize: 0,
          ),
        );
      } catch (e) {
        logger.w(
          '[DownloadService] Error starting queued task ${task.taskId}: $e',
        );
        // If start failed, we should probably not count it as active
        _activeTaskIds.remove(task.taskId);
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
    final Task? existingTask = await fileDownloader.taskForId(id);
    if (existingTask != null) {
      // Check if task is running
      final TaskStatus? status = _taskStatuses[id];
      if (status == TaskStatus.running) {
        logger.d(
          '[DownloadService] startDownload skipped: id=$id already running',
        );
        return;
      }

      // Check if task is stuck in enqueued state (more than 30 seconds)
      if (status == TaskStatus.enqueued) {
        final DateTime? enqueuedAt = _taskEnqueuedAt[id];
        if (enqueuedAt != null) {
          final Duration timeEnqueued = DateTime.now().difference(enqueuedAt);
          if (timeEnqueued.inSeconds > 30) {
            // Task is stuck in enqueued state - cancel and retry
            logger.w(
              '[DownloadService] Task stuck in enqueued state for ${timeEnqueued.inSeconds}s: id=$id - canceling and retrying',
            );
            try {
              await fileDownloader.cancelTaskWithId(id);
              // Wait a bit before retrying
              await Future.delayed(const Duration(milliseconds: 500));
              // Clear the status so we can retry
              _taskStatuses.remove(id);
              _taskEnqueuedAt.remove(id);
              _activeTaskIds.remove(id);
            } catch (e) {
              logger.w('[DownloadService] Error canceling stuck task: $e');
              // Continue to retry anyway
              _taskStatuses.remove(id);
              _taskEnqueuedAt.remove(id);
              _activeTaskIds.remove(id);
            }
          } else {
            // Task is enqueued but not stuck yet
            logger.d(
              '[DownloadService] startDownload skipped: id=$id already enqueued (${timeEnqueued.inSeconds}s ago)',
            );
            return;
          }
        } else {
          // Task is enqueued but we don't have timestamp - assume it's stuck
          logger.w(
            '[DownloadService] Task enqueued without timestamp: id=$id - canceling and retrying',
          );
          try {
            await fileDownloader.cancelTaskWithId(id);
            await Future.delayed(const Duration(milliseconds: 500));
            _taskStatuses.remove(id);
            _taskEnqueuedAt.remove(id);
            _activeTaskIds.remove(id);
          } catch (e) {
            logger.w('[DownloadService] Error canceling task: $e');
            _taskStatuses.remove(id);
            _taskEnqueuedAt.remove(id);
            _activeTaskIds.remove(id);
          }
        }
      }
    }

    // Check if already in pending queue
    if (_pendingTasks.any((t) => t.taskId == id)) {
      logger.d(
        '[DownloadService] startDownload skipped: id=$id already in pending queue',
      );
      return;
    }

    // Check if a partial file exists (for resume capability)
    final file = File(filePath);
    final partialFile = File('$filePath.partial');
    final bool hasPartialFile = partialFile.existsSync();
    final bool hasCompleteFile = file.existsSync();

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

    if (!Uri.parse(url).isAbsolute) {
      throw ArgumentError('Invalid URL');
    }

    // Extract directory and filename from filePath
    // background_downloader needs relative path from baseDirectory
    final String filename = path.basename(filePath);

    // Get the relative directory path from applicationDocuments
    // filePath is typically: /path/to/app/documents/downloads/filename.mp3
    // We need: downloads (relative to applicationDocuments)
    var relativeDirectory = 'downloads';
    final String dirname = path.dirname(filePath);
    if (dirname.contains('downloads')) {
      // Extract 'downloads' or the subdirectory after 'downloads'
      final List<String> parts = dirname.split(path.separator);
      final int downloadsIndex = parts.indexWhere((p) => p == 'downloads');
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
      updates: Updates.statusAndProgress,
      retries: 3,
      allowPause: true,
      taskId: id,
      // Add metadata for notification (as JSON string)
      metaData: '{"title":"$title","reciterName":"$reciterName"}',
      // Enable resume capability - background_downloader will automatically
      // resume from the last downloaded position if a partial file exists
      // and the server supports HTTP Range requests
    );

    // Add to pending queue instead of enqueueing immediately
    _pendingTasks.add(task);
    logger.d('[DownloadService] Task added to pending queue: id=$id');

    // Trigger queue processing
    await _processQueue();
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
    final List<Task> allTasks = await _getFileDownloader().allTasks();
    final activeIds = <String>[];

    for (final task in allTasks) {
      final TaskStatus? status = _taskStatuses[task.taskId];
      if (status == TaskStatus.running ||
          status == TaskStatus.enqueued ||
          status == TaskStatus.waitingToRetry) {
        activeIds.add(task.taskId);
      }
    }
    // Also include pending tasks in "active" list from UI perspective
    // so they show as "waiting" or similar
    for (final DownloadTask task in _pendingTasks) {
      if (!activeIds.contains(task.taskId)) {
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

    // Check pending queue first
    if (_pendingTasks.any((t) => t.taskId == id)) {
      return true;
    }

    final TaskStatus? status = _taskStatuses[id];
    if (status == null) {
      // If not tracked, check if task exists
      try {
        final Task? task = await _getFileDownloader().taskForId(id);
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
    _updatesSubscription = null;
    await _globalProgressController.close();
    _initialized = false;
    _fileDownloaderInstance = null;
    _initializationCompleter = null;
    _pendingTasks.clear();
    _activeTaskIds.clear();
    logger.d('[DownloadService] dispose: done');
  }

  /// Reset static state for testing
  /// This clears all static variables but keeps the global controller open
  /// so tests can reuse the service
  @visibleForTesting
  static Future<void> reset() async {
    await _updatesSubscription?.cancel();
    _updatesSubscription = null;
    _initialized = false;
    _fileDownloaderInstance = null;
    _initializationCompleter = null;
    _taskStatuses.clear();
    _taskEnqueuedAt.clear();
    _pendingTasks.clear();
    _activeTaskIds.clear();
  }

  /// Cancel a download
  static Future<void> cancelDownload(String id) async {
    await _initialize();
    logger.d('[DownloadService] cancelDownload: id=$id');

    // Check if it's in pending queue
    final int pendingIndex = _pendingTasks.indexWhere((t) => t.taskId == id);
    if (pendingIndex != -1) {
      _pendingTasks.removeAt(pendingIndex);
      logger.d('[DownloadService] Removed task from pending queue: id=$id');
      // No need to call fileDownloader.cancelTaskWithId because it wasn't enqueued yet
      // But we should notify listeners that it's cancelled
      _globalProgressController.add(
        DownloadProgress(
          id: id,
          status: DownloadStatus.cancelled,
          progress: 0.0,
          downloadedSize: 0,
          fileSize: 0,
        ),
      );
      return;
    }

    await _getFileDownloader().cancelTaskWithId(id);
    // Clear tracking data
    _taskStatuses.remove(id);
    _taskEnqueuedAt.remove(id);
    _activeTaskIds.remove(id);

    // Since a slot might have opened up, process queue
    await _processQueue();
  }

  /// Pause a download
  static Future<void> pauseDownload(String id) async {
    await _initialize();
    logger.d('[DownloadService] pauseDownload: id=$id');
    final Task? task = await _getFileDownloader().taskForId(id);
    if (task != null && task is DownloadTask) {
      await _getFileDownloader().pause(task);
    }
  }

  /// Resume a paused download
  static Future<void> resumeDownload(String id) async {
    await _initialize();
    logger.d('[DownloadService] resumeDownload: id=$id');
    final Task? task = await _getFileDownloader().taskForId(id);
    if (task != null && task is DownloadTask) {
      await _getFileDownloader().resume(task);
    }
  }

  /// Get download status for a specific ID
  static Future<DownloadStatus?> getDownloadStatus(String id) async {
    await _initialize();

    // Check pending queue
    if (_pendingTasks.any((t) => t.taskId == id)) {
      return DownloadStatus.pending;
    }

    final TaskStatus? status = _taskStatuses[id];
    if (status == null) {
      // If not tracked, check if task exists
      final Task? task = await _getFileDownloader().taskForId(id);
      if (task == null) {
        return null;
      }
      // Default to pending if we don't have status yet
      return DownloadStatus.pending;
    }
    return _mapTaskStatusToDownloadStatus(status);
  }

  /// Get download progress for a specific ID
  static Future<DownloadProgress?> getDownloadProgress(String id) async {
    await _initialize();

    // Check pending queue
    if (_pendingTasks.any((t) => t.taskId == id)) {
      return DownloadProgress(
        id: id,
        status: DownloadStatus.pending,
        progress: 0.0,
        downloadedSize: 0,
        fileSize: 0,
      );
    }

    final Task? task = await _getFileDownloader().taskForId(id);
    if (task == null) {
      return null;
    }

    final TaskStatus status = _taskStatuses[id] ?? TaskStatus.notFound;

    // Get progress from task updates if available
    // Note: Real progress comes from TaskProgressUpdate events in the stream
    const progress = 0.0;
    const fileSize = 0;
    const downloadedSize = 0;

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
    final Duration timeSinceLastUpdate = _lastProgressUpdateTime != null
        ? now.difference(_lastProgressUpdateTime!)
        : const Duration(seconds: 1);
    final int bytesSinceLastUpdate = received - _lastSentBytes;
    final double progressSinceLastUpdate = total > 0
        ? bytesSinceLastUpdate / total
        : 0.0;

    final bool shouldSend =
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
    final Duration timeSinceLastUpdate = _lastProgressUpdateTime != null
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
  const DownloadProgress({
    required this.id,
    required this.status,
    required this.progress,
    required this.downloadedSize,
    required this.fileSize,
  });
  final String id;
  final DownloadStatus status;
  final double progress;
  final int downloadedSize;
  final int fileSize;

  @override
  List<Object?> get props => [id, status, progress, downloadedSize, fileSize];
}
