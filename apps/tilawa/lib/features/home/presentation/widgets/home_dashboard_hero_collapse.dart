import 'package:flutter/material.dart';
import 'package:tilawa/features/home/presentation/widgets/home_hero_photo_theme.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

/// Collapse progress for home hero [SliverPersistentHeaderDelegate]s.
///
/// Returns `1` when fully expanded and `0` when pinned at [minExtent].
double homeDashboardHeroCollapseProgress({
  required double shrinkOffset,
  required double maxExtent,
  required double minExtent,
}) {
  final double range = maxExtent - minExtent;
  if (range <= 0) {
    return 0;
  }
  return (1 - (shrinkOffset / range)).clamp(0.0, 1.0);
}

/// Scroll distance where the hero transitions from expanded to pinned.
double homeDashboardHeroCollapseScrollExtent({
  required double maxExtent,
  required double minExtent,
}) {
  return maxExtent - minExtent;
}

/// Pinned hero height: status-bar inset plus compact toolbar.
double homeDashboardHeroPinnedExtent({required double topInset}) {
  return topInset + kToolbarHeight;
}

/// Pinned bar sample — canvas wash luminance for status-bar icons.
Color homeDashboardHeroCollapsedBarColor(
  TilawaHomeScreenTokens screenTokens,
) {
  return HomeHeroPhotoTheme.collapsedBarSampleColor(screenTokens);
}
