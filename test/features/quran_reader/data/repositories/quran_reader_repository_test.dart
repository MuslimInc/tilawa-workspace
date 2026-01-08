import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tilawa/features/quran_reader/data/datasources/datasources.dart';
import 'package:tilawa/features/quran_reader/data/repositories/quran_reader_repository_impl.dart';
import 'package:tilawa/features/quran_reader/domain/entities/entities.dart';

class MockQuranDataSource extends Mock implements QuranDataSource {}

class MockReaderSettingsDataSource extends Mock
    implements ReaderSettingsDataSource {}

class MockSearchRemoteDataSource extends Mock
    implements SearchRemoteDataSource {}

void main() {
  setUpAll(() {
    registerFallbackValue(const ReaderSettingsEntity());
  });

  late MockQuranDataSource quranDataSource;
  late MockReaderSettingsDataSource readerSettingsDataSource;
  late MockSearchRemoteDataSource searchRemoteDataSource;
  late QuranReaderRepositoryImpl repository;

  setUp(() {
    quranDataSource = MockQuranDataSource();
    readerSettingsDataSource = MockReaderSettingsDataSource();
    searchRemoteDataSource = MockSearchRemoteDataSource();
    repository = QuranReaderRepositoryImpl(
      quranDataSource,
      readerSettingsDataSource,
      searchRemoteDataSource,
    );
  });

  const tAyah = AyahEntity(
    number: 1,
    numberInSurah: 1,
    surahNumber: 1,
    text: 'Test Text',
    page: 1,
  );

  group('Simple delegation methods', () {
    test('getSurahContent should delegate to quranDataSource', () async {
      const tSurah = SurahContentEntity(
        number: 1,
        name: 'test',
        nameEnglish: 'test',
        nameTranslation: 'test',
        revelationType: 'test',
        numberOfAyahs: 7,
        ayahs: [],
      );
      when(
        () => quranDataSource.getSurahContent(any()),
      ).thenAnswer((_) async => tSurah);

      final SurahContentEntity result = await repository.getSurahContent(1);

      expect(result, tSurah);
      verify(() => quranDataSource.getSurahContent(1)).called(1);
    });

    test('getAyah should delegate to quranDataSource', () async {
      when(
        () => quranDataSource.getAyah(
          surahNumber: any(named: 'surahNumber'),
          ayahNumber: any(named: 'ayahNumber'),
        ),
      ).thenAnswer((_) async => tAyah);

      final AyahEntity? result = await repository.getAyah(
        surahNumber: 1,
        ayahNumber: 1,
      );

      expect(result, tAyah);
      verify(
        () => quranDataSource.getAyah(surahNumber: 1, ayahNumber: 1),
      ).called(1);
    });

    test('getPage should delegate to quranDataSource', () async {
      const tPage = QuranPageEntity(pageNumber: 1, ayahs: [], juz: 1, hizb: 1);
      when(() => quranDataSource.getPage(any())).thenAnswer((_) async => tPage);

      final QuranPageEntity result = await repository.getPage(1);

      expect(result, tPage);
      verify(() => quranDataSource.getPage(1)).called(1);
    });

    test('getJuz should delegate to quranDataSource', () async {
      when(
        () => quranDataSource.getJuz(any()),
      ).thenAnswer((_) async => [tAyah]);

      final List<AyahEntity> result = await repository.getJuz(1);

      expect(result, [tAyah]);
      verify(() => quranDataSource.getJuz(1)).called(1);
    });

    test('searchSurahs should delegate to quranDataSource', () async {
      when(
        () => quranDataSource.searchSurahs(any()),
      ).thenAnswer((_) async => []);

      final List<SurahContentEntity> result = await repository.searchSurahs(
        'test',
      );

      expect(result, isEmpty);
      verify(() => quranDataSource.searchSurahs('test')).called(1);
    });
  });

  group('searchAyahs', () {
    const tQuery = 'test';
    const tVerseKey = '1:1';

    test(
      'should return cleaned remote results when remote search is successful',
      () async {
        when(() => searchRemoteDataSource.search(any())).thenAnswer(
          (_) async => [
            RemoteSearchResult(verseKey: tVerseKey, translation: '<p>Test</p>'),
          ],
        );
        when(
          () => quranDataSource.getAyah(
            surahNumber: any(named: 'surahNumber'),
            ayahNumber: any(named: 'ayahNumber'),
          ),
        ).thenAnswer((_) async => tAyah);

        final List<AyahEntity> result = await repository.searchAyahs(tQuery);

        expect(result, isNotEmpty);
        expect(result.first.translation, 'Test');
        verify(() => searchRemoteDataSource.search(tQuery)).called(1);
      },
    );

    test('should fallback to local search when remote returns empty', () async {
      when(
        () => searchRemoteDataSource.search(any()),
      ).thenAnswer((_) async => []);
      when(
        () => quranDataSource.searchAyahs(any()),
      ).thenAnswer((_) async => [tAyah]);

      final List<AyahEntity> result = await repository.searchAyahs(tQuery);

      expect(result, [tAyah]);
      verify(() => quranDataSource.searchAyahs(tQuery)).called(1);
    });
  });

  group('Settings management', () {
    test('saveSettings should delegate to readerSettingsDataSource', () async {
      const tSettings = ReaderSettingsEntity();
      when(
        () => readerSettingsDataSource.saveSettings(any()),
      ).thenAnswer((_) async {});

      await repository.saveSettings(tSettings);

      verify(() => readerSettingsDataSource.saveSettings(tSettings)).called(1);
    });

    test('loadSettings should delegate to readerSettingsDataSource', () async {
      const tSettings = ReaderSettingsEntity();
      when(
        () => readerSettingsDataSource.loadSettings(),
      ).thenAnswer((_) async => tSettings);

      final ReaderSettingsEntity result = await repository.loadSettings();

      expect(result, tSettings);
      verify(() => readerSettingsDataSource.loadSettings()).called(1);
    });

    test(
      'saveLastReadPosition should delegate to readerSettingsDataSource',
      () async {
        when(
          () => readerSettingsDataSource.saveLastReadPosition(
            surahNumber: any(named: 'surahNumber'),
            ayahNumber: any(named: 'ayahNumber'),
            page: any(named: 'page'),
          ),
        ).thenAnswer((_) async {});

        await repository.saveLastReadPosition(
          surahNumber: 1,
          ayahNumber: 1,
          page: 1,
        );

        verify(
          () => readerSettingsDataSource.saveLastReadPosition(
            surahNumber: 1,
            ayahNumber: 1,
            page: 1,
          ),
        ).called(1);
      },
    );

    test(
      'getLastReadPosition should delegate to readerSettingsDataSource',
      () async {
        const ({int ayahNumber, int page, int surahNumber}) tPos = (
          surahNumber: 1,
          ayahNumber: 1,
          page: 1,
        );
        when(
          () => readerSettingsDataSource.getLastReadPosition(),
        ).thenAnswer((_) async => tPos);

        final ({int? ayahNumber, int? page, int? surahNumber}) result =
            await repository.getLastReadPosition();

        expect(result, tPos);
        verify(() => readerSettingsDataSource.getLastReadPosition()).called(1);
      },
    );
  });

  group('Unimplemented/Future methods', () {
    test('getTranslation should return null', () async {
      final String? result = await repository.getTranslation(
        surahNumber: 1,
        ayahNumber: 1,
        language: 'en',
      );
      expect(result, isNull);
    });

    test('getSurahTranslations should return empty map', () async {
      final Map<int, String> result = await repository.getSurahTranslations(
        surahNumber: 1,
        language: 'en',
      );
      expect(result, isEmpty);
    });

    test('totalJuz should throw UnimplementedError', () {
      expect(() => repository.totalJuz, throwsUnimplementedError);
    });

    test('totalPages should throw UnimplementedError', () {
      expect(() => repository.totalPages, throwsUnimplementedError);
    });
  });
}
