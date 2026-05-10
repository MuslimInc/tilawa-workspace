import 'package:injectable/injectable.dart';

import '../prayer_times_clock.dart';

/// Decides whether loaded prayer-time data is stale for the current device time.
///
/// This use case intentionally checks only the minimal freshness signals that
/// are already available to the Prayer Times feature: the loaded local date and
/// the loaded UTC offset.
@injectable
class ShouldRefreshPrayerTimesUseCase {
  const ShouldRefreshPrayerTimesUseCase();

  bool call({required DateTime? loadedDate, Duration? loadedUtcOffset}) {
    if (loadedDate == null) {
      return true;
    }

    final now = PrayerTimesClock.now();
    if (!_isSameLocalDate(loadedDate, now)) {
      return true;
    }

    final offset = loadedUtcOffset ?? loadedDate.timeZoneOffset;
    return offset != now.timeZoneOffset;
  }

  bool _isSameLocalDate(DateTime left, DateTime right) {
    return left.year == right.year &&
        left.month == right.month &&
        left.day == right.day;
  }
}
