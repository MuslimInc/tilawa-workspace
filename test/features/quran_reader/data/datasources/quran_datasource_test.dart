import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tilawa/features/quran_reader/data/datasources/quran_datasource.dart';
import 'package:tilawa/features/quran_reader/data/datasources/quran_local_datasource.dart';
import 'package:tilawa/features/quran_reader/data/datasources/quran_remote_datasource.dart';
import 'package:tilawa/features/quran_reader/domain/entities/entities.dart';

class MockQuranLocalDataSource extends Mock implements QuranLocalDataSource {}

class MockQuranRemoteDataSource extends Mock implements QuranRemoteDataSource {}

class MockDio extends Mock implements Dio {}

class MockAssetBundle extends Mock implements AssetBundle {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('QuranDataSourceImpl (Facade)', () {
    late QuranDataSourceImpl dataSource;
    late MockQuranLocalDataSource mockLocalDataSource;
    late MockQuranRemoteDataSource mockRemoteDataSource;

    setUp(() {
      mockLocalDataSource = MockQuranLocalDataSource();
      mockRemoteDataSource = MockQuranRemoteDataSource();
      dataSource = QuranDataSourceImpl(
        mockLocalDataSource,
        mockRemoteDataSource,
      );
    });

    group('getSurahContent', () {
      test('should delegate to local data source', () async {
        const tSurah = SurahContentEntity(
          number: 1,
          name: 'الفاتحة',
          nameEnglish: 'Al-Fatiha',
          nameTranslation: 'The Opening',
          revelationType: 'Meccan',
          numberOfAyahs: 7,
          ayahs: [],
        );

        when(
          () => mockLocalDataSource.getSurahContent(1),
        ).thenAnswer((_) async => tSurah);

        final SurahContentEntity result = await dataSource.getSurahContent(1);

        expect(result, equals(tSurah));
        verify(() => mockLocalDataSource.getSurahContent(1)).called(1);
      });
    });

    group('getAyah', () {
      test('should delegate to local data source', () async {
        const tAyah = AyahEntity(
          number: 1,
          numberInSurah: 1,
          surahNumber: 1,
          text: 'بِسْمِ ٱللَّهِ',
        );

        when(
          () => mockLocalDataSource.getAyah(surahNumber: 1, ayahNumber: 1),
        ).thenAnswer((_) async => tAyah);

        final AyahEntity? result = await dataSource.getAyah(
          surahNumber: 1,
          ayahNumber: 1,
        );

        expect(result, equals(tAyah));
        verify(
          () => mockLocalDataSource.getAyah(surahNumber: 1, ayahNumber: 1),
        ).called(1);
      });
    });

    group('getPage', () {
      test(
        'should get page from local source and fetch words from remote',
        () async {
          const tPageWithoutWords = QuranPageEntity(
            pageNumber: 1,
            ayahs: [
              PageAyahInfo(
                surahNumber: 1,
                surahName: 'الفاتحة',
                surahNameEnglish: 'Al-Fatiha',
                ayahNumber: 1,
                text: 'بِسْمِ ٱللَّهِ',
              ),
            ],
            juz: 1,
            hizb: 1,
          );

          final tWords = {
            '1:1': [
              const QuranWord(
                id: 1,
                position: 1,
                text: 'بِسْمِ',
                textUthmani: 'بِسْمِ',
                charTypeName: 'word',
              ),
            ],
          };

          final tPageWithWords = QuranPageEntity(
            pageNumber: 1,
            ayahs: [
              PageAyahInfo(
                surahNumber: 1,
                surahName: 'الفاتحة',
                surahNameEnglish: 'Al-Fatiha',
                ayahNumber: 1,
                text: 'بِسْمِ ٱللَّهِ',
                words: tWords['1:1'],
              ),
            ],
            juz: 1,
            hizb: 1,
          );

          var callCount = 0;
          when(() => mockLocalDataSource.getPage(1)).thenAnswer((_) async {
            callCount++;
            // First call returns page without words, second call returns page with words
            return callCount == 1 ? tPageWithoutWords : tPageWithWords;
          });
          when(
            () => mockRemoteDataSource.getPageWords(1),
          ).thenAnswer((_) async => tWords);
          when(
            () => mockLocalDataSource.updatePageWithWords(1, tWords),
          ).thenReturn(null);

          final QuranPageEntity result = await dataSource.getPage(1);

          expect(result.pageNumber, 1);
          verify(() => mockRemoteDataSource.getPageWords(1)).called(1);
        },
      );

      test('should return page from local when words already loaded', () async {
        const tPageWithWords = QuranPageEntity(
          pageNumber: 1,
          ayahs: [
            PageAyahInfo(
              surahNumber: 1,
              surahName: 'الفاتحة',
              surahNameEnglish: 'Al-Fatiha',
              ayahNumber: 1,
              text: 'بِسْمِ ٱللَّهِ',
              words: [
                QuranWord(
                  id: 1,
                  position: 1,
                  text: 'بِسْمِ',
                  textUthmani: 'بِسْمِ',
                  charTypeName: 'word',
                ),
              ],
            ),
          ],
          juz: 1,
          hizb: 1,
        );

        when(
          () => mockLocalDataSource.getPage(1),
        ).thenAnswer((_) async => tPageWithWords);

        final QuranPageEntity result = await dataSource.getPage(1);

        expect(result, equals(tPageWithWords));
        verifyNever(() => mockRemoteDataSource.getPageWords(any()));
      });
    });

    group('getJuz', () {
      test('should delegate to local data source', () async {
        final tAyahs = [
          const AyahEntity(
            number: 1,
            numberInSurah: 1,
            surahNumber: 1,
            text: 'test',
            juz: 1,
          ),
        ];

        when(
          () => mockLocalDataSource.getJuz(1),
        ).thenAnswer((_) async => tAyahs);

        final List<AyahEntity> result = await dataSource.getJuz(1);

        expect(result, equals(tAyahs));
        verify(() => mockLocalDataSource.getJuz(1)).called(1);
      });
    });

    group('searchAyahs', () {
      test('should delegate to local data source', () async {
        final tAyahs = [
          const AyahEntity(
            number: 1,
            numberInSurah: 1,
            surahNumber: 1,
            text: 'الحمد لله',
          ),
        ];

        when(
          () => mockLocalDataSource.searchAyahs('الحمد'),
        ).thenAnswer((_) async => tAyahs);

        final List<AyahEntity> result = await dataSource.searchAyahs('الحمد');

        expect(result, equals(tAyahs));
        verify(() => mockLocalDataSource.searchAyahs('الحمد')).called(1);
      });
    });

    group('searchSurahs', () {
      test('should delegate to local data source', () async {
        final tSurahs = [
          const SurahContentEntity(
            number: 1,
            name: 'الفاتحة',
            nameEnglish: 'Al-Fatiha',
            nameTranslation: 'The Opening',
            revelationType: 'Meccan',
            numberOfAyahs: 7,
            ayahs: [],
          ),
        ];

        when(
          () => mockLocalDataSource.searchSurahs('Fatiha'),
        ).thenAnswer((_) async => tSurahs);

        final List<SurahContentEntity> result = await dataSource.searchSurahs(
          'Fatiha',
        );

        expect(result, equals(tSurahs));
        verify(() => mockLocalDataSource.searchSurahs('Fatiha')).called(1);
      });
    });

    group('getPageWords', () {
      test('should delegate to remote data source', () async {
        final tWords = {
          '1:1': [
            const QuranWord(
              id: 1,
              position: 1,
              text: 'بِسْمِ',
              textUthmani: 'بِسْمِ',
              charTypeName: 'word',
            ),
          ],
        };

        when(
          () => mockRemoteDataSource.getPageWords(1),
        ).thenAnswer((_) async => tWords);

        final Map<String, List<QuranWord>> result = await dataSource
            .getPageWords(1);

        expect(result, equals(tWords));
        verify(() => mockRemoteDataSource.getPageWords(1)).called(1);
      });
    });
  });

  group('QuranLocalDataSourceImpl', () {
    late QuranLocalDataSourceImpl localDataSource;
    late MockAssetBundle mockAssetBundle;

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
                'text': 'بِسْمِ ٱللَّهِ ٱلرَّحْمَٰنِ ٱلرَّحِيمِ',
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
                'text': 'ٱلْحَمْدُ لِلَّهِ رَبِّ ٱلْعَٰلَمِينَ',
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
      mockAssetBundle = MockAssetBundle();
      localDataSource = QuranLocalDataSourceImpl(assetBundle: mockAssetBundle);
    });

    void setupMockAsset({Map<String, dynamic>? data, bool fail = false}) {
      if (fail) {
        when(
          () => mockAssetBundle.loadString(any()),
        ).thenThrow(Exception('Asset not found'));
      } else {
        when(
          () => mockAssetBundle.loadString(any()),
        ).thenAnswer((_) async => jsonEncode(data ?? tQuranData));
      }
    }

    group('getSurahContent', () {
      test(
        'should return SurahContentEntity when data is loaded successfully',
        () async {
          setupMockAsset();

          final SurahContentEntity result = await localDataSource
              .getSurahContent(1);

          expect(result.number, 1);
          expect(result.nameEnglish, 'Al-Fatiha');
          expect(result.ayahs.length, 2);
        },
      );

      test('should return mock data when asset fails to load', () async {
        setupMockAsset(fail: true);

        final SurahContentEntity result = await localDataSource.getSurahContent(
          1,
        );

        expect(result.number, 1);
        expect(result.ayahs.isNotEmpty, true);
      });

      test('should return mock data for non-existent surah number', () async {
        setupMockAsset();

        final SurahContentEntity result = await localDataSource.getSurahContent(
          114,
        );

        expect(result.number, 114);
        expect(result.ayahs.isNotEmpty, true);
      });

      test('should load data with direct surahs format', () async {
        final Map<String, List<Map<String, Object>>> directFormat = {
          'surahs': [
            {
              'number': 1,
              'name': 'Test',
              'englishName': 'Test',
              'ayahs': [
                {
                  'number': 1,
                  'text': 'Test',
                  'numberInSurah': 1,
                  'juz': 1,
                  'page': 1,
                },
              ],
            },
          ],
        };
        setupMockAsset(data: directFormat);

        final SurahContentEntity result = await localDataSource.getSurahContent(
          1,
        );
        expect(result.number, 1);
      });

      test('should handle unexpected format by returning mock data', () async {
        final badFormat = <String, String>{'wrong': 'key'};
        setupMockAsset(data: badFormat);

        final SurahContentEntity result = await localDataSource.getSurahContent(
          1,
        );
        expect(result.number, 1);
        expect(result.ayahs.isNotEmpty, true);
      });
    });

    group('getAyah', () {
      test(
        'should return AyahEntity for valid surah and ayah number',
        () async {
          setupMockAsset();

          final AyahEntity? result = await localDataSource.getAyah(
            surahNumber: 1,
            ayahNumber: 1,
          );

          expect(result, isNotNull);
          expect(result!.surahNumber, 1);
          expect(result.numberInSurah, 1);
        },
      );

      test('should return null for non-existent ayah', () async {
        setupMockAsset();

        final AyahEntity? result = await localDataSource.getAyah(
          surahNumber: 1,
          ayahNumber: 999,
        );

        expect(result, isNull);
      });
    });

    group('getPage', () {
      test(
        'should return QuranPageEntity with ayahs for the given page',
        () async {
          setupMockAsset();

          final QuranPageEntity result = await localDataSource.getPage(1);

          expect(result.pageNumber, 1);
          expect(result.ayahs.length, 2);
        },
      );

      test('should return empty page for non-cached page number', () async {
        setupMockAsset(fail: true);

        final QuranPageEntity result = await localDataSource.getPage(999);

        expect(result.pageNumber, 999);
        expect(result.ayahs, isEmpty);
      });

      test('should cache all 604 pages after data loads', () async {
        setupMockAsset();

        // Access any page to trigger data loading and caching
        await localDataSource.getPage(1);

        // Verify pages 1-604 are all accessible
        for (var i = 1; i <= 604; i++) {
          final QuranPageEntity page = await localDataSource.getPage(i);
          expect(page.pageNumber, i);
        }
      });
    });

    group('getJuz', () {
      test('should return ayahs for the given juz', () async {
        setupMockAsset();

        final List<AyahEntity> result = await localDataSource.getJuz(1);

        expect(result, isNotEmpty);
        expect(result.every((a) => a.juz == 1), true);
      });

      test('should return empty list when no data loaded', () async {
        setupMockAsset(fail: true);

        final List<AyahEntity> result = await localDataSource.getJuz(1);

        expect(result, isEmpty);
      });
    });

    group('searchAyahs', () {
      test('should return ayahs matching the query', () async {
        setupMockAsset();

        final List<AyahEntity> result = await localDataSource.searchAyahs(
          'الحمد',
        );

        expect(result, isNotEmpty);
        expect(result.first.text, contains('ٱلْحَمْدُ'));
      });

      test('should return empty list when no data loaded', () async {
        setupMockAsset(fail: true);

        final List<AyahEntity> result = await localDataSource.searchAyahs(
          'test',
        );

        expect(result, isEmpty);
      });
    });

    group('searchSurahs', () {
      test('should return surahs matching English name', () async {
        setupMockAsset();

        final List<SurahContentEntity> result = await localDataSource
            .searchSurahs('Fatiha');

        expect(result, isNotEmpty);
        expect(result.first.nameEnglish, 'Al-Fatiha');
      });

      test('should return surah by number', () async {
        setupMockAsset();

        final List<SurahContentEntity> result = await localDataSource
            .searchSurahs('1');

        expect(result, isNotEmpty);
        expect(result.first.number, 1);
      });
    });

    group('updatePageWithWords', () {
      test('should update page cache with words', () async {
        setupMockAsset();

        // First load the page to populate cache
        await localDataSource.getPage(1);

        final tWords = {
          '1:1': [
            const QuranWord(
              id: 1,
              position: 1,
              text: 'بِسْمِ',
              textUthmani: 'بِسْمِ',
              charTypeName: 'word',
            ),
          ],
        };

        localDataSource.updatePageWithWords(1, tWords);

        final QuranPageEntity updatedPage = await localDataSource.getPage(1);
        // Words should be updated
        expect(updatedPage.ayahs.first.words, isNotNull);
      });

      test('should do nothing for non-cached page', () async {
        setupMockAsset(fail: true);

        final tWords = {
          '1:1': [
            const QuranWord(
              id: 1,
              position: 1,
              text: 'بِسْمِ',
              textUthmani: 'بِسْمِ',
              charTypeName: 'word',
            ),
          ],
        };

        // Should not throw
        localDataSource.updatePageWithWords(999, tWords);
      });
    });
  });

  group('QuranRemoteDataSourceImpl', () {
    late QuranRemoteDataSourceImpl remoteDataSource;
    late MockDio mockDio;

    setUp(() {
      mockDio = MockDio();
      remoteDataSource = QuranRemoteDataSourceImpl(dio: mockDio);
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
          () => mockDio.get(
            any(),
            queryParameters: any(named: 'queryParameters'),
          ),
        ).thenAnswer(
          (_) async => Response(
            data: tWordsData,
            statusCode: 200,
            requestOptions: RequestOptions(),
          ),
        );

        final Map<String, List<QuranWord>> result = await remoteDataSource
            .getPageWords(1);
        expect(result, isNotEmpty);
        expect(result.containsKey('1:1'), true);
      });

      test('should return empty map when API call fails', () async {
        when(
          () => mockDio.get(
            any(),
            queryParameters: any(named: 'queryParameters'),
          ),
        ).thenThrow(DioException(requestOptions: RequestOptions()));

        final Map<String, List<QuranWord>> result = await remoteDataSource
            .getPageWords(1);
        expect(result, isEmpty);
      });
    });
  });
}
