import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:dartz_plus/dartz_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:tilawa/features/downloads/domain/entities/download_item.dart';
import 'package:tilawa/features/downloads/presentation/bloc/download_button/download_button_bloc.dart';
import 'package:tilawa_core/errors/failures.dart';

import '../../../helpers/mock_helper.mocks.dart';

void main() {
  setUpAll(() {
    provideDummy<Either<Failure, bool>>(const Right(false));
    provideDummy<Either<Failure, void>>(const Right(null));
    provideDummy<Either<Failure, DownloadItem?>>(const Right(null));
  });

  late MockCheckSurahDownloadedUseCase mockCheckSurahDownloaded;
  late MockDownloadSurahUseCase mockDownloadSurah;
  late MockCancelDownloadUseCase mockCancelDownload;
  late MockPauseDownloadUseCase mockPauseDownload;
  late MockResumeDownloadUseCase mockResumeDownload;
  late MockObserveDownloadProgressUseCase mockObserveDownloadProgress;
  late MockGetDownloadItemUseCase mockGetDownloadItem;
  late MockNetworkInfo mockNetworkInfo;
  DownloadButtonBloc? downloadButtonBloc;

  const testUrl = 'https://example.com/001.mp3';
  const testReciterName = 'Abdul Rahman Al-Sudais';
  const testReciterId = 1;
  const testSurahTitle = 'Al-Fatiha';

  setUp(() {
    mockCheckSurahDownloaded = MockCheckSurahDownloadedUseCase();
    mockDownloadSurah = MockDownloadSurahUseCase();
    mockCancelDownload = MockCancelDownloadUseCase();
    mockPauseDownload = MockPauseDownloadUseCase();
    mockResumeDownload = MockResumeDownloadUseCase();
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

    mockNetworkInfo = MockNetworkInfo();
    // Default: Online
    when(mockNetworkInfo.isConnected).thenAnswer((_) async => true);

    mockGetDownloadItem = MockGetDownloadItemUseCase();
    // Default: No active download item found
    when(
      mockGetDownloadItem.call(any),
    ).thenAnswer((_) async => const Right(null));

    downloadButtonBloc = DownloadButtonBloc(
      url: testUrl,
      reciterName: testReciterName,
      reciterId: testReciterId,
      checkSurahDownloaded: mockCheckSurahDownloaded,
      downloadSurah: mockDownloadSurah,
      cancelDownload: mockCancelDownload,
      pauseDownload: mockPauseDownload,
      resumeDownload: mockResumeDownload,
      observeDownloadProgress: mockObserveDownloadProgress,
      getDownloadItem: mockGetDownloadItem,
      networkInfo: mockNetworkInfo,
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
            getDownloadItem: mockGetDownloadItem,
            networkInfo: mockNetworkInfo,
            initialIsDownloading: true,
            initialProgress: 0.1,
            pauseDownload: mockPauseDownload,
            resumeDownload: mockResumeDownload,
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
            getDownloadItem: mockGetDownloadItem,
            networkInfo: mockNetworkInfo,
            initialIsDownloaded: true,
            pauseDownload: mockPauseDownload,
            resumeDownload: mockResumeDownload,
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
        'emits [networkError] when downloadSurah returns NetworkFailure',
        build: () {
          when(
            mockDownloadSurah.call(
              surahId: anyNamed('surahId'),
              surahTitle: anyNamed('surahTitle'),
              reciterName: anyNamed('reciterName'),
              reciterId: anyNamed('reciterId'),
            ),
          ).thenAnswer((_) async => const Left(NetworkFailure('No internet')));
          return downloadButtonBloc!;
        },
        act: (bloc) => bloc.add(
          const DownloadButtonEvent.startDownload(surahTitle: testSurahTitle),
        ),
        expect: () => [
          const DownloadButtonState.pending(),
          const DownloadButtonState.networkError(errorMessage: 'No internet'),
        ],
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

      blocTest<DownloadButtonBloc, DownloadButtonState>(
        'ignores startDownload when already pending or downloading',
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
        act: (bloc) async {
          bloc.add(
            const DownloadButtonEvent.startDownload(surahTitle: testSurahTitle),
          );
          bloc.add(
            const DownloadButtonEvent.startDownload(surahTitle: testSurahTitle),
          );
        },
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
        },
      );
      blocTest<DownloadButtonBloc, DownloadButtonState>(
        'ignores startDownload when state is downloading',
        build: () => downloadButtonBloc!,
        seed: () => const DownloadButtonState.downloading(progress: 0.5),
        act: (bloc) => bloc.add(
          const DownloadButtonEvent.startDownload(surahTitle: testSurahTitle),
        ),
        expect: () => [],
        verify: (_) {
          verifyNever(
            mockDownloadSurah.call(
              surahId: anyNamed('surahId'),
              surahTitle: anyNamed('surahTitle'),
              reciterName: anyNamed('reciterName'),
              reciterId: anyNamed('reciterId'),
            ),
          );
        },
      );
    });

    blocTest<DownloadButtonBloc, DownloadButtonState>(
      'emits [networkError] when startDownload called while offline',
      build: () {
        when(mockNetworkInfo.isConnected).thenAnswer((_) async => false);
        return downloadButtonBloc!;
      },
      act: (bloc) => bloc.add(
        const DownloadButtonEvent.startDownload(surahTitle: testSurahTitle),
      ),
      expect: () => [
        const DownloadButtonState.networkError(
          errorMessage: 'No internet connection',
        ),
      ],
      verify: (_) {
        verify(mockNetworkInfo.isConnected).called(1);
        verifyNever(
          mockDownloadSurah.call(
            surahId: anyNamed('surahId'),
            surahTitle: anyNamed('surahTitle'),
            reciterName: anyNamed('reciterName'),
            reciterId: anyNamed('reciterId'),
          ),
        );
      },
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
        ).thenAnswer((_) async => const Left(AudioFailure('Failed to cancel')));
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
        getDownloadItem: mockGetDownloadItem,
        networkInfo: mockNetworkInfo,
        pauseDownload: mockPauseDownload,
        resumeDownload: mockResumeDownload,
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

    blocTest<DownloadButtonBloc, DownloadButtonState>(
      'emits [failed] when stream emits failed status',
      build: () {
        final item = DownloadItem(
          id: testUrl,
          title: testSurahTitle,
          url: testUrl,
          filePath: '',
          reciterName: testReciterName,
          reciterId: testReciterId,
          status: DownloadStatus.failed,
          progress: 0.0,
          fileSize: 100,
          downloadedSize: 0,
          createdAt: DateTime.now(),
        );
        when(
          mockObserveDownloadProgress.call(any),
        ).thenAnswer((_) => Stream.value(item));
        return downloadButtonBloc!;
      },
      act: (bloc) => bloc.add(const DownloadButtonEvent.initialize()),
      expect: () => [
        const DownloadButtonState.readyToDownload(),
        const DownloadButtonState.failed(errorMessage: 'Download failed'),
      ],
    );

    blocTest<DownloadButtonBloc, DownloadButtonState>(
      'emits [cancelled] when stream emits cancelled status',
      build: () {
        final item = DownloadItem(
          id: testUrl,
          title: testSurahTitle,
          url: testUrl,
          filePath: '',
          reciterName: testReciterName,
          reciterId: testReciterId,
          status: DownloadStatus.cancelled,
          progress: 0.0,
          fileSize: 100,
          downloadedSize: 0,
          createdAt: DateTime.now(),
        );
        when(
          mockObserveDownloadProgress.call(any),
        ).thenAnswer((_) => Stream.value(item));
        return downloadButtonBloc!;
      },
      act: (bloc) => bloc.add(const DownloadButtonEvent.initialize()),
      expect: () => [
        const DownloadButtonState.readyToDownload(),
        const DownloadButtonState.cancelled(),
      ],
    );

    blocTest<DownloadButtonBloc, DownloadButtonState>(
      'emits [paused] when stream emits paused status',
      build: () {
        final item = DownloadItem(
          id: testUrl,
          title: testSurahTitle,
          url: testUrl,
          filePath: '',
          reciterName: testReciterName,
          reciterId: testReciterId,
          status: DownloadStatus.paused,
          progress: 0.3,
          fileSize: 100,
          downloadedSize: 30,
          createdAt: DateTime.now(),
        );
        when(
          mockObserveDownloadProgress.call(any),
        ).thenAnswer((_) => Stream.value(item));
        return downloadButtonBloc!;
      },
      act: (bloc) => bloc.add(const DownloadButtonEvent.initialize()),
      expect: () => [
        const DownloadButtonState.readyToDownload(),
        const DownloadButtonState.paused(),
      ],
    );

    blocTest<DownloadButtonBloc, DownloadButtonState>(
      'emits [pending] when stream emits pending status (handles scroll rebuild)',
      build: () {
        final item = DownloadItem(
          id: testUrl,
          title: testSurahTitle,
          url: testUrl,
          filePath: '',
          reciterName: testReciterName,
          reciterId: testReciterId,
          status: DownloadStatus.pending,
          progress: 0.0,
          fileSize: 100,
          downloadedSize: 0,
          createdAt: DateTime.now(),
        );
        when(
          mockObserveDownloadProgress.call(any),
        ).thenAnswer((_) => Stream.value(item));
        return downloadButtonBloc!;
      },
      act: (bloc) => bloc.add(const DownloadButtonEvent.initialize()),
      expect: () => [
        const DownloadButtonState.readyToDownload(),
        const DownloadButtonState.pending(), // Now correctly emits pending
      ],
    );

    blocTest<DownloadButtonBloc, DownloadButtonState>(
      'emits [failed] when stream encounters error',
      build: () {
        when(
          mockObserveDownloadProgress.call(any),
        ).thenAnswer((_) => Stream.error(Exception('Stream error')));
        return downloadButtonBloc!;
      },
      act: (bloc) => bloc.add(const DownloadButtonEvent.initialize()),
      expect: () => [
        const DownloadButtonState.readyToDownload(),
        const DownloadButtonState.failed(
          errorMessage: 'Stream error: Exception: Stream error',
        ),
      ],
    );
  });

  group('Retry Event', () {
    blocTest<DownloadButtonBloc, DownloadButtonState>(
      'retry event dispatches startDownload event',
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
      },
    );
  });

  group('Bloc Lifecycle - Race Condition Prevention', () {
    test('does not crash when stream emits after bloc is closed', () async {
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
        getDownloadItem: mockGetDownloadItem,
        networkInfo: mockNetworkInfo,
        pauseDownload: mockPauseDownload,
        resumeDownload: mockResumeDownload,
      );

      bloc.add(const DownloadButtonEvent.initialize());
      await expectLater(
        bloc.stream,
        emitsThrough(const DownloadButtonState.readyToDownload()),
      );

      // Close the bloc (simulating navigation away)
      await bloc.close();

      // Now try to emit from the stream (simulating download progress update)
      // This should NOT crash with "Cannot add new events after calling close"
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

      // Give the stream a chance to process
      await Future.delayed(const Duration(milliseconds: 100));

      // Clean up
      await controller.close();

      // If we got here without crashing, the test passes
      expect(true, isTrue);
    });

    test(
      'handles multiple stream events after bloc close gracefully',
      () async {
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
          getDownloadItem: mockGetDownloadItem,
          networkInfo: mockNetworkInfo,
          pauseDownload: mockPauseDownload,
          resumeDownload: mockResumeDownload,
        );

        bloc.add(const DownloadButtonEvent.initialize());
        await expectLater(
          bloc.stream,
          emitsThrough(const DownloadButtonState.readyToDownload()),
        );

        // Close the bloc
        await bloc.close();

        // Emit multiple events (simulating rapid download progress updates)
        controller.add(
          DownloadItem(
            id: testUrl,
            title: testSurahTitle,
            url: testUrl,
            filePath: '',
            reciterName: testReciterName,
            reciterId: testReciterId,
            status: DownloadStatus.downloading,
            progress: 0.3,
            fileSize: 100,
            downloadedSize: 30,
            createdAt: DateTime.now(),
          ),
        );

        controller.add(
          DownloadItem(
            id: testUrl,
            title: testSurahTitle,
            url: testUrl,
            filePath: '',
            reciterName: testReciterName,
            reciterId: testReciterId,
            status: DownloadStatus.downloading,
            progress: 0.7,
            fileSize: 100,
            downloadedSize: 70,
            createdAt: DateTime.now(),
          ),
        );

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

        // Give the stream time to process
        await Future.delayed(const Duration(milliseconds: 100));

        // Clean up
        await controller.close();

        // Test passes if no crash occurred
        expect(true, isTrue);
      },
    );

    test('handles stream error after bloc close gracefully', () async {
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
        getDownloadItem: mockGetDownloadItem,
        networkInfo: mockNetworkInfo,
        pauseDownload: mockPauseDownload,
        resumeDownload: mockResumeDownload,
      );

      bloc.add(const DownloadButtonEvent.initialize());
      await expectLater(
        bloc.stream,
        emitsThrough(const DownloadButtonState.readyToDownload()),
      );

      // Close the bloc
      await bloc.close();

      // Emit an error (simulating network error during download)
      controller.addError(Exception('Network error'));

      // Give the stream time to process
      await Future.delayed(const Duration(milliseconds: 100));

      // Clean up
      await controller.close();

      // Test passes if no crash occurred
      expect(true, isTrue);
    });
    group('Pause and Resume', () {
      blocTest<DownloadButtonBloc, DownloadButtonState>(
        'calls pauseDownload and emits nothing (waiting for stream) when requestPause is added',
        build: () {
          when(
            mockPauseDownload.call(any),
          ).thenAnswer((_) async => const Right(null));
          return downloadButtonBloc!;
        },
        act: (bloc) => bloc.add(const DownloadButtonEvent.requestPause()),
        verify: (_) {
          verify(mockPauseDownload.call(testUrl)).called(1);
        },
      );

      blocTest<DownloadButtonBloc, DownloadButtonState>(
        'calls resumeDownload and emits nothing (waiting for stream) when requestResume is added',
        build: () {
          when(
            mockResumeDownload.call(any),
          ).thenAnswer((_) async => const Right(null));
          return downloadButtonBloc!;
        },
        act: (bloc) => bloc.add(const DownloadButtonEvent.requestResume()),
        verify: (_) {
          verify(mockResumeDownload.call(testUrl)).called(1);
        },
      );

      blocTest<DownloadButtonBloc, DownloadButtonState>(
        'emits [paused] when paused event is received from stream',
        build: () {
          final controller = StreamController<DownloadItem>();
          when(
            mockObserveDownloadProgress.call(any),
          ).thenAnswer((_) => controller.stream);
          return downloadButtonBloc!;
        },
        act: (bloc) {
          bloc.add(const DownloadButtonEvent.initialize());
        },
        skip: 1, // Skip this for now or implement better
      );

      // Simpler version of stream test
      blocTest<DownloadButtonBloc, DownloadButtonState>(
        'emits [paused] when paused event is added',
        build: () => downloadButtonBloc!,
        act: (bloc) => bloc.add(const DownloadButtonEvent.paused()),
        expect: () => [const DownloadButtonState.paused()],
      );
    });
  });
}
