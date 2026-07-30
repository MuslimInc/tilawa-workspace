import 'package:flutter/material.dart';
import 'package:tilawa/core/extensions.dart';
import 'package:tilawa/features/home/domain/entities/home_prayer_slot.dart';
import 'package:tilawa/features/home/presentation/formatters/home_prayer_time_format.dart';
import 'package:tilawa/features/prayer_times/domain/entities/prayer_time_entity.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

/// Five-prayer strip — soft gold parchment panel on the green hero.
class HomePrayerScheduleStrip extends StatelessWidget {
  const HomePrayerScheduleStrip({
    super.key,
    required this.slots,
    required this.use24HourFormat,
    this.onOpenPrayer,
  });

  final List<HomePrayerSlot> slots;
  final bool use24HourFormat;
  final VoidCallback? onOpenPrayer;

  /// Day strip height — label + time + padding (readable at default scale).
  static double stripHeightFor(MeMuslimDesignTokens tokens) {
    return tokens.minInteractiveDimension + tokens.spaceLarge;
  }

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
    final bool isDark = theme.brightness == Brightness.dark;
    final TilawaHomeScreenTokens screenTokens =
        theme.componentTokens.homeScreen;
    final BorderRadius radius = BorderRadius.all(
      Radius.circular(
        tokens.resolveRadius(family: TilawaRadiusFamily.chrome),
      ),
    );
    // Warm hairline — gold/tertiary on dark parchment; parchment border on light.
    final Color border = isDark
        ? colorScheme.tertiary.withValues(alpha: tokens.opacityMedium)
        : Color.alphaBlend(
            screenTokens.homePrayerHeroBorder.withValues(alpha: 0.88),
            colorScheme.outlineVariant.withValues(alpha: 0.35),
          );
    final Color divider = isDark
        ? colorScheme.tertiary.withValues(
            alpha: (tokens.opacitySubtle + tokens.opacityMedium) / 2,
          )
        : Color.alphaBlend(
            screenTokens.homePrayerHeroBorder.withValues(alpha: 0.72),
            colorScheme.outlineVariant.withValues(alpha: 0.45),
          );

    final Widget row = SizedBox(
      height: stripHeightFor(tokens),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: screenTokens.homeHeaderChipBackground,
          borderRadius: radius,
          border: Border.all(
            color: border,
            width: tokens.borderWidthThin,
          ),
        ),
        child: Padding(
          padding: EdgeInsets.all(tokens.spaceExtraSmall),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (int i = 0; i < five.length; i++) ...[
                if (i > 0)
                  VerticalDivider(
                    // 0.5 line + 1.0 horizontal pad each side.
                    width: tokens.borderWidthThin * 5,
                    thickness: tokens.borderWidthThin * 2,
                    indent: tokens.spaceLarge,
                    endIndent: tokens.spaceLarge,
                    color: divider,
                  ),
                Expanded(
                  child: _HomePrayerScheduleSlot(
                    slot: five[i],
                    use24HourFormat: use24HourFormat,
                  ),
                ),
              ],
            ],
          ),
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
    required this.use24HourFormat,
  });

  final HomePrayerSlot slot;
  final bool use24HourFormat;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final MeMuslimDesignTokens tokens = theme.tokens;
    final ColorScheme colorScheme = theme.colorScheme;
    final TilawaHomeScreenTokens screenTokens =
        theme.componentTokens.homeScreen;
    final bool isDark = theme.brightness == Brightness.dark;
    final bool isActive = slot.isNext;
    // Light: soft white chip on parchment. Dark: lifted wash on opaque gold panel.
    final Color activeFill = isDark
        ? Color.alphaBlend(
            colorScheme.onSurface.withValues(alpha: 0.14),
            screenTokens.homeHeaderChipBackground,
          )
        : colorScheme.surface.withValues(alpha: 0.92);
    final Color activeInk = colorScheme.onSurface;
    final Color inactiveInk = isDark
        ? colorScheme.onSurface.withValues(alpha: 0.84)
        : colorScheme.onSurface.withValues(alpha: 0.70);
    final Color labelColor = isActive
        ? activeInk
        : inactiveInk.withValues(alpha: isDark ? 0.80 : 0.60);
    final Color timeColor = isActive ? activeInk : inactiveInk;
    final String name = _localizedPrayerName(context, slot.type);
    final String timeLabel = HomePrayerTimeFormat.formatClock(
      slot.time,
      use24HourFormat: use24HourFormat,
      isArabic: context.isArabic,
    );
    // Brand tertiary (gilding) — token, not a hard-coded second accent system.
    final Color activeDot = colorScheme.tertiary;
    final BorderRadius activeRadius = BorderRadius.all(
      Radius.circular(
        tokens.resolveRadius(family: TilawaRadiusFamily.chip),
      ),
    );
    final TextStyle labelStyle = theme.textTheme.labelMedium!.copyWith(
      color: labelColor,
      fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
      height: 1.2,
    );
    final TextStyle timeStyle = theme.textTheme.bodySmall!.copyWith(
      color: timeColor,
      fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
      fontFeatures: const [FontFeature.tabularFigures()],
      height: 1.2,
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
        padding: EdgeInsets.symmetric(
          horizontal: tokens.spaceExtraSmall,
          vertical: tokens.spaceSmall,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          spacing: tokens.spaceExtraSmall,
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
                    child: SizedBox.square(dimension: tokens.spaceSmall),
                  ),
                Flexible(
                  child: Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: labelStyle,
                  ),
                ),
              ],
            ),
            Text(
              timeLabel,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: timeStyle,
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
