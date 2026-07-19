import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:tilawa/features/home/domain/home_hijri_date_formatter.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('en');
    await initializeDateFormatting('ar');
  });

  group('formatHomeHijriDate', () {
    test('formats English month names for non-Arabic locales', () {
      final String result = formatHomeHijriDate(
        date: DateTime(2026, 6, 18),
        languageCode: 'en',
      );

      expect(result, isNotEmpty);
      expect(result, contains('1448'));
      expect(result, contains('Muharram'));
    });

    test('formats Arabic month names for ar locale', () {
      final String result = formatHomeHijriDate(
        date: DateTime(2026, 6, 18),
        languageCode: 'ar',
      );

      expect(result, isNotEmpty);
      expect(result, contains('١٤٤٨'));
      expect(result, contains('محرم'));
    });
  });

  group('formatHomeHeaderDateLine', () {
    test('prefixes weekday for English', () {
      final DateTime date = DateTime(2026, 6, 18);
      final String result = formatHomeHeaderDateLine(
        date: date,
        languageCode: 'en',
      );

      expect(result, startsWith('Thursday,'));
      expect(result, contains('Muharram'));
    });
  });
}
