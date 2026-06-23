import 'package:equatable/equatable.dart';

import 'scheduling_policy.dart';
import 'slot_duration.dart';
import 'time_range.dart';
import 'weekday.dart';

/// A teacher's recurring weekly availability — the single source of truth from
/// which bookable slots are generated. Open slots are **never** stored; they
/// are `rules − overrides − bookings`, computed on demand by [SlotGenerator].
///
/// [timezone] is an IANA zone id (e.g. `'Africa/Cairo'`). All [rules] are
/// authored in this zone's wall clock.
class WeeklySchedule extends Equatable {
  const WeeklySchedule({
    required this.teacherId,
    required this.timezone,
    required this.slotDuration,
    required this.rules,
    this.policy = SchedulingPolicy.standard,
    this.version = 1,
    this.updatedAt,
  });

  final String teacherId;

  /// IANA timezone id the [rules] are expressed in.
  final String timezone;

  final SlotDuration slotDuration;

  /// Wall-clock intervals per weekday. A missing key or empty list = closed.
  final Map<Weekday, List<TimeRange>> rules;

  final SchedulingPolicy policy;

  /// Monotonic schema/version counter, bumped on each save for optimistic
  /// concurrency and migrations.
  final int version;

  final DateTime? updatedAt;

  /// An all-closed schedule with sensible defaults — the starting point for a
  /// teacher who has never configured availability.
  factory WeeklySchedule.empty({
    required String teacherId,
    required String timezone,
  }) => WeeklySchedule(
    teacherId: teacherId,
    timezone: timezone,
    slotDuration: SlotDuration.thirty,
    rules: {for (final day in Weekday.values) day: const <TimeRange>[]},
  );

  /// Intervals configured for [day] (empty when closed).
  List<TimeRange> rangesFor(Weekday day) => rules[day] ?? const <TimeRange>[];

  /// Whether [day] has at least one interval.
  bool isOpenOn(Weekday day) => rangesFor(day).isNotEmpty;

  /// Days with at least one interval, in canonical Sat→Fri order.
  Iterable<Weekday> get openDays => Weekday.values.where(isOpenOn);

  /// True when no day has any availability.
  bool get isEmpty => Weekday.values.every((d) => rangesFor(d).isEmpty);

  /// Deep-copies [rules] so draft edits cannot mutate a shared [baseline].
  WeeklySchedule detached() => copyWith(
    rules: {
      for (final day in Weekday.values) day: List.unmodifiable(rangesFor(day)),
    },
  );

  WeeklySchedule copyWith({
    String? teacherId,
    String? timezone,
    SlotDuration? slotDuration,
    Map<Weekday, List<TimeRange>>? rules,
    SchedulingPolicy? policy,
    int? version,
    DateTime? updatedAt,
  }) => WeeklySchedule(
    teacherId: teacherId ?? this.teacherId,
    timezone: timezone ?? this.timezone,
    slotDuration: slotDuration ?? this.slotDuration,
    rules: rules ?? this.rules,
    policy: policy ?? this.policy,
    version: version ?? this.version,
    updatedAt: updatedAt ?? this.updatedAt,
  );

  /// Returns a copy with [day]'s intervals replaced by [ranges].
  WeeklySchedule withDay(Weekday day, List<TimeRange> ranges) {
    final next = Map<Weekday, List<TimeRange>>.from(rules);
    next[day] = List.unmodifiable(ranges);
    return copyWith(rules: next);
  }

  @override
  List<Object?> get props => [
    teacherId,
    timezone,
    slotDuration,
    // Map equality is needed; flatten deterministically in Sat→Fri order.
    for (final day in Weekday.values) ...[day, rangesFor(day)],
    policy,
    version,
    updatedAt,
  ];
}
