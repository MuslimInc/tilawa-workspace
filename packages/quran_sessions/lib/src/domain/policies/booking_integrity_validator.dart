import 'package:dartz_plus/dartz_plus.dart';

import '../failures/quran_sessions_failure.dart';

class BookingIntegritySnapshot {
  const BookingIntegritySnapshot({
    required this.slotAvailable,
    required this.teacherActive,
    required this.studentActive,
    required this.marketEnabled,
    required this.startsAt,
    required this.minNotice,
    required this.maxAdvanceHorizon,
    this.now = _nowUtc,
  });

  final bool slotAvailable;
  final bool teacherActive;
  final bool studentActive;
  final bool marketEnabled;
  final DateTime startsAt;
  final Duration minNotice;
  final Duration maxAdvanceHorizon;
  final DateTime Function() now;
}

class BookingIntegrityValidator {
  const BookingIntegrityValidator();

  Either<QuranSessionsFailure, void> validate(
    BookingIntegritySnapshot snapshot,
  ) {
    if (!snapshot.slotAvailable) {
      return const Left(SlotUnavailableFailure('taken_slot'));
    }
    if (!snapshot.teacherActive) {
      return const Left(
        PolicyViolationFailure(
          policyName: 'teacher_availability',
          detail: 'teacher_suspended',
        ),
      );
    }
    if (!snapshot.studentActive) {
      return const Left(
        PolicyViolationFailure(
          policyName: 'student_eligibility',
          detail: 'student_suspended',
        ),
      );
    }
    if (!snapshot.marketEnabled) {
      return const Left(
        PolicyViolationFailure(
          policyName: 'market',
          detail: 'market_disabled',
        ),
      );
    }

    final remaining = snapshot.startsAt.difference(snapshot.now());
    if (remaining < snapshot.minNotice) {
      return const Left(
        PolicyViolationFailure(
          policyName: 'booking_notice',
          detail: 'below_min_notice',
        ),
      );
    }
    if (remaining > snapshot.maxAdvanceHorizon) {
      return const Left(
        PolicyViolationFailure(
          policyName: 'booking_horizon',
          detail: 'beyond_max_horizon',
        ),
      );
    }
    return const Right(null);
  }
}

DateTime _nowUtc() => DateTime.now().toUtc();
