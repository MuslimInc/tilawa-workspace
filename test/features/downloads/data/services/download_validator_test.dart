import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tilawa/features/downloads/data/datasources/downloads_local_datasource.dart';
import 'package:tilawa/features/downloads/data/services/download_validator.dart';

class MockDownloadsLocalDataSource extends Mock
    implements DownloadsLocalDataSource {}

void main() {
  late MockDownloadsLocalDataSource mockDataSource;
  late DownloadValidator validator;
  late Directory tempDir;

  setUp(() {
    mockDataSource = MockDownloadsLocalDataSource();
    validator = DownloadValidator(mockDataSource);
    tempDir = Directory.systemTemp.createTempSync('dv_test');
  });

  tearDown(() {
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  group('verifyFileExists', () {
    test('returns true if datasource returns true immediately', () async {
      when(() => mockDataSource.isFileExists('path')).thenReturn(true);
      final bool result = await validator.verifyFileExists('path');
      expect(result, isTrue);
      verify(() => mockDataSource.isFileExists('path')).called(1);
    });

    test('retries if datasource returns false initially', () async {
      var callCount = 0;
      when(() => mockDataSource.isFileExists('path')).thenAnswer((_) {
        callCount++;
        if (callCount < 2) {
          return false;
        }
        return true;
      });

      final bool result = await validator.verifyFileExists(
        'path',
        maxRetries: 3,
      );
      expect(result, isTrue);
      expect(callCount, 2);
    });

    test('returns false if never found after retries', () async {
      when(() => mockDataSource.isFileExists('path')).thenReturn(false);
      final bool result = await validator.verifyFileExists(
        'path',
        maxRetries: 2,
      );
      expect(result, isFalse);
      verify(() => mockDataSource.isFileExists('path')).called(2);
    });
  });

  group('verifyFileSize', () {
    test('returns true if file size matches', () async {
      final file = File('${tempDir.path}/test.mp3');
      await file.writeAsBytes(List.filled(100, 0)); // 100 bytes

      final bool result = await validator.verifyFileSize(file.path, 100);
      expect(result, isTrue);
    });

    test('returns true if size within tolerance', () async {
      final file = File('${tempDir.path}/test.mp3');
      await file.writeAsBytes(List.filled(100, 0)); // 100 bytes

      // Tolerance 1% of 100 is 1.
      // Expected 101, Actual 100. Diff 1. <= Tolerance.
      final bool result = await validator.verifyFileSize(file.path, 101);
      expect(result, isTrue);
    });

    test('returns false if size mismatch outside tolerance', () async {
      final file = File('${tempDir.path}/test.mp3');
      await file.writeAsBytes(List.filled(100, 0)); // 100 bytes

      // Expected 150. Diff 50. > Tolerance (1).
      final bool result = await validator.verifyFileSize(file.path, 150);
      expect(result, isFalse);
    });

    test('returns false if file does not exist', () async {
      final bool result = await validator.verifyFileSize(
        '${tempDir.path}/missing.mp3',
        100,
      );
      expect(result, isFalse);
    });
  });
}
