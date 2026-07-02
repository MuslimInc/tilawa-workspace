import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa_ui_kit/src/foundation/foundation.dart';

void main() {
  group('MeMuslimDesignTokens', () {
    const defaultTokens = MeMuslimDesignTokens(
      spaceTiny: 2.0,
      spaceExtraSmall: 4.0,
      spaceSmall: 8.0,
      spaceMedium: 12.0,
      spaceLarge: 16.0,
      spaceExtraLarge: 24.0,
      spaceSection: 20.0,
      spaceXXL: 32.0,
      spaceHuge: 48.0,
      radiusSmall: 8.0,
      radiusMedium: 12.0,
      radiusLarge: 16.0,
      radiusExtraLarge: 10.0,
      radiusHero: 12.0,
      opacitySubtle: 0.1,
      opacityShadow: 0.12,
      opacityShadowStrong: 0.18,
      opacityMedium: 0.3,
      opacityEmphasis: 0.7,
      opacityGlass: 0.8,
      blurGlass: 12.0,
      blurShadow: 16.0,
      shadowOffsetSmall: Offset(0, 2),
      shadowOffsetMedium: Offset(0, 4),
      borderWidthThin: 0.5,
      progressHeight: 3.0,
      iconSizeExtraSmall: 12.0,
      iconSizeSmall: 16.0,
      iconSizeMedium: 20.0,
      iconSizeLarge: 24.0,
      iconSizeLargePlus: 42.0,
      iconSizeExtraLarge: 44.0,
      textHeightLoose: 1.8,
      durationFast: Duration(milliseconds: 200),
      durationMedium: Duration(milliseconds: 400),
      durationSlow: Duration(milliseconds: 600),
      curveStandard: Curves.easeOut,
      curveEmphasized: Curves.easeOutCubic,
      curveSymmetric: Curves.easeInOut,
      contentMaxWidthReader: 720,
      contentMaxWidthForm: 560,
      contentMaxWidthMedia: 1200,
      contentMaxWidthSettings: 760,
      narrowCardWidthThreshold: 180.0,
      narrowCardHeightThreshold: 155.0,
      cardTightHeightThreshold: 145.0,
      playerCollapsedHeight: 100.0,
      playerDismissThreshold: 80.0,
      playerMaxDismissOffset: 200.0,
      playerVelocityThreshold: 500.0,
      playerDismissVelocityThreshold: 300.0,
      playerDragSensitivity: 1.5,
      playerProgressThreshold: 0.5,
      playerIgnorePointerThreshold: 0.4,
      playerAlphaScalingFactor: 2.5,
      stateLayerHover: 0.08,
      stateLayerPressed: 0.12,
      stateLayerFocused: 0.12,
      inkSplashAlpha: 0.08,
      inkHighlightAlpha: 0.04,
      focusRingWidth: 2.0,
      dropdownMenuGap: 4.0,
    );

    group('factory constructors', () {
      test('light() creates correct default values', () {
        final light = MeMuslimDesignTokens.light();
        expect(light.spaceExtraSmall, 4.0);
        expect(light.spaceSmall, 8.0);
        expect(light.spaceMedium, 12.0);
        expect(light.spaceLarge, 16.0);
        expect(light.spaceExtraLarge, 24.0);
        expect(light.radiusSmall, 8.0);
        expect(light.radiusMedium, 12.0);
        expect(light.radiusLarge, 20.0);
        expect(light.radiusExtraLarge, 24.0);
        expect(light.radiusHero, 28.0);
        expect(light.opacitySubtle, 0.1);
        expect(light.opacityShadow, 0.04);
        expect(light.opacityShadowStrong, 0.08);
        expect(light.opacityMedium, 0.3);
        expect(light.opacityEmphasis, 0.7);
        expect(light.opacityGlass, 0.8);
        expect(light.blurGlass, 12.0);
        expect(light.blurShadow, 8.0);
        expect(light.shadowOffsetSmall, const Offset(0, 1));
        expect(light.shadowOffsetMedium, const Offset(0, 2));
        expect(light.borderWidthThin, 0.5);
        expect(light.progressHeight, 3.0);
        expect(light.iconSizeExtraSmall, 12.0);
        expect(light.iconSizeSmall, 16.0);
        expect(light.iconSizeMedium, 20.0);
        expect(light.iconSizeLarge, 24.0);
        expect(light.iconSizeLargePlus, 42.0);
        expect(light.iconSizeExtraLarge, 44.0);
        expect(
          light.minInteractiveDimension,
          kMeMuslimMinInteractiveDimension,
        );
        expect(light.minIconSize, kMinIconSize);
        expect(light.iconBoxSize, kIconBoxSize);
        expect(light.iconBadgeSize, kIconBadgeSize);
        expect(light.iconShortcutExtent, light.iconSizeMedium + 24.0);
        expect(light.iconHubExtent, light.iconSizeLarge + 32.0);
        expect(light.iconRingSize, light.iconSizeLarge + light.spaceSmall);
        expect(light.textHeightLoose, 2.0);
        expect(light.durationFast, const Duration(milliseconds: 200));
        expect(light.durationMedium, const Duration(milliseconds: 400));
        expect(light.durationSlow, const Duration(milliseconds: 600));
        expect(light.curveStandard, Curves.easeOut);
        expect(light.curveEmphasized, Curves.easeOutCubic);
        expect(light.curveSymmetric, Curves.easeInOut);
        expect(light.contentMaxWidthReader, 720);
        expect(light.contentMaxWidthForm, 560);
        expect(light.contentMaxWidthMedia, 1200);
        expect(light.contentMaxWidthSettings, 760);
        expect(light.narrowCardWidthThreshold, 180.0);
        expect(light.narrowCardHeightThreshold, 155.0);
        expect(light.cardTightHeightThreshold, 145.0);
        expect(light.dropdownMenuGap, 4.0);
      });

      test('dark() returns same as light()', () {
        final dark = MeMuslimDesignTokens.dark();
        final light = MeMuslimDesignTokens.light();
        expect(dark.spaceExtraSmall, light.spaceExtraSmall);
        expect(dark.spaceSmall, light.spaceSmall);
        expect(dark.radiusSmall, light.radiusSmall);
      });
    });

    group('copyWith()', () {
      test(
        'returns new instance with unchanged values when no args provided',
        () {
          final copy = defaultTokens.copyWith();
          expect(copy.spaceExtraSmall, defaultTokens.spaceExtraSmall);
          expect(copy.spaceSmall, defaultTokens.spaceSmall);
          expect(copy.radiusSmall, defaultTokens.radiusSmall);
        },
      );

      test('updates spacing values', () {
        final updated = defaultTokens.copyWith(
          spaceExtraSmall: 5.0,
          spaceSmall: 10.0,
          spaceMedium: 15.0,
        );
        expect(updated.spaceExtraSmall, 5.0);
        expect(updated.spaceSmall, 10.0);
        expect(updated.spaceMedium, 15.0);
        expect(updated.spaceLarge, defaultTokens.spaceLarge);
      });

      test('updates radius values', () {
        final updated = defaultTokens.copyWith(
          radiusSmall: 6.0,
          radiusLarge: 18.0,
        );
        expect(updated.radiusSmall, 6.0);
        expect(updated.radiusLarge, 18.0);
        expect(updated.radiusMedium, defaultTokens.radiusMedium);
      });

      test('updates opacity values', () {
        final updated = defaultTokens.copyWith(
          opacitySubtle: 0.15,
          opacityShadow: 0.2,
          opacityShadowStrong: 0.3,
          opacityMedium: 0.35,
        );
        expect(updated.opacitySubtle, 0.15);
        expect(updated.opacityMedium, 0.35);
        expect(updated.opacityEmphasis, defaultTokens.opacityEmphasis);
      });

      test('updates blur and shadow values', () {
        final updated = defaultTokens.copyWith(
          blurGlass: 14.0,
          blurShadow: 18.0,
          shadowOffsetSmall: const Offset(0, 3),
        );
        expect(updated.blurGlass, 14.0);
        expect(updated.blurShadow, 18.0);
        expect(updated.shadowOffsetSmall, const Offset(0, 3));
      });

      test('updates duration values', () {
        final updated = defaultTokens.copyWith(
          durationFast: const Duration(milliseconds: 150),
          durationSlow: const Duration(milliseconds: 700),
        );
        expect(updated.durationFast, const Duration(milliseconds: 150));
        expect(updated.durationSlow, const Duration(milliseconds: 700));
      });

      test('updates content max width values', () {
        final updated = defaultTokens.copyWith(
          contentMaxWidthReader: 800,
          contentMaxWidthForm: 600,
        );
        expect(updated.contentMaxWidthReader, 800);
        expect(updated.contentMaxWidthForm, 600);
        expect(
          updated.contentMaxWidthMedia,
          defaultTokens.contentMaxWidthMedia,
        );
      });
    });

    group('lerp()', () {
      test('returns first value at t=0', () {
        const first = MeMuslimDesignTokens(
          spaceTiny: 2.0,
          spaceExtraSmall: 4.0,
          spaceSmall: 8.0,
          spaceMedium: 12.0,
          spaceLarge: 16.0,
          spaceExtraLarge: 24.0,
          spaceSection: 20.0,
          spaceXXL: 32.0,
          spaceHuge: 48.0,
          radiusSmall: 8.0,
          radiusMedium: 12.0,
          radiusLarge: 16.0,
          radiusExtraLarge: 24.0,
          radiusHero: 32.0,
          opacitySubtle: 0.1,
          opacityShadow: 0.18,
          opacityShadowStrong: 0.28,
          opacityMedium: 0.3,
          opacityEmphasis: 0.7,
          opacityGlass: 0.8,
          blurGlass: 12.0,
          blurShadow: 16.0,
          shadowOffsetSmall: Offset(0, 2),
          shadowOffsetMedium: Offset(0, 4),
          borderWidthThin: 0.5,
          progressHeight: 3.0,
          iconSizeSmall: 16.0,
          iconSizeMedium: 20.0,
          iconSizeLarge: 24.0,
          iconSizeLargePlus: 42.0,
          durationFast: Duration(milliseconds: 200),
          durationMedium: Duration(milliseconds: 400),
          durationSlow: Duration(milliseconds: 600),
          curveStandard: Curves.easeOut,
          curveEmphasized: Curves.easeOutCubic,
          curveSymmetric: Curves.easeInOut,
          contentMaxWidthReader: 720,
          contentMaxWidthForm: 560,
          contentMaxWidthMedia: 1200,
          contentMaxWidthSettings: 760,
          narrowCardWidthThreshold: 180.0,
          narrowCardHeightThreshold: 194.0,
          cardTightHeightThreshold: 145.0,
          iconSizeExtraSmall: 12,
          iconSizeExtraLarge: 44,
          textHeightLoose: 1.8,
          playerCollapsedHeight: 100.0,
          playerDismissThreshold: 80.0,
          playerMaxDismissOffset: 200.0,
          playerVelocityThreshold: 500.0,
          playerDismissVelocityThreshold: 300.0,
          playerDragSensitivity: 1.5,
          playerProgressThreshold: 0.5,
          playerIgnorePointerThreshold: 0.4,
          playerAlphaScalingFactor: 2.5,
          stateLayerHover: 0.08,
          stateLayerPressed: 0.12,
          stateLayerFocused: 0.12,
          inkSplashAlpha: 0.08,
          inkHighlightAlpha: 0.04,
          focusRingWidth: 2.0,
          dropdownMenuGap: 4.0,
        );
        const second = MeMuslimDesignTokens(
          spaceTiny: 4.0,
          spaceExtraSmall: 8.0,
          spaceSmall: 16.0,
          spaceMedium: 24.0,
          spaceLarge: 32.0,
          spaceExtraLarge: 48.0,
          spaceSection: 40.0,
          spaceXXL: 64.0,
          spaceHuge: 96.0,
          radiusSmall: 16.0,
          radiusMedium: 24.0,
          radiusLarge: 32.0,
          radiusExtraLarge: 48.0,
          radiusHero: 64.0,
          opacitySubtle: 0.2,
          opacityShadow: 0.3,
          opacityShadowStrong: 0.45,
          opacityMedium: 0.6,
          opacityEmphasis: 0.9,
          opacityGlass: 0.9,
          blurGlass: 20.0,
          blurShadow: 24.0,
          shadowOffsetSmall: Offset(0, 4),
          shadowOffsetMedium: Offset(0, 8),
          borderWidthThin: 1.0,
          progressHeight: 6.0,
          iconSizeSmall: 24.0,
          iconSizeMedium: 32.0,
          iconSizeLarge: 40.0,
          iconSizeLargePlus: 56.0,
          durationFast: Duration(milliseconds: 300),
          durationMedium: Duration(milliseconds: 600),
          durationSlow: Duration(milliseconds: 900),
          curveStandard: Curves.linear,
          curveEmphasized: Curves.linear,
          curveSymmetric: Curves.linear,
          contentMaxWidthReader: 900,
          contentMaxWidthForm: 700,
          contentMaxWidthMedia: 1400,
          contentMaxWidthSettings: 900,
          narrowCardWidthThreshold: 200.0,
          narrowCardHeightThreshold: 220.0,
          cardTightHeightThreshold: 160.0,
          iconSizeExtraSmall: 12,
          iconSizeExtraLarge: 44,
          textHeightLoose: 2.0,
          playerCollapsedHeight: 120.0,
          playerDismissThreshold: 100.0,
          playerMaxDismissOffset: 250.0,
          playerVelocityThreshold: 600.0,
          playerDismissVelocityThreshold: 400.0,
          playerDragSensitivity: 2.0,
          playerProgressThreshold: 0.6,
          playerIgnorePointerThreshold: 0.5,
          playerAlphaScalingFactor: 3.0,
          stateLayerHover: 0.16,
          stateLayerPressed: 0.20,
          stateLayerFocused: 0.20,
          inkSplashAlpha: 0.08,
          inkHighlightAlpha: 0.04,
          focusRingWidth: 3.0,
          dropdownMenuGap: 6.0,
        );

        final lerped = first.lerp(second, 0);
        expect(lerped.spaceExtraSmall, closeTo(4.0, 0.01));
        expect(lerped.radiusSmall, closeTo(8.0, 0.01));
        expect(lerped.opacitySubtle, closeTo(0.1, 0.01));
      });

      test('returns second value at t=1', () {
        final first = MeMuslimDesignTokens.light();
        const second = MeMuslimDesignTokens(
          spaceTiny: 4.0,
          spaceExtraSmall: 8.0,
          spaceSmall: 16.0,
          spaceMedium: 24.0,
          spaceLarge: 32.0,
          spaceExtraLarge: 48.0,
          spaceSection: 40.0,
          spaceXXL: 64.0,
          spaceHuge: 96.0,
          radiusSmall: 16.0,
          radiusMedium: 24.0,
          radiusLarge: 32.0,
          radiusExtraLarge: 48.0,
          radiusHero: 64.0,
          opacitySubtle: 0.2,
          opacityShadow: 0.3,
          opacityShadowStrong: 0.45,
          opacityMedium: 0.6,
          opacityEmphasis: 0.9,
          opacityGlass: 0.9,
          blurGlass: 20.0,
          blurShadow: 24.0,
          shadowOffsetSmall: Offset(0, 4),
          shadowOffsetMedium: Offset(0, 8),
          borderWidthThin: 1.0,
          progressHeight: 6.0,
          iconSizeSmall: 24.0,
          iconSizeMedium: 32.0,
          iconSizeLarge: 40.0,
          iconSizeLargePlus: 56.0,
          durationFast: Duration(milliseconds: 300),
          durationMedium: Duration(milliseconds: 600),
          durationSlow: Duration(milliseconds: 900),
          curveStandard: Curves.linear,
          curveEmphasized: Curves.linear,
          curveSymmetric: Curves.linear,
          contentMaxWidthReader: 900,
          contentMaxWidthForm: 700,
          contentMaxWidthMedia: 1400,
          contentMaxWidthSettings: 900,
          narrowCardWidthThreshold: 200.0,
          narrowCardHeightThreshold: 220.0,
          cardTightHeightThreshold: 160.0,
          iconSizeExtraSmall: 12,
          iconSizeExtraLarge: 44,
          textHeightLoose: 2.0,
          playerCollapsedHeight: 120.0,
          playerDismissThreshold: 100.0,
          playerMaxDismissOffset: 250.0,
          playerVelocityThreshold: 600.0,
          playerDismissVelocityThreshold: 400.0,
          playerDragSensitivity: 2.0,
          playerProgressThreshold: 0.6,
          playerIgnorePointerThreshold: 0.5,
          playerAlphaScalingFactor: 3.0,
          stateLayerHover: 0.16,
          stateLayerPressed: 0.20,
          stateLayerFocused: 0.20,
          inkSplashAlpha: 0.08,
          inkHighlightAlpha: 0.04,
          focusRingWidth: 3.0,
          dropdownMenuGap: 6.0,
        );

        final lerped = first.lerp(second, 1);
        expect(lerped.spaceExtraSmall, closeTo(8.0, 0.01));
        expect(lerped.radiusSmall, closeTo(16.0, 0.01));
      });

      test('returns middle value at t=0.5', () {
        const first = MeMuslimDesignTokens(
          spaceTiny: 2.0,
          spaceExtraSmall: 4.0,
          spaceSmall: 8.0,
          spaceMedium: 12.0,
          spaceLarge: 16.0,
          spaceExtraLarge: 24.0,
          spaceSection: 20.0,
          spaceXXL: 32.0,
          spaceHuge: 48.0,
          radiusSmall: 8.0,
          radiusMedium: 12.0,
          radiusLarge: 16.0,
          radiusExtraLarge: 24.0,
          radiusHero: 32.0,
          opacitySubtle: 0.1,
          opacityShadow: 0.18,
          opacityShadowStrong: 0.28,
          opacityMedium: 0.3,
          opacityEmphasis: 0.7,
          opacityGlass: 0.8,
          blurGlass: 12.0,
          blurShadow: 16.0,
          shadowOffsetSmall: Offset(0, 2),
          shadowOffsetMedium: Offset(0, 4),
          borderWidthThin: 0.5,
          progressHeight: 3.0,
          iconSizeSmall: 16.0,
          iconSizeMedium: 20.0,
          iconSizeLarge: 24.0,
          iconSizeLargePlus: 42.0,
          durationFast: Duration(milliseconds: 200),
          durationMedium: Duration(milliseconds: 400),
          durationSlow: Duration(milliseconds: 600),
          curveStandard: Curves.easeOut,
          curveEmphasized: Curves.easeOutCubic,
          curveSymmetric: Curves.easeInOut,
          contentMaxWidthReader: 720,
          contentMaxWidthForm: 560,
          contentMaxWidthMedia: 1200,
          contentMaxWidthSettings: 760,
          narrowCardWidthThreshold: 180.0,
          narrowCardHeightThreshold: 194.0,
          cardTightHeightThreshold: 145.0,
          iconSizeExtraSmall: 12,
          iconSizeExtraLarge: 44,
          textHeightLoose: 1.8,
          playerCollapsedHeight: 100.0,
          playerDismissThreshold: 80.0,
          playerMaxDismissOffset: 200.0,
          playerVelocityThreshold: 500.0,
          playerDismissVelocityThreshold: 300.0,
          playerDragSensitivity: 1.5,
          playerProgressThreshold: 0.5,
          playerIgnorePointerThreshold: 0.4,
          playerAlphaScalingFactor: 2.5,
          stateLayerHover: 0.08,
          stateLayerPressed: 0.12,
          stateLayerFocused: 0.12,
          inkSplashAlpha: 0.08,
          inkHighlightAlpha: 0.04,
          focusRingWidth: 2.0,
          dropdownMenuGap: 4.0,
        );
        const second = MeMuslimDesignTokens(
          spaceTiny: 4.0,
          spaceExtraSmall: 8.0,
          spaceSmall: 16.0,
          spaceMedium: 24.0,
          spaceLarge: 32.0,
          spaceExtraLarge: 48.0,
          spaceSection: 40.0,
          spaceXXL: 64.0,
          spaceHuge: 96.0,
          radiusSmall: 16.0,
          radiusMedium: 24.0,
          radiusLarge: 32.0,
          radiusExtraLarge: 48.0,
          radiusHero: 64.0,
          opacitySubtle: 0.2,
          opacityShadow: 0.3,
          opacityShadowStrong: 0.45,
          opacityMedium: 0.6,
          opacityEmphasis: 0.9,
          opacityGlass: 0.9,
          blurGlass: 20.0,
          blurShadow: 24.0,
          shadowOffsetSmall: Offset(0, 4),
          shadowOffsetMedium: Offset(0, 8),
          borderWidthThin: 1.0,
          progressHeight: 6.0,
          iconSizeSmall: 24.0,
          iconSizeMedium: 32.0,
          iconSizeLarge: 40.0,
          iconSizeLargePlus: 56.0,
          durationFast: Duration(milliseconds: 300),
          durationMedium: Duration(milliseconds: 600),
          durationSlow: Duration(milliseconds: 900),
          curveStandard: Curves.linear,
          curveEmphasized: Curves.linear,
          curveSymmetric: Curves.linear,
          contentMaxWidthReader: 900,
          contentMaxWidthForm: 700,
          contentMaxWidthMedia: 1400,
          contentMaxWidthSettings: 900,
          narrowCardWidthThreshold: 200.0,
          narrowCardHeightThreshold: 220.0,
          cardTightHeightThreshold: 160.0,
          iconSizeExtraSmall: 18,
          iconSizeExtraLarge: 72,
          textHeightLoose: 2.0,
          playerCollapsedHeight: 120.0,
          playerDismissThreshold: 100.0,
          playerMaxDismissOffset: 250.0,
          playerVelocityThreshold: 600.0,
          playerDismissVelocityThreshold: 400.0,
          playerDragSensitivity: 2.0,
          playerProgressThreshold: 0.6,
          playerIgnorePointerThreshold: 0.5,
          playerAlphaScalingFactor: 3.0,
          stateLayerHover: 0.16,
          stateLayerPressed: 0.20,
          stateLayerFocused: 0.20,
          inkSplashAlpha: 0.08,
          inkHighlightAlpha: 0.04,
          focusRingWidth: 3.0,
          dropdownMenuGap: 6.0,
        );

        final lerped = first.lerp(second, 0.5);
        expect(lerped.spaceExtraSmall, closeTo(6.0, 0.01));
        expect(lerped.radiusSmall, closeTo(12.0, 0.01));
        expect(lerped.opacitySubtle, closeTo(0.15, 0.01));
        expect(lerped.contentMaxWidthReader, closeTo(810, 1.0));
        expect(lerped.iconSizeExtraSmall, closeTo(15.0, 0.01));
        expect(lerped.iconSizeExtraLarge, closeTo(58.0, 0.01));
        expect(lerped.textHeightLoose, closeTo(1.9, 0.01));
      });

      test('interpolates Offset values', () {
        final first = MeMuslimDesignTokens.light();
        const second = MeMuslimDesignTokens(
          spaceTiny: 4.0,
          spaceExtraSmall: 4.0,
          spaceSmall: 8.0,
          spaceMedium: 12.0,
          spaceLarge: 16.0,
          spaceExtraLarge: 24.0,
          spaceSection: 20.0,
          spaceXXL: 32.0,
          spaceHuge: 48.0,
          radiusSmall: 8.0,
          radiusMedium: 12.0,
          radiusLarge: 16.0,
          radiusExtraLarge: 24.0,
          radiusHero: 32.0,
          opacitySubtle: 0.1,
          opacityShadow: 0.18,
          opacityShadowStrong: 0.28,
          opacityMedium: 0.3,
          opacityEmphasis: 0.7,
          opacityGlass: 0.8,
          blurGlass: 12.0,
          blurShadow: 16.0,
          shadowOffsetSmall: Offset(0, 6),
          shadowOffsetMedium: Offset(0, 8),
          borderWidthThin: 0.5,
          progressHeight: 3.0,
          iconSizeSmall: 16.0,
          iconSizeMedium: 20.0,
          iconSizeLarge: 24.0,
          iconSizeLargePlus: 42.0,
          durationFast: Duration(milliseconds: 200),
          durationMedium: Duration(milliseconds: 400),
          durationSlow: Duration(milliseconds: 600),
          curveStandard: Curves.easeOut,
          curveEmphasized: Curves.easeOutCubic,
          curveSymmetric: Curves.easeInOut,
          contentMaxWidthReader: 720,
          contentMaxWidthForm: 560,
          contentMaxWidthMedia: 1200,
          contentMaxWidthSettings: 760,
          narrowCardWidthThreshold: 180.0,
          narrowCardHeightThreshold: 194.0,
          cardTightHeightThreshold: 145.0,
          iconSizeExtraSmall: 12,
          iconSizeExtraLarge: 44,
          textHeightLoose: 1.8,
          playerCollapsedHeight: 100.0,
          playerDismissThreshold: 80.0,
          playerMaxDismissOffset: 200.0,
          playerVelocityThreshold: 500.0,
          playerDismissVelocityThreshold: 300.0,
          playerDragSensitivity: 1.5,
          playerProgressThreshold: 0.5,
          playerIgnorePointerThreshold: 0.4,
          playerAlphaScalingFactor: 2.5,
          stateLayerHover: 0.08,
          stateLayerPressed: 0.12,
          stateLayerFocused: 0.12,
          inkSplashAlpha: 0.08,
          inkHighlightAlpha: 0.04,
          focusRingWidth: 2.0,
          dropdownMenuGap: 4.0,
        );

        final lerped = first.lerp(second, 0.5);
        expect(lerped.shadowOffsetSmall.dy, closeTo(3.5, 0.01));
      });

      test(
        'handles Duration differently (discrete at t<0.5 returns first)',
        () {
          const first = MeMuslimDesignTokens(
            spaceTiny: 4.0,
            spaceExtraSmall: 4.0,
            spaceSmall: 8.0,
            spaceMedium: 12.0,
            spaceLarge: 16.0,
            spaceExtraLarge: 24.0,
            spaceSection: 20.0,
            spaceXXL: 32.0,
            spaceHuge: 48.0,
            radiusSmall: 8.0,
            radiusMedium: 12.0,
            radiusLarge: 16.0,
            radiusExtraLarge: 24.0,
            radiusHero: 32.0,
            opacitySubtle: 0.1,
            opacityShadow: 0.18,
            opacityShadowStrong: 0.28,
            opacityMedium: 0.3,
            opacityEmphasis: 0.7,
            opacityGlass: 0.8,
            blurGlass: 12.0,
            blurShadow: 16.0,
            shadowOffsetSmall: Offset(0, 2),
            shadowOffsetMedium: Offset(0, 4),
            borderWidthThin: 0.5,
            progressHeight: 3.0,
            iconSizeExtraSmall: 12.0,
            iconSizeSmall: 16.0,
            iconSizeMedium: 20.0,
            iconSizeLarge: 24.0,
            iconSizeLargePlus: 42.0,
            iconSizeExtraLarge: 44.0,
            textHeightLoose: 1.8,
            durationFast: Duration(milliseconds: 200),
            durationMedium: Duration(milliseconds: 400),
            durationSlow: Duration(milliseconds: 600),
            curveStandard: Curves.easeOut,
            curveEmphasized: Curves.easeOutCubic,
            curveSymmetric: Curves.easeInOut,
            contentMaxWidthReader: 720,
            contentMaxWidthForm: 560,
            contentMaxWidthMedia: 1200,
            contentMaxWidthSettings: 760,
            narrowCardWidthThreshold: 180.0,
            narrowCardHeightThreshold: 194.0,
            cardTightHeightThreshold: 145.0,
            playerCollapsedHeight: 100.0,
            playerDismissThreshold: 80.0,
            playerMaxDismissOffset: 200.0,
            playerVelocityThreshold: 500.0,
            playerDismissVelocityThreshold: 300.0,
            playerDragSensitivity: 1.5,
            playerProgressThreshold: 0.5,
            playerIgnorePointerThreshold: 0.4,
            playerAlphaScalingFactor: 2.5,
            stateLayerHover: 0.08,
            stateLayerPressed: 0.12,
            stateLayerFocused: 0.12,
            inkSplashAlpha: 0.08,
            inkHighlightAlpha: 0.04,
            focusRingWidth: 2.0,
            dropdownMenuGap: 4.0,
          );
          const second = MeMuslimDesignTokens(
            spaceTiny: 4.0,
            spaceExtraSmall: 8.0,
            spaceSmall: 16.0,
            spaceMedium: 24.0,
            spaceLarge: 32.0,
            spaceExtraLarge: 48.0,
            spaceSection: 40.0,
            spaceXXL: 64.0,
            spaceHuge: 96.0,
            radiusSmall: 16.0,
            radiusMedium: 24.0,
            radiusLarge: 32.0,
            radiusExtraLarge: 48.0,
            radiusHero: 64.0,
            opacitySubtle: 0.2,
            opacityShadow: 0.3,
            opacityShadowStrong: 0.45,
            opacityMedium: 0.6,
            opacityEmphasis: 0.9,
            opacityGlass: 0.9,
            blurGlass: 20.0,
            blurShadow: 24.0,
            shadowOffsetSmall: Offset(0, 4),
            shadowOffsetMedium: Offset(0, 8),
            borderWidthThin: 1.0,
            progressHeight: 6.0,
            iconSizeExtraSmall: 24.0,
            iconSizeSmall: 24.0,
            iconSizeMedium: 32.0,
            iconSizeLarge: 40.0,
            iconSizeLargePlus: 56.0,
            iconSizeExtraLarge: 96.0,
            textHeightLoose: 2.0,
            durationFast: Duration(milliseconds: 300),
            durationMedium: Duration(milliseconds: 600),
            durationSlow: Duration(milliseconds: 900),
            curveStandard: Curves.linear,
            curveEmphasized: Curves.linear,
            curveSymmetric: Curves.linear,
            contentMaxWidthReader: 900,
            contentMaxWidthForm: 700,
            contentMaxWidthMedia: 1400,
            contentMaxWidthSettings: 900,
            narrowCardWidthThreshold: 200.0,
            narrowCardHeightThreshold: 220.0,
            cardTightHeightThreshold: 160.0,
            playerCollapsedHeight: 120.0,
            playerDismissThreshold: 100.0,
            playerMaxDismissOffset: 250.0,
            playerVelocityThreshold: 600.0,
            playerDismissVelocityThreshold: 400.0,
            playerDragSensitivity: 2.0,
            playerProgressThreshold: 0.6,
            playerIgnorePointerThreshold: 0.5,
            playerAlphaScalingFactor: 3.0,
            stateLayerHover: 0.16,
            stateLayerPressed: 0.20,
            stateLayerFocused: 0.20,
            inkSplashAlpha: 0.08,
            inkHighlightAlpha: 0.04,
            focusRingWidth: 3.0,
            dropdownMenuGap: 6.0,
          );

          final lerped = first.lerp(second, 0.3);
          expect(lerped.durationFast, const Duration(milliseconds: 200));
          expect(lerped.curveStandard, Curves.easeOut);
          expect(lerped.curveEmphasized, Curves.easeOutCubic);
        },
      );

      test('returns self when other is not MeMuslimDesignTokens', () {
        final tokens = MeMuslimDesignTokens.light();
        final result = tokens.lerp(null, 0.5);
        expect(result.spaceExtraSmall, tokens.spaceExtraSmall);
      });
    });

    group('MeMuslimDesignTokensX extension', () {
      testWidgets('can access tokens from ThemeData', (
        WidgetTester tester,
      ) async {
        final tokens = MeMuslimDesignTokens.light();
        final theme = ThemeData(extensions: [tokens]);

        await tester.pumpWidget(
          MaterialApp(
            theme: theme,
            home: Builder(
              builder: (context) {
                final accessedTokens = Theme.of(context).tokens;
                expect(accessedTokens.spaceSmall, 8.0);
                expect(accessedTokens.radiusSmall, 8.0);
                return const SizedBox.shrink();
              },
            ),
          ),
        );
      });
    });

    group('MeMuslimIconSizeX extension', () {
      testWidgets('exposes icon size steps including largePlus', (
        WidgetTester tester,
      ) async {
        final tokens = MeMuslimDesignTokens.light();
        final theme = ThemeData(extensions: [tokens]);

        await tester.pumpWidget(
          MaterialApp(
            theme: theme,
            home: Builder(
              builder: (context) {
                expect(context.iconSizeExtraLarge, 44.0);
                expect(context.iconSizeLargePlus, 42.0);
                expect(
                  context.minInteractiveDimension,
                  kMeMuslimMinInteractiveDimension,
                );
                return const SizedBox.shrink();
              },
            ),
          ),
        );
      });
    });

    group('lerpDouble helper', () {
      test('properly interpolates double values', () {
        final tokens = MeMuslimDesignTokens.light();
        final lerped = tokens.lerpDouble(4.0, 8.0, 0.5);
        expect(lerped, 6.0);
      });

      test('handles null values by treating as 0', () {
        final tokens = MeMuslimDesignTokens.light();
        final result1 = tokens.lerpDouble(null, 10.0, 0.5);
        expect(result1, 5.0);

        final result2 = tokens.lerpDouble(10.0, null, 0.5);
        expect(result2, 5.0);
      });

      test('handles both null values', () {
        final tokens = MeMuslimDesignTokens.light();
        final result = tokens.lerpDouble(null, null, 0.5);
        expect(result, isNull);
      });
    });

    group('MeMuslimRadiusResolverX', () {
      test('semantic radius aliases map to token caps', () {
        final tokens = MeMuslimDesignTokens.light();
        expect(tokens.radiusCard, 24.0);
        expect(tokens.radiusSection, 24.0);
        expect(tokens.radiusPill(48), 24.0);
        expect(tokens.radiusIcon(44), 22.0);
      });

      test('resolveRadius returns fixed family tokens', () {
        final tokens = MeMuslimDesignTokens.light();
        expect(
          tokens.resolveRadius(family: TilawaRadiusFamily.card),
          12.0,
        );
        expect(
          tokens.resolveRadius(family: TilawaRadiusFamily.pill),
          24.0,
        );
        expect(
          tokens.resolveRadius(family: TilawaRadiusFamily.chrome),
          12.0,
        );
        expect(
          tokens.resolveRadius(family: TilawaRadiusFamily.section),
          12.0,
        );
        expect(
          tokens.resolveRadius(family: TilawaRadiusFamily.hero),
          20.0,
        );
        expect(
          tokens.resolveRadius(family: TilawaRadiusFamily.decorative),
          12.0,
        );
        expect(
          tokens.resolveRadius(
            family: TilawaRadiusFamily.icon,
            width: 40,
            height: 40,
          ),
          20.0,
        );
        expect(
          tokens.resolveRadius(family: TilawaRadiusFamily.chip),
          8.0,
        );
        expect(
          tokens.resolveRadius(family: TilawaRadiusFamily.selection),
          12.0,
        );
      });

      test('resolveRadius uses height for pill affordances', () {
        final tokens = MeMuslimDesignTokens.light();
        expect(
          tokens.resolveRadius(
            family: TilawaRadiusFamily.pill,
            height: 44,
          ),
          22.0,
        );
        expect(
          tokens.resolveRadius(
            family: TilawaRadiusFamily.pill,
            height: 32,
          ),
          16.0,
        );
      });

      test('buttonBorderRadius and buttonShape use pill family', () {
        final tokens = MeMuslimDesignTokens.light();
        expect(tokens.buttonBorderRadius(), 24.0);
        expect(tokens.buttonBorderRadius(height: 56), 28.0);
        expect(
          tokens.buttonShape(height: 48).borderRadius,
          BorderRadius.circular(24),
        );
      });

      test('materialButtonStyle applies pill shape and min touch target', () {
        final tokens = MeMuslimDesignTokens.light();
        final style = tokens.materialButtonStyle();
        final shape = style.shape!.resolve(const {})! as RoundedRectangleBorder;
        final size = style.minimumSize!.resolve(const {});

        expect(shape.borderRadius, BorderRadius.circular(24));
        expect(size, const Size(48, 48));
      });

      test('resolveSegmentedControlRadii uses chrome track by default', () {
        final tokens = MeMuslimDesignTokens.light();
        final radii = tokens.resolveSegmentedControlRadii(
          itemHeight: 32,
          containerPadding: 4,
        );
        expect(radii.containerRadius, 12.0);
        expect(radii.itemRadius, 8.0);
      });

      test(
        'resolveSegmentedControlRadii uses pill track height when requested',
        () {
          final tokens = MeMuslimDesignTokens.light();
          final radii = tokens.resolveSegmentedControlRadii(
            itemHeight: 32,
            containerPadding: 4,
            trackFamily: TilawaRadiusFamily.pill,
          );
          expect(radii.containerRadius, 20.0);
          expect(radii.itemRadius, 16.0);
        },
      );
    });
  });
}
