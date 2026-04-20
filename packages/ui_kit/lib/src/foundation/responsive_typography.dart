import 'package:flutter/material.dart';

import 'breakpoints.dart';

/// Extension to provide responsive typography scaling based on window size.
extension TilawaResponsiveTypography on BuildContext {
  /// Resolves a [TextTheme] that scales font sizes based on the current
  /// [TilawaWindowSize].
  ///
  /// This ensures that on larger screens (tablets/expanded), headings and
  /// body text are slightly larger to maintain readability and visual balance.
  TextTheme get responsiveTextTheme {
    final base = Theme.of(this).textTheme;
    final size = windowSize;

    if (size.index >= TilawaWindowSize.expanded.index) {
      return base.copyWith(
        displayLarge: base.displayLarge?.copyWith(fontSize: 64),
        displayMedium: base.displayMedium?.copyWith(fontSize: 52),
        displaySmall: base.displaySmall?.copyWith(fontSize: 40),
        headlineLarge: base.headlineLarge?.copyWith(fontSize: 36),
        headlineMedium: base.headlineMedium?.copyWith(fontSize: 32),
        headlineSmall: base.headlineSmall?.copyWith(fontSize: 28),
        titleLarge: base.titleLarge?.copyWith(fontSize: 26),
        titleMedium: base.titleMedium?.copyWith(fontSize: 20),
        titleSmall: base.titleSmall?.copyWith(fontSize: 18),
        bodyLarge: base.bodyLarge?.copyWith(fontSize: 18),
        bodyMedium: base.bodyMedium?.copyWith(fontSize: 16),
        bodySmall: base.bodySmall?.copyWith(fontSize: 14),
      );
    }

    if (size.index >= TilawaWindowSize.medium.index) {
      return base.copyWith(
        displayLarge: base.displayLarge?.copyWith(fontSize: 60),
        displayMedium: base.displayMedium?.copyWith(fontSize: 48),
        titleLarge: base.titleLarge?.copyWith(fontSize: 24),
        bodyLarge: base.bodyLarge?.copyWith(fontSize: 17),
        bodyMedium: base.bodyMedium?.copyWith(fontSize: 15),
      );
    }

    return base;
  }

  /// Helper to get a responsive [TextStyle] for a specific role.
  TextStyle? responsiveStyle(TextStyle? Function(TextTheme) selector) {
    return selector(responsiveTextTheme);
  }
}
