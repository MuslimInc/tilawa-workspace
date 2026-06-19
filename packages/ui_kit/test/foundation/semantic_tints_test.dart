import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa_ui_kit/src/foundation/foundation.dart';

void main() {
  group('TilawaSemanticTintColors', () {
    late ColorScheme lightScheme;
    late ColorScheme darkScheme;

    setUp(() {
      lightScheme = ColorScheme.fromSeed(seedColor: const Color(0xFF219653));
      darkScheme = ColorScheme.fromSeed(
        seedColor: const Color(0xFF219653),
        brightness: Brightness.dark,
      );
    });

    test('ink tint maps to primary container pair', () {
      expect(
        lightScheme.semanticTintBackground(TilawaSemanticTint.ink),
        lightScheme.primaryContainer,
      );
      expect(
        lightScheme.semanticTintForeground(TilawaSemanticTint.ink),
        lightScheme.onPrimaryContainer,
      );
    });

    test('scholar tint maps to secondary container pair', () {
      expect(
        lightScheme.semanticTintBackground(TilawaSemanticTint.scholar),
        lightScheme.secondaryContainer,
      );
      expect(
        lightScheme.semanticTintForeground(TilawaSemanticTint.scholar),
        lightScheme.onSecondaryContainer,
      );
    });

    test('gilding tint maps to tertiary container pair', () {
      expect(
        lightScheme.semanticTintBackground(TilawaSemanticTint.gilding),
        lightScheme.tertiaryContainer,
      );
      expect(
        lightScheme.semanticTintForeground(TilawaSemanticTint.gilding),
        lightScheme.onTertiaryContainer,
      );
    });

    test('parchment and neutral tints map to surface container roles', () {
      expect(
        lightScheme.semanticTintBackground(TilawaSemanticTint.parchment),
        lightScheme.surfaceContainerHigh,
      );
      expect(
        lightScheme.semanticTintForeground(TilawaSemanticTint.parchment),
        lightScheme.onSurfaceVariant,
      );
      expect(
        lightScheme.semanticTintBackground(TilawaSemanticTint.neutral),
        lightScheme.surfaceContainer,
      );
      expect(
        lightScheme.semanticTintForeground(TilawaSemanticTint.neutral),
        lightScheme.onSurface,
      );
    });

    test('success and caution blend status colors onto surface', () {
      expect(
        lightScheme.semanticTintBackground(TilawaSemanticTint.success),
        Color.alphaBlend(
          lightScheme.success.withValues(alpha: 0.14),
          lightScheme.surface,
        ),
      );
      expect(
        lightScheme.semanticTintBackground(TilawaSemanticTint.caution),
        Color.alphaBlend(
          lightScheme.warning.withValues(alpha: 0.14),
          lightScheme.surface,
        ),
      );
      expect(
        lightScheme.semanticTintForeground(TilawaSemanticTint.success),
        lightScheme.success,
      );
      expect(
        darkScheme.semanticTintForeground(TilawaSemanticTint.caution),
        darkScheme.warning,
      );
    });

    test('AppTheme light scheme resolves every semantic tint', () {
      final colorScheme = AppTheme.getLightTheme(
        primaryColor: AppColors.defaultPrimary,
      ).colorScheme;

      for (final tint in TilawaSemanticTint.values) {
        expect(
          colorScheme.semanticTintBackground(tint),
          isA<Color>(),
          reason: '$tint background',
        );
        expect(
          colorScheme.semanticTintForeground(tint),
          isA<Color>(),
          reason: '$tint foreground',
        );
      }
    });
  });
}
