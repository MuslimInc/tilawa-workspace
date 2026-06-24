import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa_ui_kit/src/foundation/foundation.dart';

void main() {
  group('HomeExploreFeatureTileStyles', () {
    late ColorScheme lightScheme;

    setUp(() {
      lightScheme = AppTheme.getLightTheme(
        primaryColor: AppColors.defaultPrimary,
      ).colorScheme;
    });

    test('every feature resolves a distinct icon color', () {
      final iconColors = <Color>{
        for (final feature in HomeExploreFeature.values)
          lightScheme.homeExploreFeatureTileStyle(feature).iconForeground,
      };

      expect(
        iconColors.length,
        HomeExploreFeature.values.length,
        reason: 'each explore tile needs a unique glyph color',
      );
    });

    test('all tiles share warm manuscript cream background', () {
      expect(
        lightScheme.homeExploreTileBackground,
        isNot(equals(lightScheme.surface)),
        reason: 'cream fill should be warmer than plain white card',
      );
      expect(
        lightScheme.homeExploreTileBackground,
        equals(
          AppTheme.getLightTheme(
            primaryColor: AppColors.defaultPrimary,
          ).colorScheme.homeExploreTileBackground,
        ),
      );
    });

    test('quran icon uses ceremonial gold distinct from tasbeeh', () {
      final Color quranIcon = lightScheme
          .homeExploreFeatureTileStyle(HomeExploreFeature.quran)
          .iconForeground;
      final Color tasbeehIcon = lightScheme
          .homeExploreFeatureTileStyle(HomeExploreFeature.tasbeeh)
          .iconForeground;

      expect(quranIcon, isNot(equals(tasbeehIcon)));
    });

    test('reciters icon uses scholarly sage green', () {
      expect(
        lightScheme
            .homeExploreFeatureTileStyle(HomeExploreFeature.reciters)
            .iconForeground,
        AppColors.primarySage,
      );
    });
  });
}
