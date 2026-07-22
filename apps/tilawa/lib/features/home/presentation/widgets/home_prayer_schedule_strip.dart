import 'package:flutter/material.dart';
import 'package:tilawa/core/extensions.dart';
import 'package:tilawa/features/home/domain/entities/home_prayer_slot.dart';
import 'package:tilawa/features/prayer_times/domain/entities/prayer_time_entity.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

/// Five-prayer strip — soft sage panel on the green hero.
class HomePrayerScheduleStrip extends StatelessWidget {
  const HomePrayerScheduleStrip({
    super.key,
    required this.slots,
    this.onOpenPrayer,
  });

  final List<HomePrayerSlot> slots;
  final VoidCallback? onOpenPrayer;

  /// Compact day strip height (name + time).
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

    final ThemeData theme = Theme.of(context);
    final MeMuslimDesignTokens tokens = theme.tokens;
    final ColorScheme colorScheme = theme.colorScheme;
    final TilawaHomeScreenTokens screenTokens =
        theme.componentTokens.homeScreen;
    final BorderRadius radius = BorderRadius.all(
      Radius.circular(
        tokens.resolveRadius(family: TilawaRadiusFamily.chrome),
      ),
    );
    final Color border = Color.alphaBlend(
      screenTokens.homePrayerHeroBorder.withValues(alpha: 0.72),
      colorScheme.outlineVariant.withValues(alpha: 0.28),
    );

    final Widget row = SizedBox(
      height: stripHeight,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: screenTokens.homeHeaderChipBackground,
          borderRadius: radius,
          border: Border.all(
            color: border,
            width: tokens.borderWidthThin,
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
    final ThemeData theme = Theme.of(context);
    final MeMuslimDesignTokens tokens = theme.tokens;
    final ColorScheme colorScheme = theme.colorScheme;
    final TilawaHomeScreenTokens screenTokens =
        theme.componentTokens.homeScreen;
    final bool isDark = theme.brightness == Brightness.dark;
    final bool isActive = slot.isNext;
    // Light: soft white chip + dark ink on sage strip.
    // Dark: lifted dark glass + light ink (white chip reads as light-mode).
    final Color activeFill = isDark
        ? Color.alphaBlend(
            Colors.white.withValues(alpha: 0.16),
            colorScheme.surface,
          )
        : colorScheme.surface.withValues(alpha: 0.85);
    final Color activeInk = colorScheme.onSurface;
    final Color inactiveInk = isDark
        ? colorScheme.onSurface.withValues(alpha: 0.72)
        : screenTokens.homeHeaderSecondaryText;
    final Color labelColor = isActive ? activeInk : inactiveInk;
    final Color timeColor = labelColor;
    final String name = _localizedPrayerName(context, slot.type);
    final String timeLabel = _formatStripTime(slot.time);
    // Brand tertiary (gilding) — token, not a hard-coded second accent system.
    final Color activeDot = colorScheme.tertiary;
    final BorderRadius activeRadius = BorderRadius.all(
      Radius.circular(
        tokens.resolveRadius(family: TilawaRadiusFamily.chip),
      ),
    );

    // Active fills the whole flex cell — no inset chip.
    return DecoratedBox(
      decoration: isActive
          ? BoxDecoration(
              color: activeFill,
              borderRadius: activeRadius,
            )
          : const BoxDecoration(),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: tokens.spaceSmall),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          spacing: 3,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              spacing: tokens.spaceExtraSmall,
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
