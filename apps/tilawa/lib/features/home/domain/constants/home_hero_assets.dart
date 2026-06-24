import 'package:flutter/material.dart';

/// Bundled artwork for the home dashboard hero persistent header.
abstract final class HomeHeroAssets {
  const HomeHeroAssets._();

  /// Kaaba courtyard photograph framed through a masjid arch.
  static const String wallpaper = 'assets/images/home_hero_wallpaper.png';

  /// Frames the Kaaba through the arch with breathing room for greeting text.
  static const Alignment wallpaperAlignment = Alignment(0, 0.38);
}
