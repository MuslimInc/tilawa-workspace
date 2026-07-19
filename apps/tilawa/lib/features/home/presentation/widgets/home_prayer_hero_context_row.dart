import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:tilawa/core/extensions.dart';
import 'package:tilawa/features/home/domain/home_hijri_date_formatter.dart';
import 'package:tilawa/features/home/presentation/widgets/home_hijri_calendar_sheet.dart';
import 'package:tilawa/features/prayer_times/presentation/formatters/prayer_location_label_formatter.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

/// Date + location row for the immersive Home header zone (Figma).
class HomePrayerHeroContextRow extends StatelessWidget {
  const HomePrayerHeroContextRow({
    super.key,
    required this.locationName,
    required this.isRefreshingLocation,
    required this.onRefreshLocation,
    this.ink,
    this.muted,
    this.chipBackground,
    this.chipBorder,
  });

  final String? locationName;
  final bool isRefreshingLocation;
  final VoidCallback? onRefreshLocation;
  final Color? ink;
  final Color? muted;
  final Color? chipBackground;
  final Color? chipBorder;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final MeMuslimDesignTokens tokens = context.tokens;
    final ColorScheme colorScheme = theme.colorScheme;
    final TilawaHomeScreenTokens screenTokens =
        theme.componentTokens.homeScreen;
    final Color resolvedInk = ink ?? colorScheme.onSurface;
    final Color resolvedMuted = muted ?? screenTokens.homeHeaderSecondaryText;
    final String locationLabel =
        PrayerLocationLabelFormatter.abbreviatedLocationLabel(
          locationName: locationName,
          l10n: context.l10n,
        );
    final String dateLine = formatHomeHeaderDateLine(
      date: DateTime.now(),
      languageCode: Localizations.localeOf(context).languageCode,
    );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: TilawaInteractiveSurface(
            onTap: () => showHomeHijriCalendarSheet(context),
            borderRadius: BorderRadius.circular(tokens.radiusSmall),
            enableInk: false,
            enableStateLayer: false,
            semanticLabel: context.l10n.hijriCalendarOpenLabel,
            child: Text(
              dateLine,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.start,
              style: TextStyle(
                color: resolvedMuted,
                fontWeight: FontWeight.w400,
                letterSpacing: 0.2,
                fontSize: 11,
                height: 1.2,
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        TilawaInteractiveSurface(
          onTap: isRefreshingLocation ? null : onRefreshLocation,
          borderRadius: BorderRadius.circular(tokens.radiusSmall),
          enableInk: false,
          enableStateLayer: false,
          semanticLabel: locationLabel,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                FluentIcons.location_24_filled,
                size: 12,
                color: resolvedMuted,
              ),
              const SizedBox(width: 4),
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.sizeOf(context).width * 0.28,
                ),
                child: Text(
                  locationLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: resolvedInk.withValues(alpha: 0.8),
                    fontWeight: FontWeight.w500,
                    fontSize: 11,
                    height: 1.2,
                  ),
                ),
              ),
              if (isRefreshingLocation) ...[
                const SizedBox(width: 4),
                SizedBox(
                  width: tokens.iconSizeExtraSmall,
                  height: tokens.iconSizeExtraSmall,
                  child: TilawaLoadingIndicator(
                    centered: false,
                    strokeWidth: 1.5,
                    color: resolvedInk,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
