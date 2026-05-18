import 'package:flutter/material.dart';

import 'tilawa_colors.dart';
import 'tilawa_tokens.dart';
import 'tilawa_typography.dart';

/// Inherited bundle of design-system foundations. Place a [TilawaTheme]
/// near the root of your widget tree so atoms/molecules/organisms can pick up
/// the brand without re-resolving via [Theme.of].
class TilawaTheme extends InheritedWidget {
  const TilawaTheme({
    required this.tokens,
    required this.typography,
    required super.child,
    super.key,
  });

  final TilawaTokens tokens;
  final TilawaTypography typography;

  static TilawaTheme of(BuildContext context) {
    final t = context.dependOnInheritedWidgetOfExactType<TilawaTheme>();
    assert(t != null, 'No TilawaTheme found in context.');
    return t!;
  }

  /// Like [of], but returns `null` when no theme is in scope. Useful for
  /// widgets that want to opt-in without erroring during early bootstrap.
  static TilawaTheme? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<TilawaTheme>();
  }

  /// Convenience constructor producing the default light setup.
  factory TilawaTheme.light({Key? key, required Widget child}) {
    return TilawaTheme(
      key: key,
      tokens: TilawaTokens.light(),
      typography: TilawaTypography.light(),
      child: child,
    );
  }

  @override
  bool updateShouldNotify(TilawaTheme old) =>
      tokens != old.tokens || typography != old.typography;
}

/// Builds a Material [ThemeData] that mirrors the design system.
///
/// Useful when you want to drop a v2-themed app in quickly — for production
/// apps that already have their own [ThemeData], you can still wrap their
/// content in [TilawaTheme] and let widgets read tokens directly.
ThemeData buildTilawaMaterialTheme() {
  final type = TilawaTypography.light();
  final colors = TilawaColors.light();

  final colorScheme = ColorScheme(
    brightness: Brightness.light,
    primary: colors.brand,
    onPrimary: colors.fgOnPrimary,
    primaryContainer: TilawaPalette.green100,
    onPrimaryContainer: TilawaPalette.green900,
    secondary: TilawaPalette.gold500,
    onSecondary: TilawaPalette.gold700,
    secondaryContainer: TilawaPalette.gold100,
    onSecondaryContainer: TilawaPalette.gold700,
    tertiary: TilawaPalette.sky200,
    onTertiary: TilawaPalette.green800,
    error: colors.danger,
    onError: colors.fgOnPrimary,
    surface: colors.bgCard,
    onSurface: colors.fg1,
    surfaceContainerHighest: TilawaPalette.surfaceApp,
    onSurfaceVariant: colors.fg2,
    outline: colors.hairline,
    outlineVariant: TilawaPalette.lineCard,
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: colors.bgPage,
    fontFamily: TilawaFontFamily.ui,
    textTheme: TextTheme(
      displayLarge: type.display,
      displayMedium: type.h1,
      displaySmall: type.h2,
      headlineMedium: type.h2,
      headlineSmall: type.h3,
      titleLarge: type.h3,
      titleMedium: type.h4,
      titleSmall: type.bodyStrong,
      bodyLarge: type.bodyLg,
      bodyMedium: type.body,
      bodySmall: type.caption,
      labelLarge: type.button,
      labelMedium: type.eyebrow,
      labelSmall: type.overline,
    ),
    iconTheme: IconThemeData(color: colors.fg1, size: 20),
    dividerTheme: DividerThemeData(color: colors.hairline, thickness: 1),
    splashFactory: InkRipple.splashFactory,
  );
}
