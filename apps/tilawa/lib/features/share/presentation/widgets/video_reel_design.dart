import 'package:flutter/material.dart';

import '../../../quran_reader/presentation/theme/quran_reader_theme.dart';

abstract final class VideoReelDesign {
  static const Color mushafBackgroundColor = Color(0xFFFFF8ED);
  static const Color mushafTextColor = Color(0xF52E2116);
  static const Color verseHighlightColor = Color(0x3DF57C00);

  static const Color frameTextColor = Color(0xFF6B5B4F);
  static const Color frameSecondaryTextColor = Color(0xFF8B7355);
  static const Color frameStrongTextColor = Color(0xFF5D4037);
  static const Color frameAccentColor = Color(0xFFC5A358);
  static const Color frameSurfaceColor = Color(0xFFFFF9F2);

  static const double topBarHeightFactor = 0.042;
  static const double topBarMinHeight = 28;
  static const double topBarMaxHeight = 42;
  static const double topBarHorizontalPadding = 20;
  static const double topBarGap = 12;
  static const double topBarTitleFontSize = 16;
  static const double topBarMetaFontSize = 14;

  static const double bottomBarHorizontalMarginFactor = 0.04;
  static const double bottomBarTopMarginFactor = 0.006;
  static const double bottomBarBottomMarginFactor = 0.010;
  static const double bottomBarHorizontalPadding = 16;
  static const double bottomBarVerticalPaddingFactor = 0.002;
  static const double bottomBarMinVerticalPadding = 2;
  static const double bottomBarMaxVerticalPadding = 6;
  static const double bottomBarRadius = 32;
  static const double bottomBarMetaFontSize = 12;
  static const double bottomBarBorderAlpha = 0.30;

  static const double pageBadgeSizeFactor = 0.05;
  static const double pageBadgeMinSize = 34;
  static const double pageBadgeMaxSize = 46;
  static const double pageBadgePadding = 1;
  static const double pageBadgeAccentAlpha = 0.10;

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
