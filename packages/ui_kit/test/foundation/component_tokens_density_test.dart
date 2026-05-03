import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

void main() {
  group('TilawaComponentTokens Density', () {
    test('default constructor uses comfortable density', () {
      final tokens = TilawaComponentTokens.light();
      expect(tokens.density, TilawaDensity.comfortable);
    });

    test('explicit comfortable equals default', () {
      final defaultTokens = TilawaComponentTokens.light();
      final comfortableTokens = TilawaComponentTokens.light(
        density: TilawaDensity.comfortable,
      );

      // All component tokens should be identical
      expect(
        comfortableTokens.settingsGroup.tileContentPadding,
        equals(defaultTokens.settingsGroup.tileContentPadding),
      );
      expect(
        comfortableTokens.card.padding,
        equals(defaultTokens.card.padding),
      );
      expect(
        comfortableTokens.emptyState.iconSize,
        equals(defaultTokens.emptyState.iconSize),
      );
    });

    test('Phase 0: compact stores density but equals comfortable values', () {
      final comfortableTokens = TilawaComponentTokens.light(
        density: TilawaDensity.comfortable,
      );
      final compactTokens = TilawaComponentTokens.light(
        density: TilawaDensity.compact,
      );

      // Density field differs
      expect(compactTokens.density, TilawaDensity.compact);
      expect(comfortableTokens.density, TilawaDensity.comfortable);

      // Phase 0: All component token values are identical
      expect(
        compactTokens.settingsGroup.tileContentPadding,
        equals(comfortableTokens.settingsGroup.tileContentPadding),
      );
      expect(
        compactTokens.card.padding,
        equals(comfortableTokens.card.padding),
      );
      expect(
        compactTokens.emptyState.iconSize,
        equals(comfortableTokens.emptyState.iconSize),
      );
    });

    test('dark theme supports density parameter', () {
      final darkComfortable = TilawaComponentTokens.dark(
        density: TilawaDensity.comfortable,
      );
      final darkCompact = TilawaComponentTokens.dark(
        density: TilawaDensity.compact,
      );

      expect(darkComfortable.density, TilawaDensity.comfortable);
      expect(darkCompact.density, TilawaDensity.compact);

      // Phase 0: Same component token values
      expect(
        darkCompact.settingsGroup.tileContentPadding,
        equals(darkComfortable.settingsGroup.tileContentPadding),
      );
    });

    test('copyWith preserves density by default', () {
      final compactTokens = TilawaComponentTokens.light(
        density: TilawaDensity.compact,
      );
      final copied = compactTokens.copyWith(
        card: TilawaCardTokens.defaults().copyWith(
          padding: const EdgeInsets.all(20),
        ),
      );

      expect(copied.density, TilawaDensity.compact);
    });

    test('copyWith can change density', () {
      final comfortableTokens = TilawaComponentTokens.light(
        density: TilawaDensity.comfortable,
      );
      final compactTokens = comfortableTokens.copyWith(
        density: TilawaDensity.compact,
      );

      expect(compactTokens.density, TilawaDensity.compact);
      // Phase 0: Other values unchanged
      expect(
        compactTokens.settingsGroup.tileContentPadding,
        equals(comfortableTokens.settingsGroup.tileContentPadding),
      );
    });

    test('settings group tokens are accessible with density context', () {
      final tokens = TilawaComponentTokens.light(
        density: TilawaDensity.compact,
      );

      // Verify we can access all the expected token families
      expect(tokens.settingsGroup, isNotNull);
      expect(tokens.settingsGroup.tileTitleFontSize, greaterThan(0));
      expect(tokens.card, isNotNull);
      expect(tokens.emptyState, isNotNull);
      expect(tokens.chip, isNotNull);
      expect(tokens.searchField, isNotNull);
    });
  });
}
