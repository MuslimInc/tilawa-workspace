import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../lib/src/foundation/component_tokens/atoms_tokens.dart';
import '../../lib/src/foundation/component_tokens/component_tokens_theme.dart';
import '../../lib/src/foundation/component_tokens/molecules_tokens.dart';
import '../../lib/src/foundation/component_tokens/organisms_tokens.dart';
import '../../lib/src/foundation/component_tokens/token_lerp.dart';

void main() {
  group('TilawaSectionTitleTokens', () {
    test('defaults creates FontWeight.w800', () {
      final tokens = TilawaSectionTitleTokens.defaults();
      expect(tokens.fontWeight, FontWeight.w800);
    });

    test('copyWith updates fontWeight', () {
      final original = TilawaSectionTitleTokens.defaults();
      final updated = original.copyWith(fontWeight: FontWeight.w600);
      expect(updated.fontWeight, FontWeight.w600);
      expect(original.fontWeight, FontWeight.w800);
    });

    test('lerp at 0.0 returns first', () {
      const first = TilawaSectionTitleTokens(fontWeight: FontWeight.w600);
      const second = TilawaSectionTitleTokens(fontWeight: FontWeight.w800);
      final result = TilawaSectionTitleTokens.lerp(first, second, 0.0);
      expect(result.fontWeight, FontWeight.w600);
    });

    test('lerp at 1.0 returns second', () {
      const first = TilawaSectionTitleTokens(fontWeight: FontWeight.w600);
      const second = TilawaSectionTitleTokens(fontWeight: FontWeight.w800);
      final result = TilawaSectionTitleTokens.lerp(first, second, 1.0);
      expect(result.fontWeight, FontWeight.w800);
    });
  });

  group('TilawaSheetHandleTokens', () {
    test('defaults creates expected values', () {
      final tokens = TilawaSheetHandleTokens.defaults();
      expect(tokens.width, 46.0);
      expect(tokens.height, 5.0);
      expect(tokens.marginBottom, 16.0);
      expect(tokens.cornerRadius, 999.0);
      expect(tokens.colorOpacity, 0.22);
    });

    test('copyWith updates individual values', () {
      final original = TilawaSheetHandleTokens.defaults();
      final updated = original.copyWith(width: 50.0, marginBottom: 20.0);
      expect(updated.width, 50.0);
      expect(updated.marginBottom, 20.0);
      expect(updated.height, original.height);
    });

    test('lerp interpolates all numeric values', () {
      const first = TilawaSheetHandleTokens(
        width: 40.0,
        height: 4.0,
        marginBottom: 12.0,
        cornerRadius: 900.0,
        colorOpacity: 0.2,
      );
      const second = TilawaSheetHandleTokens(
        width: 60.0,
        height: 6.0,
        marginBottom: 20.0,
        cornerRadius: 999.0,
        colorOpacity: 0.3,
      );
      final result = TilawaSheetHandleTokens.lerp(first, second, 0.5);
      expect(result.width, closeTo(50.0, 0.01));
      expect(result.height, closeTo(5.0, 0.01));
      expect(result.marginBottom, closeTo(16.0, 0.01));
      expect(result.colorOpacity, closeTo(0.25, 0.01));
    });
  });

  group('TilawaFeedbackStripTokens', () {
    test('defaults creates expected values', () {
      final tokens = TilawaFeedbackStripTokens.defaults();
      expect(tokens.padding, const EdgeInsets.all(14));
      expect(tokens.borderRadius, 18.0);
      expect(tokens.spinnerSize, 18.0);
      expect(tokens.spinnerStrokeWidth, 2.2);
      expect(tokens.contentGap, 10.0);
    });

    test('copyWith updates padding and numeric values', () {
      final original = TilawaFeedbackStripTokens.defaults();
      final updated = original.copyWith(
        padding: const EdgeInsets.all(16),
        spinnerSize: 20.0,
      );
      expect(updated.padding, const EdgeInsets.all(16));
      expect(updated.spinnerSize, 20.0);
      expect(updated.borderRadius, original.borderRadius);
    });

    test('lerp interpolates numeric values and EdgeInsets', () {
      const first = TilawaFeedbackStripTokens(
        padding: EdgeInsets.all(10),
        borderRadius: 15.0,
        spinnerSize: 16.0,
        spinnerStrokeWidth: 2.0,
        contentGap: 8.0,
      );
      const second = TilawaFeedbackStripTokens(
        padding: EdgeInsets.all(20),
        borderRadius: 20.0,
        spinnerSize: 20.0,
        spinnerStrokeWidth: 3.0,
        contentGap: 12.0,
      );
      final result = TilawaFeedbackStripTokens.lerp(first, second, 0.5);
      expect(result.borderRadius, closeTo(17.5, 0.01));
      expect(result.spinnerSize, closeTo(18.0, 0.01));
      expect(result.contentGap, closeTo(10.0, 0.01));
    });
  });

  group('TilawaGlassPanelTokens', () {
    test('defaults creates expected values', () {
      final tokens = TilawaGlassPanelTokens.defaults();
      expect(tokens.padding, const EdgeInsets.all(16));
      expect(tokens.borderRadiusOffset, 8.0);
      expect(tokens.backgroundOpacity, 0.8);
    });

    test('copyWith updates values preserving others', () {
      final original = TilawaGlassPanelTokens.defaults();
      final updated = original.copyWith(
        padding: const EdgeInsets.all(20),
        backgroundOpacity: 0.9,
      );
      expect(updated.padding, const EdgeInsets.all(20));
      expect(updated.backgroundOpacity, 0.9);
      expect(updated.borderRadiusOffset, 8.0);
    });

    test('lerp interpolates all values', () {
      const first = TilawaGlassPanelTokens(
        padding: EdgeInsets.all(12),
        borderRadiusOffset: 6.0,
        backgroundOpacity: 0.7,
      );
      const second = TilawaGlassPanelTokens(
        padding: EdgeInsets.all(20),
        borderRadiusOffset: 10.0,
        backgroundOpacity: 0.9,
      );
      final result = TilawaGlassPanelTokens.lerp(first, second, 0.5);
      expect(result.borderRadiusOffset, closeTo(8.0, 0.01));
      expect(result.backgroundOpacity, closeTo(0.8, 0.01));
    });
  });

  group('TilawaIconActionButtonTokens', () {
    test('defaults creates expected values', () {
      final tokens = TilawaIconActionButtonTokens.defaults();
      expect(tokens.size, kMinInteractiveDimension);
      expect(tokens.borderRadius, 16.0);
      expect(tokens.activeBackgroundOpacity, 0.12);
      expect(tokens.activeBorderOpacity, 0.35);
      expect(tokens.inactiveBorderOpacity, 0.26);
    });

    test('copyWith updates opacity values', () {
      final original = TilawaIconActionButtonTokens.defaults();
      final updated = original.copyWith(
        activeBackgroundOpacity: 0.15,
        activeBorderOpacity: 0.4,
      );
      expect(updated.activeBackgroundOpacity, 0.15);
      expect(updated.activeBorderOpacity, 0.4);
      expect(updated.inactiveBorderOpacity, original.inactiveBorderOpacity);
    });

    test('lerp interpolates all numeric values', () {
      const first = TilawaIconActionButtonTokens(
        size: 40.0,
        borderRadius: 12.0,
        activeBackgroundOpacity: 0.1,
        activeBorderOpacity: 0.3,
        inactiveBorderOpacity: 0.2,
      );
      const second = TilawaIconActionButtonTokens(
        size: 50.0,
        borderRadius: 20.0,
        activeBackgroundOpacity: 0.15,
        activeBorderOpacity: 0.4,
        inactiveBorderOpacity: 0.3,
      );
      final result = TilawaIconActionButtonTokens.lerp(first, second, 0.5);
      expect(result.size, closeTo(45.0, 0.01));
      expect(result.activeBackgroundOpacity, closeTo(0.125, 0.01));
    });
  });

  group('TilawaSearchFieldTokens', () {
    test('defaults creates expected values', () {
      final tokens = TilawaSearchFieldTokens.defaults();
      expect(tokens.height, kMinInteractiveDimension);
      expect(tokens.borderRadius, 16.0);
      expect(tokens.contentPadding, const EdgeInsets.symmetric(vertical: 12));
      expect(tokens.iconSize, 18.0);
      expect(tokens.focusedBorderOpacity, 0.28);
      expect(tokens.shadowBlur, 12.0);
      expect(tokens.shadowOffset, const Offset(0, 4));
    });

    test('copyWith updates all value types', () {
      final original = TilawaSearchFieldTokens.defaults();
      final updated = original.copyWith(
        height: 52.0,
        borderRadius: 20.0,
        focusedBorderOpacity: 0.3,
        shadowOffset: const Offset(0, 6),
      );
      expect(updated.height, 52.0);
      expect(updated.focusedBorderOpacity, 0.3);
      expect(updated.shadowOffset, const Offset(0, 6));
    });

    test('lerp interpolates all numeric values and EdgeInsets', () {
      const first = TilawaSearchFieldTokens(
        height: 48.0,
        borderRadius: 14.0,
        contentPadding: EdgeInsets.symmetric(vertical: 10),
        iconSize: 16.0,
        focusedBorderOpacity: 0.25,
        unfocusedBorderOpacity: 0.2,
        shadowOpacity: 0.03,
        hintOpacity: 0.5,
        iconOpacity: 0.7,
        shadowBlur: 10.0,
        shadowOffset: Offset(0, 2),
      );
      const second = TilawaSearchFieldTokens(
        height: 56.0,
        borderRadius: 18.0,
        contentPadding: EdgeInsets.symmetric(vertical: 14),
        iconSize: 20.0,
        focusedBorderOpacity: 0.32,
        unfocusedBorderOpacity: 0.28,
        shadowOpacity: 0.05,
        hintOpacity: 0.65,
        iconOpacity: 0.75,
        shadowBlur: 14.0,
        shadowOffset: Offset(0, 6),
      );
      final result = TilawaSearchFieldTokens.lerp(first, second, 0.5);
      expect(result.height, closeTo(52.0, 0.01));
      expect(result.shadowBlur, closeTo(12.0, 0.01));
      expect(result.focusedBorderOpacity, closeTo(0.285, 0.01));
    });
  });

  group('TilawaCountProgressRingTokens', () {
    test('defaults creates expected values', () {
      final tokens = TilawaCountProgressRingTokens.defaults();
      expect(tokens.outerSize, 72.0);
      expect(tokens.innerSize, 62.0);
      expect(tokens.ringStrokeWidth, 10.0);
      expect(tokens.activeGradientEndOpacity, 0.8);
      expect(tokens.countLineHeight, 1.0);
    });

    test('copyWith updates values preserving others', () {
      final original = TilawaCountProgressRingTokens.defaults();
      final updated = original.copyWith(outerSize: 80.0, countFontSize: 40.0);
      expect(updated.outerSize, 80.0);
      expect(updated.countFontSize, 40.0);
      expect(updated.innerSize, original.innerSize);
    });

    test('lerp interpolates numeric values and EdgeInsets', () {
      const first = TilawaCountProgressRingTokens(
        outerSize: 60.0,
        innerSize: 50.0,
        ringStrokeWidth: 8.0,
        doneIconSize: 40.0,
        countFontSize: 30.0,
        countLineHeight: 0.9,
        doneBorderWidth: 1.0,
        doneBorderOpacity: 0.2,
        activeGradientEndOpacity: 0.7,
        doneGradientEndOpacity: 0.6,
        progressLabelSpacing: 12.0,
        progressLabelPadding: EdgeInsets.all(4),
        progressLabelBorderRadius: 16.0,
        progressLabelBackgroundOpacity: 0.2,
      );
      const second = TilawaCountProgressRingTokens(
        outerSize: 80.0,
        innerSize: 70.0,
        ringStrokeWidth: 12.0,
        doneIconSize: 60.0,
        countFontSize: 42.0,
        countLineHeight: 1.1,
        doneBorderWidth: 3.0,
        doneBorderOpacity: 0.4,
        activeGradientEndOpacity: 0.9,
        doneGradientEndOpacity: 0.8,
        progressLabelSpacing: 20.0,
        progressLabelPadding: EdgeInsets.all(8),
        progressLabelBorderRadius: 24.0,
        progressLabelBackgroundOpacity: 0.4,
      );
      final result = TilawaCountProgressRingTokens.lerp(first, second, 0.5);
      expect(result.outerSize, closeTo(70.0, 0.01));
      expect(result.countFontSize, closeTo(36.0, 0.01));
      expect(result.countLineHeight, closeTo(1.0, 0.01));
      expect(result.progressLabelBackgroundOpacity, closeTo(0.3, 0.01));
    });
  });

  group('TilawaPlayerBackgroundTokens', () {
    test('defaults creates expected values', () {
      final tokens = TilawaPlayerBackgroundTokens.defaults();
      expect(tokens.cacheWidthScale, 2.0);
      expect(tokens.defaultBlurAmount, 0.0);
      expect(tokens.defaultOverlayOpacity, 0.4);
      expect(tokens.overlayColor, Colors.black);
    });

    test('copyWith updates values preserving others', () {
      final original = TilawaPlayerBackgroundTokens.defaults();
      final updated = original.copyWith(defaultOverlayOpacity: 0.5);
      expect(updated.defaultOverlayOpacity, 0.5);
      expect(updated.cacheWidthScale, original.cacheWidthScale);
    });

    test('lerp interpolates values', () {
      const first = TilawaPlayerBackgroundTokens(
        cacheWidthScale: 1.0,
        defaultBlurAmount: 0.0,
        defaultOverlayOpacity: 0.3,
        overlayColor: Colors.black,
      );
      const second = TilawaPlayerBackgroundTokens(
        cacheWidthScale: 3.0,
        defaultBlurAmount: 12.0,
        defaultOverlayOpacity: 0.5,
        overlayColor: Colors.white,
      );
      final result = TilawaPlayerBackgroundTokens.lerp(first, second, 0.5);
      expect(result.cacheWidthScale, closeTo(2.0, 0.01));
      expect(result.defaultBlurAmount, closeTo(6.0, 0.01));
      expect(result.defaultOverlayOpacity, closeTo(0.4, 0.01));
    });
  });

  group('TilawaSettingsGroupTokens', () {
    test('defaults creates expected values', () {
      final tokens = TilawaSettingsGroupTokens.defaults();
      expect(tokens.groupBorderRadius, 20.0);
      expect(tokens.groupShadowOpacity, 0.06);
      expect(tokens.tileTitleFontSize, 15.5);
      expect(tokens.tileSubtitleOpacity, 0.5);
      expect(tokens.switchActiveTrackOpacity, 0.5);
    });

    test('copyWith updates nested EdgeInsets and numeric values', () {
      final original = TilawaSettingsGroupTokens.defaults();
      final updated = original.copyWith(
        groupBorderRadius: 24.0,
        tileTitleFontSize: 16.0,
        tileSubtitleOpacity: 0.6,
      );
      expect(updated.groupBorderRadius, 24.0);
      expect(updated.tileTitleFontSize, 16.0);
      expect(updated.tileSubtitleOpacity, 0.6);
      expect(updated.groupShadowOpacity, original.groupShadowOpacity);
    });

    test('lerp interpolates all numeric and EdgeInsets values', () {
      const first = TilawaSettingsGroupTokens(
        groupHeaderPadding: EdgeInsets.fromLTRB(10, 14, 14, 6),
        groupBorderRadius: 16.0,
        groupShadowOpacity: 0.04,
        groupShadowBlur: 8.0,
        groupShadowOffset: Offset(0, 2),
        groupTitleFontSize: 12.0,
        groupTitleLetterSpacing: 1.0,
        tileContentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 1),
        switchTileContentPadding: EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 10,
        ),
        tileIconPadding: EdgeInsets.all(8),
        tileIconBorderRadius: 10.0,
        tileIconSize: 20.0,
        tileTitleFontSize: 15.0,
        tileSubtitleFontSize: 12.0,
        tileSubtitleOpacity: 0.4,
        tileSubtitleSpacing: 2.0,
        tileTrailingSize: 12.0,
        tileTrailingOpacity: 0.3,
        tileIconContainerOpacity: 0.08,
        tileDividerPadding: EdgeInsets.only(left: 60, right: 14),
        tileDividerHeight: 0.5,
        tileDividerThickness: 0.25,
        tileDividerOpacity: 0.03,
        switchActiveTrackOpacity: 0.4,
        tileItemGap: 14.0,
      );
      const second = TilawaSettingsGroupTokens(
        groupHeaderPadding: EdgeInsets.fromLTRB(14, 18, 18, 10),
        groupBorderRadius: 24.0,
        groupShadowOpacity: 0.08,
        groupShadowBlur: 12.0,
        groupShadowOffset: Offset(0, 6),
        groupTitleFontSize: 13.0,
        groupTitleLetterSpacing: 1.2,
        tileContentPadding: EdgeInsets.symmetric(horizontal: 18, vertical: 3),
        switchTileContentPadding: EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 14,
        ),
        tileIconPadding: EdgeInsets.all(12),
        tileIconBorderRadius: 14.0,
        tileIconSize: 24.0,
        tileTitleFontSize: 16.0,
        tileSubtitleFontSize: 13.0,
        tileSubtitleOpacity: 0.6,
        tileSubtitleSpacing: 6.0,
        tileTrailingSize: 16.0,
        tileTrailingOpacity: 0.4,
        tileIconContainerOpacity: 0.12,
        tileDividerPadding: EdgeInsets.only(left: 68, right: 18),
        tileDividerHeight: 1.5,
        tileDividerThickness: 0.75,
        tileDividerOpacity: 0.07,
        switchActiveTrackOpacity: 0.6,
        tileItemGap: 18.0,
      );

      final result = TilawaSettingsGroupTokens.lerp(first, second, 0.5);
      expect(result.groupBorderRadius, closeTo(20.0, 0.01));
      expect(result.tileTitleFontSize, closeTo(15.5, 0.01));
      expect(result.switchActiveTrackOpacity, closeTo(0.5, 0.01));
    });
  });

  group('TilawaAdaptiveShellTokens', () {
    test('defaults creates expected values', () {
      final tokens = TilawaAdaptiveShellTokens.defaults();
      expect(tokens.compactBottomNavBarBaseHeight, 70.0);
      expect(tokens.bottomNavHorizontalMargin, 16.0);
      expect(tokens.navButtonMinHeight, 64.0);
    });

    test('copyWith updates compact bottom nav bar base height', () {
      final original = TilawaAdaptiveShellTokens.defaults();
      final updated = original.copyWith(compactBottomNavBarBaseHeight: 92.0);
      expect(updated.compactBottomNavBarBaseHeight, 92.0);
      expect(updated.bottomNavRadius, original.bottomNavRadius);
    });

    test('lerp interpolates compact bottom nav bar base height', () {
      const first = TilawaAdaptiveShellTokens(
        compactBottomNavBarBaseHeight: 88.0,
        bottomNavHorizontalMargin: 16.0,
        bottomNavVerticalMargin: 4.0,
        bottomNavInternalPadding: 8.0,
        bottomNavRadius: 32.0,
        bottomNavInnerRadius: 24.0,
        bottomNavBorderWidth: 1.0,
        bottomNavItemGap: 4.0,
        sideRailRadius: 16.0,
        sideRailShadowOpacity: 0.05,
        sideRailShadowBlur: 12.0,
        sideRailShadowOffset: Offset(2, 0),
        navButtonMinHeight: 64.0,
        navButtonVerticalPadding: 4.0,
        navButtonGap: 4.0,
        navButtonIconSize: 22.0,
        navButtonSelectedCenterScale: 1.1,
        navButtonUnselectedScale: 0.95,
        navButtonSelectedBackgroundOpacity: 0.2,
        navButtonSelectedCenterOpacity: 0.25,
        navButtonLabelFontSize: 10.0,
        navButtonSelectedLabelWeight: FontWeight.w700,
        navButtonUnselectedLabelWeight: FontWeight.w500,
      );
      const second = TilawaAdaptiveShellTokens(
        compactBottomNavBarBaseHeight: 96.0,
        bottomNavHorizontalMargin: 20.0,
        bottomNavVerticalMargin: 8.0,
        bottomNavInternalPadding: 12.0,
        bottomNavRadius: 36.0,
        bottomNavInnerRadius: 28.0,
        bottomNavBorderWidth: 2.0,
        bottomNavItemGap: 6.0,
        sideRailRadius: 20.0,
        sideRailShadowOpacity: 0.08,
        sideRailShadowBlur: 16.0,
        sideRailShadowOffset: Offset(4, 0),
        navButtonMinHeight: 68.0,
        navButtonVerticalPadding: 6.0,
        navButtonGap: 6.0,
        navButtonIconSize: 24.0,
        navButtonSelectedCenterScale: 1.2,
        navButtonUnselectedScale: 1.0,
        navButtonSelectedBackgroundOpacity: 0.25,
        navButtonSelectedCenterOpacity: 0.3,
        navButtonLabelFontSize: 11.0,
        navButtonSelectedLabelWeight: FontWeight.w800,
        navButtonUnselectedLabelWeight: FontWeight.w600,
      );

      final result = TilawaAdaptiveShellTokens.lerp(first, second, 0.5);
      expect(result.compactBottomNavBarBaseHeight, closeTo(92.0, 0.01));
      expect(result.bottomNavHorizontalMargin, closeTo(18.0, 0.01));
      expect(result.navButtonIconSize, closeTo(23.0, 0.01));
    });
  });

  group('TilawaImmersiveComposerTokens', () {
    test('defaults creates expected values', () {
      final tokens = TilawaImmersiveComposerTokens.defaults();
      expect(tokens.defaultAutoHideDuration, const Duration(seconds: 3));
      expect(tokens.transitionDuration, const Duration(milliseconds: 300));
      expect(tokens.backgroundBlurScale, 0.9);
      expect(tokens.backgroundOverlayOpacity, 0.42);
      expect(tokens.overlayBorderOpacity, 0.1);
      expect(tokens.compactHeightBreakpoint, 760.0);
      expect(tokens.compactPanelHeightFactor, 0.5);
      expect(tokens.headerButtonSize, 24.0);
    });

    test('copyWith updates numeric values', () {
      final original = TilawaImmersiveComposerTokens.defaults();
      final updated = original.copyWith(
        backgroundOverlayOpacity: 0.5,
        compactPanelHeightFactor: 0.55,
      );
      expect(updated.backgroundOverlayOpacity, 0.5);
      expect(updated.compactPanelHeightFactor, 0.55);
      expect(updated.backgroundBlurScale, original.backgroundBlurScale);
    });

    test('lerp interpolates all numeric values', () {
      const first = TilawaImmersiveComposerTokens(
        defaultAutoHideDuration: Duration(seconds: 2),
        transitionDuration: Duration(milliseconds: 250),
        backgroundBlurScale: 0.8,
        backgroundOverlayOpacity: 0.4,
        overlayBorderOpacity: 0.08,
        compactHeightBreakpoint: 700.0,
        compactPanelHeightFactor: 0.45,
        regularPanelHeightFactor: 0.4,
        compactPreviewHeightFactor: 0.38,
        regularPreviewHeightFactor: 0.45,
        panelMinHeight: 200.0,
        previewMaxHeight: 400.0,
        headerButtonSize: 40.0,
        headerIconSizeOffset: 1.0,
      );
      const second = TilawaImmersiveComposerTokens(
        defaultAutoHideDuration: Duration(seconds: 4),
        transitionDuration: Duration(milliseconds: 350),
        backgroundBlurScale: 0.95,
        backgroundOverlayOpacity: 0.5,
        overlayBorderOpacity: 0.12,
        compactHeightBreakpoint: 800.0,
        compactPanelHeightFactor: 0.55,
        regularPanelHeightFactor: 0.5,
        compactPreviewHeightFactor: 0.48,
        regularPreviewHeightFactor: 0.55,
        panelMinHeight: 250.0,
        previewMaxHeight: 500.0,
        headerButtonSize: 48.0,
        headerIconSizeOffset: 3.0,
      );

      final result = TilawaImmersiveComposerTokens.lerp(first, second, 0.5);
      expect(result.backgroundBlurScale, closeTo(0.875, 0.01));
      expect(result.compactHeightBreakpoint, closeTo(750.0, 0.1));
      expect(result.headerButtonSize, closeTo(44.0, 0.01));
    });
  });

  group('TilawaComponentTokens', () {
    test('light() creates all component tokens', () {
      final tokens = TilawaComponentTokens.light();
      expect(tokens.sectionTitle, isNotNull);
      expect(tokens.sheetHandle, isNotNull);
      expect(tokens.feedbackStrip, isNotNull);
      expect(tokens.glassPanel, isNotNull);
      expect(tokens.iconActionButton, isNotNull);
      expect(tokens.searchField, isNotNull);
      expect(tokens.countProgressRing, isNotNull);
      expect(tokens.playerBackground, isNotNull);
      expect(tokens.settingsGroup, isNotNull);
      expect(tokens.immersiveComposer, isNotNull);
    });

    test('dark() returns same as light()', () {
      final dark = TilawaComponentTokens.dark();
      final light = TilawaComponentTokens.light();
      expect(dark.sectionTitle.fontWeight, light.sectionTitle.fontWeight);
    });

    test('copyWith updates individual component tokens', () {
      final original = TilawaComponentTokens.light();
      final newSearchTokens = original.searchField.copyWith(
        focusedBorderOpacity: 0.3,
      );
      final updated = original.copyWith(searchField: newSearchTokens);

      expect(updated.searchField.focusedBorderOpacity, 0.3);
      expect(updated.sectionTitle, original.sectionTitle);
    });

    test('lerp interpolates all component tokens', () {
      final first = TilawaComponentTokens.light();
      final second = TilawaComponentTokens.dark();
      final lerped = first.lerp(second, 0.5);

      expect(lerped.sectionTitle, isNotNull);
      expect(lerped.sheetHandle, isNotNull);
      expect(lerped.feedbackStrip, isNotNull);
    });

    test('returns self when other is not TilawaComponentTokens', () {
      final tokens = TilawaComponentTokens.light();
      final result = tokens.lerp(null, 0.5);
      expect(result.sectionTitle, tokens.sectionTitle);
    });

    testWidgets(
      'TilawaComponentTokensX extension accesses tokens from ThemeData',
      (WidgetTester tester) async {
        final tokens = TilawaComponentTokens.light();
        final theme = ThemeData(extensions: [tokens]);

        await tester.pumpWidget(
          MaterialApp(
            theme: theme,
            home: Builder(
              builder: (context) {
                final accessedTokens = Theme.of(context).componentTokens;
                expect(accessedTokens.searchField, isNotNull);
                return const SizedBox.shrink();
              },
            ),
          ),
        );
      },
    );
  });

  group('lerpTokenDouble utility', () {
    test('interpolates double values correctly', () {
      final result = lerpTokenDouble(10.0, 20.0, 0.5);
      expect(result, 15.0);
    });

    test('handles edge cases at boundaries', () {
      expect(lerpTokenDouble(10.0, 20.0, 0.0), 10.0);
      expect(lerpTokenDouble(10.0, 20.0, 1.0), 20.0);
    });

    test('handles fractional t values', () {
      expect(lerpTokenDouble(0.0, 1.0, 0.25), closeTo(0.25, 0.001));
      expect(lerpTokenDouble(0.0, 1.0, 0.75), closeTo(0.75, 0.001));
    });
  });
}
