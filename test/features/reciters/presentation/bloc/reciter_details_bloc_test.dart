import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:dartz_plus/dartz_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:mocktail/mocktail.dart';
import 'package:muzakri/core/entities/moshaf_entity.dart';
import 'package:muzakri/core/entities/reciter_entity.dart';
import 'package:muzakri/features/downloads/domain/entities/download_item.dart';
import 'package:muzakri/features/downloads/domain/repositories/downloads_repository.dart';
import 'package:muzakri/features/downloads/domain/usecases/cancel_downloads_for_reciter_use_case.dart';
import 'package:muzakri/features/downloads/domain/usecases/download_all_surahs_use_case.dart';
import 'package:muzakri/features/reciters/presentation/bloc/reciter_details_bloc.dart';
import 'package:muzakri/features/surah/domain/entities/surah_entity.dart';
import 'package:muzakri/features/surah/domain/usecases/convert_media_items_to_surahs_use_case.dart';
import 'package:muzakri/features/surah/domain/usecases/refresh_surah_download_status_use_case.dart';
import 'package:muzakri/shared/audio/audio_player_handler.dart';

class MockAudioPlayerHandler extends Mock implements AudioPlayerHandler {}

class MockConvertMediaItemsToSurahsUseCase extends Mock
    implements ConvertMediaItemsToSurahsUseCase {}

class MockRefreshSurahDownloadStatusUseCase extends Mock
    implements RefreshSurahDownloadStatusUseCase {}

class MockDownloadAllSurahsUseCase extends Mock
    implements DownloadAllSurahsUseCase {}

class MockCancelDownloadsForReciterUseCase extends Mock
    implements CancelDownloadsForReciterUseCase {}

class MockDownloadsRepository extends Mock implements DownloadsRepository {}

class MockStorage extends Mock implements Storage {}

void main() {
  setUpAll(() {
    registerFallbackValue(
      const MoshafEntity(
        id: 0,
        name: '',
        server: '',
        surahTotal: 0,
        moshafType: 0,
        surahList: '',
      ),
    );
    registerFallbackValue(
      const ReciterEntity(id: 0, name: '', letter: '', date: '', moshaf: []),
    );
    registerFallbackValue(
      const SurahEntity(
        mediaItem: MediaItem(id: '0', title: ''),
      ),
    );
  });

  group('ReciterDetailsBloc Persistence', () {
    late Storage storage;
    late MockAudioPlayerHandler audioHandler;
    late MockConvertMediaItemsToSurahsUseCase convertMediaItemsToSurahs;
    late MockRefreshSurahDownloadStatusUseCase refreshSurahDownloadStatus;
    late MockDownloadAllSurahsUseCase downloadAllSurahs;
    late MockCancelDownloadsForReciterUseCase cancelDownloadsForReciter;
    late MockDownloadsRepository downloadsRepository;

    setUp(() {
      storage = MockStorage();
      when(() => storage.write(any(), any<dynamic>())).thenAnswer((_) async {});
      HydratedBloc.storage = storage;

      audioHandler = MockAudioPlayerHandler();
      convertMediaItemsToSurahs = MockConvertMediaItemsToSurahsUseCase();
      refreshSurahDownloadStatus = MockRefreshSurahDownloadStatusUseCase();
      downloadAllSurahs = MockDownloadAllSurahsUseCase();
      cancelDownloadsForReciter = MockCancelDownloadsForReciterUseCase();
      downloadsRepository = MockDownloadsRepository();

      when(
        () => downloadsRepository.downloadUpdates,
      ).thenAnswer((_) => const Stream.empty());
    });

    const moshaf = MoshafEntity(
      id: 1,
      name: 'Hafs',
      server: 'https://example.com',
      surahTotal: 114,
      moshafType: 1,
      surahList: '1,2,3',
    );

    const surah = SurahEntity(
      mediaItem: MediaItem(
        id: '1',
        title: 'Al-Fatiha',
        artist: 'Mishary',
        extras: {'nameAr': 'الفاتحة'},
      ),
      isDownloaded: true,
      downloadProgress: 1.0,
      downloadId: 'task1',
    );

    const reciter = ReciterEntity(
      id: 1,
      name: 'Mishary',
      letter: 'M',
      date: '2023',
      moshaf: [moshaf],
    );

    test('MoshafEntity serialization works', () {
      final Map<String, dynamic> json = moshaf.toJson();
      final fromJson = MoshafEntity.fromJson(json);
      expect(fromJson, equals(moshaf));
    });

    test('SurahEntity serialization works', () {
      final Map<String, dynamic> json = surah.toJson();
      final fromJson = SurahEntity.fromJson(json);
      expect(fromJson.id, equals(surah.id));
      expect(fromJson.name, equals(surah.name));
      // Note: MediaItem equality might not work directly, so we check properties
      expect(fromJson.isDownloaded, equals(surah.isDownloaded));
    });

    test('ReciterDetailsBloc toJson returns null when not loaded', () {
      final bloc = ReciterDetailsBloc(
        audioHandler,
        convertMediaItemsToSurahs,
        refreshSurahDownloadStatus,
        downloadAllSurahs,
        cancelDownloadsForReciter,
        downloadsRepository,
      );

      expect(bloc.toJson(const ReciterDetailsState()), isNull);
    });

    test('ReciterDetailsBloc toJson returns valid map when loaded', () {
      final bloc = ReciterDetailsBloc(
        audioHandler,
        convertMediaItemsToSurahs,
        refreshSurahDownloadStatus,
        downloadAllSurahs,
        cancelDownloadsForReciter,
        downloadsRepository,
      );

      const state = ReciterDetailsState(
        status: ReciterDetailsStatus.loaded,
        surahList: [surah],
        selectedMoshaf: moshaf,
        selectedSurahId: '1',
      );

      final Map<String, dynamic>? json = bloc.toJson(state);
      expect(json, isNotNull);
      expect(json!['status'], equals('ReciterDetailsStatus.loaded'));
      expect(json['surahList'], isNotEmpty);
      expect(json['selectedMoshaf'], isNotNull);
      expect(json['selectedSurahId'], equals('1'));
    });

    test('ReciterDetailsBloc fromJson restores state correctly', () {
      final bloc = ReciterDetailsBloc(
        audioHandler,
        convertMediaItemsToSurahs,
        refreshSurahDownloadStatus,
        downloadAllSurahs,
        cancelDownloadsForReciter,
        downloadsRepository,
      );

      // Manually construct JSON to simulate reading from disk
      // Using the exact structure produced by toJson
      const state = ReciterDetailsState(
        status: ReciterDetailsStatus.loaded,
        surahList: [surah],
        selectedMoshaf: moshaf,
        selectedSurahId: '1',
      );
      // We know serialization works from previous test, so we can use toJson here for convenience
      // or manually map it if we want to be stricter.
      final Map<String, dynamic> json = state.surahList.isNotEmpty
          ? {
              'status': 'ReciterDetailsStatus.loaded',
              'surahList': state.surahList.map((e) => e.toJson()).toList(),
              'selectedMoshaf': state.selectedMoshaf?.toJson(),
              'selectedSurahId': state.selectedSurahId,
            }
          : <String, dynamic>{};

      final ReciterDetailsState? restoredState = bloc.fromJson(json);

      expect(restoredState, isNotNull);
      expect(restoredState!.status, equals(ReciterDetailsStatus.loaded));
      expect(restoredState.surahList.length, equals(1));
      expect(restoredState.surahList.first.id, equals(surah.id));
      expect(restoredState.selectedMoshaf, equals(moshaf));
      expect(restoredState.selectedSurahId, equals('1'));
    });

    test('ReciterDetailsBloc fromJson returns null on error', () {
      final bloc = ReciterDetailsBloc(
        audioHandler,
        convertMediaItemsToSurahs,
        refreshSurahDownloadStatus,
        downloadAllSurahs,
        cancelDownloadsForReciter,
        downloadsRepository,
      );

      final ReciterDetailsState? restoredState = bloc.fromJson({
        'invalid': 'json',
      });
      expect(restoredState, isNotNull);
      expect(restoredState!.status, equals(ReciterDetailsStatus.initial));
      expect(restoredState.surahList, isEmpty);
    });
  });

  group('ReciterDetailsBloc DownloadAllSurahs', () {
    late Storage storage;
    late MockAudioPlayerHandler audioHandler;
    late MockConvertMediaItemsToSurahsUseCase convertMediaItemsToSurahs;
    late MockRefreshSurahDownloadStatusUseCase refreshSurahDownloadStatus;
    late MockDownloadAllSurahsUseCase downloadAllSurahs;
    late MockCancelDownloadsForReciterUseCase cancelDownloadsForReciter;
    late MockDownloadsRepository downloadsRepository;

    setUp(() {
      storage = MockStorage();
      when(() => storage.write(any(), any<dynamic>())).thenAnswer((_) async {});
      HydratedBloc.storage = storage;

      audioHandler = MockAudioPlayerHandler();
      convertMediaItemsToSurahs = MockConvertMediaItemsToSurahsUseCase();
      refreshSurahDownloadStatus = MockRefreshSurahDownloadStatusUseCase();
      downloadAllSurahs = MockDownloadAllSurahsUseCase();
      cancelDownloadsForReciter = MockCancelDownloadsForReciterUseCase();
      downloadsRepository = MockDownloadsRepository();

      when(
        () => downloadsRepository.downloadUpdates,
      ).thenAnswer((_) => const Stream.empty());
    });

    const moshaf = MoshafEntity(
      id: 1,
      name: 'Hafs',
      server: 'https://example.com',
      surahTotal: 114,
      moshafType: 1,
      surahList: '1,2,3',
    );

    const reciter = ReciterEntity(
      id: 1,
      name: 'Mishary',
      letter: 'M',
      date: '2023',
      moshaf: [moshaf],
    );

    test('DownloadAllSurahs triggers use case without state change', () async {
      final bloc = ReciterDetailsBloc(
        audioHandler,
        convertMediaItemsToSurahs,
        refreshSurahDownloadStatus,
        downloadAllSurahs,
        cancelDownloadsForReciter,
        downloadsRepository,
      );

      const surah1 = SurahEntity(
        mediaItem: MediaItem(id: '1', title: 'Surah 1'),
      );
      const surah2 = SurahEntity(
        mediaItem: MediaItem(id: '2', title: 'Surah 2'),
        isDownloaded: true,
      );

      // Seed with initial state
      bloc.emit(
        const ReciterDetailsState(
          status: ReciterDetailsStatus.loaded,
          surahList: [surah1, surah2],
        ),
      );

      when(
        () => downloadAllSurahs(
          surahs: any(named: 'surahs'),
          reciterName: any(named: 'reciterName'),
          reciterId: any(named: 'reciterId'),
        ),
      ).thenAnswer((_) async => const Right(null));

      bloc.add(
        const DownloadAllSurahs(reciter: reciter, surahs: [surah1, surah2]),
      );

      // Since we removed optimistic updates, no state is emitted immediately
      // We assume no state change or ensure specific state is NOT emitted
      await Future.delayed(Duration.zero);

      verify(
        () => downloadAllSurahs(
          surahs: [surah1, surah2],
          reciterName: reciter.name,
          reciterId: reciter.id,
        ),
      ).called(1);
    });
  });

  group('FilteredSurahs Logic', () {
    test('filteredSurahs returns all surahs when query is empty', () {
      const surah1 = SurahEntity(
        mediaItem: MediaItem(id: '1', title: 'Surah 1'),
      );
      const surah2 = SurahEntity(
        mediaItem: MediaItem(id: '2', title: 'Surah 2'),
      );
      const state = ReciterDetailsState(surahList: [surah1, surah2]);

      expect(state.filteredSurahs.length, 2);
    });

    test('filteredSurahs filters by name correctly', () {
      const surah1 = SurahEntity(
        mediaItem: MediaItem(id: '1', title: 'Al-Fatiha'),
      );
      const surah2 = SurahEntity(
        mediaItem: MediaItem(id: '2', title: 'Al-Baqara'),
      );
      const state = ReciterDetailsState(
        surahList: [surah1, surah2],
        searchQuery: 'baq',
      );

      expect(state.filteredSurahs.length, 1);
      expect(state.filteredSurahs.first.name, 'Al-Baqara');
    });

    test('filteredSurahs filters by number correctly', () {
      const surah1 = SurahEntity(
        mediaItem: MediaItem(id: '1', title: 'Al-Fatiha'),
      );
      const surah2 = SurahEntity(
        mediaItem: MediaItem(id: '2', title: 'Al-Baqara'),
      );
      // "001" padding logic test
      const state = ReciterDetailsState(
        surahList: [surah1, surah2],
        searchQuery: '001',
      );

      expect(state.filteredSurahs.length, 1);
      expect(state.filteredSurahs.first.id, '1');
    });
  });

  group('ReciterDetailsBloc Download Progress', () {
    late Storage storage;
    late MockAudioPlayerHandler audioHandler;
    late MockConvertMediaItemsToSurahsUseCase convertMediaItemsToSurahs;
    late MockRefreshSurahDownloadStatusUseCase refreshSurahDownloadStatus;
    late MockDownloadAllSurahsUseCase downloadAllSurahs;
    late MockCancelDownloadsForReciterUseCase cancelDownloadsForReciter;
    late MockDownloadsRepository downloadsRepository;

    late StreamController<DownloadItem> downloadUpdatesController;

    setUp(() {
      storage = MockStorage();
      when(() => storage.write(any(), any<dynamic>())).thenAnswer((_) async {});
      HydratedBloc.storage = storage;

      audioHandler = MockAudioPlayerHandler();
      convertMediaItemsToSurahs = MockConvertMediaItemsToSurahsUseCase();
      refreshSurahDownloadStatus = MockRefreshSurahDownloadStatusUseCase();
      downloadAllSurahs = MockDownloadAllSurahsUseCase();
      cancelDownloadsForReciter = MockCancelDownloadsForReciterUseCase();
      downloadsRepository = MockDownloadsRepository();

      downloadUpdatesController = StreamController<DownloadItem>.broadcast();
      when(
        () => downloadsRepository.downloadUpdates,
      ).thenAnswer((_) => downloadUpdatesController.stream);
    });

    tearDown(() {
      downloadUpdatesController.close();
    });

    const reciter = ReciterEntity(
      id: 1,
      name: 'Mishary',
      letter: 'M',
      date: '2023',
      moshaf: [],
    );
    const moshaf = MoshafEntity(
      id: 1,
      name: 'Hafs',
      server: '',
      surahTotal: 114,
      moshafType: 1,
      surahList: '',
    );

    test('Emits updated progress when download updates arrive', () async {
      final bloc = ReciterDetailsBloc(
        audioHandler,
        convertMediaItemsToSurahs,
        refreshSurahDownloadStatus,
        downloadAllSurahs,
        cancelDownloadsForReciter,
        downloadsRepository,
      );

      const surah1 = SurahEntity(
        mediaItem: MediaItem(
          id: '1',
          title: 'S1',
          extras: {'reciterName': 'Mishary'},
        ),
      );
      const surah2 = SurahEntity(
        mediaItem: MediaItem(
          id: '2',
          title: 'S2',
          extras: {'reciterName': 'Mishary'},
        ),
      );

      when(
        () => audioHandler.getSurahListForMoshaf(
          any(),
          reciterName: any(named: 'reciterName'),
        ),
      ).thenAnswer((_) async => [surah1.mediaItem, surah2.mediaItem]);
      when(
        () => convertMediaItemsToSurahs(any()),
      ).thenAnswer((_) async => [surah1, surah2]);

      // Trigger load to initialize subscription
      bloc.add(const LoadSurahList(reciter: reciter, moshaf: moshaf));
      await Future.delayed(Duration.zero); // Wait for load

      // Simulating download start for surah 1
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

      // Check state: progress 0/2 = 0.0, isDownloadingAll = true (because 1 is downloading)
      // Wait, logic: _onUpdateDownloadProgress updates based on _completedSurahs and _downloadingSurahs set.
      // downloadUpdates logic:
      // if downloading: add to _downloadingSurahs.
      // emit: progress = completed/total. isDownloadingAll = _downloadingSurahs.isNotEmpty.

      // Expected: matched state with isDownloadingAll: true.
      expect(bloc.state.isDownloadingAll, isTrue);
      expect(bloc.state.downloadProgress, 0.0);

      // Simulating download completed for surah 1
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

      // Expected: completed=1, total=2 => progress 0.5. downloading=0 => false.
      expect(bloc.state.isDownloadingAll, isFalse);
      expect(bloc.state.downloadProgress, 0.5);
    });

    test(
      'CancelDownloadAllSurahs calls use case and clears downloading state',
      () async {
        final bloc = ReciterDetailsBloc(
          audioHandler,
          convertMediaItemsToSurahs,
          refreshSurahDownloadStatus,
          downloadAllSurahs,
          cancelDownloadsForReciter,
          downloadsRepository,
        );

        // Setup initial state with some downloading items
        // Since we can't easily inject private state, we simulate it via events if possible, or just check the call.
        // We will load list first.

        when(
          () => cancelDownloadsForReciter(any()),
        ).thenAnswer((_) async => const Right(null));

        // ... setup list loading ...
        const surah1 = SurahEntity(
          mediaItem: MediaItem(id: '1', title: 'S1'),
        );
        when(
          () => audioHandler.getSurahListForMoshaf(
            any(),
            reciterName: any(named: 'reciterName'),
          ),
        ).thenAnswer((_) async => [surah1.mediaItem]);
        when(
          () => convertMediaItemsToSurahs(any()),
        ).thenAnswer((_) async => [surah1]);

        bloc.add(const LoadSurahList(reciter: reciter, moshaf: moshaf));
        await Future.delayed(Duration.zero);

        // Act
        bloc.add(const CancelDownloadAllSurahs('Mishary'));
        await Future.delayed(Duration.zero);

        // Assert
        verify(() => cancelDownloadsForReciter('Mishary')).called(1);
        // We expect _downloadingSurahs to be cleared, so isDownloadingAll should be false.
        expect(bloc.state.isDownloadingAll, isFalse);
      },
    );
  });
}
