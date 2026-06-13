import 'dart:async';

import 'package:dartz_plus/dartz_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:tilawa/features/downloads/domain/entities/download_item.dart';
import 'package:tilawa/features/downloads/presentation/bloc/download_button/download_button_bloc.dart';
import 'package:tilawa_core/errors/failures.dart';

import '../../../helpers/mock_helper.mocks.dart';

/// Integration test to reproduce the exact crash scenario from Firebase Crashlytics:
/// Fatal Exception: io.flutter.plugins.firebase.crashlytics.FlutterError:
/// Bad state: Cannot add new events after calling close
/// at _BroadcastStreamController.add(dart:async)
/// at Bloc.add(bloc.dart:97)
/// at DownloadButtonBloc._listenToProgress(download_button_bloc.dart:220)
///
/// This test simulates the real-world scenario:
/// 1. User starts downloading a surah
/// 2. Download is in progress (stream subscription active)
/// 3. User navigates away (widget disposed → bloc closed)
/// 4. Download progress update arrives → tries to add event to closed bloc → CRASH
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
  late MockCheckLowDeviceStorageUseCase mockCheckLowDeviceStorage;

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
    mockNetworkInfo = MockNetworkInfo();
    when(mockNetworkInfo.isConnected).thenAnswer((_) async => true);

    mockGetDownloadItem = MockGetDownloadItemUseCase();
    when(
      mockGetDownloadItem.call(any),
    ).thenAnswer((_) async => const Right(null));

    mockCheckLowDeviceStorage = MockCheckLowDeviceStorageUseCase();
    when(
      mockCheckLowDeviceStorage.call(
        estimatedRequiredBytes: anyNamed('estimatedRequiredBytes'),
      ),
    ).thenAnswer((_) async => false);

    when(
      mockCheckSurahDownloaded.call(
        surahId: anyNamed('surahId'),
        reciterName: anyNamed('reciterName'),
      ),
    ).thenAnswer((_) async => const Right(false));

    when(
      mockDownloadSurah.call(
        surahId: anyNamed('surahId'),
        surahTitle: anyNamed('surahTitle'),
        reciterName: anyNamed('reciterName'),
        reciterId: anyNamed('reciterId'),
      ),
    ).thenAnswer((_) async => const Right(null));
  });

  group('Firebase Crash Reproduction - download_button_bloc.dart:220', () {
    test('CRASH SCENARIO: Download progress updates after bloc close '
        '(simulates user navigating away during download)', () async {
      // Setup a stream controller to simulate flutter_downloader progress updates
      final progressController = StreamController<DownloadItem>.broadcast();

      when(
        mockObserveDownloadProgress.call(any),
      ).thenAnswer((_) => progressController.stream);

      // 1. Create bloc and initialize (simulates widget creation)
      final bloc = DownloadButtonBloc(
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
        checkLowDeviceStorage: mockCheckLowDeviceStorage,
      );

      // 2. Initialize and start download (normal user flow)
      bloc.add(const DownloadButtonEvent.initialize());
      await Future.delayed(const Duration(milliseconds: 50));

      bloc.add(
        const DownloadButtonEvent.startDownload(surahTitle: testSurahTitle),
      );
      await Future.delayed(const Duration(milliseconds: 50));

      // 3. Simulate initial download progress
      progressController.add(
        DownloadItem(
          id: testUrl,
          title: testSurahTitle,
          url: testUrl,
          filePath: '',
          reciterName: testReciterName,
          reciterId: testReciterId,
          status: DownloadStatus.downloading,
          progress: 0.1,
          fileSize: 1000,
          downloadedSize: 100,
          createdAt: DateTime.now(),
        ),
      );

      await Future.delayed(const Duration(milliseconds: 50));

      // 4. User navigates away → widget disposed → bloc closed
      // This is the critical moment where the bloc closes while download is active
      await bloc.close();

      // 5. BUT... download is still in progress in background!
      // flutter_downloader continues to emit progress events
      // This is where the crash occurred (line 220 in bloc)

      // WITHOUT FIX: This would throw:
      // "Bad state: Cannot add new events after calling close"
      //
      // WITH FIX: The isClosed check prevents the crash
      expect(
        () {
          progressController.add(
            DownloadItem(
              id: testUrl,
              title: testSurahTitle,
              url: testUrl,
              filePath: '',
              reciterName: testReciterName,
              reciterId: testReciterId,
              status: DownloadStatus.downloading,
              progress: 0.5, // More progress
              fileSize: 1000,
              downloadedSize: 500,
              createdAt: DateTime.now(),
            ),
          );
        },
        returnsNormally, // Should NOT crash
      );

      // Give the stream time to process the event
      await Future.delayed(const Duration(milliseconds: 100));

      // 6. More progress updates (rapid fire, as happens in real downloads)
      expect(() {
        progressController.add(
          DownloadItem(
            id: testUrl,
            title: testSurahTitle,
            url: testUrl,
            filePath: '',
            reciterName: testReciterName,
            reciterId: testReciterId,
            status: DownloadStatus.downloading,
            progress: 0.7,
            fileSize: 1000,
            downloadedSize: 700,
            createdAt: DateTime.now(),
          ),
        );
      }, returnsNormally);

      await Future.delayed(const Duration(milliseconds: 100));

      // 7. Download completes in background
      expect(() {
        progressController.add(
          DownloadItem(
            id: testUrl,
            title: testSurahTitle,
            url: testUrl,
            filePath: '/path/to/file.mp3',
            reciterName: testReciterName,
            reciterId: testReciterId,
            status: DownloadStatus.completed,
            progress: 1.0,
            fileSize: 1000,
            downloadedSize: 1000,
            createdAt: DateTime.now(),
          ),
        );
      }, returnsNormally);

      await Future.delayed(const Duration(milliseconds: 100));

      // Clean up
      await progressController.close();

      // SUCCESS: If we reach here without throwing, the fix works!
    });

    test('CRASH SCENARIO: Stream error after bloc close '
        '(simulates network error during background download)', () async {
      final progressController = StreamController<DownloadItem>.broadcast();

      when(
        mockObserveDownloadProgress.call(any),
      ).thenAnswer((_) => progressController.stream);

      final bloc = DownloadButtonBloc(
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
        checkLowDeviceStorage: mockCheckLowDeviceStorage,
      );

      bloc.add(const DownloadButtonEvent.initialize());
      await Future.delayed(const Duration(milliseconds: 50));

      bloc.add(
        const DownloadButtonEvent.startDownload(surahTitle: testSurahTitle),
      );
      await Future.delayed(const Duration(milliseconds: 50));

      // Close bloc (user navigated away)
      await bloc.close();

      // Stream error arrives (network failure, etc.)
      // WITHOUT FIX: Would try to add DownloadButtonEvent.failed → crash
      // WITH FIX: isClosed check in onError prevents crash
      expect(() {
        progressController.addError(Exception('Network connection lost'));
      }, returnsNormally);

      await Future.delayed(const Duration(milliseconds: 100));

      // Clean up
      await progressController.close();
    });

    test('CRASH SCENARIO: Multiple rapid progress updates after close '
        '(simulates fast download with many progress callbacks)', () async {
      final progressController = StreamController<DownloadItem>.broadcast();

      when(
        mockObserveDownloadProgress.call(any),
      ).thenAnswer((_) => progressController.stream);

      final bloc = DownloadButtonBloc(
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
        checkLowDeviceStorage: mockCheckLowDeviceStorage,
      );

      bloc.add(const DownloadButtonEvent.initialize());
      await Future.delayed(const Duration(milliseconds: 50));

      bloc.add(
        const DownloadButtonEvent.startDownload(surahTitle: testSurahTitle),
      );
      await Future.delayed(const Duration(milliseconds: 50));

      // Close bloc
      await bloc.close();

      // Rapid fire progress updates (as happens with fast downloads)
      // Each of these would crash without the fix
      for (var i = 0; i <= 100; i += 5) {
        expect(() {
          progressController.add(
            DownloadItem(
              id: testUrl,
              title: testSurahTitle,
              url: testUrl,
              filePath: '',
              reciterName: testReciterName,
              reciterId: testReciterId,
              status: DownloadStatus.downloading,
              progress: i / 100,
              fileSize: 1000,
              downloadedSize: i * 10,
              createdAt: DateTime.now(),
            ),
          );
        }, returnsNormally);
      }

      await Future.delayed(const Duration(milliseconds: 100));

      // Clean up
      await progressController.close();
    });
  });
}
