import 'package:flutter/material.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

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
    final tokens = Theme.of(context).tokens;
    final List<PrayerTimeItem> prayers = showSunrise
        ? prayerTimes.allPrayers
        : prayerTimes.allPrayers
              .where((p) => p.type != PrayerType.sunrise)
              .toList();

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: tokens.spaceLarge,
        vertical: tokens.spaceSmall,
      ),
      child: Column(
        children: prayers.map((prayer) {
          final isNext = currentPrayer?.type == prayer.type;
          final bool hasPassed = prayerTimes.hasPrayerPassed(prayer.type);

          return Padding(
            padding: EdgeInsets.only(bottom: tokens.spaceSmall),
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
