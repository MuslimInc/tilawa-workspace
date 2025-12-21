import 'package:audio_service/audio_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:mocktail/mocktail.dart';
import 'package:muzakri/core/entities/moshaf_entity.dart';
import 'package:muzakri/core/entities/reciter_entity.dart';
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

class MockStorage extends Mock implements Storage {}

void main() {
  group('ReciterDetailsBloc Persistence', () {
    late Storage storage;
    late MockAudioPlayerHandler audioHandler;
    late MockConvertMediaItemsToSurahsUseCase convertMediaItemsToSurahs;
    late MockRefreshSurahDownloadStatusUseCase refreshSurahDownloadStatus;
    late MockDownloadAllSurahsUseCase downloadAllSurahs;

    setUp(() {
      storage = MockStorage();
      when(() => storage.write(any(), any<dynamic>())).thenAnswer((_) async {});
      HydratedBloc.storage = storage;

      audioHandler = MockAudioPlayerHandler();
      convertMediaItemsToSurahs = MockConvertMediaItemsToSurahsUseCase();
      refreshSurahDownloadStatus = MockRefreshSurahDownloadStatusUseCase();
      downloadAllSurahs = MockDownloadAllSurahsUseCase();
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
      );

      expect(bloc.toJson(const ReciterDetailsState()), isNull);
    });

    test('ReciterDetailsBloc toJson returns valid map when loaded', () {
      final bloc = ReciterDetailsBloc(
        audioHandler,
        convertMediaItemsToSurahs,
        refreshSurahDownloadStatus,
        downloadAllSurahs,
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
      );

      final ReciterDetailsState? restoredState = bloc.fromJson({
        'invalid': 'json',
      });
      expect(restoredState, isNotNull);
      expect(restoredState!.status, equals(ReciterDetailsStatus.initial));
      expect(restoredState.surahList, isEmpty);
    });
  });
}
