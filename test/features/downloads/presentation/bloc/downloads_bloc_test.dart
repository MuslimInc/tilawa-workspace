import 'package:audio_service/audio_service.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:muzakri/audio_player_handler.dart';
import 'package:muzakri/core/errors/failures.dart';
import 'package:muzakri/core/services/analytics_service.dart';
import 'package:muzakri/features/downloads/data/services/download_service.dart';
import 'package:muzakri/features/downloads/domain/entities/download_item.dart';
import 'package:muzakri/features/downloads/domain/repositories/downloads_repository.dart';
import 'package:muzakri/features/downloads/domain/usecases/clear_all_downloads_use_case.dart';
import 'package:muzakri/features/downloads/domain/usecases/delete_download_use_case.dart';
import 'package:muzakri/features/downloads/domain/usecases/delete_reciter_downloads_use_case.dart';
import 'package:muzakri/features/downloads/domain/usecases/download_surah_use_case.dart';
import 'package:muzakri/features/downloads/domain/usecases/get_downloads_by_reciter_use_case.dart';
import 'package:muzakri/features/downloads/presentation/bloc/downloads_bloc.dart';
import 'package:muzakri/features/premium/domain/repositories/premium_repository.dart';

import 'downloads_bloc_test.mocks.dart';

@GenerateMocks([
  GetDownloadsByReciterUseCase,
  DownloadSurahUseCase,
  DeleteDownloadUseCase,
  DeleteReciterDownloadsUseCase,
  ClearAllDownloadsUseCase,
  DownloadsRepository,
  PremiumRepository,
  AudioPlayerHandler,
  AnalyticsService,
  DownloadService,
])
void main() {
  late DownloadsBloc downloadsBloc;
  late MockGetDownloadsByReciterUseCase mockGetDownloadsByReciterUseCase;
  late MockDownloadSurahUseCase mockDownloadSurahUseCase;
  late MockDeleteDownloadUseCase mockDeleteDownloadUseCase;
  late MockDeleteReciterDownloadsUseCase mockDeleteReciterDownloadsUseCase;
  late MockClearAllDownloadsUseCase mockClearAllDownloadsUseCase;
  late MockDownloadsRepository mockDownloadsRepository;
  late MockPremiumRepository mockPremiumRepository;
  late MockAudioPlayerHandler mockAudioPlayerHandler;
  late MockAnalyticsService mockAnalyticsService;

  setUp(() {
    mockGetDownloadsByReciterUseCase = MockGetDownloadsByReciterUseCase();
    mockDownloadSurahUseCase = MockDownloadSurahUseCase();
    mockDeleteDownloadUseCase = MockDeleteDownloadUseCase();
    mockDeleteReciterDownloadsUseCase = MockDeleteReciterDownloadsUseCase();
    mockClearAllDownloadsUseCase = MockClearAllDownloadsUseCase();
    mockDownloadsRepository = MockDownloadsRepository();
    mockPremiumRepository = MockPremiumRepository();
    mockAudioPlayerHandler = MockAudioPlayerHandler();
    mockAnalyticsService = MockAnalyticsService();

    downloadsBloc = DownloadsBloc(
      getDownloadsByReciter: mockGetDownloadsByReciterUseCase,
      downloadSurah: mockDownloadSurahUseCase,
      deleteDownload: mockDeleteDownloadUseCase,
      deleteReciterDownloads: mockDeleteReciterDownloadsUseCase,
      clearAllDownloads: mockClearAllDownloadsUseCase,
      downloadsRepository: mockDownloadsRepository,
      premiumRepository: mockPremiumRepository,
      audioPlayerHandler: mockAudioPlayerHandler,
      analyticsService: mockAnalyticsService,
    );
  });

  tearDown(() {
    downloadsBloc.close();
  });

  group('DownloadsBloc', () {
    test('initial state should be DownloadsState.initial', () {
      expect(downloadsBloc.state, const DownloadsState.initial());
    });

    group('LoadDownloads', () {
      blocTest<DownloadsBloc, DownloadsState>(
        'emits [loading, loaded] when LoadDownloads is successful',
        build: () {
          when(
            mockGetDownloadsByReciterUseCase(),
          ).thenAnswer((_) async => const Right({}));
          return downloadsBloc;
        },
        act: (bloc) => bloc.add(const LoadDownloads()),
        expect: () => [
          const DownloadsState.loading(),
          const DownloadsState.loaded({}),
        ],
      );

      blocTest<DownloadsBloc, DownloadsState>(
        'emits [loading, error] when LoadDownloads fails',
        build: () {
          when(mockGetDownloadsByReciterUseCase()).thenAnswer(
            (_) async => const Left(AudioFailure('Failed to load downloads')),
          );
          return downloadsBloc;
        },
        act: (bloc) => bloc.add(const LoadDownloads()),
        expect: () => [
          const DownloadsState.loading(),
          const DownloadsState.error('Failed to load downloads'),
        ],
      );
    });

    group('DownloadSurahEvent', () {
      const testSurahId = '001';
      const testSurahTitle = 'Al-Fatiha';
      const testReciterName = 'Abdul Rahman Al-Sudais';

      blocTest<DownloadsBloc, DownloadsState>(
        'emits [downloadStarted, loaded] when download is successful',
        build: () {
          when(
            mockPremiumRepository.canDownload(),
          ).thenAnswer((_) async => true);
          when(
            mockDownloadsRepository.isSurahDownloaded(any, any),
          ).thenAnswer((_) async => false);
          when(
            mockDownloadSurahUseCase(
              surahId: anyNamed('surahId'),
              surahTitle: anyNamed('surahTitle'),
              reciterName: anyNamed('reciterName'),
            ),
          ).thenAnswer((_) async => const Right(null));
          when(
            mockGetDownloadsByReciterUseCase(),
          ).thenAnswer((_) async => const Right({}));
          when(
            mockAnalyticsService.logDownloadStart(
              any,
              fileName: anyNamed('fileName'),
            ),
          ).thenAnswer((_) async {});
          when(
            mockAnalyticsService.logDownloadComplete(
              any,
              fileName: anyNamed('fileName'),
            ),
          ).thenAnswer((_) async {});
          return downloadsBloc;
        },
        act: (bloc) => bloc.add(
          const DownloadSurahEvent(
            surahId: testSurahId,
            surahTitle: testSurahTitle,
            reciterName: testReciterName,
          ),
        ),
        expect: () => [
          const DownloadsState.downloadStarted(
            surahId: testSurahId,
            surahTitle: testSurahTitle,
            reciterName: testReciterName,
          ),
          const DownloadsState.loading(),
          const DownloadsState.loaded({}),
        ],
      );

      blocTest<DownloadsBloc, DownloadsState>(
        'emits [premiumRequired] when user does not have premium access',
        build: () {
          when(
            mockPremiumRepository.canDownload(),
          ).thenAnswer((_) async => false);
          return downloadsBloc;
        },
        act: (bloc) => bloc.add(
          const DownloadSurahEvent(
            surahId: testSurahId,
            surahTitle: testSurahTitle,
            reciterName: testReciterName,
          ),
        ),
        expect: () => [
          const DownloadsState.premiumRequired(
            message:
                'Download feature requires premium subscription. Upgrade to unlock unlimited downloads!',
          ),
        ],
      );

      blocTest<DownloadsBloc, DownloadsState>(
        'emits [error] when surah is already downloaded',
        build: () {
          when(
            mockPremiumRepository.canDownload(),
          ).thenAnswer((_) async => true);
          when(
            mockDownloadsRepository.isSurahDownloaded(any, any),
          ).thenAnswer((_) async => true);
          return downloadsBloc;
        },
        act: (bloc) => bloc.add(
          const DownloadSurahEvent(
            surahId: testSurahId,
            surahTitle: testSurahTitle,
            reciterName: testReciterName,
          ),
        ),
        expect: () => [
          const DownloadsState.error(
            'Surah "Al-Fatiha" by Abdul Rahman Al-Sudais is already downloaded',
          ),
        ],
      );

      blocTest<DownloadsBloc, DownloadsState>(
        'emits [downloadStarted, error] when download fails',
        build: () {
          when(
            mockPremiumRepository.canDownload(),
          ).thenAnswer((_) async => true);
          when(
            mockDownloadsRepository.isSurahDownloaded(any, any),
          ).thenAnswer((_) async => false);
          when(
            mockDownloadSurahUseCase(
              surahId: anyNamed('surahId'),
              surahTitle: anyNamed('surahTitle'),
              reciterName: anyNamed('reciterName'),
            ),
          ).thenAnswer((_) async => const Left(AudioFailure('Network error')));
          when(
            mockAnalyticsService.logDownloadStart(
              any,
              fileName: anyNamed('fileName'),
            ),
          ).thenAnswer((_) async {});
          when(
            mockAnalyticsService.logEvent(
              any,
              parameters: anyNamed('parameters'),
            ),
          ).thenAnswer((_) async {});
          return downloadsBloc;
        },
        act: (bloc) => bloc.add(
          const DownloadSurahEvent(
            surahId: testSurahId,
            surahTitle: testSurahTitle,
            reciterName: testReciterName,
          ),
        ),
        expect: () => [
          const DownloadsState.downloadStarted(
            surahId: testSurahId,
            surahTitle: testSurahTitle,
            reciterName: testReciterName,
          ),
          const DownloadsState.error('Network error'),
        ],
      );
    });

    group('DeleteDownloadEvent', () {
      const testDownloadId = '001_Abdul_Rahman_Al-Sudais';

      blocTest<DownloadsBloc, DownloadsState>(
        'emits [loaded] when delete is successful',
        build: () {
          when(
            mockDeleteDownloadUseCase(any),
          ).thenAnswer((_) async => const Right(null));
          when(
            mockGetDownloadsByReciterUseCase(),
          ).thenAnswer((_) async => const Right({}));
          return downloadsBloc;
        },
        act: (bloc) =>
            bloc.add(const DeleteDownloadEvent(downloadId: testDownloadId)),
        expect: () => [
          const DownloadsState.loading(),
          const DownloadsState.loaded({}),
        ],
      );

      blocTest<DownloadsBloc, DownloadsState>(
        'emits [error] when delete fails',
        build: () {
          when(mockDeleteDownloadUseCase(any)).thenAnswer(
            (_) async => const Left(AudioFailure('Failed to delete')),
          );
          return downloadsBloc;
        },
        act: (bloc) =>
            bloc.add(const DeleteDownloadEvent(downloadId: testDownloadId)),
        expect: () => [const DownloadsState.error('Failed to delete')],
      );
    });

    group('DeleteReciterDownloads', () {
      const testReciterName = 'Abdul Rahman Al-Sudais';

      blocTest<DownloadsBloc, DownloadsState>(
        'emits [loading, loaded] when delete is successful',
        build: () {
          when(
            mockDeleteReciterDownloadsUseCase(any),
          ).thenAnswer((_) async => const Right(null));
          when(
            mockGetDownloadsByReciterUseCase(),
          ).thenAnswer((_) async => const Right({}));
          when(
            mockAnalyticsService.logEvent(
              any,
              parameters: anyNamed('parameters'),
            ),
          ).thenAnswer((_) async {});
          return downloadsBloc;
        },
        act: (bloc) => bloc.add(
          const DeleteReciterDownloads(reciterName: testReciterName),
        ),
        expect: () => [
          const DownloadsState.loading(),
          const DownloadsState.loaded({}),
        ],
      );

      blocTest<DownloadsBloc, DownloadsState>(
        'emits [loading, error] when delete fails',
        build: () {
          when(mockDeleteReciterDownloadsUseCase(any)).thenAnswer(
            (_) async =>
                const Left(AudioFailure('Failed to delete reciter downloads')),
          );
          return downloadsBloc;
        },
        act: (bloc) => bloc.add(
          const DeleteReciterDownloads(reciterName: testReciterName),
        ),
        expect: () => [
          const DownloadsState.loading(),
          const DownloadsState.error('Failed to delete reciter downloads'),
        ],
      );
    });

    group('ClearAllDownloads', () {
      blocTest<DownloadsBloc, DownloadsState>(
        'emits [loading, loaded] when clear is successful',
        build: () {
          when(
            mockClearAllDownloadsUseCase(),
          ).thenAnswer((_) async => const Right(null));
          when(
            mockGetDownloadsByReciterUseCase(),
          ).thenAnswer((_) async => const Right({}));
          when(
            mockAnalyticsService.logEvent(
              any,
              parameters: anyNamed('parameters'),
            ),
          ).thenAnswer((_) async {});
          return downloadsBloc;
        },
        act: (bloc) => bloc.add(const ClearAllDownloads()),
        expect: () => [
          const DownloadsState.loading(),
          const DownloadsState.loaded({}),
        ],
      );

      blocTest<DownloadsBloc, DownloadsState>(
        'emits [loading, error] when clear fails',
        build: () {
          when(mockClearAllDownloadsUseCase()).thenAnswer(
            (_) async =>
                const Left(AudioFailure('Failed to clear all downloads')),
          );
          return downloadsBloc;
        },
        act: (bloc) => bloc.add(const ClearAllDownloads()),
        expect: () => [
          const DownloadsState.loading(),
          const DownloadsState.error('Failed to clear all downloads'),
        ],
      );
    });

    group('CheckSurahDownloadedEvent', () {
      const testSurahId = '001';
      const testReciterName = 'Abdul Rahman Al-Sudais';

      blocTest<DownloadsBloc, DownloadsState>(
        'emits [surahDownloadStatus] when check is successful',
        build: () {
          when(
            mockDownloadsRepository.isSurahDownloaded(any, any),
          ).thenAnswer((_) async => true);
          return downloadsBloc;
        },
        act: (bloc) => bloc.add(
          const CheckSurahDownloadedEvent(
            surahId: testSurahId,
            reciterName: testReciterName,
          ),
        ),
        expect: () => [
          const DownloadsState.surahDownloadStatus(
            surahId: testSurahId,
            reciterName: testReciterName,
            isDownloaded: true,
          ),
        ],
      );

      blocTest<DownloadsBloc, DownloadsState>(
        'emits [error] when check fails',
        build: () {
          when(
            mockDownloadsRepository.isSurahDownloaded(any, any),
          ).thenThrow(Exception('Database error'));
          return downloadsBloc;
        },
        act: (bloc) => bloc.add(
          const CheckSurahDownloadedEvent(
            surahId: testSurahId,
            reciterName: testReciterName,
          ),
        ),
        expect: () => [
          const DownloadsState.error(
            'Failed to check download status: Exception: Database error',
          ),
        ],
      );
    });

    group('ValidateDownloadedFileEvent', () {
      const testDownloadId = '001_Abdul_Rahman_Al-Sudais';
      final testDownloadItem = DownloadItem(
        id: testDownloadId,
        title: 'Al-Fatiha',
        url: 'https://example.com/audio.mp3',
        filePath: '/path/to/file.mp3',
        reciterName: 'Abdul Rahman Al-Sudais',
        status: DownloadStatus.completed,
        progress: 1.0,
        fileSize: 1024000,
        downloadedSize: 1024000,
        createdAt: DateTime.now(),
      );

      blocTest<DownloadsBloc, DownloadsState>(
        'emits [fileValidationResult] when validation is successful',
        build: () {
          when(
            mockDownloadsRepository.getDownloadItem(any),
          ).thenAnswer((_) async => testDownloadItem);
          when(
            mockDownloadsRepository.validateDownloadedFile(any),
          ).thenAnswer((_) async => true);
          return downloadsBloc;
        },
        act: (bloc) => bloc.add(
          const ValidateDownloadedFileEvent(downloadId: testDownloadId),
        ),
        expect: () => [
          const DownloadsState.fileValidationResult(
            downloadId: testDownloadId,
            isValid: true,
          ),
        ],
      );

      blocTest<DownloadsBloc, DownloadsState>(
        'emits [error] when download item is not found',
        build: () {
          when(
            mockDownloadsRepository.getDownloadItem(any),
          ).thenAnswer((_) async => null);
          return downloadsBloc;
        },
        act: (bloc) => bloc.add(
          const ValidateDownloadedFileEvent(downloadId: testDownloadId),
        ),
        expect: () => [const DownloadsState.error('Download not found')],
      );

      blocTest<DownloadsBloc, DownloadsState>(
        'emits [error] when validation fails',
        build: () {
          when(
            mockDownloadsRepository.getDownloadItem(any),
          ).thenAnswer((_) async => testDownloadItem);
          when(
            mockDownloadsRepository.validateDownloadedFile(any),
          ).thenThrow(Exception('File validation error'));
          return downloadsBloc;
        },
        act: (bloc) => bloc.add(
          const ValidateDownloadedFileEvent(downloadId: testDownloadId),
        ),
        expect: () => [
          const DownloadsState.error(
            'Failed to validate file: Exception: File validation error',
          ),
        ],
      );
    });

    group('GetValidCompletedDownloadsEvent', () {
      const testReciterName = 'Abdul Rahman Al-Sudais';
      final testValidDownloads = [
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
      ];

      blocTest<DownloadsBloc, DownloadsState>(
        'emits [validDownloadsLoaded] when get is successful',
        build: () {
          when(
            mockDownloadsRepository.getValidCompletedDownloads(any),
          ).thenAnswer((_) async => testValidDownloads);
          return downloadsBloc;
        },
        act: (bloc) => bloc.add(
          const GetValidCompletedDownloadsEvent(reciterName: testReciterName),
        ),
        expect: () => [
          DownloadsState.validDownloadsLoaded(
            reciterName: testReciterName,
            validDownloads: testValidDownloads,
          ),
        ],
      );

      blocTest<DownloadsBloc, DownloadsState>(
        'emits [error] when get fails',
        build: () {
          when(
            mockDownloadsRepository.getValidCompletedDownloads(any),
          ).thenThrow(Exception('Database error'));
          return downloadsBloc;
        },
        act: (bloc) => bloc.add(
          const GetValidCompletedDownloadsEvent(reciterName: testReciterName),
        ),
        expect: () => [
          const DownloadsState.error(
            'Failed to get valid downloads: Exception: Database error',
          ),
        ],
      );
    });

    group('PlayDownloadedSurahEvent', () {
      const testDownloadId = '001_Abdul_Rahman_Al-Sudais';
      final testDownloadItem = DownloadItem(
        id: testDownloadId,
        title: 'Al-Fatiha',
        url: 'https://example.com/audio.mp3',
        filePath: '/path/to/file.mp3',
        reciterName: 'Abdul Rahman Al-Sudais',
        status: DownloadStatus.completed,
        progress: 1.0,
        fileSize: 1024000,
        downloadedSize: 1024000,
        createdAt: DateTime.now(),
      );

      blocTest<DownloadsBloc, DownloadsState>(
        'emits [playbackInitiated] when play is successful',
        build: () {
          when(
            mockDownloadsRepository.getDownloadItem(any),
          ).thenAnswer((_) async => testDownloadItem);
          when(
            mockDownloadsRepository.validateDownloadedFile(any),
          ).thenAnswer((_) async => true);
          when(
            mockDownloadsRepository.createMediaItemFromDownload(any),
          ).thenReturn(
            MediaItem(
              id: testDownloadId,
              title: testDownloadItem.title,
              artist: testDownloadItem.reciterName,
              duration: const Duration(minutes: 5),
              artUri: Uri.parse('https://example.com/art.jpg'),
              extras: {'filePath': testDownloadItem.filePath},
            ),
          );
          when(
            mockAudioPlayerHandler.updateQueue(any),
          ).thenAnswer((_) async {});
          when(mockAudioPlayerHandler.pause()).thenAnswer((_) async {});
          when(
            mockAudioPlayerHandler.skipToQueueItem(any),
          ).thenAnswer((_) async {});
          when(mockAudioPlayerHandler.play()).thenAnswer((_) async {});
          return downloadsBloc;
        },
        act: (bloc) => bloc.add(
          const PlayDownloadedSurahEvent(downloadId: testDownloadId),
        ),
        expect: () => [
          const DownloadsState.playbackInitiated(message: 'Playing Al-Fatiha'),
        ],
      );

      blocTest<DownloadsBloc, DownloadsState>(
        'emits [error] when download item is not found',
        build: () {
          when(
            mockDownloadsRepository.getDownloadItem(any),
          ).thenAnswer((_) async => null);
          return downloadsBloc;
        },
        act: (bloc) => bloc.add(
          const PlayDownloadedSurahEvent(downloadId: testDownloadId),
        ),
        expect: () => [const DownloadsState.error('Download not found')],
      );

      blocTest<DownloadsBloc, DownloadsState>(
        'emits [error] when file does not exist',
        build: () {
          when(
            mockDownloadsRepository.getDownloadItem(any),
          ).thenAnswer((_) async => testDownloadItem);
          when(
            mockDownloadsRepository.validateDownloadedFile(any),
          ).thenAnswer((_) async => false);
          return downloadsBloc;
        },
        act: (bloc) => bloc.add(
          const PlayDownloadedSurahEvent(downloadId: testDownloadId),
        ),
        expect: () => [const DownloadsState.error('Downloaded file not found')],
      );

      blocTest<DownloadsBloc, DownloadsState>(
        'emits [error] when play fails',
        build: () {
          when(
            mockDownloadsRepository.getDownloadItem(any),
          ).thenAnswer((_) async => testDownloadItem);
          when(
            mockDownloadsRepository.validateDownloadedFile(any),
          ).thenAnswer((_) async => true);
          when(
            mockDownloadsRepository.createMediaItemFromDownload(any),
          ).thenThrow(Exception('Media creation error'));
          return downloadsBloc;
        },
        act: (bloc) => bloc.add(
          const PlayDownloadedSurahEvent(downloadId: testDownloadId),
        ),
        expect: () => [
          const DownloadsState.error(
            'Error playing surah: Exception: Media creation error',
          ),
        ],
      );
    });

    group('PlayAllDownloadsEvent', () {
      const testReciterName = 'Abdul Rahman Al-Sudais';
      final testValidDownloads = [
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
      ];

      blocTest<DownloadsBloc, DownloadsState>(
        'emits [playbackInitiated] when play all is successful',
        build: () {
          when(
            mockDownloadsRepository.getValidCompletedDownloads(any),
          ).thenAnswer((_) async => testValidDownloads);
          when(
            mockDownloadsRepository.createMediaItemsFromDownloads(any),
          ).thenReturn([
            MediaItem(
              id: '001_Abdul_Rahman_Al-Sudais',
              title: 'Al-Fatiha',
              artist: 'Abdul Rahman Al-Sudais',
              duration: const Duration(minutes: 5),
              artUri: Uri.parse('https://example.com/art.jpg'),
              extras: {'filePath': '/path/to/file.mp3'},
            ),
          ]);
          when(
            mockAudioPlayerHandler.updateQueue(any),
          ).thenAnswer((_) async {});
          when(mockAudioPlayerHandler.pause()).thenAnswer((_) async {});
          when(
            mockAudioPlayerHandler.skipToQueueItem(any),
          ).thenAnswer((_) async {});
          when(mockAudioPlayerHandler.play()).thenAnswer((_) async {});
          return downloadsBloc;
        },
        act: (bloc) =>
            bloc.add(const PlayAllDownloadsEvent(reciterName: testReciterName)),
        expect: () => [
          const DownloadsState.playbackInitiated(
            message: 'Playing 1 surahs from Abdul Rahman Al-Sudais',
          ),
        ],
      );

      blocTest<DownloadsBloc, DownloadsState>(
        'emits [error] when no valid downloads found',
        build: () {
          when(
            mockDownloadsRepository.getValidCompletedDownloads(any),
          ).thenAnswer((_) async => []);
          return downloadsBloc;
        },
        act: (bloc) =>
            bloc.add(const PlayAllDownloadsEvent(reciterName: testReciterName)),
        expect: () => [
          const DownloadsState.error('No valid downloaded files found'),
        ],
      );

      blocTest<DownloadsBloc, DownloadsState>(
        'emits [error] when play all fails',
        build: () {
          when(
            mockDownloadsRepository.getValidCompletedDownloads(any),
          ).thenThrow(Exception('Database error'));
          return downloadsBloc;
        },
        act: (bloc) =>
            bloc.add(const PlayAllDownloadsEvent(reciterName: testReciterName)),
        expect: () => [
          const DownloadsState.error(
            'Error playing downloads: Exception: Database error',
          ),
        ],
      );
    });

    group('CheckPremiumAccessEvent', () {
      blocTest<DownloadsBloc, DownloadsState>(
        'emits [premiumRequired] when user does not have premium access',
        build: () {
          when(
            mockPremiumRepository.canDownload(),
          ).thenAnswer((_) async => false);
          return downloadsBloc;
        },
        act: (bloc) => bloc.add(const CheckPremiumAccessEvent()),
        expect: () => [
          const DownloadsState.premiumRequired(
            message:
                'Download feature requires premium subscription. Upgrade to unlock unlimited downloads!',
          ),
        ],
      );

      blocTest<DownloadsBloc, DownloadsState>(
        'emits nothing when user has premium access',
        build: () {
          when(
            mockPremiumRepository.canDownload(),
          ).thenAnswer((_) async => true);
          return downloadsBloc;
        },
        act: (bloc) => bloc.add(const CheckPremiumAccessEvent()),
        expect: () => [],
      );

      blocTest<DownloadsBloc, DownloadsState>(
        'emits [error] when check fails',
        build: () {
          when(
            mockPremiumRepository.canDownload(),
          ).thenThrow(Exception('Premium check error'));
          return downloadsBloc;
        },
        act: (bloc) => bloc.add(const CheckPremiumAccessEvent()),
        expect: () => [
          const DownloadsState.error(
            'Failed to check premium access: Exception: Premium check error',
          ),
        ],
      );
    });

    group('RetryDownloadEvent', () {
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

      blocTest<DownloadsBloc, DownloadsState>(
        'emits [downloadStarted, loaded] when retry is successful',
        build: () {
          when(
            mockDownloadsRepository.getDownloadItem(any),
          ).thenAnswer((_) async => testDownloadItem);
          when(
            mockPremiumRepository.canDownload(),
          ).thenAnswer((_) async => true);
          when(
            mockDownloadsRepository.retryDownload(any),
          ).thenAnswer((_) async {});
          when(
            mockGetDownloadsByReciterUseCase(),
          ).thenAnswer((_) async => const Right({}));
          when(
            mockAnalyticsService.logEvent(
              any,
              parameters: anyNamed('parameters'),
            ),
          ).thenAnswer((_) async {});
          return downloadsBloc;
        },
        act: (bloc) =>
            bloc.add(const RetryDownloadEvent(downloadId: testDownloadId)),
        expect: () => [
          const DownloadsState.downloadStarted(
            surahId: '001',
            surahTitle: 'Al-Fatiha',
            reciterName: 'Abdul Rahman Al-Sudais',
          ),
          const DownloadsState.loading(),
          const DownloadsState.loaded({}),
        ],
      );

      blocTest<DownloadsBloc, DownloadsState>(
        'emits [error] when download item is not found',
        build: () {
          when(
            mockDownloadsRepository.getDownloadItem(any),
          ).thenAnswer((_) async => null);
          return downloadsBloc;
        },
        act: (bloc) =>
            bloc.add(const RetryDownloadEvent(downloadId: testDownloadId)),
        expect: () => [const DownloadsState.error('Download not found')],
      );

      blocTest<DownloadsBloc, DownloadsState>(
        'emits [error] when download is not in failed status',
        build: () {
          final completedDownload = testDownloadItem.copyWith(
            status: DownloadStatus.completed,
          );
          when(
            mockDownloadsRepository.getDownloadItem(any),
          ).thenAnswer((_) async => completedDownload);
          return downloadsBloc;
        },
        act: (bloc) =>
            bloc.add(const RetryDownloadEvent(downloadId: testDownloadId)),
        expect: () => [
          const DownloadsState.error('Only failed downloads can be retried'),
        ],
      );

      blocTest<DownloadsBloc, DownloadsState>(
        'emits [premiumRequired] when user does not have premium access for retry',
        build: () {
          when(
            mockDownloadsRepository.getDownloadItem(any),
          ).thenAnswer((_) async => testDownloadItem);
          when(
            mockPremiumRepository.canDownload(),
          ).thenAnswer((_) async => false);
          return downloadsBloc;
        },
        act: (bloc) =>
            bloc.add(const RetryDownloadEvent(downloadId: testDownloadId)),
        expect: () => [
          const DownloadsState.premiumRequired(
            message:
                'Download feature requires premium subscription. Upgrade to unlock unlimited downloads!',
          ),
        ],
      );

      blocTest<DownloadsBloc, DownloadsState>(
        'emits [error] when retry fails',
        build: () {
          when(
            mockDownloadsRepository.getDownloadItem(any),
          ).thenAnswer((_) async => testDownloadItem);
          when(
            mockPremiumRepository.canDownload(),
          ).thenAnswer((_) async => true);
          when(
            mockDownloadsRepository.retryDownload(any),
          ).thenThrow(Exception('Retry failed'));
          when(
            mockAnalyticsService.logEvent(
              any,
              parameters: anyNamed('parameters'),
            ),
          ).thenAnswer((_) async {});
          return downloadsBloc;
        },
        act: (bloc) =>
            bloc.add(const RetryDownloadEvent(downloadId: testDownloadId)),
        expect: () => [
          const DownloadsState.downloadStarted(
            surahId: '001',
            surahTitle: 'Al-Fatiha',
            reciterName: 'Abdul Rahman Al-Sudais',
          ),
          const DownloadsState.error(
            'Failed to retry download: Exception: Retry failed',
          ),
        ],
      );
    });

    group('Edge Cases and Error Handling', () {
      blocTest<DownloadsBloc, DownloadsState>(
        'handles multiple rapid events correctly',
        build: () {
          when(
            mockGetDownloadsByReciterUseCase(),
          ).thenAnswer((_) async => const Right({}));
          when(
            mockPremiumRepository.canDownload(),
          ).thenAnswer((_) async => true);
          when(
            mockDownloadsRepository.isSurahDownloaded(any, any),
          ).thenAnswer((_) async => false);
          when(
            mockDownloadSurahUseCase(
              surahId: anyNamed('surahId'),
              surahTitle: anyNamed('surahTitle'),
              reciterName: anyNamed('reciterName'),
            ),
          ).thenAnswer((_) async => const Right(null));
          when(
            mockAnalyticsService.logDownloadStart(
              any,
              fileName: anyNamed('fileName'),
            ),
          ).thenAnswer((_) async {});
          when(
            mockAnalyticsService.logDownloadComplete(
              any,
              fileName: anyNamed('fileName'),
            ),
          ).thenAnswer((_) async {});
          return downloadsBloc;
        },
        act: (bloc) {
          bloc.add(const LoadDownloads());
          bloc.add(
            const DownloadSurahEvent(
              surahId: '001',
              surahTitle: 'Al-Fatiha',
              reciterName: 'Test Reciter',
            ),
          );
          bloc.add(const CheckPremiumAccessEvent());
        },
        expect: () => [
          const DownloadsState.loading(),
          const DownloadsState.loaded({}),
          const DownloadsState.downloadStarted(
            surahId: '001',
            surahTitle: 'Al-Fatiha',
            reciterName: 'Test Reciter',
          ),
          const DownloadsState.loading(),
          const DownloadsState.loaded({}),
        ],
      );

      blocTest<DownloadsBloc, DownloadsState>(
        'handles null failure messages gracefully',
        build: () {
          when(
            mockGetDownloadsByReciterUseCase(),
          ).thenAnswer((_) async => const Left(AudioFailure(null)));
          return downloadsBloc;
        },
        act: (bloc) => bloc.add(const LoadDownloads()),
        expect: () => [
          const DownloadsState.loading(),
          const DownloadsState.error('Failed to load downloads'),
        ],
      );
    });
  });
}
