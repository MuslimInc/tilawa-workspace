import 'package:tilawa/features/prayer_times/presentation/formatters/prayer_time_label_formatter.dart';

/// Home-header clock formatting — delegates to prayer-time label rules.
///
/// Keeps Home widgets free of DateFormat / 12–24 branching (SRP). The
/// [use24HourFormat] flag is domain config from the dashboard snapshot,
/// not a hard-coded presentation choice (DIP).
abstract final class HomePrayerTimeFormat {
  static String formatClock(
    DateTime time, {
    required bool use24HourFormat,
    required bool isArabic,
  }) {
    return PrayerTimeLabelFormatter.formatDateTime(
      time,
      use24HourFormat: use24HourFormat,
      isArabic: isArabic,
    );
  }
}
