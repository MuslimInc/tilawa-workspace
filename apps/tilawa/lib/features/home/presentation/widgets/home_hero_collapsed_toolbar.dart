import 'dart:async';

import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:tilawa/core/extensions.dart';
import 'package:tilawa/features/home/domain/entities/home_dashboard.dart';
import 'package:tilawa/features/home/presentation/widgets/home_hero_photo_theme.dart';
import 'package:tilawa/features/prayer_times/domain/entities/prayer_time_entity.dart';
import 'package:tilawa/features/prayer_times/presentation/formatters/prayer_location_label_formatter.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

/// Premium pinned hero toolbar — location chip, prayer glance, countdown pill.
class HomeHeroCollapsedToolbar extends StatelessWidget {
  const HomeHeroCollapsedToolbar({
    super.key,
    required this.heroTokens,
    required this.collapsedBarColor,
    required this.nextPrayer,
    required this.locationName,
    required this.isRefreshingLocation,
    required this.onRefreshLocation,
    required this.onOpenPrayer,
  });

  final TilawaHomeNextPrayerHeroTokens heroTokens;
  final Color collapsedBarColor;
  final HomeNextPrayer? nextPrayer;
  final String? locationName;
  final bool isRefreshingLocation;
  final VoidCallback? onRefreshLocation;
  final VoidCallback onOpenPrayer;

  static const double _locationMaxWidthFactor = 0.34;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final TilawaDesignTokens tokens = theme.tokens;
    final ColorScheme colorScheme = theme.colorScheme;
    final Color foreground = HomeHeroPhotoTheme.collapsedToolbarForeground(
      collapsedBarColor: collapsedBarColor,
      heroTokens: heroTokens,
      colorScheme: colorScheme,
    );
    final Color muted = HomeHeroPhotoTheme.collapsedToolbarMuted(colorScheme);
    final TextStyle? locationStyle = HomeHeroPhotoTheme.labelStyle(
      theme.textTheme.labelSmall,
      colorScheme.onPrimary,
      tokens: tokens,
      fontWeight: FontWeight.w600,
    );
    final TextStyle prayerStyle = HomeHeroPhotoTheme.titleStyle(
      theme.textTheme.titleSmall,
      foreground,
      tokens: tokens,
      fontWeight: FontWeight.w800,
    )!;
    final TextStyle countdownStyle = HomeHeroPhotoTheme.labelStyle(
      theme.textTheme.labelSmall,
      colorScheme.semanticTintForeground(TilawaSemanticTint.gilding),
      tokens: tokens,
      fontWeight: FontWeight.w700,
    )!;
    final String locationLabel =
        PrayerLocationLabelFormatter.abbreviatedLocationLabel(
          locationName: locationName,
          l10n: context.l10n,
        );

    return ConstrainedBox(
      constraints: BoxConstraints(minHeight: tokens.minInteractiveDimension),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Flexible(
            flex: 3,
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
          _HomeHeroCollapsedZoneDivider(colorScheme: colorScheme),
          Expanded(
            flex: 4,
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
          if (nextPrayer != null) ...[
            _HomeHeroCollapsedZoneDivider(colorScheme: colorScheme),
            Flexible(
              flex: 3,
              child: _HomeHeroCollapsedCountdownPill(
                prayer: nextPrayer!,
                labelStyle: countdownStyle,
                onOpenPrayer: onOpenPrayer,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _HomeHeroCollapsedZoneDivider extends StatelessWidget {
  const _HomeHeroCollapsedZoneDivider({required this.colorScheme});

  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    final TilawaDesignTokens tokens = context.tokens;
    final TilawaBottomSheetScaffoldTokens sheetTokens = Theme.of(
      context,
    ).componentTokens.bottomSheetScaffold;

    return Padding(
      padding: EdgeInsetsDirectional.symmetric(
        horizontal: tokens.spaceExtraSmall,
      ),
      child: SizedBox(
        height: tokens.iconSizeSmall,
        child: VerticalDivider(
          width: sheetTokens.footerTopBorderWidth,
          thickness: sheetTokens.footerTopBorderWidth,
          color: HomeHeroPhotoTheme.collapsedToolbarDividerColor(colorScheme),
        ),
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
    final TilawaDesignTokens tokens = context.tokens;
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
                        color: colorScheme.onPrimary,
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
    final TilawaDesignTokens tokens = context.tokens;
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

class _HomeHeroCollapsedCountdownPill extends StatefulWidget {
  const _HomeHeroCollapsedCountdownPill({
    required this.prayer,
    required this.labelStyle,
    required this.onOpenPrayer,
  });

  final HomeNextPrayer prayer;
  final TextStyle labelStyle;
  final VoidCallback onOpenPrayer;

  @override
  State<_HomeHeroCollapsedCountdownPill> createState() =>
      _HomeHeroCollapsedCountdownPillState();
}

class _HomeHeroCollapsedCountdownPillState
    extends State<_HomeHeroCollapsedCountdownPill> {
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _scheduleTicker();
  }

  @override
  void didUpdateWidget(covariant _HomeHeroCollapsedCountdownPill oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.prayer.time != widget.prayer.time) {
      _scheduleTicker();
    }
  }

  void _scheduleTicker() {
    _ticker?.cancel();
    final Duration remaining = _remaining;
    if (remaining <= Duration.zero) {
      return;
    }

    final Duration interval = remaining < const Duration(hours: 1)
        ? const Duration(seconds: 1)
        : const Duration(minutes: 1);

    _ticker = Timer.periodic(interval, (_) {
      if (!mounted) {
        return;
      }
      if (_remaining <= Duration.zero) {
        _ticker?.cancel();
      }
      setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  Duration get _remaining {
    final Duration difference = widget.prayer.time.difference(DateTime.now());
    return difference.isNegative ? Duration.zero : difference;
  }

  @override
  Widget build(BuildContext context) {
    final TilawaDesignTokens tokens = context.tokens;
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final String countdown = _remaining <= Duration.zero
        ? context.l10n.homePrayerNow
        : _formatCountdown(context, _remaining);

    return Semantics(
      button: true,
      label: countdown,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onOpenPrayer,
          borderRadius: BorderRadius.circular(tokens.radiusLarge),
          child: DecoratedBox(
            decoration: HomeHeroPhotoTheme.collapsedCountdownChipDecoration(
              colorScheme: colorScheme,
              tokens: tokens,
            ),
            child: Padding(
              padding: EdgeInsetsDirectional.symmetric(
                horizontal: tokens.spaceSmall,
                vertical: tokens.spaceExtraSmall,
              ),
              child: Text(
                countdown,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: widget.labelStyle,
              ),
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

String _formatCountdown(BuildContext context, Duration duration) {
  if (duration.inMinutes < 1) {
    return context.l10n.homePrayerNow;
  }
  final int totalMinutes = duration.inMinutes;
  final int hours = totalMinutes ~/ 60;
  final int minutes = totalMinutes % 60;
  if (hours == 0) {
    return context.l10n.homePrayerInMinutes(minutes);
  }
  return context.l10n.homePrayerInHoursMinutes(hours, minutes);
}
