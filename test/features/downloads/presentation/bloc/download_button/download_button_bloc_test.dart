import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:dartz_plus/dartz_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:muzakri/core/errors/failures.dart';
import 'package:muzakri/features/downloads/domain/entities/download_item.dart';
import 'package:muzakri/features/downloads/domain/usecases/usecases.dart';
import 'package:muzakri/features/downloads/presentation/bloc/download_button/download_button_bloc.dart';

import 'download_button_bloc_test.mocks.dart';

@GenerateMocks([
  CheckSurahDownloadedUseCase,
  DownloadSurahUseCase,
  CancelDownloadUseCase,
  ObserveDownloadProgressUseCase,
])
void main() {
  setUpAll(() {
    provideDummy<Either<Failure, bool>>(const Right(false));
    provideDummy<Either<Failure, void>>(const Right(null));
  });

  late MockCheckSurahDownloadedUseCase mockCheckSurahDownloaded;
  late MockDownloadSurahUseCase mockDownloadSurah;
  late MockCancelDownloadUseCase mockCancelDownload;
  late MockObserveDownloadProgressUseCase mockObserveDownloadProgress;
  DownloadButtonBloc? downloadButtonBloc;

  const testUrl = 'https://example.com/001.mp3';
  const testReciterName = 'Abdul Rahman Al-Sudais';
  const testReciterId = 1;
  const testSurahTitle = 'Al-Fatiha';

  setUp(() {
    mockCheckSurahDownloaded = MockCheckSurahDownloadedUseCase();
    mockDownloadSurah = MockDownloadSurahUseCase();
    mockCancelDownload = MockCancelDownloadUseCase();
    mockObserveDownloadProgress = MockObserveDownloadProgressUseCase();

    // Default: Check returns false (not downloaded)
    when(
      mockCheckSurahDownloaded.call(
        surahId: anyNamed('surahId'),
        reciterName: anyNamed('reciterName'),
      ),
    ).thenAnswer((_) async => const Right(false));

    // Default: Observe returns empty stream (no active download)
    when(
      mockObserveDownloadProgress.call(any),
    ).thenAnswer((_) => const Stream.empty());

    downloadButtonBloc = DownloadButtonBloc(
      url: testUrl,
      reciterName: testReciterName,
      reciterId: testReciterId,
      checkSurahDownloaded: mockCheckSurahDownloaded,
      downloadSurah: mockDownloadSurah,
      cancelDownload: mockCancelDownload,
      observeDownloadProgress: mockObserveDownloadProgress,
    );
  });

  tearDown(() {
    downloadButtonBloc?.close();
  });

  group('DownloadButtonBloc -', () {
    group('Initialization', () {
      test('initial state is initial()', () {
        expect(downloadButtonBloc!.state, const DownloadButtonState.initial());
      });

      blocTest<DownloadButtonBloc, DownloadButtonState>(
        'emits [readyToDownload] when surah is not downloaded and no stream events',
        build: () => downloadButtonBloc!,
        act: (bloc) => bloc.add(const DownloadButtonEvent.initialize()),
        expect: () => [const DownloadButtonState.readyToDownload()],
        verify: (_) {
          verify(
            mockCheckSurahDownloaded.call(
              surahId: testUrl,
              reciterName: testReciterName,
            ),
          ).called(1);
          verify(mockObserveDownloadProgress.call(testUrl)).called(1);
        },
      );

      blocTest<DownloadButtonBloc, DownloadButtonState>(
        'emits [completed] when surah is already downloaded',
        build: () {
          when(
            mockCheckSurahDownloaded.call(
              surahId: anyNamed('surahId'),
              reciterName: anyNamed('reciterName'),
            ),
          ).thenAnswer((_) async => const Right(true));
          return downloadButtonBloc!;
        },
        act: (bloc) => bloc.add(const DownloadButtonEvent.initialize()),
        expect: () => [const DownloadButtonState.completed()],
      );

      blocTest<DownloadButtonBloc, DownloadButtonState>(
        'emits [downloading] when stream emits downloading item',
        build: () {
          final item = DownloadItem(
            id: testUrl,
            title: testSurahTitle,
            url: testUrl,
            filePath: 'path',
            reciterName: testReciterName,
            reciterId: testReciterId,
            status: DownloadStatus.downloading,
            progress: 0.5,
            fileSize: 100,
            downloadedSize: 50,
            createdAt: DateTime.now(),
          );
          when(
            mockObserveDownloadProgress.call(any),
          ).thenAnswer((_) => Stream.value(item));
          return downloadButtonBloc!;
        },
        act: (bloc) => bloc.add(const DownloadButtonEvent.initialize()),
        expect: () => [
          const DownloadButtonState.readyToDownload(), // Emitted because verify happens async
          const DownloadButtonState.downloading(
            progress: 0.5,
            downloadedBytes: 50,
            totalBytes: 100,
          ),
        ],
      );

      blocTest<DownloadButtonBloc, DownloadButtonState>(
        'emits [downloading] immediately if initialIsDownloading is true',
        build: () {
          // Check returns false but initialIsDownloading is true
          when(
            mockCheckSurahDownloaded.call(
              surahId: anyNamed('surahId'),
              reciterName: anyNamed('reciterName'),
            ),
          ).thenAnswer((_) async => const Right(false));

          return DownloadButtonBloc(
            url: testUrl,
            reciterName: testReciterName,
            reciterId: testReciterId,
            checkSurahDownloaded: mockCheckSurahDownloaded,
            downloadSurah: mockDownloadSurah,
            cancelDownload: mockCancelDownload,
            observeDownloadProgress: mockObserveDownloadProgress,
            initialIsDownloading: true,
            initialProgress: 0.1,
          );
        },
        act: (bloc) => bloc.add(const DownloadButtonEvent.initialize()),
        expect: () => [const DownloadButtonState.downloading(progress: 0.1)],
      );

      blocTest<DownloadButtonBloc, DownloadButtonState>(
        'emits [completed] immediately if initialIsDownloaded is true',
        build: () {
          return DownloadButtonBloc(
            url: testUrl,
            reciterName: testReciterName,
            reciterId: testReciterId,
            checkSurahDownloaded: mockCheckSurahDownloaded,
            downloadSurah: mockDownloadSurah,
            cancelDownload: mockCancelDownload,
            observeDownloadProgress: mockObserveDownloadProgress,
            initialIsDownloaded: true,
          );
        },
        act: (bloc) => bloc.add(const DownloadButtonEvent.initialize()),
        expect: () => [const DownloadButtonState.completed()],
        verify: (_) {
          // verify that checkSurahDownloaded was NOT called
          verifyNever(
            mockCheckSurahDownloaded.call(
              surahId: anyNamed('surahId'),
              reciterName: anyNamed('reciterName'),
            ),
          );
        },
      );
    });

    group('StartDownload Event', () {
      blocTest<DownloadButtonBloc, DownloadButtonState>(
        'emits [pending] and calls downloadSurah',
        build: () {
          when(
            mockDownloadSurah.call(
              surahId: anyNamed('surahId'),
              surahTitle: anyNamed('surahTitle'),
              reciterName: anyNamed('reciterName'),
              reciterId: anyNamed('reciterId'),
            ),
          ).thenAnswer((_) async => const Right(null));
          return downloadButtonBloc!;
        },
        act: (bloc) => bloc.add(
          const DownloadButtonEvent.startDownload(surahTitle: testSurahTitle),
        ),
        expect: () => [const DownloadButtonState.pending()],
        verify: (_) {
          verify(
            mockDownloadSurah.call(
              surahId: testUrl,
              surahTitle: testSurahTitle,
              reciterName: testReciterName,
              reciterId: testReciterId,
            ),
          ).called(1);
          verify(mockObserveDownloadProgress.call(testUrl)).called(1);
        },
      );

      blocTest<DownloadButtonBloc, DownloadButtonState>(
        'emits [failed] when downloadSurah returns failure',
        build: () {
          when(
            mockDownloadSurah.call(
              surahId: anyNamed('surahId'),
              surahTitle: anyNamed('surahTitle'),
              reciterName: anyNamed('reciterName'),
              reciterId: anyNamed('reciterId'),
            ),
          ).thenAnswer((_) async => const Left(AudioFailure('Network error')));
          return downloadButtonBloc!;
        },
        act: (bloc) => bloc.add(
          const DownloadButtonEvent.startDownload(surahTitle: testSurahTitle),
        ),
        expect: () => [
          const DownloadButtonState.pending(),
          const DownloadButtonState.failed(errorMessage: 'Network error'),
        ],
      );
    });

    group('Cancel Event', () {
      blocTest<DownloadButtonBloc, DownloadButtonState>(
        'emits [cancelled] when cancelDownload succeeds',
        build: () {
          when(
            mockCancelDownload.call(any),
          ).thenAnswer((_) async => const Right(null));
          return downloadButtonBloc!;
        },
        act: (bloc) => bloc.add(const DownloadButtonEvent.cancel()),
        expect: () => [const DownloadButtonState.cancelled()],
        verify: (_) {
          verify(mockCancelDownload.call(testUrl)).called(1);
        },
      );

      blocTest<DownloadButtonBloc, DownloadButtonState>(
        'emits [failed] when cancelDownload fails',
        build: () {
          when(
            mockCancelDownload.call(any),
          ).thenAnswer((_) async => const Left(AudioFailure('Cancel failed')));
          return downloadButtonBloc!;
        },
        act: (bloc) => bloc.add(const DownloadButtonEvent.cancel()),
        expect: () => [
          const DownloadButtonState.failed(errorMessage: 'Failed to cancel'),
        ],
      );
    });

    group('State Updates from Stream', () {
      test('updates state based on stream events', () async {
        final controller = StreamController<DownloadItem>();
        when(
          mockObserveDownloadProgress.call(any),
        ).thenAnswer((_) => controller.stream);

        final bloc = DownloadButtonBloc(
          url: testUrl,
          reciterName: testReciterName,
          reciterId: testReciterId,
          checkSurahDownloaded: mockCheckSurahDownloaded,
          downloadSurah: mockDownloadSurah,
          cancelDownload: mockCancelDownload,
          observeDownloadProgress: mockObserveDownloadProgress,
        );

        bloc.add(const DownloadButtonEvent.initialize());
        await expectLater(
          bloc.stream,
          emitsThrough(const DownloadButtonState.readyToDownload()),
        );

        // Emit downloading
        controller.add(
          DownloadItem(
            id: testUrl,
            title: testSurahTitle,
            url: testUrl,
            filePath: '',
            reciterName: testReciterName,
            reciterId: testReciterId,
            status: DownloadStatus.downloading,
            progress: 0.5,
            fileSize: 100,
            downloadedSize: 50,
            createdAt: DateTime.now(),
          ),
        );

        await expectLater(
          bloc.stream,
          emits(
            const DownloadButtonState.downloading(
              progress: 0.5,
              downloadedBytes: 50,
              totalBytes: 100,
            ),
          ),
        );

        // Emit completed
        controller.add(
          DownloadItem(
            id: testUrl,
            title: testSurahTitle,
            url: testUrl,
            filePath: '',
            reciterName: testReciterName,
            reciterId: testReciterId,
            status: DownloadStatus.completed,
            progress: 1.0,
            fileSize: 100,
            downloadedSize: 100,
            createdAt: DateTime.now(),
          ),
        );

        await expectLater(
          bloc.stream,
          emits(const DownloadButtonState.completed()),
        );

        await bloc.close();
        await controller.close();
      });
    });
  });
}
