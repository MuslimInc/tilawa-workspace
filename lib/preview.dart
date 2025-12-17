import 'package:audio_service/audio_service.dart';
import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';

import 'core/theme/app_theme.dart';
import 'shared/models/position_data.dart';
import 'shared/widgets/bottom_player_ui.dart';

PreviewThemeData themeData() {
  return PreviewThemeData(
    materialLight: AppTheme.getLightTheme(FlexScheme.redM3),
    materialDark: AppTheme.getDarkTheme(FlexScheme.redM3),
  );
}

@Preview(
  name: 'BottomPlayer',
  group: 'Widgets',
  brightness: Brightness.light,
  theme: themeData,
)
Widget preview() {
  // Example MediaItem for preview
  final mediaItem = MediaItem(
    id: 'preview-1',
    title: 'Surah Al-Fatiha',
    artist: 'Abdul Basit',
    artUri: Uri.parse('https://example.com/art.jpg'),
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
          mediaItem: mediaItem,
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
