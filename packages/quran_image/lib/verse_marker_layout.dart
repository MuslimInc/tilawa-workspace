/// Layout math for verse-end marker ornaments over the line image stack.
///
/// Horizontal placement must use the **same width** as the painted overlay
/// ([LayoutBuilder] / [Stack]) so markers stay aligned on every device width.
class VerseMarkerLayout {
  const VerseMarkerLayout._();

  /// Ornament width as a fraction of page/overlay width (Ayah reference).
  static const double markerWidthRatio = 0.05138889;

  /// Ornament height as a fraction of page/overlay width.
  static const double markerHeightRatio = 0.06527778;

  static double markerWidth(double layoutWidth) =>
      layoutWidth * markerWidthRatio;

  static double markerHeight(double layoutWidth) =>
      layoutWidth * markerHeightRatio;

  /// Left offset of the marker for JSON [centerX] in `[0, 1]` and overlay
  /// width [layoutWidth].
  static double markerLeftOffset({
    required double centerX,
    required double layoutWidth,
  }) {
    final double mw = markerWidth(layoutWidth);
    return (centerX * layoutWidth - mw / 2).clamp(
      0.0,
      layoutWidth - mw,
    );
  }

  /// Horizontal center of the marker after [markerLeftOffset] clamping.
  static double markerCenterXAfterLayout({
    required double centerX,
    required double layoutWidth,
  }) {
    final double mw = markerWidth(layoutWidth);
    return markerLeftOffset(
          centerX: centerX,
          layoutWidth: layoutWidth,
        ) +
        mw / 2;
  }
}
