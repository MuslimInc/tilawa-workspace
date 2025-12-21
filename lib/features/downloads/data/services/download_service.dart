import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_downloader/flutter_downloader.dart';

import '../../../../main.dart';
import '../../domain/entities/download_item.dart';
import 'flutter_downloader_wrapper.dart';
import 'helpers/download_file_helper.dart';
import 'helpers/download_isolate_manager.dart';
import 'helpers/download_status_mapper.dart';

/// Abstract interface for download service.
abstract class DownloadService {
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

  /// Cancel all active downloads.
  Future<void> cancelAll();

  /// Dispose and cleanup the download service.
  Future<void> disposeService();

  /// Initialize the download service and set up update listeners.
  Future<void> initialize();

  /// Static instance for backward compatibility - delegates to DownloadServiceImpl
  static DownloadService get instance => DownloadServiceImpl.instance;

  // --------------------------------------------------------------------------
  // Static Compatibility Layer - DEPRECATED: PREFER INSTANCE methods via DI
  // --------------------------------------------------------------------------

  static Stream<DownloadProgress> get globalProgressStreamStatic =>
      DownloadServiceImpl.instance._globalProgressController.stream;

  @visibleForTesting
  static StreamController<DownloadProgress> get globalProgressController =>
      DownloadServiceImpl.instance._globalProgressController;

  static Stream<DownloadProgress> progressStream(String id) =>
      DownloadServiceImpl.instance.getProgressStream(id);

  static Future<List<String>> get activeDownloadIds =>
      DownloadServiceImpl.instance.getActiveDownloadIds();

  static Future<bool> isDownloadActive(String id) =>
      DownloadServiceImpl.instance.isStatusDownloadActive(id);

  static Future<DownloadStatus?> getDownloadStatus(String id) =>
      DownloadServiceImpl.instance.getStatus(id);

  static Future<void> startDownload({
    required String id,
    required String url,
    required String filePath,
    required String title,
    required String reciterName,
    int? reciterId,
    bool showNotification = true,
  }) => DownloadServiceImpl.instance.download(
    id: id,
    url: url,
    filePath: filePath,
    title: title,
    reciterName: reciterName,
    reciterId: reciterId,
    showNotification: showNotification,
  );

  static Future<void> cancelDownload(String id) =>
      DownloadServiceImpl.instance.cancel(id);

  static Future<void> cancelAllDownloads() =>
      DownloadServiceImpl.instance.cancelAll();

  static Future<void> dispose() =>
      DownloadServiceImpl.instance.disposeService();

  @visibleForTesting
  static Future<void> reset() async {
    await DownloadServiceImpl.instance.disposeService();
  }

  @visibleForTesting
  static FlutterDownloaderWrapper get flutterDownloaderTestOverride =>
      DownloadServiceImpl.instance._flutterDownloader;

  @visibleForTesting
  static set flutterDownloaderTestOverride(FlutterDownloaderWrapper value) {
    DownloadServiceImpl.instance._flutterDownloader = value;
  }
}

@pragma('vm:entry-point')
class DownloadServiceImpl implements DownloadService {
  /// Create a new DownloadServiceImpl.
  ///
  /// [flutterDownloader] can be provided for testing purposes.
  DownloadServiceImpl({
    FlutterDownloaderWrapper? flutterDownloader,
    DownloadFileHelper? fileHelper,
    DownloadStatusMapper? statusMapper,
    DownloadIsolateManager? isolateManager,
  }) : _flutterDownloader = flutterDownloader ?? FlutterDownloaderWrapper(),
       _fileHelper = fileHelper ?? DownloadFileHelper(),
       _statusMapper = statusMapper ?? DownloadStatusMapper(),
       _isolateManager = isolateManager ?? DownloadIsolateManager();

  /// Singleton instance
  static final DownloadServiceImpl _instance = DownloadServiceImpl();
  static DownloadServiceImpl get instance => _instance;

  FlutterDownloaderWrapper _flutterDownloader;
  final DownloadFileHelper _fileHelper;
  final DownloadStatusMapper _statusMapper;
  final DownloadIsolateManager _isolateManager;

  final StreamController<DownloadProgress> _globalProgressController =
      StreamController<DownloadProgress>.broadcast();

  /// Tracks initialization state
  bool _initialized = false;
  Completer<void>? _initializationCompleter;

  @visibleForTesting
  static FlutterDownloaderWrapper get flutterDownloaderTestOverride =>
      instance._flutterDownloader;

  @visibleForTesting
  static set flutterDownloaderTestOverride(FlutterDownloaderWrapper value) {
    instance._flutterDownloader = value;
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
      rethrow;
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
      await _flutterDownloader.registerCallback(
        DownloadServiceImpl._downloadCallback,
        step: 3,
      );

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
        showNotification: showNotification,
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
  @override
  Future<List<String>> getActiveDownloadIds() async {
    await initialize();
    return _activeDownloadUrls.toList();
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
  static void _downloadCallback(String id, int status, int progress) {
    DownloadIsolateManager.forwardDownloadUpdate(id, status, progress);
  }
}

/// Download progress information.
///
/// Emitted by [DownloadService] to notify about download state changes.
///
/// Fields:
/// - `id`: The download identifier (typically the URL).
/// - `status`: Current download status (pending, downloading, completed, etc.).
/// - `progress`: Download progress as a fraction (0.0 to 1.0).
/// - `downloadedSize`: Bytes downloaded (not fully populated by flutter_downloader).
/// - `fileSize`: Total file size in bytes (not fully populated by flutter_downloader).
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
