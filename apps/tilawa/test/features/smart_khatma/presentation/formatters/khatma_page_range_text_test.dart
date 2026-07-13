import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa/features/smart_khatma/presentation/formatters/khatma_page_range_text.dart';
import 'package:tilawa/l10n/generated/app_localizations_ar.dart';
import 'package:tilawa/l10n/generated/app_localizations_en.dart';

void main() {
  group('formatKhatmaPageRange', () {
    test('orders pages low-to-high before isolating numerals', () {
      final l10n = AppLocalizationsEn();

      final formatted = formatKhatmaPageRange(l10n, 41, 1);

      expect(formatted, 'Pages \u20661–41\u2069');
      expect(formatted.indexOf('1'), lessThan(formatted.indexOf('41')));
    });

    test('wraps Arabic page ranges in LTR isolates', () {
      final l10n = AppLocalizationsAr();

      final formatted = formatKhatmaPageRange(l10n, 1, 41);

      expect(formatted, contains('الصفحات'));
      expect(formatted, contains('\u20661–41\u2069'));
      expect(formatted.indexOf('1'), lessThan(formatted.indexOf('41')));
    });
  });
}
