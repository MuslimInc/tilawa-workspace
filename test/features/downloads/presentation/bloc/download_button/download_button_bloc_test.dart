import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:muzakri/features/downloads/data/services/download_service.dart';
import 'package:muzakri/features/downloads/domain/entities/download_item.dart';
import 'package:muzakri/features/downloads/domain/repositories/downloads_repository.dart';
import 'package:muzakri/features/downloads/presentation/bloc/download_button/download_button_bloc.dart';

import 'download_button_bloc_test.mocks.dart';

@GenerateMocks([DownloadsRepository, DownloadService])
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockDownloadsRepository mockDownloadsRepository;
  late DownloadButtonBloc downloadButtonBloc;

  const testUrl = 'https://example.com/001.mp3';
  const testReciterName = 'Abdul Rahman Al-Sudais';
  const testReciterId = 1;
  const testSurahTitle = 'Al-Fatiha';

  setUp(() {
    mockDownloadsRepository = MockDownloadsRepository();
    when(
      mockDownloadsRepository.downloadUpdates,
    ).thenAnswer((_) => const Stream.empty());

    downloadButtonBloc = DownloadButtonBloc(
      url: testUrl,
      reciterName: testReciterName,
      reciterId: testReciterId,
      downloadsRepository: mockDownloadsRepository,
    );
  });

  tearDown(() {
    downloadButtonBloc.close();
  });

  group('DownloadButtonBloc -', () {
    group('Initialization', () {
      test('initial state is initial()', () {
        expect(downloadButtonBloc.state, const DownloadButtonState.initial());
      });

      blocTest<DownloadButtonBloc, DownloadButtonState>(
        'emits [readyToDownload] when surah is not downloaded',
        build: () {
          when(
            mockDownloadsRepository.isSurahDownloaded(any, any),
          ).thenAnswer((_) async => false);
          when(
            mockDownloadsRepository.isSurahDownloading(any, any),
          ).thenAnswer((_) async => false);
          return downloadButtonBloc;
        },
        act: (bloc) => bloc.add(const DownloadButtonEvent.initialize()),
        expect: () => [const DownloadButtonState.readyToDownload()],
      );

      blocTest<DownloadButtonBloc, DownloadButtonState>(
        'emits [completed] when surah is already downloaded',
        build: () {
          when(
            mockDownloadsRepository.isSurahDownloaded(any, any),
          ).thenAnswer((_) async => true);
          return DownloadButtonBloc(
            url: testUrl,
            reciterName: testReciterName,
            reciterId: testReciterId,
            downloadsRepository: mockDownloadsRepository,
          );
        },
        act: (bloc) => bloc.add(const DownloadButtonEvent.initialize()),
        expect: () => [const DownloadButtonState.completed()],
      );

      blocTest<DownloadButtonBloc, DownloadButtonState>(
        'emits [completed] instantly when initialIsDownloaded is true (Optimization)',
        build: () {
          return DownloadButtonBloc(
            url: testUrl,
            reciterName: testReciterName,
            reciterId: testReciterId,
            downloadsRepository: mockDownloadsRepository,
            initialIsDownloaded: true,
          );
        },
        act: (bloc) => bloc.add(const DownloadButtonEvent.initialize()),
        expect: () => [const DownloadButtonState.completed()],
        verify: (_) {
          verifyNever(mockDownloadsRepository.isSurahDownloaded(any, any));
        },
      );

      blocTest<DownloadButtonBloc, DownloadButtonState>(
        'emits [downloading] instantly when initialIsDownloading is true (Optimization)',
        build: () {
          return DownloadButtonBloc(
            url: testUrl,
            reciterName: testReciterName,
            reciterId: testReciterId,
            downloadsRepository: mockDownloadsRepository,
            initialIsDownloading: true,
            initialProgress: 0.5,
          );
        },
        act: (bloc) => bloc.add(const DownloadButtonEvent.initialize()),
        expect: () => [const DownloadButtonState.downloading(progress: 0.5)],
        verify: (_) {
          verifyNever(mockDownloadsRepository.isSurahDownloading(any, any));
        },
      );

      blocTest<DownloadButtonBloc, DownloadButtonState>(
        'emits [pending] when surah is currently pending',
        build: () {
          when(
            mockDownloadsRepository.isSurahDownloaded(any, any),
          ).thenAnswer((_) async => false);
          when(
            mockDownloadsRepository.isSurahDownloading(any, any),
          ).thenAnswer((_) async => true);
          when(mockDownloadsRepository.getDownloadItem(any)).thenAnswer(
            (_) async => DownloadItem(
              id: '${testUrl}_$testReciterName',
              title: testSurahTitle,
              url: testUrl,
              filePath: '/path/to/file.mp3',
              reciterName: testReciterName,
              reciterId: testReciterId,
              status: DownloadStatus.pending,
              progress: 0.0,
              fileSize: 1024000,
              downloadedSize: 0,
              createdAt: DateTime.now(),
            ),
          );
          return DownloadButtonBloc(
            url: testUrl,
            reciterName: testReciterName,
            reciterId: testReciterId,
            downloadsRepository: mockDownloadsRepository,
          );
        },
        act: (bloc) => bloc.add(const DownloadButtonEvent.initialize()),
        expect: () => [const DownloadButtonState.pending()],
      );

      blocTest<DownloadButtonBloc, DownloadButtonState>(
        'emits [downloading] when surah is currently downloading',
        build: () {
          when(
            mockDownloadsRepository.isSurahDownloaded(any, any),
          ).thenAnswer((_) async => false);
          when(
            mockDownloadsRepository.isSurahDownloading(any, any),
          ).thenAnswer((_) async => true);
          when(mockDownloadsRepository.getDownloadItem(any)).thenAnswer(
            (_) async => DownloadItem(
              id: '${testUrl}_$testReciterName',
              title: testSurahTitle,
              url: testUrl,
              filePath: '/path/to/file.mp3',
              reciterName: testReciterName,
              reciterId: testReciterId,
              status: DownloadStatus.downloading,
              progress: 0.5,
              fileSize: 1024000,
              downloadedSize: 512000,
              createdAt: DateTime.now(),
            ),
          );
          return DownloadButtonBloc(
            url: testUrl,
            reciterName: testReciterName,
            reciterId: testReciterId,
            downloadsRepository: mockDownloadsRepository,
          );
        },
        act: (bloc) => bloc.add(const DownloadButtonEvent.initialize()),
        expect: () => [
          const DownloadButtonState.downloading(
            progress: 0.5,
            downloadedBytes: 512000,
            totalBytes: 1024000,
          ),
        ],
      );

      blocTest<DownloadButtonBloc, DownloadButtonState>(
        'emits [failed] when surah download previously failed',
        build: () {
          when(
            mockDownloadsRepository.isSurahDownloaded(any, any),
          ).thenAnswer((_) async => false);
          when(
            mockDownloadsRepository.isSurahDownloading(any, any),
          ).thenAnswer((_) async => true);
          when(mockDownloadsRepository.getDownloadItem(any)).thenAnswer(
            (_) async => DownloadItem(
              id: '${testUrl}_$testReciterName',
              title: testSurahTitle,
              url: testUrl,
              filePath: '/path/to/file.mp3',
              reciterName: testReciterName,
              reciterId: testReciterId,
              status: DownloadStatus.failed,
              progress: 0.3,
              fileSize: 1024000,
              downloadedSize: 307200,
              createdAt: DateTime.now(),
            ),
          );
          return DownloadButtonBloc(
            url: testUrl,
            reciterName: testReciterName,
            reciterId: testReciterId,
            downloadsRepository: mockDownloadsRepository,
          );
        },
        act: (bloc) => bloc.add(const DownloadButtonEvent.initialize()),
        expect: () => [const DownloadButtonState.failed()],
      );

      blocTest<DownloadButtonBloc, DownloadButtonState>(
        'emits [readyToDownload] when initialization fails with MissingPluginException',
        build: () {
          when(
            mockDownloadsRepository.isSurahDownloaded(any, any),
          ).thenThrow(MissingPluginException('Platform channel not available'));
          return DownloadButtonBloc(
            url: testUrl,
            reciterName: testReciterName,
            reciterId: testReciterId,
            downloadsRepository: mockDownloadsRepository,
          );
        },
        act: (bloc) => bloc.add(const DownloadButtonEvent.initialize()),
        expect: () => [const DownloadButtonState.readyToDownload()],
      );

      blocTest<DownloadButtonBloc, DownloadButtonState>(
        'emits [failed] when initialization fails with general exception',
        build: () {
          when(
            mockDownloadsRepository.isSurahDownloaded(any, any),
          ).thenThrow(Exception('Database error'));
          return DownloadButtonBloc(
            url: testUrl,
            reciterName: testReciterName,
            reciterId: testReciterId,
            downloadsRepository: mockDownloadsRepository,
          );
        },
        act: (bloc) => bloc.add(const DownloadButtonEvent.initialize()),
        expect: () => [
          const DownloadButtonState.failed(
            errorMessage: 'Failed to check download status',
          ),
        ],
      );
    });

    group('StartDownload Event', () {
      blocTest<DownloadButtonBloc, DownloadButtonState>(
        'emits [pending] when startDownload is triggered',
        build: () {
          when(
            mockDownloadsRepository.isSurahDownloaded(any, any),
          ).thenAnswer((_) async => false);
          when(
            mockDownloadsRepository.isSurahDownloading(any, any),
          ).thenAnswer((_) async => false);
          when(
            mockDownloadsRepository.startDownload(
              any,
              title: anyNamed('title'),
              reciterName: anyNamed('reciterName'),
              reciterId: anyNamed('reciterId'),
              surahTitle: anyNamed('surahTitle'),
              showNotification: anyNamed('showNotification'),
            ),
          ).thenAnswer((_) async {
            return;
          });
          return downloadButtonBloc;
        },
        act: (bloc) => bloc.add(
          const DownloadButtonEvent.startDownload(surahTitle: testSurahTitle),
        ),
        expect: () => [const DownloadButtonState.pending()],
      );

      blocTest<DownloadButtonBloc, DownloadButtonState>(
        'emits [pending] when download fails with MissingPluginException in test',
        build: () {
          when(
            mockDownloadsRepository.isSurahDownloaded(any, any),
          ).thenAnswer((_) async => false);
          when(
            mockDownloadsRepository.isSurahDownloading(any, any),
          ).thenAnswer((_) async => false);
          when(
            mockDownloadsRepository.startDownload(
              any,
              title: anyNamed('title'),
              surahTitle: anyNamed('surahTitle'),
              reciterName: anyNamed('reciterName'),
              reciterId: anyNamed('reciterId'),
            ),
          ).thenThrow(MissingPluginException('Platform channel not available'));
          return downloadButtonBloc;
        },
        act: (bloc) => bloc.add(
          const DownloadButtonEvent.startDownload(surahTitle: testSurahTitle),
        ),
        expect: () => [const DownloadButtonState.pending()],
      );

      blocTest<DownloadButtonBloc, DownloadButtonState>(
        'emits [pending, failed] when download fails with general exception',
        build: () {
          when(
            mockDownloadsRepository.isSurahDownloaded(any, any),
          ).thenAnswer((_) async => false);
          when(
            mockDownloadsRepository.isSurahDownloading(any, any),
          ).thenAnswer((_) async => false);
          when(
            mockDownloadsRepository.startDownload(
              any,
              title: anyNamed('title'),
              surahTitle: anyNamed('surahTitle'),
              reciterName: anyNamed('reciterName'),
              reciterId: anyNamed('reciterId'),
            ),
          ).thenThrow(Exception('Network error'));
          return downloadButtonBloc;
        },
        act: (bloc) => bloc.add(
          const DownloadButtonEvent.startDownload(surahTitle: testSurahTitle),
        ),
        expect: () => [
          const DownloadButtonState.pending(),
          const DownloadButtonState.failed(
            errorMessage: 'Failed to start download: Exception: Network error',
          ),
        ],
      );
    });

    group('Retry Event', () {
      blocTest<DownloadButtonBloc, DownloadButtonState>(
        'triggers startDownload event when retry is called',
        build: () {
          when(
            mockDownloadsRepository.isSurahDownloaded(any, any),
          ).thenAnswer((_) async => false);
          when(
            mockDownloadsRepository.isSurahDownloading(any, any),
          ).thenAnswer((_) async => false);
          when(
            mockDownloadsRepository.startDownload(
              any,
              title: anyNamed('title'),
              surahTitle: anyNamed('surahTitle'),
              reciterName: anyNamed('reciterName'),
              reciterId: anyNamed('reciterId'),
            ),
          ).thenAnswer((_) async {
            return;
          });
          return downloadButtonBloc;
        },
        act: (bloc) => bloc.add(
          const DownloadButtonEvent.retry(surahTitle: testSurahTitle),
        ),
        expect: () => [const DownloadButtonState.pending()],
      );
    });

    group('Cancel Event', () {
      blocTest<DownloadButtonBloc, DownloadButtonState>(
        'emits [cancelled] when cancel is triggered',
        build: () {
          when(
            mockDownloadsRepository.isSurahDownloaded(any, any),
          ).thenAnswer((_) async => false);
          when(
            mockDownloadsRepository.isSurahDownloading(any, any),
          ).thenAnswer((_) async => false);
          when(mockDownloadsRepository.cancelDownload(any)).thenAnswer((
            _,
          ) async {
            return;
          });
          return downloadButtonBloc;
        },
        act: (bloc) => bloc.add(const DownloadButtonEvent.cancel()),
        expect: () => [const DownloadButtonState.cancelled()],
      );

      blocTest<DownloadButtonBloc, DownloadButtonState>(
        'emits [cancelled] when cancel fails with MissingPluginException',
        build: () {
          when(
            mockDownloadsRepository.isSurahDownloaded(any, any),
          ).thenAnswer((_) async => false);
          when(
            mockDownloadsRepository.isSurahDownloading(any, any),
          ).thenAnswer((_) async => false);
          when(
            mockDownloadsRepository.cancelDownload(any),
          ).thenThrow(MissingPluginException('Platform channel not available'));
          return downloadButtonBloc;
        },
        act: (bloc) => bloc.add(const DownloadButtonEvent.cancel()),
        expect: () => [const DownloadButtonState.cancelled()],
      );

      blocTest<DownloadButtonBloc, DownloadButtonState>(
        'emits [failed] when cancel fails with general exception',
        build: () {
          when(
            mockDownloadsRepository.isSurahDownloaded(any, any),
          ).thenAnswer((_) async => false);
          when(
            mockDownloadsRepository.isSurahDownloading(any, any),
          ).thenAnswer((_) async => false);
          when(
            mockDownloadsRepository.cancelDownload(any),
          ).thenThrow(Exception('Cancel failed'));
          return downloadButtonBloc;
        },
        act: (bloc) => bloc.add(const DownloadButtonEvent.cancel()),
        expect: () => [
          const DownloadButtonState.failed(
            errorMessage: 'Failed to cancel download',
          ),
        ],
      );
    });

    group('ProgressUpdated Event', () {
      blocTest<DownloadButtonBloc, DownloadButtonState>(
        'emits [downloading] with updated progress',
        build: () {
          when(
            mockDownloadsRepository.isSurahDownloaded(any, any),
          ).thenAnswer((_) async => false);
          when(
            mockDownloadsRepository.isSurahDownloading(any, any),
          ).thenAnswer((_) async => false);
          return downloadButtonBloc;
        },
        act: (bloc) => bloc.add(
          const DownloadButtonEvent.progressUpdated(
            progress: 0.75,
            downloadedBytes: 768000,
            totalBytes: 1024000,
          ),
        ),
        expect: () => [
          const DownloadButtonState.downloading(
            progress: 0.75,
            downloadedBytes: 768000,
            totalBytes: 1024000,
          ),
        ],
      );
    });

    group('Completed Event', () {
      blocTest<DownloadButtonBloc, DownloadButtonState>(
        'emits [completed] when download completes',
        build: () {
          when(
            mockDownloadsRepository.isSurahDownloaded(any, any),
          ).thenAnswer((_) async => false);
          when(
            mockDownloadsRepository.isSurahDownloading(any, any),
          ).thenAnswer((_) async => false);
          return downloadButtonBloc;
        },
        act: (bloc) => bloc.add(const DownloadButtonEvent.completed()),
        expect: () => [const DownloadButtonState.completed()],
      );
    });

    group('Failed Event', () {
      blocTest<DownloadButtonBloc, DownloadButtonState>(
        'emits [failed] with error message',
        build: () {
          when(
            mockDownloadsRepository.isSurahDownloaded(any, any),
          ).thenAnswer((_) async => false);
          when(
            mockDownloadsRepository.isSurahDownloading(any, any),
          ).thenAnswer((_) async => false);
          return downloadButtonBloc;
        },
        act: (bloc) => bloc.add(
          const DownloadButtonEvent.failed(errorMessage: 'Network timeout'),
        ),
        expect: () => [
          const DownloadButtonState.failed(errorMessage: 'Network timeout'),
        ],
      );

      blocTest<DownloadButtonBloc, DownloadButtonState>(
        'emits [failed] without error message',
        build: () {
          when(
            mockDownloadsRepository.isSurahDownloaded(any, any),
          ).thenAnswer((_) async => false);
          when(
            mockDownloadsRepository.isSurahDownloading(any, any),
          ).thenAnswer((_) async => false);
          // Return fresh instance so skip: 1 works correctly
          return DownloadButtonBloc(
            url: testUrl,
            reciterName: testReciterName,
            reciterId: testReciterId,
            downloadsRepository: mockDownloadsRepository,
          );
        },
        act: (bloc) => bloc.add(const DownloadButtonEvent.failed()),
        expect: () => [const DownloadButtonState.failed()],
      );
    });

    group('Cancelled Event', () {
      blocTest<DownloadButtonBloc, DownloadButtonState>(
        'emits [cancelled] from event',
        build: () {
          when(
            mockDownloadsRepository.isSurahDownloaded(any, any),
          ).thenAnswer((_) async => false);
          when(
            mockDownloadsRepository.isSurahDownloading(any, any),
          ).thenAnswer((_) async => false);
          // Return fresh instance so skip: 1 works correctly
          return DownloadButtonBloc(
            url: testUrl,
            reciterName: testReciterName,
            reciterId: testReciterId,
            downloadsRepository: mockDownloadsRepository,
          );
        },
        act: (bloc) => bloc.add(const DownloadButtonEvent.cancelled()),
        expect: () => [const DownloadButtonState.cancelled()],
      );
    });

    group('Repository Updates', () {
      test('re-initializes when receiving matching update', () async {
        // Arrange
        final updatesController = StreamController<DownloadItem>.broadcast();
        when(
          mockDownloadsRepository.downloadUpdates,
        ).thenAnswer((_) => updatesController.stream);

        // Initial check returns false
        when(
          mockDownloadsRepository.isSurahDownloaded(any, any),
        ).thenAnswer((_) async => false);
        when(
          mockDownloadsRepository.isSurahDownloading(any, any),
        ).thenAnswer((_) async => false);

        final bloc = DownloadButtonBloc(
          url: testUrl,
          reciterName: testReciterName,
          reciterId: testReciterId,
          downloadsRepository: mockDownloadsRepository,
        );
        bloc.add(const DownloadButtonEvent.initialize());

        // Wait for first state
        await expectLater(
          bloc.stream,
          emitsThrough(const DownloadButtonState.readyToDownload()),
        );

        // Act
        // Setup mock for re-initialization to return true (downloading)
        when(
          mockDownloadsRepository.isSurahDownloading(any, any),
        ).thenAnswer((_) async => true);
        when(mockDownloadsRepository.getDownloadItem(any)).thenAnswer(
          (_) async => DownloadItem(
            id: 'id',
            title: 'title',
            url: testUrl,
            filePath: 'path',
            reciterName: testReciterName,
            reciterId: 1,
            status: DownloadStatus.pending,
            progress: 0,
            fileSize: 0,
            downloadedSize: 0,
            createdAt: DateTime.now(),
          ),
        );

        // Assert
        // Expect state to change to pending
        final Future<void> future = expectLater(
          bloc.stream,
          emitsThrough(const DownloadButtonState.pending()),
        );

        // Emit update
        updatesController.add(
          DownloadItem(
            id: 'id',
            title: 'title',
            url: testUrl,
            filePath: 'path',
            reciterName: testReciterName,
            reciterId: 1,
            status: DownloadStatus.pending,
            progress: 0,
            fileSize: 0,
            downloadedSize: 0,
            createdAt: DateTime.now(),
          ),
        );

        await future;

        await bloc.close();
        await updatesController.close();
      });
    });

    group('_isFirstInit Flag Behavior (State Synchronization Fix)', () {
      blocTest<DownloadButtonBloc, DownloadButtonState>(
        'first initialization uses initialIsDownloaded without querying repository',
        build: () {
          // This should NOT call repository methods
          return DownloadButtonBloc(
            url: testUrl,
            reciterName: testReciterName,
            reciterId: testReciterId,
            downloadsRepository: mockDownloadsRepository,
            initialIsDownloaded: true,
          );
        },
        act: (bloc) => bloc.add(const DownloadButtonEvent.initialize()),
        expect: () => [const DownloadButtonState.completed()],
        verify: (_) {
          // Verify repository was NOT queried (optimization)
          verifyNever(mockDownloadsRepository.isSurahDownloaded(any, any));
          verifyNever(mockDownloadsRepository.isSurahDownloading(any, any));
        },
      );

      blocTest<DownloadButtonBloc, DownloadButtonState>(
        'second initialization IGNORES initial values and queries repository',
        build: () {
          // Setup: Repository returns false (not downloaded)
          when(
            mockDownloadsRepository.isSurahDownloaded(any, any),
          ).thenAnswer((_) async => false);
          when(
            mockDownloadsRepository.isSurahDownloading(any, any),
          ).thenAnswer((_) async => false);

          // Create bloc with initialIsDownloaded=true (stale value)
          return DownloadButtonBloc(
            url: testUrl,
            reciterName: testReciterName,
            reciterId: testReciterId,
            downloadsRepository: mockDownloadsRepository,
            initialIsDownloaded: true, // Stale - says it's downloaded
          );
        },
        act: (bloc) {
          // First init - uses initial value
          bloc.add(const DownloadButtonEvent.initialize());
          // Second init - should query repository and get actual state
          bloc.add(const DownloadButtonEvent.initialize());
        },
        expect: () => [
          const DownloadButtonState.completed(), // First: uses initial value
          const DownloadButtonState.readyToDownload(), // Second: queries repo, gets actual state
        ],
        verify: (_) {
          // Verify repository was queried on SECOND initialization
          verify(mockDownloadsRepository.isSurahDownloaded(any, any)).called(1);
        },
      );

      test(
        'repository update triggers re-initialization with actual state',
        () async {
          // Arrange
          final updatesController = StreamController<DownloadItem>.broadcast();
          when(
            mockDownloadsRepository.downloadUpdates,
          ).thenAnswer((_) => updatesController.stream);

          // Initial state: not downloaded
          when(
            mockDownloadsRepository.isSurahDownloaded(any, any),
          ).thenAnswer((_) async => false);
          when(
            mockDownloadsRepository.isSurahDownloading(any, any),
          ).thenAnswer((_) async => false);

          final bloc = DownloadButtonBloc(
            url: testUrl,
            reciterName: testReciterName,
            reciterId: testReciterId,
            downloadsRepository: mockDownloadsRepository,
            initialIsDownloaded: false, // Says not downloaded
          );

          // Act: First initialization
          bloc.add(const DownloadButtonEvent.initialize());
          await expectLater(
            bloc.stream,
            emitsThrough(const DownloadButtonState.readyToDownload()),
          );

          // Simulate batch download: repository now reports it as downloading
          when(
            mockDownloadsRepository.isSurahDownloaded(any, any),
          ).thenAnswer((_) async => false);
          when(
            mockDownloadsRepository.isSurahDownloading(any, any),
          ).thenAnswer((_) async => true);
          when(mockDownloadsRepository.getDownloadItem(any)).thenAnswer(
            (_) async => DownloadItem(
              id: testUrl,
              title: testSurahTitle,
              url: testUrl,
              filePath: '/path/to/file.mp3',
              reciterName: testReciterName,
              reciterId: testReciterId,
              status: DownloadStatus.downloading,
              progress: 0.3,
              fileSize: 1024000,
              downloadedSize: 307200,
              createdAt: DateTime.now(),
            ),
          );

          // Assert: Expect state change when repository emits update
          final Future<void> future = expectLater(
            bloc.stream,
            emitsThrough(
              const DownloadButtonState.downloading(
                progress: 0.3,
                downloadedBytes: 307200,
                totalBytes: 1024000,
              ),
            ),
          );

          // Trigger update from repository (simulating batch download)
          updatesController.add(
            DownloadItem(
              id: testUrl,
              title: testSurahTitle,
              url: testUrl,
              filePath: '/path/to/file.mp3',
              reciterName: testReciterName,
              reciterId: testReciterId,
              status: DownloadStatus.downloading,
              progress: 0.3,
              fileSize: 1024000,
              downloadedSize: 307200,
              createdAt: DateTime.now(),
            ),
          );

          await future;

          // Verify repository was queried on re-initialization
          verify(
            mockDownloadsRepository.isSurahDownloading(any, any),
          ).called(greaterThan(1));

          await bloc.close();
          await updatesController.close();
        },
      );

      test(
        'batch download creates item -> button receives update -> queries actual state',
        () async {
          // This test simulates the exact scenario:
          // 1. Button initialized with initialIsDownloaded=false
          // 2. User clicks "Download All"
          // 3. Repository creates download item and emits update
          // 4. Button re-initializes and should show downloading state

          final updatesController = StreamController<DownloadItem>.broadcast();
          when(
            mockDownloadsRepository.downloadUpdates,
          ).thenAnswer((_) => updatesController.stream);

          // Initial: not downloaded, not downloading
          when(
            mockDownloadsRepository.isSurahDownloaded(any, any),
          ).thenAnswer((_) async => false);
          when(
            mockDownloadsRepository.isSurahDownloading(any, any),
          ).thenAnswer((_) async => false);

          final bloc = DownloadButtonBloc(
            url: testUrl,
            reciterName: testReciterName,
            reciterId: testReciterId,
            downloadsRepository: mockDownloadsRepository,
            initialIsDownloaded: false,
            initialIsDownloading: false,
          );

          bloc.add(const DownloadButtonEvent.initialize());
          await expectLater(
            bloc.stream,
            emitsThrough(const DownloadButtonState.readyToDownload()),
          );

          // Batch download starts: repository creates pending item
          when(
            mockDownloadsRepository.isSurahDownloaded(any, any),
          ).thenAnswer((_) async => false);
          when(
            mockDownloadsRepository.isSurahDownloading(any, any),
          ).thenAnswer((_) async => true);
          when(mockDownloadsRepository.getDownloadItem(any)).thenAnswer(
            (_) async => DownloadItem(
              id: testUrl,
              title: testSurahTitle,
              url: testUrl,
              filePath: '/path/to/file.mp3',
              reciterName: testReciterName,
              reciterId: testReciterId,
              status: DownloadStatus.pending,
              progress: 0.0,
              fileSize: 0,
              downloadedSize: 0,
              createdAt: DateTime.now(),
            ),
          );

          final Future<void> future = expectLater(
            bloc.stream,
            emitsThrough(const DownloadButtonState.pending()),
          );

          // Repository emits update (simulating batch download addDownload call)
          updatesController.add(
            DownloadItem(
              id: testUrl,
              title: testSurahTitle,
              url: testUrl,
              filePath: '/path/to/file.mp3',
              reciterName: testReciterName,
              reciterId: testReciterId,
              status: DownloadStatus.pending,
              progress: 0.0,
              fileSize: 0,
              downloadedSize: 0,
              createdAt: DateTime.now(),
            ),
          );

          await future;

          // The fix ensures this works:
          // - First init used initial values (fast, no repo query)
          // - Second init (from update) queried repository once (correct state)
          verify(
            mockDownloadsRepository.isSurahDownloading(any, any),
          ).called(1);

          await bloc.close();
          await updatesController.close();
        },
      );
    });
  });
}
