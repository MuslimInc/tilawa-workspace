import 'package:flutter/material.dart';

import '../../domain/entities/entities.dart';
import 'prayer_time_card.dart';

class PrayerTimesGrid extends StatelessWidget {
  const PrayerTimesGrid({
    super.key,
    required this.prayerTimes,
    this.currentPrayer,
    this.use24HourFormat = true,
  });

  final PrayerTimeEntity prayerTimes;
  final PrayerTimeItem? currentPrayer;
  final bool use24HourFormat;

  @override
  Widget build(BuildContext context) {
    // The screen shot displays 4 rows of 2 columns
    // The order should be:
    // row 1: Sunrise, Fajr
    // row 2: Asr, Dhuhr
    // row 3: Isha, Maghrib
    // row 4: Last Third, Midnight
    //
    // Note: Due to RTL directionality in Arabic, the grid will naturally
    // place item 0 on the Right and item 1 on the Left. Setting up the list
    // chronologically [Fajr, Sunrise, Dhuhr, Asr, ...] will map correctly:
    // [Fajr(Right), Sunrise(Left)]

    final List<PrayerTimeItem> gridItems = [
      _getPrayer(PrayerType.fajr),
      _getPrayer(PrayerType.sunrise),
      _getPrayer(PrayerType.dhuhr),
      _getPrayer(PrayerType.asr),
      _getPrayer(PrayerType.maghrib),
      _getPrayer(PrayerType.isha),
      _getPrayer(PrayerType.midnight),
      _getPrayer(PrayerType.lastThird),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        const double spacing = 14;
        final double textScale = MediaQuery.textScalerOf(context).scale(1);
        final int crossAxisCount = constraints.maxWidth >= 980
            ? 4
            : constraints.maxWidth >= 680
            ? 3
            : 2;
        final double itemWidth =
            (constraints.maxWidth - (spacing * (crossAxisCount - 1))) /
            crossAxisCount;
        final bool compact = itemWidth < 180;
        final double mainAxisExtent =
            (compact ? 202.0 : 190.0) +
            ((textScale - 1.0).clamp(0.0, 0.6) * 28);

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            mainAxisExtent: mainAxisExtent,
            crossAxisSpacing: spacing,
            mainAxisSpacing: spacing,
          ),
          itemCount: gridItems.length,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemBuilder: (context, index) {
            final prayer = gridItems[index];
            final isNext = currentPrayer?.type == prayer.type;
            final bool hasPassed = prayerTimes.hasPrayerPassed(prayer.type);

            return PrayerTimeCard(
              prayer: prayer,
              isNext: isNext,
              hasPassed: hasPassed && !isNext,
              use24HourFormat: use24HourFormat,
            );
          },
        );
      },
    );
  }

  PrayerTimeItem _getPrayer(PrayerType type) {
    return prayerTimes.allPrayers.firstWhere((p) => p.type == type);
  }
}
