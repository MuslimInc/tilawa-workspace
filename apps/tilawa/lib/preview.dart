import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

PreviewThemeData themeData() {
  return PreviewThemeData(
    materialLight: AppTheme.getLightTheme(primaryColor: AppColors.primaryCyan),
    materialDark: AppTheme.getDarkTheme(primaryColor: AppColors.primaryCyan),
  );
}

@Preview(
  name: 'BottomPlayer',
  group: 'Widgets',
  brightness: Brightness.light,
  theme: themeData,
)
Widget preview() {
  return Scaffold(
    body: Padding(
      padding: const EdgeInsets.all(8.0),
      child: Center(
        child: TilawaMediaPlayerBar(
          title: 'Surah Al-Fatiha',
          subtitle: 'Abdul Basit',
          progress: 0.5,
          isPlaying: true,
          canGoPrevious: true,
          canGoNext: true,
          onPlayPause: () {
            // Preview callback - no action needed
          },
          onPrevious: () {
            // Preview callback - no action needed
          },
          onNext: () {
            // Preview callback - no action needed
          },
          onTap: () {
            // Preview callback - no action needed
          },
        ),
      ),
    ),
  );
}
