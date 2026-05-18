import 'package:flutter/material.dart';

import 'breakpoints.dart';

abstract final class _ResponsiveTypeScale {
  // Narrow window class (phones, < 600 dp): tiny size nudges plus explicit
  // height
  // and letterSpacing to add presence without inflating the scale. These
  // close most of the perceived gap between "looks great on emulator"
  // (which usually crosses into medium/expanded) and a real ~412 dp phone.
  static const double narrowTitleLarge = 23;
  static const double narrowBodyLarge = 16.5;
  static const double narrowHeadlineHeight = 1.25;
  static const double narrowBodyHeight = 1.4;
  static const double narrowDisplayLetterSpacing = -0.2;

  static const double mediumDisplayLarge = 60;
  static const double mediumDisplayMedium = 48;
  static const double mediumTitleLarge = 24;
  static const double mediumBodyLarge = 17;
  static const double mediumBodyMedium = 15;

  static const double expandedDisplayLarge = 64;
  static const double expandedDisplayMedium = 52;
  static const double expandedDisplaySmall = 40;
  static const double expandedHeadlineLarge = 36;
  static const double expandedHeadlineMedium = 32;
  static const double expandedHeadlineSmall = 28;
  static const double expandedTitleLarge = 26;
  static const double expandedTitleMedium = 20;
  static const double expandedTitleSmall = 18;
  static const double expandedBodyLarge = 18;
  static const double expandedBodyMedium = 16;
  static const double expandedBodySmall = 14;
}

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
        displayLarge: base.displayLarge?.copyWith(
          fontSize: _ResponsiveTypeScale.expandedDisplayLarge,
        ),
        displayMedium: base.displayMedium?.copyWith(
          fontSize: _ResponsiveTypeScale.expandedDisplayMedium,
        ),
        displaySmall: base.displaySmall?.copyWith(
          fontSize: _ResponsiveTypeScale.expandedDisplaySmall,
        ),
        headlineLarge: base.headlineLarge?.copyWith(
          fontSize: _ResponsiveTypeScale.expandedHeadlineLarge,
        ),
        headlineMedium: base.headlineMedium?.copyWith(
          fontSize: _ResponsiveTypeScale.expandedHeadlineMedium,
        ),
        headlineSmall: base.headlineSmall?.copyWith(
          fontSize: _ResponsiveTypeScale.expandedHeadlineSmall,
        ),
        titleLarge: base.titleLarge?.copyWith(
          fontSize: _ResponsiveTypeScale.expandedTitleLarge,
        ),
        titleMedium: base.titleMedium?.copyWith(
          fontSize: _ResponsiveTypeScale.expandedTitleMedium,
        ),
        titleSmall: base.titleSmall?.copyWith(
          fontSize: _ResponsiveTypeScale.expandedTitleSmall,
        ),
        bodyLarge: base.bodyLarge?.copyWith(
          fontSize: _ResponsiveTypeScale.expandedBodyLarge,
        ),
        bodyMedium: base.bodyMedium?.copyWith(
          fontSize: _ResponsiveTypeScale.expandedBodyMedium,
        ),
        bodySmall: base.bodySmall?.copyWith(
          fontSize: _ResponsiveTypeScale.expandedBodySmall,
        ),
      );
    }

    if (size.index >= TilawaWindowSize.medium.index) {
      return base.copyWith(
        displayLarge: base.displayLarge?.copyWith(
          fontSize: _ResponsiveTypeScale.mediumDisplayLarge,
        ),
        displayMedium: base.displayMedium?.copyWith(
          fontSize: _ResponsiveTypeScale.mediumDisplayMedium,
        ),
        titleLarge: base.titleLarge?.copyWith(
          fontSize: _ResponsiveTypeScale.mediumTitleLarge,
        ),
        bodyLarge: base.bodyLarge?.copyWith(
          fontSize: _ResponsiveTypeScale.mediumBodyLarge,
        ),
        bodyMedium: base.bodyMedium?.copyWith(
          fontSize: _ResponsiveTypeScale.mediumBodyMedium,
        ),
      );
    }

    // Narrow (phones): close the asymmetry where only larger windows got
    // typography love. Sub-pt size nudges plus explicit height/letterSpacing
    // give headlines presence and body text breathing room on ~412 dp screens.
    return base.copyWith(
      displayLarge: base.displayLarge?.copyWith(
        height: _ResponsiveTypeScale.narrowHeadlineHeight,
        letterSpacing: _ResponsiveTypeScale.narrowDisplayLetterSpacing,
      ),
      displayMedium: base.displayMedium?.copyWith(
        height: _ResponsiveTypeScale.narrowHeadlineHeight,
        letterSpacing: _ResponsiveTypeScale.narrowDisplayLetterSpacing,
      ),
      displaySmall: base.displaySmall?.copyWith(
        height: _ResponsiveTypeScale.narrowHeadlineHeight,
        letterSpacing: _ResponsiveTypeScale.narrowDisplayLetterSpacing,
      ),
      headlineLarge: base.headlineLarge?.copyWith(
        height: _ResponsiveTypeScale.narrowHeadlineHeight,
      ),
      headlineMedium: base.headlineMedium?.copyWith(
        height: _ResponsiveTypeScale.narrowHeadlineHeight,
      ),
      headlineSmall: base.headlineSmall?.copyWith(
        height: _ResponsiveTypeScale.narrowHeadlineHeight,
      ),
      titleLarge: base.titleLarge?.copyWith(
        fontSize: _ResponsiveTypeScale.narrowTitleLarge,
        height: _ResponsiveTypeScale.narrowHeadlineHeight,
      ),
      bodyLarge: base.bodyLarge?.copyWith(
        fontSize: _ResponsiveTypeScale.narrowBodyLarge,
        height: _ResponsiveTypeScale.narrowBodyHeight,
      ),
      bodyMedium: base.bodyMedium?.copyWith(
        height: _ResponsiveTypeScale.narrowBodyHeight,
      ),
      bodySmall: base.bodySmall?.copyWith(
        height: _ResponsiveTypeScale.narrowBodyHeight,
      ),
    );
  }

  /// Helper to get a responsive [TextStyle] for a specific role.
  TextStyle? responsiveStyle(TextStyle? Function(TextTheme) selector) {
    return selector(responsiveTextTheme);
  }
}
