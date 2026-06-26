import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:tilawa/core/extensions.dart';
import 'package:tilawa/features/home/domain/home_hijri_date_formatter.dart';
import 'package:tilawa/features/home/presentation/widgets/home_hijri_calendar_sheet.dart';
import 'package:tilawa/features/prayer_times/presentation/formatters/prayer_location_label_formatter.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

/// Location chip + Hijri date row above the Home Prayer Hero card.
class HomePrayerHeroContextRow extends StatelessWidget {
  const HomePrayerHeroContextRow({
    super.key,
    required this.locationName,
    required this.isRefreshingLocation,
    required this.onRefreshLocation,
    this.ink,
    this.muted,
  });

  final String? locationName;
  final bool isRefreshingLocation;
  final VoidCallback? onRefreshLocation;

  /// When null, uses [ColorScheme.onSurface] / header secondary tokens.
  final Color? ink;
  final Color? muted;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final MeMuslimDesignTokens tokens = theme.tokens;
    final TilawaHomeScreenTokens screenTokens =
        theme.componentTokens.homeScreen;
    final ColorScheme colorScheme = theme.colorScheme;
    final Color resolvedInk = ink ?? colorScheme.onSurface;
    final Color resolvedMuted = muted ?? screenTokens.homeHeaderSecondaryText;
    final String locationLabel =
        PrayerLocationLabelFormatter.abbreviatedLocationLabel(
          locationName: locationName,
          l10n: context.l10n,
        );
    final String hijriDateLine = formatHomeHijriDate(
      date: DateTime.now(),
      languageCode: Localizations.localeOf(context).languageCode,
    );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      spacing: tokens.spaceSmall,
      children: [
        Flexible(
          child: Align(
            alignment: AlignmentDirectional.centerStart,
            child: _HomePrayerHeroLocationChip(
              label: locationLabel,
              ink: resolvedInk,
              muted: resolvedMuted,
              chipBackground: screenTokens.homeHeaderChipBackground,
              isRefreshingLocation: isRefreshingLocation,
              onRefreshLocation: onRefreshLocation,
            ),
          ),
        ),
        Semantics(
          button: true,
          label: context.l10n.hijriCalendarOpenLabel,
          child: InkWell(
            onTap: () => showHomeHijriCalendarSheet(context),
            borderRadius: BorderRadius.circular(tokens.radiusSmall),
            child: Text(
              hijriDateLine,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.end,
              style: theme.textTheme.labelMedium?.copyWith(
                color: resolvedMuted,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _HomePrayerHeroLocationChip extends StatelessWidget {
  const _HomePrayerHeroLocationChip({
    required this.label,
    required this.ink,
    required this.muted,
    required this.chipBackground,
    required this.isRefreshingLocation,
    required this.onRefreshLocation,
  });

  final String label;
  final Color ink;
  final Color muted;
  final Color chipBackground;
  final bool isRefreshingLocation;
  final VoidCallback? onRefreshLocation;

  @override
  Widget build(BuildContext context) {
    final MeMuslimDesignTokens tokens = Theme.of(context).tokens;

    return Semantics(
      button: true,
      label: label,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isRefreshingLocation ? null : onRefreshLocation,
          borderRadius: BorderRadius.circular(tokens.radiusLarge),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: chipBackground,
              borderRadius: BorderRadius.circular(tokens.radiusLarge),
              border: Border.all(
                color: Theme.of(
                  context,
                ).componentTokens.homeScreen.homePrayerHeroBorder,
                width: tokens.borderWidthThin,
              ),
            ),
            child: Padding(
              padding: EdgeInsetsDirectional.symmetric(
                horizontal: tokens.spaceSmall,
                vertical: tokens.spaceExtraSmall,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                spacing: tokens.spaceExtraSmall * 0.75,
                children: [
                  Icon(
                    FluentIcons.location_24_regular,
                    size: tokens.iconSizeSmall,
                    color: muted,
                  ),
                  Flexible(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: ink,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  if (isRefreshingLocation)
                    SizedBox(
                      width: tokens.iconSizeSmall,
                      height: tokens.iconSizeSmall,
                      child: TilawaLoadingIndicator(
                        centered: false,
                        strokeWidth: 2,
                        color: ink,
                      ),
                    )
                  else
                    Icon(
                      FluentIcons.chevron_down_24_regular,
                      size: tokens.iconSizeSmall * 0.85,
                      color: muted,
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
