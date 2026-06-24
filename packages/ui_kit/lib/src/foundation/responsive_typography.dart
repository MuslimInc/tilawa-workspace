import 'package:flutter/material.dart';

import 'breakpoints.dart';

/// M3 2021 default sizes — ratios are applied to the already-scaled
/// [ThemeData.textTheme] from [AppTheme], not re-scaled here.
abstract final class _M3TypographyDefaults {
  static const double displayLarge = 57;
  static const double displayMedium = 45;
  static const double displaySmall = 36;
  static const double headlineLarge = 32;
  static const double headlineMedium = 28;
  static const double headlineSmall = 24;
  static const double titleLarge = 22;
  static const double titleMedium = 16;
  static const double titleSmall = 14;
  static const double bodyLarge = 16;
  static const double bodyMedium = 14;
  static const double bodySmall = 12;
}

TextStyle? _nudgeRoleSize(
  TextStyle? style,
  double designSize,
  double m3Default,
) {
  final double? size = style?.fontSize;
  if (style == null || size == null) return style;
  return style.copyWith(fontSize: size * (designSize / m3Default));
}

abstract final class _ResponsiveTypeScale {
  // Narrow window class: tiny size nudges plus explicit height and
  // letterSpacing. Ratios are vs M3 defaults on the globally scaled theme.
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
        displayLarge: _nudgeRoleSize(
          base.displayLarge,
          _ResponsiveTypeScale.expandedDisplayLarge,
          _M3TypographyDefaults.displayLarge,
        ),
        displayMedium: _nudgeRoleSize(
          base.displayMedium,
          _ResponsiveTypeScale.expandedDisplayMedium,
          _M3TypographyDefaults.displayMedium,
        ),
        displaySmall: _nudgeRoleSize(
          base.displaySmall,
          _ResponsiveTypeScale.expandedDisplaySmall,
          _M3TypographyDefaults.displaySmall,
        ),
        headlineLarge: _nudgeRoleSize(
          base.headlineLarge,
          _ResponsiveTypeScale.expandedHeadlineLarge,
          _M3TypographyDefaults.headlineLarge,
        ),
        headlineMedium: _nudgeRoleSize(
          base.headlineMedium,
          _ResponsiveTypeScale.expandedHeadlineMedium,
          _M3TypographyDefaults.headlineMedium,
        ),
        headlineSmall: _nudgeRoleSize(
          base.headlineSmall,
          _ResponsiveTypeScale.expandedHeadlineSmall,
          _M3TypographyDefaults.headlineSmall,
        ),
        titleLarge: _nudgeRoleSize(
          base.titleLarge,
          _ResponsiveTypeScale.expandedTitleLarge,
          _M3TypographyDefaults.titleLarge,
        ),
        titleMedium: _nudgeRoleSize(
          base.titleMedium,
          _ResponsiveTypeScale.expandedTitleMedium,
          _M3TypographyDefaults.titleMedium,
        ),
        titleSmall: _nudgeRoleSize(
          base.titleSmall,
          _ResponsiveTypeScale.expandedTitleSmall,
          _M3TypographyDefaults.titleSmall,
        ),
        bodyLarge: _nudgeRoleSize(
          base.bodyLarge,
          _ResponsiveTypeScale.expandedBodyLarge,
          _M3TypographyDefaults.bodyLarge,
        ),
        bodyMedium: _nudgeRoleSize(
          base.bodyMedium,
          _ResponsiveTypeScale.expandedBodyMedium,
          _M3TypographyDefaults.bodyMedium,
        ),
        bodySmall: _nudgeRoleSize(
          base.bodySmall,
          _ResponsiveTypeScale.expandedBodySmall,
          _M3TypographyDefaults.bodySmall,
        ),
      );
    }

    if (size.index >= TilawaWindowSize.medium.index) {
      return base.copyWith(
        displayLarge: _nudgeRoleSize(
          base.displayLarge,
          _ResponsiveTypeScale.mediumDisplayLarge,
          _M3TypographyDefaults.displayLarge,
        ),
        displayMedium: _nudgeRoleSize(
          base.displayMedium,
          _ResponsiveTypeScale.mediumDisplayMedium,
          _M3TypographyDefaults.displayMedium,
        ),
        titleLarge: _nudgeRoleSize(
          base.titleLarge,
          _ResponsiveTypeScale.mediumTitleLarge,
          _M3TypographyDefaults.titleLarge,
        ),
        bodyLarge: _nudgeRoleSize(
          base.bodyLarge,
          _ResponsiveTypeScale.mediumBodyLarge,
          _M3TypographyDefaults.bodyLarge,
        ),
        bodyMedium: _nudgeRoleSize(
          base.bodyMedium,
          _ResponsiveTypeScale.mediumBodyMedium,
          _M3TypographyDefaults.bodyMedium,
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
      titleLarge: _nudgeRoleSize(
        base.titleLarge?.copyWith(
          height: _ResponsiveTypeScale.narrowHeadlineHeight,
        ),
        _ResponsiveTypeScale.narrowTitleLarge,
        _M3TypographyDefaults.titleLarge,
      ),
      bodyLarge: _nudgeRoleSize(
        base.bodyLarge?.copyWith(
          height: _ResponsiveTypeScale.narrowBodyHeight,
        ),
        _ResponsiveTypeScale.narrowBodyLarge,
        _M3TypographyDefaults.bodyLarge,
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
