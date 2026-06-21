import 'package:equatable/equatable.dart';

import 'availability_override.dart';
import 'time_range.dart';

/// Consecutive calendar days that share the same override configuration.
class AvailabilityOverrideGroup extends Equatable {
  const AvailabilityOverrideGroup({
    required this.start,
    required this.end,
    required this.type,
    required this.intervals,
    required this.dateKeys,
  });

  final DateTime start;
  final DateTime end;
  final OverrideType type;
  final List<TimeRange> intervals;
  final List<String> dateKeys;

  bool get isSingleDay => dateKeys.length == 1;

  @override
  List<Object?> get props => [start, end, type, intervals, dateKeys];
}

/// Groups sorted overrides into consecutive runs with identical config.
List<AvailabilityOverrideGroup> groupAvailabilityOverrides(
  List<AvailabilityOverride> overrides,
) {
  if (overrides.isEmpty) return const <AvailabilityOverrideGroup>[];

  final sorted = List<AvailabilityOverride>.from(overrides)
    ..sort((a, b) => a.date.compareTo(b.date));

  final groups = <AvailabilityOverrideGroup>[];
  var runStart = sorted.first;
  var runEnd = sorted.first;
  final keys = <String>[sorted.first.dateKey];

  for (var i = 1; i < sorted.length; i++) {
    final current = sorted[i];
    if (_sameConfig(runStart, current) &&
        _isNextCalendarDay(runEnd.date, current.date)) {
      runEnd = current;
      keys.add(current.dateKey);
    } else {
      groups.add(_toGroup(runStart, runEnd, keys));
      runStart = current;
      runEnd = current;
      keys
        ..clear()
        ..add(current.dateKey);
    }
  }
  groups.add(_toGroup(runStart, runEnd, keys));
  return groups;
}

AvailabilityOverrideGroup _toGroup(
  AvailabilityOverride start,
  AvailabilityOverride end,
  List<String> keys,
) => AvailabilityOverrideGroup(
  start: start.date,
  end: end.date,
  type: start.type,
  intervals: start.intervals,
  dateKeys: List.unmodifiable(keys),
);

bool _sameConfig(AvailabilityOverride a, AvailabilityOverride b) {
  if (a.type != b.type || a.reason != b.reason) return false;
  if (a.intervals.length != b.intervals.length) return false;
  for (var i = 0; i < a.intervals.length; i++) {
    if (a.intervals[i] != b.intervals[i]) return false;
  }
  return true;
}

bool _isNextCalendarDay(DateTime previous, DateTime next) {
  final normalized = DateTime(previous.year, previous.month, previous.day);
  final expected = normalized.add(const Duration(days: 1));
  return next.year == expected.year &&
      next.month == expected.month &&
      next.day == expected.day;
}
