import 'package:flutter/material.dart';
import 'package:tilawa/core/extensions.dart';
import 'package:tilawa/features/home/domain/entities/home_prayer_slot.dart';
import 'package:tilawa/features/prayer_times/domain/entities/prayer_time_entity.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

/// Five-prayer strip — MeMuslim Figma `prayers-row` CSS.
class HomePrayerScheduleStrip extends StatelessWidget {
  const HomePrayerScheduleStrip({
    super.key,
    required this.slots,
    this.onOpenPrayer,
  });

  final List<HomePrayerSlot> slots;
  final VoidCallback? onOpenPrayer;

  /// Figma: height 52, radius 16, fill 0.1 / border 0.12.
  static const double stripHeight = 52;

  @override
  Widget build(BuildContext context) {
    final List<HomePrayerSlot> five = [
      for (final HomePrayerSlot slot in slots)
        if (_isFiveDaily(slot.type)) slot,
    ];
    if (five.isEmpty) {
      return const SizedBox.shrink();
    }

    const BorderRadius radius = BorderRadius.all(Radius.circular(16));

    final Widget row = SizedBox(
      height: stripHeight,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: const Color.fromRGBO(255, 255, 255, 0.1),
          borderRadius: radius,
          border: Border.all(
            color: const Color.fromRGBO(255, 255, 255, 0.12),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final HomePrayerSlot slot in five)
              Expanded(child: _HomePrayerScheduleSlot(slot: slot)),
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
  const _HomePrayerScheduleSlot({required this.slot});

  final HomePrayerSlot slot;

  @override
  Widget build(BuildContext context) {
    final bool isActive = slot.isNext;
    // Figma inactive: rgba(255,255,255,0.501961)
    const Color inactive = Color.fromRGBO(255, 255, 255, 0.5);
    final Color labelColor = isActive ? Colors.white : inactive;
    final Color timeColor = isActive ? Colors.white : inactive;
    final String name = _localizedPrayerName(context, slot.type);
    final String timeLabel = _formatStripTime(slot.time);
    // Brand tertiary (gilding) — token, not a hard-coded second accent system.
    final Color activeDot = Theme.of(context).colorScheme.tertiary;

    // Figma active fills the whole flex cell (padding 8 0, radius 12) — no inset chip.
    return DecoratedBox(
      decoration: isActive
          ? const BoxDecoration(
              color: Color.fromRGBO(255, 255, 255, 0.2),
              borderRadius: BorderRadius.all(Radius.circular(12)),
            )
          : const BoxDecoration(),
      child: Padding(
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
                      color: activeDot,
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
                      height: 15 / 10,
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
                height: 18 / 12,
              ),
            ),
          ],
        ),
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
