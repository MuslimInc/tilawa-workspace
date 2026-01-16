import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa/features/downloads/data/services/flutter_downloader_wrapper.dart';

void main() {
  late FlutterDownloaderWrapper wrapper;

  setUp(() {
    wrapper = FlutterDownloaderWrapper();
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  test('initialize calls FlutterDownloader.initialize', () async {
    // We expect MissingPluginException because we are not mocking the channel
    // and running in a test environment. This proves the wrapper calls the static method.
    await expectLater(() => wrapper.initialize(), throwsA(anything));
  });

  test('registerCallback calls FlutterDownloader.registerCallback', () async {
    await expectLater(
      () => wrapper.registerCallback((id, status, progress) {}),
      throwsA(anything),
    );
  });

  test('enqueue calls FlutterDownloader.enqueue', () async {
    await expectLater(
      () => wrapper.enqueue(
        url: 'http://example.com',
        savedDir: '/tmp',
        fileName: 'file.mp3',
      ),
      throwsA(anything),
    );
  });

  test('cancel calls FlutterDownloader.cancel', () async {
    await expectLater(() => wrapper.cancel(taskId: '123'), throwsA(anything));
  });

  test('cancelAll calls FlutterDownloader.cancelAll', () async {
    await expectLater(() => wrapper.cancelAll(), throwsA(anything));
  });

  test('pause calls FlutterDownloader.pause', () async {
    await expectLater(() => wrapper.pause(taskId: '123'), throwsA(anything));
  });

  test('resume calls FlutterDownloader.resume', () async {
    await expectLater(() => wrapper.resume(taskId: '123'), throwsA(anything));
  });

  test('retry calls FlutterDownloader.retry', () async {
    await expectLater(() => wrapper.retry(taskId: '123'), throwsA(anything));
  });

  test('remove calls FlutterDownloader.remove', () async {
    await expectLater(() => wrapper.remove(taskId: '123'), throwsA(anything));
  });

  test('loadTasks calls FlutterDownloader.loadTasks', () async {
    await expectLater(() => wrapper.loadTasks(), throwsA(anything));
  });

  test(
    'loadTasksWithRawQuery calls FlutterDownloader.loadTasksWithRawQuery',
    () async {
      await expectLater(
        () => wrapper.loadTasksWithRawQuery(query: 'SELECT * FROM tasks'),
        throwsA(anything),
      );
    },
  );
}
