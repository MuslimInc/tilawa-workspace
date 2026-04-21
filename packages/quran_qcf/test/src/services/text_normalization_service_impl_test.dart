import 'package:flutter_test/flutter_test.dart';
import 'package:quran_qcf/src/services/text_normalization_service_impl.dart';

void main() {
  late TextNormalizationServiceImpl service;

  setUp(() {
    service = const TextNormalizationServiceImpl();
  });

  group('TextNormalizationServiceImpl', () {
    group('normalise', () {
      test('removes tashkeel (diacritics)', () {
        const input = 'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ';
        final String result = service.normalise(input);
        // Should not contain common tashkeel marks
        expect(result.contains('\u064E'), isFalse); // Fatha
        expect(result.contains('\u0650'), isFalse); // Kasra
        expect(result.contains('\u064F'), isFalse); // Damma
        expect(result.contains('\u0651'), isFalse); // Shadda
      });

      test('removes tatweel', () {
        const input = 'الرحمـــــن';
        final String result = service.normalise(input);
        expect(result.contains('\u0640'), isFalse);
      });

      test('normalizes Alif variants', () {
        const alifWithHamzaAbove = 'أ';
        const alifWithHamzaBelow = 'إ';
        const alifWithMadda = 'آ';

        final String result1 = service.normalise(alifWithHamzaAbove);
        final String result2 = service.normalise(alifWithHamzaBelow);
        final String result3 = service.normalise(alifWithMadda);

        // All should be normalized to plain Alif
        expect(result1, 'ا');
        expect(result2, 'ا');
        expect(result3, 'ا');
      });

      test('normalizes Ya to Alif Maksura', () {
        final String result = service.normalise('ي');
        expect(result, 'ى');
      });

      test('normalizes Ta Marbuta to Ha', () {
        final String result = service.normalise('ة');
        expect(result, 'ه');
      });

      test('removes end of ayah symbol', () {
        const input = 'آية۝';
        final String result = service.normalise(input);
        expect(result.contains('\u06DD'), isFalse);
      });

      test('preserves base Arabic letters', () {
        const input = 'محمد';
        final String result = service.normalise(input);
        expect(result, 'محمد');
      });
    });

    group('removeDiacritics', () {
      test('removes Fatha', () {
        const input = 'بَ';
        final String result = service.removeDiacritics(input);
        expect(result, 'ب');
      });

      test('removes Damma', () {
        const input = 'بُ';
        final String result = service.removeDiacritics(input);
        expect(result, 'ب');
      });

      test('removes Kasra', () {
        const input = 'بِ';
        final String result = service.removeDiacritics(input);
        expect(result, 'ب');
      });

      test('removes Shadda', () {
        const input = 'بّ';
        final String result = service.removeDiacritics(input);
        expect(result, 'ب');
      });

      test('removes Tanwin Fatha', () {
        const input = 'بً';
        final String result = service.removeDiacritics(input);
        expect(result, 'ب');
      });

      test('removes Tanwin Damma', () {
        const input = 'بٌ';
        final String result = service.removeDiacritics(input);
        expect(result, 'ب');
      });

      test('removes Tanwin Kasra', () {
        const input = 'بٍ';
        final String result = service.removeDiacritics(input);
        expect(result, 'ب');
      });

      test('removes multiple diacritics', () {
        const input = 'بِسْمِ اللَّهِ';
        final String result = service.removeDiacritics(input);
        expect(result.contains('َ'), isFalse);
        expect(result.contains('ِ'), isFalse);
        expect(result.contains('ّ'), isFalse);
      });

      test('preserves base letters', () {
        const input = 'الله';
        final String result = service.removeDiacritics(input);
        expect(result, 'الله');
      });
    });
  });
}
