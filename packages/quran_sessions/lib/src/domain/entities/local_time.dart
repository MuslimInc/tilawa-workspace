import 'package:equatable/equatable.dart';

/// A wall-clock time of day with no date and no timezone — e.g. `09:00`.
///
/// Availability rules are authored in the **teacher's local wall clock**; the
/// absolute instant is resolved later by [SlotGenerator] using the teacher's
/// IANA zone. Keeping this a pure value (no [DateTime], no `TimeOfDay`) keeps
/// the domain free of Flutter and of hidden timezone assumptions.
///
/// [minute] is 0–59. [hour] is 0–24, where `24:00` is permitted **only** as an
/// exclusive end-of-day bound (see [TimeRange]); it represents midnight at the
/// end of the day.
class LocalTime extends Equatable implements Comparable<LocalTime> {
  const LocalTime(this.hour, this.minute)
    : assert(hour >= 0 && hour <= 24, 'hour must be 0..24'),
      assert(minute >= 0 && minute <= 59, 'minute must be 0..59'),
      assert(hour * 60 + minute <= 24 * 60, 'must not exceed 24:00');

  final int hour;
  final int minute;

  /// Minutes elapsed since 00:00 (0–1440).
  int get minutesSinceMidnight => hour * 60 + minute;

  /// Builds a [LocalTime] from [minutesSinceMidnight] (0–1440).
  factory LocalTime.fromMinutes(int minutes) {
    assert(minutes >= 0 && minutes <= 24 * 60, 'minutes must be 0..1440');
    return LocalTime(minutes ~/ 60, minutes % 60);
  }

  /// Parses a canonical `HH:mm` string (e.g. `'09:00'`, `'24:00'`).
  factory LocalTime.parse(String value) {
    final parts = value.split(':');
    if (parts.length != 2) {
      throw FormatException('Expected HH:mm', value);
    }
    return LocalTime(int.parse(parts[0]), int.parse(parts[1]));
  }

  /// Canonical `HH:mm` serialization (24-hour, zero-padded).
  String toHmm() =>
      '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';

  @override
  int compareTo(LocalTime other) =>
      minutesSinceMidnight - other.minutesSinceMidnight;

  bool operator <(LocalTime other) => compareTo(other) < 0;
  bool operator <=(LocalTime other) => compareTo(other) <= 0;
  bool operator >(LocalTime other) => compareTo(other) > 0;
  bool operator >=(LocalTime other) => compareTo(other) >= 0;

  @override
  List<Object?> get props => [hour, minute];

  @override
  String toString() => toHmm();
}
