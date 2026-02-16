import 'package:flutter_test/flutter_test.dart';
import 'package:quran/src/helpers/convert_to_arabic_number.dart';

void main() {
  group('convertToArabicNumber', () {
    test('converts single digit integer', () {
      expect(convertToArabicNumber('0'), '٠');
      expect(convertToArabicNumber('1'), '١');
      expect(convertToArabicNumber('5'), '٥');
      expect(convertToArabicNumber('9'), '٩');
    });

    test('converts multi-digit integer', () {
      expect(convertToArabicNumber('10'), '١٠');
      expect(convertToArabicNumber('123'), '١٢٣');
      expect(convertToArabicNumber('999'), '٩٩٩');
      expect(convertToArabicNumber('2024'), '٢٠٢٤');
    });

    test('converts single digit string', () {
      expect(convertToArabicNumber('0'), '٠');
      expect(convertToArabicNumber('7'), '٧');
    });

    test('converts multi-digit string', () {
      expect(convertToArabicNumber('42'), '٤٢');
      expect(convertToArabicNumber('100'), '١٠٠');
      expect(convertToArabicNumber('6236'), '٦٢٣٦'); // Total Quran verses
    });

    test('handles negative numbers', () {
      // Negative sign should be preserved
      expect(convertToArabicNumber('-5'), '-٥');
      expect(convertToArabicNumber('-123'), '-١٢٣');
    });

    test('handles large numbers', () {
      expect(convertToArabicNumber('1000000'), '١٠٠٠٠٠٠');
      expect(convertToArabicNumber('9999999'), '٩٩٩٩٩٩٩');
    });

    test('handles verse numbers commonly used in Quran', () {
      // Al-Fatiha verses (1-7)
      expect(convertToArabicNumber('1'), '١');
      expect(convertToArabicNumber('7'), '٧');

      // Al-Baqarah longest verse marker
      expect(convertToArabicNumber('286'), '٢٨٦');

      // Surah count
      expect(convertToArabicNumber('114'), '١١٤');
    });

    test('preserves non-digit characters', () {
      expect(convertToArabicNumber('1.5'), '١.٥');
      expect(convertToArabicNumber('a1b2c3'), 'a١b٢c٣');
    });
  });
}
