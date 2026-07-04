import 'platform_scheduling_policy.dart';
import 'staging_qa_join_window_bypass.dart';

/// When RTC join credentials may be prefetched before the user taps Join.
class SessionJoinWindowPolicy {
  const SessionJoinWindowPolicy({
    this.prefetchLeadTime = PlatformSchedulingPolicy.joinWindowLeadTime,
    this.distribution = stagingQaJoinWindowBypassDefaultDistribution,
  });

  final Duration prefetchLeadTime;
  final String distribution;

  /// True when [now] is inside the join window (Q-VC-03: 15m before until endsAt).
  ///
  /// When [qaBypassUserId] is a staging QA account, window timing is skipped.
  bool isWithinJoinWindow({
    required DateTime startsAt,
    required DateTime endsAt,
    required DateTime now,
    String? qaBypassUserId,
  }) {
    if (isQaJoinWindowBypassEligible(
      userId: qaBypassUserId,
      distribution: distribution,
    )) {
      return true;
    }

    final windowStart = startsAt.subtract(prefetchLeadTime);
    return !now.isBefore(windowStart) && !now.isAfter(endsAt);
  }
}
