import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tilawa/features/quran_reader/data/datasources/quran_datasource.dart';
import 'package:tilawa/features/quran_reader/domain/entities/entities.dart';

class MockDio extends Mock implements Dio {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late QuranDataSourceImpl dataSource;
  late MockDio mockDio;

  const Map<String, Object> tQuranData = {
    'code': 200,
    'status': 'OK',
    'data': {
      'surahs': [
        {
          'number': 1,
          'name': 'سُورَةُ ٱلْفَاتِحَةِ',
          'englishName': 'Al-Faatiha',
          'englishNameTranslation': 'The Opening',
          'revealationType': 'Meccan',
          'ayahs': [
            {
              'number': 1,
              'text': 'بِسْمِ ٱللَّهِ ٱلرَّحْمَٰنِ ٱلرَّحِيمِ',
              'numberInSurah': 1,
              'juz': 1,
              'manzil': 1,
              'page': 1,
              'ruku': 1,
              'hizbQuarter': 1,
              'sajda': false,
            },
            {
              'number': 2,
              'text': 'ٱلْحَمْدُ لِلَّهِ رَبِّ ٱلْعَٰلَمِينَ',
              'numberInSurah': 2,
              'juz': 1,
              'manzil': 1,
              'page': 1,
              'ruku': 1,
              'hizbQuarter': 1,
              'sajda': false,
            },
          ],
        },
      ],
    },
  };

  setUp(() {
    mockDio = MockDio();
    dataSource = QuranDataSourceImpl(dio: mockDio);
  });

  void setupMockAsset({Map<String, dynamic>? data, bool fail = false}) {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMessageHandler('flutter/assets', (message) async {
          if (fail) return null;
          final Uint8List encoded = utf8.encoder.convert(
            jsonEncode(data ?? tQuranData),
          );
          return encoded.buffer.asByteData();
        });
  }

  group('getSurahContent', () {
    test(
      'should return SurahContentEntity when data is loaded successfully',
      () async {
        setupMockAsset();

        final SurahContentEntity result = await dataSource.getSurahContent(1);

        expect(result.number, 1);
        expect(result.nameEnglish, 'Al-Fatiha');
        expect(result.ayahs.length, 2);
      },
    );

    test('should return mock data when asset fails to load', () async {
      setupMockAsset(fail: true);

      final SurahContentEntity result = await dataSource.getSurahContent(1);

      expect(result.number, 1);
      expect(result.ayahs.isNotEmpty, true);
    });

    test('should return mock data when index is out of range', () async {
      setupMockAsset();

      final SurahContentEntity result = await dataSource.getSurahContent(114);

      expect(result.number, 114);
      expect(result.ayahs, isNotEmpty);
    });
  });

  group('getAyah', () {
    test('should return AyahEntity for given surah and ayah number', () async {
      setupMockAsset();

      final AyahEntity? result = await dataSource.getAyah(
        surahNumber: 1,
        ayahNumber: 2,
      );

      expect(result, isNotNull);
      expect(result!.surahNumber, 1);
      expect(result.numberInSurah, 2);
    });
  });

  group('getPage', () {
    test(
      'should return QuranPageEntity with ayahs for the given page',
      () async {
        setupMockAsset();

        final QuranPageEntity result = await dataSource.getPage(1);

        expect(result.pageNumber, 1);
        expect(result.ayahs.length, 2);
      },
    );
  });

  group('getJuz', () {
    test('should return list of ayahs for the given juz', () async {
      setupMockAsset();

      final List<AyahEntity> result = await dataSource.getJuz(1);

      expect(result, isNotEmpty);
      expect(result.every((a) => a.juz == 1), true);
    });
  });

  group('searchAyahs', () {
    test('should return ayahs matching the query', () async {
      setupMockAsset();

      final List<AyahEntity> result = await dataSource.searchAyahs('الحمد');

      expect(result, isNotEmpty);
      expect(result.first.text, contains('ٱلْحَمْدُ'));
    });
  });

  group('searchSurahs', () {
    test('should return surahs matching the query name', () async {
      setupMockAsset();

      final List<SurahContentEntity> result = await dataSource.searchSurahs(
        'Fatiha',
      );

      expect(result, isNotEmpty);
      expect(result.first.nameEnglish, 'Al-Fatiha');
    });
  });

  group('getPageWords', () {
    test('should return map of words when API call is successful', () async {
      final Map<String, List<Map<String, Object>>> tWordsData = {
        'verses': [
          {
            'words': [
              {
                'id': 1,
                'position': 1,
                'text': 'test',
                'text_uthmani': 'test',
                'audio_url': 'test.mp3',
                'code_v1': 'test',
                'char_type_name': 'word',
              },
            ],
            'verse_key': '1:1',
          },
        ],
      };

      when(
        () =>
            mockDio.get(any(), queryParameters: any(named: 'queryParameters')),
      ).thenAnswer(
        (_) async => Response(
          data: tWordsData,
          statusCode: 200,
          requestOptions: RequestOptions(),
        ),
      );

      final Map<String, List<QuranWord>> result = await dataSource.getPageWords(
        1,
      );
      expect(result, isNotEmpty);
      expect(result.containsKey('1:1'), true);
    });

    test('should return empty map when API call fails', () async {
      when(
        () =>
            mockDio.get(any(), queryParameters: any(named: 'queryParameters')),
      ).thenThrow(DioException(requestOptions: RequestOptions()));

      final Map<String, List<QuranWord>> result = await dataSource.getPageWords(
        1,
      );
      expect(result, isEmpty);
    });
  });

  group('_ensureDataLoaded alternative formats', () {
    test('should load data from direct surahs format', () async {
      final Map<String, List<Map<String, Object>>> directFormat = {
        'surahs': [
          {'number': 1, 'name': 'Name', 'englishName': 'Name', 'ayahs': []},
        ],
      };
      setupMockAsset(data: directFormat);

      final SurahContentEntity result = await dataSource.getSurahContent(1);
      expect(result.number, 1);
    });

    test('should handle unexpected format', () async {
      final badFormat = {'wrong': 'key'};
      setupMockAsset(data: badFormat);

      final SurahContentEntity result = await dataSource.getSurahContent(1);
      // Fails to "else" which throws, caught and yields mock data
      expect(result.number, 1);
    });
  });
}
