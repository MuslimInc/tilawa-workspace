/// When RTC join credentials may be prefetched before the user taps Join.
class SessionJoinWindowPolicy {
  const SessionJoinWindowPolicy({
    this.prefetchLeadTime = const Duration(minutes: 15),
    this.postStartGrace = const Duration(hours: 2),
  });

  final Duration prefetchLeadTime;
  final Duration postStartGrace;

  /// True when [now] is inside the join window for a session starting at
  /// [startsAt].
  bool isWithinJoinWindow({
    required DateTime startsAt,
    required DateTime now,
  }) {
    final windowStart = startsAt.subtract(prefetchLeadTime);
    final windowEnd = startsAt.add(postStartGrace);
    return !now.isBefore(windowStart) && now.isBefore(windowEnd);
  }
}
