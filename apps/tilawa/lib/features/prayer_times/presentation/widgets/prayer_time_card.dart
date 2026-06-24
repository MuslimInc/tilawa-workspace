import 'package:flutter/material.dart';
import 'package:tilawa/core/extensions.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import '../../domain/entities/entities.dart';
import '../extensions/prayer_type_ui.dart';
import '../formatters/prayer_time_label_formatter.dart';
import 'prayer_time_localizations.dart';

/// A card displaying a specific prayer time with status and supporting info.
///
/// Follows Atomic Design by decomposing into atoms: icon, status chip, labels.
class PrayerTimeCard extends StatelessWidget {
  const PrayerTimeCard({
    super.key,
    required this.prayer,
    this.isNext = false,
    this.hasPassed = false,
    this.use24HourFormat = true,
  });

  final PrayerTimeItem prayer;
  final bool isNext;
  final bool hasPassed;
  final bool use24HourFormat;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.tokens;
    final colorScheme = theme.colorScheme;
    final product = theme.productColors;

    return LayoutBuilder(
      builder: (context, constraints) {
        // When the card is narrow or short, use tighter typography and icon size.
        final bool narrowTile =
            constraints.maxWidth < tokens.narrowCardWidthThreshold ||
            constraints.maxHeight < tokens.narrowCardHeightThreshold;
        final bool tightHeight =
            constraints.maxHeight < tokens.cardTightHeightThreshold;

        final Color accentColor = product.prayerTimeActive;
        final Color emphasisColor = colorScheme.onSurface;

        final Color surfaceColor = isNext
            ? product.prayerTimeNextSurface.withValues(
                alpha: tokens.opacityMedium,
              )
            : colorScheme.surfaceContainerLow;
        final Color borderColor = isNext
            ? product.prayerTimeActive.withValues(
                alpha: tokens.opacitySubtle * 1.5,
              )
            : colorScheme.outlineVariant.withValues(
                alpha: tokens.opacitySubtle,
              );
        final double cardPadH = tokens.spaceMedium;
        final double cardPadV = tightHeight
            ? tokens.spaceSmall
            : tokens.spaceMedium;

        return Container(
          decoration: BoxDecoration(
            color: surfaceColor,
            borderRadius: BorderRadius.circular(tokens.radiusLarge),
            border: Border.all(
              color: borderColor,
              width: tokens.borderWidthThin,
            ),
            boxShadow: isNext
                ? [
                    BoxShadow(
                      color: product.prayerTimeActive.withValues(
                        alpha: tokens.opacityShadow * 0.5,
                      ),
                      blurRadius: tokens.blurShadow,
                      offset: tokens.shadowOffsetSmall,
                    ),
                  ]
                : null,
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: cardPadH,
              vertical: cardPadV,
            ),
            child: _MainColumn(
              constraints: constraints,
              narrowTile: narrowTile,
              tightHeight: tightHeight,
              prayer: prayer,
              isNext: isNext,
              hasPassed: hasPassed,
              emphasisColor: emphasisColor,
              accentColor: accentColor,
              use24HourFormat: use24HourFormat,
            ),
          ),
        );
      },
    );
  }
}

class _MainColumn extends StatelessWidget {
  const _MainColumn({
    required this.constraints,
    required this.narrowTile,
    required this.tightHeight,
    required this.prayer,
    required this.isNext,
    required this.hasPassed,
    required this.emphasisColor,
    required this.accentColor,
    required this.use24HourFormat,
  });

  final BoxConstraints constraints;
  final bool narrowTile;
  final bool tightHeight;
  final PrayerTimeItem prayer;
  final bool isNext;
  final bool hasPassed;
  final Color emphasisColor;
  final Color accentColor;
  final bool use24HourFormat;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: .start,
      mainAxisSize: .min,
      mainAxisAlignment: .spaceBetween,
      children: [
        _HeaderRow(
          prayer: prayer,
          isNext: isNext,
          hasPassed: hasPassed,
          narrowTile: narrowTile,
          tightHeight: tightHeight,
        ),
        _PrayerTimeLabel(
          prayer: prayer,
          hasPassed: hasPassed,
          narrowTile: narrowTile,
          emphasisColor: emphasisColor,
        ),
        _PrayerTimeValue(
          prayer: prayer,
          isNext: isNext,
          hasPassed: hasPassed,
          use24HourFormat: use24HourFormat,
          accentColor: accentColor,
        ),
      ],
    );
  }
}

class _HeaderRow extends StatelessWidget {
  const _HeaderRow({
    required this.prayer,
    required this.isNext,
    required this.hasPassed,
    required this.narrowTile,
    required this.tightHeight,
  });

  final PrayerTimeItem prayer;
  final bool isNext;
  final bool hasPassed;
  final bool narrowTile;
  final bool tightHeight;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final tokens = theme.tokens;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TilawaIconBox(
          icon: prayer.type.icon,
          size: narrowTile ? tokens.iconSizeSmall : tokens.iconSizeLarge,
          padding: tightHeight ? tokens.spaceExtraSmall : tokens.spaceSmall,
          backgroundColor: colorScheme.surfaceContainerHighest.withValues(
            alpha: tokens.opacityMedium,
          ),
          iconColor: isNext
              ? colorScheme.primary
              : colorScheme.onSurfaceVariant,
          borderRadius: tokens.radiusSmall,
        ),
        const Spacer(),
        TilawaStatusChip(
          label: isNext
              ? context.l10n.next
              : hasPassed
              ? context.l10n.prayerTimesPassed
              : context.l10n.prayerTimesUpcoming,
          backgroundColor: isNext
              ? colorScheme.primary
              : colorScheme.surfaceContainerHighest,
          foregroundColor: isNext
              ? colorScheme.onPrimary
              : colorScheme.onSurfaceVariant,
        ),
      ],
    );
  }
}

class _PrayerTimeLabel extends StatelessWidget {
  const _PrayerTimeLabel({
    required this.prayer,
    required this.hasPassed,
    required this.narrowTile,
    required this.emphasisColor,
  });

  final PrayerTimeItem prayer;
  final bool hasPassed;
  final bool narrowTile;
  final Color emphasisColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final double baseFontSize = theme.textTheme.titleMedium?.fontSize ?? 18;
    final double fontSize = narrowTile ? baseFontSize - 1 : baseFontSize;

    return Text(
      prayer.type.localizedName(context),
      maxLines: narrowTile ? 1 : 2,
      overflow: TextOverflow.ellipsis,
      style: theme.textTheme.titleLarge?.copyWith(
        fontSize: fontSize,
        fontWeight: FontWeight.w800,
        color: emphasisColor.withValues(
          alpha: hasPassed ? theme.tokens.opacityEmphasis : 1.0,
        ),
      ),
    );
  }
}

class _PrayerTimeValue extends StatelessWidget {
  const _PrayerTimeValue({
    required this.prayer,
    required this.isNext,
    required this.hasPassed,
    required this.use24HourFormat,
    required this.accentColor,
  });

  final PrayerTimeItem prayer;
  final bool isNext;
  final bool hasPassed;
  final bool use24HourFormat;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final double fontSize =
        (theme.textTheme.titleLarge?.fontSize ?? 22) -
        (theme.tokens.spaceExtraSmall / 2);
    final isArabic = context.isArabic;

    return Text(
      PrayerTimeLabelFormatter.formatItem(
        prayer,
        use24HourFormat: use24HourFormat,
        isArabic: isArabic,
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: theme.textTheme.headlineSmall?.copyWith(
        fontSize: fontSize,
        fontWeight: FontWeight.w800,
        color: isNext
            ? accentColor
            : theme.colorScheme.onSurface.withValues(
                alpha: hasPassed ? theme.tokens.opacityEmphasis : 1.0,
              ),
      ),
    );
  }
}
