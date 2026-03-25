import 'package:flutter/material.dart';

import '../../domain/entities/entities.dart';
import 'prayer_time_card.dart';

class PrayerTimesList extends StatelessWidget {
  const PrayerTimesList({
    super.key,
    required this.prayerTimes,
    this.currentPrayer,
    this.use24HourFormat = true,
    this.showSunrise = false,
  });

  final PrayerTimeEntity prayerTimes;
  final PrayerTimeItem? currentPrayer;
  final bool use24HourFormat;
  final bool showSunrise;

  @override
  Widget build(BuildContext context) {
    final List<PrayerTimeItem> prayers = showSunrise
        ? prayerTimes.allPrayers
        : prayerTimes.allPrayers
              .where((p) => p.type != PrayerType.sunrise)
              .toList();

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: prayers.map((prayer) {
          final isNext = currentPrayer?.type == prayer.type;
          final bool hasPassed = prayerTimes.hasPrayerPassed(prayer.type);

          return Padding(
            padding: EdgeInsets.only(bottom: 8),
            child: PrayerTimeCard(
              prayer: prayer,
              isNext: isNext,
              hasPassed: hasPassed && !isNext,
              use24HourFormat: use24HourFormat,
            ),
          );
        }).toList(),
      ),
    );
  }
}
