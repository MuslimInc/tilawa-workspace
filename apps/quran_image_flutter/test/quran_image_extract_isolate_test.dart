import 'dart:io';
import 'dart:isolate';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_image_flutter/data/repositories/quran_image_extract_isolate.dart';

void main() {
  late Directory tempDirectory;

  setUp(() async {
    tempDirectory = await Directory.systemTemp.createTemp(
      'quran_image_extract_isolate_test_',
    );
  });

  tearDown(() async {
    if (tempDirectory.existsSync()) {
      await tempDirectory.delete(recursive: true);
    }
  });

  test(
    'extractIsolateEntryPoint extracts files and reports completion',
    () async {
      final archive = Archive()
        ..addFile(ArchiveFile('folder/a.txt', 1, 'A'.codeUnits))
        ..addFile(ArchiveFile('folder/b.txt', 1, 'B'.codeUnits));
      final archivePath = '${tempDirectory.path}/archive.zip';
      await File(archivePath).writeAsBytes(ZipEncoder().encode(archive));

      final destination = '${tempDirectory.path}/out';
      final receivePort = ReceivePort();
      addTearDown(receivePort.close);

      extractIsolateEntryPoint(
        ExtractMessage(
          archivePath: archivePath,
          destinationPath: destination,
          sendPort: receivePort.sendPort,
        ),
      );

      final result = await receivePort.first as ExtractDone;

      expect(result.count, 2);
      expect(result.error, isNull);
      expect(File('$destination/folder/a.txt').readAsStringSync(), 'A');
      expect(File('$destination/folder/b.txt').readAsStringSync(), 'B');
    },
  );

  test('extractIsolateEntryPoint reports extraction failures', () async {
    final receivePort = ReceivePort();
    addTearDown(receivePort.close);

    extractIsolateEntryPoint(
      ExtractMessage(
        archivePath: '${tempDirectory.path}/missing.zip',
        destinationPath: '${tempDirectory.path}/out',
        sendPort: receivePort.sendPort,
      ),
    );

    final result = await receivePort.first as ExtractDone;
    expect(result.count, 0);
    expect(result.error, isNotNull);
  });
}
