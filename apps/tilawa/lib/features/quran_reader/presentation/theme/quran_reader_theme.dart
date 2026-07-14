import 'package:flutter/material.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

/// Theme extension for the Quran Reader feature.
///
/// Provides distinct colors for the Mushaf pages and the navigation UI
/// that work across both Light and Dark modes via Flutter's theme system.
class QuranReaderTheme extends ThemeExtension<QuranReaderTheme> {
  const QuranReaderTheme({
    required this.pageBackground,
    required this.textColor,
    required this.primaryColor,
    required this.headerBackground,
    required this.headerTextColor,
    required this.headerImageFilter,
    required this.systemBarColor,
    required this.statusBarIconBrightness,
    required this.statusBarBrightness,
    required this.sliderRangeTextStyle,
    required this.pillSurahTextStyle,
    required this.pillPageTextStyle,
    required this.cardPageBadgeTextStyle,
    required this.cardContextSummaryTextStyle,
    required this.indexTitleTextStyle,
    required this.indexSubtitleTextStyle,
    required this.surahTileNameTextStyle,
    required this.surahTileMetaTextStyle,
    required this.surahTileArabicNameTextStyle,
  });

  /// Pre-built light-mode instance.
  static const QuranReaderTheme light = QuranReaderTheme(
    pageBackground: AppQuranReaderLegacyColors.lightPageBackground,
    textColor: AppQuranReaderLegacyColors.lightOnSurface,
    primaryColor: AppQuranReaderLegacyColors.lightPrimary,
    headerBackground: AppQuranReaderLegacyColors.lightHeaderBackground,
    headerTextColor: AppQuranReaderLegacyColors.lightOnSurface,
    headerImageFilter: null,
    systemBarColor: AppQuranReaderLegacyColors.lightSystemBar,
    statusBarIconBrightness: Brightness.dark,
    statusBarBrightness: Brightness.light,
    sliderRangeTextStyle: TextStyle(
      color: AppQuranReaderLegacyColors.lightMutedOnSurface,
      fontSize: 10,
      fontWeight: FontWeight.w800,
    ),
    pillSurahTextStyle: TextStyle(
      color: AppQuranReaderLegacyColors.lightOnSurface,
      fontSize: 13,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.2,
    ),
    pillPageTextStyle: TextStyle(
      color: AppQuranReaderLegacyColors.lightPrimary,
      fontSize: 11,
      fontWeight: FontWeight.w700,
    ),
    cardPageBadgeTextStyle: TextStyle(
      color: AppQuranReaderLegacyColors.lightPrimary,
      fontWeight: FontWeight.w900,
      fontSize: 12,
    ),
    cardContextSummaryTextStyle: TextStyle(
      color: AppQuranReaderLegacyColors.lightMutedOnSurface,
      fontSize: 12,
      fontWeight: FontWeight.w600,
      letterSpacing: -0.1,
    ),
    indexTitleTextStyle: TextStyle(
      color: AppQuranReaderLegacyColors.lightOnSurface,
      fontSize: 20,
      fontWeight: FontWeight.w800,
      letterSpacing: -0.5,
    ),
    indexSubtitleTextStyle: TextStyle(
      color: AppQuranReaderLegacyColors.lightMutedOnSurface,
      fontSize: 12,
      fontWeight: FontWeight.w500,
    ),
    surahTileNameTextStyle: TextStyle(
      color: AppQuranReaderLegacyColors.lightOnSurface,
      fontSize: 14,
      fontWeight: FontWeight.w700,
    ),
    surahTileMetaTextStyle: TextStyle(
      color: AppQuranReaderLegacyColors.lightMutedOnSurface,
      fontSize: 11,
      fontWeight: FontWeight.w500,
    ),
    surahTileArabicNameTextStyle: TextStyle(
      color: AppQuranReaderLegacyColors.lightPrimary,
      fontFamily: AppTheme.arabicFontFamily,
      fontSize: 18,
      fontWeight: FontWeight.w800,
    ),
  );

  /// Pre-built dark-mode instance.
  static const QuranReaderTheme dark = QuranReaderTheme(
    pageBackground: AppQuranReaderLegacyColors.darkPageBackground,
    textColor: AppQuranReaderLegacyColors.darkOnSurface,
    primaryColor: AppQuranReaderLegacyColors.darkPrimary,
    headerBackground: AppQuranReaderLegacyColors.darkHeaderBackground,
    headerTextColor: AppQuranReaderLegacyColors.darkHeaderOnSurface,
    headerImageFilter: ColorFilter.matrix([
      -0.8,
      0,
      0,
      0,
      230,
      0,
      -0.8,
      0,
      0,
      230,
      0,
      0,
      -0.8,
      0,
      230,
      0,
      0,
      0,
      1,
      0,
    ]),
    systemBarColor: AppQuranReaderLegacyColors.darkSystemBar,
    statusBarIconBrightness: Brightness.light,
    statusBarBrightness: Brightness.dark,
    sliderRangeTextStyle: TextStyle(
      color: AppQuranReaderLegacyColors.darkMutedCaption,
      fontSize: 10,
      fontWeight: FontWeight.w800,
    ),
    pillSurahTextStyle: TextStyle(
      color: AppQuranReaderLegacyColors.darkPillSurah,
      fontSize: 13,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.2,
    ),
    pillPageTextStyle: TextStyle(
      color: AppQuranReaderLegacyColors.darkPrimary,
      fontSize: 11,
      fontWeight: FontWeight.w700,
    ),
    cardPageBadgeTextStyle: TextStyle(
      color: AppQuranReaderLegacyColors.darkPrimary,
      fontWeight: FontWeight.w900,
      fontSize: 12,
    ),
    cardContextSummaryTextStyle: TextStyle(
      color: AppQuranReaderLegacyColors.darkMutedCaption,
      fontSize: 12,
      fontWeight: FontWeight.w600,
      letterSpacing: -0.1,
    ),
    indexTitleTextStyle: TextStyle(
      color: AppQuranReaderLegacyColors.darkHeaderOnSurface,
      fontSize: 20,
      fontWeight: FontWeight.w800,
      letterSpacing: -0.5,
    ),
    indexSubtitleTextStyle: TextStyle(
      color: AppQuranReaderLegacyColors.darkMutedCaption,
      fontSize: 12,
      fontWeight: FontWeight.w500,
    ),
    surahTileNameTextStyle: TextStyle(
      color: AppQuranReaderLegacyColors.darkSurahTileName,
      fontSize: 14,
      fontWeight: FontWeight.w700,
    ),
    surahTileMetaTextStyle: TextStyle(
      color: AppQuranReaderLegacyColors.darkMutedCaption,
      fontSize: 11,
      fontWeight: FontWeight.w500,
    ),
    surahTileArabicNameTextStyle: TextStyle(
      color: AppQuranReaderLegacyColors.darkArabicAccent,
      fontFamily: AppTheme.arabicFontFamily,
      fontSize: 18,
      fontWeight: FontWeight.w700,
    ),
  );

  /// Background color for the Mushaf page.
  final Color pageBackground;

  /// Color for the Quran text glyphs.
  final Color textColor;

  /// Primary accent color for the reader.
  final Color primaryColor;

  /// Background color for the Surah header banner.
  final Color headerBackground;

  /// Text color for the Surah name inside the banner.
  final Color headerTextColor;

  /// Color filter for the Surah header banner image (inverts in dark mode).
  final ColorFilter? headerImageFilter;

  /// Color for the system status bar area.
  final Color systemBarColor;

  /// Icon brightness for the status bar.
  final Brightness statusBarIconBrightness;

  /// Status bar brightness hint.
  final Brightness statusBarBrightness;

  /// Text style for the 1-604 slider range labels.
  final TextStyle sliderRangeTextStyle;

  /// Text style for the surah name in the preview pill.
  final TextStyle pillSurahTextStyle;

  /// Text style for the page label in the preview pill.
  final TextStyle pillPageTextStyle;

  /// Text style for the current page badge in the card.
  final TextStyle cardPageBadgeTextStyle;

  /// Text style for the Juz/Hizb info in the card.
  final TextStyle cardContextSummaryTextStyle;

  /// Text style for the "Surah Index" title in the sheet.
  final TextStyle indexTitleTextStyle;

  /// Text style for the surah count subtitle in the sheet.
  final TextStyle indexSubtitleTextStyle;

  /// Text style for the English surah name in the index list.
  final TextStyle surahTileNameTextStyle;

  /// Text style for the Ayah count / place info in the index list.
  final TextStyle surahTileMetaTextStyle;

  /// Text style for the Arabic surah name in the index list.
  final TextStyle surahTileArabicNameTextStyle;

  /// Convenience accessor: `QuranReaderTheme.of(context)`.
  static QuranReaderTheme of(BuildContext context) {
    final theme = Theme.of(context);
    return theme.extension<QuranReaderTheme>() ?? fromTheme(theme);
  }

  /// Builds reader colors and text styles from the active app [ThemeData].
  ///
  /// This keeps the Quran reader aligned with the app-wide color scheme
  /// instead of injecting a separate reader-specific theme at the app root.
  static QuranReaderTheme fromTheme(ThemeData theme) {
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final isDark = theme.brightness == Brightness.dark;
    final iconBrightness = isDark ? Brightness.light : Brightness.dark;
    final statusBarBrightness = isDark ? Brightness.dark : Brightness.light;
    final pageBackground = theme.scaffoldBackgroundColor;
    final primary = colorScheme.primary;
    final onSurface = colorScheme.onSurface;
    final onSurfaceVariant = colorScheme.onSurfaceVariant;

    return QuranReaderTheme(
      pageBackground: pageBackground,
      textColor: onSurface,
      primaryColor: primary,
      headerBackground: colorScheme.surfaceContainerHighest,
      headerTextColor: onSurface,
      headerImageFilter: isDark ? dark.headerImageFilter : null,
      systemBarColor: pageBackground,
      statusBarIconBrightness: iconBrightness,
      statusBarBrightness: statusBarBrightness,
      sliderRangeTextStyle:
          textTheme.labelSmall?.copyWith(
            color: onSurfaceVariant,
            fontWeight: FontWeight.w800,
          ) ??
          TextStyle(
            color: onSurfaceVariant,
            fontSize: 10,
            fontWeight: FontWeight.w800,
          ),
      pillSurahTextStyle:
          textTheme.labelLarge?.copyWith(
            color: onSurface,
            fontWeight: FontWeight.w700,
          ) ??
          TextStyle(
            color: onSurface,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
      pillPageTextStyle:
          textTheme.labelMedium?.copyWith(
            color: primary,
            fontWeight: FontWeight.w700,
          ) ??
          TextStyle(color: primary, fontSize: 11, fontWeight: FontWeight.w700),
      cardPageBadgeTextStyle:
          textTheme.labelLarge?.copyWith(
            color: primary,
            fontWeight: FontWeight.w800,
          ) ??
          TextStyle(color: primary, fontSize: 12, fontWeight: FontWeight.w800),
      cardContextSummaryTextStyle:
          textTheme.labelMedium?.copyWith(
            color: onSurfaceVariant,
            fontWeight: FontWeight.w600,
          ) ??
          TextStyle(
            color: onSurfaceVariant,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
      indexTitleTextStyle:
          textTheme.titleLarge?.copyWith(
            color: onSurface,
            fontWeight: FontWeight.w800,
          ) ??
          TextStyle(
            color: onSurface,
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
      indexSubtitleTextStyle:
          textTheme.bodySmall?.copyWith(color: onSurfaceVariant) ??
          TextStyle(color: onSurfaceVariant, fontSize: 12),
      surahTileNameTextStyle:
          textTheme.titleSmall?.copyWith(
            color: onSurface,
            fontWeight: FontWeight.w700,
          ) ??
          TextStyle(
            color: onSurface,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
      surahTileMetaTextStyle:
          textTheme.labelSmall?.copyWith(color: onSurfaceVariant) ??
          TextStyle(color: onSurfaceVariant, fontSize: 11),
      surahTileArabicNameTextStyle:
          textTheme.titleMedium?.copyWith(
            color: primary,
            fontWeight: FontWeight.w800,
          ) ??
          TextStyle(color: primary, fontSize: 18, fontWeight: FontWeight.w800),
    );
  }

  @override
  QuranReaderTheme copyWith({
    Color? pageBackground,
    Color? textColor,
    Color? primaryColor,
    Color? headerBackground,
    Color? headerTextColor,
    ColorFilter? headerImageFilter,
    Color? systemBarColor,
    Brightness? statusBarIconBrightness,
    Brightness? statusBarBrightness,
    TextStyle? sliderRangeTextStyle,
    TextStyle? pillSurahTextStyle,
    TextStyle? pillPageTextStyle,
    TextStyle? cardPageBadgeTextStyle,
    TextStyle? cardContextSummaryTextStyle,
    TextStyle? indexTitleTextStyle,
    TextStyle? indexSubtitleTextStyle,
    TextStyle? surahTileNameTextStyle,
    TextStyle? surahTileMetaTextStyle,
    TextStyle? surahTileArabicNameTextStyle,
  }) {
    return QuranReaderTheme(
      pageBackground: pageBackground ?? this.pageBackground,
      textColor: textColor ?? this.textColor,
      primaryColor: primaryColor ?? this.primaryColor,
      headerBackground: headerBackground ?? this.headerBackground,
      headerTextColor: headerTextColor ?? this.headerTextColor,
      headerImageFilter: headerImageFilter ?? this.headerImageFilter,
      systemBarColor: systemBarColor ?? this.systemBarColor,
      statusBarIconBrightness:
          statusBarIconBrightness ?? this.statusBarIconBrightness,
      statusBarBrightness: statusBarBrightness ?? this.statusBarBrightness,
      sliderRangeTextStyle: sliderRangeTextStyle ?? this.sliderRangeTextStyle,
      pillSurahTextStyle: pillSurahTextStyle ?? this.pillSurahTextStyle,
      pillPageTextStyle: pillPageTextStyle ?? this.pillPageTextStyle,
      cardPageBadgeTextStyle:
          cardPageBadgeTextStyle ?? this.cardPageBadgeTextStyle,
      cardContextSummaryTextStyle:
          cardContextSummaryTextStyle ?? this.cardContextSummaryTextStyle,
      indexTitleTextStyle: indexTitleTextStyle ?? this.indexTitleTextStyle,
      indexSubtitleTextStyle:
          indexSubtitleTextStyle ?? this.indexSubtitleTextStyle,
      surahTileNameTextStyle:
          surahTileNameTextStyle ?? this.surahTileNameTextStyle,
      surahTileMetaTextStyle:
          surahTileMetaTextStyle ?? this.surahTileMetaTextStyle,
      surahTileArabicNameTextStyle:
          surahTileArabicNameTextStyle ?? this.surahTileArabicNameTextStyle,
    );
  }

  @override
  QuranReaderTheme lerp(covariant QuranReaderTheme? other, double t) {
    if (other == null) return this;
    return QuranReaderTheme(
      pageBackground: Color.lerp(pageBackground, other.pageBackground, t)!,
      textColor: Color.lerp(textColor, other.textColor, t)!,
      primaryColor: Color.lerp(primaryColor, other.primaryColor, t)!,
      headerBackground: Color.lerp(
        headerBackground,
        other.headerBackground,
        t,
      )!,
      headerTextColor: Color.lerp(headerTextColor, other.headerTextColor, t)!,
      headerImageFilter: t < 0.5 ? headerImageFilter : other.headerImageFilter,
      systemBarColor: Color.lerp(systemBarColor, other.systemBarColor, t)!,
      statusBarIconBrightness: t < 0.5
          ? statusBarIconBrightness
          : other.statusBarIconBrightness,
      statusBarBrightness: t < 0.5
          ? statusBarBrightness
          : other.statusBarBrightness,
      sliderRangeTextStyle: TextStyle.lerp(
        sliderRangeTextStyle,
        other.sliderRangeTextStyle,
        t,
      )!,
      pillSurahTextStyle: TextStyle.lerp(
        pillSurahTextStyle,
        other.pillSurahTextStyle,
        t,
      )!,
      pillPageTextStyle: TextStyle.lerp(
        pillPageTextStyle,
        other.pillPageTextStyle,
        t,
      )!,
      cardPageBadgeTextStyle: TextStyle.lerp(
        cardPageBadgeTextStyle,
        other.cardPageBadgeTextStyle,
        t,
      )!,
      cardContextSummaryTextStyle: TextStyle.lerp(
        cardContextSummaryTextStyle,
        other.cardContextSummaryTextStyle,
        t,
      )!,
      indexTitleTextStyle: TextStyle.lerp(
        indexTitleTextStyle,
        other.indexTitleTextStyle,
        t,
      )!,
      indexSubtitleTextStyle: TextStyle.lerp(
        indexSubtitleTextStyle,
        other.indexSubtitleTextStyle,
        t,
      )!,
      surahTileNameTextStyle: TextStyle.lerp(
        surahTileNameTextStyle,
        other.surahTileNameTextStyle,
        t,
      )!,
      surahTileMetaTextStyle: TextStyle.lerp(
        surahTileMetaTextStyle,
        other.surahTileMetaTextStyle,
        t,
      )!,
      surahTileArabicNameTextStyle: TextStyle.lerp(
        surahTileArabicNameTextStyle,
        other.surahTileArabicNameTextStyle,
        t,
      )!,
    );
  }
}

/// Theme extension for the Quran Reader Page Navigation Bar.
///
/// Contains all layout constants and decorative tokens to avoid magic numbers.
class PageNavigationBarTheme extends ThemeExtension<PageNavigationBarTheme> {
  const PageNavigationBarTheme({
    required this.barMarginHorizontal,
    required this.barMarginBottom,
    required this.barBorderRadius,
    required this.barPadding,
    required this.sliderSectionPadding,
    required this.sliderSectionRadius,
    required this.sliderThumbSize,
    required this.sliderRangeLabelWidth,
    required this.sliderRangeGap,
    required this.sliderHeight,
    required this.sliderStageHeight,
    required this.sliderTrackHeight,
    required this.sliderHandleBorderWidth,
    required this.previewPillMinWidth,
    required this.previewPillMaxWidthFactor,
    required this.previewPillTopOffset,
    required this.previewPillHorizontalPadding,
    required this.previewPillContentGap,
    required this.previewPillChipHorizontalPadding,
    required this.previewPillPadding,
    required this.previewPillRadius,
    required this.previewPillBorderAlphaLight,
    required this.previewPillBorderAlphaDark,
    required this.previewPillShadowAlphaLight,
    required this.previewPillShadowAlphaDark,
    required this.headerActionSize,
    required this.actionButtonRadius,
    required this.actionButtonIconSize,
    required this.actionButtonBgAlphaLight,
    required this.actionButtonBgAlphaDark,
    required this.actionButtonBorderAlphaLight,
    required this.actionButtonBorderAlphaDark,
    required this.badgePadding,
    required this.badgeRadius,
    required this.badgeBgAlphaLight,
    required this.badgeBgAlphaDark,
    required this.badgeBorderAlphaLight,
    required this.badgeBorderAlphaDark,
    required this.cardPadding,
    required this.cardRadius,
    required this.cardIconSize,
    required this.cardIconBgAlphaLight,
    required this.cardIconBgAlphaDark,
    required this.cardBorderAlpha,
    required this.cardShadowAlphaLight,
    required this.cardShadowAlphaDark,
    required this.pagePreviewDuration,
    required this.blurSigma,
  });

  final double barMarginHorizontal;
  final double barMarginBottom;
  final double barBorderRadius;
  final EdgeInsets barPadding;
  final EdgeInsets sliderSectionPadding;
  final double sliderSectionRadius;
  final double sliderThumbSize;
  final double sliderRangeLabelWidth;
  final double sliderRangeGap;
  final double sliderHeight;
  final double sliderStageHeight;
  final double sliderTrackHeight;
  final double sliderHandleBorderWidth;
  final double previewPillMinWidth;
  final double previewPillMaxWidthFactor;
  final double previewPillTopOffset;
  final double previewPillHorizontalPadding;
  final double previewPillContentGap;
  final double previewPillChipHorizontalPadding;
  final EdgeInsets previewPillPadding;
  final double previewPillRadius;
  final double previewPillBorderAlphaLight;
  final double previewPillBorderAlphaDark;
  final double previewPillShadowAlphaLight;
  final double previewPillShadowAlphaDark;
  final double headerActionSize;
  final double actionButtonRadius;
  final double actionButtonIconSize;
  final double actionButtonBgAlphaLight;
  final double actionButtonBgAlphaDark;
  final double actionButtonBorderAlphaLight;
  final double actionButtonBorderAlphaDark;
  final EdgeInsets badgePadding;
  final double badgeRadius;
  final double badgeBgAlphaLight;
  final double badgeBgAlphaDark;
  final double badgeBorderAlphaLight;
  final double badgeBorderAlphaDark;
  final EdgeInsets cardPadding;
  final double cardRadius;
  final double cardIconSize;
  final double cardIconBgAlphaLight;
  final double cardIconBgAlphaDark;
  final double cardBorderAlpha;
  final double cardShadowAlphaLight;
  final double cardShadowAlphaDark;
  final Duration pagePreviewDuration;
  final double blurSigma;

  static const PageNavigationBarTheme standard = PageNavigationBarTheme(
    barMarginHorizontal: 20.0,
    barMarginBottom: 16.0,
    barBorderRadius: 36.0,
    barPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    sliderSectionPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 8),
    sliderSectionRadius: 20.0,
    sliderThumbSize: 20.0,
    sliderRangeLabelWidth: 28.0,
    sliderRangeGap: 8.0,
    sliderHeight: 28.0,
    sliderStageHeight: 36.0,
    sliderTrackHeight: 4.0,
    sliderHandleBorderWidth: 2.0,
    previewPillMinWidth: 120.0,
    previewPillMaxWidthFactor: 0.85,
    previewPillTopOffset: 42.0,
    previewPillHorizontalPadding: 16.0,
    previewPillContentGap: 12.0,
    previewPillChipHorizontalPadding: 10.0,
    previewPillPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 8),
    previewPillRadius: 999.0,
    previewPillBorderAlphaLight: 0.2,
    previewPillBorderAlphaDark: 0.34,
    previewPillShadowAlphaLight: 0.12,
    previewPillShadowAlphaDark: 0.28,
    headerActionSize: 48.0,
    actionButtonRadius: 14.0,
    actionButtonIconSize: 20.0,
    actionButtonBgAlphaLight: 0.1,
    actionButtonBgAlphaDark: 0.16,
    actionButtonBorderAlphaLight: 0.12,
    actionButtonBorderAlphaDark: 0.18,
    badgePadding: EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    badgeRadius: 8.0,
    badgeBgAlphaLight: 0.1,
    badgeBgAlphaDark: 0.15,
    badgeBorderAlphaLight: 0.12,
    badgeBorderAlphaDark: 0.2,
    cardPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    cardRadius: 16.0,
    cardIconSize: 36.0,
    cardIconBgAlphaLight: 0.12,
    cardIconBgAlphaDark: 0.18,
    cardBorderAlpha: 0.7,
    cardShadowAlphaLight: 0.07,
    cardShadowAlphaDark: 0.2,
    pagePreviewDuration: Duration(milliseconds: 1100),
    blurSigma: 40.0,
  );

  static PageNavigationBarTheme of(BuildContext context) {
    return Theme.of(context).extension<PageNavigationBarTheme>() ?? standard;
  }

  @override
  PageNavigationBarTheme copyWith({
    double? barMarginHorizontal,
    double? barMarginBottom,
    double? barBorderRadius,
    EdgeInsets? barPadding,
    EdgeInsets? sliderSectionPadding,
    double? sliderSectionRadius,
    double? sliderThumbSize,
    double? sliderRangeLabelWidth,
    double? sliderRangeGap,
    double? sliderHeight,
    double? sliderStageHeight,
    double? sliderTrackHeight,
    double? sliderHandleBorderWidth,
    double? previewPillMinWidth,
    double? previewPillMaxWidthFactor,
    double? previewPillTopOffset,
    double? previewPillHorizontalPadding,
    double? previewPillContentGap,
    double? previewPillChipHorizontalPadding,
    EdgeInsets? previewPillPadding,
    double? previewPillRadius,
    double? previewPillBorderAlphaLight,
    double? previewPillBorderAlphaDark,
    double? previewPillShadowAlphaLight,
    double? previewPillShadowAlphaDark,
    double? headerActionSize,
    double? actionButtonRadius,
    double? actionButtonIconSize,
    double? actionButtonBgAlphaLight,
    double? actionButtonBgAlphaDark,
    double? actionButtonBorderAlphaLight,
    double? actionButtonBorderAlphaDark,
    EdgeInsets? badgePadding,
    double? badgeRadius,
    double? badgeBgAlphaLight,
    double? badgeBgAlphaDark,
    double? badgeBorderAlphaLight,
    double? badgeBorderAlphaDark,
    EdgeInsets? cardPadding,
    double? cardRadius,
    double? cardIconSize,
    double? cardIconBgAlphaLight,
    double? cardIconBgAlphaDark,
    double? cardBorderAlpha,
    double? cardShadowAlphaLight,
    double? cardShadowAlphaDark,
    Duration? pagePreviewDuration,
    double? blurSigma,
  }) {
    return PageNavigationBarTheme(
      barMarginHorizontal: barMarginHorizontal ?? this.barMarginHorizontal,
      barMarginBottom: barMarginBottom ?? this.barMarginBottom,
      barBorderRadius: barBorderRadius ?? this.barBorderRadius,
      barPadding: barPadding ?? this.barPadding,
      sliderSectionPadding: sliderSectionPadding ?? this.sliderSectionPadding,
      sliderSectionRadius: sliderSectionRadius ?? this.sliderSectionRadius,
      sliderThumbSize: sliderThumbSize ?? this.sliderThumbSize,
      sliderRangeLabelWidth:
          sliderRangeLabelWidth ?? this.sliderRangeLabelWidth,
      sliderRangeGap: sliderRangeGap ?? this.sliderRangeGap,
      sliderHeight: sliderHeight ?? this.sliderHeight,
      sliderStageHeight: sliderStageHeight ?? this.sliderStageHeight,
      sliderTrackHeight: sliderTrackHeight ?? this.sliderTrackHeight,
      sliderHandleBorderWidth:
          sliderHandleBorderWidth ?? this.sliderHandleBorderWidth,
      previewPillMinWidth: previewPillMinWidth ?? this.previewPillMinWidth,
      previewPillMaxWidthFactor:
          previewPillMaxWidthFactor ?? this.previewPillMaxWidthFactor,
      previewPillTopOffset: previewPillTopOffset ?? this.previewPillTopOffset,
      previewPillHorizontalPadding:
          previewPillHorizontalPadding ?? this.previewPillHorizontalPadding,
      previewPillContentGap:
          previewPillContentGap ?? this.previewPillContentGap,
      previewPillChipHorizontalPadding:
          previewPillChipHorizontalPadding ??
          this.previewPillChipHorizontalPadding,
      previewPillPadding: previewPillPadding ?? this.previewPillPadding,
      previewPillRadius: previewPillRadius ?? this.previewPillRadius,
      previewPillBorderAlphaLight:
          previewPillBorderAlphaLight ?? this.previewPillBorderAlphaLight,
      previewPillBorderAlphaDark:
          previewPillBorderAlphaDark ?? this.previewPillBorderAlphaDark,
      previewPillShadowAlphaLight:
          previewPillShadowAlphaLight ?? this.previewPillShadowAlphaLight,
      previewPillShadowAlphaDark:
          previewPillShadowAlphaDark ?? this.previewPillShadowAlphaDark,
      headerActionSize: headerActionSize ?? this.headerActionSize,
      actionButtonRadius: actionButtonRadius ?? this.actionButtonRadius,
      actionButtonIconSize: actionButtonIconSize ?? this.actionButtonIconSize,
      actionButtonBgAlphaLight:
          actionButtonBgAlphaLight ?? this.actionButtonBgAlphaLight,
      actionButtonBgAlphaDark:
          actionButtonBgAlphaDark ?? this.actionButtonBgAlphaDark,
      actionButtonBorderAlphaLight:
          actionButtonBorderAlphaLight ?? this.actionButtonBorderAlphaLight,
      actionButtonBorderAlphaDark:
          actionButtonBorderAlphaDark ?? this.actionButtonBorderAlphaDark,
      badgePadding: badgePadding ?? this.badgePadding,
      badgeRadius: badgeRadius ?? this.badgeRadius,
      badgeBgAlphaLight: badgeBgAlphaLight ?? this.badgeBgAlphaLight,
      badgeBgAlphaDark: badgeBgAlphaDark ?? this.badgeBgAlphaDark,
      badgeBorderAlphaLight:
          badgeBorderAlphaLight ?? this.badgeBorderAlphaLight,
      badgeBorderAlphaDark: badgeBorderAlphaDark ?? this.badgeBorderAlphaDark,
      cardPadding: cardPadding ?? this.cardPadding,
      cardRadius: cardRadius ?? this.cardRadius,
      cardIconSize: cardIconSize ?? this.cardIconSize,
      cardIconBgAlphaLight: cardIconBgAlphaLight ?? this.cardIconBgAlphaLight,
      cardIconBgAlphaDark: cardIconBgAlphaDark ?? this.cardIconBgAlphaDark,
      cardBorderAlpha: cardBorderAlpha ?? this.cardBorderAlpha,
      cardShadowAlphaLight: cardShadowAlphaLight ?? this.cardShadowAlphaLight,
      cardShadowAlphaDark: cardShadowAlphaDark ?? this.cardShadowAlphaDark,
      pagePreviewDuration: pagePreviewDuration ?? this.pagePreviewDuration,
      blurSigma: blurSigma ?? this.blurSigma,
    );
  }

  @override
  PageNavigationBarTheme lerp(
    covariant ThemeExtension<PageNavigationBarTheme>? other,
    double t,
  ) {
    if (other is! PageNavigationBarTheme) return this;
    return PageNavigationBarTheme(
      barMarginHorizontal: lerpDouble(
        barMarginHorizontal,
        other.barMarginHorizontal,
        t,
      )!,
      barMarginBottom: lerpDouble(barMarginBottom, other.barMarginBottom, t)!,
      barBorderRadius: lerpDouble(barBorderRadius, other.barBorderRadius, t)!,
      barPadding: EdgeInsets.lerp(barPadding, other.barPadding, t)!,
      sliderSectionPadding: EdgeInsets.lerp(
        sliderSectionPadding,
        other.sliderSectionPadding,
        t,
      )!,
      sliderSectionRadius: lerpDouble(
        sliderSectionRadius,
        other.sliderSectionRadius,
        t,
      )!,
      sliderThumbSize: lerpDouble(sliderThumbSize, other.sliderThumbSize, t)!,
      sliderRangeLabelWidth: lerpDouble(
        sliderRangeLabelWidth,
        other.sliderRangeLabelWidth,
        t,
      )!,
      sliderRangeGap: lerpDouble(sliderRangeGap, other.sliderRangeGap, t)!,
      sliderHeight: lerpDouble(sliderHeight, other.sliderHeight, t)!,
      sliderStageHeight: lerpDouble(
        sliderStageHeight,
        other.sliderStageHeight,
        t,
      )!,
      sliderTrackHeight: lerpDouble(
        sliderTrackHeight,
        other.sliderTrackHeight,
        t,
      )!,
      sliderHandleBorderWidth: lerpDouble(
        sliderHandleBorderWidth,
        other.sliderHandleBorderWidth,
        t,
      )!,
      previewPillMinWidth: lerpDouble(
        previewPillMinWidth,
        other.previewPillMinWidth,
        t,
      )!,
      previewPillMaxWidthFactor: lerpDouble(
        previewPillMaxWidthFactor,
        other.previewPillMaxWidthFactor,
        t,
      )!,
      previewPillTopOffset: lerpDouble(
        previewPillTopOffset,
        other.previewPillTopOffset,
        t,
      )!,
      previewPillHorizontalPadding: lerpDouble(
        previewPillHorizontalPadding,
        other.previewPillHorizontalPadding,
        t,
      )!,
      previewPillContentGap: lerpDouble(
        previewPillContentGap,
        other.previewPillContentGap,
        t,
      )!,
      previewPillChipHorizontalPadding: lerpDouble(
        previewPillChipHorizontalPadding,
        other.previewPillChipHorizontalPadding,
        t,
      )!,
      previewPillPadding: EdgeInsets.lerp(
        previewPillPadding,
        other.previewPillPadding,
        t,
      )!,
      previewPillRadius: lerpDouble(
        previewPillRadius,
        other.previewPillRadius,
        t,
      )!,
      previewPillBorderAlphaLight: lerpDouble(
        previewPillBorderAlphaLight,
        other.previewPillBorderAlphaLight,
        t,
      )!,
      previewPillBorderAlphaDark: lerpDouble(
        previewPillBorderAlphaDark,
        other.previewPillBorderAlphaDark,
        t,
      )!,
      previewPillShadowAlphaLight: lerpDouble(
        previewPillShadowAlphaLight,
        other.previewPillShadowAlphaLight,
        t,
      )!,
      previewPillShadowAlphaDark: lerpDouble(
        previewPillShadowAlphaDark,
        other.previewPillShadowAlphaDark,
        t,
      )!,
      headerActionSize: lerpDouble(
        headerActionSize,
        other.headerActionSize,
        t,
      )!,
      actionButtonRadius: lerpDouble(
        actionButtonRadius,
        other.actionButtonRadius,
        t,
      )!,
      actionButtonIconSize: lerpDouble(
        actionButtonIconSize,
        other.actionButtonIconSize,
        t,
      )!,
      actionButtonBgAlphaLight: lerpDouble(
        actionButtonBgAlphaLight,
        other.actionButtonBgAlphaLight,
        t,
      )!,
      actionButtonBgAlphaDark: lerpDouble(
        actionButtonBgAlphaDark,
        other.actionButtonBgAlphaDark,
        t,
      )!,
      actionButtonBorderAlphaLight: lerpDouble(
        actionButtonBorderAlphaLight,
        other.actionButtonBorderAlphaLight,
        t,
      )!,
      actionButtonBorderAlphaDark: lerpDouble(
        actionButtonBorderAlphaDark,
        other.actionButtonBorderAlphaDark,
        t,
      )!,
      badgePadding: EdgeInsets.lerp(badgePadding, other.badgePadding, t)!,
      badgeRadius: lerpDouble(badgeRadius, other.badgeRadius, t)!,
      badgeBgAlphaLight: lerpDouble(
        badgeBgAlphaLight,
        other.badgeBgAlphaLight,
        t,
      )!,
      badgeBgAlphaDark: lerpDouble(
        badgeBgAlphaDark,
        other.badgeBgAlphaDark,
        t,
      )!,
      badgeBorderAlphaLight: lerpDouble(
        badgeBorderAlphaLight,
        other.badgeBorderAlphaLight,
        t,
      )!,
      badgeBorderAlphaDark: lerpDouble(
        badgeBorderAlphaDark,
        other.badgeBorderAlphaDark,
        t,
      )!,
      cardPadding: EdgeInsets.lerp(cardPadding, other.cardPadding, t)!,
      cardRadius: lerpDouble(cardRadius, other.cardRadius, t)!,
      cardIconSize: lerpDouble(cardIconSize, other.cardIconSize, t)!,
      cardIconBgAlphaLight: lerpDouble(
        cardIconBgAlphaLight,
        other.cardIconBgAlphaLight,
        t,
      )!,
      cardIconBgAlphaDark: lerpDouble(
        cardIconBgAlphaDark,
        other.cardIconBgAlphaDark,
        t,
      )!,
      cardBorderAlpha: lerpDouble(cardBorderAlpha, other.cardBorderAlpha, t)!,
      cardShadowAlphaLight: lerpDouble(
        cardShadowAlphaLight,
        other.cardShadowAlphaLight,
        t,
      )!,
      cardShadowAlphaDark: lerpDouble(
        cardShadowAlphaDark,
        other.cardShadowAlphaDark,
        t,
      )!,
      pagePreviewDuration: t < 0.5
          ? pagePreviewDuration
          : other.pagePreviewDuration,
      blurSigma: lerpDouble(blurSigma, other.blurSigma, t)!,
    );
  }

  double? lerpDouble(num? a, num? b, double t) {
    if (a == null && b == null) return null;
    return (a ?? 0) + ((b ?? 0) - (a ?? 0)) * t;
  }
}

/// Theme extension for the Quran Reader Surah Index Sheet.
class SurahIndexTheme extends ThemeExtension<SurahIndexTheme> {
  const SurahIndexTheme({
    required this.sheetRadius,
    required this.sheetPadding,
    required this.dragHandleWidth,
    required this.dragHandleHeight,
    required this.dragHandleRadius,
    required this.headerIconSize,
    required this.headerIconPadding,
    required this.headerIconRadius,
    required this.searchBarRadius,
    required this.searchBarBorderWidth,
    required this.searchBarIconSize,
    required this.searchBarVerticalPadding,
    required this.tilePadding,
    required this.tileRadius,
    required this.tileBorderWidth,
    required this.tileNumberSize,
    required this.tileNumberRadius,
    required this.tileNumberFontSize,
    required this.tileArabicNameSize,
    required this.tileMetaFontSize,
  });

  final double sheetRadius;
  final EdgeInsets sheetPadding;
  final double dragHandleWidth;
  final double dragHandleHeight;
  final double dragHandleRadius;
  final double headerIconSize;
  final double headerIconPadding;
  final double headerIconRadius;
  final double searchBarRadius;
  final double searchBarBorderWidth;
  final double searchBarIconSize;
  final double searchBarVerticalPadding;
  final EdgeInsets tilePadding;
  final double tileRadius;
  final double tileBorderWidth;
  final double tileNumberSize;
  final double tileNumberRadius;
  final double tileNumberFontSize;
  final double tileArabicNameSize;
  final double tileMetaFontSize;

  static const SurahIndexTheme standard = SurahIndexTheme(
    sheetRadius: 24.0,
    sheetPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
    dragHandleWidth: 40.0,
    dragHandleHeight: 4.0,
    dragHandleRadius: 2.0,
    headerIconSize: 24.0,
    headerIconPadding: 8.0,
    headerIconRadius: 12.0,
    searchBarRadius: 14.0,
    searchBarBorderWidth: 0.8,
    searchBarIconSize: 20.0,
    searchBarVerticalPadding: 10.0,
    tilePadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    tileRadius: 14.0,
    tileBorderWidth: 0.6,
    tileNumberSize: 40.0,
    tileNumberRadius: 10.0,
    tileNumberFontSize: 13.0,
    tileArabicNameSize: 18.0,
    tileMetaFontSize: 11.0,
  );

  static SurahIndexTheme of(BuildContext context) {
    return Theme.of(context).extension<SurahIndexTheme>() ?? standard;
  }

  @override
  SurahIndexTheme copyWith({
    double? sheetRadius,
    EdgeInsets? sheetPadding,
    double? dragHandleWidth,
    double? dragHandleHeight,
    double? dragHandleRadius,
    double? headerIconSize,
    double? headerIconPadding,
    double? headerIconRadius,
    double? searchBarRadius,
    double? searchBarBorderWidth,
    double? searchBarIconSize,
    double? searchBarVerticalPadding,
    EdgeInsets? tilePadding,
    double? tileRadius,
    double? tileBorderWidth,
    double? tileNumberSize,
    double? tileNumberRadius,
    double? tileNumberFontSize,
    double? tileArabicNameSize,
    double? tileMetaFontSize,
  }) {
    return SurahIndexTheme(
      sheetRadius: sheetRadius ?? this.sheetRadius,
      sheetPadding: sheetPadding ?? this.sheetPadding,
      dragHandleWidth: dragHandleWidth ?? this.dragHandleWidth,
      dragHandleHeight: dragHandleHeight ?? this.dragHandleHeight,
      dragHandleRadius: dragHandleRadius ?? this.dragHandleRadius,
      headerIconSize: headerIconSize ?? this.headerIconSize,
      headerIconPadding: headerIconPadding ?? this.headerIconPadding,
      headerIconRadius: headerIconRadius ?? this.headerIconRadius,
      searchBarRadius: searchBarRadius ?? this.searchBarRadius,
      searchBarBorderWidth: searchBarBorderWidth ?? this.searchBarBorderWidth,
      searchBarIconSize: searchBarIconSize ?? this.searchBarIconSize,
      searchBarVerticalPadding:
          searchBarVerticalPadding ?? this.searchBarVerticalPadding,
      tilePadding: tilePadding ?? this.tilePadding,
      tileRadius: tileRadius ?? this.tileRadius,
      tileBorderWidth: tileBorderWidth ?? this.tileBorderWidth,
      tileNumberSize: tileNumberSize ?? this.tileNumberSize,
      tileNumberRadius: tileNumberRadius ?? this.tileNumberRadius,
      tileNumberFontSize: tileNumberFontSize ?? this.tileNumberFontSize,
      tileArabicNameSize: tileArabicNameSize ?? this.tileArabicNameSize,
      tileMetaFontSize: tileMetaFontSize ?? this.tileMetaFontSize,
    );
  }

  @override
  SurahIndexTheme lerp(
    covariant ThemeExtension<SurahIndexTheme>? other,
    double t,
  ) {
    if (other is! SurahIndexTheme) return this;
    return SurahIndexTheme(
      sheetRadius: lerpDouble(sheetRadius, other.sheetRadius, t)!,
      sheetPadding: EdgeInsets.lerp(sheetPadding, other.sheetPadding, t)!,
      dragHandleWidth: lerpDouble(dragHandleWidth, other.dragHandleWidth, t)!,
      dragHandleHeight: lerpDouble(
        dragHandleHeight,
        other.dragHandleHeight,
        t,
      )!,
      dragHandleRadius: lerpDouble(
        dragHandleRadius,
        other.dragHandleRadius,
        t,
      )!,
      headerIconSize: lerpDouble(headerIconSize, other.headerIconSize, t)!,
      headerIconPadding: lerpDouble(
        headerIconPadding,
        other.headerIconPadding,
        t,
      )!,
      headerIconRadius: lerpDouble(
        headerIconRadius,
        other.headerIconRadius,
        t,
      )!,
      searchBarRadius: lerpDouble(searchBarRadius, other.searchBarRadius, t)!,
      searchBarBorderWidth: lerpDouble(
        searchBarBorderWidth,
        other.searchBarBorderWidth,
        t,
      )!,
      searchBarIconSize: lerpDouble(
        searchBarIconSize,
        other.searchBarIconSize,
        t,
      )!,
      searchBarVerticalPadding: lerpDouble(
        searchBarVerticalPadding,
        other.searchBarVerticalPadding,
        t,
      )!,
      tilePadding: EdgeInsets.lerp(tilePadding, other.tilePadding, t)!,
      tileRadius: lerpDouble(tileRadius, other.tileRadius, t)!,
      tileBorderWidth: lerpDouble(tileBorderWidth, other.tileBorderWidth, t)!,
      tileNumberSize: lerpDouble(tileNumberSize, other.tileNumberSize, t)!,
      tileNumberRadius: lerpDouble(
        tileNumberRadius,
        other.tileNumberRadius,
        t,
      )!,
      tileNumberFontSize: lerpDouble(
        tileNumberFontSize,
        other.tileNumberFontSize,
        t,
      )!,
      tileArabicNameSize: lerpDouble(
        tileArabicNameSize,
        other.tileArabicNameSize,
        t,
      )!,
      tileMetaFontSize: lerpDouble(
        tileMetaFontSize,
        other.tileMetaFontSize,
        t,
      )!,
    );
  }

  double? lerpDouble(num? a, num? b, double t) {
    if (a == null && b == null) return null;
    return (a ?? 0) + ((b ?? 0) - (a ?? 0)) * t;
  }
}
