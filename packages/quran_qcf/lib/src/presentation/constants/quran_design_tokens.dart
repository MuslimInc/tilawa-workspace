import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

/// Quran-specific design tokens for the reader UI.
///
/// Extends the Tilawa design tokens with Quran-specific colors and values
/// that are used throughout the reader UI. These values are centered around
/// the Quran page color scheme and text rendering.
@immutable
class QuranDesignTokens extends ThemeExtension<QuranDesignTokens> {
  const QuranDesignTokens({
    required this.pageBackgroundColor,
    required this.pageTextColor,
    required this.verseHighlightColor,
    required this.headerTextColor,
    required this.headerTopPadding,
    required this.bismillahFontScale,
  });

  /// The default background color for Quran pages (warm off-white).
  /// Default: 0xFFFFF9F1
  final Color pageBackgroundColor;

  /// The default text color for Quran verses (black).
  /// Default: 0xFF000000
  final Color pageTextColor;

  /// The highlight color for searched or selected verses.
  /// Default: 0xFF9A7A57 (warm brown)
  final Color verseHighlightColor;

  /// The text color for Surah headers.
  /// Default: Colors.black
  final Color headerTextColor;

  /// Top padding for header widgets in dp.
  /// Default: 12.0
  final double headerTopPadding;

  /// Font scale factor for Bismillah text (relative to page font size).
  /// Default: 1.0
  final double bismillahFontScale;

  @override
  QuranDesignTokens copyWith({
    Color? pageBackgroundColor,
    Color? pageTextColor,
    Color? verseHighlightColor,
    Color? headerTextColor,
    double? headerTopPadding,
    double? bismillahFontScale,
  }) {
    return QuranDesignTokens(
      pageBackgroundColor: pageBackgroundColor ?? this.pageBackgroundColor,
      pageTextColor: pageTextColor ?? this.pageTextColor,
      verseHighlightColor: verseHighlightColor ?? this.verseHighlightColor,
      headerTextColor: headerTextColor ?? this.headerTextColor,
      headerTopPadding: headerTopPadding ?? this.headerTopPadding,
      bismillahFontScale: bismillahFontScale ?? this.bismillahFontScale,
    );
  }

  @override
  QuranDesignTokens lerp(QuranDesignTokens? other, double t) {
    if (other is! QuranDesignTokens) {
      return this;
    }
    return QuranDesignTokens(
      pageBackgroundColor:
          Color.lerp(pageBackgroundColor, other.pageBackgroundColor, t) ??
          pageBackgroundColor,
      pageTextColor:
          Color.lerp(pageTextColor, other.pageTextColor, t) ?? pageTextColor,
      verseHighlightColor:
          Color.lerp(verseHighlightColor, other.verseHighlightColor, t) ??
          verseHighlightColor,
      headerTextColor:
          Color.lerp(headerTextColor, other.headerTextColor, t) ??
          headerTextColor,
      headerTopPadding:
          lerpDouble(headerTopPadding, other.headerTopPadding, t) ??
          headerTopPadding,
      bismillahFontScale:
          lerpDouble(bismillahFontScale, other.bismillahFontScale, t) ??
          bismillahFontScale,
    );
  }

  /// Default Quran design tokens for light theme.
  static const QuranDesignTokens light = QuranDesignTokens(
    pageBackgroundColor: AppQuranReaderLegacyColors.lightPageBackground,
    pageTextColor: AppQuranReaderLegacyColors.lightOnSurface,
    verseHighlightColor: AppQuranReaderLegacyColors.lightVerseHighlight,
    headerTextColor: AppQuranReaderLegacyColors.lightOnSurface,
    headerTopPadding: 12.0,
    bismillahFontScale: 1.0,
  );

  /// Default Quran design tokens for dark theme.
  static const QuranDesignTokens dark = QuranDesignTokens(
    pageBackgroundColor: AppQuranReaderLegacyColors.darkPageBackground,
    pageTextColor: AppQuranReaderLegacyColors.darkOnSurface,
    verseHighlightColor: AppQuranReaderLegacyColors.darkVerseHighlight,
    headerTextColor: AppQuranReaderLegacyColors.darkOnSurface,
    headerTopPadding: 12.0,
    bismillahFontScale: 1.0,
  );
}

/// Extension on ThemeData to access Quran design tokens.
extension QuranDesignTokensThemeExtension on ThemeData {
  QuranDesignTokens get quranTokens =>
      extension<QuranDesignTokens>() ?? QuranDesignTokens.light;
}
