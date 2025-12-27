import 'package:dartz_plus/dartz_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:tilawa/core/entities/reciter_entity.dart';
import 'package:tilawa/core/errors/failures.dart';
import 'package:tilawa/features/downloads/domain/entities/download_item.dart';
import 'package:tilawa/features/downloads/domain/usecases/delete_reciter_downloads_use_case.dart';

import '../../helpers/mock_helper.mocks.dart';

void main() {
  late DeleteReciterDownloadsUseCase useCase;
  late MockDownloadsRepository mockRepository;
  late MockRecitersRepository mockRecitersRepository;

  void provideDummies() {
    provideDummy<Either<Failure, List<ReciterEntity>>>(const Right([]));
  }

  setUp(() {
    provideDummies();
    mockRepository = MockDownloadsRepository();
    mockRecitersRepository = MockRecitersRepository();
    useCase = DeleteReciterDownloadsUseCase(
      mockRepository,
      mockRecitersRepository,
    );
  });

  const testReciterName = 'Abdul Rahman Al-Sudais';
  const testReciterId = 1;

  const testReciter = ReciterEntity(
    id: testReciterId,
    name: testReciterName,
    letter: 'A',
    date: '2024-01-01',
    moshaf: [],
  );

  final downloadActive = DownloadItem(
    id: '1',
    reciterName: testReciterName,
    reciterId: testReciterId,
    status: DownloadStatus.downloading,
    title: 'Surah 1',
    url: 'url1',
    progress: 0.5,
    fileSize: 100,
    downloadedSize: 50,
    createdAt: DateTime.now(),
    filePath: "/downloads/$testReciterName/Rewayat Hafs A'n Assem/001.mp3",
  );

  final downloadCompleted = DownloadItem(
    id: '2',
    reciterName: testReciterName,
    reciterId: testReciterId,
    status: DownloadStatus.completed,
    title: 'Surah 2',
    url: 'url2',
    progress: 1.0,
    fileSize: 100,
    downloadedSize: 100,
    createdAt: DateTime.now(),
    filePath: "/downloads/$testReciterName/Rewayat Hafs A'n Assem/002.mp3",
  );

  final otherReciterDownload = DownloadItem(
    id: '3',
    reciterName: 'Other Reciter',
    reciterId: 2,
    status: DownloadStatus.downloading,
    title: 'Surah 3',
    url: 'url3',
    progress: 0.5,
    fileSize: 100,
    downloadedSize: 50,
    createdAt: DateTime.now(),
    filePath: "/downloads/Other Reciter/Rewayat Hafs A'n Assem/003.mp3",
  );

  group('DeleteReciterDownloadsUseCase', () {
    test(
      'should delete all downloads for reciter and cancel active ones',
      () async {
        // Arrange
        when(mockRepository.getAllDownloads()).thenAnswer(
          (_) async => [
            downloadActive,
            downloadCompleted,
            otherReciterDownload,
          ],
        );
        when(
          mockRecitersRepository.getReciters(),
        ).thenAnswer((_) async => const Right([testReciter]));
        when(
          mockRepository.cancelDownload(any),
        ).thenAnswer((_) async => Future.value());
        when(
          mockRepository.deleteDownload(any),
        ).thenAnswer((_) async => Future.value());

        // Act
        final Either<Failure, void> result = await useCase(testReciterName);

        // Assert
        expect(result, isA<Right>());

        // Should cancel active download
        verify(mockRepository.cancelDownload(downloadActive.id)).called(1);

        // Should delete both active and completed downloads for target reciter
        verify(mockRepository.deleteDownload(downloadActive.id)).called(1);
        verify(mockRepository.deleteDownload(downloadCompleted.id)).called(1);

        // Should NOT touch other reciter's download
        verifyNever(mockRepository.deleteDownload(otherReciterDownload.id));
      },
    );

    test('should return AudioFailure when getAllDownloads fails', () async {
      // Arrange
      const errorMessage = 'DB Error';
      when(mockRepository.getAllDownloads()).thenThrow(Exception(errorMessage));

      // Act
      final Either<Failure, void> result = await useCase(testReciterName);

      // Assert
      expect(result, isA<Left>());
      result.fold((failure) {
        expect(failure, isA<AudioFailure>());
        expect(failure.message, contains(errorMessage));
      }, (_) => fail('Should return Left'));
    });

    test(
      'should fallback to name matching if reciter resolution fails',
      () async {
        // Arrange
        when(
          mockRepository.getAllDownloads(),
        ).thenAnswer((_) async => [downloadCompleted]);
        when(
          mockRecitersRepository.getReciters(),
        ).thenAnswer((_) async => const Left(ServerFailure('API Error')));
        when(
          mockRepository.deleteDownload(any),
        ).thenAnswer((_) async => Future.value());

        // Act
        final Either<Failure, void> result = await useCase(testReciterName);

        // Assert
        expect(result, isA<Right>());
        verify(mockRepository.deleteDownload(downloadCompleted.id)).called(1);
      },
    );
  });
}
