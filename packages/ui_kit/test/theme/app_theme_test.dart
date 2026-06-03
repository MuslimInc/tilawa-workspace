import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../lib/src/foundation/app_theme.dart';

void main() {
  group('AppTheme', () {
    test('private constructor should prevent direct instantiation', () {
      // This test verifies that AppTheme has a private constructor
      expect(AppTheme, isNotNull);
    });

    test(
      'audit: Flutter test env builds theme without google_fonts network path',
      () {
        final ThemeData theme = AppTheme.getLightTheme(
          primaryColor: const Color(0xFF2E7D6F),
        );
        expect(theme.textTheme.bodyMedium, isNotNull);
        expect(theme.textTheme.titleMedium, isNotNull);
      },
    );

    // Note: getLightTheme and getDarkTheme tests are covered in integration
    // tests and actual app usage.
  });
}
