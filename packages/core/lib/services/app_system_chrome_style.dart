import 'package:flutter/services.dart';

/// Centralized System UI styles for the app.
///
/// Default behavior:
/// - All screens use [defaultAppStyle].
/// - Quran Reader can use [quranReaderStyle] as a screen-specific override.
///
/// Keep this class small. Do not add screen-specific styles unless the screen
/// has a real visual/system UI requirement.
final class AppSystemChromeStyle {
  const AppSystemChromeStyle._();

  static SystemUiOverlayStyle _defaultAppStyle = const SystemUiOverlayStyle(
    statusBarColor: Color(0x00000000),
    systemNavigationBarColor: Color(0x00000000),
    systemNavigationBarDividerColor: Color(0x00000000),
    systemStatusBarContrastEnforced: false,
    systemNavigationBarContrastEnforced: false,
  );
  static SystemUiOverlayStyle _quranReaderStyle = const SystemUiOverlayStyle(
    statusBarColor: Color(0x00000000),
    systemNavigationBarColor: Color(0x00000000),
    systemNavigationBarDividerColor: Color(0x00000000),
    systemStatusBarContrastEnforced: false,
    systemNavigationBarContrastEnforced: false,
  );

  /// The default System UI style used by all screens.
  static SystemUiOverlayStyle get defaultAppStyle => _defaultAppStyle;

  /// Screen-specific System UI style for Quran Reader only.
  static SystemUiOverlayStyle get quranReaderStyle => _quranReaderStyle;

  /// Updates the default app-wide System UI style.
  ///
  /// Use this when the app theme changes.
  static void updateDefaultAppStyle(SystemUiOverlayStyle style) {
    _defaultAppStyle = style;
  }

  /// Updates the Quran Reader-specific System UI style.
  ///
  /// Use this only from Quran Reader theme/setup logic.
  static void updateQuranReaderStyle(SystemUiOverlayStyle style) {
    _quranReaderStyle = style;
  }

  /// Returns the correct System UI style for a route/screen.
  static SystemUiOverlayStyle resolve({required AppSystemChromeTarget target}) {
    return switch (target) {
      AppSystemChromeTarget.quranReader => _quranReaderStyle,
      AppSystemChromeTarget.defaultScreen => _defaultAppStyle,
    };
  }

  /// Applies the default app chrome: edge-to-edge mode + default overlay style.
  ///
  /// Call when leaving a screen with a custom system UI mode (e.g. the Quran
  /// Reader's immersive sticky mode) so the rest of the app returns to its
  /// expected chrome.
  static void applyDefault() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setSystemUIOverlayStyle(_defaultAppStyle);
  }

  /// Applies the Quran Reader chrome: immersive sticky mode + reader overlay.
  static void applyQuranReader() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    SystemChrome.setSystemUIOverlayStyle(_quranReaderStyle);
  }
}

enum AppSystemChromeTarget { defaultScreen, quranReader }
