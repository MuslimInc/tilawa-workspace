import 'package:flutter_test/flutter_test.dart';
import 'package:quran_qcf/src/data/sources/juzs.dart';

void main() {
  group('Juz data', () {
    test('has exactly 30 entries', () {
      expect(juzData.length, 30);
    });

    test('juz IDs are sequential from 1 to 30', () {
      for (var i = 0; i < 30; i++) {
        expect(juzData[i]['id'], i + 1);
      }
    });

    test('first juz contains Al-Fatiha and part of Al-Baqarah', () {
      final Map<String, dynamic> firstJuz = juzData[0];
      expect(firstJuz['surahs'], [1, 2]);
      expect((firstJuz['verses'] as Map)[1], [1, 7]);
      expect((firstJuz['verses'] as Map)[2], [1, 141]);
    });

    test('last juz (Juz Amma) contains surahs 78-114', () {
      final Map<String, dynamic> lastJuz = juzData[29];
      expect(lastJuz['id'], 30);
      final surahs = lastJuz['surahs'] as List;
      expect(surahs.first, 78);
      expect(surahs.last, 114);
      expect(surahs.length, 37);
    });

    test('each juz has valid verse ranges', () {
      for (final Map<String, dynamic> juzMap in juzData) {
        final verses = juzMap['verses'] as Map;
        for (final MapEntry<dynamic, dynamic> entry in verses.entries) {
          final range = entry.value as List;
          expect(
            range.length,
            2,
            reason: 'Each verse range should have [start, end]',
          );
          expect(
            range[0],
            lessThanOrEqualTo(range[1]),
            reason: 'Start verse should be <= end verse',
          );
          expect(
            range[0],
            greaterThan(0),
            reason: 'Start verse should be positive',
          );
        }
      }
    });
  });

  group('Juz class', () {
    test('creates from map correctly', () {
      final juz = Juz.fromMap(juzData[0]);
      expect(juz.id, 1);
      expect(juz.surahs, [1, 2]);
      expect(juz.verses[1], [1, 7]);
    });

    test('start getter returns first surah and verse', () {
      final juz = Juz.fromMap(juzData[0]);
      expect(juz.start.surah, 1);
      expect(juz.start.verse, 1);
    });

    test('end getter returns last surah and verse', () {
      final juz = Juz.fromMap(juzData[0]);
      expect(juz.end.surah, 2);
      expect(juz.end.verse, 141);
    });
  });

  group('getAllJuz', () {
    test('returns 30 Juz objects', () {
      final List<Juz> allJuz = getAllJuz();
      expect(allJuz.length, 30);
    });

    test('returns Juz objects in order', () {
      final List<Juz> allJuz = getAllJuz();
      for (var i = 0; i < 30; i++) {
        expect(allJuz[i].id, i + 1);
      }
    });
  });

  group('getJuz', () {
    test('returns correct Juz for valid number', () {
      final Juz? juz1 = getJuz(1);
      expect(juz1, isNotNull);
      expect(juz1!.id, 1);

      final Juz? juz15 = getJuz(15);
      expect(juz15, isNotNull);
      expect(juz15!.id, 15);

      final Juz? juz30 = getJuz(30);
      expect(juz30, isNotNull);
      expect(juz30!.id, 30);
    });

    test('returns null for invalid number', () {
      expect(getJuz(0), isNull);
      expect(getJuz(-1), isNull);
      expect(getJuz(31), isNull);
    });
  });

  group('getJuzForVerse', () {
    test('Al-Fatiha (1:1-7) is in Juz 1', () {
      expect(getJuzForVerse(1, 1), 1);
      expect(getJuzForVerse(1, 7), 1);
    });

    test('Al-Baqarah 2:141 is in Juz 1', () {
      expect(getJuzForVerse(2, 141), 1);
    });

    test('Al-Baqarah 2:142 is in Juz 2', () {
      expect(getJuzForVerse(2, 142), 2);
    });

    test('Surah An-Nas (114:1-6) is in Juz 30', () {
      expect(getJuzForVerse(114, 1), 30);
      expect(getJuzForVerse(114, 6), 30);
    });

    test('returns null for invalid verse', () {
      // Verse 300 doesn't exist in any surah
      expect(getJuzForVerse(2, 300), isNull);
    });
  });
}
