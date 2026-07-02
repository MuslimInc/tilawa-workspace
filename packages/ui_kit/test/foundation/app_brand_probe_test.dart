import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

void main() {
  group('AppBrandProbe', () {
    test(
      'brand action green passes ink onPrimary contrast',
      () {
        final ratio = _contrastRatio(
          AppColors.lightSchemeOnPrimary,
          AppColors.brandActionGreen,
        );
        expect(
          ratio,
          greaterThanOrEqualTo(4.5),
          reason: 'ink onPrimary on #1DAB61 (${ratio.toStringAsFixed(2)}:1)',
        );
      },
    );

    test(
      'dark brand primary passes ink onPrimary contrast',
      () {
        final ratio = _contrastRatio(
          AppColors.lightSchemeOnPrimary,
          AppColors.darkDefaultPrimary,
        );
        expect(
          ratio,
          greaterThanOrEqualTo(4.5),
          reason: 'ink onPrimary on #6BC992 (${ratio.toStringAsFixed(2)}:1)',
        );
      },
    );

    test('production default primary is brand action green', () {
      expect(AppColors.defaultPrimary, AppColors.brandActionGreen);
      expect(AppBrandProbe.actionGreen, AppColors.brandActionGreen);
    });

    test('default primary uses brand-locked scheme roles', () {
      final scheme = AppTheme.getLightTheme(
        primaryColor: AppColors.defaultPrimary,
      ).colorScheme;

      expect(scheme.primary, AppColors.brandActionGreen);
      expect(scheme.onPrimary, AppColors.lightSchemeOnPrimary);
    });

    test('home dashboard accents align with brand action green', () {
      expect(AppColors.homeDashboardAccent, AppColors.brandActionGreen);
      expect(AppColors.homePrayerHeroAccent, AppColors.brandActionGreen);
      expect(AppColors.homeHeroPatternInk, AppColors.brandActionGreen);
      expect(AppColors.homeTravelSectionLink, AppColors.brandActionGreen);
      expect(AppColors.homeTravelDestinationIcon, AppColors.brandActionGreen);
    });

    test('featured tutor CTA accent aligns with global primary green', () {
      expect(AppColors.homeFeaturedTutorAccent, AppColors.brandActionGreen);
      expect(
        AppColors.homeFeaturedTutorAccentDark,
        AppColors.darkDefaultPrimary,
      );
    });

    test('home dark accents use lifted brand green', () {
      expect(AppColors.homeDashboardAccentDark, AppColors.darkDefaultPrimary);
      expect(AppColors.homePrayerHeroAccentDark, AppColors.darkDefaultPrimary);
      expect(AppColors.homeHeroPatternInkDark, AppColors.darkDefaultPrimary);
    });

    test('launch splash is brand splash green', () {
      expect(AppColors.launchSplashBackground, AppColors.brandSplashGreen);
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
