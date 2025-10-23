import 'dart:async';
import 'dart:isolate';

import 'package:dio/dio.dart';
import 'package:muzakri/features/downloads/domain/entities/download_item.dart';
import 'package:muzakri/main.dart';

class DownloadService {
  static final Map<String, _DownloadTask> _tasks = {};
  static final StreamController<DownloadProgress> _globalProgressController =
      StreamController<DownloadProgress>.broadcast();

  /// Start downloading a file in background with its own isolate
  static Future<void> startDownload({
    required String id,
    required String url,
    required String filePath,
    required String title,
    required String reciterName,
  }) async {
    if (_tasks.containsKey(id)) {
      // Already downloading
      // ignore: avoid_print
      print('[DownloadService] startDownload skipped: id=$id already active');
      return;
    }

    // ignore: avoid_print
    print(
      '[DownloadService] startDownload: id=$id title="$title" reciter="$reciterName" url=$url path=$filePath',
    );

    final receivePort = ReceivePort();
    final completer = Completer<SendPort>();

    late final StreamSubscription sub;
    sub = receivePort.listen((message) {
      if (message is SendPort) {
        completer.complete(message);
      } else if (message is DownloadProgress) {
        // Forward to individual task controller
        _tasks[id]?.controller.add(message);
        // Forward to global progress stream
        _globalProgressController.add(message);
        if (message.progress == 0.0 || message.progress == 1.0) {
          // ignore: avoid_print
          print(
            '[DownloadService] progress: id=${message.id} status=${message.status} progress=${message.progress}',
          );
        }
      }
    });

    final isolate = await Isolate.spawn<_DownloadInitMessage>(
      _downloadIsolateEntry,
      _DownloadInitMessage(
        id: id,
        url: url,
        filePath: filePath,
        title: title,
        reciterName: reciterName,
        sendPort: receivePort.sendPort,
      ),
    );

    final sendPort = await completer.future;

    final controller = StreamController<DownloadProgress>.broadcast(
      onCancel: () {
        // Optionally handle controller cancellation
      },
    );

    _tasks[id] = _DownloadTask(
      isolate: isolate,
      controller: controller,
      receivePort: receivePort,
      sendPort: sendPort,
      subscription: sub,
    );

    // ignore: avoid_print
    print('[DownloadService] task registered: id=$id');
  }

  /// Listen to download progress of a specific download ID
  static Stream<DownloadProgress> progressStream(String id) {
    final task = _tasks[id];
    if (task != null) {
      return task.controller.stream;
    }
    return Stream.empty();
  }

  /// Listen to all download progress updates
  static Stream<DownloadProgress> get globalProgressStream =>
      _globalProgressController.stream;

  /// Get all active download task IDs
  static List<String> get activeDownloadIds => _tasks.keys.toList();

  /// Check if a download is active
  static bool isDownloadActive(String id) => _tasks.containsKey(id);

  /// Dispose all downloads and cleanup
  static Future<void> dispose() async {
    // Cancel all active downloads
    // ignore: avoid_print
    print(
      '[DownloadService] dispose: cancelling ${_tasks.length} active task(s)',
    );
    for (final task in _tasks.values) {
      task.isolate.kill(priority: Isolate.immediate);
      await task.subscription.cancel();
      task.receivePort.close();
      await task.controller.close();
    }
    _tasks.clear();
    await _globalProgressController.close();
    // ignore: avoid_print
    print('[DownloadService] dispose: done');
  }

  /// Cancel a download and clean up its resources
  static Future<void> cancelDownload(String id) async {
    final task = _tasks.remove(id);
    if (task != null) {
      // ignore: avoid_print
      print('[DownloadService] cancelDownload: id=$id');
      task.isolate.kill(priority: Isolate.immediate);
      await task.subscription.cancel();
      task.receivePort.close();
      await task.controller.close();
    }
  }

  @pragma('vm:entry-point')
  static void _downloadIsolateEntry(_DownloadInitMessage message) async {
    final id = message.id;
    final url = message.url;
    final filePath = message.filePath;
    final sendPort = message.sendPort;

    final receivePort = ReceivePort();
    sendPort.send(receivePort.sendPort);

    final dio = Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 30),
        followRedirects: true,
        maxRedirects: 5,
        validateStatus: (status) => status != null && status < 500,
        headers: {'User-Agent': 'muzakri/1.0 (Flutter; Dart)'},
      ),
    );
    final cancelToken = CancelToken();

    receivePort.listen((dynamic msg) {
      // We can extend this for pause/resume if needed
      if (msg is String && msg == 'cancel') {
        cancelToken.cancel();
      }
    });

    try {
      // ignore: avoid_print
      logger.d(
        '[DownloadService Isolate] starting: id=$id url=$url -> $filePath',
      );
      // Send initial progress
      sendPort.send(
        DownloadProgress(
          id: id,
          status: DownloadStatus.downloading,
          progress: 0.0,
          downloadedSize: 0,
          fileSize: 0,
        ),
      );

      await dio.download(
        url,
        filePath,
        cancelToken: cancelToken,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            final progress = received / total;
            sendPort.send(
              DownloadProgress(
                id: id,
                status: DownloadStatus.downloading,
                progress: progress,
                downloadedSize: received,
                fileSize: total,
              ),
            );
            if (received == 0 || received == total) {
              logger.d(
                '[DownloadService Isolate] onReceive: id=$id received=$received total=$total',
              );
            }
          }
        },
      );

      // Send completion
      sendPort.send(
        DownloadProgress(
          id: id,
          status: DownloadStatus.completed,
          progress: 1.0,
          downloadedSize: 0,
          fileSize: 0,
        ),
      );
      // ignore: avoid_print
      print('[DownloadService Isolate] completed: id=$id');
    } catch (e) {
      if (e is DioException && e.type == DioExceptionType.cancel) {
        // ignore: avoid_print
        print('[DownloadService Isolate] cancelled: id=$id');
        sendPort.send(
          DownloadProgress(
            id: id,
            status: DownloadStatus.cancelled,
            progress: 0.0,
            downloadedSize: 0,
            fileSize: 0,
          ),
        );
      } else {
        if (e is DioException) {
          // ignore: avoid_print
          print(
            '[DownloadService Isolate] DioException: id=$id type=${e.type} status=${e.response?.statusCode} message=${e.message} url=$url',
          );
        } else {
          // ignore: avoid_print
          print(
            '[DownloadService Isolate] Error: id=$id error=${e.toString()}',
          );
        }
        sendPort.send(
          DownloadProgress(
            id: id,
            status: DownloadStatus.failed,
            progress: 0.0,
            downloadedSize: 0,
            fileSize: 0,
          ),
        );
      }
    } finally {
      receivePort.close();
      // ignore: avoid_print
      print('[DownloadService Isolate] closed: id=$id');
    }
  }
}

class _DownloadTask {
  final Isolate isolate;
  final StreamController<DownloadProgress> controller;
  final ReceivePort receivePort;
  final SendPort sendPort;
  final StreamSubscription subscription;

  _DownloadTask({
    required this.isolate,
    required this.controller,
    required this.receivePort,
    required this.sendPort,
    required this.subscription,
  });
}

class _DownloadInitMessage {
  final String id;
  final String url;
  final String filePath;
  final String title;
  final String reciterName;
  final SendPort sendPort;

  _DownloadInitMessage({
    required this.id,
    required this.url,
    required this.filePath,
    required this.title,
    required this.reciterName,
    required this.sendPort,
  });
}

class DownloadProgress {
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
}
