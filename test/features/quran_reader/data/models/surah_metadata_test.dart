import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa/features/quran_reader/data/models/surah_metadata.dart';

void main() {
  group('SurahMetadata', () {
    test('should create SurahMetadata with all properties', () {
      const surah = SurahMetadata(
        number: 1,
        nameArabic: 'الفاتحة',
        nameEnglish: 'Al-Fatiha',
        nameTranslation: 'The Opening',
        revelationType: 'Meccan',
        ayahCount: 7,
      );

      expect(surah.number, 1);
      expect(surah.nameArabic, 'الفاتحة');
      expect(surah.nameEnglish, 'Al-Fatiha');
      expect(surah.nameTranslation, 'The Opening');
      expect(surah.revelationType, 'Meccan');
      expect(surah.ayahCount, 7);
    });

    test('should return true for isMeccan when revelationType is Meccan', () {
      const surah = SurahMetadata(
        number: 1,
        nameArabic: 'الفاتحة',
        nameEnglish: 'Al-Fatiha',
        nameTranslation: 'The Opening',
        revelationType: 'Meccan',
        ayahCount: 7,
      );

      expect(surah.isMeccan, true);
      expect(surah.isMedinan, false);
    });

    test('should return true for isMedinan when revelationType is Medinan', () {
      const surah = SurahMetadata(
        number: 2,
        nameArabic: 'البقرة',
        nameEnglish: 'Al-Baqara',
        nameTranslation: 'The Cow',
        revelationType: 'Medinan',
        ayahCount: 286,
      );

      expect(surah.isMeccan, false);
      expect(surah.isMedinan, true);
    });
  });

  group('SurahMetadataRepository', () {
    group('getSurah', () {
      test('should return correct surah for valid surah number', () {
        final SurahMetadata surah = SurahMetadataRepository.getSurah(1);

        expect(surah.number, 1);
        expect(surah.nameEnglish, 'Al-Fatiha');
        expect(surah.ayahCount, 7);
      });

      test('should return Al-Baqara for surah number 2', () {
        final SurahMetadata surah = SurahMetadataRepository.getSurah(2);

        expect(surah.number, 2);
        expect(surah.nameEnglish, 'Al-Baqara');
        expect(surah.ayahCount, 286);
      });

      test('should return last surah (An-Nas) for surah number 114', () {
        final SurahMetadata surah = SurahMetadataRepository.getSurah(114);

        expect(surah.number, 114);
        expect(surah.nameEnglish, 'An-Nas');
        expect(surah.ayahCount, 6);
      });

      test('should throw RangeError for surah number 0', () {
        expect(
          () => SurahMetadataRepository.getSurah(0),
          throwsA(isA<RangeError>()),
        );
      });

      test('should throw RangeError for surah number 115', () {
        expect(
          () => SurahMetadataRepository.getSurah(115),
          throwsA(isA<RangeError>()),
        );
      });

      test('should throw RangeError for negative surah number', () {
        expect(
          () => SurahMetadataRepository.getSurah(-1),
          throwsA(isA<RangeError>()),
        );
      });
    });

    group('allSurahs', () {
      test('should return list of exactly 114 surahs', () {
        final List<SurahMetadata> surahs = SurahMetadataRepository.allSurahs;

        expect(surahs.length, 114);
      });

      test('should have surahs in correct order', () {
        final List<SurahMetadata> surahs = SurahMetadataRepository.allSurahs;

        expect(surahs.first.number, 1);
        expect(surahs.first.nameEnglish, 'Al-Fatiha');
        expect(surahs.last.number, 114);
        expect(surahs.last.nameEnglish, 'An-Nas');
      });

      test('should have consecutive surah numbers', () {
        final List<SurahMetadata> surahs = SurahMetadataRepository.allSurahs;

        for (var i = 0; i < surahs.length; i++) {
          expect(surahs[i].number, i + 1);
        }
      });
    });

    group('search', () {
      test('should return empty list for empty query', () {
        final List<SurahMetadata> results = SurahMetadataRepository.search('');

        expect(results, isEmpty);
      });

      test('should return empty list for whitespace query', () {
        final List<SurahMetadata> results = SurahMetadataRepository.search(
          '   ',
        );

        expect(results, isEmpty);
      });

      test('should find surah by English name', () {
        final List<SurahMetadata> results = SurahMetadataRepository.search(
          'fatiha',
        );

        expect(results, isNotEmpty);
        expect(results.first.nameEnglish, 'Al-Fatiha');
      });

      test('should find surah by English name (case-insensitive)', () {
        final List<SurahMetadata> results = SurahMetadataRepository.search(
          'FATIHA',
        );

        expect(results, isNotEmpty);
        expect(results.first.nameEnglish, 'Al-Fatiha');
      });

      test('should find surah by Arabic name', () {
        final List<SurahMetadata> results = SurahMetadataRepository.search(
          'الفاتحة',
        );

        expect(results, isNotEmpty);
        expect(results.first.nameArabic, 'الفاتحة');
      });

      test('should find surah by number', () {
        final List<SurahMetadata> results = SurahMetadataRepository.search('1');

        expect(results, isNotEmpty);
        expect(results.first.number, 1);
      });

      test('should find multiple surahs with partial match', () {
        // "Al-" should match many surahs
        final List<SurahMetadata> results = SurahMetadataRepository.search(
          'al-',
        );

        expect(results.length, greaterThan(10));
      });

      test('should return empty list for non-matching query', () {
        final List<SurahMetadata> results = SurahMetadataRepository.search(
          'xyz123',
        );

        expect(results, isEmpty);
      });

      test('should find surah by partial Arabic name', () {
        final List<SurahMetadata> results = SurahMetadataRepository.search(
          'بقر',
        );

        expect(results, isNotEmpty);
        expect(results.first.nameEnglish, 'Al-Baqara');
      });

      test('should handle mixed case search', () {
        final List<SurahMetadata> results = SurahMetadataRepository.search(
          'Al-Baqara',
        );

        expect(results, isNotEmpty);
        expect(results.first.number, 2);
      });
    });
  });
}
