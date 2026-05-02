import 'package:flutter/material.dart';
import '../foundation/app_theme.dart';
import '../foundation/app_colors.dart';

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
    this.useGoogleFonts = false, // Default to false for test/preview stability
  });

  final Widget child;
  final bool isDark;
  final bool isRTL;
  final double textScale;
  final EdgeInsets padding;
  final bool useGoogleFonts;

  @override
  Widget build(BuildContext context) {
    final theme = isDark
        ? AppTheme.getDarkTheme(
            primaryColor: AppColors.primaryCyan,
            useGoogleFontsOverride: useGoogleFonts,
          )
        : AppTheme.getLightTheme(
            primaryColor: AppColors.primaryCyan,
            useGoogleFontsOverride: useGoogleFonts,
          );

    return MediaQuery(
      data: MediaQuery.of(context).copyWith(
        platformBrightness: isDark ? Brightness.dark : Brightness.light,
        textScaler: TextScaler.linear(textScale),
      ),
      child: Theme(
        data: theme,
        child: Material(
          color: Colors.transparent,
          child: Directionality(
            textDirection: isRTL ? TextDirection.rtl : TextDirection.ltr,
            child: Padding(padding: padding, child: child),
          ),
        ),
      ),
    );
  }
}
