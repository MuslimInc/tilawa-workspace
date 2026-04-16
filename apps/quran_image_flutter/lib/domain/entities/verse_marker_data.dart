/// Data source type for marker coordinates.
enum MarkerDataSource {
  /// Production: Single JSON file with all pages.
  production,

  /// Debug: Individual JSON files per page for precise debugging.
  debug,
}

/// Represents the position of a verse-end marker on a Quran page.
///
/// Coordinates are normalised to the page's logical dimensions:
///   - [line] is a 0-based index into the 15-slot line grid.
///   - [centerX] is in `[0.0, 1.0]` from the left page edge.
class VerseMarkerData {
  /// Surah number (1-114).
  final int sura;

  /// Ayah number within the surah.
  final int ayah;

  /// 0-based index into the 15-slot line grid.
  ///
  /// Maps to the yOffsets formula: `yCenter = yOffsets[line] + lineHeight / 2`.
  final int line;

  /// Normalised X in `[0.0, 1.0]` from the left page edge.
  ///
  /// Derived from gap-centre (multi-verse lines) or text_left offset
  /// (single-verse lines).
  final double centerX;

  const VerseMarkerData({
    required this.sura,
    required this.ayah,
    required this.line,
    required this.centerX,
  });
}
