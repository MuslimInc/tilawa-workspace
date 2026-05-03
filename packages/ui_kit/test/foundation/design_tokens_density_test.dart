import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

void main() {
  group('TilawaDesignTokens Density', () {
    test('default constructor uses comfortable density', () {
      final tokens = TilawaDesignTokens.light();
      expect(tokens.density, TilawaDensity.comfortable);
    });

    test('explicit comfortable equals default', () {
      final defaultTokens = TilawaDesignTokens.light();
      final comfortableTokens = TilawaDesignTokens.light(
        density: TilawaDensity.comfortable,
      );

      // All numeric values should be identical
      expect(comfortableTokens.spaceTiny, equals(defaultTokens.spaceTiny));
      expect(comfortableTokens.spaceSmall, equals(defaultTokens.spaceSmall));
      expect(comfortableTokens.spaceMedium, equals(defaultTokens.spaceMedium));
      expect(comfortableTokens.spaceLarge, equals(defaultTokens.spaceLarge));
      expect(
        comfortableTokens.spaceExtraLarge,
        equals(defaultTokens.spaceExtraLarge),
      );
      expect(comfortableTokens.radiusSmall, equals(defaultTokens.radiusSmall));
      expect(
        comfortableTokens.radiusMedium,
        equals(defaultTokens.radiusMedium),
      );
      expect(
        comfortableTokens.iconSizeMedium,
        equals(defaultTokens.iconSizeMedium),
      );
    });

    test('Phase 0: compact stores density but equals comfortable values', () {
      final comfortableTokens = TilawaDesignTokens.light(
        density: TilawaDensity.comfortable,
      );
      final compactTokens = TilawaDesignTokens.light(
        density: TilawaDensity.compact,
      );

      // Density field differs
      expect(compactTokens.density, TilawaDensity.compact);
      expect(comfortableTokens.density, TilawaDensity.comfortable);

      // Phase 0: All values are identical (no compact scaling yet)
      expect(compactTokens.spaceTiny, equals(comfortableTokens.spaceTiny));
      expect(compactTokens.spaceSmall, equals(comfortableTokens.spaceSmall));
      expect(compactTokens.spaceMedium, equals(comfortableTokens.spaceMedium));
      expect(compactTokens.radiusSmall, equals(comfortableTokens.radiusSmall));
      expect(
        compactTokens.iconSizeMedium,
        equals(comfortableTokens.iconSizeMedium),
      );
    });

    test('dark theme supports density parameter', () {
      final darkComfortable = TilawaDesignTokens.dark(
        density: TilawaDensity.comfortable,
      );
      final darkCompact = TilawaDesignTokens.dark(
        density: TilawaDensity.compact,
      );

      expect(darkComfortable.density, TilawaDensity.comfortable);
      expect(darkCompact.density, TilawaDensity.compact);

      // Phase 0: Same values
      expect(darkCompact.spaceMedium, equals(darkComfortable.spaceMedium));
    });

    test('copyWith preserves density by default', () {
      final compactTokens = TilawaDesignTokens.light(
        density: TilawaDensity.compact,
      );
      final copied = compactTokens.copyWith(spaceMedium: 20.0);

      expect(copied.density, TilawaDensity.compact);
      expect(copied.spaceMedium, 20.0);
    });

    test('copyWith can change density', () {
      final comfortableTokens = TilawaDesignTokens.light(
        density: TilawaDensity.comfortable,
      );
      final compactTokens = comfortableTokens.copyWith(
        density: TilawaDensity.compact,
      );

      expect(compactTokens.density, TilawaDensity.compact);
      // Phase 0: Other values unchanged
      expect(compactTokens.spaceMedium, comfortableTokens.spaceMedium);
    });
  });
}
