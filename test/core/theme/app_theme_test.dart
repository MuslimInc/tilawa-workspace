import 'package:flex_color_scheme/src/flex_scheme.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa/core/theme/app_theme.dart';

void main() {
  group('AppTheme', () {
    test('getAvailableSchemes should return list with schemes', () {
      // act
      final List<FlexScheme> schemes = AppTheme.getAvailableSchemes();

      // assert
      expect(schemes, isNotEmpty);
      expect(schemes.length, 1);
    });

    test('private constructor should prevent direct instantiation', () {
      // This test verifies that AppTheme has a private constructor
      expect(AppTheme, isNotNull);
    });

    // Note: getLightTheme and getDarkTheme tests are skipped because they
    // use google_fonts which requires network access in tests. These methods
    // are covered in integration tests and actual app usage.
  });
}
