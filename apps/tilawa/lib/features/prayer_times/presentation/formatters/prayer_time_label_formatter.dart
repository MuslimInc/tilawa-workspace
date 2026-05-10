import 'package:intl/intl.dart';

import '../../domain/entities/entities.dart';

/// Formats prayer times consistently across Prayer Times presentation widgets.
abstract final class PrayerTimeLabelFormatter {
  static String formatItem(
    PrayerTimeItem prayer, {
    required bool use24HourFormat,
    required bool isArabic,
  }) {
    return formatDateTime(
      prayer.time,
      use24HourFormat: use24HourFormat,
      isArabic: isArabic,
    );
  }

  static String formatDateTime(
    DateTime time, {
    required bool use24HourFormat,
    required bool isArabic,
  }) {
    final locale = isArabic ? 'ar' : 'en';
    final formatter = use24HourFormat
        ? DateFormat.Hm(locale)
        : DateFormat.jm(locale);
    return formatter.format(time);
  }
}
