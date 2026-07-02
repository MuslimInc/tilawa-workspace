import 'package:flutter/material.dart';

import '../foundation/app_colors.dart';
import '../foundation/app_theme.dart';
import '../foundation/tilawa_type_scale.dart';

/// A wrapper widget for Widget Previews and Golden Tests to ensure
/// consistent environment configuration across themes, locales, and scales.
///
/// This provides a "Safe App Environment" including MediaQuery, Theme,
/// Material, and Directionality without the layout overhead of a full MaterialApp.
class TilawaPreviewWrapper extends StatelessWidget {
  const TilawaPreviewWrapper({
    super.key,
    required this.child,
    this.isDark = false,
    this.isRTL = false,
    this.textScale = 1.0,
    this.padding = const EdgeInsets.all(16.0),
  });

  final Widget child;
  final bool isDark;
  final bool isRTL;
  final double textScale;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final theme = isDark
        ? AppTheme.getDarkTheme(
            primaryColor: AppColors.defaultPrimary,
            isDefaultPreset: true,
          )
        : AppTheme.getLightTheme(
            primaryColor: AppColors.defaultPrimary,
          );

    final mediaQuery = MediaQuery.maybeOf(context);
    final baseData = mediaQuery ?? const MediaQueryData();

    return MediaQuery(
      data: baseData.copyWith(
        platformBrightness: isDark ? Brightness.dark : Brightness.light,
        textScaler: tilawaProductTextScaler(TextScaler.linear(textScale)),
      ),
      child: Theme(
        data: theme,
        child: Material(
          color: theme.scaffoldBackgroundColor,
          child: Directionality(
            textDirection: isRTL ? TextDirection.rtl : TextDirection.ltr,
            child: Padding(padding: padding, child: child),
          ),
        ),
      ),
    );
  }
}
