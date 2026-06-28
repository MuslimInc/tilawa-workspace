import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:tilawa/core/extensions.dart';
import 'package:tilawa/features/home/domain/entities/home_dashboard.dart';
import 'package:tilawa/features/home/presentation/widgets/home_hero_photo_theme.dart';
import 'package:tilawa/features/prayer_times/domain/entities/prayer_time_entity.dart';
import 'package:tilawa/features/prayer_times/presentation/formatters/prayer_location_label_formatter.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

/// Premium pinned hero toolbar — location chip and prayer glance.
class HomeHeroCollapsedToolbar extends StatelessWidget {
  const HomeHeroCollapsedToolbar({
    super.key,
    required this.nextPrayer,
    required this.locationName,
    required this.isRefreshingLocation,
    required this.onRefreshLocation,
    required this.onOpenPrayer,
  });

  final HomeNextPrayer? nextPrayer;
  final String? locationName;
  final bool isRefreshingLocation;
  final VoidCallback? onRefreshLocation;
  final VoidCallback onOpenPrayer;

  static const double _locationMaxWidthFactor = 0.36;
  static const double _prayerMaxWidthFactor = 0.58;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final MeMuslimDesignTokens tokens = theme.tokens;
    final ColorScheme colorScheme = theme.colorScheme;
    final Color foreground = HomeHeroPhotoTheme.collapsedToolbarForeground(
      colorScheme: colorScheme,
    );
    final Color muted = HomeHeroPhotoTheme.collapsedToolbarMuted(colorScheme);
    final TextStyle? locationStyle = HomeHeroPhotoTheme.labelStyle(
      theme.textTheme.labelSmall,
      colorScheme.onSurface,
      tokens: tokens,
      colorScheme: colorScheme,
      fontWeight: FontWeight.w600,
    );
    final TextStyle prayerStyle = HomeHeroPhotoTheme.titleStyle(
      theme.textTheme.titleSmall,
      foreground,
      tokens: tokens,
      colorScheme: colorScheme,
      fontWeight: FontWeight.w800,
    )!;
    final String locationLabel =
        PrayerLocationLabelFormatter.abbreviatedLocationLabel(
          locationName: locationName,
          l10n: context.l10n,
        );

    return ConstrainedBox(
      constraints: BoxConstraints(minHeight: tokens.minInteractiveDimension),
      child: Stack(
        alignment: AlignmentDirectional.center,
        children: [
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth:
                    MediaQuery.sizeOf(context).width * _locationMaxWidthFactor,
              ),
              child: _HomeHeroCollapsedLocationChip(
                label: locationLabel,
                labelStyle: locationStyle,
                muted: muted,
                isRefreshingLocation: isRefreshingLocation,
                onRefreshLocation: onRefreshLocation,
              ),
            ),
          ),
          Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth:
                    MediaQuery.sizeOf(context).width * _prayerMaxWidthFactor,
              ),
              child: switch (nextPrayer) {
                null => Text(
                  context.l10n.homeNextPrayerUnavailable,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: prayerStyle,
                ),
                final prayer => _HomeHeroCollapsedPrayerCenter(
                  prayer: prayer,
                  prayerStyle: prayerStyle,
                  onOpenPrayer: onOpenPrayer,
                ),
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _HomeHeroCollapsedLocationChip extends StatelessWidget {
  const _HomeHeroCollapsedLocationChip({
    required this.label,
    required this.labelStyle,
    required this.muted,
    required this.isRefreshingLocation,
    required this.onRefreshLocation,
  });

  final String label;
  final TextStyle? labelStyle;
  final Color muted;
  final bool isRefreshingLocation;
  final VoidCallback? onRefreshLocation;

  @override
  Widget build(BuildContext context) {
    final MeMuslimDesignTokens tokens = context.tokens;
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    return Semantics(
      button: true,
      label: label,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isRefreshingLocation ? null : onRefreshLocation,
          borderRadius: BorderRadius.circular(tokens.radiusLarge),
          child: DecoratedBox(
            decoration: HomeHeroPhotoTheme.collapsedLocationChipDecoration(
              colorScheme: colorScheme,
              tokens: tokens,
            ),
            child: Padding(
              padding: EdgeInsetsDirectional.symmetric(
                horizontal: tokens.spaceSmall,
                vertical: tokens.spaceExtraSmall,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                spacing: tokens.spaceExtraSmall * 0.5,
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
                      style: labelStyle,
                    ),
                  ),
                  if (isRefreshingLocation)
                    SizedBox(
                      width: tokens.iconSizeSmall,
                      height: tokens.iconSizeSmall,
                      child: TilawaLoadingIndicator(
                        centered: false,
                        strokeWidth: 2,
                        color: colorScheme.onSurface,
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

class _HomeHeroCollapsedPrayerCenter extends StatelessWidget {
  const _HomeHeroCollapsedPrayerCenter({
    required this.prayer,
    required this.prayerStyle,
    required this.onOpenPrayer,
  });

  final HomeNextPrayer prayer;
  final TextStyle prayerStyle;
  final VoidCallback onOpenPrayer;

  @override
  Widget build(BuildContext context) {
    final MeMuslimDesignTokens tokens = context.tokens;
    final String name = _localizedPrayerName(context, prayer.type);
    final String time = _formatTime(context, prayer.time);

    return Semantics(
      button: true,
      label: '$name, $time',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onOpenPrayer,
          borderRadius: BorderRadius.circular(tokens.radiusSmall),
          child: Padding(
            padding: EdgeInsetsDirectional.symmetric(
              horizontal: tokens.spaceExtraSmall,
              vertical: tokens.spaceExtraSmall * 0.5,
            ),
            child: Text(
              '$name · $time',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: prayerStyle,
            ),
          ),
        ),
      ),
    );
  }
}

String _localizedPrayerName(BuildContext context, PrayerType type) {
  return switch (type) {
    PrayerType.fajr => context.l10n.fajr,
    PrayerType.sunrise => context.l10n.sunrise,
    PrayerType.dhuhr => context.l10n.dhuhr,
    PrayerType.asr => context.l10n.asr,
    PrayerType.maghrib => context.l10n.maghrib,
    PrayerType.isha => context.l10n.isha,
    PrayerType.midnight => context.l10n.midnight,
    PrayerType.lastThird => context.l10n.lastThird,
  };
}

String _formatTime(BuildContext context, DateTime time) {
  return MaterialLocalizations.of(context).formatTimeOfDay(
    TimeOfDay.fromDateTime(time),
  );
}
