import 'package:flutter/material.dart';

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
