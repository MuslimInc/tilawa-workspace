import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'dart:ui';

import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_downloader/flutter_downloader.dart';

import '../../../../main.dart';
import '../../domain/entities/download_item.dart';
import '../../utils/download_path_utils.dart';
import 'flutter_downloader_wrapper.dart';

@pragma('vm:entry-point')
class DownloadService {
  /// Create a new DownloadService.
  ///
  /// [flutterDownloader] can be provided for testing purposes.
  DownloadService({FlutterDownloaderWrapper? flutterDownloader})
    : _flutterDownloader = flutterDownloader ?? FlutterDownloaderWrapper();

  /// Singleton instance for backward compatibility
  static final DownloadService _instance = DownloadService();
  static DownloadService get instance => _instance;

  FlutterDownloaderWrapper _flutterDownloader;
  final StreamController<DownloadProgress> _globalProgressController =
      StreamController<DownloadProgress>.broadcast();

  /// Tracks initialization state
  bool _initialized = false;
  Completer<void>? _initializationCompleter;
  ReceivePort? _port;
  static const String _portName = 'downloader_send_port';

  /// Map to store taskId -> URL for reverse lookups
  /// Used to map platform callbacks back to external IDs
  final Map<String, String> _taskIdToUrlMap = {};

  // --------------------------------------------------------------------------
  // Static Compatibility Layer
  // --------------------------------------------------------------------------

  @visibleForTesting
  static FlutterDownloaderWrapper get flutterDownloaderTestOverride =>
      instance._flutterDownloader;

  @visibleForTesting
  static set flutterDownloaderTestOverride(FlutterDownloaderWrapper value) {
    instance._flutterDownloader = value;
  }

  /// Stream for monitoring all download progress updates globally.
  /// Emits [DownloadProgress] events for every active download.
  static Stream<DownloadProgress> get globalProgressStream =>
      instance._globalProgressController.stream;

  /// Get a filtered stream for a specific download by URL.
  ///
  /// [id] The download URL/ID to monitor.
  /// Returns a stream that only emits updates for the specified download.
  static Stream<DownloadProgress> progressStream(String id) =>
      instance.getProgressStream(id);

  /// Get all currently active download URLs.
  ///
  /// Returns a list of URLs for downloads that are running or enqueued.
  static Future<List<String>> get activeDownloadIds =>
      instance.getActiveDownloadIds();

  /// Check if a download is currently active (running or enqueued).
  ///
  /// [id] The download URL/ID to check.
  /// Returns true if the download is active, false otherwise.
  static Future<bool> isDownloadActive(String id) =>
      instance.isStatusDownloadActive(id);

  /// Get the current status of a download.
  ///
  /// [id] The download URL/ID.
  /// Returns the [DownloadStatus] or null if not found.
  static Future<DownloadStatus?> getDownloadStatus(String id) =>
      instance.getStatus(id);

  /// Start a new download.
  ///
  /// [id] Unique identifier (typically the download URL).
  /// [url] The remote file URL to download.
  /// [filePath] Local file path where to save the download.
  /// [title] Human-readable title for notifications.
  /// [reciterName] The reciter name (metadata).
  static Future<void> startDownload({
    required String id,
    required String url,
    required String filePath,
    required String title,
    required String reciterName,
  }) => instance.download(
    id: id,
    url: url,
    filePath: filePath,
    title: title,
    reciterName: reciterName,
  );

  /// Cancel a download by its ID.
  ///
  /// [id] The download URL/ID to cancel.
  static Future<void> cancelDownload(String id) => instance.cancel(id);

  /// Dispose and cleanup the download service.
  static Future<void> dispose() => instance.disposeService();

  @visibleForTesting
  static Future<void> reset() async {
    await instance.disposeService();
  }

  // --------------------------------------------------------------------------
  // Instance Methods
  // --------------------------------------------------------------------------

  /// Initialize the download service and set up update listeners.
  ///
  /// Must be called before any download operations. Safe to call multiple times.
  /// Subsequent calls will return the same initialization future.
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
      // Assumes WidgetsFlutterBinding is already initialized in main.dart
      try {
        await _flutterDownloader.initialize();
      } catch (e) {
        // FlutterDownloader may be already initialized or have platform issues
        logger.d('[DownloadService] FlutterDownloader initialize warning: $e');
      }

      // Register port for background IPC communication
      _registerPort();

      // Register the static callback for platform layer
      await _flutterDownloader.registerCallback(_downloadCallback);

      logger.d('[DownloadService] Initialized successfully');
    } catch (e) {
      logger.w('[DownloadService] Initialization error: $e');
      rethrow;
    }
  }

  /// Register an isolate port for receiving download updates from the platform layer.
  /// Uses IsolateNameServer for cross-isolate communication.
  void _registerPort() {
    IsolateNameServer.removePortNameMapping(_portName);

    _port = ReceivePort();
    IsolateNameServer.registerPortWithName(_port!.sendPort, _portName);

    _port!.listen((dynamic data) async {
      if (data is List && data.length >= 3) {
        final taskId = data[0] as String;
        final statusInt = data[1] as int;
        final progress = data[2] as int;
        final status = DownloadTaskStatus.fromInt(statusInt);

        await _handleTaskUpdate(taskId, status, progress);
      }
    });
  }

  /// Static callback registered with FlutterDownloader.
  /// Called by the platform layer when download status/progress changes.
  /// Posts updates to the registered isolate port.
  @pragma('vm:entry-point')
  static void _downloadCallback(String id, int status, int progress) {
    final SendPort? send = IsolateNameServer.lookupPortByName(_portName);
    send?.send([id, status, progress]);
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
      final DownloadStatus downloadStatus = _mapTaskStatusToDownloadStatus(
        status,
      );
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
  Future<void> download({
    required String id,
    required String url,
    required String filePath,
    required String title,
    required String reciterName,
  }) async {
    await initialize();

    // Check if task already exists for this URL
    // Status codes: 1=enqueued, 2=running, 3=complete, 4=failed, 5=cancelled
    final List<DownloadTask>? existingTasks = await _queryTasksByUrl(url);

    if (existingTasks != null && existingTasks.isNotEmpty) {
      final DownloadTask task = existingTasks.first;

      if (task.status == DownloadTaskStatus.complete) {
        // Already completed
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
      } else if (task.status == DownloadTaskStatus.running ||
          task.status == DownloadTaskStatus.enqueued) {
        // Already active, map it
        _taskIdToUrlMap[task.taskId] = id;
        return;
      }
    }

    // Create directory if needed
    final String savedDir = DownloadPathUtils.getDirectoryName(filePath);
    final String fileName = DownloadPathUtils.getFileName(filePath);
    final dir = Directory(savedDir);

    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
    }

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
      logger.w('[DownloadService] Failed to enqueue download for $url');
    }
  }

  /// Cancel a download by URL/ID.
  ///
  /// Attempts to cancel and remove the task from the download manager.
  /// Emits a cancelled progress event.
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

  /// Get a filtered stream for a specific download.
  Stream<DownloadProgress> getProgressStream(String id) {
    return _globalProgressController.stream.where(
      (progress) => progress.id == id,
    );
  }

  /// Get all currently active download URLs.
  Future<List<String>> getActiveDownloadIds() async {
    await initialize();
    final List<DownloadTask>? tasks = await _flutterDownloader.loadTasks();

    if (tasks == null) {
      return [];
    }

    return tasks
        .where(
          (t) =>
              t.status == DownloadTaskStatus.running ||
              t.status == DownloadTaskStatus.enqueued,
        )
        .map((t) => t.url)
        .toList();
  }

  /// Check if a download is currently active.
  Future<bool> isStatusDownloadActive(String id) async {
    await initialize();
    final List<DownloadTask>? tasks = await _queryTasksByUrl(id);

    if (tasks == null || tasks.isEmpty) {
      return false;
    }

    return tasks.any(
      (t) =>
          t.status == DownloadTaskStatus.running ||
          t.status == DownloadTaskStatus.enqueued,
    );
  }

  /// Get the current status of a download.
  Future<DownloadStatus?> getStatus(String id) async {
    await initialize();
    final List<DownloadTask>? tasks = await _queryTasksByUrl(id);

    if (tasks == null || tasks.isEmpty) {
      return null;
    }

    return _mapTaskStatusToDownloadStatus(tasks.last.status);
  }

  /// Cleanup and dispose of resources.
  Future<void> disposeService() async {
    _port?.close();
    IsolateNameServer.removePortNameMapping(_portName);
    _initialized = false;
    _taskIdToUrlMap.clear();
  }

  /// Query tasks by URL from FlutterDownloader database.
  ///
  /// Note: flutter_downloader's loadTasksWithRawQuery doesn't support
  /// parameterized queries, so we load all and filter. This is a limitation
  /// of the underlying library.
  Future<List<DownloadTask>?> _queryTasksByUrl(String url) async {
    try {
      final List<DownloadTask>? tasks = await _flutterDownloader.loadTasks();
      if (tasks == null) return null;
      return tasks.where((t) => t.url == url).toList();
    } catch (e) {
      logger.w('[DownloadService] Error querying tasks for $url: $e');
      return null;
    }
  }

  /// Map FlutterDownloader task status to app-level status.
  static DownloadStatus _mapTaskStatusToDownloadStatus(
    DownloadTaskStatus status,
  ) {
    return switch (status) {
      DownloadTaskStatus.enqueued => DownloadStatus.pending,
      DownloadTaskStatus.running => DownloadStatus.downloading,
      DownloadTaskStatus.complete => DownloadStatus.completed,
      DownloadTaskStatus.failed => DownloadStatus.failed,
      DownloadTaskStatus.canceled => DownloadStatus.cancelled,
      DownloadTaskStatus.paused => DownloadStatus.paused,
      _ => DownloadStatus.failed,
    };
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
