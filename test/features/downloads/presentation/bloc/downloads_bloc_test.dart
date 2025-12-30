import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:dartz_plus/dartz_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mockito/mockito.dart';
import 'package:tilawa/core/errors/failures.dart';
import 'package:tilawa/features/downloads/data/models/download_progress.dart';
import 'package:tilawa/features/downloads/data/services/download_notification_service.dart';
import 'package:tilawa/features/downloads/data/services/download_queue_manager.dart';
import 'package:tilawa/features/downloads/data/services/download_service_impl.dart';
import 'package:tilawa/features/downloads/data/services/download_service_interface.dart';
import 'package:tilawa/features/downloads/domain/entities/download_item.dart';
import 'package:tilawa/features/downloads/presentation/bloc/downloads_bloc.dart';
import 'package:tilawa/features/downloads/presentation/bloc/downloads_status.dart';

import '../../../../helpers/hydrated_bloc_test_helper.dart';
import '../../helpers/mock_helper.mocks.dart';

// Provide dummy values for Either types that Mockito can't generate automatically
@visibleForTesting
Either<Failure, void> provideDummyEitherFailureVoid() => const Right(null);

@visibleForTesting
Either<Failure, Map<String, Map<String, List<DownloadItem>>>>
provideDummyEitherFailureMapStringMapStringListDownloadItem() =>
    const Right({});

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
    if (getIt.isRegistered<DownloadNotificationService>()) {
      await getIt.unregister<DownloadNotificationService>();
    }
    if (getIt.isRegistered<DownloadServiceInterface>()) {
      await getIt.unregister<DownloadServiceInterface>();
    }
    if (getIt.isRegistered<DownloadQueueManager>()) {
      try {
        await getIt.unregister<DownloadQueueManager>();
      } catch (_) {}
    }
  });

  late DownloadsBloc downloadsBloc;
  late MockGetDownloadsByReciterUseCase mockGetDownloadsByReciterUseCase;
  late MockGetTotalDownloadsSizeUseCase mockGetTotalDownloadsSizeUseCase;
  late MockDownloadSurahUseCase mockDownloadSurahUseCase;
  late MockDeleteDownloadUseCase mockDeleteDownloadUseCase;
  late MockDeleteReciterDownloadsUseCase mockDeleteReciterDownloadsUseCase;
  late MockClearAllDownloadsUseCase mockClearAllDownloadsUseCase;
  late MockCheckSurahDownloadedUseCase mockCheckSurahDownloadedUseCase;
  late MockValidateDownloadedFileUseCase mockValidateDownloadedFileUseCase;
  late MockGetValidCompletedDownloadsUseCase
  mockGetValidCompletedDownloadsUseCase;
  late MockCheckDownloadAccessUseCase mockCheckDownloadAccessUseCase;
  late MockPlayDownloadUseCase mockPlayDownloadUseCase;
  late MockPlayAllDownloadsUseCase mockPlayAllDownloadsUseCase;
  late MockRetryDownloadUseCase mockRetryDownloadUseCase;
  late MockGetDownloadItemUseCase mockGetDownloadItemUseCase;
  late MockCancelDownloadUseCase mockCancelDownloadUseCase;
  late MockDownloadNotificationService mockDownloadNotificationService;
  late MockObserveGlobalDownloadProgressUseCase
  mockObserveGlobalDownloadProgressUseCase;
  late MockGetDownloadStatusUseCase mockGetDownloadStatusUseCase;
  late MockRemoveFromDownloadQueueUseCase mockRemoveFromDownloadQueueUseCase;
  late MockFlutterDownloaderWrapper mockDownloader;

  setUp(() {
    // Provide dummy values for Either types
    provideDummy<Either<Failure, void>>(const Right(null));
    provideDummy<Either<Failure, Map<String, Map<String, List<DownloadItem>>>>>(
      const Right({}),
    );
    provideDummy<Either<Failure, int>>(const Right(0));
    provideDummy<Either<Failure, bool>>(const Right(true));
    provideDummy<Either<Failure, DownloadItem?>>(const Right(null));
    provideDummy<Either<Failure, List<DownloadItem>>>(const Right([]));

    mockGetDownloadsByReciterUseCase = MockGetDownloadsByReciterUseCase();
    mockGetTotalDownloadsSizeUseCase = MockGetTotalDownloadsSizeUseCase();
    mockDownloadSurahUseCase = MockDownloadSurahUseCase();
    mockDeleteDownloadUseCase = MockDeleteDownloadUseCase();
    mockDeleteReciterDownloadsUseCase = MockDeleteReciterDownloadsUseCase();
    mockClearAllDownloadsUseCase = MockClearAllDownloadsUseCase();
    mockCheckSurahDownloadedUseCase = MockCheckSurahDownloadedUseCase();
    mockValidateDownloadedFileUseCase = MockValidateDownloadedFileUseCase();
    mockGetValidCompletedDownloadsUseCase =
        MockGetValidCompletedDownloadsUseCase();
    mockCheckDownloadAccessUseCase = MockCheckDownloadAccessUseCase();
    mockPlayDownloadUseCase = MockPlayDownloadUseCase();
    mockPlayAllDownloadsUseCase = MockPlayAllDownloadsUseCase();
    mockRetryDownloadUseCase = MockRetryDownloadUseCase();
    mockGetDownloadItemUseCase = MockGetDownloadItemUseCase();
    mockCancelDownloadUseCase = MockCancelDownloadUseCase();
    mockDownloadNotificationService = MockDownloadNotificationService();
    mockObserveGlobalDownloadProgressUseCase =
        MockObserveGlobalDownloadProgressUseCase();
    mockGetDownloadStatusUseCase = MockGetDownloadStatusUseCase();
    mockRemoveFromDownloadQueueUseCase = MockRemoveFromDownloadQueueUseCase();

    // Explicitly unregister potential conflicts first
    if (GetIt.I.isRegistered<DownloadNotificationService>()) {
      GetIt.I.unregister<DownloadNotificationService>();
    }
    if (GetIt.I.isRegistered<DownloadServiceInterface>()) {
      GetIt.I.unregister<DownloadServiceInterface>();
    }
    if (GetIt.I.isRegistered<DownloadQueueManager>()) {
      GetIt.I.unregister<DownloadQueueManager>();
    }

    GetIt.I.registerSingleton<DownloadNotificationService>(
      mockDownloadNotificationService,
    );

    when(mockDownloadNotificationService.initialize()).thenAnswer((_) async {});
    when(
      mockDownloadNotificationService.showDownloadProgress(
        downloadId: anyNamed('downloadId'),
        title: anyNamed('title'),
        reciterName: anyNamed('reciterName'),
        progress: anyNamed('progress'),
        status: anyNamed('status'),
        pendingMessage: anyNamed('pendingMessage'),
        progressMessage: anyNamed('progressMessage'),
        completeMessage: anyNamed('completeMessage'),
        failedMessage: anyNamed('failedMessage'),
      ),
    ).thenAnswer((_) async {});
    when(
      mockDownloadNotificationService.cancelNotification(any),
    ).thenAnswer((_) async {});

    // Mock FlutterDownloader for DownloadService
    mockDownloader = MockFlutterDownloaderWrapper();

    // Register mocked DownloadService
    final mockDownloadService = DownloadServiceImpl(
      MockFlutterDownloaderWrapper(),
      MockDownloadFileHelper(),
      MockDownloadStatusMapper(),
      MockDownloadIsolateManager(),
    );
    GetIt.I.registerSingleton<DownloadServiceInterface>(mockDownloadService);

    // Initialize DownloadQueueManager for testing with mocked service
    if (GetIt.I.isRegistered<DownloadQueueManager>()) {
      GetIt.I.unregister<DownloadQueueManager>();
    }
    GetIt.I.registerSingleton<DownloadQueueManager>(
      DownloadQueueManager(
        mockDownloadService,
        mockDownloadNotificationService,
      ),
    );

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

    when(
      mockGetTotalDownloadsSizeUseCase(any),
    ).thenAnswer((_) async => const Right(0));

    when(
      mockCheckSurahDownloadedUseCase(
        surahId: anyNamed('surahId'),
        reciterName: anyNamed('reciterName'),
      ),
    ).thenAnswer((_) async => const Right(false));

    when(mockGetDownloadStatusUseCase(any)).thenAnswer((_) async => null);

    when(
      mockCheckDownloadAccessUseCase(any),
    ).thenAnswer((_) async => const Right(true));

    mockObserveGlobalDownloadProgressUseCase =
        MockObserveGlobalDownloadProgressUseCase();

    // Stub global progress observation
    when(
      mockObserveGlobalDownloadProgressUseCase(),
    ).thenAnswer((_) => const Stream.empty());

    downloadsBloc = DownloadsBloc(
      getDownloadsByReciter: mockGetDownloadsByReciterUseCase,
      downloadSurah: mockDownloadSurahUseCase,
      deleteDownload: mockDeleteDownloadUseCase,
      deleteReciterDownloads: mockDeleteReciterDownloadsUseCase,
      clearAllDownloads: mockClearAllDownloadsUseCase,
      getTotalDownloadsSize: mockGetTotalDownloadsSizeUseCase,
      checkSurahDownloaded: mockCheckSurahDownloadedUseCase,
      validateDownloadedFile: mockValidateDownloadedFileUseCase,
      getValidCompletedDownloads: mockGetValidCompletedDownloadsUseCase,
      checkDownloadAccess: mockCheckDownloadAccessUseCase,
      playDownload: mockPlayDownloadUseCase,
      playAllDownloads: mockPlayAllDownloadsUseCase,
      retryDownload: mockRetryDownloadUseCase,
      getDownloadItem: mockGetDownloadItemUseCase,
      cancelDownload: mockCancelDownloadUseCase,
      observeGlobalDownloadProgress: mockObserveGlobalDownloadProgressUseCase,
      getDownloadStatus: mockGetDownloadStatusUseCase,
      removeFromDownloadQueue: mockRemoveFromDownloadQueueUseCase,
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
          when(
            mockGetTotalDownloadsSizeUseCase(any),
          ).thenAnswer((_) async => const Right(0));
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
      const testReciterId = 1;

      test(
        'emits [DownloadStarted] in statusStream when download is initiated',
        () async {
          when(
            mockCheckDownloadAccessUseCase(any),
          ).thenAnswer((_) async => const Right(true));
          when(
            mockCheckSurahDownloadedUseCase(
              surahId: anyNamed('surahId'),
              reciterName: anyNamed('reciterName'),
            ),
          ).thenAnswer((_) async => const Right(false));
          when(
            mockDownloadSurahUseCase(
              surahId: anyNamed('surahId'),
              surahTitle: anyNamed('surahTitle'),
              reciterName: anyNamed('reciterName'),
              reciterId: anyNamed('reciterId'),
            ),
          ).thenAnswer((_) async => const Right(null));
          when(
            mockGetDownloadsByReciterUseCase(),
          ).thenAnswer((_) async => const Right({}));

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
              reciterId: testReciterId,
            ),
          );
        },
      );

      test(
        'emits [PremiumRequired] in statusStream when user does not have premium',
        () async {
          when(
            mockCheckDownloadAccessUseCase(any),
          ).thenAnswer((_) async => const Right(false));

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
              reciterId: testReciterId,
            ),
          );
        },
      );

      test(
        'emits [Error] in statusStream when surah is already downloaded',
        () async {
          when(
            mockCheckDownloadAccessUseCase(any),
          ).thenAnswer((_) async => const Right(true));
          when(
            mockCheckSurahDownloadedUseCase(
              surahId: anyNamed('surahId'),
              reciterName: anyNamed('reciterName'),
            ),
          ).thenAnswer((_) async => const Right(true));

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
              reciterId: testReciterId,
            ),
          );
        },
      );

      test('emits [Error] in statusStream when surah is paused', () async {
        when(
          mockCheckDownloadAccessUseCase(any),
        ).thenAnswer((_) async => const Right(true));
        when(
          mockCheckSurahDownloadedUseCase(
            surahId: anyNamed('surahId'),
            reciterName: anyNamed('reciterName'),
          ),
        ).thenAnswer((_) async => const Right(false));
        when(
          mockGetDownloadStatusUseCase(any),
        ).thenAnswer((_) async => DownloadStatus.paused);

        unawaited(
          expectLater(
            downloadsBloc.statusStream,
            emits(
              isA<Error>().having(
                (e) => e.message,
                'message',
                contains('already being downloaded'),
              ),
            ),
          ),
        );

        downloadsBloc.add(
          const DownloadSurahEvent(
            surahId: testSurahId,
            surahTitle: testSurahTitle,
            reciterName: testReciterName,
            reciterId: testReciterId,
          ),
        );
      });

      test(
        'emits [DownloadStarted, Error] in statusStream when download fails',
        () async {
          when(
            mockCheckDownloadAccessUseCase(any),
          ).thenAnswer((_) async => const Right(true));
          when(
            mockCheckSurahDownloadedUseCase(
              surahId: anyNamed('surahId'),
              reciterName: anyNamed('reciterName'),
            ),
          ).thenAnswer((_) async => const Right(false));
          when(
            mockDownloadSurahUseCase(
              surahId: anyNamed('surahId'),
              surahTitle: anyNamed('surahTitle'),
              reciterName: anyNamed('reciterName'),
              reciterId: anyNamed('reciterId'),
            ),
          ).thenAnswer((_) async => const Left(AudioFailure('Network error')));

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
              reciterId: testReciterId,
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

      test('handles cancel download error before deletion', () async {
        when(
          mockGetDownloadStatusUseCase(any),
        ).thenAnswer((_) async => DownloadStatus.downloading);
        when(
          mockCancelDownloadUseCase(any),
        ).thenAnswer((_) async => const Left(AudioFailure('Cancel failed')));
        when(
          mockDeleteDownloadUseCase(any),
        ).thenAnswer((_) async => const Right(null));
        when(
          mockGetDownloadsByReciterUseCase(),
        ).thenAnswer((_) async => const Right({}));

        // Should still proceed with deletion even if cancel fails
        downloadsBloc.add(
          const DeleteDownloadEvent(downloadId: testDownloadId),
        );

        await Future.delayed(const Duration(milliseconds: 100));
        verify(mockCancelDownloadUseCase(any)).called(1);
        verify(mockDeleteDownloadUseCase(any)).called(1);
      });

      test(
        'handles exception when checking download status before deletion',
        () async {
          when(
            mockGetDownloadStatusUseCase(any),
          ).thenThrow(Exception('Status check failed'));
          when(
            mockDeleteDownloadUseCase(any),
          ).thenAnswer((_) async => const Right(null));
          when(
            mockGetDownloadsByReciterUseCase(),
          ).thenAnswer((_) async => const Right({}));

          // Should still proceed with deletion even if status check throws
          downloadsBloc.add(
            const DeleteDownloadEvent(downloadId: testDownloadId),
          );

          await Future.delayed(const Duration(milliseconds: 100));
          verify(mockDeleteDownloadUseCase(any)).called(1);
        },
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
            mockCheckSurahDownloadedUseCase(
              surahId: anyNamed('surahId'),
              reciterName: anyNamed('reciterName'),
            ),
          ).thenAnswer((_) async => const Right(true));

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
          mockCheckSurahDownloadedUseCase(
            surahId: anyNamed('surahId'),
            reciterName: anyNamed('reciterName'),
          ),
        ).thenAnswer((_) async => const Left(ServerFailure('Database error')));

        unawaited(
          expectLater(
            downloadsBloc.statusStream,
            emits(
              isA<Error>().having(
                (e) => e.message,
                'message',
                contains('Database error'),
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
            mockGetDownloadItemUseCase(any),
          ).thenAnswer((_) async => Right(testDownloadItem));
          when(
            mockValidateDownloadedFileUseCase(any),
          ).thenAnswer((_) async => const Right(true));

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
            mockGetDownloadItemUseCase(any),
          ).thenAnswer((_) async => const Right(null));
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
            mockGetDownloadItemUseCase(any),
          ).thenAnswer((_) async => Right(testDownloadItem));
          when(mockValidateDownloadedFileUseCase(any)).thenAnswer(
            (_) async => const Left(ServerFailure('File validation error')),
          );

          unawaited(
            expectLater(
              downloadsBloc.statusStream,
              emits(
                isA<Error>().having(
                  (e) => e.message,
                  'message',
                  contains('File validation error'),
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
            mockGetValidCompletedDownloadsUseCase(any),
          ).thenAnswer((_) async => Right(testValidDownloads));

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
          mockGetValidCompletedDownloadsUseCase(any),
        ).thenAnswer((_) async => const Left(ServerFailure('Database error')));

        unawaited(
          expectLater(
            downloadsBloc.statusStream,
            emits(
              isA<Error>().having(
                (e) => e.message,
                'message',
                contains('Database error'),
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
            mockGetDownloadItemUseCase(any),
          ).thenAnswer((_) async => Right(testDownloadItem));
          when(
            mockValidateDownloadedFileUseCase(any),
          ).thenAnswer((_) async => const Right(true));
          when(
            mockPlayDownloadUseCase(any),
          ).thenAnswer((_) async => const Right(null));

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
            mockGetDownloadItemUseCase(any),
          ).thenAnswer((_) async => const Right(null));

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
          mockGetDownloadItemUseCase(any),
        ).thenAnswer((_) async => Right(testDownloadItem));
        when(
          mockValidateDownloadedFileUseCase(any),
        ).thenAnswer((_) async => const Right(false));

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
          mockGetDownloadItemUseCase(any),
        ).thenAnswer((_) async => Right(testDownloadItem));
        when(
          mockValidateDownloadedFileUseCase(any),
        ).thenAnswer((_) async => const Right(true));
        when(mockPlayDownloadUseCase(any)).thenAnswer(
          (_) async => const Left(ServerFailure('Error playing surah')),
        );

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
            mockGetValidCompletedDownloadsUseCase(any),
          ).thenAnswer((_) async => Right(testValidDownloads));
          when(
            mockPlayAllDownloadsUseCase(any),
          ).thenAnswer((_) async => const Right(null));

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
            mockGetValidCompletedDownloadsUseCase(any),
          ).thenAnswer((_) async => const Right([]));

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
          mockGetValidCompletedDownloadsUseCase(any),
        ).thenAnswer((_) async => Right(testValidDownloads));
        when(mockPlayAllDownloadsUseCase(any)).thenAnswer(
          (_) async => const Left(ServerFailure('Error playing downloads')),
        );

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
            mockCheckDownloadAccessUseCase(any),
          ).thenAnswer((_) async => const Right(false));

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
            mockCheckDownloadAccessUseCase(any),
          ).thenAnswer((_) async => const Right(true));

          downloadsBloc.add(const CheckPremiumAccessEvent());
          await Future.delayed(const Duration(milliseconds: 100));
        },
      );

      test('emits [Error] in statusStream when check fails', () async {
        when(mockCheckDownloadAccessUseCase(any)).thenAnswer(
          (_) async => const Left(ServerFailure('Premium check error')),
        );

        unawaited(
          expectLater(
            downloadsBloc.statusStream,
            emits(
              isA<Error>().having(
                (e) => e.message,
                'message',
                contains('Premium check error'),
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
          mockGetDownloadItemUseCase(any),
        ).thenAnswer((_) async => Right(testDownloadItem));
        when(
          mockCheckDownloadAccessUseCase(any),
        ).thenAnswer((_) async => const Right(true));
        when(
          mockRetryDownloadUseCase(any),
        ).thenAnswer((_) async => const Right(null));
        when(
          mockGetDownloadsByReciterUseCase(),
        ).thenAnswer((_) async => const Right({}));

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
          mockGetDownloadItemUseCase(any),
        ).thenAnswer((_) async => const Right(null));

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
            mockGetDownloadItemUseCase(any),
          ).thenAnswer((_) async => Right(completedDownload));

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
          mockGetDownloadItemUseCase(any),
        ).thenAnswer((_) async => Right(testDownloadItem));
        when(
          mockCheckDownloadAccessUseCase(any),
        ).thenAnswer((_) async => const Right(false));

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
          mockGetDownloadItemUseCase(any),
        ).thenAnswer((_) async => Right(testDownloadItem));
        when(
          mockCheckDownloadAccessUseCase(any),
        ).thenAnswer((_) async => const Right(true));
        when(
          mockRetryDownloadUseCase(any),
        ).thenAnswer((_) async => const Left(ServerFailure('Retry failed')));

        unawaited(
          expectLater(
            downloadsBloc.statusStream,
            emitsThrough(
              isA<Error>().having(
                (e) => e.message,
                'message',
                contains('Retry failed'),
              ),
            ),
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
        when(
          mockCheckDownloadAccessUseCase(any),
        ).thenAnswer((_) async => const Right(true));
        when(
          mockCheckSurahDownloadedUseCase(
            surahId: anyNamed('surahId'),
            reciterName: anyNamed('reciterName'),
          ),
        ).thenAnswer((_) async => const Right(false));
        when(
          mockDownloadSurahUseCase(
            surahId: anyNamed('surahId'),
            surahTitle: anyNamed('surahTitle'),
            reciterName: anyNamed('reciterName'),
            reciterId: anyNamed('reciterId'),
          ),
        ).thenAnswer((_) async => const Right(null));

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
            reciterId: 1,
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

    group('Missing Coverage Scenarios', () {
      test(
        'DeleteDownloadEvent cancels active download before deleting',
        () async {
          const testDownloadId = '001_Reciter';
          final activeDownload = DownloadItem(
            id: testDownloadId,
            title: 'Surah',
            url: 'url',
            filePath: 'path',
            reciterName: 'Reciter',
            status: DownloadStatus.downloading,
            progress: 0.5,
            fileSize: 100,
            downloadedSize: 50,
            createdAt: DateTime.now(),
          );

          when(
            mockGetDownloadItemUseCase(any),
          ).thenAnswer((_) async => Right(activeDownload));
          when(
            mockGetDownloadStatusUseCase(any),
          ).thenAnswer((_) async => DownloadStatus.downloading);
          when(
            mockCancelDownloadUseCase(any),
          ).thenAnswer((_) async => const Right(null));
          when(
            mockDeleteDownloadUseCase(any),
          ).thenAnswer((_) async => const Right(null));
          when(
            mockGetDownloadsByReciterUseCase(),
          ).thenAnswer((_) async => const Right({}));

          downloadsBloc.add(
            const DeleteDownloadEvent(downloadId: testDownloadId),
          );

          await expectLater(
            downloadsBloc.stream,
            emitsThrough(
              const DownloadsState(status: DownloadsStateStatus.loaded),
            ),
          );

          verify(mockCancelDownloadUseCase(activeDownload.id)).called(1);
          verify(mockDeleteDownloadUseCase(activeDownload.id)).called(1);
        },
      );

      test('Global progress stream handles errors gracefully', () async {
        // Arrange: Create a stream controller to simulate errors
        final errorStreamController =
            StreamController<DownloadProgress>.broadcast();

        when(
          mockObserveGlobalDownloadProgressUseCase(),
        ).thenAnswer((_) => errorStreamController.stream);

        // Re-instantiate bloc to listen to the new stream
        downloadsBloc = DownloadsBloc(
          deleteDownload: mockDeleteDownloadUseCase,
          downloadSurah: mockDownloadSurahUseCase,
          getDownloadsByReciter: mockGetDownloadsByReciterUseCase,
          observeGlobalDownloadProgress:
              mockObserveGlobalDownloadProgressUseCase,
          checkDownloadAccess: mockCheckDownloadAccessUseCase,
          checkSurahDownloaded: mockCheckSurahDownloadedUseCase,
          deleteReciterDownloads: mockDeleteReciterDownloadsUseCase,
          clearAllDownloads: mockClearAllDownloadsUseCase,
          getTotalDownloadsSize: mockGetTotalDownloadsSizeUseCase,
          validateDownloadedFile: mockValidateDownloadedFileUseCase,
          getValidCompletedDownloads: mockGetValidCompletedDownloadsUseCase,
          playDownload: mockPlayDownloadUseCase,
          playAllDownloads: mockPlayAllDownloadsUseCase,
          retryDownload: mockRetryDownloadUseCase,
          getDownloadStatus: mockGetDownloadStatusUseCase,
          removeFromDownloadQueue: mockRemoveFromDownloadQueueUseCase,
          getDownloadItem: mockGetDownloadItemUseCase,
          cancelDownload: mockCancelDownloadUseCase,
        );

        // Act: Emit an error
        errorStreamController.addError(Exception('Stream error'));
        await pumpEventQueue();

        // Assert: Bloc should still be functional (e.g. can load downloads)
        when(
          mockGetDownloadsByReciterUseCase(),
        ).thenAnswer((_) async => const Right({}));
        downloadsBloc.add(const LoadDownloads());

        await expectLater(
          downloadsBloc.stream,
          emitsThrough(
            const DownloadsState(status: DownloadsStateStatus.loaded),
          ),
        );
        await errorStreamController.close();
      });

      test('initialization handles synchronous errors gracefully', () async {
        // Arrange: Mock invocation to throw synchronously
        when(
          mockObserveGlobalDownloadProgressUseCase(),
        ).thenThrow(Exception('Setup error'));

        // Re-instantiate bloc
        downloadsBloc = DownloadsBloc(
          deleteDownload: mockDeleteDownloadUseCase,
          downloadSurah: mockDownloadSurahUseCase,
          getDownloadsByReciter: mockGetDownloadsByReciterUseCase,
          observeGlobalDownloadProgress:
              mockObserveGlobalDownloadProgressUseCase,
          checkDownloadAccess: mockCheckDownloadAccessUseCase,
          checkSurahDownloaded: mockCheckSurahDownloadedUseCase,
          deleteReciterDownloads: mockDeleteReciterDownloadsUseCase,
          clearAllDownloads: mockClearAllDownloadsUseCase,
          getTotalDownloadsSize: mockGetTotalDownloadsSizeUseCase,
          validateDownloadedFile: mockValidateDownloadedFileUseCase,
          getValidCompletedDownloads: mockGetValidCompletedDownloadsUseCase,
          playDownload: mockPlayDownloadUseCase,
          playAllDownloads: mockPlayAllDownloadsUseCase,
          retryDownload: mockRetryDownloadUseCase,
          getDownloadStatus: mockGetDownloadStatusUseCase,
          removeFromDownloadQueue: mockRemoveFromDownloadQueueUseCase,
          getDownloadItem: mockGetDownloadItemUseCase,
          cancelDownload: mockCancelDownloadUseCase,
        );

        // Assert: No crash, bloc functions
        when(
          mockGetDownloadsByReciterUseCase(),
        ).thenAnswer((_) async => const Right({}));
        downloadsBloc.add(const LoadDownloads());
        await expectLater(
          downloadsBloc.stream,
          emitsThrough(
            const DownloadsState(status: DownloadsStateStatus.loaded),
          ),
        );
      });

      test(
        'Reloads downloads when global progress listener emits a terminal status',
        () async {
          // Arrange
          final progressController =
              StreamController<DownloadProgress>.broadcast();
          when(
            mockObserveGlobalDownloadProgressUseCase(),
          ).thenAnswer((_) => progressController.stream);

          // Re-instantiate logic to hook up the stream
          downloadsBloc = DownloadsBloc(
            deleteDownload: mockDeleteDownloadUseCase,
            downloadSurah: mockDownloadSurahUseCase,
            getDownloadsByReciter: mockGetDownloadsByReciterUseCase,
            observeGlobalDownloadProgress:
                mockObserveGlobalDownloadProgressUseCase,
            checkDownloadAccess: mockCheckDownloadAccessUseCase,
            checkSurahDownloaded: mockCheckSurahDownloadedUseCase,
            deleteReciterDownloads: mockDeleteReciterDownloadsUseCase,
            clearAllDownloads: mockClearAllDownloadsUseCase,
            getTotalDownloadsSize: mockGetTotalDownloadsSizeUseCase,
            validateDownloadedFile: mockValidateDownloadedFileUseCase,
            getValidCompletedDownloads: mockGetValidCompletedDownloadsUseCase,
            playDownload: mockPlayDownloadUseCase,
            playAllDownloads: mockPlayAllDownloadsUseCase,
            retryDownload: mockRetryDownloadUseCase,
            getDownloadStatus: mockGetDownloadStatusUseCase,
            removeFromDownloadQueue: mockRemoveFromDownloadQueueUseCase,
            getDownloadItem: mockGetDownloadItemUseCase,
            cancelDownload: mockCancelDownloadUseCase,
          );

          // Mock generic load response
          when(
            mockGetDownloadsByReciterUseCase(),
          ).thenAnswer((_) async => const Right({}));

          // Act: Emit terminal statuses
          final List<DownloadStatus> terminalStatuses = [
            DownloadStatus.completed,
            DownloadStatus.failed,
            DownloadStatus.cancelled,
          ];

          for (final status in terminalStatuses) {
            progressController.add(
              DownloadProgress(
                id: '1',
                status: status,
                progress: 100,
                downloadedSize: 100,
                fileSize: 100,
              ),
            );
            // Allow event loop to process
            await Future<void>.delayed(Duration.zero);
          }

          // Wait for async processing
          await Future<void>.delayed(const Duration(milliseconds: 50));

          // Verify that reload was triggered for each terminal status
          verify(
            mockGetDownloadsByReciterUseCase(),
          ).called(terminalStatuses.length);

          await progressController.close();
        },
      );
    });

    group('Premium Access Check', () {
      test(
        'CheckPremiumAccessEvent emits premiumRequired when access is denied',
        () async {
          // Arrange
          when(
            mockCheckDownloadAccessUseCase(any),
          ).thenAnswer((_) async => const Right(false));

          // Act
          downloadsBloc.add(const CheckPremiumAccessEvent());

          // Assert
          await expectLater(
            downloadsBloc.statusStream,
            emits(
              isA<DownloadsStatus>().having(
                (s) => s.maybeMap(
                  premiumRequired: (_) => true,
                  orElse: () => false,
                ),
                'is premiumRequired',
                true,
              ),
            ),
          );
        },
      );

      test(
        'DownloadSurahEvent blocks download when premium is required and access is denied',
        () async {
          // Arrange
          when(
            mockCheckDownloadAccessUseCase(any),
          ).thenAnswer((_) async => const Right(false));

          // Act
          downloadsBloc.add(
            const DownloadSurahEvent(
              surahId: '001',
              surahTitle: 'Al-Fatiha',
              reciterName: 'Mishary',
              reciterId: 1,
            ),
          );

          // Assert
          await expectLater(
            downloadsBloc.statusStream,
            emits(
              isA<DownloadsStatus>().having(
                (s) => s.maybeMap(
                  premiumRequired: (_) => true,
                  orElse: () => false,
                ),
                'is premiumRequired',
                true,
              ),
            ),
          );
          verifyNoMoreInteractions(mockDownloadSurahUseCase);
        },
      );
    });

    group('Retry Download', () {
      test(
        'RetryDownloadEvent emits error when download is not found',
        () async {
          // Arrange
          when(
            mockGetDownloadItemUseCase(any),
          ).thenAnswer((_) async => const Right(null));

          // Act
          downloadsBloc.add(const RetryDownloadEvent(downloadId: '123'));

          // Assert
          await expectLater(
            downloadsBloc.statusStream,
            emits(
              isA<DownloadsStatus>().having(
                (s) => s.maybeMap(
                  error: (e) => e.message == 'Download not found',
                  orElse: () => false,
                ),
                'is error: Download not found',
                true,
              ),
            ),
          );
        },
      );

      test(
        'RetryDownloadEvent calls retry strategy when download is failed',
        () async {
          // Arrange
          final failedItem = DownloadItem(
            id: '123_Mishary',
            url: '001',
            title: 'Al-Fatiha',
            reciterId: 1,
            reciterName: 'Mishary',
            status: DownloadStatus.failed,
            progress: 0.0,
            downloadedSize: 0,
            fileSize: 0,
            filePath: '',
            createdAt: DateTime.now(),
          );
          when(
            mockGetDownloadItemUseCase(any),
          ).thenAnswer((_) async => Right(failedItem));
          when(
            mockCheckDownloadAccessUseCase(any),
          ).thenAnswer((_) async => const Right(true));
          when(
            mockGetDownloadStatusUseCase(any),
          ).thenAnswer((_) async => DownloadStatus.failed);
          when(
            mockRetryDownloadUseCase(any),
          ).thenAnswer((_) async => const Right(null));
          // Stub for background refresh that happens after retry
          when(
            mockGetDownloadsByReciterUseCase(),
          ).thenAnswer((_) async => const Right({}));

          // Act
          downloadsBloc.add(
            const RetryDownloadEvent(downloadId: '123_Mishary'),
          );

          // Assert
          await expectLater(
            downloadsBloc.statusStream,
            emitsThrough(
              isA<DownloadsStatus>().having(
                (s) => s.maybeMap(
                  downloadStarted: (_) => true,
                  orElse: () => false,
                ),
                'is downloadStarted',
                true,
              ),
            ),
          );
          verify(mockRetryDownloadUseCase(any)).called(1);
        },
      );

      test(
        'RetryDownloadEvent allows retry for stuck downloads (0% after 30s)',
        () async {
          // Arrange - Create a download that's stuck at 0% for >30 seconds
          final stuckItem = DownloadItem(
            id: '123_Mishary',
            url: '001',
            title: 'Al-Fatiha',
            reciterId: 1,
            reciterName: 'Mishary',
            status: DownloadStatus.downloading,
            progress: 0.0,
            downloadedSize: 0,
            fileSize: 100,
            filePath: '',
            createdAt: DateTime.now().subtract(const Duration(seconds: 35)),
          );
          when(
            mockGetDownloadItemUseCase(any),
          ).thenAnswer((_) async => Right(stuckItem));
          when(
            mockCheckDownloadAccessUseCase(any),
          ).thenAnswer((_) async => const Right(true));
          when(
            mockGetDownloadStatusUseCase(any),
          ).thenAnswer((_) async => null); // Not active, allow retry
          when(
            mockRetryDownloadUseCase(any),
          ).thenAnswer((_) async => const Right(null));
          when(
            mockGetDownloadsByReciterUseCase(),
          ).thenAnswer((_) async => const Right({}));

          // Act
          downloadsBloc.add(
            const RetryDownloadEvent(downloadId: '123_Mishary'),
          );

          // Assert - Should allow retry for stuck download
          await expectLater(
            downloadsBloc.statusStream,
            emitsThrough(
              isA<DownloadsStatus>().having(
                (s) => s.maybeMap(
                  downloadStarted: (_) => true,
                  orElse: () => false,
                ),
                'is downloadStarted',
                true,
              ),
            ),
          ).timeout(
            const Duration(seconds: 2),
            onTimeout: () => fail('Test timed out waiting for downloadStarted'),
          );
          verify(mockRetryDownloadUseCase(any)).called(1);
        },
      );
    });

    group('Validate Download', () {
      test(
        'ValidateDownloadedFileEvent emits error when download is not found',
        () async {
          // Arrange
          when(
            mockGetDownloadItemUseCase(any),
          ).thenAnswer((_) async => const Right(null));

          // Act
          downloadsBloc.add(
            const ValidateDownloadedFileEvent(downloadId: '123'),
          );

          // Assert
          await expectLater(
            downloadsBloc.stream,
            emits(
              isA<DownloadsState>()
                  .having((s) => s.status, 'status', DownloadsStateStatus.error)
                  .having(
                    (s) => s.errorMessage,
                    'errorMessage',
                    'Download not found',
                  ),
            ),
          );
        },
      );

      test(
        'ValidateDownloadedFileEvent emits fileValidationResult on success',
        () async {
          // Arrange
          final item = DownloadItem(
            id: '123',
            url: '001',
            title: 'Al-Fatiha',
            reciterId: 1,
            reciterName: 'Mishary',
            status: DownloadStatus.completed,
            progress: 100,
            downloadedSize: 100,
            fileSize: 100,
            filePath: 'path',
            createdAt: DateTime.now(),
          );
          when(
            mockGetDownloadItemUseCase(any),
          ).thenAnswer((_) async => Right(item));
          when(
            mockValidateDownloadedFileUseCase(any),
          ).thenAnswer((_) async => const Right(true));

          // Act
          downloadsBloc.add(
            const ValidateDownloadedFileEvent(downloadId: '123'),
          );

          // Assert
          await expectLater(
            downloadsBloc.statusStream,
            emits(
              isA<DownloadsStatus>().having(
                (s) => s.maybeMap(
                  fileValidationResult: (r) => r.isValid,
                  orElse: () => false,
                ),
                'is valid result',
                true,
              ),
            ),
          );
        },
      );
    });

    group('Play Download', () {
      test(
        'PlayDownloadedSurahEvent emits error when download is not found',
        () async {
          // Arrange
          when(
            mockGetDownloadItemUseCase(any),
          ).thenAnswer((_) async => const Right(null));

          // Act
          downloadsBloc.add(const PlayDownloadedSurahEvent(downloadId: '123'));

          // Assert
          await expectLater(
            downloadsBloc.statusStream,
            emits(
              isA<DownloadsStatus>().having(
                (s) => s.maybeMap(
                  error: (e) => e.message == 'Download not found',
                  orElse: () => false,
                ),
                'is error: Download not found',
                true,
              ),
            ),
          );
        },
      );

      test(
        'PlayDownloadedSurahEvent emits error when file validation fails',
        () async {
          // Arrange
          final item = DownloadItem(
            id: '123',
            url: '001',
            title: 'Al-Fatiha',
            reciterId: 1,
            reciterName: 'Mishary',
            status: DownloadStatus.completed,
            progress: 100,
            downloadedSize: 100,
            fileSize: 100,
            filePath: 'path',
            createdAt: DateTime.now(),
          );
          when(
            mockGetDownloadItemUseCase(any),
          ).thenAnswer((_) async => Right(item));
          when(
            mockValidateDownloadedFileUseCase(any),
          ).thenAnswer((_) async => const Right(false));

          // Act
          downloadsBloc.add(const PlayDownloadedSurahEvent(downloadId: '123'));

          // Assert
          await expectLater(
            downloadsBloc.statusStream,
            emits(
              isA<DownloadsStatus>().having(
                (s) => s.maybeMap(
                  error: (e) => e.message == 'Downloaded file not found',
                  orElse: () => false,
                ),
                'is error: Downloaded file not found',
                true,
              ),
            ),
          );
        },
      );

      test(
        'PlayDownloadedSurahEvent emits playbackInitiated on success',
        () async {
          // Arrange
          final item = DownloadItem(
            id: '123',
            url: '001',
            title: 'Al-Fatiha',
            reciterId: 1,
            reciterName: 'Mishary',
            status: DownloadStatus.completed,
            progress: 100,
            downloadedSize: 100,
            fileSize: 100,
            filePath: 'path',
            createdAt: DateTime.now(),
          );
          when(
            mockGetDownloadItemUseCase(any),
          ).thenAnswer((_) async => Right(item));
          when(
            mockValidateDownloadedFileUseCase(any),
          ).thenAnswer((_) async => const Right(true));
          when(
            mockPlayDownloadUseCase(any),
          ).thenAnswer((_) async => const Right(null));

          // Act
          downloadsBloc.add(const PlayDownloadedSurahEvent(downloadId: '123'));

          // Assert
          await expectLater(
            downloadsBloc.statusStream,
            emits(
              isA<DownloadsStatus>().having(
                (s) => s.maybeMap(
                  playbackInitiated: (_) => true,
                  orElse: () => false,
                ),
                'is playbackInitiated',
                true,
              ),
            ),
          );
        },
      );
    });

    group('Play All Downloads', () {
      test(
        'PlayAllDownloadsEvent emits error when no valid downloads found',
        () async {
          // Arrange
          when(
            mockGetValidCompletedDownloadsUseCase(any),
          ).thenAnswer((_) async => const Right([]));

          // Act
          downloadsBloc.add(
            const PlayAllDownloadsEvent(reciterName: 'Mishary'),
          );

          // Assert
          await expectLater(
            downloadsBloc.statusStream,
            emits(
              isA<DownloadsStatus>().having(
                (s) => s.maybeMap(
                  error: (e) => e.message == 'No valid downloaded files found',
                  orElse: () => false,
                ),
                'is error: No valid files',
                true,
              ),
            ),
          );
        },
      );

      test(
        'PlayAllDownloadsEvent emits playbackInitiated on success',
        () async {
          // Arrange
          final item = DownloadItem(
            id: '123',
            url: '001',
            title: 'Al-Fatiha',
            reciterId: 1,
            reciterName: 'Mishary',
            status: DownloadStatus.completed,
            progress: 100,
            downloadedSize: 100,
            fileSize: 100,
            filePath: 'path',
            createdAt: DateTime.now(),
          );
          when(
            mockGetValidCompletedDownloadsUseCase(any),
          ).thenAnswer((_) async => Right([item]));
          when(
            mockPlayAllDownloadsUseCase(any),
          ).thenAnswer((_) async => const Right(null));

          // Act
          downloadsBloc.add(
            const PlayAllDownloadsEvent(reciterName: 'Mishary'),
          );

          // Assert
          await expectLater(
            downloadsBloc.statusStream,
            emits(
              isA<DownloadsStatus>().having(
                (s) => s.maybeMap(
                  playbackInitiated: (_) => true,
                  orElse: () => false,
                ),
                'is playbackInitiated',
                true,
              ),
            ),
          );
        },
      );
    });

    // Phase 1: Exception Handling Tests
    group('Exception Handling', () {
      test('CheckSurahDownloadedEvent handles exceptions', () async {
        when(
          mockCheckSurahDownloadedUseCase(
            surahId: anyNamed('surahId'),
            reciterName: anyNamed('reciterName'),
          ),
        ).thenThrow(Exception('Database connection failed'));

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
            surahId: '001',
            reciterName: 'Test Reciter',
          ),
        );
      });

      test('ValidateDownloadedFileEvent handles exceptions', () async {
        final testItem = DownloadItem(
          id: '123',
          url: '001',
          title: 'Al-Fatiha',
          reciterId: 1,
          reciterName: 'Test Reciter',
          status: DownloadStatus.completed,
          progress: 1.0,
          downloadedSize: 100,
          fileSize: 100,
          filePath: '/path/to/file.mp3',
          createdAt: DateTime.now(),
        );

        when(
          mockGetDownloadItemUseCase(any),
        ).thenAnswer((_) async => Right(testItem));
        when(
          mockValidateDownloadedFileUseCase(any),
        ).thenThrow(Exception('File system error'));

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

        downloadsBloc.add(const ValidateDownloadedFileEvent(downloadId: '123'));
      });

      test('GetValidCompletedDownloadsEvent handles exceptions', () async {
        when(
          mockGetValidCompletedDownloadsUseCase(any),
        ).thenThrow(Exception('Repository error'));

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
          const GetValidCompletedDownloadsEvent(reciterName: 'Test Reciter'),
        );
      });

      test('PlayDownloadedSurahEvent handles exceptions', () async {
        final testItem = DownloadItem(
          id: '123',
          url: '001',
          title: 'Al-Fatiha',
          reciterId: 1,
          reciterName: 'Test Reciter',
          status: DownloadStatus.completed,
          progress: 1.0,
          downloadedSize: 100,
          fileSize: 100,
          filePath: '/path/to/file.mp3',
          createdAt: DateTime.now(),
        );

        when(
          mockGetDownloadItemUseCase(any),
        ).thenAnswer((_) async => Right(testItem));
        when(
          mockValidateDownloadedFileUseCase(any),
        ).thenThrow(Exception('Validation error'));

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

        downloadsBloc.add(const PlayDownloadedSurahEvent(downloadId: '123'));
      });

      test('PlayAllDownloadsEvent handles exceptions', () async {
        when(
          mockGetValidCompletedDownloadsUseCase(any),
        ).thenThrow(Exception('Repository error'));

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
          const PlayAllDownloadsEvent(reciterName: 'Test Reciter'),
        );
      });

      test('CheckPremiumAccessEvent handles exceptions', () async {
        when(
          mockCheckDownloadAccessUseCase(any),
        ).thenThrow(Exception('Auth service error'));

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

      test('RetryDownloadEvent handles exceptions', () async {
        final testItem = DownloadItem(
          id: '123',
          url: '001',
          title: 'Al-Fatiha',
          reciterId: 1,
          reciterName: 'Test Reciter',
          status: DownloadStatus.failed,
          progress: 0.0,
          downloadedSize: 0,
          fileSize: 100,
          filePath: '/path/to/file.mp3',
          createdAt: DateTime.now(),
        );

        when(
          mockGetDownloadItemUseCase(any),
        ).thenAnswer((_) async => Right(testItem));
        when(
          mockCheckDownloadAccessUseCase(any),
        ).thenThrow(Exception('Premium check error'));

        unawaited(
          expectLater(
            downloadsBloc.statusStream,
            emits(
              isA<Error>().having(
                (e) => e.message,
                'message',
                contains('Failed to retry download'),
              ),
            ),
          ),
        );

        downloadsBloc.add(const RetryDownloadEvent(downloadId: '123'));
      });

      test('DownloadSurahEvent handles active download check error', () async {
        when(
          mockCheckDownloadAccessUseCase(any),
        ).thenAnswer((_) async => const Right(true));
        when(
          mockCheckSurahDownloadedUseCase(
            surahId: anyNamed('surahId'),
            reciterName: anyNamed('reciterName'),
          ),
        ).thenAnswer((_) async => const Right(false));
        when(
          mockGetDownloadStatusUseCase(any),
        ).thenThrow(Exception('Status check failed'));
        when(
          mockDownloadSurahUseCase(
            surahId: anyNamed('surahId'),
            surahTitle: anyNamed('surahTitle'),
            reciterName: anyNamed('reciterName'),
            reciterId: anyNamed('reciterId'),
          ),
        ).thenAnswer((_) async => const Right(null));
        when(
          mockGetDownloadsByReciterUseCase(),
        ).thenAnswer((_) async => const Right({}));

        // Should proceed with download even if active check throws
        downloadsBloc.add(
          const DownloadSurahEvent(
            surahId: '001',
            surahTitle: 'Al-Fatiha',
            reciterName: 'Test Reciter',
            reciterId: 1,
          ),
        );

        await Future.delayed(const Duration(milliseconds: 100));
        verify(
          mockDownloadSurahUseCase(
            surahId: anyNamed('surahId'),
            surahTitle: anyNamed('surahTitle'),
            reciterName: anyNamed('reciterName'),
            reciterId: anyNamed('reciterId'),
          ),
        ).called(1);
      });
    });

    group('RefreshDownloadsProgress', () {
      test('logs error when refresh fails', () async {
        // First, successfully load downloads to get into loaded state
        when(
          mockGetDownloadsByReciterUseCase(),
        ).thenAnswer((_) async => const Right({}));

        downloadsBloc.add(const LoadDownloads());
        await Future.delayed(const Duration(milliseconds: 100));

        // Verify we're in loaded state
        expect(downloadsBloc.state.status, DownloadsStateStatus.loaded);

        // Now make the next call fail to trigger the error logging
        when(
          mockGetDownloadsByReciterUseCase(),
        ).thenAnswer((_) async => const Left(AudioFailure('Refresh failed')));

        downloadsBloc.add(const RefreshDownloadsProgress());

        // Wait for the refresh to complete
        await Future.delayed(const Duration(milliseconds: 100));

        // State should remain loaded (error is logged, not emitted)
        expect(downloadsBloc.state.status, DownloadsStateStatus.loaded);
      });
    });

    group('Hydrated Bloc', () {
      test('fromJson returns initial state', () {
        final Map<String, Object> json = {'status': 'loaded', 'downloads': {}};
        final DownloadsState? state = downloadsBloc.fromJson(json);
        expect(state, const DownloadsState());
      });

      test('toJson returns null for non-initial states', () {
        const state = DownloadsState(status: DownloadsStateStatus.loaded);
        final Map<String, dynamic>? json = downloadsBloc.toJson(state);
        expect(json, isNull);
      });
    });
  });
}
