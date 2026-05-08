import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa/features/share/presentation/utils/surah_header_policy.dart';

void main() {
  group('decideSurahHeader', () {
    test('includes banner when selection touches ayah 1', () {
      final decision = decideSurahHeader(
        surahNumber: 18,
        selectionTouchesOpeningAyah: true,
        isInitialSelection: false,
      );

      expect(decision.includeBanner, isTrue);
      expect(decision.includeBismillah, isTrue);
      expect(decision.reason, SurahHeaderReason.openingAyah);
    });

    test('includes banner for the initial untouched selection', () {
      final decision = decideSurahHeader(
        surahNumber: 2,
        selectionTouchesOpeningAyah: false,
        isInitialSelection: true,
      );

      expect(decision.includeBanner, isTrue);
      expect(decision.includeBismillah, isTrue);
      expect(decision.reason, SurahHeaderReason.initialSelection);
    });

    test('omits banner for adjusted ranges that do not touch ayah 1', () {
      final decision = decideSurahHeader(
        surahNumber: 2,
        selectionTouchesOpeningAyah: false,
        isInitialSelection: false,
      );

      expect(decision.includeBanner, isFalse);
      expect(decision.includeBismillah, isFalse);
      expect(decision.reason, SurahHeaderReason.omitted);
    });

    test('omits Bismillah for Al-Fatihah and At-Tawbah', () {
      final fatihah = decideSurahHeader(
        surahNumber: kAlFatihahSurahNumber,
        selectionTouchesOpeningAyah: true,
        isInitialSelection: false,
      );
      final tawbah = decideSurahHeader(
        surahNumber: kAtTawbahSurahNumber,
        selectionTouchesOpeningAyah: true,
        isInitialSelection: false,
      );

      expect(fatihah.includeBanner, isTrue);
      expect(fatihah.includeBismillah, isFalse);
      expect(tawbah.includeBanner, isTrue);
      expect(tawbah.includeBismillah, isFalse);
    });
  });
}
