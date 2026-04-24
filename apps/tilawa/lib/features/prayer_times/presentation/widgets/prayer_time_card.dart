import 'package:flutter/material.dart';
import 'package:tilawa/core/extensions.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import '../../domain/entities/entities.dart';
import '../extensions/prayer_type_ui.dart';
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

    return LayoutBuilder(
      builder: (context, constraints) {
        // Thresholds for compact mode to avoid overflows on small screens
        final bool compact =
            constraints.maxWidth < tokens.cardCompactWidthThreshold ||
            constraints.maxHeight < tokens.cardCompactHeightThreshold;
        final bool tightHeight =
            constraints.maxHeight < tokens.cardTightHeightThreshold;

        final Color accentColor = colorScheme.primary;
        final Color emphasisColor = colorScheme.onSurface;

        return Container(
          decoration: BoxDecoration(
            color: isNext
                ? colorScheme.surfaceContainerLow
                : colorScheme.surface,
            borderRadius: BorderRadius.circular(tokens.radiusExtraLarge),
            border: Border.all(
              color: isNext
                  ? accentColor.withValues(alpha: tokens.opacityMedium)
                  : colorScheme.outlineVariant.withValues(
                      alpha: tokens.opacityMedium,
                    ),
              width: isNext
                  ? tokens.borderWidthThin * 3
                  : tokens.borderWidthThin * 2,
            ),
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: tokens.spaceMedium,
              vertical: tightHeight ? tokens.spaceSmall : tokens.spaceMedium,
            ),
            child: _MainColumn(
              constraints: constraints,
              compact: compact,
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
    required this.compact,
    required this.tightHeight,
    required this.prayer,
    required this.isNext,
    required this.hasPassed,
    required this.emphasisColor,
    required this.accentColor,
    required this.use24HourFormat,
  });

  final BoxConstraints constraints;
  final bool compact;
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
          compact: compact,
          tightHeight: tightHeight,
        ),
        _PrayerTimeLabel(
          prayer: prayer,
          hasPassed: hasPassed,
          compact: compact,
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
    required this.compact,
    required this.tightHeight,
  });

  final PrayerTimeItem prayer;
  final bool isNext;
  final bool hasPassed;
  final bool compact;
  final bool tightHeight;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TilawaIconBox(
          icon: prayer.type.icon,
          size: compact ? 16 : 24,
          padding: tightHeight ? 4 : 8,
          backgroundColor: isNext
              ? colorScheme.primary.withValues(alpha: 0.12)
              : colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
          iconColor: isNext
              ? colorScheme.primary
              : colorScheme.onSurfaceVariant,
          borderRadius: 8,
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
              : hasPassed
              ? colorScheme.surfaceContainerHighest
              : colorScheme.primaryContainer,
          foregroundColor: isNext
              ? colorScheme.onPrimary
              : hasPassed
              ? colorScheme.onSurfaceVariant
              : colorScheme.onPrimaryContainer,
        ),
      ],
    );
  }
}

class _PrayerTimeLabel extends StatelessWidget {
  const _PrayerTimeLabel({
    required this.prayer,
    required this.hasPassed,
    required this.compact,
    required this.emphasisColor,
  });

  final PrayerTimeItem prayer;
  final bool hasPassed;
  final bool compact;
  final Color emphasisColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final double baseFontSize = theme.textTheme.titleMedium?.fontSize ?? 18;
    final double fontSize = compact ? baseFontSize - 1 : baseFontSize;

    return Text(
      prayer.type.localizedName(context),
      maxLines: compact ? 1 : 2,
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
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    return Text(
      use24HourFormat
          ? prayer.formattedTime
          : prayer.getFormattedTime12Hour(isArabic: isArabic),
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
