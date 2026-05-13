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

    test('compact tightens medium/large spacing and radii', () {
      final comfortableTokens = TilawaDesignTokens.light(
        density: TilawaDensity.comfortable,
      );
      final compactTokens = TilawaDesignTokens.light(
        density: TilawaDensity.compact,
      );

      // Density field differs.
      expect(compactTokens.density, TilawaDensity.compact);
      expect(comfortableTokens.density, TilawaDensity.comfortable);

      // Tiny/small spacing and small/medium radii are shared across
      // densities — going further would erode hit margins.
      expect(compactTokens.spaceTiny, equals(comfortableTokens.spaceTiny));
      expect(compactTokens.spaceSmall, equals(comfortableTokens.spaceSmall));
      expect(compactTokens.radiusSmall, equals(comfortableTokens.radiusSmall));
      expect(
        compactTokens.radiusMedium,
        equals(comfortableTokens.radiusMedium),
      );
      expect(
        compactTokens.iconSizeMedium,
        equals(comfortableTokens.iconSizeMedium),
      );

      // Medium spacing tightens on compact (8 vs 12). Larger space/radius
      // steps stay on the same 8dp multiples for both densities today.
      expect(
        compactTokens.spaceMedium,
        lessThan(comfortableTokens.spaceMedium),
      );
      expect(compactTokens.spaceLarge, comfortableTokens.spaceLarge);
      expect(
        compactTokens.spaceExtraLarge,
        comfortableTokens.spaceExtraLarge,
      );
      expect(compactTokens.radiusLarge, comfortableTokens.radiusLarge);
      expect(
        compactTokens.radiusExtraLarge,
        comfortableTokens.radiusExtraLarge,
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

      // Compact tightens medium spacing in dark theme too.
      expect(darkCompact.spaceMedium, lessThan(darkComfortable.spaceMedium));
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
      // copyWith does not recompute spacing from density; explicit fields carry
      // over from the base instance.
      expect(compactTokens.spaceMedium, comfortableTokens.spaceMedium);
    });
  });
}
