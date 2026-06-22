import 'package:equatable/equatable.dart';

/// Inclusive calendar-date bounds for a Sat→Fri (or configured) week bucket.
class WeekAvailabilityWindow extends Equatable {
  const WeekAvailabilityWindow({
    required this.weekKey,
    required this.startDate,
    required this.endDate,
  });

  /// Stable `yyyy-MM-dd` key for the week start (Saturday by default).
  final String weekKey;

  /// First calendar day in the week (local, date-only).
  final DateTime startDate;

  /// Last calendar day in the week (local, date-only).
  final DateTime endDate;

  bool containsLocalDate(DateTime localDate) {
    final d = DateTime(localDate.year, localDate.month, localDate.day);
    return !d.isBefore(startDate) && !d.isAfter(endDate);
  }

  @override
  List<Object?> get props => [weekKey, startDate, endDate];
}
