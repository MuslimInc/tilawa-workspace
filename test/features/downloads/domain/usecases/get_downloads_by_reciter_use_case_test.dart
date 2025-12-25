import 'package:dartz_plus/dartz_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:tilawa/core/errors/failures.dart';
import 'package:tilawa/features/downloads/domain/entities/download_item.dart';
import 'package:tilawa/features/downloads/domain/repositories/downloads_repository.dart';
import 'package:tilawa/features/downloads/domain/usecases/get_downloads_by_reciter_use_case.dart';

import 'get_downloads_by_reciter_use_case_test.mocks.dart';

@GenerateMocks([DownloadsRepository])
void main() {
  late GetDownloadsByReciterUseCase useCase;
  late MockDownloadsRepository mockRepository;

  setUp(() {
    mockRepository = MockDownloadsRepository();
    useCase = GetDownloadsByReciterUseCase(mockRepository);
  });

  group('GetDownloadsByReciterUseCase', () {
    group('call', () {
      test(
        'should return Right(Map) when repository returns downloads',
        () async {
          // Arrange
          final testDownloads = <String, Map<String, List<DownloadItem>>>{
            'Abdul Rahman Al-Sudais': {
              'Default': [
                DownloadItem(
                  id: '001_Abdul_Rahman_Al-Sudais',
                  title: 'Al-Fatiha',
                  url: 'https://example.com/audio.mp3',
                  filePath: '/path/to/file.mp3',
                  reciterName: 'Abdul Rahman Al-Sudais',
                  status: DownloadStatus.completed,
                  progress: 1.0,
                  fileSize: 1024000,
                  downloadedSize: 1024000,
                  createdAt: DateTime.now(),
                ),
              ],
            },
            'Mishary Rashid Alafasy': {
              'Default': [
                DownloadItem(
                  id: '002_Mishary_Rashid_Alafasy',
                  title: 'Al-Baqarah',
                  url: 'https://example.com/audio2.mp3',
                  filePath: '/path/to/file2.mp3',
                  reciterName: 'Mishary Rashid Alafasy',
                  status: DownloadStatus.completed,
                  progress: 1.0,
                  fileSize: 2048000,
                  downloadedSize: 2048000,
                  createdAt: DateTime.now(),
                ),
              ],
            },
          };

          when(
            mockRepository.getDownloadsByReciter(),
          ).thenAnswer((_) async => testDownloads);

          // Act
          final Either<Failure, Map<String, Map<String, List<DownloadItem>>>>
          result = await useCase();

          // Assert
          result.fold(
            (_) => fail('Expected Right but got Left'),
            (downloads) => expect(downloads, testDownloads),
          );
          verify(mockRepository.getDownloadsByReciter()).called(1);
          verifyNoMoreInteractions(mockRepository);
        },
      );

      test(
        'should return Right(empty Map) when repository returns empty map',
        () async {
          // Arrange
          const testDownloads = <String, Map<String, List<DownloadItem>>>{};

          when(
            mockRepository.getDownloadsByReciter(),
          ).thenAnswer((_) async => testDownloads);

          // Act
          final Either<Failure, Map<String, Map<String, List<DownloadItem>>>>
          result = await useCase();

          // Assert
          result.fold(
            (_) => fail('Expected Right but got Left'),
            (downloads) => expect(downloads, testDownloads),
          );
          verify(mockRepository.getDownloadsByReciter()).called(1);
          verifyNoMoreInteractions(mockRepository);
        },
      );

      test(
        'should return Left(AudioFailure) when repository throws exception',
        () async {
          // Arrange
          const errorMessage = 'Database connection failed';
          when(
            mockRepository.getDownloadsByReciter(),
          ).thenThrow(Exception(errorMessage));

          // Act
          final Either<Failure, Map<String, Map<String, List<DownloadItem>>>>
          result = await useCase();

          // Assert
          result.fold((failure) {
            expect(failure, isA<AudioFailure>());
            expect(failure.message, 'Exception: $errorMessage');
          }, (_) => fail('Expected Left but got Right'));
          verify(mockRepository.getDownloadsByReciter()).called(1);
          verifyNoMoreInteractions(mockRepository);
        },
      );

      test(
        'should return Left(AudioFailure) when repository throws generic exception',
        () async {
          // Arrange
          when(
            mockRepository.getDownloadsByReciter(),
          ).thenThrow('Generic error');

          // Act
          final Either<Failure, Map<String, Map<String, List<DownloadItem>>>>
          result = await useCase();

          // Assert
          result.fold((failure) {
            expect(failure, isA<AudioFailure>());
            expect(failure.message, 'Generic error');
          }, (_) => fail('Expected Left but got Right'));
          verify(mockRepository.getDownloadsByReciter()).called(1);
          verifyNoMoreInteractions(mockRepository);
        },
      );

      test('should handle downloads with different statuses', () async {
        // Arrange
        final testDownloads = <String, Map<String, List<DownloadItem>>>{
          'Test Reciter': {
            'Default': [
              DownloadItem(
                id: '001_Test_Reciter',
                title: 'Al-Fatiha',
                url: 'https://example.com/audio.mp3',
                filePath: '/path/to/file.mp3',
                reciterName: 'Test Reciter',
                status: DownloadStatus.pending,
                progress: 0.0,
                fileSize: 1024000,
                downloadedSize: 0,
                createdAt: DateTime.now(),
              ),
              DownloadItem(
                id: '002_Test_Reciter',
                title: 'Al-Baqarah',
                url: 'https://example.com/audio2.mp3',
                filePath: '/path/to/file2.mp3',
                reciterName: 'Test Reciter',
                status: DownloadStatus.downloading,
                progress: 0.5,
                fileSize: 2048000,
                downloadedSize: 1024000,
                createdAt: DateTime.now(),
              ),
              DownloadItem(
                id: '003_Test_Reciter',
                title: 'Ali Imran',
                url: 'https://example.com/audio3.mp3',
                filePath: '/path/to/file3.mp3',
                reciterName: 'Test Reciter',
                status: DownloadStatus.failed,
                progress: 0.3,
                fileSize: 1536000,
                downloadedSize: 460800,
                createdAt: DateTime.now(),
              ),
              DownloadItem(
                id: '004_Test_Reciter',
                title: 'An-Nisa',
                url: 'https://example.com/audio4.mp3',
                filePath: '/path/to/file4.mp3',
                reciterName: 'Test Reciter',
                status: DownloadStatus.paused,
                progress: 0.7,
                fileSize: 1792000,
                downloadedSize: 1254400,
                createdAt: DateTime.now(),
              ),
              DownloadItem(
                id: '005_Test_Reciter',
                title: 'Al-Maidah',
                url: 'https://example.com/audio5.mp3',
                filePath: '/path/to/file5.mp3',
                reciterName: 'Test Reciter',
                status: DownloadStatus.cancelled,
                progress: 0.2,
                fileSize: 1280000,
                downloadedSize: 256000,
                createdAt: DateTime.now(),
              ),
            ],
          },
        };

        when(
          mockRepository.getDownloadsByReciter(),
        ).thenAnswer((_) async => testDownloads);

        // Act
        final Either<Failure, Map<String, Map<String, List<DownloadItem>>>>
        result = await useCase();

        // Assert
        result.fold(
          (_) => fail('Expected Right but got Left'),
          (downloads) => expect(downloads, testDownloads),
        );
        verify(mockRepository.getDownloadsByReciter()).called(1);
        verifyNoMoreInteractions(mockRepository);
      });

      test('should handle large number of downloads', () async {
        // Arrange
        final testDownloads = <String, Map<String, List<DownloadItem>>>{};

        // Create 100 downloads for 10 different reciters
        for (var i = 0; i < 10; i++) {
          final reciterName = 'Reciter $i';
          final downloads = <DownloadItem>[];

          for (var j = 1; j <= 10; j++) {
            downloads.add(
              DownloadItem(
                id: '${j.toString().padLeft(3, '0')}_Reciter_$i',
                title: 'Surah $j',
                url: 'https://example.com/audio$j.mp3',
                filePath: '/path/to/file$j.mp3',
                reciterName: reciterName,
                status: DownloadStatus.completed,
                progress: 1.0,
                fileSize: 1024000 * j,
                downloadedSize: 1024000 * j,
                createdAt: DateTime.now(),
              ),
            );
          }

          testDownloads[reciterName] = {'Default': downloads};
        }

        when(
          mockRepository.getDownloadsByReciter(),
        ).thenAnswer((_) async => testDownloads);

        // Act
        final Either<Failure, Map<String, Map<String, List<DownloadItem>>>>
        result = await useCase();

        // Assert
        result.fold(
          (_) => fail('Expected Right but got Left'),
          (downloads) => expect(downloads, testDownloads),
        );
        expect(result.getOrElse(() => {}).length, 10);
        expect(
          result
              .getOrElse(() => {})
              .values
              .expand((map) => map.values)
              .expand((list) => list)
              .length,
          100,
        );
        verify(mockRepository.getDownloadsByReciter()).called(1);
        verifyNoMoreInteractions(mockRepository);
      });

      test('should handle null values in download items gracefully', () async {
        // Arrange
        final testDownloads = <String, Map<String, List<DownloadItem>>>{
          'Test Reciter': {
            'Default': [
              DownloadItem(
                id: '001_Test_Reciter',
                title: 'Al-Fatiha',
                url: 'https://example.com/audio.mp3',
                filePath: '/path/to/file.mp3',
                reciterName: 'Test Reciter',
                status: DownloadStatus.completed,
                progress: 1.0,
                fileSize: 1024000,
                downloadedSize: 1024000,
                createdAt: DateTime.now(),
              ),
            ],
          },
        };

        when(
          mockRepository.getDownloadsByReciter(),
        ).thenAnswer((_) async => testDownloads);

        // Act
        final Either<Failure, Map<String, Map<String, List<DownloadItem>>>>
        result = await useCase();

        // Assert
        result.fold(
          (_) => fail('Expected Right but got Left'),
          (downloads) => expect(downloads, testDownloads),
        );
        verify(mockRepository.getDownloadsByReciter()).called(1);
        verifyNoMoreInteractions(mockRepository);
      });
    });
  });
}
