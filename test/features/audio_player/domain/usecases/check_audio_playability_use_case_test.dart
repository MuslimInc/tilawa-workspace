import 'package:dartz_plus/dartz_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tilawa/core/entities/audio.dart';
import 'package:tilawa/core/errors/failures.dart';
import 'package:tilawa/core/network/network_info.dart';
import 'package:tilawa/features/audio_player/domain/usecases/check_audio_playability_use_case.dart';
import 'package:tilawa/features/downloads/domain/entities/download_item.dart';
import 'package:tilawa/features/downloads/domain/repositories/downloads_repository.dart';

class MockNetworkInfo extends Mock implements NetworkInfo {}

class MockDownloadsRepository extends Mock implements DownloadsRepository {}

void main() {
  late CheckAudioPlayabilityUseCase useCase;
  late MockNetworkInfo mockNetworkInfo;
  late MockDownloadsRepository mockDownloadsRepository;

  const tAudio = AudioEntity(
    id: '001',
    title: 'Al-Fatihah',
    url: 'https://example.com/audio.mp3',
    duration: Duration.zero,
  );

  setUp(() {
    mockNetworkInfo = MockNetworkInfo();
    mockDownloadsRepository = MockDownloadsRepository();
    useCase = CheckAudioPlayabilityUseCase(
      mockNetworkInfo,
      mockDownloadsRepository,
    );
  });

  group('CheckAudioPlayabilityUseCase', () {
    test('should return Right when user is online', () async {
      // arrange
      when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => true);

      // act
      final Either<Failure, void> result = await useCase(tAudio);

      // assert
      expect(result, const Right<Failure, void>(null));
      verify(() => mockNetworkInfo.isConnected).called(1);
      verifyNever(() => mockDownloadsRepository.getDownloadItem(any()));
    });

    test(
      'should return Right when offline but audio is downloaded and completed',
      () async {
        // arrange
        when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => false);

        final tDownloadItem = DownloadItem(
          id: tAudio.id,
          title: tAudio.title,
          url: tAudio.url,
          filePath: '/path/to/file.mp3',
          reciterName: 'Test Reciter',
          status: DownloadStatus.completed,
          progress: 1.0,
          fileSize: 1024,
          downloadedSize: 1024,
          createdAt: DateTime.now(),
        );

        when(
          () => mockDownloadsRepository.getDownloadItem(tAudio.id),
        ).thenAnswer((_) async => tDownloadItem);
        when(
          () => mockDownloadsRepository.validateDownloadedFile(tDownloadItem),
        ).thenAnswer((_) async => true);

        // act
        final Either<Failure, void> result = await useCase(tAudio);

        // assert
        expect(result, const Right<Failure, void>(null));
        verify(() => mockNetworkInfo.isConnected).called(1);
        verify(
          () => mockDownloadsRepository.getDownloadItem(tAudio.id),
        ).called(1);
        verify(
          () => mockDownloadsRepository.validateDownloadedFile(tDownloadItem),
        ).called(1);
      },
    );

    test(
      'should return Left(OfflinePlaybackFailure) when offline and not downloaded',
      () async {
        // arrange
        when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => false);
        when(
          () => mockDownloadsRepository.getDownloadItem(tAudio.id),
        ).thenAnswer((_) async => null);

        // act
        final Either<Failure, void> result = await useCase(tAudio);

        // assert
        expect(result, isA<Left>());
        result.fold(
          (failure) => expect(failure, isA<OfflinePlaybackFailure>()),
          (_) => fail('Should return failure'),
        );
      },
    );

    test(
      'should return Left(OfflinePlaybackFailure) when offline and download is incomplete',
      () async {
        // arrange
        when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => false);

        final tDownloadItem = DownloadItem(
          id: tAudio.id,
          title: tAudio.title,
          url: tAudio.url,
          filePath: '/path/to/file.mp3',
          reciterName: 'Test Reciter',
          status: DownloadStatus.downloading, // Not completed
          progress: 0.5,
          fileSize: 1024,
          downloadedSize: 512,
          createdAt: DateTime.now(),
        );

        when(
          () => mockDownloadsRepository.getDownloadItem(tAudio.id),
        ).thenAnswer((_) async => tDownloadItem);

        // act
        final Either<Failure, void> result = await useCase(tAudio);

        // assert
        expect(result, isA<Left>());
        result.fold(
          (failure) => expect(failure, isA<OfflinePlaybackFailure>()),
          (_) => fail('Should return failure'),
        );
      },
    );

    test(
      'should return Left(OfflinePlaybackFailure) when file is completed but missing on disk',
      () async {
        // arrange
        when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => false);

        final tDownloadItem = DownloadItem(
          id: tAudio.id,
          title: tAudio.title,
          url: tAudio.url,
          filePath: '/path/to/file.mp3',
          reciterName: 'Test Reciter',
          status: DownloadStatus.completed,
          progress: 1.0,
          fileSize: 1024,
          downloadedSize: 1024,
          createdAt: DateTime.now(),
        );

        when(
          () => mockDownloadsRepository.getDownloadItem(tAudio.id),
        ).thenAnswer((_) async => tDownloadItem);
        when(
          () => mockDownloadsRepository.validateDownloadedFile(tDownloadItem),
        ).thenAnswer((_) async => false); // File missing

        // act
        final Either<Failure, void> result = await useCase(tAudio);

        // assert
        expect(result, isA<Left>());
        result.fold((failure) {
          expect(failure, isA<OfflinePlaybackFailure>());
          expect(failure.message, contains('Downloaded file is missing'));
        }, (_) => fail('Should return failure'));
      },
    );
  });
}
