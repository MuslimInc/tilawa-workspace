/// Narrow-width thresholds for Prayer Times presentation layout.
///
/// [TilawaWindowSize.narrow] spans all phones (< 600dp); this flag splits
/// typical small phones (~360dp logical) from larger handsets in portrait.
class PrayerTimesLayout {
  const PrayerTimesLayout._();

  /// Max width for the **content** box (e.g. [LayoutBuilder] constraints),
  /// below which stacked layouts apply.
  static const double narrowContentWidth = 400;

  static bool isNarrowWidth(double maxWidth) =>
      maxWidth > 0 && maxWidth < narrowContentWidth;
}
