import 'package:flutter/material.dart';
import 'package:tilawa/core/extensions.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import '../../domain/entities/entities.dart';
import '../extensions/prayer_type_ui.dart';
import '../formatters/prayer_time_label_formatter.dart';
import '../layout/prayer_times_layout.dart';
import '../models/prayer_row_view_data.dart';
import 'prayer_alert_status_chip.dart';
import 'prayer_time_localizations.dart';

class NextPrayerCountdownCard extends StatelessWidget {
  const NextPrayerCountdownCard({
    super.key,
    required this.nextPrayer,
    required this.timeUntil,
    this.use24HourFormat = true,
    this.dateMetaLabel,
    this.alert,
    this.showPrayerTimeChipLabels = true,
    this.onAlertTap,
    this.alertTooltip,
  });

  final PrayerTimeItem nextPrayer;
  final Duration timeUntil;
  final bool use24HourFormat;
  final String? dateMetaLabel;
  final PrayerAlertViewData? alert;
  final bool showPrayerTimeChipLabels;

  /// Opens the same per-prayer alert sheet as Today's schedule rows.
  final VoidCallback? onAlertTap;

  /// Tooltip / semantics hint for the alert control (e.g. "Prayer notifications").
  final String? alertTooltip;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;
    final bool isArabic = context.isArabic;
    final Duration remaining = timeUntil.isNegative ? Duration.zero : timeUntil;
    final Color accentColor = colorScheme.primary;
    final alert = this.alert;

    final int hours = remaining.inHours;
    final int minutes = remaining.inMinutes.remainder(60);
    final int seconds = remaining.inSeconds.remainder(60);

    final String prayerName = nextPrayer.type.localizedName(context);
    final String remainingCaption =
        context.l10n.prayerTimesTimeRemainingCaption;
    final String prayerTime = PrayerTimeLabelFormatter.formatItem(
      nextPrayer,
      use24HourFormat: use24HourFormat,
      isArabic: isArabic,
    );

    final tokens = theme.tokens;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        tokens.spaceLarge,
        tokens.spaceSmall,
        tokens.spaceLarge,
        0,
      ),
      child: TilawaCard(
        surface: TilawaCardSurface.raised,
        borderRadius: tokens.radiusExtraLarge,
        backgroundColor: colorScheme.surface,
        padding: EdgeInsets.fromLTRB(
          tokens.spaceLarge,
          tokens.spaceMedium,
          tokens.spaceLarge,
          tokens.spaceSmall,
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final narrow = PrayerTimesLayout.isNarrowWidth(
              constraints.maxWidth,
            );
            final bool heroChipLabels = showPrayerTimeChipLabels && !narrow;
            final TextStyle metaStyle =
                theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ) ??
                TextStyle(
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                  fontSize: theme.textTheme.bodySmall?.fontSize ?? 12,
                );

            final List<String> metaParts = <String>[
              if (dateMetaLabel != null && dateMetaLabel!.isNotEmpty)
                dateMetaLabel!,
              prayerTime,
            ];
            final String metaLine = metaParts.join(' · ');

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  metaLine,
                  style: metaStyle,
                  maxLines: narrow ? 3 : 2,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: tokens.spaceSmall),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  spacing: tokens.spaceMedium,
                  children: [
                    Expanded(
                      child: Text(
                        prayerName,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                          height: 1.15,
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ),
                    _NextPrayerVisual(icon: nextPrayer.type.icon),
                  ],
                ),
                SizedBox(height: tokens.spaceSmall),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  spacing: tokens.spaceSmall,
                  mainAxisAlignment: .spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        remainingCaption,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    if (alert != null && alert.supportsAlerts) ...[
                      _HeroAlertControl(
                        alert: alert,
                        showLabel: heroChipLabels,
                        onTap: onAlertTap,
                        tooltip: alertTooltip,
                        tokens: tokens,
                      ),
                    ],
                  ],
                ),
                SizedBox(height: tokens.spaceTiny),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: AlignmentDirectional.centerStart,
                  child: Text(
                    '${hours.toString().padLeft(2, '0')}'
                    ':${minutes.toString().padLeft(2, '0')}'
                    ':${seconds.toString().padLeft(2, '0')}',
                    style: theme.textTheme.headlineLarge?.copyWith(
                      color: accentColor,
                      fontWeight: FontWeight.w800,
                      height: 1.05,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _HeroAlertControl extends StatelessWidget {
  const _HeroAlertControl({
    required this.alert,
    required this.showLabel,
    required this.onTap,
    required this.tooltip,
    required this.tokens,
  });

  final PrayerAlertViewData alert;
  final bool showLabel;
  final VoidCallback? onTap;
  final String? tooltip;
  final TilawaDesignTokens tokens;

  @override
  Widget build(BuildContext context) {
    final chip = PrayerAlertStatusChip(
      alert: alert,
      showLabel: showLabel,
      dense: true,
    );

    if (onTap == null) {
      return chip;
    }

    final borderRadius = BorderRadius.circular(tokens.radiusLarge);
    final Widget tappable = Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: borderRadius,
        child: Padding(
          padding: EdgeInsets.all(tokens.spaceExtraSmall),
          child: chip,
        ),
      ),
    );

    final padded = ConstrainedBox(
      constraints: BoxConstraints(
        minWidth: tokens.minInteractiveDimension,
        minHeight: tokens.minInteractiveDimension,
      ),
      child: Center(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: tappable,
        ),
      ),
    );

    final message = tooltip;
    if (message != null && message.isNotEmpty) {
      return Tooltip(
        message: message,
        child: Semantics(
          button: true,
          label: '${alert.label}. $message',
          child: padded,
        ),
      );
    }

    return Semantics(
      button: true,
      label: alert.label,
      child: padded,
    );
  }
}

class _NextPrayerVisual extends StatelessWidget {
  const _NextPrayerVisual({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.tokens;
    final colorScheme = theme.colorScheme;

    return Container(
      width: tokens.iconSizeLargePlus,
      height: tokens.iconSizeLargePlus,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: colorScheme.primaryContainer,
      ),
      child: Icon(
        icon,
        size: tokens.iconSizeLarge,
        color: colorScheme.primary,
      ),
    );
  }
}
