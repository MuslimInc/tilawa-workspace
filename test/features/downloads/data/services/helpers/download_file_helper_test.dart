import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:muzakri/features/downloads/data/services/helpers/download_file_helper.dart';

void main() {
  late DownloadFileHelper fileHelper;

  setUp(() {
    fileHelper = DownloadFileHelper();
  });

  group('DownloadFileHelper', () {
    test('getDirectoryName extracts directory correctly', () {
      expect(fileHelper.getDirectoryName('/path/to/file.mp3'), '/path/to');
      expect(fileHelper.getDirectoryName('file.mp3'), '.');
    });

    test('getFileName extracts filename correctly', () {
      expect(fileHelper.getFileName('/path/to/file.mp3'), 'file.mp3');
      expect(fileHelper.getFileName('file.mp3'), 'file.mp3');
    });

    test('ensureDirectoryExists creates directory if not exists', () async {
      final Directory tempDir = Directory.systemTemp.createTempSync(
        'download_helper_test',
      );
      final targetDir = Directory('${tempDir.path}/nested/dir');

      expect(targetDir.existsSync(), isFalse);

      final bool result = fileHelper.ensureDirectoryExists(
        targetDir.path,
      );

      expect(result, isTrue);
      expect(targetDir.existsSync(), isTrue);

      // Cleanup
      tempDir.deleteSync(recursive: true);
    });

    test(
      'ensureDirectoryExists returns true if directory already exists',
      () async {
        final Directory tempDir = Directory.systemTemp.createTempSync(
          'download_helper_test_2',
        );

        expect(tempDir.existsSync(), isTrue);

        final bool result = fileHelper.ensureDirectoryExists(
          tempDir.path,
        );

        expect(result, isTrue);
        expect(tempDir.existsSync(), isTrue);

        // Cleanup
        tempDir.deleteSync(recursive: true);
      },
    );

    test(
      'ensureDirectoryExists returns false and logs error on failure',
      () async {
        final Directory tempDir = Directory.systemTemp.createTempSync(
          'download_helper_test_3',
        );

        // Create a file with the same name as the intended directory
        // This causes createSync to throw a FileSystemException
        final fileBlockingDir = File('${tempDir.path}/blocked_dir');
        fileBlockingDir.createSync();

        final bool result = fileHelper.ensureDirectoryExists(
          fileBlockingDir.path,
        );

        expect(result, isFalse);

        // Cleanup
        tempDir.deleteSync(recursive: true);
      },
    );
  });
}
