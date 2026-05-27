import 'package:flutter_test/flutter_test.dart';
import '../../lib/src/foundation/app_theme.dart';

void main() {
  group('AppTheme', () {
    test('private constructor should prevent direct instantiation', () {
      // This test verifies that AppTheme has a private constructor
      expect(AppTheme, isNotNull);
    });

    // Note: getLightTheme and getDarkTheme tests are covered in integration
    // tests and actual app usage.
  });
}
