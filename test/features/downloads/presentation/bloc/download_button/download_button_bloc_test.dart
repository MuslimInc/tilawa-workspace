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
  const testSurahTitle = 'Al-Fatiha';

  setUp(() {
    mockDownloadsRepository = MockDownloadsRepository();

    downloadButtonBloc = DownloadButtonBloc(
      url: testUrl,
      reciterName: testReciterName,
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
          when(mockDownloadsRepository.startDownload(any, any, any)).thenAnswer(
            (_) async {
              return;
            },
          );
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
            mockDownloadsRepository.startDownload(any, any, any),
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
            mockDownloadsRepository.startDownload(any, any, any),
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
          when(mockDownloadsRepository.startDownload(any, any, any)).thenAnswer(
            (_) async {
              return;
            },
          );
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
            downloadsRepository: mockDownloadsRepository,
          );
        },
        act: (bloc) => bloc.add(const DownloadButtonEvent.cancelled()),
        expect: () => [const DownloadButtonState.cancelled()],
      );
    });
  });
}
