import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';

/// Service that provides FlexColorScheme theme configurations
///
/// Note: This service is kept for backward compatibility.
/// New code should use [AppTheme] directly.
@Deprecated('Use AppTheme instead')
class ThemeService {
  /// Get the light theme configuration
  static ThemeData getLightTheme() {
    return AppTheme.getLightTheme(FlexScheme.green);
  }

  /// Get the dark theme configuration
  static ThemeData getDarkTheme() {
    return AppTheme.getDarkTheme(FlexScheme.green);
  }

  /// Get available color schemes for the app
  static List<FlexScheme> getAvailableSchemes() {
    return AppTheme.getAvailableSchemes();
  }
}
