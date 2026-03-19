import 'dart:async';

/// Repository responsible for managing Quran fonts.
abstract class QuranFontRepository {
  /// Checks if all fonts are already downloaded.
  Future<bool> areFontsDownloaded();

  /// Downloads the font zip, extracts it, and saves it locally.
  Future<void> downloadFonts({void Function(double)? onProgress});

  /// Registers the fonts with the Flutter engine.
  Future<void> loadFontsToEngine();

  /// Returns true if fonts have already been loaded to engine in this session.
  bool get hasLoadedFontsToEngine;
}
