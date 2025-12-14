import 'package:flutter_downloader/flutter_downloader.dart';

/// Wrapper around [FlutterDownloader] to facilitate unit testing.
///
/// [FlutterDownloader] uses static methods which makes it hard to mock.
/// This wrapper exposes those methods as instance methods.
class FlutterDownloaderWrapper {
  Future<void> initialize({bool debug = true, bool ignoreSsl = false}) {
    return FlutterDownloader.initialize(debug: debug, ignoreSsl: ignoreSsl);
  }

  Future<void> registerCallback(
    DownloadCallback callback, {
    int step = 1,
  }) async {
    await FlutterDownloader.registerCallback(callback, step: step);
  }

  Future<String?> enqueue({
    required String url,
    required String savedDir,
    required String fileName,
    Map<String, String>? headers,
    bool showNotification = false, // Disabled - using custom notifications
    bool openFileFromNotification = true,
    bool requiresStorageNotLow = true,
    bool saveInPublicStorage = false,
    String? title,
  }) {
    return FlutterDownloader.enqueue(
      url: url,
      savedDir: savedDir,
      fileName: fileName,
      headers: headers ?? {}, // Fix: pass empty map if null
      showNotification: showNotification,
      openFileFromNotification: openFileFromNotification,
      requiresStorageNotLow: requiresStorageNotLow,
      saveInPublicStorage: saveInPublicStorage,
    );
  }

  Future<void> cancel({required String taskId}) {
    return FlutterDownloader.cancel(taskId: taskId);
  }

  Future<void> cancelAll() {
    return FlutterDownloader.cancelAll();
  }

  Future<void> pause({required String taskId}) {
    return FlutterDownloader.pause(taskId: taskId);
  }

  Future<void> resume({required String taskId}) {
    return FlutterDownloader.resume(taskId: taskId);
  }

  Future<void> retry({required String taskId}) {
    return FlutterDownloader.retry(taskId: taskId);
  }

  Future<void> remove({
    required String taskId,
    bool shouldDeleteContent = false,
  }) {
    return FlutterDownloader.remove(
      taskId: taskId,
      shouldDeleteContent: shouldDeleteContent,
    );
  }

  Future<List<DownloadTask>?> loadTasks() {
    return FlutterDownloader.loadTasks();
  }

  Future<List<DownloadTask>?> loadTasksWithRawQuery({required String query}) {
    return FlutterDownloader.loadTasksWithRawQuery(query: query);
  }
}
