import 'package:flutter/material.dart';
import 'package:tilawa/core/extensions.dart';
import 'package:tilawa/features/home/domain/entities/home_prayer_slot.dart';
import 'package:tilawa/features/prayer_times/domain/entities/prayer_time_entity.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

/// Compact five-prayer strip matching MeMuslim Figma header-zone.
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
  static const double _inactiveOpacity = 0.5;
  static const double _fillOpacity = 0.1;
  static const double _borderOpacity = 0.12;
  static const double _activeFillOpacity = 0.2;

  @override
  Widget build(BuildContext context) {
    final List<HomePrayerSlot> five = [
      for (final HomePrayerSlot slot in slots)
        if (_isFiveDaily(slot.type)) slot,
    ];
    if (five.isEmpty) {
      return const SizedBox.shrink();
    }

    final MeMuslimDesignTokens tokens = context.tokens;
    final BorderRadius radius = BorderRadius.circular(16);

    // Flat frosted fill — no BackdropFilter (muddies dark greens / adds haze).
    final Widget row = SizedBox(
      height: _stripHeight,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: _fillOpacity),
          borderRadius: radius,
          border: Border.all(
            color: Colors.white.withValues(alpha: _borderOpacity),
            width: tokens.borderWidthThin,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final HomePrayerSlot slot in five)
              Expanded(
                child: _HomePrayerScheduleSlot(slot: slot, onHero: onHero),
              ),
          ],
        ),
      ),
    );

    return Semantics(
      button: onOpenPrayer != null,
      label: context.l10n.homePrayerStripTitle,
      child: TilawaInteractiveSurface(
        onTap: onOpenPrayer,
        borderRadius: radius,
        enableInk: false,
        enableStateLayer: false,
        child: row,
      ),
    );
  }
}

class _HomePrayerScheduleSlot extends StatelessWidget {
  const _HomePrayerScheduleSlot({
    required this.slot,
    required this.onHero,
  });

  final HomePrayerSlot slot;
  final Color onHero;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool isActive = slot.isNext;
    final Color muted = Colors.white.withValues(
      alpha: HomePrayerScheduleStrip._inactiveOpacity,
    );
    final Color labelColor = isActive ? Colors.white : muted;
    final Color timeColor = isActive ? Colors.white : muted;
    final String name = _localizedPrayerName(context, slot.type);
    final String timeLabel = _formatStripTime(slot.time);

    final Widget content = Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        spacing: 3,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            spacing: 4,
            children: [
              if (isActive)
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: theme.colorScheme.tertiary,
                    shape: BoxShape.circle,
                  ),
                  child: const SizedBox.square(dimension: 5),
                ),
              Flexible(
                child: Text(
                  name.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: labelColor,
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                    letterSpacing: 0.5,
                    fontSize: 10,
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
            style: TextStyle(
              color: timeColor,
              fontWeight: isActive ? FontWeight.w700 : FontWeight.w600,
              fontFeatures: const [FontFeature.tabularFigures()],
              fontSize: 12,
              height: 1.1,
            ),
          ),
        ],
      ),
    );

    if (!isActive) {
      return content;
    }

    // Flat active wash — no outer padding chip / elevation.
    return Padding(
      padding: const EdgeInsets.all(4),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white.withValues(
            alpha: HomePrayerScheduleStrip._activeFillOpacity,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: content,
      ),
    );
  }
}

bool _isFiveDaily(PrayerType type) {
  return switch (type) {
    PrayerType.fajr ||
    PrayerType.dhuhr ||
    PrayerType.asr ||
    PrayerType.maghrib ||
    PrayerType.isha => true,
    _ => false,
  };
}

String _formatStripTime(DateTime time) {
  final int hour = time.hour;
  final String minute = time.minute.toString().padLeft(2, '0');
  return '$hour:$minute';
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
