import 'package:equatable/equatable.dart';

import 'local_time.dart';

/// A half-open wall-clock interval `[start, end)` within a single day.
///
/// `end` is exclusive. Midnight-crossing ranges are **not** representable —
/// the editor splits an overnight span into two ranges so that [SlotGenerator]
/// can reason one calendar day at a time.
class TimeRange extends Equatable {
  const TimeRange({required this.start, required this.end});

  final LocalTime start;
  final LocalTime end;

  /// True when [start] is strictly before [end] (a non-empty interval).
  bool get isValid => start < end;

  /// Length of the interval in minutes.
  int get durationMinutes =>
      end.minutesSinceMidnight - start.minutesSinceMidnight;

  /// Whether this interval overlaps [other] (touching edges do not count).
  bool overlaps(TimeRange other) => start < other.end && other.start < end;

  /// Whether this interval is fully before [other] with no overlap or touch.
  bool isBefore(TimeRange other) => end <= other.start;

  @override
  List<Object?> get props => [start, end];

  @override
  String toString() => '${start.toHmm()}-${end.toHmm()}';
}
