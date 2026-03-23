import 'package:flutter/material.dart';
import 'package:tilawa/core/extensions.dart';

import '../../domain/entities/entities.dart';

extension PrayerTypeLocalization on PrayerType {
  String localizedName(BuildContext context) {
    return switch (this) {
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
}
