import 'package:flutter_test/flutter_test.dart';
import 'package:quran_qcf/src/data/sources/quarters.dart';

void main() {
  group('Quarters data', () {
    test('has exactly 240 entries', () {
      expect(quartersData.length, 240);
    });

    test('first quarter starts at Al-Fatiha 1:1', () {
      expect(quartersData[0]['surah'], 1);
      expect(quartersData[0]['ayah'], 1);
    });

    test('last quarter starts at surah 100 ayah 9', () {
      final Map<String, int> last = quartersData.last;
      expect(last['surah'], 100);
      expect(last['ayah'], 9);
    });

    test('all entries have surah and ayah keys', () {
      for (var i = 0; i < quartersData.length; i++) {
        expect(
          quartersData[i].containsKey('surah'),
          isTrue,
          reason: 'Quarter $i missing surah key',
        );
        expect(
          quartersData[i].containsKey('ayah'),
          isTrue,
          reason: 'Quarter $i missing ayah key',
        );
      }
    });

    test('surah values are in range 1-114', () {
      for (final Map<String, int> q in quartersData) {
        expect(q['surah'], greaterThanOrEqualTo(1));
        expect(q['surah'], lessThanOrEqualTo(114));
      }
    });

    test('ayah values are positive', () {
      for (final Map<String, int> q in quartersData) {
        expect(q['ayah'], greaterThan(0));
      }
    });
  });

  group('Quarter class', () {
    test('creates from map correctly', () {
      final quarter = Quarter.fromMap({'surah': 2, 'ayah': 26});
      expect(quarter.surah, 2);
      expect(quarter.ayah, 26);
    });

    test('toMap returns correct format', () {
      const quarter = Quarter(surah: 5, ayah: 12);
      final Map<String, int> map = quarter.toMap();
      expect(map['surah'], 5);
      expect(map['ayah'], 12);
    });
  });

  group('getAllQuarters', () {
    test('returns 240 Quarter objects', () {
      final List<Quarter> allQuarters = getAllQuarters();
      expect(allQuarters.length, 240);
    });

    test('first quarter is Al-Fatiha 1:1', () {
      final List<Quarter> allQuarters = getAllQuarters();
      expect(allQuarters[0].surah, 1);
      expect(allQuarters[0].ayah, 1);
    });
  });

  group('getQuarter', () {
    test('returns correct quarter for valid index', () {
      final Quarter? q0 = getQuarter(0);
      expect(q0, isNotNull);
      expect(q0!.surah, 1);
      expect(q0.ayah, 1);

      final Quarter? q1 = getQuarter(1);
      expect(q1, isNotNull);
      expect(q1!.surah, 2);
      expect(q1.ayah, 26);
    });

    test('returns null for invalid index', () {
      expect(getQuarter(-1), isNull);
      expect(getQuarter(240), isNull);
      expect(getQuarter(1000), isNull);
    });
  });

  group('getQuarterForVerse', () {
    test('Al-Fatiha 1:1 is in quarter 1', () {
      expect(getQuarterForVerse(1, 1), 1);
    });

    test('Al-Baqarah 2:1-25 is in quarter 1', () {
      expect(getQuarterForVerse(2, 1), 1);
      expect(getQuarterForVerse(2, 25), 1);
    });

    test('Al-Baqarah 2:26 starts quarter 2', () {
      expect(getQuarterForVerse(2, 26), 2);
    });

    test('Al-Baqarah 2:44 starts quarter 3', () {
      expect(getQuarterForVerse(2, 44), 3);
    });

    test('verses within a quarter return correct quarter', () {
      // Quarter 2 is 2:26-43
      expect(getQuarterForVerse(2, 30), 2);
      expect(getQuarterForVerse(2, 43), 2);
    });
  });

  group('getHizbForVerse', () {
    test('quarters 1-4 are in Hizb 1', () {
      expect(getHizbForVerse(1, 1), 1); // Quarter 1
      expect(getHizbForVerse(2, 26), 1); // Quarter 2
      expect(getHizbForVerse(2, 44), 1); // Quarter 3
      expect(getHizbForVerse(2, 60), 1); // Quarter 4
    });

    test('quarter 5 starts Hizb 2', () {
      expect(getHizbForVerse(2, 75), 2); // Quarter 5
    });

    test('Hizb calculation is correct', () {
      // Each Hizb contains 4 quarters
      // Hizb 1: Quarters 1-4
      // Hizb 2: Quarters 5-8
      // etc.

      // Quarter 8 (last of Hizb 2): 2:124
      expect(getHizbForVerse(2, 124), 2);

      // Quarter 9 (first of Hizb 3): 2:142
      expect(getHizbForVerse(2, 142), 3);
    });

    test('returns null for verse before first quarter', () {
      // The first quarter is at 1:1, so there's no valid verse before it.
      // However, if we pass surah 0 (invalid), it should return null.
      expect(getHizbForVerse(0, 1), isNull);
    });
  });

  group('totalQuarters constant', () {
    test('equals 240', () {
      expect(totalQuarters, 240);
    });

    test('matches data length', () {
      expect(totalQuarters, quartersData.length);
    });
  });
}
