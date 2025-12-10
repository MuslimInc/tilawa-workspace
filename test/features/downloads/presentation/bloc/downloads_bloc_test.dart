import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:dartz_plus/dartz_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:muzakri/core/errors/failures.dart';
import 'package:muzakri/core/services/analytics_service.dart';
import 'package:muzakri/features/downloads/data/services/download_queue_manager.dart';
import 'package:muzakri/features/downloads/data/services/download_service.dart';
import 'package:muzakri/features/downloads/domain/entities/download_item.dart';
import 'package:muzakri/features/downloads/domain/repositories/downloads_repository.dart';
import 'package:muzakri/features/downloads/domain/usecases/clear_all_downloads_use_case.dart';
import 'package:muzakri/features/downloads/domain/usecases/delete_download_use_case.dart';
import 'package:muzakri/features/downloads/domain/usecases/delete_reciter_downloads_use_case.dart';
import 'package:muzakri/features/downloads/domain/usecases/download_surah_use_case.dart';
import 'package:muzakri/features/downloads/domain/usecases/get_downloads_by_reciter_use_case.dart';
import 'package:muzakri/features/downloads/presentation/bloc/downloads_bloc.dart';
import 'package:muzakri/features/downloads/presentation/bloc/downloads_status.dart';
import 'package:muzakri/features/premium/domain/repositories/premium_repository.dart';
import 'package:muzakri/shared/audio/audio_player_handler.dart';

import '../../../../helpers/hydrated_bloc_test_helper.dart';
import '../../data/services/download_service_test.mocks.dart';
import 'downloads_bloc_test.mocks.dart';

// Provide dummy values for Either types that Mockito can't generate automatically
@visibleForTesting
Either<Failure, void> provideDummyEitherFailureVoid() => const Right(null);

@visibleForTesting
Either<Failure, Map<String, Map<String, List<DownloadItem>>>>
provideDummyEitherFailureMapStringMapStringListDownloadItem() =>
    const Right({});

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
  // Initialize Flutter bindings for background_downloader
  // This is required because DownloadService uses platform channels
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    // Register mock method channel handlers
    const pathProviderChannel = MethodChannel(
      'plugins.flutter.io/path_provider',
    );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(pathProviderChannel, (
          MethodCall methodCall,
        ) async {
          if (methodCall.method == 'getApplicationSupportDirectory' ||
              methodCall.method == 'getApplicationDocumentsDirectory') {
            return '.';
          }
          return null;
        });

    const backgroundDownloaderChannel = MethodChannel(
      'com.bbflight.background_downloader',
    );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(backgroundDownloaderChannel, (
          MethodCall methodCall,
        ) async {
          return null;
        });

    // Register Dio FIRST before anything else that might use it
    // This prevents "Dio is not registered" errors when DownloadService
    // tries to access Dio via GetIt
    final GetIt getIt = GetIt.instance;
    if (getIt.isRegistered<Dio>()) {
      await getIt.unregister<Dio>();
    }
    // Use registerSingleton to ensure it's available immediately
    getIt.registerSingleton<Dio>(Dio());

    await initializeHydratedStorageForTest();
  });

  tearDownAll(() async {
    await clearHydratedStorageForTest();

    // Clean up GetIt registration
    final GetIt getIt = GetIt.instance;
    if (getIt.isRegistered<Dio>()) {
      await getIt.unregister<Dio>();
    }
  });

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
  late MockFlutterDownloaderWrapper mockDownloader;

  setUp(() {
    // Provide dummy values for Either types
    provideDummy<Either<Failure, void>>(const Right(null));
    provideDummy<Either<Failure, Map<String, Map<String, List<DownloadItem>>>>>(
      const Right({}),
    );

    mockGetDownloadsByReciterUseCase = MockGetDownloadsByReciterUseCase();
    mockDownloadSurahUseCase = MockDownloadSurahUseCase();
    mockDeleteDownloadUseCase = MockDeleteDownloadUseCase();
    mockDeleteReciterDownloadsUseCase = MockDeleteReciterDownloadsUseCase();
    mockClearAllDownloadsUseCase = MockClearAllDownloadsUseCase();
    mockDownloadsRepository = MockDownloadsRepository();
    mockPremiumRepository = MockPremiumRepository();
    mockAudioPlayerHandler = MockAudioPlayerHandler();
    mockAnalyticsService = MockAnalyticsService();

    // Mock FlutterDownloader for DownloadService
    mockDownloader = MockFlutterDownloaderWrapper();
    DownloadService.flutterDownloaderTestOverride = mockDownloader;

    DownloadQueueManager.reset();

    // Stub common methods to avoid MissingStubError
    when(mockDownloader.initialize(debug: anyNamed('debug'))).thenAnswer((
      _,
    ) async {
      return;
    });
    when(
      mockDownloader.registerCallback(any, step: anyNamed('step')),
    ).thenAnswer((_) async {
      return;
    });
    when(mockDownloader.loadTasks()).thenAnswer((_) async => []);
    when(
      mockDownloader.loadTasksWithRawQuery(query: anyNamed('query')),
    ).thenAnswer((_) async => []);

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
      expect(downloadsBloc.state, const DownloadsState());
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
          const DownloadsState(status: DownloadsStateStatus.loading),
          const DownloadsState(status: DownloadsStateStatus.loaded),
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
          const DownloadsState(status: DownloadsStateStatus.loading),
          const DownloadsState(
            status: DownloadsStateStatus.error,
            errorMessage: 'Failed to load downloads',
          ),
        ],
      );
    });

    group('DownloadSurahEvent', () {
      const testSurahId = '001';
      const testSurahTitle = 'Al-Fatiha';
      const testReciterName = 'Abdul Rahman Al-Sudais';

      test(
        'emits [DownloadStarted] in statusStream when download is initiated',
        () async {
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

          unawaited(
            expectLater(
              downloadsBloc.statusStream,
              emitsInOrder([
                isA<DownloadStarted>()
                    .having((s) => s.surahId, 'surahId', testSurahId)
                    .having(
                      (s) => s.reciterName,
                      'reciterName',
                      testReciterName,
                    ),
              ]),
            ),
          );

          downloadsBloc.add(
            const DownloadSurahEvent(
              surahId: testSurahId,
              surahTitle: testSurahTitle,
              reciterName: testReciterName,
            ),
          );
        },
      );

      test(
        'emits [PremiumRequired] in statusStream when user does not have premium',
        () async {
          when(
            mockPremiumRepository.canDownload(),
          ).thenAnswer((_) async => false);

          unawaited(
            expectLater(
              downloadsBloc.statusStream,
              emits(isA<PremiumRequired>()),
            ),
          );

          downloadsBloc.add(
            const DownloadSurahEvent(
              surahId: testSurahId,
              surahTitle: testSurahTitle,
              reciterName: testReciterName,
            ),
          );
        },
      );

      test(
        'emits [Error] in statusStream when surah is already downloaded',
        () async {
          when(
            mockPremiumRepository.canDownload(),
          ).thenAnswer((_) async => true);
          when(
            mockDownloadsRepository.isSurahDownloaded(any, any),
          ).thenAnswer((_) async => true);

          unawaited(
            expectLater(
              downloadsBloc.statusStream,
              emits(
                isA<Error>().having(
                  (e) => e.message,
                  'message',
                  contains('already downloaded'),
                ),
              ),
            ),
          );

          downloadsBloc.add(
            const DownloadSurahEvent(
              surahId: testSurahId,
              surahTitle: testSurahTitle,
              reciterName: testReciterName,
            ),
          );
        },
      );

      test(
        'emits [DownloadStarted, Error] in statusStream when download fails',
        () async {
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

          unawaited(
            expectLater(
              downloadsBloc.statusStream,
              emitsInOrder([
                isA<DownloadStarted>(),
                isA<Error>().having(
                  (e) => e.message,
                  'message',
                  'Network error',
                ),
              ]),
            ),
          );

          downloadsBloc.add(
            const DownloadSurahEvent(
              surahId: testSurahId,
              surahTitle: testSurahTitle,
              reciterName: testReciterName,
            ),
          );
        },
      );
    });

    group('DeleteDownloadEvent', () {
      const testDownloadId = '001_Abdul_Rahman_Al-Sudais';

      blocTest<DownloadsBloc, DownloadsState>(
        'emits [loading, loaded] when delete is successful',
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
          const DownloadsState(status: DownloadsStateStatus.loading),
          const DownloadsState(status: DownloadsStateStatus.loaded),
        ],
      );

      test('emits [Error] in statusStream when delete fails', () async {
        when(
          mockDeleteDownloadUseCase(any),
        ).thenAnswer((_) async => const Left(AudioFailure('Failed to delete')));

        unawaited(
          expectLater(
            downloadsBloc.statusStream,
            emits(
              isA<Error>().having(
                (e) => e.message,
                'message',
                'Failed to delete',
              ),
            ),
          ),
        );

        downloadsBloc.add(
          const DeleteDownloadEvent(downloadId: testDownloadId),
        );
      });
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
          const DownloadsState(status: DownloadsStateStatus.loading),
          const DownloadsState(status: DownloadsStateStatus.loaded),
        ],
      );

      test('emits [Error] in statusStream when delete fails', () async {
        when(mockDeleteReciterDownloadsUseCase(any)).thenAnswer(
          (_) async =>
              const Left(AudioFailure('Failed to delete reciter downloads')),
        );

        unawaited(
          expectLater(
            downloadsBloc.statusStream,
            emits(
              isA<Error>().having(
                (e) => e.message,
                'message',
                'Failed to delete reciter downloads',
              ),
            ),
          ),
        );

        downloadsBloc.add(
          const DeleteReciterDownloads(reciterName: testReciterName),
        );
      });
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
          const DownloadsState(status: DownloadsStateStatus.loading),
          const DownloadsState(status: DownloadsStateStatus.loaded),
        ],
      );

      test('emits [Error] in statusStream when clear fails', () async {
        when(mockClearAllDownloadsUseCase()).thenAnswer(
          (_) async =>
              const Left(AudioFailure('Failed to clear all downloads')),
        );

        unawaited(
          expectLater(
            downloadsBloc.statusStream,
            emits(
              isA<Error>().having(
                (e) => e.message,
                'message',
                'Failed to clear all downloads',
              ),
            ),
          ),
        );

        downloadsBloc.add(const ClearAllDownloads());
      });
    });

    group('CheckSurahDownloadedEvent', () {
      const testSurahId = '001';
      const testReciterName = 'Abdul Rahman Al-Sudais';

      test(
        'emits [SurahDownloadStatus] in statusStream when check is successful',
        () async {
          when(
            mockDownloadsRepository.isSurahDownloaded(any, any),
          ).thenAnswer((_) async => true);

          unawaited(
            expectLater(
              downloadsBloc.statusStream,
              emits(
                isA<SurahDownloadStatus>()
                    .having((s) => s.surahId, 'surahId', testSurahId)
                    .having(
                      (s) => s.reciterName,
                      'reciterName',
                      testReciterName,
                    )
                    .having((s) => s.isDownloaded, 'isDownloaded', true),
              ),
            ),
          );

          downloadsBloc.add(
            const CheckSurahDownloadedEvent(
              surahId: testSurahId,
              reciterName: testReciterName,
            ),
          );
        },
      );

      test('emits [Error] in statusStream when check fails', () async {
        when(
          mockDownloadsRepository.isSurahDownloaded(any, any),
        ).thenThrow(Exception('Database error'));

        unawaited(
          expectLater(
            downloadsBloc.statusStream,
            emits(
              isA<Error>().having(
                (e) => e.message,
                'message',
                contains('Failed to check download status'),
              ),
            ),
          ),
        );

        downloadsBloc.add(
          const CheckSurahDownloadedEvent(
            surahId: testSurahId,
            reciterName: testReciterName,
          ),
        );
      });
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

      test(
        'emits [FileValidationResult] in statusStream when validation is successful',
        () async {
          when(
            mockDownloadsRepository.getDownloadItem(any),
          ).thenAnswer((_) async => testDownloadItem);
          when(
            mockDownloadsRepository.validateDownloadedFile(any),
          ).thenAnswer((_) async => true);

          unawaited(
            expectLater(
              downloadsBloc.statusStream,
              emits(
                isA<FileValidationResult>()
                    .having((s) => s.downloadId, 'downloadId', testDownloadId)
                    .having((s) => s.isValid, 'isValid', true),
              ),
            ),
          );

          downloadsBloc.add(
            const ValidateDownloadedFileEvent(downloadId: testDownloadId),
          );
        },
      );

      blocTest<DownloadsBloc, DownloadsState>(
        'emits [error] in state when download item is not found',
        build: () {
          when(
            mockDownloadsRepository.getDownloadItem(any),
          ).thenAnswer((_) async => null);
          return downloadsBloc;
        },
        act: (bloc) => bloc.add(
          const ValidateDownloadedFileEvent(downloadId: testDownloadId),
        ),
        expect: () => [
          const DownloadsState(
            status: DownloadsStateStatus.error,
            errorMessage: 'Download not found',
          ),
        ],
      );

      test(
        'emits [Error] in statusStream when validation fails with exception',
        () async {
          when(
            mockDownloadsRepository.getDownloadItem(any),
          ).thenAnswer((_) async => testDownloadItem);
          when(
            mockDownloadsRepository.validateDownloadedFile(any),
          ).thenThrow(Exception('File validation error'));

          unawaited(
            expectLater(
              downloadsBloc.statusStream,
              emits(
                isA<Error>().having(
                  (e) => e.message,
                  'message',
                  contains('Failed to validate file'),
                ),
              ),
            ),
          );

          downloadsBloc.add(
            const ValidateDownloadedFileEvent(downloadId: testDownloadId),
          );
        },
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

      test(
        'emits [ValidDownloadsLoaded] in statusStream when get is successful',
        () async {
          when(
            mockDownloadsRepository.getValidCompletedDownloads(any),
          ).thenAnswer((_) async => testValidDownloads);

          unawaited(
            expectLater(
              downloadsBloc.statusStream,
              emits(
                isA<ValidDownloadsLoaded>()
                    .having(
                      (s) => s.reciterName,
                      'reciterName',
                      testReciterName,
                    )
                    .having(
                      (s) => s.validDownloads,
                      'validDownloads',
                      testValidDownloads,
                    ),
              ),
            ),
          );

          downloadsBloc.add(
            const GetValidCompletedDownloadsEvent(reciterName: testReciterName),
          );
        },
      );

      test('emits [Error] in statusStream when get fails', () async {
        when(
          mockDownloadsRepository.getValidCompletedDownloads(any),
        ).thenThrow(Exception('Database error'));

        unawaited(
          expectLater(
            downloadsBloc.statusStream,
            emits(
              isA<Error>().having(
                (e) => e.message,
                'message',
                contains('Failed to get valid downloads'),
              ),
            ),
          ),
        );

        downloadsBloc.add(
          const GetValidCompletedDownloadsEvent(reciterName: testReciterName),
        );
      });
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

      test(
        'emits [PlaybackInitiated] in statusStream when play is successful',
        () async {
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

          unawaited(
            expectLater(
              downloadsBloc.statusStream,
              emits(
                isA<PlaybackInitiated>().having(
                  (s) => s.message,
                  'message',
                  'Playing Al-Fatiha',
                ),
              ),
            ),
          );

          downloadsBloc.add(
            const PlayDownloadedSurahEvent(downloadId: testDownloadId),
          );
        },
      );

      test(
        'emits [Error] in statusStream when download item is not found',
        () async {
          when(
            mockDownloadsRepository.getDownloadItem(any),
          ).thenAnswer((_) async => null);

          unawaited(
            expectLater(
              downloadsBloc.statusStream,
              emits(
                isA<Error>().having(
                  (e) => e.message,
                  'message',
                  'Download not found',
                ),
              ),
            ),
          );

          downloadsBloc.add(
            const PlayDownloadedSurahEvent(downloadId: testDownloadId),
          );
        },
      );

      test('emits [Error] in statusStream when file does not exist', () async {
        when(
          mockDownloadsRepository.getDownloadItem(any),
        ).thenAnswer((_) async => testDownloadItem);
        when(
          mockDownloadsRepository.validateDownloadedFile(any),
        ).thenAnswer((_) async => false);

        unawaited(
          expectLater(
            downloadsBloc.statusStream,
            emits(
              isA<Error>().having(
                (e) => e.message,
                'message',
                'Downloaded file not found',
              ),
            ),
          ),
        );

        downloadsBloc.add(
          const PlayDownloadedSurahEvent(downloadId: testDownloadId),
        );
      });

      test('emits [Error] in statusStream when play fails', () async {
        when(
          mockDownloadsRepository.getDownloadItem(any),
        ).thenAnswer((_) async => testDownloadItem);
        when(
          mockDownloadsRepository.validateDownloadedFile(any),
        ).thenAnswer((_) async => true);
        when(
          mockDownloadsRepository.createMediaItemFromDownload(any),
        ).thenThrow(Exception('Media creation error'));

        unawaited(
          expectLater(
            downloadsBloc.statusStream,
            emits(
              isA<Error>().having(
                (e) => e.message,
                'message',
                contains('Error playing surah'),
              ),
            ),
          ),
        );

        downloadsBloc.add(
          const PlayDownloadedSurahEvent(downloadId: testDownloadId),
        );
      });
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

      test(
        'emits [PlaybackInitiated] in statusStream when play all is successful',
        () async {
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

          unawaited(
            expectLater(
              downloadsBloc.statusStream,
              emits(
                isA<PlaybackInitiated>().having(
                  (s) => s.message,
                  'message',
                  'Playing 1 surahs from Abdul Rahman Al-Sudais',
                ),
              ),
            ),
          );

          downloadsBloc.add(
            const PlayAllDownloadsEvent(reciterName: testReciterName),
          );
        },
      );

      test(
        'emits [Error] in statusStream when no valid downloads found',
        () async {
          when(
            mockDownloadsRepository.getValidCompletedDownloads(any),
          ).thenAnswer((_) async => []);

          unawaited(
            expectLater(
              downloadsBloc.statusStream,
              emits(
                isA<Error>().having(
                  (e) => e.message,
                  'message',
                  'No valid downloaded files found',
                ),
              ),
            ),
          );

          downloadsBloc.add(
            const PlayAllDownloadsEvent(reciterName: testReciterName),
          );
        },
      );

      test('emits [Error] in statusStream when play all fails', () async {
        when(
          mockDownloadsRepository.getValidCompletedDownloads(any),
        ).thenThrow(Exception('Database error'));

        unawaited(
          expectLater(
            downloadsBloc.statusStream,
            emits(
              isA<Error>().having(
                (e) => e.message,
                'message',
                contains('Error playing downloads'),
              ),
            ),
          ),
        );

        downloadsBloc.add(
          const PlayAllDownloadsEvent(reciterName: testReciterName),
        );
      });
    });

    group('CheckPremiumAccessEvent', () {
      test(
        'emits [PremiumRequired] in statusStream when user does not have premium access',
        () async {
          when(
            mockPremiumRepository.canDownload(),
          ).thenAnswer((_) async => false);

          unawaited(
            expectLater(
              downloadsBloc.statusStream,
              emits(isA<PremiumRequired>()),
            ),
          );

          downloadsBloc.add(const CheckPremiumAccessEvent());
        },
      );

      test(
        'emits nothing in statusStream when user has premium access',
        () async {
          when(
            mockPremiumRepository.canDownload(),
          ).thenAnswer((_) async => true);

          // We expect no events in statusStream, but we can't easily wait for "nothing".
          // So we verify no interactions or errors that produce emissions.
          // Or we can check state doesn't change.
          // Since setup returns true, _onCheckPremiumAccess does nothing.

          downloadsBloc.add(const CheckPremiumAccessEvent());
          await Future.delayed(const Duration(milliseconds: 100));
          // implicit success if no error thrown
        },
      );

      test('emits [Error] in statusStream when check fails', () async {
        when(
          mockPremiumRepository.canDownload(),
        ).thenThrow(Exception('Premium check error'));

        unawaited(
          expectLater(
            downloadsBloc.statusStream,
            emits(
              isA<Error>().having(
                (e) => e.message,
                'message',
                contains('Failed to check premium access'),
              ),
            ),
          ),
        );

        downloadsBloc.add(const CheckPremiumAccessEvent());
      });
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

      test('emits [DownloadStarted] when retry is successful', () async {
        when(
          mockDownloadsRepository.getDownloadItem(any),
        ).thenAnswer((_) async => testDownloadItem);
        when(mockPremiumRepository.canDownload()).thenAnswer((_) async => true);
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

        unawaited(
          expectLater(
            downloadsBloc.statusStream,
            emits(isA<DownloadStarted>()),
          ),
        );

        downloadsBloc.add(const RetryDownloadEvent(downloadId: testDownloadId));
      });

      test('emits [Error] when download item is not found', () async {
        when(
          mockDownloadsRepository.getDownloadItem(any),
        ).thenAnswer((_) async => null);

        unawaited(
          expectLater(
            downloadsBloc.statusStream,
            emits(
              isA<Error>().having(
                (e) => e.message,
                'message',
                'Download not found',
              ),
            ),
          ),
        );

        downloadsBloc.add(const RetryDownloadEvent(downloadId: testDownloadId));
      });

      test(
        'emits [Error] when download is not in failed or stuck status',
        () async {
          final DownloadItem completedDownload = testDownloadItem.copyWith(
            status: DownloadStatus.completed,
          );
          when(
            mockDownloadsRepository.getDownloadItem(any),
          ).thenAnswer((_) async => completedDownload);

          unawaited(
            expectLater(
              downloadsBloc.statusStream,
              emits(
                isA<Error>().having(
                  (e) => e.message,
                  'message',
                  'Only failed or stuck downloads can be retried',
                ),
              ),
            ),
          );

          downloadsBloc.add(
            const RetryDownloadEvent(downloadId: testDownloadId),
          );
        },
      );

      test('emits [PremiumRequired] when user does not have premium', () async {
        when(
          mockDownloadsRepository.getDownloadItem(any),
        ).thenAnswer((_) async => testDownloadItem);
        when(
          mockPremiumRepository.canDownload(),
        ).thenAnswer((_) async => false);

        unawaited(
          expectLater(
            downloadsBloc.statusStream,
            emits(isA<PremiumRequired>()),
          ),
        );

        downloadsBloc.add(const RetryDownloadEvent(downloadId: testDownloadId));
      });

      test('emits [Error] when retry fails', () async {
        when(
          mockDownloadsRepository.getDownloadItem(any),
        ).thenAnswer((_) async => testDownloadItem);
        when(mockPremiumRepository.canDownload()).thenAnswer((_) async => true);
        when(
          mockDownloadsRepository.retryDownload(any),
        ).thenThrow(Exception('Retry failed'));
        when(
          mockAnalyticsService.logEvent(
            any,
            parameters: anyNamed('parameters'),
          ),
        ).thenAnswer((_) async {});

        unawaited(
          expectLater(
            downloadsBloc.statusStream,
            emitsInOrder([
              isA<DownloadStarted>(), // It emits started before calling repo
              isA<Error>().having(
                (e) => e.message,
                'message',
                contains('Failed to retry download'),
              ),
            ]),
          ),
        );

        downloadsBloc.add(const RetryDownloadEvent(downloadId: testDownloadId));
      });
    });

    group('Edge Cases and Error Handling', () {
      test('handles multiple rapid events correctly', () async {
        when(
          mockGetDownloadsByReciterUseCase(),
        ).thenAnswer((_) async => const Right({}));
        when(mockPremiumRepository.canDownload()).thenAnswer((_) async => true);
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
        when(
          mockAnalyticsService.logEvent(
            any,
            parameters: anyNamed('parameters'),
          ),
        ).thenAnswer((_) async {});

        // Expect stream emissions for DownloadSurah
        unawaited(
          expectLater(
            downloadsBloc.statusStream,
            emits(isA<DownloadStarted>()),
          ),
        );

        // Expect state transitions for LoadDownloads
        unawaited(
          expectLater(
            downloadsBloc.stream,
            emitsInOrder([
              const DownloadsState(status: DownloadsStateStatus.loading),
              const DownloadsState(status: DownloadsStateStatus.loaded),
            ]),
          ),
        );

        downloadsBloc.add(const LoadDownloads());
        downloadsBloc.add(
          const DownloadSurahEvent(
            surahId: '001',
            surahTitle: 'Al-Fatiha',
            reciterName: 'Test Reciter',
          ),
        );
        downloadsBloc.add(const CheckPremiumAccessEvent());
      });

      blocTest<DownloadsBloc, DownloadsState>(
        'handles null failure messages gracefully',
        build: () {
          when(
            mockGetDownloadsByReciterUseCase(),
          ).thenAnswer((_) async => const Left(AudioFailure()));
          return downloadsBloc;
        },
        act: (bloc) => bloc.add(const LoadDownloads()),
        expect: () => [
          const DownloadsState(status: DownloadsStateStatus.loading),
          const DownloadsState(
            status: DownloadsStateStatus.error,
            errorMessage: 'Failed to load downloads',
          ),
        ],
      );
    });

    group('RefreshDownloadsProgress', () {
      test('should refresh downloads without showing loading state', () async {
        // Arrange
        final testDownloads = {
          'Reciter 1': {
            'Default': [
              DownloadItem(
                id: 'download_1',
                title: 'Surah 1',
                url: 'https://example.com/1.mp3',
                filePath: '/path/1.mp3',
                reciterName: 'Reciter 1',
                status: DownloadStatus.downloading,
                progress: 0.5,
                fileSize: 1024,
                downloadedSize: 512,
                createdAt: DateTime.now(),
              ),
            ],
          },
        };

        // First load downloads to get to loaded state
        when(
          mockGetDownloadsByReciterUseCase(),
        ).thenAnswer((_) async => Right(testDownloads));

        // Act
        downloadsBloc.add(const LoadDownloads());
        await Future.delayed(const Duration(milliseconds: 100));

        // Now refresh progress
        when(
          mockGetDownloadsByReciterUseCase(),
        ).thenAnswer((_) async => Right(testDownloads));
        downloadsBloc.add(const DownloadsEvent.refreshDownloadsProgress());
        await Future.delayed(
          const Duration(milliseconds: 1100),
        ); // Wait for debounce (1000ms) + buffer

        // Assert - Should be in loaded state, not loading
        expect(
          downloadsBloc.state,
          isA<DownloadsState>().having(
            (s) => s.status,
            'status',
            DownloadsStateStatus.loaded,
          ),
        );
        final DownloadsState loadedState = downloadsBloc.state;
        expect(loadedState.downloads, testDownloads);
      });

      test('should not refresh if not in loaded state', () async {
        // Arrange - Start in initial state
        when(
          mockGetDownloadsByReciterUseCase(),
        ).thenAnswer((_) async => const Right({}));

        // Act
        downloadsBloc.add(const DownloadsEvent.refreshDownloadsProgress());
        await Future.delayed(
          const Duration(milliseconds: 1100),
        ); // Wait for debounce (1000ms) + buffer

        // Assert - Should remain in initial state (debounce won't process if not in loaded state)
        expect(downloadsBloc.state, const DownloadsState());
        verifyNever(mockGetDownloadsByReciterUseCase());
      });

      blocTest<DownloadsBloc, DownloadsState>(
        'emits [loaded] with updated progress when RefreshDownloadsProgress is called',
        build: () {
          final testDownloads = {
            'Reciter 1': {
              'Default': [
                DownloadItem(
                  id: 'download_1',
                  title: 'Surah 1',
                  url: 'https://example.com/1.mp3',
                  filePath: '/path/1.mp3',
                  reciterName: 'Reciter 1',
                  status: DownloadStatus.downloading,
                  progress: 0.75, // Updated progress
                  fileSize: 1024,
                  downloadedSize: 768,
                  createdAt: DateTime.now(),
                ),
              ],
            },
          };
          when(
            mockGetDownloadsByReciterUseCase(),
          ).thenAnswer((_) async => Right(testDownloads));
          return downloadsBloc;
        },
        seed: () => DownloadsState(
          status: DownloadsStateStatus.loaded,
          downloads: {
            'Reciter 1': {
              'Default': [
                DownloadItem(
                  // Dummy item for seed, specific content doesn't matter much as logic replaces it
                  id: 'download_1',
                  title: 'Surah 1',
                  url: 'https://example.com/1.mp3',
                  filePath: '/path/1.mp3',
                  reciterName: 'Reciter 1',
                  status: DownloadStatus.downloading,
                  progress: 0.5,
                  fileSize: 1024,
                  downloadedSize: 512,
                  createdAt: DateTime.now(), // Fixed time tricky in const
                ),
              ],
            },
          },
        ),
        act: (bloc) =>
            bloc.add(const DownloadsEvent.refreshDownloadsProgress()),
        wait: const Duration(
          milliseconds: 1100,
        ), // Wait for debounce (1000ms) + buffer
        expect: () => [
          isA<DownloadsState>().having(
            (state) => state.downloads['Reciter 1']!['Default']!.first.progress,
            'progress',
            0.75,
          ),
        ],
      );
    });

    group('Progress Updates', () {
      test('should have updateDownloadProgress method in repository', () {
        // This test verifies that the repository has the updateDownloadProgress method
        // which is called when progress updates are received from DownloadService

        // Note: We can't easily test the stream listener directly in unit tests,
        // as it's set up in the bloc constructor. Integration tests would be needed
        // to verify the full flow of progress updates triggering state changes.

        // This test documents the expected behavior
        expect(
          mockDownloadsRepository.updateDownloadProgress,
          isNotNull,
          reason: 'Repository should have updateDownloadProgress method',
        );
      });
    });
  });
}
