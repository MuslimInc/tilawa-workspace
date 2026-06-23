import '../entities/local_time.dart';
import '../entities/time_range.dart';

/// Removes [hole] from [ranges], splitting any overlapping interval.
List<TimeRange> subtractInterval(List<TimeRange> ranges, TimeRange hole) {
  final remaining = <TimeRange>[];
  for (final range in ranges) {
    if (!range.overlaps(hole)) {
      remaining.add(range);
      continue;
    }
    if (hole.start > range.start) {
      remaining.add(TimeRange(start: range.start, end: hole.start));
    }
    if (hole.end < range.end) {
      remaining.add(TimeRange(start: hole.end, end: range.end));
    }
  }
  return remaining.where((range) => range.isValid).toList();
}

TimeRange localTimeRange({
  required LocalTime start,
  required int durationMinutes,
}) => TimeRange(
  start: start,
  end: LocalTime.fromMinutes(start.minutesSinceMidnight + durationMinutes),
);
