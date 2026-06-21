import 'package:equatable/equatable.dart';

import 'time_range.dart';

/// How a dated override changes a single calendar day.
enum OverrideType {
  /// The day generates **no** slots, beating the recurring weekly rule —
  /// vacations, holidays, "busy".
  unavailable,

  /// The day's [AvailabilityOverride.intervals] **replace** the weekly rule —
  /// covers both "different hours today" and "open on a normally-closed day".
  custom,
}

/// A one-off change to a specific calendar [date] that takes precedence over
/// the recurring [WeeklySchedule]. [date] is a teacher-local calendar date;
/// only its year/month/day are significant (see [dateKey]).
class AvailabilityOverride extends Equatable {
  AvailabilityOverride({
    required DateTime date,
    required this.type,
    this.intervals = const <TimeRange>[],
    this.reason,
  }) : date = DateTime(date.year, date.month, date.day);

  final DateTime date;
  final OverrideType type;

  /// Replacement intervals — only meaningful when [type] is [OverrideType.custom].
  final List<TimeRange> intervals;

  /// Optional machine-readable reason, e.g. `'vacation'` or `'busy'`.
  final String? reason;

  /// Stable `yyyy-MM-dd` key used for storage doc ids and lookups.
  String get dateKey =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';

  AvailabilityOverride copyWith({
    DateTime? date,
    OverrideType? type,
    List<TimeRange>? intervals,
    String? reason,
  }) => AvailabilityOverride(
    date: date ?? this.date,
    type: type ?? this.type,
    intervals: intervals ?? this.intervals,
    reason: reason ?? this.reason,
  );

  @override
  List<Object?> get props => [date, type, intervals, reason];
}
