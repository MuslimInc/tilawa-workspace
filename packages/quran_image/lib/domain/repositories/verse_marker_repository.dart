import '../entities/verse_marker_data.dart';

/// Repository interface for accessing Quran verse markers.
///
/// The domain layer depends on this abstraction. Concrete implementations
/// (e.g. loading from bundled JSON assets) live in the data layer.
abstract class VerseMarkerRepository {
  /// Returns all verse-end markers for [pageNumber] (1-604).
  ///
  /// Returns an empty list if no markers are available yet.
  /// This method is synchronous and reads from an internal cache.
  List<VerseMarkerData> getMarkersForPage(int pageNumber);

  /// Asynchronously loads and returns markers for [pageNumber].
  ///
  /// Useful when the data may not yet be cached (e.g. debug mode
  /// without full preloading).
  Future<List<VerseMarkerData>> getMarkersForPageAsync(int pageNumber);

  /// Current preload progress in `[0.0, 1.0]`.
  double get preloadProgress;

  /// Whether a background preload is currently in progress.
  bool get isPreloading;

  /// Whether all pages have been preloaded into the cache.
  bool get isPreloaded;

  /// Whether the repository is using per-page debug files.
  bool get isDebugMode;

  /// Releases resources held by this repository.
  void dispose();
}
