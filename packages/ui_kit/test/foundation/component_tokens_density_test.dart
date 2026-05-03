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

    test('compact stores density correctly', () {
      final comfortableTokens = TilawaComponentTokens.light(
        density: TilawaDensity.comfortable,
      );
      final compactTokens = TilawaComponentTokens.light(
        density: TilawaDensity.compact,
      );

      // Density field differs
      expect(compactTokens.density, TilawaDensity.compact);
      expect(comfortableTokens.density, TilawaDensity.comfortable);
    });

    test(
      'compact equals comfortable for non-settings-non-emptyState-non-iconBox-non-chip families',
      () {
        // Phase 1A: settingsGroup diverges. Phase 1C-A: emptyState diverges.
        // Phase 1D-A: iconBox and chip diverge.
        // All other component token families remain identical until they
        // get their own dedicated compact phases.
        final comfortableTokens = TilawaComponentTokens.light(
          density: TilawaDensity.comfortable,
        );
        final compactTokens = TilawaComponentTokens.light(
          density: TilawaDensity.compact,
        );

        expect(
          compactTokens.card.padding,
          equals(comfortableTokens.card.padding),
        );
        // chip.padding and iconBox.iconSize removed — they diverge in Phase 1D-A
        expect(
          compactTokens.searchField.borderRadius,
          equals(comfortableTokens.searchField.borderRadius),
        );
        expect(
          compactTokens.feedbackStrip.padding,
          equals(comfortableTokens.feedbackStrip.padding),
        );
      },
    );

    test('dark theme supports density parameter', () {
      final darkComfortable = TilawaComponentTokens.dark(
        density: TilawaDensity.comfortable,
      );
      final darkCompact = TilawaComponentTokens.dark(
        density: TilawaDensity.compact,
      );

      expect(darkComfortable.density, TilawaDensity.comfortable);
      expect(darkCompact.density, TilawaDensity.compact);

      // Non-settings families remain identical between density modes
      expect(darkCompact.card.padding, equals(darkComfortable.card.padding));
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

  group('Empty State Compact Density (Phase 1C-A)', () {
    test('comfortable emptyState tokens equal default/current values', () {
      final defaultTokens = TilawaEmptyStateTokens.defaults();
      final comfortable = TilawaEmptyStateTokens.defaults(
        density: TilawaDensity.comfortable,
      );

      expect(comfortable.iconSize, equals(defaultTokens.iconSize));
      expect(comfortable.iconOpacity, equals(defaultTokens.iconOpacity));
      expect(comfortable.titleSpacing, equals(defaultTokens.titleSpacing));
      expect(
        comfortable.subtitleSpacing,
        equals(defaultTokens.subtitleSpacing),
      );
      expect(comfortable.actionSpacing, equals(defaultTokens.actionSpacing));
      expect(comfortable.padding, equals(defaultTokens.padding));
    });

    test('compact changes padding to EdgeInsets.all(16)', () {
      final compact = TilawaEmptyStateTokens.defaults(
        density: TilawaDensity.compact,
      );
      expect(compact.padding, const EdgeInsets.all(16.0));
    });

    test('compact changes iconSize to 40', () {
      final compact = TilawaEmptyStateTokens.defaults(
        density: TilawaDensity.compact,
      );
      expect(compact.iconSize, 40.0);
    });

    test('compact changes titleSpacing to 12', () {
      final compact = TilawaEmptyStateTokens.defaults(
        density: TilawaDensity.compact,
      );
      expect(compact.titleSpacing, 12.0);
    });

    test('compact changes subtitleSpacing to 4', () {
      final compact = TilawaEmptyStateTokens.defaults(
        density: TilawaDensity.compact,
      );
      expect(compact.subtitleSpacing, 4.0);
    });

    test('compact changes actionSpacing to 16', () {
      final compact = TilawaEmptyStateTokens.defaults(
        density: TilawaDensity.compact,
      );
      expect(compact.actionSpacing, 16.0);
    });

    test('compact does NOT change iconOpacity', () {
      final compact = TilawaEmptyStateTokens.defaults(
        density: TilawaDensity.compact,
      );
      final comfortable = TilawaEmptyStateTokens.defaults();
      expect(compact.iconOpacity, equals(comfortable.iconOpacity));
    });

    test('component tokens propagate compact density to emptyState', () {
      final tokens = TilawaComponentTokens.light(
        density: TilawaDensity.compact,
      );
      expect(tokens.emptyState.padding, const EdgeInsets.all(16.0));
      expect(tokens.emptyState.iconSize, 40.0);
      expect(tokens.emptyState.titleSpacing, 12.0);
      expect(tokens.emptyState.subtitleSpacing, 4.0);
      expect(tokens.emptyState.actionSpacing, 16.0);
    });

    test('dark component tokens propagate compact density to emptyState', () {
      final tokens = TilawaComponentTokens.dark(density: TilawaDensity.compact);
      expect(tokens.emptyState.padding, const EdgeInsets.all(16.0));
      expect(tokens.emptyState.iconSize, 40.0);
      expect(tokens.emptyState.titleSpacing, 12.0);
      expect(tokens.emptyState.subtitleSpacing, 4.0);
      expect(tokens.emptyState.actionSpacing, 16.0);
    });
  });

  group('Settings Group Compact Density (Phase 1A)', () {
    test('comfortable settings tokens equal default/current values', () {
      final defaultTokens = TilawaSettingsGroupTokens.defaults();
      final comfortable = TilawaSettingsGroupTokens.defaults(
        density: TilawaDensity.comfortable,
      );

      // Approved-changed tokens (still equal in comfortable)
      expect(
        comfortable.groupHeaderPadding,
        equals(defaultTokens.groupHeaderPadding),
      );
      expect(
        comfortable.switchTileContentPadding,
        equals(defaultTokens.switchTileContentPadding),
      );
      expect(
        comfortable.tileSubtitleSpacing,
        equals(defaultTokens.tileSubtitleSpacing),
      );

      // Preserved tokens
      expect(
        comfortable.tileContentPadding,
        equals(defaultTokens.tileContentPadding),
      );
      expect(
        comfortable.groupTitleFontSize,
        equals(defaultTokens.groupTitleFontSize),
      );
      expect(
        comfortable.tileTitleFontSize,
        equals(defaultTokens.tileTitleFontSize),
      );
      expect(comfortable.tileIconSize, equals(defaultTokens.tileIconSize));
      expect(
        comfortable.tileIconPadding,
        equals(defaultTokens.tileIconPadding),
      );
      expect(comfortable.tileItemGap, equals(defaultTokens.tileItemGap));
    });

    test('compact changes groupHeaderPadding to (12, 12, 16, 6)', () {
      final compact = TilawaSettingsGroupTokens.defaults(
        density: TilawaDensity.compact,
      );
      expect(
        compact.groupHeaderPadding,
        const EdgeInsets.fromLTRB(12, 12, 16, 6),
      );
    });

    test('compact changes switchTileContentPadding vertical to 8', () {
      final compact = TilawaSettingsGroupTokens.defaults(
        density: TilawaDensity.compact,
      );
      expect(
        compact.switchTileContentPadding,
        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      );
    });

    test('compact changes tileSubtitleSpacing to 2', () {
      final compact = TilawaSettingsGroupTokens.defaults(
        density: TilawaDensity.compact,
      );
      expect(compact.tileSubtitleSpacing, 2);
    });

    test('compact does NOT change tileContentPadding', () {
      final compact = TilawaSettingsGroupTokens.defaults(
        density: TilawaDensity.compact,
      );
      final comfortable = TilawaSettingsGroupTokens.defaults();
      expect(
        compact.tileContentPadding,
        equals(comfortable.tileContentPadding),
      );
    });

    test('compact does NOT change font sizes', () {
      final compact = TilawaSettingsGroupTokens.defaults(
        density: TilawaDensity.compact,
      );
      final comfortable = TilawaSettingsGroupTokens.defaults();
      expect(
        compact.groupTitleFontSize,
        equals(comfortable.groupTitleFontSize),
      );
      expect(
        compact.groupTitleLetterSpacing,
        equals(comfortable.groupTitleLetterSpacing),
      );
      expect(compact.tileTitleFontSize, equals(comfortable.tileTitleFontSize));
      expect(
        compact.tileSubtitleFontSize,
        equals(comfortable.tileSubtitleFontSize),
      );
    });

    test('compact does NOT change icon sizes or icon padding', () {
      final compact = TilawaSettingsGroupTokens.defaults(
        density: TilawaDensity.compact,
      );
      final comfortable = TilawaSettingsGroupTokens.defaults();
      expect(compact.tileIconSize, equals(comfortable.tileIconSize));
      expect(compact.tileIconPadding, equals(comfortable.tileIconPadding));
      expect(
        compact.tileIconBorderRadius,
        equals(comfortable.tileIconBorderRadius),
      );
      expect(compact.tileTrailingSize, equals(comfortable.tileTrailingSize));
    });

    test('compact does NOT change divider values', () {
      final compact = TilawaSettingsGroupTokens.defaults(
        density: TilawaDensity.compact,
      );
      final comfortable = TilawaSettingsGroupTokens.defaults();
      expect(
        compact.tileDividerPadding,
        equals(comfortable.tileDividerPadding),
      );
      expect(compact.tileDividerHeight, equals(comfortable.tileDividerHeight));
      expect(
        compact.tileDividerThickness,
        equals(comfortable.tileDividerThickness),
      );
      expect(
        compact.tileDividerOpacity,
        equals(comfortable.tileDividerOpacity),
      );
    });

    test('compact does NOT change horizontal alignment values', () {
      final compact = TilawaSettingsGroupTokens.defaults(
        density: TilawaDensity.compact,
      );
      final comfortable = TilawaSettingsGroupTokens.defaults();

      expect(compact.tileItemGap, equals(comfortable.tileItemGap));

      // Horizontal padding preserved on switchTileContentPadding
      final compactSwitch = compact.switchTileContentPadding as EdgeInsets;
      final comfortableSwitch =
          comfortable.switchTileContentPadding as EdgeInsets;
      expect(compactSwitch.horizontal, equals(comfortableSwitch.horizontal));

      // Horizontal padding preserved on tileContentPadding
      final compactTile = compact.tileContentPadding as EdgeInsets;
      final comfortableTile = comfortable.tileContentPadding as EdgeInsets;
      expect(compactTile.horizontal, equals(comfortableTile.horizontal));
    });

    test('compact does NOT change shadows, radii, or opacities', () {
      final compact = TilawaSettingsGroupTokens.defaults(
        density: TilawaDensity.compact,
      );
      final comfortable = TilawaSettingsGroupTokens.defaults();
      expect(compact.groupBorderRadius, equals(comfortable.groupBorderRadius));
      expect(
        compact.groupShadowOpacity,
        equals(comfortable.groupShadowOpacity),
      );
      expect(compact.groupShadowBlur, equals(comfortable.groupShadowBlur));
      expect(compact.groupShadowOffset, equals(comfortable.groupShadowOffset));
      expect(
        compact.tileSubtitleOpacity,
        equals(comfortable.tileSubtitleOpacity),
      );
      expect(
        compact.tileTrailingOpacity,
        equals(comfortable.tileTrailingOpacity),
      );
      expect(
        compact.tileIconContainerOpacity,
        equals(comfortable.tileIconContainerOpacity),
      );
      expect(
        compact.switchActiveTrackOpacity,
        equals(comfortable.switchActiveTrackOpacity),
      );
    });

    test('component tokens propagate compact density to settingsGroup', () {
      final tokens = TilawaComponentTokens.light(
        density: TilawaDensity.compact,
      );
      expect(
        tokens.settingsGroup.groupHeaderPadding,
        const EdgeInsets.fromLTRB(12, 12, 16, 6),
      );
      expect(
        tokens.settingsGroup.switchTileContentPadding,
        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      );
      expect(tokens.settingsGroup.tileSubtitleSpacing, 2);
    });

    test('component tokens dark theme propagates compact density', () {
      final tokens = TilawaComponentTokens.dark(density: TilawaDensity.compact);
      expect(
        tokens.settingsGroup.groupHeaderPadding,
        const EdgeInsets.fromLTRB(12, 12, 16, 6),
      );
      expect(
        tokens.settingsGroup.switchTileContentPadding,
        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      );
      expect(tokens.settingsGroup.tileSubtitleSpacing, 2);
    });
  });

  group('IconBox Compact Density (Phase 1D-A)', () {
    test('comfortable iconBox tokens equal default/current values', () {
      final defaultTokens = TilawaIconBoxTokens.defaults();
      final comfortable = TilawaIconBoxTokens.defaults(
        density: TilawaDensity.comfortable,
      );

      expect(comfortable.iconSize, equals(defaultTokens.iconSize));
      expect(comfortable.padding, equals(defaultTokens.padding));
      expect(comfortable.borderRadius, equals(defaultTokens.borderRadius));
    });

    test('compact changes iconSize to 20', () {
      final compact = TilawaIconBoxTokens.defaults(
        density: TilawaDensity.compact,
      );
      expect(compact.iconSize, 20.0);
    });

    test('compact changes padding to 6', () {
      final compact = TilawaIconBoxTokens.defaults(
        density: TilawaDensity.compact,
      );
      expect(compact.padding, 6.0);
    });

    test('compact changes borderRadius to 10', () {
      final compact = TilawaIconBoxTokens.defaults(
        density: TilawaDensity.compact,
      );
      expect(compact.borderRadius, 10.0);
    });

    test('component tokens propagate compact density to iconBox', () {
      final tokens = TilawaComponentTokens.light(
        density: TilawaDensity.compact,
      );
      expect(tokens.iconBox.iconSize, 20.0);
      expect(tokens.iconBox.padding, 6.0);
      expect(tokens.iconBox.borderRadius, 10.0);
    });

    test('dark component tokens propagate compact density to iconBox', () {
      final tokens = TilawaComponentTokens.dark(density: TilawaDensity.compact);
      expect(tokens.iconBox.iconSize, 20.0);
      expect(tokens.iconBox.padding, 6.0);
      expect(tokens.iconBox.borderRadius, 10.0);
    });
  });

  group('Chip Compact Density (Phase 1D-A)', () {
    test('comfortable chip tokens equal default/current values', () {
      final defaultTokens = TilawaChipTokens.defaults();
      final comfortable = TilawaChipTokens.defaults(
        density: TilawaDensity.comfortable,
      );

      expect(comfortable.padding, equals(defaultTokens.padding));
      expect(comfortable.compactPadding, equals(defaultTokens.compactPadding));
      expect(comfortable.contentGap, equals(defaultTokens.contentGap));
      expect(comfortable.iconSize, equals(defaultTokens.iconSize));
      expect(
        comfortable.compactIconSize,
        equals(defaultTokens.compactIconSize),
      );
      expect(comfortable.borderWidth, equals(defaultTokens.borderWidth));
      expect(comfortable.pillRadius, equals(defaultTokens.pillRadius));
      expect(comfortable.roundedRadius, equals(defaultTokens.roundedRadius));
      expect(
        comfortable.selectedShadowOpacity,
        equals(defaultTokens.selectedShadowOpacity),
      );
      expect(
        comfortable.selectedShadowBlur,
        equals(defaultTokens.selectedShadowBlur),
      );
      expect(
        comfortable.selectionFontWeight,
        equals(defaultTokens.selectionFontWeight),
      );
      expect(
        comfortable.statusFontWeight,
        equals(defaultTokens.statusFontWeight),
      );
      expect(
        comfortable.statusLetterSpacing,
        equals(defaultTokens.statusLetterSpacing),
      );
    });

    test('compact changes padding to h:12 v:6', () {
      final compact = TilawaChipTokens.defaults(density: TilawaDensity.compact);
      expect(
        compact.padding,
        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      );
    });

    test('compact changes contentGap to 6', () {
      final compact = TilawaChipTokens.defaults(density: TilawaDensity.compact);
      expect(compact.contentGap, 6.0);
    });

    test('compact does NOT change compactPadding', () {
      final compact = TilawaChipTokens.defaults(density: TilawaDensity.compact);
      final comfortable = TilawaChipTokens.defaults();
      expect(compact.compactPadding, equals(comfortable.compactPadding));
    });

    test('compact does NOT change compactIconSize', () {
      final compact = TilawaChipTokens.defaults(density: TilawaDensity.compact);
      final comfortable = TilawaChipTokens.defaults();
      expect(compact.compactIconSize, equals(comfortable.compactIconSize));
    });

    test('compact does NOT change iconSize', () {
      final compact = TilawaChipTokens.defaults(density: TilawaDensity.compact);
      final comfortable = TilawaChipTokens.defaults();
      expect(compact.iconSize, equals(comfortable.iconSize));
    });

    test('compact does NOT change borderWidth', () {
      final compact = TilawaChipTokens.defaults(density: TilawaDensity.compact);
      final comfortable = TilawaChipTokens.defaults();
      expect(compact.borderWidth, equals(comfortable.borderWidth));
    });

    test('compact does NOT change pillRadius', () {
      final compact = TilawaChipTokens.defaults(density: TilawaDensity.compact);
      final comfortable = TilawaChipTokens.defaults();
      expect(compact.pillRadius, equals(comfortable.pillRadius));
    });

    test('compact does NOT change roundedRadius', () {
      final compact = TilawaChipTokens.defaults(density: TilawaDensity.compact);
      final comfortable = TilawaChipTokens.defaults();
      expect(compact.roundedRadius, equals(comfortable.roundedRadius));
    });

    test('compact does NOT change selectedShadowOpacity', () {
      final compact = TilawaChipTokens.defaults(density: TilawaDensity.compact);
      final comfortable = TilawaChipTokens.defaults();
      expect(
        compact.selectedShadowOpacity,
        equals(comfortable.selectedShadowOpacity),
      );
    });

    test('compact does NOT change selectedShadowBlur', () {
      final compact = TilawaChipTokens.defaults(density: TilawaDensity.compact);
      final comfortable = TilawaChipTokens.defaults();
      expect(
        compact.selectedShadowBlur,
        equals(comfortable.selectedShadowBlur),
      );
    });

    test('compact does NOT change selectionFontWeight', () {
      final compact = TilawaChipTokens.defaults(density: TilawaDensity.compact);
      final comfortable = TilawaChipTokens.defaults();
      expect(
        compact.selectionFontWeight,
        equals(comfortable.selectionFontWeight),
      );
    });

    test('compact does NOT change statusFontWeight', () {
      final compact = TilawaChipTokens.defaults(density: TilawaDensity.compact);
      final comfortable = TilawaChipTokens.defaults();
      expect(compact.statusFontWeight, equals(comfortable.statusFontWeight));
    });

    test('compact does NOT change statusLetterSpacing', () {
      final compact = TilawaChipTokens.defaults(density: TilawaDensity.compact);
      final comfortable = TilawaChipTokens.defaults();
      expect(
        compact.statusLetterSpacing,
        equals(comfortable.statusLetterSpacing),
      );
    });

    test('component tokens propagate compact density to chip', () {
      final tokens = TilawaComponentTokens.light(
        density: TilawaDensity.compact,
      );
      expect(
        tokens.chip.padding,
        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      );
      expect(tokens.chip.contentGap, 6.0);
    });

    test('dark component tokens propagate compact density to chip', () {
      final tokens = TilawaComponentTokens.dark(density: TilawaDensity.compact);
      expect(
        tokens.chip.padding,
        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      );
      expect(tokens.chip.contentGap, 6.0);
    });
  });
}
