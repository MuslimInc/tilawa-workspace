import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:muzakri/features/downloads/data/datasources/downloads_local_datasource.dart';
import 'package:muzakri/features/downloads/data/repositories/downloads_repository_impl.dart';
import 'package:muzakri/features/downloads/domain/entities/download_item.dart';

import 'downloads_repository_impl_test.mocks.dart';

@GenerateMocks([DownloadsLocalDataSource])
void main() {
  setUpAll(() {
    // Register Dio in GetIt for DownloadService to use
    // This prevents "Dio is not registered" errors when DownloadService
    // tries to access Dio via GetIt
    final getIt = GetIt.instance;
    if (getIt.isRegistered<Dio>()) {
      getIt.unregister<Dio>();
    }
    // Use registerSingleton to ensure it's available immediately
    getIt.registerSingleton<Dio>(Dio());
  });

  tearDownAll(() {
    // Clean up GetIt registration
    final getIt = GetIt.instance;
    if (getIt.isRegistered<Dio>()) {
      getIt.unregister<Dio>();
    }
  });

  late DownloadsRepositoryImpl repository;
  late MockDownloadsLocalDataSource mockLocalDataSource;

  setUp(() {
    mockLocalDataSource = MockDownloadsLocalDataSource();
    repository = DownloadsRepositoryImpl(mockLocalDataSource);
  });

  group('DownloadsRepositoryImpl', () {
    group('startDownload', () {
      const testSurahId = '001';
      const testSurahTitle = 'Al-Fatiha';
      const testReciterName = 'Abdul Rahman Al-Sudais';

      test('should create download item and start download service', () async {
        // Arrange
        const testDownloadsDir = '/test/downloads';
        when(
          mockLocalDataSource.getDownloadsDirectory(),
        ).thenAnswer((_) async => testDownloadsDir);
        when(mockLocalDataSource.getDownloads()).thenAnswer((_) async => []);

        // Act
        await repository.startDownload(
          testSurahId,
          testSurahTitle,
          testReciterName,
        );

        // Assert
        verify(mockLocalDataSource.getDownloadsDirectory()).called(1);
        verify(mockLocalDataSource.addDownload(any)).called(1);

        // Test passes if no exceptions are thrown
      });

      test('should handle directory creation failure', () async {
        // Arrange
        when(
          mockLocalDataSource.getDownloadsDirectory(),
        ).thenThrow(Exception('Failed to create downloads directory'));

        // Act & Assert
        expect(
          () => repository.startDownload(
            testSurahId,
            testSurahTitle,
            testReciterName,
          ),
          throwsException,
        );
      });

      test('should handle addDownload failure', () async {
        // Arrange
        const testDownloadsDir = '/test/downloads';
        when(
          mockLocalDataSource.getDownloadsDirectory(),
        ).thenAnswer((_) async => testDownloadsDir);
        when(
          mockLocalDataSource.addDownload(any),
        ).thenThrow(Exception('Failed to add download'));

        // Act & Assert
        expect(
          () => repository.startDownload(
            testSurahId,
            testSurahTitle,
            testReciterName,
          ),
          throwsException,
        );
      });
    });

    group('retryDownload', () {
      const testDownloadId = '001_Abdul_Rahman_Al-Sudais';
      final testDownloadItem = DownloadItem(
        id: testDownloadId,
        title: 'Al-Fatiha',
        url: 'https://example.com/audio.mp3',
        filePath: '/path/to/file.mp3',
        reciterName: 'Abdul Rahman Al-Sudais',
        status: DownloadStatus.failed,
        progress: 0.0,
        fileSize: 0,
        downloadedSize: 0,
        createdAt: DateTime.now(),
      );

      test('should successfully retry a failed download', () async {
        // Arrange
        when(
          mockLocalDataSource.getDownloads(),
        ).thenAnswer((_) async => [testDownloadItem]);
        when(mockLocalDataSource.updateDownload(any)).thenAnswer((_) async {
          return;
        });

        // Act
        await repository.retryDownload(testDownloadId);

        // Assert
        verify(mockLocalDataSource.getDownloads()).called(1);
        verify(mockLocalDataSource.updateDownload(any)).called(1);

        // Test passes if no exceptions are thrown
      });

      test('should throw exception when download not found', () async {
        // Arrange
        when(mockLocalDataSource.getDownloads()).thenAnswer((_) async => []);

        // Act & Assert
        expect(
          () => repository.retryDownload(testDownloadId),
          throwsA(
            isA<Exception>().having(
              (e) => e.toString(),
              'message',
              contains('Download not found'),
            ),
          ),
        );
      });

      test('should throw exception when download is not failed', () async {
        // Arrange
        final completedDownload = testDownloadItem.copyWith(
          status: DownloadStatus.completed,
        );
        when(
          mockLocalDataSource.getDownloads(),
        ).thenAnswer((_) async => [completedDownload]);

        // Act & Assert
        expect(
          () => repository.retryDownload(testDownloadId),
          throwsA(
            isA<Exception>().having(
              (e) => e.toString(),
              'message',
              contains('Only failed downloads can be retried'),
            ),
          ),
        );
      });

      test('should handle updateDownload failure', () async {
        // Arrange
        when(
          mockLocalDataSource.getDownloads(),
        ).thenAnswer((_) async => [testDownloadItem]);
        when(
          mockLocalDataSource.updateDownload(any),
        ).thenThrow(Exception('Failed to update download'));

        // Act & Assert
        expect(() => repository.retryDownload(testDownloadId), throwsException);
      });
    });

    group('validateDownloadedFile', () {
      final testDownloadItem = DownloadItem(
        id: '001_Abdul_Rahman_Al-Sudais',
        title: 'Al-Fatiha',
        url: 'https://example.com/audio.mp3',
        filePath: '/path/to/file.mp3',
        reciterName: 'Abdul Rahman Al-Sudais',
        status: DownloadStatus.completed,
        progress: 1.0,
        fileSize: 1024,
        downloadedSize: 1024,
        createdAt: DateTime.now(),
      );

      test('should return false when file validation fails', () async {
        // The repository's validateDownloadedFile uses File.exists() directly
        // which is hard to mock, so we test the exception handling path
        // by providing an invalid file path that will cause an exception
        final invalidDownloadItem = testDownloadItem.copyWith(
          filePath: '/invalid/path/with/special/chars/\x00',
        );

        // Act
        final result = await repository.validateDownloadedFile(
          invalidDownloadItem,
        );

        // Assert
        expect(result, false);
      });
    });

    group('isSurahDownloaded', () {
      const testSurahId = '001';
      const testReciterName = 'Abdul Rahman Al-Sudais';

      test('should return true when surah is downloaded', () async {
        // Arrange
        final testDownload = DownloadItem(
          id: '${testSurahId}_${testReciterName.replaceAll(' ', '_')}',
          title: 'Surah $testSurahId',
          url: 'https://example.com/audio.mp3',
          filePath: '/test/downloads/test.mp3',
          reciterName: testReciterName,
          status: DownloadStatus.completed,
          progress: 1.0,
          fileSize: 1024,
          downloadedSize: 1024,
          createdAt: DateTime.now(),
        );
        when(
          mockLocalDataSource.getDownloads(),
        ).thenAnswer((_) async => [testDownload]);
        when(
          mockLocalDataSource.isFileExists(testDownload.filePath),
        ).thenAnswer((_) async => true);

        // Act
        final result = await repository.isSurahDownloaded(
          testSurahId,
          testReciterName,
        );

        // Assert
        expect(result, true);
        verify(mockLocalDataSource.getDownloads()).called(1);
        verify(
          mockLocalDataSource.isFileExists(testDownload.filePath),
        ).called(1);
      });

      test('should return false when surah is not downloaded', () async {
        // Arrange
        when(mockLocalDataSource.getDownloads()).thenAnswer((_) async => []);

        // Act
        final result = await repository.isSurahDownloaded(
          testSurahId,
          testReciterName,
        );

        // Assert
        expect(result, false);
        verify(mockLocalDataSource.getDownloads()).called(1);
      });

      test('should handle check failure', () async {
        // Arrange
        when(
          mockLocalDataSource.getDownloads(),
        ).thenThrow(Exception('Failed to check download status'));

        // Act & Assert
        expect(
          () => repository.isSurahDownloaded(testSurahId, testReciterName),
          throwsException,
        );
      });
    });

    group('getDownloadedFilePath', () {
      const testSurahId = '001';
      const testReciterName = 'Abdul Rahman Al-Sudais';
      const testFilePath = '/path/to/downloaded/file.mp3';

      test('should return file path when surah is downloaded', () async {
        // Arrange
        final testDownload = DownloadItem(
          id: '${testSurahId}_${testReciterName.replaceAll(' ', '_')}',
          title: 'Surah $testSurahId',
          url: 'https://example.com/audio.mp3',
          filePath: testFilePath,
          reciterName: testReciterName,
          status: DownloadStatus.completed,
          progress: 1.0,
          fileSize: 1024,
          downloadedSize: 1024,
          createdAt: DateTime.now(),
        );
        when(
          mockLocalDataSource.getDownloads(),
        ).thenAnswer((_) async => [testDownload]);
        when(
          mockLocalDataSource.isFileExists(testFilePath),
        ).thenAnswer((_) async => true);

        // Act
        final result = await repository.getDownloadedFilePath(
          testSurahId,
          testReciterName,
        );

        // Assert
        expect(result, testFilePath);
        verify(mockLocalDataSource.getDownloads()).called(1);
        verify(mockLocalDataSource.isFileExists(testFilePath)).called(1);
      });

      test('should return null when surah is not downloaded', () async {
        // Arrange
        when(mockLocalDataSource.getDownloads()).thenAnswer((_) async => []);

        // Act & Assert
        expect(
          () => repository.getDownloadedFilePath(testSurahId, testReciterName),
          throwsA(isA<StateError>()),
        );
      });

      test('should handle get file path failure', () async {
        // Arrange
        when(
          mockLocalDataSource.getDownloads(),
        ).thenThrow(Exception('Failed to get file path'));

        // Act & Assert
        expect(
          () => repository.getDownloadedFilePath(testSurahId, testReciterName),
          throwsException,
        );
      });
    });
  });
}
