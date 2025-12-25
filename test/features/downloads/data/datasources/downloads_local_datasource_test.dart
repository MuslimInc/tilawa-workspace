import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:muzakri/features/downloads/data/datasources/downloads_local_datasource.dart';
import 'package:muzakri/features/downloads/domain/entities/download_item.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'downloads_local_datasource_test.mocks.dart';

@GenerateMocks([SharedPreferencesAsync])
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late DownloadsLocalDataSourceImpl dataSource;
  late MockSharedPreferencesAsync mockPrefs;

  // Test data
  final testDateTime = DateTime(2024, 1, 15, 10, 30);
  DownloadItem createTestDownload({
    String id = 'test_id',
    String title = 'Test Surah',
    String url = 'https://example.com/audio.mp3',
    String filePath = '/path/to/audio.mp3',
    String reciterName = 'Test Reciter',
    DownloadStatus status = DownloadStatus.completed,
    double progress = 1.0,
    int fileSize = 1024,
    int downloadedSize = 1024,
  }) {
    return DownloadItem(
      id: id,
      title: title,
      url: url,
      filePath: filePath,
      reciterName: reciterName,
      status: status,
      progress: progress,
      fileSize: fileSize,
      downloadedSize: downloadedSize,
      createdAt: testDateTime,
    );
  }

  setUp(() {
    mockPrefs = MockSharedPreferencesAsync();
    dataSource = DownloadsLocalDataSourceImpl(mockPrefs);
  });

  group('DownloadsLocalDataSourceImpl', () {
    group('getDownloads', () {
      test('should return empty list when no downloads stored', () async {
        // Arrange
        when(
          mockPrefs.getStringList('downloads'),
        ).thenAnswer((_) async => null);

        // Act
        final List<DownloadItem> result = await dataSource.getDownloads();

        // Assert
        expect(result, isEmpty);
        verify(mockPrefs.getStringList('downloads')).called(1);
      });

      test('should return list of downloads when data exists', () async {
        // Arrange
        final DownloadItem download = createTestDownload();
        final String jsonString = jsonEncode(download.toJson());
        when(
          mockPrefs.getStringList('downloads'),
        ).thenAnswer((_) async => [jsonString]);

        // Act
        final List<DownloadItem> result = await dataSource.getDownloads();

        // Assert
        expect(result.length, 1);
        expect(result.first.id, 'test_id');
        expect(result.first.title, 'Test Surah');
      });

      test('should parse multiple downloads correctly', () async {
        // Arrange
        final DownloadItem download1 = createTestDownload(
          id: 'id1',
          title: 'Surah 1',
        );
        final DownloadItem download2 = createTestDownload(
          id: 'id2',
          title: 'Surah 2',
        );
        final List<String> jsonList = [
          jsonEncode(download1.toJson()),
          jsonEncode(download2.toJson()),
        ];
        when(
          mockPrefs.getStringList('downloads'),
        ).thenAnswer((_) async => jsonList);

        // Act
        final List<DownloadItem> result = await dataSource.getDownloads();

        // Assert
        expect(result.length, 2);
        expect(result[0].id, 'id1');
        expect(result[1].id, 'id2');
      });

      test('should return cached downloads on second call', () async {
        // Arrange
        final DownloadItem download = createTestDownload();
        final String jsonString = jsonEncode(download.toJson());
        when(
          mockPrefs.getStringList('downloads'),
        ).thenAnswer((_) async => [jsonString]);

        // Act - First call loads from prefs
        final List<DownloadItem> result1 = await dataSource.getDownloads();
        // Second call should use cache (line 35)
        final List<DownloadItem> result2 = await dataSource.getDownloads();

        // Assert
        expect(result1.length, 1);
        expect(result2.length, 1);
        // Verify prefs was only called once (second call used cache)
        verify(mockPrefs.getStringList('downloads')).called(1);
      });
    });

    group('saveDownloads', () {
      test('should save downloads to shared preferences', () async {
        // Arrange
        final List<DownloadItem> downloads = [
          createTestDownload(id: 'id1'),
          createTestDownload(id: 'id2'),
        ];
        when(mockPrefs.setStringList(any, any)).thenAnswer((_) async {});

        // Act
        await dataSource.saveDownloads(downloads);

        // Assert
        final List<dynamic> captured = verify(
          mockPrefs.setStringList('downloads', captureAny),
        ).captured;
        final savedList = captured.first as List<String>;
        expect(savedList.length, 2);

        // Verify JSON is valid
        final decoded1 = jsonDecode(savedList[0]) as Map<String, dynamic>;
        expect(decoded1['id'], 'id1');
      });

      test('should save empty list when no downloads', () async {
        // Arrange
        when(mockPrefs.setStringList(any, any)).thenAnswer((_) async {});

        // Act
        await dataSource.saveDownloads([]);

        // Assert
        verify(mockPrefs.setStringList('downloads', [])).called(1);
      });
    });

    group('addDownload', () {
      test('should add new download to empty list', () async {
        // Arrange
        final DownloadItem download = createTestDownload();
        when(mockPrefs.getStringList('downloads')).thenAnswer((_) async => []);
        when(mockPrefs.setStringList(any, any)).thenAnswer((_) async {});

        // Act
        await dataSource.addDownload(download);

        // Assert
        final List<dynamic> captured = verify(
          mockPrefs.setStringList('downloads', captureAny),
        ).captured;
        final savedList = captured.first as List<String>;
        expect(savedList.length, 1);
      });

      test('should update existing download with same id', () async {
        // Arrange
        final DownloadItem existingDownload = createTestDownload(
          title: 'Old Title',
        );
        final DownloadItem updatedDownload = createTestDownload(
          title: 'New Title',
        );
        when(
          mockPrefs.getStringList('downloads'),
        ).thenAnswer((_) async => [jsonEncode(existingDownload.toJson())]);
        when(mockPrefs.setStringList(any, any)).thenAnswer((_) async {});

        // Act
        await dataSource.addDownload(updatedDownload);

        // Assert
        final List<dynamic> captured = verify(
          mockPrefs.setStringList('downloads', captureAny),
        ).captured;
        final savedList = captured.first as List<String>;
        expect(savedList.length, 1); // Should not add duplicate

        final decoded = jsonDecode(savedList[0]) as Map<String, dynamic>;
        expect(decoded['title'], 'New Title');
      });

      test('should add new download to existing list', () async {
        // Arrange
        final DownloadItem existing = createTestDownload(id: 'existing_id');
        final DownloadItem newDownload = createTestDownload(id: 'new_id');
        when(
          mockPrefs.getStringList('downloads'),
        ).thenAnswer((_) async => [jsonEncode(existing.toJson())]);
        when(mockPrefs.setStringList(any, any)).thenAnswer((_) async {});

        // Act
        await dataSource.addDownload(newDownload);

        // Assert
        final List<dynamic> captured = verify(
          mockPrefs.setStringList('downloads', captureAny),
        ).captured;
        final savedList = captured.first as List<String>;
        expect(savedList.length, 2);
      });
    });

    group('addDownloads', () {
      test('should do nothing when list is empty', () async {
        // Arrange
        when(mockPrefs.getStringList('downloads')).thenAnswer((_) async => []);

        // Act
        await dataSource.addDownloads([]);

        // Assert
        verifyNever(mockPrefs.setStringList(any, any));
      });

      test('should add multiple new downloads to empty list', () async {
        // Arrange
        final List<DownloadItem> items = [
          createTestDownload(id: 'id1'),
          createTestDownload(id: 'id2'),
        ];
        when(mockPrefs.getStringList('downloads')).thenAnswer((_) async => []);
        when(mockPrefs.setStringList(any, any)).thenAnswer((_) async {});

        // Act
        await dataSource.addDownloads(items);

        // Assert
        final List<dynamic> captured = verify(
          mockPrefs.setStringList('downloads', captureAny),
        ).captured;
        final savedList = captured.first as List<String>;
        expect(savedList.length, 2);
      });

      test('should update existing and add new downloads', () async {
        // Arrange
        final DownloadItem existing = createTestDownload(
          id: 'existing',
          title: 'Old',
        );
        final List<DownloadItem> items = [
          createTestDownload(id: 'existing', title: 'New'),
          createTestDownload(id: 'new'),
        ];
        when(
          mockPrefs.getStringList('downloads'),
        ).thenAnswer((_) async => [jsonEncode(existing.toJson())]);
        when(mockPrefs.setStringList(any, any)).thenAnswer((_) async {});

        // Act
        await dataSource.addDownloads(items);

        // Assert
        final List<dynamic> captured = verify(
          mockPrefs.setStringList('downloads', captureAny),
        ).captured;
        final savedList = captured.first as List<String>;
        expect(savedList.length, 2);

        final List<DownloadItem> decodedList = savedList
            .map((e) => DownloadItem.fromJson(jsonDecode(e)))
            .toList();
        expect(decodedList.firstWhere((e) => e.id == 'existing').title, 'New');
        expect(decodedList.any((e) => e.id == 'new'), isTrue);
      });
    });

    group('updateDownloads', () {
      test('should do nothing when list is empty', () async {
        // Arrange
        when(mockPrefs.getStringList('downloads')).thenAnswer((_) async => []);

        // Act
        await dataSource.updateDownloads([]);

        // Assert
        verifyNever(mockPrefs.setStringList(any, any));
      });

      test('should update matching items and save', () async {
        // Arrange
        final DownloadItem item1 = createTestDownload(id: 'id1', progress: 0.1);
        final DownloadItem item2 = createTestDownload(id: 'id2', progress: 0.2);
        final List<DownloadItem> updates = [createTestDownload(id: 'id1')];

        when(mockPrefs.getStringList('downloads')).thenAnswer(
          (_) async => [jsonEncode(item1.toJson()), jsonEncode(item2.toJson())],
        );
        when(mockPrefs.setStringList(any, any)).thenAnswer((_) async {});

        // Act
        await dataSource.updateDownloads(updates);

        // Assert
        final List<dynamic> captured = verify(
          mockPrefs.setStringList('downloads', captureAny),
        ).captured;
        final savedList = captured.first as List<String>;
        final List<DownloadItem> decodedList = savedList
            .map((e) => DownloadItem.fromJson(jsonDecode(e)))
            .toList();

        expect(decodedList.firstWhere((e) => e.id == 'id1').progress, 1.0);
        expect(decodedList.firstWhere((e) => e.id == 'id2').progress, 0.2);
      });

      test('should not save if no items match', () async {
        // Arrange
        final DownloadItem item = createTestDownload(id: 'id1');
        final List<DownloadItem> updates = [createTestDownload(id: 'unknown')];

        when(
          mockPrefs.getStringList('downloads'),
        ).thenAnswer((_) async => [jsonEncode(item.toJson())]);

        // Act
        await dataSource.updateDownloads(updates);

        // Assert
        verifyNever(mockPrefs.setStringList(any, any));
      });
    });

    group('updateDownload', () {
      test('should update existing download', () async {
        // Arrange
        final DownloadItem existing = createTestDownload(progress: 0.5);
        final DownloadItem updated = createTestDownload();
        when(
          mockPrefs.getStringList('downloads'),
        ).thenAnswer((_) async => [jsonEncode(existing.toJson())]);
        when(mockPrefs.setStringList(any, any)).thenAnswer((_) async {});

        // Act
        await dataSource.updateDownload(updated);

        // Assert
        final List<dynamic> captured = verify(
          mockPrefs.setStringList('downloads', captureAny),
        ).captured;
        final savedList = captured.first as List<String>;
        final decoded = jsonDecode(savedList[0]) as Map<String, dynamic>;
        expect(decoded['progress'], 1.0);
      });

      test('should not save if download not found', () async {
        // Arrange
        final DownloadItem download = createTestDownload(id: 'non_existent_id');
        when(mockPrefs.getStringList('downloads')).thenAnswer((_) async => []);

        // Act
        await dataSource.updateDownload(download);

        // Assert
        verifyNever(mockPrefs.setStringList(any, any));
      });
    });

    group('deleteDownload', () {
      test('should remove download by id', () async {
        // Arrange
        final DownloadItem download1 = createTestDownload(id: 'id1');
        final DownloadItem download2 = createTestDownload(id: 'id2');
        when(mockPrefs.getStringList('downloads')).thenAnswer(
          (_) async => [
            jsonEncode(download1.toJson()),
            jsonEncode(download2.toJson()),
          ],
        );
        when(mockPrefs.setStringList(any, any)).thenAnswer((_) async {});

        // Act
        await dataSource.deleteDownload('id1');

        // Assert
        final List<dynamic> captured = verify(
          mockPrefs.setStringList('downloads', captureAny),
        ).captured;
        final savedList = captured.first as List<String>;
        expect(savedList.length, 1);

        final decoded = jsonDecode(savedList[0]) as Map<String, dynamic>;
        expect(decoded['id'], 'id2');
      });

      test('should handle deleting non-existent download', () async {
        // Arrange
        when(mockPrefs.getStringList('downloads')).thenAnswer((_) async => []);
        when(mockPrefs.setStringList(any, any)).thenAnswer((_) async {});

        // Act
        await dataSource.deleteDownload('non_existent');

        // Assert - should still save (empty list)
        verify(mockPrefs.setStringList('downloads', [])).called(1);
      });
    });

    group('clearAllDownloads', () {
      test('should remove downloads key from preferences', () async {
        // Arrange
        when(mockPrefs.remove('downloads')).thenAnswer((_) async {});

        // Act
        await dataSource.clearAllDownloads();

        // Assert
        verify(mockPrefs.remove('downloads')).called(1);
      });
    });

    group('isFileExists', () {
      test('should return true when file exists', () async {
        // Arrange
        final Directory tempDir = Directory.systemTemp.createTempSync();
        final testFile = File('${tempDir.path}/test_file.mp3');
        await testFile.writeAsBytes([0, 1, 2, 3]);

        // Act
        final bool result = dataSource.isFileExists(testFile.path);

        // Assert
        expect(result, isTrue);

        // Cleanup
        await testFile.delete();
        await tempDir.delete();
      });

      test('should return false when file does not exist', () async {
        // Act
        final bool result = dataSource.isFileExists('/non/existent/path.mp3');

        // Assert
        expect(result, isFalse);
      });
    });

    group('deleteFile', () {
      test('should delete file when it exists', () async {
        // Arrange
        final Directory tempDir = Directory.systemTemp.createTempSync();
        final testFile = File('${tempDir.path}/to_delete.mp3');
        await testFile.writeAsBytes([0, 1, 2, 3]);
        expect(testFile.existsSync(), isTrue);

        // Act
        await dataSource.deleteFile(testFile.path);

        // Assert
        expect(testFile.existsSync(), isFalse);

        // Cleanup
        await tempDir.delete();
      });

      test('should do nothing when file does not exist', () async {
        // Act - should not throw
        await dataSource.deleteFile('/non/existent/file.mp3');

        // Assert - test passes if no exception thrown
      });
    });

    group('getDownloadsDirectory', () {
      test('should get external storage directory (covers line 133)', () async {
        // Arrange - Setup mock that returns external storage path
        final Directory tempExternal = Directory.systemTemp.createTempSync(
          'external',
        );
        PathProviderPlatform.instance = _FakePathProvider(
          externalStoragePath: tempExternal.path,
          applicationDocumentsPath: Directory.systemTemp.path,
        );

        // Act
        final String result = await dataSource.getDownloadsDirectory();

        // Assert - Should end with downloads subdirectory
        expect(result, endsWith('downloads'));
        expect(Directory(result).existsSync(), isTrue);

        // Cleanup
        if (tempExternal.existsSync()) {
          await tempExternal.delete(recursive: true);
        }
      });

      test(
        'should fallback to application documents when external storage is null',
        () async {
          // Arrange - Mock scenario without external storage (e.g., iOS)
          final Directory appDocsPath = Directory.systemTemp.createTempSync(
            'app_docs',
          );
          PathProviderPlatform.instance = _FakePathProvider(
            externalStoragePath: null,
            applicationDocumentsPath: appDocsPath.path,
          );

          // Act
          final String result = await dataSource.getDownloadsDirectory();

          // Assert - Should use application documents path
          expect(result, contains(appDocsPath.path));
          expect(result, endsWith('downloads'));
          expect(Directory(result).existsSync(), isTrue);

          // Cleanup
          if (appDocsPath.existsSync()) {
            await appDocsPath.delete(recursive: true);
          }
        },
      );

      test(
        'should create downloads directory if it does not exist (line 141)',
        () async {
          // Arrange - Use a completely fresh temp directory
          final Directory tempBase = Directory.systemTemp.createTempSync(
            'test_create',
          );
          final downloadsPath = '${tempBase.path}/downloads';

          PathProviderPlatform.instance = _FakePathProvider(
            externalStoragePath: null,
            applicationDocumentsPath: tempBase.path,
          );

          // Ensure downloads directory doesn't exist
          final downloadsDir = Directory(downloadsPath);
          if (downloadsDir.existsSync()) {
            await downloadsDir.delete(recursive: true);
          }

          // Verify it doesn't exist before calling
          expect(
            downloadsDir.existsSync(),
            isFalse,
            reason: 'Downloads directory should not exist before test',
          );

          // Act - This should trigger line 141 (directory creation)
          final String result = await dataSource.getDownloadsDirectory();

          // Assert - Directory should now be created
          expect(result, equals(downloadsPath));
          expect(
            Directory(result).existsSync(),
            isTrue,
            reason: 'Directory should exist after getDownloadsDirectory()',
          );

          // Cleanup
          if (tempBase.existsSync()) {
            await tempBase.delete(recursive: true);
          }
        },
      );

      test('should return existing directory if it already exists', () async {
        // Arrange - Pre-create the downloads directory
        final Directory tempBase = Directory.systemTemp.createTempSync(
          'test_existing',
        );
        final downloadsPath = '${tempBase.path}/downloads';
        final downloadsDir = Directory(downloadsPath);
        await downloadsDir.create(recursive: true);

        PathProviderPlatform.instance = _FakePathProvider(
          externalStoragePath: null,
          applicationDocumentsPath: tempBase.path,
        );

        // Verify it exists before calling
        expect(
          downloadsDir.existsSync(),
          isTrue,
          reason: 'Downloads directory should exist before test',
        );

        // Act
        final String result = await dataSource.getDownloadsDirectory();

        // Assert - Should return the same path
        expect(result, equals(downloadsPath));
        expect(Directory(result).existsSync(), isTrue);

        // Cleanup
        if (tempBase.existsSync()) {
          await tempBase.delete(recursive: true);
        }
      });
    });
  });
}

/// Fake PathProviderPlatform for testing
class _FakePathProvider extends PathProviderPlatform {
  _FakePathProvider({
    required this.externalStoragePath,
    required this.applicationDocumentsPath,
  });

  final String? externalStoragePath;
  final String applicationDocumentsPath;

  @override
  Future<String?> getExternalStoragePath() async {
    return externalStoragePath;
  }

  @override
  Future<String?> getApplicationDocumentsPath() async {
    return applicationDocumentsPath;
  }
}
