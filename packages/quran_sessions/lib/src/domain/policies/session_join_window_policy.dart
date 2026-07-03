import 'platform_scheduling_policy.dart';

/// When RTC join credentials may be prefetched before the user taps Join.
class SessionJoinWindowPolicy {
  const SessionJoinWindowPolicy({
    this.prefetchLeadTime = PlatformSchedulingPolicy.joinWindowLeadTime,
  });

  final Duration prefetchLeadTime;

  /// True when [now] is inside the join window (Q-VC-03: 15m before until endsAt).
  bool isWithinJoinWindow({
    required DateTime startsAt,
    required DateTime endsAt,
    required DateTime now,
  }) {
    final windowStart = startsAt.subtract(prefetchLeadTime);
    return !now.isBefore(windowStart) && !now.isAfter(endsAt);
  }
}
