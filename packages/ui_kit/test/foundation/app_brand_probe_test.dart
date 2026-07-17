import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

void main() {
  group('AppBrandProbe', () {
    test(
      'brand action orange passes decorative onPrimary contrast',
      () {
        final ratio = _contrastRatio(
          AppColors.lightSchemeOnPrimary,
          AppColors.brandActionOrange,
        );
        expect(
          ratio,
          greaterThanOrEqualTo(2.9),
          reason:
              'white onPrimary on #FA5B2E (${ratio.toStringAsFixed(2)}:1) — '
              'large UI / brand accent',
        );
      },
    );

    test(
      'brand action orange accessible passes solid CTA contrast',
      () {
        final ratio = _contrastRatio(
          AppColors.lightSchemeOnPrimary,
          AppColors.brandActionOrangeAccessible,
        );
        expect(
          ratio,
          greaterThanOrEqualTo(4.5),
          reason:
              'white on #C2410C (${ratio.toStringAsFixed(2)}:1) — filled buttons',
        );
      },
    );

    test(
      'dark brand primary passes onPrimary contrast',
      () {
        final scheme = AppTheme.getDarkTheme(
          primaryColor: AppColors.defaultPrimary,
          isDefaultPreset: true,
        ).colorScheme;
        final ratio = _contrastRatio(scheme.onPrimary, scheme.primary);
        expect(
          ratio,
          greaterThanOrEqualTo(4.5),
          reason: 'dark onPrimary on #FF8A65 (${ratio.toStringAsFixed(2)}:1)',
        );
      },
    );

    test('production default primary is brand action orange', () {
      expect(AppColors.defaultPrimary, AppColors.brandActionOrange);
      expect(AppBrandProbe.actionOrange, AppColors.brandActionOrange);
      expect(AppBrandProbe.actionGreen, AppColors.brandActionOrange);
    });

    test('default primary uses brand-locked scheme roles', () {
      final scheme = AppTheme.getLightTheme(
        primaryColor: AppColors.defaultPrimary,
      ).colorScheme;

      expect(scheme.primary, AppColors.brandActionOrange);
      expect(scheme.onPrimary, AppColors.lightSchemeOnPrimary);
    });

    test('home dashboard accents align with brand action orange', () {
      expect(AppColors.homeDashboardAccent, AppColors.brandActionOrange);
      expect(AppColors.homePrayerHeroAccent, AppColors.brandActionOrange);
      expect(AppColors.homeHeroPatternInk, AppColors.brandActionOrange);
      expect(AppColors.homeTravelSectionLink, AppColors.brandActionOrange);
      expect(AppColors.homeTravelDestinationIcon, AppColors.brandActionOrange);
    });

    test('featured tutor CTA accent aligns with global primary orange', () {
      expect(AppColors.homeFeaturedTutorAccent, AppColors.brandActionOrange);
      expect(
        AppColors.homeFeaturedTutorAccentDark,
        AppColors.darkDefaultPrimary,
      );
    });

    test('home dark accents use lifted brand orange', () {
      expect(AppColors.homeDashboardAccentDark, AppColors.darkDefaultPrimary);
      expect(AppColors.homePrayerHeroAccentDark, AppColors.darkDefaultPrimary);
      expect(AppColors.homeHeroPatternInkDark, AppColors.darkDefaultPrimary);
    });

    test('launch splash is brand splash orange', () {
      expect(AppColors.launchSplashBackground, AppColors.brandSplashOrange);
    });
  });
}

double _contrastRatio(Color a, Color b) {
  final luminanceA = a.computeLuminance();
  final luminanceB = b.computeLuminance();
  final lighter = math.max(luminanceA, luminanceB);
  final darker = math.min(luminanceA, luminanceB);

  return (lighter + 0.05) / (darker + 0.05);
}
