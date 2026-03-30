import 'dart:async';

/// Repository responsible for managing Quran fonts.
abstract class QuranFontRepository {
  /// Checks if all fonts are already downloaded.
  Future<bool> areFontsDownloaded();

  /// Downloads the font zip, extracts it, and saves it locally.
  Future<void> downloadFonts({void Function(double)? onProgress});

  /// Registers the initial reading window fonts immediately, then continues
  /// warming the remaining page fonts in the background.
  Future<void> loadFontsToEngine({required int initialPageNumber});

  /// Returns true if fonts have already been loaded to engine in this session.
  bool get hasLoadedFontsToEngine;
}
