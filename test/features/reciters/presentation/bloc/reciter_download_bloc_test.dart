import 'dart:async';

import 'package:dartz_plus/dartz_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tilawa/core/entities/audio.dart';
import 'package:tilawa/core/entities/reciter_entity.dart';
import 'package:tilawa/features/downloads/domain/entities/download_item.dart';
import 'package:tilawa/features/downloads/domain/usecases/cancel_downloads_for_reciter_use_case.dart';
import 'package:tilawa/features/downloads/domain/usecases/download_all_surahs_use_case.dart';
import 'package:tilawa/features/downloads/domain/usecases/observe_reciter_downloads_use_case.dart';
import 'package:tilawa/features/reciters/presentation/bloc/reciter_download_bloc.dart';
import 'package:tilawa/features/surah/domain/entities/surah_entity.dart';

class MockDownloadAllSurahsUseCase extends Mock
    implements DownloadAllSurahsUseCase {}

class MockCancelDownloadsForReciterUseCase extends Mock
    implements CancelDownloadsForReciterUseCase {}

class MockObserveReciterDownloadsUseCase extends Mock
    implements ObserveReciterDownloadsUseCase {}

void main() {
  late ReciterDownloadBloc bloc;
  late MockDownloadAllSurahsUseCase downloadAllSurahs;
  late MockCancelDownloadsForReciterUseCase cancelDownloadsForReciter;
  late MockObserveReciterDownloadsUseCase observeReciterDownloads;
  late StreamController<DownloadItem> downloadUpdatesController;

  setUp(() {
    downloadAllSurahs = MockDownloadAllSurahsUseCase();
    cancelDownloadsForReciter = MockCancelDownloadsForReciterUseCase();
    observeReciterDownloads = MockObserveReciterDownloadsUseCase();

    downloadUpdatesController = StreamController<DownloadItem>.broadcast();
    when(
      () => observeReciterDownloads(any()),
    ).thenAnswer((_) => downloadUpdatesController.stream);

    bloc = ReciterDownloadBloc(
      downloadAllSurahs,
      cancelDownloadsForReciter,
      observeReciterDownloads,
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
      bloc.add(
        const InitializeReciterDownload(
          reciterName: 'Mishary',
          totalSurahs: 2,
          downloadedSurahIds: [],
        ),
      );
      await Future.delayed(Duration.zero);

      // 1. Surah 1 starts downloading
      downloadUpdatesController.add(
        DownloadItem(
          id: '1',
          url: 'url1',
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
          url: 'url1',
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

      // 3. Surah 2 starts
      downloadUpdatesController.add(
        DownloadItem(
          id: '2',
          url: 'url2',
          title: 'S2',
          filePath: '',
          reciterName: 'Mishary',
          status: DownloadStatus.pending,
          progress: 0.0,
          fileSize: 100,
          downloadedSize: 0,
          createdAt: DateTime.now(),
        ),
      );

      await Future.delayed(Duration.zero);
      expect(bloc.state.isDownloadingAll, isTrue);

      // 4. Surah 2 fails
      downloadUpdatesController.add(
        DownloadItem(
          id: '2',
          url: 'url2',
          title: 'S2',
          filePath: '',
          reciterName: 'Mishary',
          status: DownloadStatus.failed,
          progress: 0.0,
          fileSize: 100,
          downloadedSize: 0,
          createdAt: DateTime.now(),
        ),
      );

      await Future.delayed(Duration.zero);
      expect(bloc.state.isDownloadingAll, isFalse);
      expect(bloc.state.downloadedCount, equals(1));
    });
  });
}
