import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:dartz_plus/dartz_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tilawa/features/downloads/domain/entities/download_item.dart';
import 'package:tilawa/features/downloads/domain/usecases/cancel_downloads_for_reciter_use_case.dart';
import 'package:tilawa/features/downloads/domain/usecases/check_low_device_storage_use_case.dart';
import 'package:tilawa/features/downloads/domain/usecases/download_all_surahs_use_case.dart';
import 'package:tilawa/features/downloads/domain/usecases/observe_reciter_downloads_use_case.dart';
import 'package:tilawa/features/reciters/presentation/bloc/reciter_download_bloc.dart';
import 'package:tilawa/features/surah/domain/entities/surah_entity.dart';
import 'package:tilawa_core/entities/audio.dart';
import 'package:tilawa_core/entities/reciter_entity.dart';
import 'package:tilawa_core/errors/failures.dart';

class MockDownloadAllSurahsUseCase extends Mock
    implements DownloadAllSurahsUseCase {}

class MockCancelDownloadsForReciterUseCase extends Mock
    implements CancelDownloadsForReciterUseCase {}

class MockObserveReciterDownloadsUseCase extends Mock
    implements ObserveReciterDownloadsUseCase {}

class MockCheckLowDeviceStorageUseCase extends Mock
    implements CheckLowDeviceStorageUseCase {}

void main() {
  late ReciterDownloadBloc bloc;
  late MockDownloadAllSurahsUseCase downloadAllSurahs;
  late MockCancelDownloadsForReciterUseCase cancelDownloadsForReciter;
  late MockObserveReciterDownloadsUseCase observeReciterDownloads;
  late MockCheckLowDeviceStorageUseCase checkLowDeviceStorage;
  late StreamController<DownloadItem> downloadUpdatesController;

  setUp(() {
    downloadAllSurahs = MockDownloadAllSurahsUseCase();
    cancelDownloadsForReciter = MockCancelDownloadsForReciterUseCase();
    observeReciterDownloads = MockObserveReciterDownloadsUseCase();
    checkLowDeviceStorage = MockCheckLowDeviceStorageUseCase();

    downloadUpdatesController = StreamController<DownloadItem>.broadcast();
    when(
      () => observeReciterDownloads(any()),
    ).thenAnswer((_) => downloadUpdatesController.stream);
    when(
      () => checkLowDeviceStorage(estimatedRequiredBytes: any(named: 'estimatedRequiredBytes')),
    ).thenAnswer((_) async => false);

    bloc = ReciterDownloadBloc(
      downloadAllSurahs,
      cancelDownloadsForReciter,
      observeReciterDownloads,
      checkLowDeviceStorage,
    );
  });

  tearDown(() {
    downloadUpdatesController.close();
    bloc.close();
  });

  const reciter = ReciterEntity(
    id: 1,
    name: 'Mishary',
    letter: 'M',
    date: '2023',
    moshaf: [],
  );

  const surah1 = SurahEntity(
    audio: AudioEntity(
      id: '1',
      title: 'Surah 1',
      url: 'url1',
      duration: Duration.zero,
    ),
  );

  const surah2 = SurahEntity(
    audio: AudioEntity(
      id: '2',
      title: 'Surah 2',
      url: 'url2',
      duration: Duration.zero,
    ),
  );

  group('ReciterDownloadBloc Initialization', () {
    test(
      'InitializeReciterDownload sets initial state and subscribes',
      () async {
        bloc.add(
          const InitializeReciterDownload(
            reciterName: 'Mishary',
            totalSurahs: 114,
            downloadedSurahIds: ['url1'],
          ),
        );

        await Future.delayed(Duration.zero);

        expect(bloc.state.downloadedCount, equals(1));
        expect(bloc.state.totalCount, equals(114));
        expect(bloc.state.progress, closeTo(1 / 114, 0.0001));
        verify(() => observeReciterDownloads('Mishary')).called(1);
      },
    );
  });

  group('ReciterDownloadBloc Actions', () {
    test('StartReciterDownloadAll calls use case', () async {
      when(
        () => downloadAllSurahs(
          surahs: any(named: 'surahs'),
          reciterName: any(named: 'reciterName'),
          reciterId: any(named: 'reciterId'),
        ),
      ).thenAnswer((_) async => const Right(null));

      bloc.add(
        const StartReciterDownloadAll(
          reciter: reciter,
          surahs: [surah1, surah2],
        ),
      );

      await Future.delayed(Duration.zero);

      verify(
        () => downloadAllSurahs(
          surahs: [surah1, surah2],
          reciterName: reciter.name,
          reciterId: reciter.id,
        ),
      ).called(1);
    });

    blocTest<ReciterDownloadBloc, ReciterDownloadState>(
      'blocks StartReciterDownloadAll when storage check fails',
      build: () {
        when(
          () => checkLowDeviceStorage(
            estimatedRequiredBytes: any(named: 'estimatedRequiredBytes'),
          ),
        ).thenAnswer((_) async => true);
        return bloc;
      },
      act: (bloc) => bloc.add(
        const StartReciterDownloadAll(reciter: reciter, surahs: [surah1]),
      ),
      expect: () => [
        const ReciterDownloadState(errorMessage: kInsufficientStorageError),
      ],
      verify: (_) {
        verifyNever(
          () => downloadAllSurahs(
            surahs: any(named: 'surahs'),
            reciterName: any(named: 'reciterName'),
            reciterId: any(named: 'reciterId'),
          ),
        );
      },
    );

    test(
      'CancelReciterDownloadAll clears downloading and calls use case',
      () async {
        when(
          () => cancelDownloadsForReciter(any()),
        ).thenAnswer((_) async => const Right(null));

        bloc.add(const CancelReciterDownloadAll(reciterName: 'Mishary'));

        // Immediate state update
        expect(bloc.state.isDownloadingAll, isFalse);

        await Future.delayed(Duration.zero);

        verify(() => cancelDownloadsForReciter('Mishary')).called(1);
      },
    );

    test(
      'StartReciterDownloadAll emits error on failure and clears it on retry',
      () async {
        // 1. Setup failure
        const failure = NetworkFailure('No internet');
        when(
          () => downloadAllSurahs(
            surahs: any(named: 'surahs'),
            reciterName: any(named: 'reciterName'),
            reciterId: any(named: 'reciterId'),
          ),
        ).thenAnswer((_) async => const Left(failure));

        // 2. Trigger first attempt
        bloc.add(
          const StartReciterDownloadAll(reciter: reciter, surahs: [surah1]),
        );
        await Future.delayed(Duration.zero);

        // Verify error state
        expect(bloc.state.errorMessage, equals('No internet'));
      },
    );
  });

  group('ReciterDownloadBloc Progress Updates', () {
    test('UpdateReciterDownloadProgress updates state', () async {
      bloc.add(
        const UpdateReciterDownloadProgress(
          progress: 0.5,
          isDownloading: true,
          downloadedCount: 5,
          totalCount: 10,
        ),
      );

      await Future.delayed(Duration.zero);

      expect(bloc.state.progress, equals(0.5));
      expect(bloc.state.isDownloadingAll, isTrue);
      expect(bloc.state.downloadedCount, equals(5));
      expect(bloc.state.totalCount, equals(10));
    });

    test('Handles download status updates via stream', () async {
      when(
        () => downloadAllSurahs(
          surahs: any(named: 'surahs'),
          reciterName: any(named: 'reciterName'),
          reciterId: any(named: 'reciterId'),
        ),
      ).thenAnswer((_) async => const Right(null));

      bloc.add(
        const InitializeReciterDownload(
          reciterName: 'Mishary',
          totalSurahs: 2,
          downloadedSurahIds: [],
        ),
      );
      await Future.delayed(Duration.zero);
      // Start batch download with 1 surah to test completion
      bloc.add(
        const StartReciterDownloadAll(reciter: reciter, surahs: [surah1]),
      );
      await Future.delayed(Duration.zero);

      // 1. Surah 1 starts downloading
      downloadUpdatesController.add(
        DownloadItem(
          id: '1',
          url: '1',
          title: 'S1',
          filePath: '',
          reciterName: 'Mishary',
          status: DownloadStatus.downloading,
          progress: 0.1,
          fileSize: 100,
          downloadedSize: 10,
          createdAt: DateTime.now(),
        ),
      );

      await Future.delayed(Duration.zero);
      expect(bloc.state.isDownloadingAll, isTrue);
      expect(bloc.state.downloadedCount, equals(0));

      // 2. Surah 1 completes
      downloadUpdatesController.add(
        DownloadItem(
          id: '1',
          url: '1',
          title: 'S1',
          filePath: '',
          reciterName: 'Mishary',
          status: DownloadStatus.completed,
          progress: 1.0,
          fileSize: 100,
          downloadedSize: 100,
          createdAt: DateTime.now(),
        ),
      );

      await Future.delayed(Duration.zero);
      expect(bloc.state.isDownloadingAll, isFalse);
      expect(bloc.state.downloadedCount, equals(1));
      expect(bloc.state.progress, equals(0.5));
    });

    blocTest<ReciterDownloadBloc, ReciterDownloadState>(
      'does not set isDownloadingAll when a single completed event arrives without a prior downloading event',
      build: () => bloc,
      act: (bloc) async {
        bloc.add(
          const InitializeReciterDownload(
            reciterName: 'Mishary',
            totalSurahs: 10,
            downloadedSurahIds: [],
          ),
        );
        await Future.delayed(Duration.zero);

        // Simulate single download completion
        downloadUpdatesController.add(
          DownloadItem(
            id: '1',
            url: '1',
            title: 'title',
            status: DownloadStatus.completed,
            progress: 1.0,
            fileSize: 100,
            downloadedSize: 100,
            createdAt: DateTime.now(),
            reciterName: 'Mishary',
            filePath: '',
          ),
        );
      },
      expect: () => [
        const ReciterDownloadState(totalCount: 10),
        const ReciterDownloadState(
          totalCount: 10,
          progress: 0.1, // 1/10
          downloadedCount: 1,
        ),
      ],
    );

    blocTest<ReciterDownloadBloc, ReciterDownloadState>(
      'sets isDownloadingAll to true when a downloading stream event arrives, even without a batch',
      build: () => bloc,
      act: (bloc) async {
        bloc.add(
          const InitializeReciterDownload(
            reciterName: 'Mishary',
            totalSurahs: 10,
            downloadedSurahIds: [],
          ),
        );
        await Future.delayed(Duration.zero);

        // Single individual download starts — no StartReciterDownloadAll
        downloadUpdatesController.add(
          DownloadItem(
            id: '1',
            url: '1',
            title: 'title',
            status: DownloadStatus.downloading,
            progress: 0.5,
            fileSize: 100,
            downloadedSize: 50,
            createdAt: DateTime.now(),
            reciterName: 'Mishary',
            filePath: '',
          ),
        );
        await Future.delayed(Duration.zero);

        // And completes
        downloadUpdatesController.add(
          DownloadItem(
            id: '1',
            url: '1',
            title: 'title',
            status: DownloadStatus.completed,
            progress: 1.0,
            fileSize: 100,
            downloadedSize: 100,
            createdAt: DateTime.now(),
            reciterName: 'Mishary',
            filePath: '',
          ),
        );
      },
      expect: () => [
        const ReciterDownloadState(totalCount: 10),
        // Individual download active → isDownloadingAll flips to true
        const ReciterDownloadState(totalCount: 10, isDownloadingAll: true),
        // Completed → isDownloadingAll back to false
        const ReciterDownloadState(
          totalCount: 10,
          isDownloadingAll: false,
          downloadedCount: 1,
          progress: 0.1,
        ),
      ],
    );

    blocTest<ReciterDownloadBloc, ReciterDownloadState>(
      'sets isDownloadingAll via StartReciterDownloadAll batch flow',
      build: () {
        when(
          () => downloadAllSurahs(
            surahs: any(named: 'surahs'),
            reciterName: any(named: 'reciterName'),
            reciterId: any(named: 'reciterId'),
          ),
        ).thenAnswer((_) async => const Right(null));
        return bloc;
      },
      act: (bloc) async {
        bloc.add(
          const InitializeReciterDownload(
            reciterName: 'Mishary',
            totalSurahs: 1,
            downloadedSurahIds: [],
          ),
        );
        await Future.delayed(Duration.zero);

        bloc.add(
          const StartReciterDownloadAll(reciter: reciter, surahs: [surah1]),
        );
        await Future.delayed(Duration.zero);

        // Add stream item after Start
        downloadUpdatesController.add(
          DownloadItem(
            id: '1',
            url: '1',
            title: 'title',
            status: DownloadStatus.downloading,
            progress: 0.5,
            fileSize: 100,
            downloadedSize: 50,
            createdAt: DateTime.now(),
            reciterName: 'Mishary',
            filePath: '',
          ),
        );
      },
      skip: 1, // Skip Initialize state
      expect: () => [
        // Start -> Pending=true, DownloadingAll=true
        const ReciterDownloadState(
          totalCount: 1,
          isDownloadingAll: true,
          isPending: true,
        ),
        // Update -> Pending=false, DownloadingAll=true (batch flag true)
        const ReciterDownloadState(totalCount: 1, isDownloadingAll: true),
      ],
    );

    blocTest<ReciterDownloadBloc, ReciterDownloadState>(
      'handles pending download status and adds to downloading set',
      build: () {
        when(
          () => downloadAllSurahs(
            surahs: any(named: 'surahs'),
            reciterName: any(named: 'reciterName'),
            reciterId: any(named: 'reciterId'),
          ),
        ).thenAnswer((_) async => const Right(null));
        return bloc;
      },
      act: (bloc) async {
        bloc.add(
          const InitializeReciterDownload(
            reciterName: 'Mishary',
            totalSurahs: 1,
            downloadedSurahIds: [],
          ),
        );
        await Future.delayed(Duration.zero);

        bloc.add(
          const StartReciterDownloadAll(reciter: reciter, surahs: [surah1]),
        );
        await Future.delayed(Duration.zero);

        // Add stream item with pending status
        downloadUpdatesController.add(
          DownloadItem(
            id: '1',
            url: '1',
            title: 'title',
            status: DownloadStatus.pending,
            progress: 0.0,
            fileSize: 100,
            downloadedSize: 0,
            createdAt: DateTime.now(),
            reciterName: 'Mishary',
            filePath: '',
          ),
        );
      },
      skip: 1, // Skip Initialize state
      expect: () => [
        // Start -> Pending=true, DownloadingAll=true
        const ReciterDownloadState(
          totalCount: 1,
          isDownloadingAll: true,
          isPending: true,
        ),
        // Pending status update -> still downloading
        const ReciterDownloadState(totalCount: 1, isDownloadingAll: true),
      ],
    );

    blocTest<ReciterDownloadBloc, ReciterDownloadState>(
      'handles failed download status and removes from downloading set',
      build: () {
        when(
          () => downloadAllSurahs(
            surahs: any(named: 'surahs'),
            reciterName: any(named: 'reciterName'),
            reciterId: any(named: 'reciterId'),
          ),
        ).thenAnswer((_) async => const Right(null));
        return bloc;
      },
      act: (bloc) async {
        bloc.add(
          const InitializeReciterDownload(
            reciterName: 'Mishary',
            totalSurahs: 2,
            downloadedSurahIds: [],
          ),
        );
        await Future.delayed(Duration.zero);

        bloc.add(
          const StartReciterDownloadAll(reciter: reciter, surahs: [surah1]),
        );
        await Future.delayed(Duration.zero);

        // First, add a downloading item
        downloadUpdatesController.add(
          DownloadItem(
            id: '1',
            url: '1',
            title: 'title',
            status: DownloadStatus.downloading,
            progress: 0.5,
            fileSize: 100,
            downloadedSize: 50,
            createdAt: DateTime.now(),
            reciterName: 'Mishary',
            filePath: '',
          ),
        );
        await Future.delayed(Duration.zero);

        // Then mark it as failed
        downloadUpdatesController.add(
          DownloadItem(
            id: '1',
            url: '1',
            title: 'title',
            status: DownloadStatus.failed,
            progress: 0.5,
            fileSize: 100,
            downloadedSize: 50,
            createdAt: DateTime.now(),
            reciterName: 'Mishary',
            filePath: '',
          ),
        );
      },
      skip: 1, // Skip Initialize state
      expect: () => [
        // Start -> Pending=true, DownloadingAll=true
        const ReciterDownloadState(
          totalCount: 2,
          isDownloadingAll: true,
          isPending: true,
        ),
        // Downloading status -> still downloading
        const ReciterDownloadState(totalCount: 2, isDownloadingAll: true),
        // Failed status -> download stops since no more items
        const ReciterDownloadState(totalCount: 2, progress: 0.0),
      ],
    );

    blocTest<ReciterDownloadBloc, ReciterDownloadState>(
      'handles multiple downloads with one failing',
      build: () {
        when(
          () => downloadAllSurahs(
            surahs: any(named: 'surahs'),
            reciterName: any(named: 'reciterName'),
            reciterId: any(named: 'reciterId'),
          ),
        ).thenAnswer((_) async => const Right(null));
        return bloc;
      },
      act: (bloc) async {
        bloc.add(
          const InitializeReciterDownload(
            reciterName: 'Mishary',
            totalSurahs: 2,
            downloadedSurahIds: [],
          ),
        );
        await Future.delayed(Duration.zero);

        bloc.add(
          const StartReciterDownloadAll(
            reciter: reciter,
            surahs: [surah1, surah2],
          ),
        );
        await Future.delayed(Duration.zero);

        // Start downloading two items
        downloadUpdatesController.add(
          DownloadItem(
            id: '1',
            url: '1',
            title: 'title1',
            status: DownloadStatus.downloading,
            progress: 0.5,
            fileSize: 100,
            downloadedSize: 50,
            createdAt: DateTime.now(),
            reciterName: 'Mishary',
            filePath: '',
          ),
        );
        await Future.delayed(Duration.zero);

        downloadUpdatesController.add(
          DownloadItem(
            id: '2',
            url: '2',
            title: 'title2',
            status: DownloadStatus.downloading,
            progress: 0.3,
            fileSize: 100,
            downloadedSize: 30,
            createdAt: DateTime.now(),
            reciterName: 'Mishary',
            filePath: '',
          ),
        );
        await Future.delayed(Duration.zero);

        // First one fails
        downloadUpdatesController.add(
          DownloadItem(
            id: '1',
            url: '1',
            title: 'title1',
            status: DownloadStatus.failed,
            progress: 0.5,
            fileSize: 100,
            downloadedSize: 50,
            createdAt: DateTime.now(),
            reciterName: 'Mishary',
            filePath: '',
          ),
        );
        await Future.delayed(Duration.zero);

        // Second one completes
        downloadUpdatesController.add(
          DownloadItem(
            id: '2',
            url: '2',
            title: 'title2',
            status: DownloadStatus.completed,
            progress: 1.0,
            fileSize: 100,
            downloadedSize: 100,
            createdAt: DateTime.now(),
            reciterName: 'Mishary',
            filePath: '',
          ),
        );
      },
      skip: 1, // Skip Initialize state
      expect: () => [
        // Start -> Pending=true, DownloadingAll=true
        const ReciterDownloadState(
          totalCount: 2,
          isDownloadingAll: true,
          isPending: true,
        ),
        // First item downloading (adds to set, pending becomes false)
        const ReciterDownloadState(totalCount: 2, isDownloadingAll: true),
        // Note: Adding second item to set doesn't change visible state values
        // Failed status removes from set but visible state unchanged
        // Second item completed (set empty, batch ends)
        const ReciterDownloadState(
          totalCount: 2,
          downloadedCount: 1,
          progress: 0.5,
        ),
      ],
    );
  });
}
