import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';

import 'core/entities/audio.dart';
import 'core/theme/app_theme.dart';
import 'shared/models/position_data.dart';
import 'shared/widgets/bottom_player_ui.dart';

PreviewThemeData themeData() {
  return PreviewThemeData(
    materialLight: AppTheme.getLightTheme(primaryColor: Colors.red),
    materialDark: AppTheme.getDarkTheme(primaryColor: Colors.red),
  );
}

@Preview(
  name: 'BottomPlayer',
  group: 'Widgets',
  brightness: Brightness.light,
  theme: themeData,
)
Widget preview() {
  // Example AudioEntity for preview
  const audio = AudioEntity(
    id: 'preview-1',
    title: 'Surah Al-Fatiha',
    url: 'https://example.com/audio.mp3',
    duration: Duration(minutes: 3),
    artist: 'Abdul Basit',
    artUri: 'https://example.com/art.jpg',
  );

  // Example position data
  const positionData = PositionData(
    position: Duration(seconds: 30),
    bufferedPosition: Duration(seconds: 60),
    duration: Duration(minutes: 3),
  );

  return Scaffold(
    body: Padding(
      padding: const EdgeInsets.all(8.0),
      child: Center(
        child: BottomPlayerUi(
          audio: audio,
          positionData: positionData,
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
