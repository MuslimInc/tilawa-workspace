/// Animation and timing constants for the application.
/// 
/// All durations are defined in milliseconds for consistency.
class AppDurations {
  // Prevent instantiation
  AppDurations._();

  /// Navigation slider visibility animations
  static const int sliderShowHide = 300;
  static const int sliderFadeIn = 250;
  static const int sliderFadeOut = 350;

  /// Auto-hide timer duration in seconds
  static const int sliderAutoHideSeconds = 3;

  /// Page navigation animations
  static const int pageTransition = 300;
  static const int pageScroll = 500;

  /// Interaction debounce
  static const int interactionDebounce = 50;

  /// Long press duration
  static const int longPress = 500;

  /// Double tap gap
  static const int doubleTapGap = 300;
}
