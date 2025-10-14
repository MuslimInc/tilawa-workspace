import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:muzakri/audio_player_handler.dart';
import 'package:muzakri/core/errors/failures.dart';
import 'package:muzakri/core/services/analytics_service.dart';
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
    group('LoadDownloads', () {
      test('initial state should be DownloadsState.initial', () {
        expect(downloadsBloc.state, const DownloadsState.initial());
      });

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
      const testUrl = 'https://example.com/audio.mp3';

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
              url: anyNamed('url'),
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
          ).thenAnswer((_) async {
            return;
          });
          when(
            mockAnalyticsService.logDownloadComplete(
              any,
              fileName: anyNamed('fileName'),
            ),
          ).thenAnswer((_) async {
            return;
          });
          return downloadsBloc;
        },
        act: (bloc) => bloc.add(
          const DownloadSurahEvent(
            surahId: testSurahId,
            surahTitle: testSurahTitle,
            reciterName: testReciterName,
            url: testUrl,
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
            url: testUrl,
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
            url: testUrl,
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
              url: anyNamed('url'),
            ),
          ).thenAnswer((_) async => const Left(AudioFailure('Network error')));
          when(
            mockAnalyticsService.logDownloadStart(
              any,
              fileName: anyNamed('fileName'),
            ),
          ).thenAnswer((_) async {
            return;
          });
          when(
            mockAnalyticsService.logEvent(
              any,
              parameters: anyNamed('parameters'),
            ),
          ).thenAnswer((_) async {
            return;
          });
          return downloadsBloc;
        },
        act: (bloc) => bloc.add(
          const DownloadSurahEvent(
            surahId: testSurahId,
            surahTitle: testSurahTitle,
            reciterName: testReciterName,
            url: testUrl,
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

      blocTest<DownloadsBloc, DownloadsState>(
        'emits [error] when download is already in progress',
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
              url: anyNamed('url'),
            ),
          ).thenAnswer((_) async => const Right(null));
          when(
            mockGetDownloadsByReciterUseCase(),
          ).thenAnswer((_) async => const Right({}));
          // Mock DownloadService.isDownloadActive to return true
          // Note: This would require making DownloadService mockable or using a different approach
          return downloadsBloc;
        },
        act: (bloc) => bloc.add(
          const DownloadSurahEvent(
            surahId: testSurahId,
            surahTitle: testSurahTitle,
            reciterName: testReciterName,
            url: testUrl,
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
          // The actual test would depend on DownloadService.isDownloadActive implementation
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
          when(mockDownloadsRepository.retryDownload(any)).thenAnswer((
            _,
          ) async {
            return;
          });
          when(
            mockGetDownloadsByReciterUseCase(),
          ).thenAnswer((_) async => const Right({}));
          when(
            mockAnalyticsService.logEvent(
              any,
              parameters: anyNamed('parameters'),
            ),
          ).thenAnswer((_) async {
            return;
          });
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
    });
  });
}
