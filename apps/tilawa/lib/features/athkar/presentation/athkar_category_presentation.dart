import 'package:flutter/material.dart';
import 'package:tilawa/core/extensions.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import '../domain/entities/athkar_category.dart';

String localizedAthkarCategoryTitle(
  BuildContext context,
  AthkarCategory category,
) {
  if (context.isArabic) return category.nameAr;
  final String english = category.nameEn.trim();
  return english.isNotEmpty ? english : category.nameAr;
}

IconData athkarCategoryIcon(String iconName) {
  switch (iconName) {
    case 'wb_sunny_rounded':
      return Icons.wb_sunny_rounded;
    case 'nights_stay_rounded':
      return Icons.nights_stay_rounded;
    case 'bedtime_rounded':
      return Icons.bedtime_rounded;
    case 'alarm_rounded':
      return Icons.alarm_rounded;
    case 'mosque_rounded':
      return Icons.mosque_rounded;
    case 'auto_stories_rounded':
      return Icons.auto_stories_rounded;
    case 'prayer_times_rounded':
      return Icons.auto_awesome_rounded;
    case 'tasbeeh':
      return Icons.radio_button_checked_rounded;
    default:
      return Icons.bookmark_added_rounded;
  }
}

/// Soft card wash alpha for Athkar category tiles (Behance-style pastel).
const double kAthkarCategorySurfaceTintAlpha = 0.14;

/// Icon-well wash — slightly stronger than [kAthkarCategorySurfaceTintAlpha].
const double kAthkarCategoryIconWellTintAlpha = 0.22;

/// Category accent from known Athkar icon keys — product colors only.
Color athkarCategoryAccent(
  String iconName, {
  required MeMuslimProductColors product,
  required ColorScheme colorScheme,
}) {
  return switch (iconName) {
    // Morning — warm amber (sunrise).
    'wb_sunny_rounded' => product.exploreFeatureIcon(HomeExploreFeature.quran),
    // Evening — indigo dusk.
    'nights_stay_rounded' => product.exploreFeatureIcon(
      HomeExploreFeature.bookmarks,
    ),
    // Sleep — quiet blue-grey night.
    'bedtime_rounded' => product.info,
    // Wake — clear blue.
    'alarm_rounded' => product.exploreFeatureIcon(HomeExploreFeature.qibla),
    // After prayer — brand-adjacent green.
    'mosque_rounded' => product.exploreFeatureIcon(HomeExploreFeature.reciters),
    // Miscellaneous — soft teal.
    'auto_stories_rounded' => product.exploreFeatureIcon(
      HomeExploreFeature.support,
    ),
    'prayer_times_rounded' => colorScheme.primary,
    'tasbeeh' => product.featuredGradientEnd,
    _ => colorScheme.primary,
  };
}

Color athkarCategorySurfaceWash({
  required Color accent,
  required ColorScheme colorScheme,
}) {
  return Color.alphaBlend(
    accent.withValues(alpha: kAthkarCategorySurfaceTintAlpha),
    colorScheme.surface,
  );
}
