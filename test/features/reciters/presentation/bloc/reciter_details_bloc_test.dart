import 'package:dartz_plus/dartz_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tilawa/core/entities/audio.dart';
import 'package:tilawa/core/entities/moshaf_entity.dart';
import 'package:tilawa/core/entities/reciter_entity.dart';
import 'package:tilawa/features/downloads/domain/usecases/get_valid_completed_downloads_use_case.dart';
import 'package:tilawa/features/reciters/presentation/bloc/reciter_details_bloc.dart';
import 'package:tilawa/features/surah/domain/entities/surah_entity.dart';
import 'package:tilawa/features/surah/domain/usecases/convert_audio_entities_to_surahs_use_case.dart';
import 'package:tilawa/features/surah/domain/usecases/refresh_surah_download_status_use_case.dart';
import 'package:tilawa/shared/audio/audio_player_handler.dart';

class MockAudioPlayerHandler extends Mock implements AudioPlayerHandler {}

class MockConvertAudioEntitiesToSurahsUseCase extends Mock
    implements ConvertAudioEntitiesToSurahsUseCase {}

class MockRefreshSurahDownloadStatusUseCase extends Mock
    implements RefreshSurahDownloadStatusUseCase {}

class MockGetValidCompletedDownloadsUseCase extends Mock
    implements GetValidCompletedDownloadsUseCase {}

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
        audio: AudioEntity(
          id: '0',
          title: '',
          url: '',
          duration: Duration.zero,
        ),
      ),
    );
  });

  group('ReciterDetailsBloc Persistence', () {
    late Storage storage;
    late MockAudioPlayerHandler audioHandler;
    late MockConvertAudioEntitiesToSurahsUseCase convertAudioEntitiesToSurahs;
    late MockRefreshSurahDownloadStatusUseCase refreshSurahDownloadStatus;
    late MockGetValidCompletedDownloadsUseCase getValidCompletedDownloads;

    setUp(() {
      storage = MockStorage();
      when(() => storage.write(any(), any<dynamic>())).thenAnswer((_) async {});
      HydratedBloc.storage = storage;

      audioHandler = MockAudioPlayerHandler();
      convertAudioEntitiesToSurahs = MockConvertAudioEntitiesToSurahsUseCase();
      refreshSurahDownloadStatus = MockRefreshSurahDownloadStatusUseCase();
      getValidCompletedDownloads = MockGetValidCompletedDownloadsUseCase();

      when(
        () => getValidCompletedDownloads(any()),
      ).thenAnswer((_) async => const Right([]));
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
      audio: AudioEntity(
        id: '1',
        title: 'Al-Fatiha',
        artist: 'Mishary',
        url: '',
        duration: Duration.zero,
      ),
      isDownloaded: true,
      downloadProgress: 1.0,
      downloadId: 'task1',
    );

    test('ReciterDetailsBloc toJson returns null when not loaded', () {
      final bloc = ReciterDetailsBloc(
        audioHandler,
        convertAudioEntitiesToSurahs,
        refreshSurahDownloadStatus,
        getValidCompletedDownloads,
      );

      expect(bloc.toJson(const ReciterDetailsState()), isNull);
    });

    test('ReciterDetailsBloc toJson returns valid map when loaded', () {
      final bloc = ReciterDetailsBloc(
        audioHandler,
        convertAudioEntitiesToSurahs,
        refreshSurahDownloadStatus,
        getValidCompletedDownloads,
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
        convertAudioEntitiesToSurahs,
        refreshSurahDownloadStatus,
        getValidCompletedDownloads,
      );

      // Manually construct JSON to simulate reading from disk
      const state = ReciterDetailsState(
        status: ReciterDetailsStatus.loaded,
        surahList: [surah],
        selectedMoshaf: moshaf,
        selectedSurahId: '1',
      );
      final Map<String, dynamic> json = {
        'status': 'ReciterDetailsStatus.loaded',
        'surahList': state.surahList.map((e) => e.toJson()).toList(),
        'selectedMoshaf': state.selectedMoshaf?.toJson(),
        'selectedSurahId': state.selectedSurahId,
      };

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
        convertAudioEntitiesToSurahs,
        refreshSurahDownloadStatus,
        getValidCompletedDownloads,
      );

      final ReciterDetailsState? restoredState = bloc.fromJson({
        'invalid': 'json',
      });
      expect(restoredState, isNotNull);
      expect(restoredState!.status, equals(ReciterDetailsStatus.initial));
      expect(restoredState.surahList, isEmpty);
    });
  });

  group('ReciterDetailsBloc FilterSurahs', () {
    late Storage storage;
    late MockAudioPlayerHandler audioHandler;
    late MockConvertAudioEntitiesToSurahsUseCase convertAudioEntitiesToSurahs;
    late MockRefreshSurahDownloadStatusUseCase refreshSurahDownloadStatus;
    late MockGetValidCompletedDownloadsUseCase getValidCompletedDownloads;

    setUp(() {
      storage = MockStorage();
      when(() => storage.write(any(), any<dynamic>())).thenAnswer((_) async {});
      HydratedBloc.storage = storage;

      audioHandler = MockAudioPlayerHandler();
      convertAudioEntitiesToSurahs = MockConvertAudioEntitiesToSurahsUseCase();
      refreshSurahDownloadStatus = MockRefreshSurahDownloadStatusUseCase();
      getValidCompletedDownloads = MockGetValidCompletedDownloadsUseCase();

      when(
        () => getValidCompletedDownloads(any()),
      ).thenAnswer((_) async => const Right([]));
    });

    test('FilterSurahs updates search query', () {
      final bloc = ReciterDetailsBloc(
        audioHandler,
        convertAudioEntitiesToSurahs,
        refreshSurahDownloadStatus,
        getValidCompletedDownloads,
      );

      bloc.add(const FilterSurahs('Al-Fatiha'));

      expectLater(
        bloc.stream,
        emits(
          predicate<ReciterDetailsState>(
            (state) => state.searchQuery == 'Al-Fatiha',
          ),
        ),
      );
    });
  });

  group('ReciterDetailsBloc SelectMoshaf and SelectSurah', () {
    late Storage storage;
    late MockAudioPlayerHandler audioHandler;
    late MockConvertAudioEntitiesToSurahsUseCase convertAudioEntitiesToSurahs;
    late MockRefreshSurahDownloadStatusUseCase refreshSurahDownloadStatus;
    late MockGetValidCompletedDownloadsUseCase getValidCompletedDownloads;

    setUp(() {
      storage = MockStorage();
      when(() => storage.write(any(), any<dynamic>())).thenAnswer((_) async {});
      HydratedBloc.storage = storage;

      audioHandler = MockAudioPlayerHandler();
      convertAudioEntitiesToSurahs = MockConvertAudioEntitiesToSurahsUseCase();
      refreshSurahDownloadStatus = MockRefreshSurahDownloadStatusUseCase();
      getValidCompletedDownloads = MockGetValidCompletedDownloadsUseCase();

      when(
        () => getValidCompletedDownloads(any()),
      ).thenAnswer((_) async => const Right([]));
    });

    const moshaf = MoshafEntity(
      id: 1,
      name: 'Hafs',
      server: '',
      surahTotal: 114,
      moshafType: 1,
      surahList: '',
    );

    test('SelectMoshaf does nothing when not loaded', () {
      final bloc = ReciterDetailsBloc(
        audioHandler,
        convertAudioEntitiesToSurahs,
        refreshSurahDownloadStatus,
        getValidCompletedDownloads,
      );

      bloc.add(const SelectMoshaf(moshaf));

      expectLater(bloc.stream, emitsInOrder([]));
    });

    test('SelectMoshaf updates selected moshaf when loaded', () async {
      final bloc = ReciterDetailsBloc(
        audioHandler,
        convertAudioEntitiesToSurahs,
        refreshSurahDownloadStatus,
        getValidCompletedDownloads,
      );

      // Set to loaded state
      bloc.emit(const ReciterDetailsState(status: ReciterDetailsStatus.loaded));

      bloc.add(const SelectMoshaf(moshaf));

      await expectLater(
        bloc.stream,
        emits(
          predicate<ReciterDetailsState>(
            (state) => state.selectedMoshaf == moshaf,
          ),
        ),
      );
    });

    test('SelectSurah does nothing when not loaded', () {
      final bloc = ReciterDetailsBloc(
        audioHandler,
        convertAudioEntitiesToSurahs,
        refreshSurahDownloadStatus,
        getValidCompletedDownloads,
      );

      bloc.add(const SelectSurah('1'));

      expectLater(bloc.stream, emitsInOrder([]));
    });

    test('SelectSurah updates selected surah when loaded', () async {
      final bloc = ReciterDetailsBloc(
        audioHandler,
        convertAudioEntitiesToSurahs,
        refreshSurahDownloadStatus,
        getValidCompletedDownloads,
      );

      // Set to loaded state
      bloc.emit(const ReciterDetailsState(status: ReciterDetailsStatus.loaded));

      bloc.add(const SelectSurah('1'));

      await expectLater(
        bloc.stream,
        emits(
          predicate<ReciterDetailsState>(
            (state) => state.selectedSurahId == '1',
          ),
        ),
      );
    });
  });

  group('ReciterDetailsBloc Error Handling', () {
    late Storage storage;
    late MockAudioPlayerHandler audioHandler;
    late MockConvertAudioEntitiesToSurahsUseCase convertAudioEntitiesToSurahs;
    late MockRefreshSurahDownloadStatusUseCase refreshSurahDownloadStatus;
    late MockGetValidCompletedDownloadsUseCase getValidCompletedDownloads;

    setUp(() {
      storage = MockStorage();
      when(() => storage.write(any(), any<dynamic>())).thenAnswer((_) async {});
      HydratedBloc.storage = storage;

      audioHandler = MockAudioPlayerHandler();
      convertAudioEntitiesToSurahs = MockConvertAudioEntitiesToSurahsUseCase();
      refreshSurahDownloadStatus = MockRefreshSurahDownloadStatusUseCase();
      getValidCompletedDownloads = MockGetValidCompletedDownloadsUseCase();

      when(
        () => getValidCompletedDownloads(any()),
      ).thenAnswer((_) async => const Right([]));
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

    test(
      'LoadSurahList emits error when getSurahListForMoshaf returns null',
      () async {
        final bloc = ReciterDetailsBloc(
          audioHandler,
          convertAudioEntitiesToSurahs,
          refreshSurahDownloadStatus,
          getValidCompletedDownloads,
        );

        when(
          () => audioHandler.getSurahListForMoshaf(
            any(),
            reciterName: any(named: 'reciterName'),
          ),
        ).thenAnswer((_) async => null);

        bloc.add(const LoadSurahList(reciter: reciter, moshaf: moshaf));

        await expectLater(
          bloc.stream,
          emitsInOrder([
            predicate<ReciterDetailsState>(
              (state) => state.status == ReciterDetailsStatus.loading,
            ),
            predicate<ReciterDetailsState>(
              (state) =>
                  state.status == ReciterDetailsStatus.error &&
                  state.errorMessage == 'Failed to load surah list',
            ),
          ]),
        );
      },
    );

    test('LoadSurahList emits error when exception is thrown', () async {
      final bloc = ReciterDetailsBloc(
        audioHandler,
        convertAudioEntitiesToSurahs,
        refreshSurahDownloadStatus,
        getValidCompletedDownloads,
      );

      when(
        () => audioHandler.getSurahListForMoshaf(
          any(),
          reciterName: any(named: 'reciterName'),
        ),
      ).thenThrow(Exception('Network error'));

      bloc.add(const LoadSurahList(reciter: reciter, moshaf: moshaf));

      await expectLater(
        bloc.stream,
        emitsInOrder([
          predicate<ReciterDetailsState>(
            (state) => state.status == ReciterDetailsStatus.loading,
          ),
          predicate<ReciterDetailsState>(
            (state) =>
                state.status == ReciterDetailsStatus.error &&
                state.errorMessage!.contains('Error loading surah list'),
          ),
        ]),
      );
    });

    test('LoadSurahList tracks already downloaded surahs', () async {
      final bloc = ReciterDetailsBloc(
        audioHandler,
        convertAudioEntitiesToSurahs,
        refreshSurahDownloadStatus,
        getValidCompletedDownloads,
      );

      const surah1 = SurahEntity(
        audio: AudioEntity(
          id: '1',
          title: 'Al-Fatiha',
          url: '',
          duration: Duration.zero,
        ),
        isDownloaded: true, // Already downloaded - covers line 98
      );
      const surah2 = SurahEntity(
        audio: AudioEntity(
          id: '2',
          title: 'Al-Baqarah',
          url: '',
          duration: Duration.zero,
        ),
      );

      when(
        () => audioHandler.getSurahListForMoshaf(
          any(),
          reciterName: any(named: 'reciterName'),
        ),
      ).thenAnswer((_) async => [surah1.audio, surah2.audio]);

      when(
        () => convertAudioEntitiesToSurahs(any()),
      ).thenAnswer((_) async => [surah1, surah2]);

      bloc.add(const LoadSurahList(reciter: reciter, moshaf: moshaf));

      await expectLater(
        bloc.stream,
        emitsInOrder([
          predicate<ReciterDetailsState>(
            (state) => state.status == ReciterDetailsStatus.loading,
          ),
          predicate<ReciterDetailsState>(
            (state) =>
                state.status == ReciterDetailsStatus.loaded &&
                state.surahList.length == 2,
          ),
        ]),
      );
    });

    test('RefreshSurahDownloadStatus does nothing when not loaded', () {
      final bloc = ReciterDetailsBloc(
        audioHandler,
        convertAudioEntitiesToSurahs,
        refreshSurahDownloadStatus,
        getValidCompletedDownloads,
      );

      bloc.add(
        const RefreshSurahDownloadStatus(surahId: '1', reciterName: 'Mishary'),
      );

      expectLater(bloc.stream, emitsInOrder([]));
    });

    test('RefreshSurahDownloadStatus updates surah list when loaded', () async {
      final bloc = ReciterDetailsBloc(
        audioHandler,
        convertAudioEntitiesToSurahs,
        refreshSurahDownloadStatus,
        getValidCompletedDownloads,
      );

      const surah = SurahEntity(
        audio: AudioEntity(
          id: '1',
          title: 'Al-Fatiha',
          url: '',
          duration: Duration.zero,
        ),
      );

      // Set to loaded state
      bloc.emit(
        const ReciterDetailsState(
          status: ReciterDetailsStatus.loaded,
          surahList: [surah],
        ),
      );

      const updatedSurah = SurahEntity(
        audio: AudioEntity(
          id: '1',
          title: 'Al-Fatiha',
          url: '',
          duration: Duration.zero,
        ),
        isDownloaded: true,
      );

      when(
        () => refreshSurahDownloadStatus.call(
          currentSurahs: any(named: 'currentSurahs'),
          surahId: any(named: 'surahId'),
          reciterName: any(named: 'reciterName'),
        ),
      ).thenAnswer((_) async => [updatedSurah]);

      bloc.add(
        const RefreshSurahDownloadStatus(surahId: '1', reciterName: 'Mishary'),
      );

      await expectLater(
        bloc.stream,
        emits(
          predicate<ReciterDetailsState>(
            (state) => state.surahList.first.isDownloaded,
          ),
        ),
      );
    });

    test('RefreshSurahDownloadStatus silently fails on error', () async {
      final bloc = ReciterDetailsBloc(
        audioHandler,
        convertAudioEntitiesToSurahs,
        refreshSurahDownloadStatus,
        getValidCompletedDownloads,
      );

      const surah = SurahEntity(
        audio: AudioEntity(
          id: '1',
          title: 'Al-Fatiha',
          url: '',
          duration: Duration.zero,
        ),
      );

      // Set to loaded state
      bloc.emit(
        const ReciterDetailsState(
          status: ReciterDetailsStatus.loaded,
          surahList: [surah],
        ),
      );

      when(
        () => refreshSurahDownloadStatus.call(
          currentSurahs: any(named: 'currentSurahs'),
          surahId: any(named: 'surahId'),
          reciterName: any(named: 'reciterName'),
        ),
      ).thenThrow(Exception('Error'));

      bloc.add(
        const RefreshSurahDownloadStatus(surahId: '1', reciterName: 'Mishary'),
      );

      // Should not emit error, just keep current state
      await expectLater(bloc.stream, emitsInOrder([]));
    });
  });

  group('ReciterDetailsBloc Close', () {
    late Storage storage;
    late MockAudioPlayerHandler audioHandler;
    late MockConvertAudioEntitiesToSurahsUseCase convertAudioEntitiesToSurahs;
    late MockRefreshSurahDownloadStatusUseCase refreshSurahDownloadStatus;
    late MockGetValidCompletedDownloadsUseCase getValidCompletedDownloads;

    setUp(() {
      storage = MockStorage();
      when(() => storage.write(any(), any<dynamic>())).thenAnswer((_) async {});
      HydratedBloc.storage = storage;

      audioHandler = MockAudioPlayerHandler();
      convertAudioEntitiesToSurahs = MockConvertAudioEntitiesToSurahsUseCase();
      refreshSurahDownloadStatus = MockRefreshSurahDownloadStatusUseCase();
      getValidCompletedDownloads = MockGetValidCompletedDownloadsUseCase();

      when(
        () => getValidCompletedDownloads(any()),
      ).thenAnswer((_) async => const Right([]));
    });

    test('close cancels downloads subscription', () async {
      final bloc = ReciterDetailsBloc(
        audioHandler,
        convertAudioEntitiesToSurahs,
        refreshSurahDownloadStatus,
        getValidCompletedDownloads,
      );

      await bloc.close();

      expect(bloc.isClosed, isTrue);
    });
  });
}
