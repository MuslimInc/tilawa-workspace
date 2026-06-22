import '../entities/session_lifecycle_status.dart';

class NoShowPolicyConfig {
  const NoShowPolicyConfig({
    this.gracePeriod = const Duration(minutes: 10),
  });

  final Duration gracePeriod;
}

class NoShowPolicy {
  const NoShowPolicy({
    this.config = const NoShowPolicyConfig(),
    this.now = _nowUtc,
  });

  final NoShowPolicyConfig config;
  final DateTime Function() now;

  SessionLifecycleStatus classify({
    required DateTime startsAt,
    required bool teacherJoined,
    required bool studentJoined,
  }) {
    final isPastGrace = now().isAfter(startsAt.add(config.gracePeriod));
    if (!isPastGrace) {
      return SessionLifecycleStatus.inProgress;
    }
    if (!teacherJoined && studentJoined) {
      return SessionLifecycleStatus.teacherNoShow;
    }
    if (teacherJoined && !studentJoined) {
      return SessionLifecycleStatus.studentNoShow;
    }
    if (!teacherJoined && !studentJoined) {
      return SessionLifecycleStatus.bothNoShow;
    }
    return SessionLifecycleStatus.inProgress;
  }
}

DateTime _nowUtc() => DateTime.now().toUtc();
