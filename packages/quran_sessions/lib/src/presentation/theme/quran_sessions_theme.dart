import 'package:flutter/material.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import 'quran_sessions_palette.dart';

/// Feature-scoped visual tokens for the Quran Tutor / Sessions learning module.
///
/// Colors and typography are derived from the parent app [ThemeData] so the
/// module matches the active MeMuslim theme while keeping compact tutoring
/// layout tokens (spacing, radius, shadows).
@immutable
class QuranSessionsTheme extends ThemeExtension<QuranSessionsTheme> {
  const QuranSessionsTheme({
    required this.primaryColor,
    required this.onPrimaryColor,
    required this.linkColor,
    required this.scaffoldBackground,
    required this.cardBackground,
    required this.cardBorderColor,
    required this.filterTrackColor,
    required this.filterSelectedBackground,
    required this.filterSelectedForeground,
    required this.filterUnselectedForeground,
    required this.accentSoftBackground,
    required this.highlightBorderColor,
    required this.ratingColor,
    required this.helperTextColor,
    required this.statusScheduledBackground,
    required this.statusScheduledForeground,
    required this.destructive,
    required this.destructiveSoft,
    required this.onDestructive,
    required this.disabledBackground,
    required this.disabledForeground,
    required this.disabledBorder,
    required this.success,
    required this.warning,
    required this.info,
    required this.upcomingStatus,
    required this.completedStatus,
    required this.cancelledStatus,
    required this.missedStatus,
    required this.joinAvailable,
    required this.joinUnavailable,
    required this.screenPaddingHorizontal,
    required this.cardPadding,
    required this.cardGap,
    required this.listItemGap,
    required this.sectionGap,
    required this.filterBarHeight,
    required this.cardRadius,
    required this.chipRadius,
    required this.dateChipRadius,
    required this.segmentedRadius,
    required this.profileAvatarRadius,
    required this.listAvatarRadius,
    required this.cardShadow,
    required this.elevatedCardShadow,
    required this.screenTitleStyle,
    required this.screenSubtitleStyle,
    required this.cardTitleStyle,
    required this.cardMetaStyle,
    required this.chipLabelStyle,
    required this.priceBadgeStyle,
    required this.summaryLabelStyle,
    required this.sectionTitleStyle,
  });

  final Color primaryColor;
  final Color onPrimaryColor;
  final Color linkColor;
  final Color scaffoldBackground;
  final Color cardBackground;
  final Color cardBorderColor;
  final Color filterTrackColor;
  final Color filterSelectedBackground;
  final Color filterSelectedForeground;
  final Color filterUnselectedForeground;
  final Color accentSoftBackground;
  final Color highlightBorderColor;
  final Color ratingColor;
  final Color helperTextColor;
  final Color statusScheduledBackground;
  final Color statusScheduledForeground;
  final Color destructive;
  final Color destructiveSoft;
  final Color onDestructive;
  final Color disabledBackground;
  final Color disabledForeground;
  final Color disabledBorder;
  final Color success;
  final Color warning;
  final Color info;
  final Color upcomingStatus;
  final Color completedStatus;
  final Color cancelledStatus;
  final Color missedStatus;
  final Color joinAvailable;
  final Color joinUnavailable;

  final double screenPaddingHorizontal;
  final double cardPadding;
  final double cardGap;
  final double listItemGap;
  final double sectionGap;
  final double filterBarHeight;

  final double cardRadius;
  final double chipRadius;
  final double dateChipRadius;
  final double segmentedRadius;
  final double profileAvatarRadius;
  final double listAvatarRadius;

  final List<BoxShadow> cardShadow;
  final List<BoxShadow> elevatedCardShadow;

  final TextStyle screenTitleStyle;
  final TextStyle screenSubtitleStyle;
  final TextStyle cardTitleStyle;
  final TextStyle cardMetaStyle;
  final TextStyle chipLabelStyle;
  final TextStyle priceBadgeStyle;
  final TextStyle summaryLabelStyle;
  final TextStyle sectionTitleStyle;

  static QuranSessionsTheme of(BuildContext context) {
    final theme = Theme.of(context);
    return theme.extension<QuranSessionsTheme>() ?? fromTheme(theme);
  }

  static QuranSessionsTheme fromTheme(ThemeData theme) {
    final scheme = theme.colorScheme;
    final palette = QuranSessionsPalette.fromScheme(scheme);
    final tokens = theme.tokens;
    final textTheme = theme.textTheme;
    final shadowBase = scheme.shadow.withValues(alpha: tokens.opacityShadow);

    final cardShadow = [
      BoxShadow(
        color: shadowBase,
        blurRadius: tokens.blurShadow,
        offset: tokens.shadowOffsetSmall,
      ),
    ];
    final elevatedCardShadow = [
      BoxShadow(
        color: scheme.shadow.withValues(alpha: tokens.opacityShadowStrong),
        blurRadius: tokens.blurShadow + 4,
        offset: tokens.shadowOffsetMedium,
      ),
    ];

    return QuranSessionsTheme(
      primaryColor: palette.primary,
      onPrimaryColor: palette.onPrimary,
      linkColor: palette.link,
      scaffoldBackground: palette.canvas,
      cardBackground: palette.card,
      cardBorderColor: palette.border.withValues(
        alpha: tokens.opacityEmphasis,
      ),
      filterTrackColor: palette.chipIdle,
      filterSelectedBackground: palette.primary,
      filterSelectedForeground: palette.onPrimary,
      filterUnselectedForeground: palette.textSecondary,
      accentSoftBackground: palette.accentSoft,
      highlightBorderColor: palette.primary.withValues(alpha: 0.35),
      ratingColor: palette.rating,
      helperTextColor: palette.textSecondary,
      statusScheduledBackground: palette.statusBackground,
      statusScheduledForeground: palette.statusForeground,
      destructive: palette.destructive,
      destructiveSoft: palette.destructiveSoft,
      onDestructive: palette.onDestructive,
      disabledBackground: palette.disabledBackground,
      disabledForeground: palette.disabledForeground,
      disabledBorder: palette.disabledBorder,
      success: palette.success,
      warning: palette.warning,
      info: palette.info,
      upcomingStatus: palette.primary,
      completedStatus: palette.success,
      cancelledStatus: palette.destructive,
      missedStatus: palette.warning,
      joinAvailable: palette.primary,
      joinUnavailable: palette.disabledForeground,
      screenPaddingHorizontal: tokens.spaceMedium,
      cardPadding: tokens.spaceSmall,
      cardGap: tokens.spaceSmall,
      listItemGap: tokens.spaceExtraSmall,
      sectionGap: tokens.spaceSmall,
      filterBarHeight: tokens.minInteractiveDimension * 0.8,
      cardRadius: tokens.radiusCard,
      chipRadius: tokens.resolveRadius(family: TilawaRadiusFamily.pill),
      dateChipRadius: tokens.resolveRadius(family: TilawaRadiusFamily.chip),
      segmentedRadius: tokens.resolveRadius(family: TilawaRadiusFamily.chrome),
      profileAvatarRadius: tokens.iconSizeLarge,
      listAvatarRadius: tokens.iconSizeSmall + 2,
      cardShadow: cardShadow,
      elevatedCardShadow: elevatedCardShadow,
      screenTitleStyle:
          textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
            color: scheme.onSurface,
          ) ??
          TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: scheme.onSurface,
          ),
      screenSubtitleStyle:
          textTheme.bodyMedium?.copyWith(
            color: scheme.onSurfaceVariant,
            height: 1.35,
          ) ??
          TextStyle(color: scheme.onSurfaceVariant, fontSize: 14, height: 1.35),
      cardTitleStyle:
          textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: scheme.onSurface,
          ) ??
          TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: scheme.onSurface,
          ),
      cardMetaStyle:
          textTheme.bodySmall?.copyWith(
            color: scheme.onSurfaceVariant,
            height: 1.3,
          ) ??
          TextStyle(color: scheme.onSurfaceVariant, fontSize: 12, height: 1.3),
      chipLabelStyle:
          textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w600) ??
          const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
      priceBadgeStyle:
          textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w700) ??
          const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
      summaryLabelStyle:
          textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w600) ??
          const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
      sectionTitleStyle:
          textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: scheme.onSurface,
          ) ??
          TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: scheme.onSurface,
          ),
    );
  }

  EdgeInsets get screenPadding =>
      EdgeInsets.symmetric(horizontal: screenPaddingHorizontal);

  EdgeInsets cardPaddingInsets([double? vertical]) => EdgeInsets.symmetric(
    horizontal: screenPaddingHorizontal,
    vertical: vertical ?? listItemGap,
  );

  @override
  QuranSessionsTheme copyWith({
    Color? primaryColor,
    Color? onPrimaryColor,
    Color? linkColor,
    Color? scaffoldBackground,
    Color? cardBackground,
    Color? cardBorderColor,
    Color? filterTrackColor,
    Color? filterSelectedBackground,
    Color? filterSelectedForeground,
    Color? filterUnselectedForeground,
    Color? accentSoftBackground,
    Color? highlightBorderColor,
    Color? ratingColor,
    Color? helperTextColor,
    Color? statusScheduledBackground,
    Color? statusScheduledForeground,
    Color? destructive,
    Color? destructiveSoft,
    Color? onDestructive,
    Color? disabledBackground,
    Color? disabledForeground,
    Color? disabledBorder,
    Color? success,
    Color? warning,
    Color? info,
    Color? upcomingStatus,
    Color? completedStatus,
    Color? cancelledStatus,
    Color? missedStatus,
    Color? joinAvailable,
    Color? joinUnavailable,
    double? screenPaddingHorizontal,
    double? cardPadding,
    double? cardGap,
    double? listItemGap,
    double? sectionGap,
    double? filterBarHeight,
    double? cardRadius,
    double? chipRadius,
    double? dateChipRadius,
    double? segmentedRadius,
    double? profileAvatarRadius,
    double? listAvatarRadius,
    List<BoxShadow>? cardShadow,
    List<BoxShadow>? elevatedCardShadow,
    TextStyle? screenTitleStyle,
    TextStyle? screenSubtitleStyle,
    TextStyle? cardTitleStyle,
    TextStyle? cardMetaStyle,
    TextStyle? chipLabelStyle,
    TextStyle? priceBadgeStyle,
    TextStyle? summaryLabelStyle,
    TextStyle? sectionTitleStyle,
  }) {
    return QuranSessionsTheme(
      primaryColor: primaryColor ?? this.primaryColor,
      onPrimaryColor: onPrimaryColor ?? this.onPrimaryColor,
      linkColor: linkColor ?? this.linkColor,
      scaffoldBackground: scaffoldBackground ?? this.scaffoldBackground,
      cardBackground: cardBackground ?? this.cardBackground,
      cardBorderColor: cardBorderColor ?? this.cardBorderColor,
      filterTrackColor: filterTrackColor ?? this.filterTrackColor,
      filterSelectedBackground:
          filterSelectedBackground ?? this.filterSelectedBackground,
      filterSelectedForeground:
          filterSelectedForeground ?? this.filterSelectedForeground,
      filterUnselectedForeground:
          filterUnselectedForeground ?? this.filterUnselectedForeground,
      accentSoftBackground: accentSoftBackground ?? this.accentSoftBackground,
      highlightBorderColor: highlightBorderColor ?? this.highlightBorderColor,
      ratingColor: ratingColor ?? this.ratingColor,
      helperTextColor: helperTextColor ?? this.helperTextColor,
      statusScheduledBackground:
          statusScheduledBackground ?? this.statusScheduledBackground,
      statusScheduledForeground:
          statusScheduledForeground ?? this.statusScheduledForeground,
      destructive: destructive ?? this.destructive,
      destructiveSoft: destructiveSoft ?? this.destructiveSoft,
      onDestructive: onDestructive ?? this.onDestructive,
      disabledBackground: disabledBackground ?? this.disabledBackground,
      disabledForeground: disabledForeground ?? this.disabledForeground,
      disabledBorder: disabledBorder ?? this.disabledBorder,
      success: success ?? this.success,
      warning: warning ?? this.warning,
      info: info ?? this.info,
      upcomingStatus: upcomingStatus ?? this.upcomingStatus,
      completedStatus: completedStatus ?? this.completedStatus,
      cancelledStatus: cancelledStatus ?? this.cancelledStatus,
      missedStatus: missedStatus ?? this.missedStatus,
      joinAvailable: joinAvailable ?? this.joinAvailable,
      joinUnavailable: joinUnavailable ?? this.joinUnavailable,
      screenPaddingHorizontal:
          screenPaddingHorizontal ?? this.screenPaddingHorizontal,
      cardPadding: cardPadding ?? this.cardPadding,
      cardGap: cardGap ?? this.cardGap,
      listItemGap: listItemGap ?? this.listItemGap,
      sectionGap: sectionGap ?? this.sectionGap,
      filterBarHeight: filterBarHeight ?? this.filterBarHeight,
      cardRadius: cardRadius ?? this.cardRadius,
      chipRadius: chipRadius ?? this.chipRadius,
      dateChipRadius: dateChipRadius ?? this.dateChipRadius,
      segmentedRadius: segmentedRadius ?? this.segmentedRadius,
      profileAvatarRadius: profileAvatarRadius ?? this.profileAvatarRadius,
      listAvatarRadius: listAvatarRadius ?? this.listAvatarRadius,
      cardShadow: cardShadow ?? this.cardShadow,
      elevatedCardShadow: elevatedCardShadow ?? this.elevatedCardShadow,
      screenTitleStyle: screenTitleStyle ?? this.screenTitleStyle,
      screenSubtitleStyle: screenSubtitleStyle ?? this.screenSubtitleStyle,
      cardTitleStyle: cardTitleStyle ?? this.cardTitleStyle,
      cardMetaStyle: cardMetaStyle ?? this.cardMetaStyle,
      chipLabelStyle: chipLabelStyle ?? this.chipLabelStyle,
      priceBadgeStyle: priceBadgeStyle ?? this.priceBadgeStyle,
      summaryLabelStyle: summaryLabelStyle ?? this.summaryLabelStyle,
      sectionTitleStyle: sectionTitleStyle ?? this.sectionTitleStyle,
    );
  }

  @override
  QuranSessionsTheme lerp(covariant QuranSessionsTheme? other, double t) {
    if (other == null) return this;
    return QuranSessionsTheme(
      primaryColor: Color.lerp(primaryColor, other.primaryColor, t)!,
      onPrimaryColor: Color.lerp(onPrimaryColor, other.onPrimaryColor, t)!,
      linkColor: Color.lerp(linkColor, other.linkColor, t)!,
      scaffoldBackground: Color.lerp(
        scaffoldBackground,
        other.scaffoldBackground,
        t,
      )!,
      cardBackground: Color.lerp(cardBackground, other.cardBackground, t)!,
      cardBorderColor: Color.lerp(cardBorderColor, other.cardBorderColor, t)!,
      filterTrackColor: Color.lerp(
        filterTrackColor,
        other.filterTrackColor,
        t,
      )!,
      filterSelectedBackground: Color.lerp(
        filterSelectedBackground,
        other.filterSelectedBackground,
        t,
      )!,
      filterSelectedForeground: Color.lerp(
        filterSelectedForeground,
        other.filterSelectedForeground,
        t,
      )!,
      filterUnselectedForeground: Color.lerp(
        filterUnselectedForeground,
        other.filterUnselectedForeground,
        t,
      )!,
      accentSoftBackground: Color.lerp(
        accentSoftBackground,
        other.accentSoftBackground,
        t,
      )!,
      highlightBorderColor: Color.lerp(
        highlightBorderColor,
        other.highlightBorderColor,
        t,
      )!,
      ratingColor: Color.lerp(ratingColor, other.ratingColor, t)!,
      helperTextColor: Color.lerp(helperTextColor, other.helperTextColor, t)!,
      statusScheduledBackground: Color.lerp(
        statusScheduledBackground,
        other.statusScheduledBackground,
        t,
      )!,
      statusScheduledForeground: Color.lerp(
        statusScheduledForeground,
        other.statusScheduledForeground,
        t,
      )!,
      destructive: Color.lerp(destructive, other.destructive, t)!,
      destructiveSoft: Color.lerp(destructiveSoft, other.destructiveSoft, t)!,
      onDestructive: Color.lerp(onDestructive, other.onDestructive, t)!,
      disabledBackground: Color.lerp(
        disabledBackground,
        other.disabledBackground,
        t,
      )!,
      disabledForeground: Color.lerp(
        disabledForeground,
        other.disabledForeground,
        t,
      )!,
      disabledBorder: Color.lerp(disabledBorder, other.disabledBorder, t)!,
      success: Color.lerp(success, other.success, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      info: Color.lerp(info, other.info, t)!,
      upcomingStatus: Color.lerp(upcomingStatus, other.upcomingStatus, t)!,
      completedStatus: Color.lerp(completedStatus, other.completedStatus, t)!,
      cancelledStatus: Color.lerp(cancelledStatus, other.cancelledStatus, t)!,
      missedStatus: Color.lerp(missedStatus, other.missedStatus, t)!,
      joinAvailable: Color.lerp(joinAvailable, other.joinAvailable, t)!,
      joinUnavailable: Color.lerp(joinUnavailable, other.joinUnavailable, t)!,
      screenPaddingHorizontal: _lerpDouble(
        screenPaddingHorizontal,
        other.screenPaddingHorizontal,
        t,
      ),
      cardPadding: _lerpDouble(cardPadding, other.cardPadding, t),
      cardGap: _lerpDouble(cardGap, other.cardGap, t),
      listItemGap: _lerpDouble(listItemGap, other.listItemGap, t),
      sectionGap: _lerpDouble(sectionGap, other.sectionGap, t),
      filterBarHeight: _lerpDouble(filterBarHeight, other.filterBarHeight, t),
      cardRadius: _lerpDouble(cardRadius, other.cardRadius, t),
      chipRadius: _lerpDouble(chipRadius, other.chipRadius, t),
      dateChipRadius: _lerpDouble(dateChipRadius, other.dateChipRadius, t),
      segmentedRadius: _lerpDouble(segmentedRadius, other.segmentedRadius, t),
      profileAvatarRadius: _lerpDouble(
        profileAvatarRadius,
        other.profileAvatarRadius,
        t,
      ),
      listAvatarRadius: _lerpDouble(
        listAvatarRadius,
        other.listAvatarRadius,
        t,
      ),
      cardShadow: t < 0.5 ? cardShadow : other.cardShadow,
      elevatedCardShadow: t < 0.5
          ? elevatedCardShadow
          : other.elevatedCardShadow,
      screenTitleStyle: TextStyle.lerp(
        screenTitleStyle,
        other.screenTitleStyle,
        t,
      )!,
      screenSubtitleStyle: TextStyle.lerp(
        screenSubtitleStyle,
        other.screenSubtitleStyle,
        t,
      )!,
      cardTitleStyle: TextStyle.lerp(cardTitleStyle, other.cardTitleStyle, t)!,
      cardMetaStyle: TextStyle.lerp(cardMetaStyle, other.cardMetaStyle, t)!,
      chipLabelStyle: TextStyle.lerp(chipLabelStyle, other.chipLabelStyle, t)!,
      priceBadgeStyle: TextStyle.lerp(
        priceBadgeStyle,
        other.priceBadgeStyle,
        t,
      )!,
      summaryLabelStyle: TextStyle.lerp(
        summaryLabelStyle,
        other.summaryLabelStyle,
        t,
      )!,
      sectionTitleStyle: TextStyle.lerp(
        sectionTitleStyle,
        other.sectionTitleStyle,
        t,
      )!,
    );
  }

  static double _lerpDouble(double a, double b, double t) => a + (b - a) * t;
}

extension QuranSessionsThemeX on BuildContext {
  QuranSessionsTheme get quranSessionsTheme => QuranSessionsTheme.of(this);
}
