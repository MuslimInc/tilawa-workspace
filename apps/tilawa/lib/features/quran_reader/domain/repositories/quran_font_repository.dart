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

  /// Ensures the current page window is ready before a programmatic jump.
  Future<void> ensureFontsForPageWindow({required int pageNumber});

  /// Temporarily reduces background registration pressure during heavy UI work.
  void pauseBackgroundWarmUp();

  /// Resumes any background warm-up that was paused for foreground work.
  void resumeBackgroundWarmUp();

  /// Returns true if fonts have already been loaded to engine in this session.
  bool get hasLoadedFontsToEngine;

  /// Ensures the Quran page/word data (JSON) is fully loaded before rendering.
  Future<void> ensureQuranDataLoaded();

  /// Loads only the font for [pageNumber] with no neighbor side effects.
  Future<void> ensureSingleFontLoaded(int pageNumber);

  /// Returns true if the font for [pageNumber] is already loaded in the engine.
  bool isFontLoaded(int pageNumber);

  /// Informs the service of the user's current page to prioritize font registration.
  void updateCurrentPage(int pageNumber);

  /// Pre-warms the glyph atlas for [pageNumber].
  /// Must be called after both [loadFontsToEngine] and [ensureQuranDataLoaded].
  Future<void> warmInitialPage(int pageNumber);

  /// Performs a sequential, low-impact warming of all 604 pages.
  /// Reports progress as the current page number being warmed.
  Future<void> batchWarmPages(
    int start,
    int end,
    Future<void> Function(int) onProgress, {
    int? pivotPage,
  });
}
