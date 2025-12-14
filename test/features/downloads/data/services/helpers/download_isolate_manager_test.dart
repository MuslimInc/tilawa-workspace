import 'dart:async';
import 'dart:isolate';
import 'dart:ui';

import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:muzakri/features/downloads/data/services/helpers/download_isolate_manager.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late DownloadIsolateManager isolateManager;
  const portName = 'downloader_send_port';

  setUp(() {
    isolateManager = DownloadIsolateManager();
  });

  tearDown(() {
    isolateManager.dispose();
  });

  group('DownloadIsolateManager', () {
    test('registerPort registers a ReceivePort with IsolateNameServer', () {
      isolateManager.registerPort();

      final SendPort? sendPort = IsolateNameServer.lookupPortByName(portName);
      expect(sendPort, isNotNull);
    });

    test('updateStream emits events when data is sent to the port', () async {
      isolateManager.registerPort();

      final SendPort? sendPort = IsolateNameServer.lookupPortByName(portName);
      expect(sendPort, isNotNull);

      // Listen to the stream
      // DownloadTaskStatus:
      // 1: enqueued, 2: running, 3: complete, 4: failed, 5: canceled, 6: paused

      // Expect running (2)
      unawaited(
        expectLater(
          isolateManager.updateStream,
          emits(
            predicate<(String, DownloadTaskStatus, int)>((tuple) {
              return tuple.$1 == 'task-1' &&
                  tuple.$2 == DownloadTaskStatus.running &&
                  tuple.$3 == 50;
            }),
          ),
        ),
      );

      // Simulate sending data (2 = running)
      sendPort!.send(['task-1', 2, 50]);
    });

    test('forwardDownloadUpdate sends data to the registered port', () async {
      isolateManager.registerPort();

      // Listen to the stream to verify receipt
      // Expect complete (3)
      unawaited(
        expectLater(
          isolateManager.updateStream,
          emits(
            predicate<(String, DownloadTaskStatus, int)>((tuple) {
              return tuple.$1 == 'task-2' &&
                  tuple.$2 == DownloadTaskStatus.complete &&
                  tuple.$3 == 100;
            }),
          ),
        ),
      );

      // Use the static method to forward data (3 = complete)
      DownloadIsolateManager.forwardDownloadUpdate('task-2', 3, 100);
    });

    test('dispose removes the port mapping', () {
      isolateManager.registerPort();
      expect(IsolateNameServer.lookupPortByName(portName), isNotNull);

      isolateManager.dispose();
      expect(IsolateNameServer.lookupPortByName(portName), isNull);
    });
  });
}
