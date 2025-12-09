import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'dart:ui';

import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:path/path.dart' as path;

import '../../../../main.dart';
import '../../domain/entities/download_item.dart';
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

  bool _initialized = false;
  Completer<void>? _initializationCompleter;
  ReceivePort? _port;
  static const String _portName = 'downloader_send_port';

  // Map to store taskId -> externalId (URL)
  final Map<String, String> _taskIdMap = {};

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

  static Stream<DownloadProgress> get globalProgressStream =>
      instance._globalProgressController.stream;

  static Stream<DownloadProgress> progressStream(String id) =>
      instance.getProgressStream(id);

  static Future<List<String>> get activeDownloadIds =>
      instance.getActiveDownloadIds();

  static Future<bool> isDownloadActive(String id) =>
      instance.isStatusDownloadActive(id);

  static Future<DownloadStatus?> getDownloadStatus(String id) =>
      instance.getStatus(id);

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

  static Future<void> cancelDownload(String id) => instance.cancel(id);

  static Future<void> dispose() => instance.disposeService();

  @visibleForTesting
  static Future<void> reset() async {
    await instance.disposeService();
  }

  // --------------------------------------------------------------------------
  // Instance Methods
  // --------------------------------------------------------------------------

  /// Initialize the download service and set up update listeners
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

  Future<void> _performInitialization() async {
    try {
      // Initialize FlutterDownloader
      // We assume WidgetsFlutterBinding is already initialized in main.dart
      try {
        await _flutterDownloader.initialize();
      } catch (e) {
        logger.d('[DownloadService] FlutterDownloader initialize warning: $e');
        // It might be already initialized or platform issues
      }

      // Register port for background communication
      _registerPort();

      // Register the static callback
      await _flutterDownloader.registerCallback(_downloadCallback);

      logger.d('[DownloadService] Initialized with FlutterDownloader');
    } catch (e) {
      logger.w('[DownloadService] Error during initialization: $e');
      rethrow;
    }
  }

  void _registerPort() {
    IsolateNameServer.removePortNameMapping(_portName);

    _port = ReceivePort();
    IsolateNameServer.registerPortWithName(_port!.sendPort, _portName);

    _port!.listen((dynamic data) async {
      if (data is List) {
        final taskId = data[0] as String;
        final statusInt = data[1] as int;
        final progress = data[2] as int;
        final status = DownloadTaskStatus.fromInt(statusInt);

        await _handleTaskUpdate(taskId, status, progress);
      }
    });
  }

  @pragma('vm:entry-point')
  static void _downloadCallback(String id, int status, int progress) {
    final SendPort? send = IsolateNameServer.lookupPortByName(_portName);
    send?.send([id, status, progress]);
  }

  Future<void> _handleTaskUpdate(
    String taskId,
    DownloadTaskStatus status,
    int progress,
  ) async {
    // Resolve external ID (URL)
    String? externalId = _taskIdMap[taskId];

    if (externalId == null) {
      // Try to find it in DB
      try {
        final List<DownloadTask>? tasks = await _flutterDownloader
            .loadTasksWithRawQuery(
              query: "SELECT * FROM task WHERE task_id = '$taskId'",
            );
        if (tasks != null && tasks.isNotEmpty) {
          externalId = tasks.first.url;
          _taskIdMap[taskId] = externalId;
        }
      } catch (e) {
        logger.w('[DownloadService] Error resolving taskId $taskId: $e');
      }
    }

    if (externalId != null) {
      final DownloadStatus downloadStatus = _mapTaskStatusToDownloadStatus(
        status,
      );
      _globalProgressController.add(
        DownloadProgress(
          id: externalId,
          status: downloadStatus,
          progress: progress / 100.0,
          downloadedSize: 0,
          fileSize: 0,
        ),
      );
    }
  }

  Future<void> download({
    required String id,
    required String url,
    required String filePath,
    required String title,
    required String reciterName,
  }) async {
    await initialize();

    // Check if already active
    // We treat 'id' as the URL for querying purposes
    final List<DownloadTask>?
    tasks = await _flutterDownloader.loadTasksWithRawQuery(
      query:
          "SELECT * FROM task WHERE url = '$url' AND status != 4 AND status != 5",
    );

    if (tasks != null && tasks.isNotEmpty) {
      final DownloadTask task = tasks.first;
      if (task.status == DownloadTaskStatus.complete) {
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
        // Already active
        // Map the existing taskId to this ID just in case
        _taskIdMap[task.taskId] = id;
        return;
      }
    }

    final String savedDir = path.dirname(filePath);
    final String fileName = path.basename(filePath);

    final dir = Directory(savedDir);
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
    }

    final String? taskId = await _flutterDownloader.enqueue(
      url: url,
      savedDir: savedDir,
      fileName: fileName,
      openFileFromNotification: false,
      title: title,
    );

    if (taskId != null) {
      _taskIdMap[taskId] = id;

      _globalProgressController.add(
        DownloadProgress(
          id: id,
          status: DownloadStatus.pending,
          progress: 0.0,
          downloadedSize: 0,
          fileSize: 0,
        ),
      );
    }
  }

  Future<void> cancel(String id) async {
    await initialize();
    // Assuming id is the URL
    final List<DownloadTask>? tasks = await _flutterDownloader
        .loadTasksWithRawQuery(query: "SELECT * FROM task WHERE url = '$id'");

    if (tasks != null) {
      for (final DownloadTask task in tasks) {
        // Cancel or remove. Remove is safer to clean up DB.
        await _flutterDownloader.cancel(taskId: task.taskId);
        await _flutterDownloader.remove(
          taskId: task.taskId,
          shouldDeleteContent: true,
        );
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

  Stream<DownloadProgress> getProgressStream(String id) {
    return _globalProgressController.stream.where(
      (progress) => progress.id == id,
    );
  }

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

  Future<bool> isStatusDownloadActive(String id) async {
    await initialize();
    final List<DownloadTask>? tasks = await _flutterDownloader
        .loadTasksWithRawQuery(query: "SELECT * FROM task WHERE url = '$id'");
    if (tasks == null || tasks.isEmpty) {
      return false;
    }

    return tasks.any(
      (t) =>
          t.status == DownloadTaskStatus.running ||
          t.status == DownloadTaskStatus.enqueued,
    );
  }

  Future<DownloadStatus?> getStatus(String id) async {
    await initialize();
    final List<DownloadTask>? tasks = await _flutterDownloader
        .loadTasksWithRawQuery(query: "SELECT * FROM task WHERE url = '$id'");
    if (tasks == null || tasks.isEmpty) {
      return null;
    }

    final DownloadTask task = tasks.last;
    return _mapTaskStatusToDownloadStatus(task.status);
  }

  Future<void> disposeService() async {
    _port?.close();
    IsolateNameServer.removePortNameMapping(_portName);
    _initialized = false;
    _taskIdMap.clear();
  }

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

/// Download Status Enum related classes
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
