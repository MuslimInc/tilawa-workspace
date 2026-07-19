import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:tilawa/core/extensions.dart';
import 'package:tilawa/features/home/domain/entities/home_prayer_slot.dart';
import 'package:tilawa/features/prayer_times/domain/entities/prayer_time_entity.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

/// Compact five-prayer strip for the immersive Home header zone.
class HomePrayerScheduleStrip extends StatelessWidget {
  const HomePrayerScheduleStrip({
    super.key,
    required this.slots,
    required this.onHero,
    required this.heroTokens,
    this.onOpenPrayer,
  });

  final List<HomePrayerSlot> slots;
  final Color onHero;
  final TilawaHomeNextPrayerHeroTokens heroTokens;
  final VoidCallback? onOpenPrayer;

  static const double _stripHeight = 52;

  @override
  Widget build(BuildContext context) {
    if (slots.isEmpty) {
      return const SizedBox.shrink();
    }

    final ThemeData theme = Theme.of(context);
    final MeMuslimDesignTokens tokens = theme.tokens;
    final BorderRadius radius = BorderRadius.circular(
      tokens.resolveRadius(family: TilawaRadiusFamily.card),
    );
    final Color fill = onHero.withValues(
      alpha: heroTokens.locationChipFillOpacity,
    );
    final Color border = onHero.withValues(
      alpha: heroTokens.locationChipBorderOpacity,
    );

    final Widget row = SizedBox(
      height: _stripHeight,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: fill,
          borderRadius: radius,
          border: Border.all(
            color: border,
            width: tokens.borderWidthThin,
          ),
        ),
        child: Row(
          children: [
            for (final HomePrayerSlot slot in slots)
              Expanded(
                child: _HomePrayerScheduleSlot(
                  slot: slot,
                  onHero: onHero,
                  heroTokens: heroTokens,
                ),
              ),
          ],
        ),
      ),
    );

    final Widget clipped = ClipRRect(
      borderRadius: radius,
      child: _maybeBlur(context, tokens, row),
    );

    return Semantics(
      button: onOpenPrayer != null,
      label: context.l10n.homePrayerStripTitle,
      child: TilawaInteractiveSurface(
        onTap: onOpenPrayer,
        borderRadius: radius,
        child: clipped,
      ),
    );
  }

  Widget _maybeBlur(
    BuildContext context,
    MeMuslimDesignTokens tokens,
    Widget child,
  ) {
    final bool useBlur =
        !kIsWeb && defaultTargetPlatform != TargetPlatform.android;
    if (!useBlur) {
      return child;
    }
    return BackdropFilter(
      filter: ImageFilter.blur(
        sigmaX: tokens.blurGlass,
        sigmaY: tokens.blurGlass,
      ),
      child: child,
    );
  }
}

class _HomePrayerScheduleSlot extends StatelessWidget {
  const _HomePrayerScheduleSlot({
    required this.slot,
    required this.onHero,
    required this.heroTokens,
  });

  final HomePrayerSlot slot;
  final Color onHero;
  final TilawaHomeNextPrayerHeroTokens heroTokens;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final MeMuslimDesignTokens tokens = theme.tokens;
    final bool isActive = slot.isNext;
    final Color muted = onHero.withValues(
      alpha: heroTokens.mutedForegroundOpacity * (slot.hasPassed ? 0.75 : 1),
    );
    final Color labelColor = isActive ? onHero : muted;
    final Color timeColor = isActive ? onHero : muted;
    final String name = _localizedPrayerName(context, slot.type);
    final String timeLabel = MaterialLocalizations.of(context).formatTimeOfDay(
      TimeOfDay.fromDateTime(slot.time),
    );

    final Widget content = Column(
      mainAxisAlignment: MainAxisAlignment.center,
      spacing: tokens.spaceTiny,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          spacing: tokens.spaceExtraSmall,
          children: [
            if (isActive)
              DecoratedBox(
                decoration: BoxDecoration(
                  color: theme.colorScheme.tertiary,
                  shape: BoxShape.circle,
                ),
                child: SizedBox.square(dimension: tokens.spaceExtraSmall),
              ),
            Flexible(
              child: Text(
                name.toUpperCase(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: labelColor,
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                  letterSpacing: 0.5,
                  height: 1.1,
                ),
              ),
            ),
          ],
        ),
        Text(
          timeLabel,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.labelMedium?.copyWith(
            color: timeColor,
            fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
            fontFeatures: const [FontFeature.tabularFigures()],
            height: 1.1,
          ),
        ),
      ],
    );

    if (!isActive) {
      return content;
    }

    return Padding(
      padding: EdgeInsets.all(tokens.spaceExtraSmall),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: onHero.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(tokens.radiusMedium),
        ),
        child: content,
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
