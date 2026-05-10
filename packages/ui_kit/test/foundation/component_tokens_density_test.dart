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

    test('compact equals comfortable for non-divergent families', () {
      // Witness: divider is intentionally no-op compact (1px display-only
      // line; nothing meaningful to shrink). If this ever diverges, replace
      // the witness with another permanently no-op family.
      final comfortableTokens = TilawaComponentTokens.light(
        density: TilawaDensity.comfortable,
      );
      final compactTokens = TilawaComponentTokens.light(
        density: TilawaDensity.compact,
      );

      expect(
        compactTokens.divider.thickness,
        equals(comfortableTokens.divider.thickness),
      );
      expect(
        compactTokens.divider.height,
        equals(comfortableTokens.divider.height),
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

      // card.padding removed — it diverges in Phase 1E-A
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

    test('compact changes switchTileContentPadding vertical to 10', () {
      final compact = TilawaSettingsGroupTokens.defaults(
        density: TilawaDensity.compact,
      );
      expect(
        compact.switchTileContentPadding,
        const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      );
    });

    test('compact changes tileSubtitleSpacing to 2', () {
      final compact = TilawaSettingsGroupTokens.defaults(
        density: TilawaDensity.compact,
      );
      expect(compact.tileSubtitleSpacing, 2);
    });

    test('compact changes tileContentPadding vertical to 8', () {
      final compact = TilawaSettingsGroupTokens.defaults(
        density: TilawaDensity.compact,
      );
      expect(
        compact.tileContentPadding,
        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
      // tileSubtitleFontSize changes to 13 in compact
      expect(compact.tileSubtitleFontSize, 13.0);
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
      // tileTrailingSize changes to 18 in compact
      expect(compact.tileTrailingSize, 18.0);
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
      // tileSubtitleOpacity changes to 0.65 in compact
      expect(compact.tileSubtitleOpacity, 0.65);
      // tileTrailingOpacity changes to 0.55 in compact
      expect(compact.tileTrailingOpacity, 0.55);
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
        const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
        const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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

  group('Card Compact Density (Phase 1E-A)', () {
    test('comfortable card tokens equal default/current values', () {
      final defaultTokens = TilawaCardTokens.defaults();
      final comfortable = TilawaCardTokens.defaults(
        density: TilawaDensity.comfortable,
      );

      expect(comfortable.borderRadius, equals(defaultTokens.borderRadius));
      expect(comfortable.borderWidth, equals(defaultTokens.borderWidth));
      expect(comfortable.padding, equals(defaultTokens.padding));
    });

    test('compact changes padding to all(8)', () {
      final compact = TilawaCardTokens.defaults(density: TilawaDensity.compact);
      expect(compact.padding, const EdgeInsets.all(8.0));
    });

    test('compact changes borderRadius to 14', () {
      final compact = TilawaCardTokens.defaults(density: TilawaDensity.compact);
      expect(compact.borderRadius, 14.0);
    });

    test('compact does NOT change borderWidth', () {
      final compact = TilawaCardTokens.defaults(density: TilawaDensity.compact);
      final comfortable = TilawaCardTokens.defaults();
      expect(compact.borderWidth, equals(comfortable.borderWidth));
    });

    test('component tokens propagate compact density to card', () {
      final tokens = TilawaComponentTokens.light(
        density: TilawaDensity.compact,
      );
      expect(tokens.card.padding, const EdgeInsets.all(8.0));
      expect(tokens.card.borderRadius, 14.0);
    });

    test('dark component tokens propagate compact density to card', () {
      final tokens = TilawaComponentTokens.dark(density: TilawaDensity.compact);
      expect(tokens.card.padding, const EdgeInsets.all(8.0));
      expect(tokens.card.borderRadius, 14.0);
    });
  });

  group('GlassPanel Compact Density (Phase 1E-A)', () {
    test('comfortable glassPanel tokens equal default/current values', () {
      final defaultTokens = TilawaGlassPanelTokens.defaults();
      final comfortable = TilawaGlassPanelTokens.defaults(
        density: TilawaDensity.comfortable,
      );

      expect(comfortable.padding, equals(defaultTokens.padding));
      expect(
        comfortable.borderRadiusOffset,
        equals(defaultTokens.borderRadiusOffset),
      );
      expect(
        comfortable.backgroundOpacity,
        equals(defaultTokens.backgroundOpacity),
      );
    });

    test('compact changes padding to all(12)', () {
      final compact = TilawaGlassPanelTokens.defaults(
        density: TilawaDensity.compact,
      );
      expect(compact.padding, const EdgeInsets.all(12));
    });

    test('compact does NOT change borderRadiusOffset', () {
      final compact = TilawaGlassPanelTokens.defaults(
        density: TilawaDensity.compact,
      );
      final comfortable = TilawaGlassPanelTokens.defaults();
      expect(
        compact.borderRadiusOffset,
        equals(comfortable.borderRadiusOffset),
      );
    });

    test('compact does NOT change backgroundOpacity', () {
      final compact = TilawaGlassPanelTokens.defaults(
        density: TilawaDensity.compact,
      );
      final comfortable = TilawaGlassPanelTokens.defaults();
      expect(compact.backgroundOpacity, equals(comfortable.backgroundOpacity));
    });

    test('component tokens propagate compact density to glassPanel', () {
      final tokens = TilawaComponentTokens.light(
        density: TilawaDensity.compact,
      );
      expect(tokens.glassPanel.padding, const EdgeInsets.all(12));
    });

    test('dark component tokens propagate compact density to glassPanel', () {
      final tokens = TilawaComponentTokens.dark(density: TilawaDensity.compact);
      expect(tokens.glassPanel.padding, const EdgeInsets.all(12));
    });
  });

  group('FeedbackStrip Compact Density (Phase 1E-A)', () {
    test('comfortable feedbackStrip tokens equal default/current values', () {
      final defaultTokens = TilawaFeedbackStripTokens.defaults();
      final comfortable = TilawaFeedbackStripTokens.defaults(
        density: TilawaDensity.comfortable,
      );

      expect(comfortable.padding, equals(defaultTokens.padding));
      expect(comfortable.contentGap, equals(defaultTokens.contentGap));
      expect(comfortable.borderRadius, equals(defaultTokens.borderRadius));
      expect(comfortable.spinnerSize, equals(defaultTokens.spinnerSize));
      expect(
        comfortable.spinnerStrokeWidth,
        equals(defaultTokens.spinnerStrokeWidth),
      );
    });

    test('compact changes padding to all(10)', () {
      final compact = TilawaFeedbackStripTokens.defaults(
        density: TilawaDensity.compact,
      );
      expect(compact.padding, const EdgeInsets.all(10));
    });

    test('compact changes contentGap to 8', () {
      final compact = TilawaFeedbackStripTokens.defaults(
        density: TilawaDensity.compact,
      );
      expect(compact.contentGap, 8.0);
    });

    test('compact does NOT change borderRadius', () {
      final compact = TilawaFeedbackStripTokens.defaults(
        density: TilawaDensity.compact,
      );
      final comfortable = TilawaFeedbackStripTokens.defaults();
      expect(compact.borderRadius, equals(comfortable.borderRadius));
    });

    test('compact does NOT change spinnerSize', () {
      final compact = TilawaFeedbackStripTokens.defaults(
        density: TilawaDensity.compact,
      );
      final comfortable = TilawaFeedbackStripTokens.defaults();
      expect(compact.spinnerSize, equals(comfortable.spinnerSize));
    });

    test('compact does NOT change spinnerStrokeWidth', () {
      final compact = TilawaFeedbackStripTokens.defaults(
        density: TilawaDensity.compact,
      );
      final comfortable = TilawaFeedbackStripTokens.defaults();
      expect(
        compact.spinnerStrokeWidth,
        equals(comfortable.spinnerStrokeWidth),
      );
    });

    test('component tokens propagate compact density to feedbackStrip', () {
      final tokens = TilawaComponentTokens.light(
        density: TilawaDensity.compact,
      );
      expect(tokens.feedbackStrip.padding, const EdgeInsets.all(10));
      expect(tokens.feedbackStrip.contentGap, 8.0);
    });

    test(
      'dark component tokens propagate compact density to feedbackStrip',
      () {
        final tokens = TilawaComponentTokens.dark(
          density: TilawaDensity.compact,
        );
        expect(tokens.feedbackStrip.padding, const EdgeInsets.all(10));
        expect(tokens.feedbackStrip.contentGap, 8.0);
      },
    );
  });

  // ----- Phase F-A divergent families -----

  group('SheetHandle Compact Density (Phase F-A)', () {
    test('comfortable equals legacy default', () {
      final defaultTokens = TilawaSheetHandleTokens.defaults();
      final comfortable = TilawaSheetHandleTokens.defaults(
        density: TilawaDensity.comfortable,
      );
      expect(comfortable.width, equals(defaultTokens.width));
      expect(comfortable.height, equals(defaultTokens.height));
      expect(comfortable.marginTop, equals(defaultTokens.marginTop));
      expect(comfortable.marginBottom, equals(defaultTokens.marginBottom));
      expect(comfortable.cornerRadius, equals(defaultTokens.cornerRadius));
      expect(comfortable.colorOpacity, equals(defaultTokens.colorOpacity));
    });

    test('compact reduces marginBottom 16→12 and marginTop 12→10', () {
      final compact = TilawaSheetHandleTokens.defaults(
        density: TilawaDensity.compact,
      );
      expect(compact.marginBottom, 12.0);
      expect(compact.marginTop, 10.0);
    });

    test('compact preserves width, height, cornerRadius, colorOpacity', () {
      final compact = TilawaSheetHandleTokens.defaults(
        density: TilawaDensity.compact,
      );
      final comfortable = TilawaSheetHandleTokens.defaults();
      expect(compact.width, equals(comfortable.width));
      expect(compact.height, equals(comfortable.height));
      expect(compact.cornerRadius, equals(comfortable.cornerRadius));
      expect(compact.colorOpacity, equals(comfortable.colorOpacity));
    });

    test('component tokens propagate compact density (light + dark)', () {
      final light = TilawaComponentTokens.light(density: TilawaDensity.compact);
      final dark = TilawaComponentTokens.dark(density: TilawaDensity.compact);
      expect(light.sheetHandle.marginBottom, 12.0);
      expect(light.sheetHandle.marginTop, 10.0);
      expect(dark.sheetHandle.marginBottom, 12.0);
      expect(dark.sheetHandle.marginTop, 10.0);
    });
  });

  group('ErrorState Compact Density (Phase F-A)', () {
    test('comfortable equals legacy default', () {
      final defaultTokens = TilawaErrorStateTokens.defaults();
      final comfortable = TilawaErrorStateTokens.defaults(
        density: TilawaDensity.comfortable,
      );
      expect(comfortable.iconSize, equals(defaultTokens.iconSize));
      expect(comfortable.titleSpacing, equals(defaultTokens.titleSpacing));
      expect(
        comfortable.subtitleSpacing,
        equals(defaultTokens.subtitleSpacing),
      );
      expect(comfortable.actionSpacing, equals(defaultTokens.actionSpacing));
      expect(comfortable.padding, equals(defaultTokens.padding));
      expect(
        comfortable.retryButtonPadding,
        equals(defaultTokens.retryButtonPadding),
      );
      expect(
        comfortable.retryButtonBorderRadius,
        equals(defaultTokens.retryButtonBorderRadius),
      );
    });

    test('compact reduces iconSize 80→64', () {
      final compact = TilawaErrorStateTokens.defaults(
        density: TilawaDensity.compact,
      );
      expect(compact.iconSize, 64.0);
    });

    test('compact reduces titleSpacing 24→16', () {
      final compact = TilawaErrorStateTokens.defaults(
        density: TilawaDensity.compact,
      );
      expect(compact.titleSpacing, 16.0);
    });

    test('compact reduces subtitleSpacing 12→8', () {
      final compact = TilawaErrorStateTokens.defaults(
        density: TilawaDensity.compact,
      );
      expect(compact.subtitleSpacing, 8.0);
    });

    test('compact reduces actionSpacing 32→20', () {
      final compact = TilawaErrorStateTokens.defaults(
        density: TilawaDensity.compact,
      );
      expect(compact.actionSpacing, 20.0);
    });

    test('compact preserves typography, padding, retry button', () {
      final compact = TilawaErrorStateTokens.defaults(
        density: TilawaDensity.compact,
      );
      final comfortable = TilawaErrorStateTokens.defaults();
      expect(compact.iconOpacity, equals(comfortable.iconOpacity));
      expect(compact.titleFontSize, equals(comfortable.titleFontSize));
      expect(compact.titleFontWeight, equals(comfortable.titleFontWeight));
      expect(compact.subtitleFontSize, equals(comfortable.subtitleFontSize));
      expect(compact.subtitleOpacity, equals(comfortable.subtitleOpacity));
      expect(compact.padding, equals(comfortable.padding));
      expect(
        compact.retryButtonPadding,
        equals(comfortable.retryButtonPadding),
      );
      expect(
        compact.retryButtonBorderRadius,
        equals(comfortable.retryButtonBorderRadius),
      );
    });

    test('component tokens propagate compact density (light + dark)', () {
      final light = TilawaComponentTokens.light(density: TilawaDensity.compact);
      final dark = TilawaComponentTokens.dark(density: TilawaDensity.compact);
      expect(light.errorState.iconSize, 64.0);
      expect(dark.errorState.iconSize, 64.0);
    });
  });

  // ----- Phase F-B divergent families -----

  group('SegmentedControl Compact Density (Phase F-B)', () {
    test('comfortable equals legacy default', () {
      final defaultTokens = TilawaSegmentedControlTokens.defaults();
      final comfortable = TilawaSegmentedControlTokens.defaults(
        density: TilawaDensity.comfortable,
      );
      expect(
        comfortable.containerPadding,
        equals(defaultTokens.containerPadding),
      );
      expect(comfortable.itemPadding, equals(defaultTokens.itemPadding));
      expect(
        comfortable.containerRadius,
        equals(defaultTokens.containerRadius),
      );
      expect(comfortable.itemRadius, equals(defaultTokens.itemRadius));
    });

    test('compact tightens containerPadding all(4)→all(2)', () {
      final compact = TilawaSegmentedControlTokens.defaults(
        density: TilawaDensity.compact,
      );
      expect(compact.containerPadding, const EdgeInsets.all(2));
    });

    test('compact tightens itemPadding (h:16,v:8)→(h:12,v:6)', () {
      final compact = TilawaSegmentedControlTokens.defaults(
        density: TilawaDensity.compact,
      );
      expect(
        compact.itemPadding,
        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      );
    });

    test('compact tightens containerRadius 12→10 and itemRadius 8→6', () {
      final compact = TilawaSegmentedControlTokens.defaults(
        density: TilawaDensity.compact,
      );
      expect(compact.containerRadius, 10.0);
      expect(compact.itemRadius, 6.0);
    });

    test('compact preserves opacities, minItemWidth, font weights', () {
      final compact = TilawaSegmentedControlTokens.defaults(
        density: TilawaDensity.compact,
      );
      final comfortable = TilawaSegmentedControlTokens.defaults();
      expect(compact.containerOpacity, equals(comfortable.containerOpacity));
      expect(compact.minItemWidth, equals(comfortable.minItemWidth));
      expect(
        compact.selectedFontWeight,
        equals(comfortable.selectedFontWeight),
      );
      expect(
        compact.unselectedFontWeight,
        equals(comfortable.unselectedFontWeight),
      );
    });

    test('component tokens propagate compact density (light + dark)', () {
      final light = TilawaComponentTokens.light(density: TilawaDensity.compact);
      final dark = TilawaComponentTokens.dark(density: TilawaDensity.compact);
      expect(light.segmentedControl.itemRadius, 6.0);
      expect(dark.segmentedControl.itemRadius, 6.0);
    });
  });

  group('PermissionBanner Compact Density (Phase F-B)', () {
    test('comfortable equals legacy default', () {
      final defaultTokens = TilawaPermissionBannerTokens.defaults();
      final comfortable = TilawaPermissionBannerTokens.defaults(
        density: TilawaDensity.comfortable,
      );
      expect(comfortable.padding, equals(defaultTokens.padding));
      expect(comfortable.borderRadius, equals(defaultTokens.borderRadius));
      expect(comfortable.iconSize, equals(defaultTokens.iconSize));
      expect(comfortable.iconSpacing, equals(defaultTokens.iconSpacing));
      expect(comfortable.actionSpacing, equals(defaultTokens.actionSpacing));
    });

    test('compact tightens padding (h:12,v:8)→(h:10,v:6)', () {
      final compact = TilawaPermissionBannerTokens.defaults(
        density: TilawaDensity.compact,
      );
      expect(
        compact.padding,
        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      );
    });

    test('compact tightens borderRadius 12→10', () {
      final compact = TilawaPermissionBannerTokens.defaults(
        density: TilawaDensity.compact,
      );
      expect(compact.borderRadius, 10.0);
    });

    test('compact tightens iconSpacing 8→6 and actionSpacing 8→6', () {
      final compact = TilawaPermissionBannerTokens.defaults(
        density: TilawaDensity.compact,
      );
      expect(compact.iconSpacing, 6.0);
      expect(compact.actionSpacing, 6.0);
    });

    test('compact preserves iconSize', () {
      final compact = TilawaPermissionBannerTokens.defaults(
        density: TilawaDensity.compact,
      );
      final comfortable = TilawaPermissionBannerTokens.defaults();
      expect(compact.iconSize, equals(comfortable.iconSize));
    });

    test('component tokens propagate compact density (light + dark)', () {
      final light = TilawaComponentTokens.light(density: TilawaDensity.compact);
      final dark = TilawaComponentTokens.dark(density: TilawaDensity.compact);
      expect(light.permissionBanner.borderRadius, 10.0);
      expect(dark.permissionBanner.borderRadius, 10.0);
    });
  });

  group('PrayerAlertRow Compact Density (Phase F-B)', () {
    test('comfortable equals legacy default', () {
      final defaultTokens = TilawaPrayerAlertRowTokens.defaults();
      final comfortable = TilawaPrayerAlertRowTokens.defaults(
        density: TilawaDensity.comfortable,
      );
      expect(
        comfortable.verticalPadding,
        equals(defaultTokens.verticalPadding),
      );
      expect(comfortable.toggleSpacing, equals(defaultTokens.toggleSpacing));
    });

    test('compact tightens verticalPadding 4→2 and toggleSpacing 8→6', () {
      final compact = TilawaPrayerAlertRowTokens.defaults(
        density: TilawaDensity.compact,
      );
      expect(compact.verticalPadding, 2.0);
      expect(compact.toggleSpacing, 6.0);
    });

    test('component tokens propagate compact density (light + dark)', () {
      final light = TilawaComponentTokens.light(density: TilawaDensity.compact);
      final dark = TilawaComponentTokens.dark(density: TilawaDensity.compact);
      expect(light.prayerAlertRow.verticalPadding, 2.0);
      expect(dark.prayerAlertRow.verticalPadding, 2.0);
    });
  });

  // ----- Phase F-C divergent family -----

  group('SearchField Compact Density (Phase F-C)', () {
    test('comfortable equals legacy default', () {
      final defaultTokens = TilawaSearchFieldTokens.defaults();
      final comfortable = TilawaSearchFieldTokens.defaults(
        density: TilawaDensity.comfortable,
      );
      expect(comfortable.height, equals(defaultTokens.height));
      expect(comfortable.borderRadius, equals(defaultTokens.borderRadius));
      expect(comfortable.contentPadding, equals(defaultTokens.contentPadding));
      expect(comfortable.iconSize, equals(defaultTokens.iconSize));
      expect(comfortable.shadowBlur, equals(defaultTokens.shadowBlur));
      expect(comfortable.shadowOffset, equals(defaultTokens.shadowOffset));
    });

    test('compact preserves height at kMinInteractiveDimension (48dp)', () {
      final compact = TilawaSearchFieldTokens.defaults(
        density: TilawaDensity.compact,
      );
      final comfortable = TilawaSearchFieldTokens.defaults();
      expect(compact.height, equals(comfortable.height));
      expect(compact.height, kMinInteractiveDimension);
    });

    test('compact tightens borderRadius 16→12', () {
      final compact = TilawaSearchFieldTokens.defaults(
        density: TilawaDensity.compact,
      );
      expect(compact.borderRadius, 12.0);
    });

    test('compact tightens contentPadding vertical 12→10', () {
      final compact = TilawaSearchFieldTokens.defaults(
        density: TilawaDensity.compact,
      );
      expect(compact.contentPadding, const EdgeInsets.symmetric(vertical: 10));
    });

    test('compact tightens iconSize 18→16', () {
      final compact = TilawaSearchFieldTokens.defaults(
        density: TilawaDensity.compact,
      );
      expect(compact.iconSize, 16.0);
    });

    test('compact tightens shadowBlur 12→8 and shadowOffset (0,4)→(0,2)', () {
      final compact = TilawaSearchFieldTokens.defaults(
        density: TilawaDensity.compact,
      );
      expect(compact.shadowBlur, 8.0);
      expect(compact.shadowOffset, const Offset(0, 2));
    });

    test('compact preserves opacities', () {
      final compact = TilawaSearchFieldTokens.defaults(
        density: TilawaDensity.compact,
      );
      final comfortable = TilawaSearchFieldTokens.defaults();
      expect(
        compact.focusedBorderOpacity,
        equals(comfortable.focusedBorderOpacity),
      );
      expect(
        compact.unfocusedBorderOpacity,
        equals(comfortable.unfocusedBorderOpacity),
      );
      expect(compact.shadowOpacity, equals(comfortable.shadowOpacity));
      expect(compact.hintOpacity, equals(comfortable.hintOpacity));
      expect(compact.iconOpacity, equals(comfortable.iconOpacity));
    });

    test('component tokens propagate compact density (light + dark)', () {
      final light = TilawaComponentTokens.light(density: TilawaDensity.compact);
      final dark = TilawaComponentTokens.dark(density: TilawaDensity.compact);
      expect(light.searchField.borderRadius, 12.0);
      expect(dark.searchField.borderRadius, 12.0);
      expect(light.searchField.height, kMinInteractiveDimension);
      expect(dark.searchField.height, kMinInteractiveDimension);
    });
  });

  // ----- Phase F-D divergent families -----

  group('FooterBar Compact Density (Phase F-D)', () {
    test('comfortable equals legacy default', () {
      final defaultTokens = TilawaFooterBarTokens.defaults();
      final comfortable = TilawaFooterBarTokens.defaults(
        density: TilawaDensity.comfortable,
      );
      expect(comfortable.height, equals(defaultTokens.height));
      expect(
        comfortable.horizontalPadding,
        equals(defaultTokens.horizontalPadding),
      );
      expect(comfortable.contentGap, equals(defaultTokens.contentGap));
    });

    test('compact reduces height 56→52', () {
      final compact = TilawaFooterBarTokens.defaults(
        density: TilawaDensity.compact,
      );
      expect(compact.height, 52.0);
    });

    test('compact reduces horizontalPadding 16→12', () {
      final compact = TilawaFooterBarTokens.defaults(
        density: TilawaDensity.compact,
      );
      expect(compact.horizontalPadding, 12.0);
    });

    test('compact reduces contentGap 12→8', () {
      final compact = TilawaFooterBarTokens.defaults(
        density: TilawaDensity.compact,
      );
      expect(compact.contentGap, 8.0);
    });

    test('compact preserves typography', () {
      final compact = TilawaFooterBarTokens.defaults(
        density: TilawaDensity.compact,
      );
      final comfortable = TilawaFooterBarTokens.defaults();
      expect(compact.labelFontSize, equals(comfortable.labelFontSize));
      expect(compact.labelFontWeight, equals(comfortable.labelFontWeight));
      expect(
        compact.secondaryLabelFontSize,
        equals(comfortable.secondaryLabelFontSize),
      );
      expect(
        compact.secondaryLabelOpacity,
        equals(comfortable.secondaryLabelOpacity),
      );
    });

    test('component tokens propagate compact density (light + dark)', () {
      final light = TilawaComponentTokens.light(density: TilawaDensity.compact);
      final dark = TilawaComponentTokens.dark(density: TilawaDensity.compact);
      expect(light.footerBar.height, 52.0);
      expect(dark.footerBar.height, 52.0);
    });
  });

  group('BottomSheetScaffold Compact Density (Phase F-D)', () {
    test('comfortable equals legacy default', () {
      final defaultTokens = TilawaBottomSheetScaffoldTokens.defaults();
      final comfortable = TilawaBottomSheetScaffoldTokens.defaults(
        density: TilawaDensity.comfortable,
      );
      expect(comfortable.topRadius, equals(defaultTokens.topRadius));
      expect(comfortable.headerPadding, equals(defaultTokens.headerPadding));
      expect(comfortable.bodyPadding, equals(defaultTokens.bodyPadding));
      expect(
        comfortable.closeButtonSize,
        equals(defaultTokens.closeButtonSize),
      );
    });

    test('compact reduces topRadius 28→24', () {
      final compact = TilawaBottomSheetScaffoldTokens.defaults(
        density: TilawaDensity.compact,
      );
      expect(compact.topRadius, 24.0);
    });

    test('compact tightens headerPadding (20,8,12,12)→(16,6,8,8)', () {
      final compact = TilawaBottomSheetScaffoldTokens.defaults(
        density: TilawaDensity.compact,
      );
      expect(compact.headerPadding, const EdgeInsets.fromLTRB(16, 6, 8, 8));
    });

    test('compact tightens bodyPadding all(20)→all(16)', () {
      final compact = TilawaBottomSheetScaffoldTokens.defaults(
        density: TilawaDensity.compact,
      );
      expect(compact.bodyPadding, const EdgeInsets.all(16));
    });

    test('compact preserves closeButtonSize at 40 (already <48dp)', () {
      final compact = TilawaBottomSheetScaffoldTokens.defaults(
        density: TilawaDensity.compact,
      );
      final comfortable = TilawaBottomSheetScaffoldTokens.defaults();
      expect(compact.closeButtonSize, equals(comfortable.closeButtonSize));
      expect(compact.closeButtonSize, 40.0);
    });

    test('component tokens propagate compact density (light + dark)', () {
      final light = TilawaComponentTokens.light(density: TilawaDensity.compact);
      final dark = TilawaComponentTokens.dark(density: TilawaDensity.compact);
      expect(light.bottomSheetScaffold.topRadius, 24.0);
      expect(dark.bottomSheetScaffold.topRadius, 24.0);
    });
  });

  // ----- No-op families (intentionally non-divergent) -----
  //
  // These tests pin every field of each no-op family. If a future engineer
  // adds compact divergence to any of these without intending to, these
  // tests will fail and force them to think about it.

  group('No-op compact families (Phase F)', () {
    test('SectionTitle: compact equals comfortable for every field', () {
      final c = TilawaSectionTitleTokens.defaults(
        density: TilawaDensity.comfortable,
      );
      final k = TilawaSectionTitleTokens.defaults(
        density: TilawaDensity.compact,
      );
      expect(k.fontWeight, equals(c.fontWeight));
    });

    test('LoadingIndicator: compact equals comfortable for every field', () {
      final c = TilawaLoadingIndicatorTokens.defaults(
        density: TilawaDensity.comfortable,
      );
      final k = TilawaLoadingIndicatorTokens.defaults(
        density: TilawaDensity.compact,
      );
      expect(k.defaultStrokeWidth, equals(c.defaultStrokeWidth));
      expect(k.compactStrokeWidth, equals(c.compactStrokeWidth));
    });

    test('IconToggle: compact equals comfortable for every field', () {
      final c = TilawaIconToggleTokens.defaults(
        density: TilawaDensity.comfortable,
      );
      final k = TilawaIconToggleTokens.defaults(density: TilawaDensity.compact);
      expect(k.iconSize, equals(c.iconSize));
      expect(k.padding, equals(c.padding));
      expect(k.borderRadius, equals(c.borderRadius));
    });

    test('Divider: compact equals comfortable for every field', () {
      final c = TilawaDividerTokens.defaults(
        density: TilawaDensity.comfortable,
      );
      final k = TilawaDividerTokens.defaults(density: TilawaDensity.compact);
      expect(k.height, equals(c.height));
      expect(k.thickness, equals(c.thickness));
      expect(k.colorOpacity, equals(c.colorOpacity));
    });

    test('AlphabetScrollbar: compact equals comfortable for every field', () {
      final c = TilawaAlphabetScrollbarTokens.defaults(
        density: TilawaDensity.comfortable,
      );
      final k = TilawaAlphabetScrollbarTokens.defaults(
        density: TilawaDensity.compact,
      );
      expect(k.width, equals(c.width));
      expect(k.itemExtent, equals(c.itemExtent));
      expect(k.selectedIndicatorExtent, equals(c.selectedIndicatorExtent));
      expect(k.letterFontSize, equals(c.letterFontSize));
      expect(k.verticalPadding, equals(c.verticalPadding));
      expect(k.overlaySize, equals(c.overlaySize));
      expect(k.overlayFontSize, equals(c.overlayFontSize));
      expect(k.overlayRadius, equals(c.overlayRadius));
      expect(k.overlayOffset, equals(c.overlayOffset));
    });

    test('IconActionButton: compact equals comfortable for every field', () {
      final c = TilawaIconActionButtonTokens.defaults(
        density: TilawaDensity.comfortable,
      );
      final k = TilawaIconActionButtonTokens.defaults(
        density: TilawaDensity.compact,
      );
      expect(k.size, equals(c.size));
      expect(k.borderRadius, equals(c.borderRadius));
      expect(k.activeBackgroundOpacity, equals(c.activeBackgroundOpacity));
      expect(k.activeBorderOpacity, equals(c.activeBorderOpacity));
      expect(k.inactiveBorderOpacity, equals(c.inactiveBorderOpacity));
    });

    test('SeekBar: compact equals comfortable for every field', () {
      final c = TilawaSeekBarTokens.defaults(
        density: TilawaDensity.comfortable,
      );
      final k = TilawaSeekBarTokens.defaults(density: TilawaDensity.compact);
      expect(k.touchExtent, equals(c.touchExtent));
      expect(k.horizontalMargin, equals(c.horizontalMargin));
      expect(k.trackHeight, equals(c.trackHeight));
      expect(k.thumbRadius, equals(c.thumbRadius));
      expect(k.bufferedTrackOpacity, equals(c.bufferedTrackOpacity));
      expect(k.inactiveTrackOpacity, equals(c.inactiveTrackOpacity));
    });

    test('CountProgressRing: compact equals comfortable for every field', () {
      final c = TilawaCountProgressRingTokens.defaults(
        density: TilawaDensity.comfortable,
      );
      final k = TilawaCountProgressRingTokens.defaults(
        density: TilawaDensity.compact,
      );
      expect(k.outerSize, equals(c.outerSize));
      expect(k.innerSize, equals(c.innerSize));
      expect(k.ringStrokeWidth, equals(c.ringStrokeWidth));
      expect(k.doneIconSize, equals(c.doneIconSize));
      expect(k.countFontSize, equals(c.countFontSize));
      expect(k.countLineHeight, equals(c.countLineHeight));
      expect(k.progressLabelSpacing, equals(c.progressLabelSpacing));
      expect(k.progressLabelPadding, equals(c.progressLabelPadding));
      expect(k.progressLabelBorderRadius, equals(c.progressLabelBorderRadius));
    });

    test('PlayerBackground: compact equals comfortable for every field', () {
      final c = TilawaPlayerBackgroundTokens.defaults(
        density: TilawaDensity.comfortable,
      );
      final k = TilawaPlayerBackgroundTokens.defaults(
        density: TilawaDensity.compact,
      );
      expect(k.cacheWidthScale, equals(c.cacheWidthScale));
      expect(k.defaultBlurAmount, equals(c.defaultBlurAmount));
      expect(k.defaultOverlayOpacity, equals(c.defaultOverlayOpacity));
      expect(k.overlayColor, equals(c.overlayColor));
    });

    test('MediaPlayerBar: compact equals comfortable for every field', () {
      final c = TilawaMediaPlayerBarTokens.defaults(
        density: TilawaDensity.comfortable,
      );
      final k = TilawaMediaPlayerBarTokens.defaults(
        density: TilawaDensity.compact,
      );
      expect(k.contentPadding, equals(c.contentPadding));
      expect(k.borderRadius, equals(c.borderRadius));
      expect(k.artworkSize, equals(c.artworkSize));
      expect(k.controlButtonSize, equals(c.controlButtonSize));
      expect(k.playPauseButtonSize, equals(c.playPauseButtonSize));
    });

    test('AdaptiveShell: compact equals comfortable for every field', () {
      final c = TilawaAdaptiveShellTokens.defaults(
        density: TilawaDensity.comfortable,
      );
      final k = TilawaAdaptiveShellTokens.defaults(
        density: TilawaDensity.compact,
      );
      expect(
        k.compactBottomNavBarBaseHeight,
        equals(c.compactBottomNavBarBaseHeight),
      );
      expect(k.bottomNavInternalPadding, equals(c.bottomNavInternalPadding));
      expect(k.navButtonMinHeight, equals(c.navButtonMinHeight));
      expect(k.navButtonIconSize, equals(c.navButtonIconSize));
      expect(k.navButtonLabelFontSize, equals(c.navButtonLabelFontSize));
    });

    test('ImmersiveComposer: compact equals comfortable for every field', () {
      final c = TilawaImmersiveComposerTokens.defaults(
        density: TilawaDensity.comfortable,
      );
      final k = TilawaImmersiveComposerTokens.defaults(
        density: TilawaDensity.compact,
      );
      expect(k.compactHeightBreakpoint, equals(c.compactHeightBreakpoint));
      expect(k.compactPanelHeightFactor, equals(c.compactPanelHeightFactor));
      expect(k.regularPanelHeightFactor, equals(c.regularPanelHeightFactor));
      expect(k.panelMinHeight, equals(c.panelMinHeight));
      expect(k.previewMaxHeight, equals(c.previewMaxHeight));
      expect(k.headerButtonSize, equals(c.headerButtonSize));
    });
  });
}
