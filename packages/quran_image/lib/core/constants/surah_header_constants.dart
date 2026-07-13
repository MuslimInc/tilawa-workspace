/// Centralised constants for calculating dimensions and scaling for the
/// Surah header banners within a Quran page overlay.
///
/// These values represent mathematical derivations, usually via
/// linear regression based on the difference between standard layout width and
/// device pixel widths to maintain parity with reference applications.
class SurahHeaderConstants {
  SurahHeaderConstants._();

  /// Number of line slots used by each Quran page image layout.
  static const int lineCount = 15;

  /// Last valid zero-based line slot.
  static const int lastLineIndex = lineCount - 1;

  /// Reference line image height used by the Ayah page layout formula.
  static const double lineHeightReferencePixels = 174;

  /// Reference line image width used by the Ayah page layout formula.
  static const double lineHeightReferenceWidth = 1080;

  /// Aspect ratio constraint inherently mapping to the Surah header asset.
  static const double bannerHeightToWidthRatio = 0.11228293967474158;

  /// The static multiplier for portrait layouts at base resolutions.
  static const double portraitWidthRatioBase = 0.97354259;

  /// Modifying slope applied to device aspect ratio factor.
  static const double portraitWidthRatioAspectSlope = -0.015786;

  /// Modifying slope applied dynamically against device viewport width.
  static const double portraitWidthRatioViewportSlope = -0.0000049331266667;

  /// Normalised vertical target point (Y-axis distance fraction) from the banner bounding box.
  static const double targetInkCenterYFraction = 0.509;

  /// The fallback value normally used if no custom fraction matches a surah index.
  static const double defaultInkCenterYFraction = 0.5;

  /// Minimum allowed banner width ratio.
  static const double minWidthRatio = 0.0;

  /// Maximum allowed banner width ratio.
  static const double maxWidthRatio = 1.0;
}
