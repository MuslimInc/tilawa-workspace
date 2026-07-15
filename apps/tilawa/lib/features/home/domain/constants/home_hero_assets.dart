import 'package:flutter/material.dart';

/// Bundled artwork retained for Qibla / legacy hero experiments.
///
/// The Home next-prayer card uses period [HomeHeroBackground] gradients —
/// not [wallpaper] — so busy photographs do not fight calm dashboard chrome.
abstract final class HomeHeroAssets {
  const HomeHeroAssets._();

  /// Historical masjid photograph — unused by the current Home prayer card.
  static const String wallpaper = 'assets/images/mecca.jpg';

  /// Focal point for [wallpaper] if an image surface is reintroduced.
  static Alignment wallpaperFocalAlignment(TextDirection direction) {
    final double x = direction == TextDirection.rtl ? 0.82 : -0.82;
    return Alignment(x, -0.76);
  }
}
