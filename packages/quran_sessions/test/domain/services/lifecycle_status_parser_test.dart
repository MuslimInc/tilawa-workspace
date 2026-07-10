import 'package:checks/checks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_sessions/quran_sessions.dart';

void main() {
  group('parseLifecycleStatusFromRaw', () {
    test('maps tutor_cancelled legacy alias to cancelledByTeacher', () {
      check(
        parseLifecycleStatusFromRaw('tutor_cancelled'),
      ).equals(SessionLifecycleStatus.cancelledByTeacher);
    });

    test('maps student_cancelled legacy alias to cancelledByStudent', () {
      check(
        parseLifecycleStatusFromRaw('student_cancelled'),
      ).equals(SessionLifecycleStatus.cancelledByStudent);
    });

    test('maps canonical enum names', () {
      check(
        parseLifecycleStatusFromRaw('scheduled'),
      ).equals(SessionLifecycleStatus.scheduled);
      check(
        parseLifecycleStatusFromRaw('cancelled_by_teacher'),
      ).equals(SessionLifecycleStatus.cancelledByTeacher);
    });
  });

  group('parseSessionActionFromRaw', () {
    test('maps tutor_cancelled legacy alias to cancelByTeacher', () {
      check(
        parseSessionActionFromRaw('tutor_cancelled'),
      ).equals(SessionAction.cancelByTeacher);
    });

    test('maps finalizer sweep audit actions to timeline-safe actions', () {
      check(
        parseSessionActionFromRaw('expire_unattended_session'),
      ).equals(SessionAction.expireReservation);
      check(
        parseSessionActionFromRaw('finalize_completed_session'),
      ).equals(SessionAction.completeSession);
    });
  });

  group('tryParseLifecycleStatusFromRaw', () {
    test('returns null for unknown free-form text', () {
      check(tryParseLifecycleStatusFromRaw('Running late')).isNull();
    });
  });

  group('resolveLifecycleStatusRawFromFirestore', () {
    test('prefers legacy cancelled status over stale lifecycle', () {
      check(
        resolveLifecycleStatusRawFromFirestore({
          'status': 'cancelled',
          'cancelledByRole': 'teacher',
          'lifecycleStatus': 'scheduled',
        }),
      ).equals('cancelled_by_teacher');
    });

    test('infers tutor_cancelled reason when lifecycle missing', () {
      check(
        resolveLifecycleStatusRawFromFirestore({
          'status': 'confirmed',
          'cancellationReason': 'tutor_cancelled',
        }),
      ).equals('cancelled_by_teacher');
    });
  });

  group('resolveBookingIdFromFirestore', () {
    test('falls back to document id when bookingId empty', () {
      check(
        resolveBookingIdFromFirestore('session-doc-id', const {}),
      ).equals('session-doc-id');
    });
  });
}
