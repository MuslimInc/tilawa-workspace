import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'package:quran/quran.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

PreviewThemeData themeData() {
  return PreviewThemeData(
    materialLight: AppTheme.getLightTheme(primaryColor: AppColors.primaryCyan),
    materialDark: AppTheme.getDarkTheme(primaryColor: AppColors.primaryCyan),
  );
}

@Preview(
  name: 'SurahHeaderBanner - Portrait',
  group: 'Quran',
  brightness: Brightness.light,
  theme: themeData,
)
Widget previewPortrait() {
  return const Scaffold(
    body: Center(
      child: SurahHeaderBanner(
        surahNumber: 1, // Al-Fatiha
        lineHeight: 24,
        viewportWidth: 0,
        viewportHeight: 0,
        isLandscape: false,
      ),
    ),
  );
}

@Preview(
  name: 'SurahHeaderBanner - Landscape',
  group: 'Quran',
  brightness: Brightness.light,
  theme: themeData,
)
Widget previewLandscape() {
  return const Scaffold(
    body: Center(
      child: SurahHeaderBanner(
        surahNumber: 114, // An-Nas
        lineHeight: 24,
        viewportWidth: 0,
        viewportHeight: 0,
        isLandscape: true,
      ),
    ),
  );
}
