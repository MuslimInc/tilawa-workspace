import 'package:flutter/material.dart';

/// Bundled artwork for the home dashboard hero persistent header.
abstract final class HomeHeroAssets {
  const HomeHeroAssets._();

  /// Masjid arch lattice photograph — cropped to sky and stone, not the courtyard.
  static const String wallpaper = 'assets/images/mecca.jpg';

  /// Focal point for [wallpaper]: architectural detail on the visual-left edge,
  /// prayer copy on the visual-right (start in RTL).
  ///
  /// Vertical bias favors stone lattice over open sky; excludes courtyard crowds.
  static Alignment wallpaperFocalAlignment(TextDirection direction) {
    final double x = direction == TextDirection.rtl ? 0.82 : -0.82;
    return Alignment(x, -0.76);
  }
}
