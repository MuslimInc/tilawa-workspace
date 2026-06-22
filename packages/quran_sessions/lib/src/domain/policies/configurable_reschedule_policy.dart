import 'package:dartz_plus/dartz_plus.dart';

import '../failures/quran_sessions_failure.dart';

class ReschedulePolicyConfig {
  const ReschedulePolicyConfig({
    this.maxReschedules = 1,
    this.minNotice = const Duration(hours: 24),
  });

  final int maxReschedules;
  final Duration minNotice;
}

class ConfigurableReschedulePolicy {
  const ConfigurableReschedulePolicy({
    this.config = const ReschedulePolicyConfig(),
    this.now = _nowUtc,
  });

  final ReschedulePolicyConfig config;
  final DateTime Function() now;

  Either<QuranSessionsFailure, void> validate({
    required DateTime startsAt,
    required int currentRescheduleCount,
  }) {
    if (currentRescheduleCount >= config.maxReschedules) {
      return const Left(
        PolicyViolationFailure(
          policyName: 'reschedule_limit',
          detail: 'max_reschedules_reached',
        ),
      );
    }

    final remaining = startsAt.difference(now());
    if (remaining < config.minNotice) {
      return const Left(
        PolicyViolationFailure(
          policyName: 'reschedule_notice',
          detail: 'below_min_notice',
        ),
      );
    }
    return const Right(null);
  }
}

DateTime _nowUtc() => DateTime.now().toUtc();
