import 'package:dartz_plus/dartz_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:tilawa_core/entities/reciter_entity.dart';
import 'package:tilawa_core/errors/failures.dart';
import 'package:tilawa/features/downloads/domain/entities/download_item.dart';
import 'package:tilawa/features/downloads/domain/usecases/cancel_downloads_for_reciter_use_case.dart';

import '../../helpers/mock_helper.mocks.dart';

void main() {
  late CancelDownloadsForReciterUseCase useCase;
  late MockDownloadsRepository mockRepository;
  late MockRecitersRepository mockRecitersRepository;

  void provideDummies() {
    provideDummy<Either<Failure, List<ReciterEntity>>>(const Right([]));
  }

  setUp(() {
    provideDummies();
    mockRepository = MockDownloadsRepository();
    mockRecitersRepository = MockRecitersRepository();
    useCase = CancelDownloadsForReciterUseCase(
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

  final downloadToCancel = DownloadItem(
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

  group('CancelDownloadsForReciterUseCase', () {
    test('should cancel only active downloads for specific reciter', () async {
      // Arrange
      when(mockRepository.getAllDownloads()).thenAnswer(
        (_) async => [
          downloadToCancel,
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

      // Act
      final Either<Failure, void> result = await useCase(testReciterName);

      // Assert
      expect(result, isA<Right>());

      // Should verify reciter resolution
      verify(mockRecitersRepository.getReciters()).called(1);

      // Should cancel the active download for target reciter
      verify(mockRepository.cancelDownload(downloadToCancel.id)).called(1);

      // Should NOT cancel completed download or other reciter's download
      verifyNever(mockRepository.cancelDownload(downloadCompleted.id));
      verifyNever(mockRepository.cancelDownload(otherReciterDownload.id));
    });

    test('should return ServerFailure when getAllDownloads fails', () async {
      // Arrange
      const errorMessage = 'DB Error';
      when(mockRepository.getAllDownloads()).thenThrow(Exception(errorMessage));

      // Act
      final Either<Failure, void> result = await useCase(testReciterName);

      // Assert
      expect(result, isA<Left>());
      result.fold((failure) {
        expect(failure, isA<ServerFailure>());
        expect(failure.message, contains(errorMessage));
      }, (_) => fail('Should return Left'));
    });

    test(
      'should fallback to name matching if reciter resolution fails',
      () async {
        // Arrange
        when(
          mockRepository.getAllDownloads(),
        ).thenAnswer((_) async => [downloadToCancel]);
        // Simulate failure in getting reciters
        when(
          mockRecitersRepository.getReciters(),
        ).thenAnswer((_) async => const Left(ServerFailure('API Error')));
        when(
          mockRepository.cancelDownload(any),
        ).thenAnswer((_) async => Future.value());

        // Act
        final Either<Failure, void> result = await useCase(testReciterName);

        // Assert
        expect(result, isA<Right>());
        verify(mockRepository.cancelDownload(downloadToCancel.id)).called(1);
      },
    );
  });
}
