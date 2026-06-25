import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

void main() {
  group('MeMuslimProductColors', () {
    test('light and dark themes register the extension', () {
      final ThemeData light = AppTheme.getLightTheme(
        primaryColor: AppColors.defaultPrimary,
      );
      final ThemeData dark = AppTheme.getDarkTheme(
        primaryColor: AppColors.defaultPrimary,
        isDefaultPreset: true,
      );

      expect(light.extension<MeMuslimProductColors>(), isNotNull);
      expect(dark.extension<MeMuslimProductColors>(), isNotNull);
      expect(light.productColors, isA<MeMuslimProductColors>());
    });

    test('prayer roles track ColorScheme primary in light mode', () {
      final ColorScheme scheme = AppTheme.getLightTheme(
        primaryColor: AppColors.defaultPrimary,
      ).colorScheme;
      final MeMuslimProductColors product = MeMuslimProductColors.light(scheme);

      expect(product.prayerTimeActive, scheme.primary);
      expect(product.prayerTimeNextSurface, scheme.primaryContainer);
    });

    test('quran reader roles use legacy mushaf palette', () {
      final MeMuslimProductColors light = MeMuslimProductColors.light(
        AppTheme.getLightTheme(
          primaryColor: AppColors.defaultPrimary,
        ).colorScheme,
      );
      final MeMuslimProductColors dark = MeMuslimProductColors.dark(
        AppTheme.getDarkTheme(
          primaryColor: AppColors.defaultPrimary,
          isDefaultPreset: true,
        ).colorScheme,
      );

      expect(
        light.quranPageBackground,
        AppQuranReaderLegacyColors.lightPageBackground,
      );
      expect(
        dark.quranPageBackground,
        AppQuranReaderLegacyColors.darkPageBackground,
      );
    });

    test('explore hub icons stay distinct per feature', () {
      final MeMuslimProductColors product = MeMuslimProductColors.light(
        AppTheme.getLightTheme(
          primaryColor: AppColors.defaultPrimary,
        ).colorScheme,
      );
      final Set<Color> icons = {
        for (final feature in HomeExploreFeature.values)
          product.exploreFeatureIcon(feature),
      };

      expect(icons.length, HomeExploreFeature.values.length);
    });

    test(
      'brand lock stays on default primary when scheme uses custom accent',
      () {
        const Color customPrimary = Color(0xFF7A5C89);
        final ColorScheme scheme = AppTheme.getLightTheme(
          primaryColor: customPrimary,
        ).colorScheme;
        final MeMuslimProductColors product = MeMuslimProductColors.light(
          scheme,
        );

        expect(product.brandLockedPrimary, AppColors.defaultPrimary);
        expect(scheme.primary, customPrimary);
      },
    );
  });
}
