import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';

import '../../domain/entities/prayer_time_entity.dart';

/// UI-related extensions for PrayerType.
extension PrayerTypeUI on PrayerType {
  /// Get the appropriate icon for the prayer type.
  IconData get icon {
    switch (this) {
      case PrayerType.fajr:
        return FluentIcons.weather_haze_24_regular;
      case PrayerType.sunrise:
        return FluentIcons.weather_sunny_24_regular;
      case PrayerType.dhuhr:
        return FluentIcons.weather_sunny_high_24_regular;
      case PrayerType.asr:
        return FluentIcons.weather_sunny_low_24_regular;
      case PrayerType.maghrib:
        return FluentIcons.weather_moon_24_regular;
      case PrayerType.isha:
        return FluentIcons.weather_moon_24_filled;
      case PrayerType.midnight:
        return FluentIcons.weather_moon_off_24_regular;
      case PrayerType.lastThird:
        return FluentIcons.star_24_filled;
    }
  }
}
