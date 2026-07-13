import 'package:flutter_test/flutter_test.dart';
import 'package:quran_qcf/quran_qcf.dart';
import 'package:tilawa/features/smart_khatma/domain/khatma_plan_boundaries.dart';

void main() {
  group('KhatmaPlanBoundaries', () {
    test('resolves surah ayah to mushaf pages', () {
      expect(
        KhatmaPlanBoundaries.pageForSurahAyah(2, 142),
        getPageNumber(2, 142),
      );
      expect(
        KhatmaPlanBoundaries.pageForSurahAyah(6, 94),
        getPageNumber(6, 94),
      );
    });

    test('accepts ordered surah ayah ranges', () {
      expect(
        KhatmaPlanBoundaries.isOrderedSurahRange(
          startSurah: 2,
          startAyah: 142,
          endSurah: 6,
          endAyah: 94,
        ),
        isTrue,
      );
      expect(
        KhatmaPlanBoundaries.isOrderedSurahRange(
          startSurah: 6,
          startAyah: 10,
          endSurah: 2,
          endAyah: 1,
        ),
        isFalse,
      );
      expect(
        KhatmaPlanBoundaries.isOrderedSurahRange(
          startSurah: 2,
          startAyah: 300,
          endSurah: 3,
          endAyah: 1,
        ),
        isFalse,
      );
    });

    test('validates page ranges', () {
      expect(KhatmaPlanBoundaries.isValidPageRange(1, 604), isTrue);
      expect(KhatmaPlanBoundaries.isValidPageRange(80, 200), isTrue);
      expect(KhatmaPlanBoundaries.isValidPageRange(200, 80), isFalse);
      expect(KhatmaPlanBoundaries.isValidPageRange(0, 604), isFalse);
      expect(KhatmaPlanBoundaries.isValidPageRange(1, 605), isFalse);
    });

    test('derives duration from target date', () {
      final int days = KhatmaPlanBoundaries.durationDaysFromTargetDate(
        startDate: DateTime(2026, 7, 12),
        targetDate: DateTime(2026, 8, 10),
      );

      expect(days, 30);
    });
  });
}
