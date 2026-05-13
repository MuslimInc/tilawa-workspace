import 'package:flutter/material.dart';
import 'package:tilawa/core/extensions.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import '../../domain/entities/entities.dart';
import '../formatters/prayer_time_label_formatter.dart';
import '../extensions/prayer_type_ui.dart';
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
  });

  final PrayerTimeItem nextPrayer;
  final Duration timeUntil;
  final bool use24HourFormat;
  final String? dateMetaLabel;
  final PrayerAlertViewData? alert;
  final bool showPrayerTimeChipLabels;

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
    final String nextPrayerLabel = context.l10n.nextPrayer;
    final String scheduledLabel = context.l10n.prayerTimesScheduled;
    final String remainingLabel = context.l10n.prayerTimesTimeRemainingUntil(
      prayerName,
    );
    final String prayerTime = PrayerTimeLabelFormatter.formatItem(
      nextPrayer,
      use24HourFormat: use24HourFormat,
      isArabic: isArabic,
    );

    final tokens = theme.tokens;

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: tokens.spaceLarge,
        vertical: tokens.spaceSmall,
      ),
      child: TilawaCard(
        flat: true,
        borderRadius: tokens.radiusExtraLarge,
        gradient: LinearGradient(
          begin: AlignmentDirectional.topStart,
          end: AlignmentDirectional.bottomEnd,
          colors: [
            Color.alphaBlend(
              colorScheme.primary.withValues(
                alpha: tokens.opacitySubtle * 0.85,
              ),
              colorScheme.surface,
            ),
            colorScheme.surfaceContainerLow,
          ],
        ),
        borderColor: colorScheme.primary.withValues(
          alpha: tokens.opacitySubtle * 1.4,
        ),
        padding: EdgeInsets.fromLTRB(
          tokens.spaceLarge,
          tokens.spaceMedium,
          tokens.spaceLarge,
          tokens.spaceMedium,
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final narrow = PrayerTimesLayout.isNarrowWidth(
              constraints.maxWidth,
            );
            final bool heroChipLabels = showPrayerTimeChipLabels && !narrow;
            final TextStyle scheduledStyle =
                theme.textTheme.labelMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ) ??
                TextStyle(
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                  fontSize: theme.textTheme.labelMedium?.fontSize ?? 12,
                );

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (narrow) ...[
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: AlignmentDirectional.centerStart,
                      child: TilawaStatusChip(
                        label: nextPrayerLabel,
                        backgroundColor: accentColor,
                        foregroundColor: colorScheme.onPrimary,
                        icon: Icons.notifications_active_rounded,
                        showLabel: heroChipLabels,
                      ),
                    ),
                  ),
                  SizedBox(height: tokens.spaceExtraSmall),
                  Text(
                    '$scheduledLabel • $prayerTime',
                    style: scheduledStyle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ] else ...[
                  Row(
                    children: [
                      Expanded(
                        child: Align(
                          alignment: AlignmentDirectional.centerStart,
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: AlignmentDirectional.centerStart,
                            child: TilawaStatusChip(
                              label: nextPrayerLabel,
                              backgroundColor: accentColor,
                              foregroundColor: colorScheme.onPrimary,
                              icon: Icons.notifications_active_rounded,
                              showLabel: showPrayerTimeChipLabels,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: tokens.spaceSmall),
                      Expanded(
                        child: Text(
                          '$scheduledLabel • $prayerTime',
                          style: scheduledStyle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.end,
                        ),
                      ),
                    ],
                  ),
                ],
                if (dateMetaLabel != null) ...[
                  SizedBox(height: tokens.spaceExtraSmall),
                  Text(
                    dateMetaLabel!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: narrow ? 2 : 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                SizedBox(height: tokens.spaceMedium),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        prayerName,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ),
                    SizedBox(width: tokens.spaceMedium),
                    _NextPrayerVisual(icon: nextPrayer.type.icon),
                  ],
                ),
                SizedBox(height: tokens.spaceSmall),
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(
                    horizontal: tokens.spaceMedium,
                    vertical: tokens.spaceSmall,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.surface.withValues(
                      alpha: tokens.opacityMedium,
                    ),
                    borderRadius: BorderRadius.circular(tokens.radiusLarge),
                    border: Border.all(
                      color: colorScheme.primary.withValues(
                        alpha: tokens.opacitySubtle,
                      ),
                      width: tokens.borderWidthThin,
                    ),
                  ),
                  child: Text(
                    remainingLabel,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                SizedBox(height: tokens.spaceSmall),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: AlignmentDirectional.centerStart,
                        child: Text(
                          '${hours.toString().padLeft(2, '0')}'
                          ':${minutes.toString().padLeft(2, '0')}'
                          ':${seconds.toString().padLeft(2, '0')}',
                          style: theme.textTheme.displaySmall?.copyWith(
                            color: accentColor,
                            fontWeight: FontWeight.w800,
                            fontFeatures: const [
                              FontFeature.tabularFigures(),
                            ],
                          ),
                        ),
                      ),
                    ),
                    if (alert != null && alert.supportsAlerts) ...[
                      SizedBox(width: tokens.spaceSmall),
                      Flexible(
                        child: Align(
                          alignment: AlignmentDirectional.bottomEnd,
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: AlignmentDirectional.centerEnd,
                            child: PrayerAlertStatusChip(
                              alert: alert,
                              showLabel: heroChipLabels,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            );
          },
        ),
      ),
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
      width: tokens.iconSizeExtraLarge + tokens.spaceLarge,
      height: tokens.iconSizeExtraLarge + tokens.spaceLarge,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: colorScheme.primaryContainer.withValues(
          alpha: tokens.opacityMedium,
        ),
        border: Border.all(
          color: colorScheme.primary.withValues(alpha: tokens.opacitySubtle),
          width: tokens.borderWidthThin,
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withValues(alpha: tokens.opacitySubtle),
            blurRadius: tokens.blurShadow,
            offset: tokens.shadowOffsetSmall,
          ),
        ],
      ),
      child: Icon(
        icon,
        size: tokens.iconSizeLarge,
        color: colorScheme.primary,
      ),
    );
  }
}
