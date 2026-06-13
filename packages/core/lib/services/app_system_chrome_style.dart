import 'package:flutter/material.dart';
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

  /// Builds the default system UI style for standard app routes.
  ///
  /// Status-bar icon brightness follows [statusBarBackgroundColor] (defaults
  /// to [ThemeData.scaffoldBackgroundColor]) so icons stay readable on the page
  /// behind the bar — not from the bottom-nav fill.
  ///
  /// The navigation bar uses [navigationBarColor] (Tilawa bottom-nav fill) so
  /// the OS gesture strip blends with the floating nav.
  static SystemUiOverlayStyle buildDefaultAppStyle(
    ThemeData theme, {
    Color? navigationBarColor,
    Color? statusBarBackgroundColor,
  }) {
    final Color statusBackground =
        statusBarBackgroundColor ?? theme.scaffoldBackgroundColor;
    final Color resolvedNavColor =
        navigationBarColor ?? theme.colorScheme.surface;

    final Brightness statusBarBrightness = ThemeData.estimateBrightnessForColor(
      statusBackground,
    );
    final Brightness statusIconBrightness =
        statusBarBrightness == Brightness.dark
        ? Brightness.light
        : Brightness.dark;

    final Brightness navBarBrightness = ThemeData.estimateBrightnessForColor(
      resolvedNavColor,
    );
    final Brightness navIconBrightness = navBarBrightness == Brightness.dark
        ? Brightness.light
        : Brightness.dark;

    final Color opaqueStatusColor = statusBackground.withValues(alpha: 1);
    final Color opaqueNavColor = resolvedNavColor.withValues(alpha: 1);

    return SystemUiOverlayStyle(
      statusBarColor: opaqueStatusColor,
      statusBarIconBrightness: statusIconBrightness,
      statusBarBrightness: statusBarBrightness,
      systemNavigationBarColor: opaqueNavColor,
      systemNavigationBarDividerColor: Colors.transparent,
      systemNavigationBarIconBrightness: navIconBrightness,
      systemStatusBarContrastEnforced: false,
      systemNavigationBarContrastEnforced: false,
    );
  }

  /// Launch / full-bleed screens with one background (e.g. green splash).
  static SystemUiOverlayStyle buildColoredScreenStyle({
    required Color backgroundColor,
    Color? navigationBarColor,
  }) {
    final Brightness barBrightness = ThemeData.estimateBrightnessForColor(
      backgroundColor,
    );
    final Brightness iconBrightness = barBrightness == Brightness.dark
        ? Brightness.light
        : Brightness.dark;
    final Color opaqueBackground = backgroundColor.withValues(alpha: 1);
    final Color opaqueNavColor = (navigationBarColor ?? backgroundColor)
        .withValues(alpha: 1);

    return SystemUiOverlayStyle(
      statusBarColor: opaqueBackground,
      statusBarIconBrightness: iconBrightness,
      statusBarBrightness: barBrightness,
      systemNavigationBarColor: opaqueNavColor,
      systemNavigationBarIconBrightness: iconBrightness,
      systemNavigationBarDividerColor: Colors.transparent,
      systemStatusBarContrastEnforced: false,
      systemNavigationBarContrastEnforced: false,
    );
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
