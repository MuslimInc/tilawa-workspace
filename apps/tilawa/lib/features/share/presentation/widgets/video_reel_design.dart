import 'package:flutter/material.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import '../../../quran_reader/presentation/theme/quran_reader_theme.dart';

abstract final class VideoReelDesign {
  static const Color mushafBackgroundColor =
      AppVideoReelDesignDefaults.mushafBackgroundColor;
  static const Color mushafTextColor =
      AppVideoReelDesignDefaults.mushafTextColor;
  static const Color verseHighlightColor =
      AppVideoReelDesignDefaults.verseHighlightColor;

  static const Color frameTextColor =
      AppVideoReelDesignDefaults.frameTextColor;
  static const Color frameSecondaryTextColor =
      AppVideoReelDesignDefaults.frameSecondaryTextColor;
  static const Color frameStrongTextColor =
      AppVideoReelDesignDefaults.frameStrongTextColor;
  static const Color frameAccentColor =
      AppVideoReelDesignDefaults.frameAccentColor;
  static const Color frameSurfaceColor =
      AppVideoReelDesignDefaults.frameSurfaceColor;

  static const double topBarHeightFactor = 0.042;
  static const double topBarMinHeight = 28;
  static const double topBarMaxHeight = 42;
  static const double topBarHorizontalPadding = 20;
  static const double topBarGap = 12;
  static const double topBarTitleFontSize = 16;
  static const double topBarMetaFontSize = 14;

  static const double surahHeaderToBismillahGapFactor = 0.08;
  static const double surahHeaderToBismillahMinGap = 3;
  static const double surahHeaderToBismillahMaxGap = 6;
  static const double bismillahToTextGapFactor = 0.05;
  static const double bismillahToTextMinGap = 2;
  static const double bismillahToTextMaxGap = 4;
}

class VideoReelPalette {
  const VideoReelPalette({
    required this.mushafBackgroundColor,
    required this.mushafTextColor,
    required this.verseHighlightColor,
    required this.frameTextColor,
    required this.frameSecondaryTextColor,
    required this.frameStrongTextColor,
    required this.frameAccentColor,
    required this.frameSurfaceColor,
  });

  final Color mushafBackgroundColor;
  final Color mushafTextColor;
  final Color verseHighlightColor;
  final Color frameTextColor;
  final Color frameSecondaryTextColor;
  final Color frameStrongTextColor;
  final Color frameAccentColor;
  final Color frameSurfaceColor;

  factory VideoReelPalette.fromContext(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final readerTheme = QuranReaderTheme.of(context);
    final isDark = colorScheme.brightness == Brightness.dark;

    final backgroundTint = isDark ? 0.08 : 0.12;
    final frameTint = isDark ? 0.18 : 0.30;
    final mushafBackgroundColor = Color.lerp(
      readerTheme.pageBackground,
      colorScheme.primaryContainer,
      backgroundTint,
    )!;

    return VideoReelPalette(
      mushafBackgroundColor: mushafBackgroundColor,
      mushafTextColor: readerTheme.textColor,
      verseHighlightColor: colorScheme.primary.withValues(
        alpha: isDark ? 0.24 : 0.15,
      ),
      frameTextColor: colorScheme.onSurface.withValues(alpha: 0.82),
      frameSecondaryTextColor: colorScheme.onSurfaceVariant.withValues(
        alpha: 0.82,
      ),
      frameStrongTextColor: colorScheme.onSurface,
      frameAccentColor: colorScheme.primary,
      frameSurfaceColor: Color.lerp(
        mushafBackgroundColor,
        colorScheme.primaryContainer,
        frameTint,
      )!,
    );
  }
}
