import '../../history/domain/entities/history_entity.dart';

/// Consecutive-day engagement streak from listening history activity.
int quranEngagementStreakDays({
  required List<HistoryEntity> history,
  required DateTime today,
}) {
  if (history.isEmpty) {
    return 0;
  }

  final Set<String> activeDays = history
      .map((item) => _dateKey(item.playedAt))
      .toSet();
  final String todayKey = _dateKey(today);
  final String yesterdayKey = _dateKey(
    today.subtract(const Duration(days: 1)),
  );

  late final DateTime startDay;
  if (activeDays.contains(todayKey)) {
    startDay = today;
  } else if (activeDays.contains(yesterdayKey)) {
    startDay = today.subtract(const Duration(days: 1));
  } else {
    return 0;
  }

  var streak = 0;
  for (var day = startDay; activeDays.contains(_dateKey(day));) {
    streak++;
    day = day.subtract(const Duration(days: 1));
  }
  return streak;
}

String _dateKey(DateTime date) {
  final String month = date.month.toString().padLeft(2, '0');
  final String day = date.day.toString().padLeft(2, '0');
  return '${date.year}-$month-$day';
}
