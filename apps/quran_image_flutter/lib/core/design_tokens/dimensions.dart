/// Design tokens for spacing, sizing, and layout.
/// 
/// All dimensions are defined as ratios relative to screen dimensions
/// to ensure responsive behavior across different device sizes.
class AppDimensions {
  // Prevent instantiation
  AppDimensions._();

  /// Screen dimension ratios
  static const double designWidth = 1344.0;
  static const double designHeight = 2992.0;

  /// Navigation slider dimensions
  static const double sliderHeightRatio = 0.08; // 8% of screen height
  static const double sliderHorizontalPaddingRatio = 0.04; // 4% of screen width
  static const double sliderBottomMarginRatio = 0.02; // 2% of screen height
  static const double sliderBorderRadiusRatio = 0.02; // 2% of screen width

  /// Slider thumb dimensions
  static const double thumbSizeRatio = 0.04; // 4% of screen width
  static const double thumbBorderWidth = 2.0;

  /// Button sizes
  static const double iconButtonSizeRatio = 0.08; // 8% of screen width
  static const double iconSizeRatio = 0.04; // 4% of screen width

  /// Text sizes (as ratio of screen width)
  static const double pageNumberTextSizeRatio = 0.04; // 4% of screen width
  static const double verseNumberTextSizeRatio = 0.025; // 2.5% of screen width

  /// Marker dimensions
  static const double markerWidthRatio = 68.0 / 1344.0; // ~0.0506
  static const double markerHeightRatio = 87.0 / 1344.0; // ~0.0647

  /// Line height ratio (from Ayah app spec)
  static const double lineHeightRatio = 174.0 / 1080.0;

  /// Page count
  static const int totalPages = 604;
  static const int linesPerPage = 15;
}
