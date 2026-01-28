import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:injectable/injectable.dart';

import '../../../../main.dart';
import '../../domain/entities/download_item.dart';
import '../models/download_progress.dart';
import 'download_service_interface.dart';
import 'flutter_downloader_wrapper.dart';
import 'helpers/download_file_helper.dart';
import 'helpers/download_isolate_manager.dart';
import 'helpers/download_status_mapper.dart';

@pragma('vm:entry-point')
@LazySingleton(as: DownloadServiceInterface)
class DownloadServiceImpl implements DownloadServiceInterface {
  DownloadServiceImpl(
    this._flutterDownloader,
    this._fileHelper,
    this._statusMapper,
    this._isolateManager,
  );

  FlutterDownloaderWrapper _flutterDownloader;
  final DownloadFileHelper _fileHelper;
  final DownloadStatusMapper _statusMapper;
  final DownloadIsolateManager _isolateManager;

  final StreamController<DownloadProgress> _globalProgressController =
      StreamController<DownloadProgress>.broadcast();

  @visibleForTesting
  StreamController<DownloadProgress> get globalProgressControllerInternal =>
      _globalProgressController;

  /// Tracks initialization state
  bool _initialized = false;
  Completer<void>? _initializationCompleter;

  @visibleForTesting
  FlutterDownloaderWrapper get flutterDownloaderInternal => _flutterDownloader;

  @visibleForTesting
  set flutterDownloaderInternal(FlutterDownloaderWrapper value) {
    _flutterDownloader = value;
  }

  /// Reset internal state for testing
  @visibleForTesting
  void resetForTesting() {
    _activeDownloadUrls.clear();
    _taskIdToUrlMap.clear();
    _initialized = false;
  }

  /// Map to store taskId -> URL for reverse lookups
  /// Used to map platform callbacks back to external IDs
  final Map<String, String> _taskIdToUrlMap = {};

  /// Cache for active download URLs to avoid expensive IPC calls
  final Set<String> _activeDownloadUrls = {};

  @override
  Stream<DownloadProgress> get globalProgressStream =>
      _globalProgressController.stream;

  // --------------------------------------------------------------------------
  // Instance Methods
  // --------------------------------------------------------------------------

  /// Initialize the download service and set up update listeners.
  ///
  /// Must be called before any download operations. Safe to call multiple times.
  /// Subsequent calls will return the same initialization future.
  @override
  Future<void> initialize() async {
    if (_initializationCompleter != null) {
      return _initializationCompleter!.future;
    }

    if (_initialized) {
      return Future.value();
    }

    final completer = Completer<void>();
    _initializationCompleter = completer;

    try {
      await _performInitialization();
      _initialized = true;
      completer.complete();
    } catch (e) {
      _initialized = false;
      if (!completer.isCompleted) {
        completer.completeError(e);
      }
      return completer.future;
    } finally {
      _initializationCompleter = null;
    }
  }

  /// Performs the actual initialization work.
  /// Sets up FlutterDownloader and registers callbacks.
  Future<void> _performInitialization() async {
    try {
      // Initialize FlutterDownloader
      await _flutterDownloader.initialize();

      // Register port for background IPC communication
      _isolateManager.registerPort();

      // Listen for updates
      _isolateManager.updateStream.listen((data) {
        final (taskId, status, progress) = data;
        _handleTaskUpdate(taskId, status, progress);
      });

      // Register the static callback for platform layer
      // Use step 3 to reduce frequency of updates (every 3%)
      await _flutterDownloader.registerCallback(downloadCallback, step: 3);

      // Populate initial cache
      try {
        final List<DownloadTask>? tasks = await _flutterDownloader.loadTasks();
        if (tasks != null) {
          _activeDownloadUrls.clear();
          for (final DownloadTask task in tasks) {
            // Cache task ID mapping
            _taskIdToUrlMap[task.taskId] = task.url;

            // Cache active status
            if (task.status == DownloadTaskStatus.running ||
                task.status == DownloadTaskStatus.enqueued) {
              _activeDownloadUrls.add(task.url);
            }
          }
        }
      } catch (e) {
        logger.w('[DownloadService] Failed to load initial tasks: $e');
      }

      logger.d('[DownloadService] Initialized successfully');
    } catch (e) {
      logger.w('[DownloadService] Initialization error: $e');
      rethrow;
    }
  }

  /// Handle a task status/progress update from the platform layer.
  /// Maps taskId back to URL and emits progress events.
  Future<void> _handleTaskUpdate(
    String taskId,
    DownloadTaskStatus status,
    int progress,
  ) async {
    // Resolve URL from cached mapping
    String? url = _taskIdToUrlMap[taskId];

    if (url == null) {
      // Try to find in database as fallback
      try {
        final List<DownloadTask>? tasks = await _flutterDownloader.loadTasks();
        if (tasks != null) {
          // Find task with matching ID
          for (final DownloadTask task in tasks) {
            if (task.taskId == taskId) {
              url = task.url;
              _taskIdToUrlMap[taskId] = url;
              break;
            }
          }
        }
      } catch (e) {
        logger.w('[DownloadService] Failed to resolve taskId $taskId: $e');
      }
    }

    if (url != null) {
      // Update active cache
      if (status == DownloadTaskStatus.running ||
          status == DownloadTaskStatus.enqueued) {
        _activeDownloadUrls.add(url);
      } else {
        _activeDownloadUrls.remove(url);
      }

      final DownloadStatus downloadStatus = _statusMapper
          .mapTaskStatusToDownloadStatus(status);
      _globalProgressController.add(
        DownloadProgress(
          id: url,
          status: downloadStatus,
          progress: progress / 100.0,
          downloadedSize: 0,
          fileSize: 0,
        ),
      );
    }
  }

  /// Download a file.
  ///
  /// [id] Unique identifier (typically the URL).
  /// [url] Remote file URL.
  /// [filePath] Local file path to save to.
  /// [title] Human-readable title for notifications.
  /// [reciterName] Reciter metadata.
  ///
  /// If a download for this URL is already active, returns immediately.
  /// If already completed, emits a completed progress event.
  @override
  Future<void> download({
    required String id,
    required String url,
    required String filePath,
    required String title,
    required String reciterName,
    int? reciterId,
    bool showNotification = false,
  }) async {
    await initialize();

    // Check if task already exists for this URL
    // Status codes: 1=enqueued, 2=running, 3=complete, 4=failed, 5=cancelled
    final List<DownloadTask>? existingTasks = await _queryTasksByUrl(url);

    if (existingTasks != null && existingTasks.isNotEmpty) {
      final DownloadTask task = existingTasks.first;

      if (task.status == DownloadTaskStatus.complete) {
        // Verify the file actually exists
        final bool exists = _fileHelper.isFileExists(filePath);
        if (exists) {
          // Already completed and file exists
          _globalProgressController.add(
            DownloadProgress(
              id: id,
              status: DownloadStatus.completed,
              progress: 1.0,
              downloadedSize: 0,
              fileSize: 0,
            ),
          );
          return;
        } else {
          // Stale task - DB says complete but file is missing
          logger.i(
            '[DownloadService] Found stale complete task for $url. File missing at $filePath. Removing stale task and restarting download.',
          );
          await _removeTaskWithRetries(task.taskId);
          // Continue to enqueue new download...
        }
      } else if (task.status == DownloadTaskStatus.running ||
          task.status == DownloadTaskStatus.enqueued) {
        // Already active, map it
        _taskIdToUrlMap[task.taskId] = id;
        _activeDownloadUrls.add(id);
        return;
      }
    }

    // Create directory if needed
    final String savedDir = _fileHelper.getDirectoryName(filePath);
    final String fileName = _fileHelper.getFileName(filePath);

    logger.d(
      '[DownloadService] Enqueuing: url=$url, filePath=$filePath, savedDir=$savedDir, fileName=$fileName',
    );

    // Validate parameters to prevent NPE in background worker
    if (savedDir.isEmpty) {
      logger.e('[DownloadService] Cannot enqueue: savedDir is empty for $url');
      return;
    }
    if (fileName.isEmpty) {
      logger.e('[DownloadService] Cannot enqueue: fileName is empty for $url');
      return;
    }

    if (!_fileHelper.ensureDirectoryExists(savedDir)) {
      return;
    }

    try {
      // Enqueue the download
      final String? taskId = await _flutterDownloader.enqueue(
        url: url,
        savedDir: savedDir,
        fileName: fileName,
        openFileFromNotification: false,
        title: title,
      );

      if (taskId != null) {
        _taskIdToUrlMap[taskId] = id;
        _activeDownloadUrls.add(id);

        _globalProgressController.add(
          DownloadProgress(
            id: id,
            status: DownloadStatus.pending,
            progress: 0.0,
            downloadedSize: 0,
            fileSize: 0,
          ),
        );
      } else {
        logger.w(
          '[DownloadService] Failed to enqueue download for $url (taskId is null)',
        );
      }
    } catch (e) {
      logger.e('[DownloadService] Exception enqueuing download for $url: $e');
    }
  }

  /// Cancel a download by URL/ID.
  ///
  /// Attempts to cancel and remove the task from the download manager.
  /// Emits a cancelled progress event.
  @override
  Future<void> cancel(String id) async {
    await initialize();

    final List<DownloadTask>? tasks = await _queryTasksByUrl(id);

    if (tasks != null) {
      for (final DownloadTask task in tasks) {
        try {
          await _flutterDownloader.cancel(taskId: task.taskId);
          await _flutterDownloader.remove(
            taskId: task.taskId,
            shouldDeleteContent: true,
          );
        } catch (e) {
          logger.w(
            '[DownloadService] Error cancelling task ${task.taskId}: $e',
          );
        }
      }
    }

    _activeDownloadUrls.remove(id);

    _globalProgressController.add(
      DownloadProgress(
        id: id,
        status: DownloadStatus.cancelled,
        progress: 0.0,
        downloadedSize: 0,
        fileSize: 0,
      ),
    );
  }

  @override
  Future<void> cancelAll() async {
    await initialize();

    final List<DownloadTask>? tasks = await _flutterDownloader.loadTasks();

    if (tasks != null) {
      for (final DownloadTask task in tasks) {
        try {
          await _flutterDownloader.cancel(taskId: task.taskId);
          await _flutterDownloader.remove(
            taskId: task.taskId,
            shouldDeleteContent: true,
          );
        } catch (e) {
          logger.w(
            '[DownloadService] Error cancelling task ${task.taskId}: $e',
          );
        }
      }
    }

    final List<String> urlsToNotify = _activeDownloadUrls.toList();
    _activeDownloadUrls.clear();

    for (final id in urlsToNotify) {
      _globalProgressController.add(
        DownloadProgress(
          id: id,
          status: DownloadStatus.cancelled,
          progress: 0.0,
          downloadedSize: 0,
          fileSize: 0,
        ),
      );
    }
  }

  /// Get a filtered stream for a specific download.
  @override
  Stream<DownloadProgress> getProgressStream(String id) {
    return _globalProgressController.stream.where(
      (progress) => progress.id == id,
    );
  }

  /// Get all currently active download URLs.
  ///
  /// Queries fresh data from the downloader to ensure accuracy.
  @override
  Future<List<String>> getActiveDownloadIds() async {
    await initialize();

    try {
      final List<DownloadTask>? tasks = await _flutterDownloader.loadTasks();
      if (tasks == null) {
        return _activeDownloadUrls.toList();
      }

      // Update cache and return fresh list
      final Set<String> activeUrls = {};
      for (final DownloadTask task in tasks) {
        if (task.status == DownloadTaskStatus.running ||
            task.status == DownloadTaskStatus.enqueued) {
          activeUrls.add(task.url);
        }
      }
      _activeDownloadUrls
        ..clear()
        ..addAll(activeUrls);
      return activeUrls.toList();
    } catch (e) {
      logger.w('[DownloadService] Error getting active downloads: $e');
      return _activeDownloadUrls.toList();
    }
  }

  /// Check if a download is currently active.
  @override
  Future<bool> isStatusDownloadActive(String id) async {
    await initialize();
    return _activeDownloadUrls.contains(id);
  }

  /// Get the current status of a download.
  @override
  Future<DownloadStatus?> getStatus(String id) async {
    await initialize();
    final List<DownloadTask>? tasks = await _queryTasksByUrl(id);

    if (tasks == null || tasks.isEmpty) {
      return null;
    }

    return _statusMapper.mapTaskStatusToDownloadStatus(tasks.last.status);
  }

  /// Cleanup and dispose of resources.
  @override
  Future<void> disposeService() async {
    try {
      _isolateManager.dispose();
    } catch (_) {}
    _initialized = false;
    _taskIdToUrlMap.clear();
    _activeDownloadUrls.clear();
  }

  /// Query tasks by URL from FlutterDownloader database.
  ///
  /// Note: flutter_downloader's loadTasksWithRawQuery doesn't support
  /// parameterized queries, so we load all and filter. This is a limitation
  /// of the underlying library.
  Future<List<DownloadTask>?> _queryTasksByUrl(String url) async {
    try {
      final List<DownloadTask>? tasks = await _flutterDownloader.loadTasks();
      if (tasks == null) {
        return null;
      }
      return tasks.where((t) => t.url == url).toList();
    } catch (e) {
      logger.w('[DownloadService] Error querying tasks for $url: $e');
      return null;
    }
  }

  /// Remove a task from the downloader with a small retry/backoff policy.
  /// Helps handle transient platform/database errors when calling into the
  /// native downloader plugin.
  Future<void> _removeTaskWithRetries(String taskId, {int retries = 3}) async {
    var attempt = 0;
    while (true) {
      try {
        await _flutterDownloader.remove(taskId: taskId);
        logger.d('[DownloadService] Successfully removed task $taskId');
        return;
      } catch (e) {
        attempt++;
        logger.w(
          '[DownloadService] Failed to remove task $taskId (attempt $attempt): $e',
        );
        if (attempt >= retries) {
          logger.e(
            '[DownloadService] Giving up removing task $taskId after $attempt attempts',
          );
          return;
        }
        await Future.delayed(Duration(milliseconds: 200 * attempt));
      }
    }
  }

  /// Static callback registered with FlutterDownloader.
  /// Called by the platform layer when download status/progress changes.
  @pragma('vm:entry-point')
  static void downloadCallback(String id, int status, int progress) {
    DownloadIsolateManager.forwardDownloadUpdate(id, status, progress);
  }
}
