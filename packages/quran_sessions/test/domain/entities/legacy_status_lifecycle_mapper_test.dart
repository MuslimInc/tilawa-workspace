import 'package:checks/checks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_sessions/quran_sessions.dart';

void main() {
  group('BookingStatusLifecycleMapper', () {
    test('maps legacy booking statuses to canonical lifecycle statuses', () {
      check(BookingStatus.pending.toLifecycleStatus()).equals(
        SessionLifecycleStatus.pendingPayment,
      );
      check(BookingStatus.confirmed.toLifecycleStatus()).equals(
        SessionLifecycleStatus.scheduled,
      );
      check(BookingStatus.rejected.toLifecycleStatus()).equals(
        SessionLifecycleStatus.expired,
      );
      check(BookingStatus.completed.toLifecycleStatus()).equals(
        SessionLifecycleStatus.completed,
      );
      check(BookingStatus.refunded.toLifecycleStatus()).equals(
        SessionLifecycleStatus.refunded,
      );
    });

    test('maps cancelled with actor hint', () {
      check(
        BookingStatus.cancelled.toLifecycleStatus(
          cancelledBy: ActorRole.student,
        ),
      ).equals(SessionLifecycleStatus.cancelledByStudent);
      check(
        BookingStatus.cancelled.toLifecycleStatus(
          cancelledBy: ActorRole.teacher,
        ),
      ).equals(SessionLifecycleStatus.cancelledByTeacher);
      check(
        BookingStatus.cancelled.toLifecycleStatus(cancelledBy: ActorRole.admin),
      ).equals(SessionLifecycleStatus.cancelledByAdmin);
    });
  });

  group('QuranSessionStatusLifecycleMapper', () {
    test('maps legacy session statuses to canonical lifecycle statuses', () {
      check(QuranSessionStatus.scheduled.toLifecycleStatus()).equals(
        SessionLifecycleStatus.scheduled,
      );
      check(QuranSessionStatus.inProgress.toLifecycleStatus()).equals(
        SessionLifecycleStatus.inProgress,
      );
      check(QuranSessionStatus.completed.toLifecycleStatus()).equals(
        SessionLifecycleStatus.completed,
      );
      check(QuranSessionStatus.cancelledByStudent.toLifecycleStatus()).equals(
        SessionLifecycleStatus.cancelledByStudent,
      );
      check(QuranSessionStatus.cancelledByTeacher.toLifecycleStatus()).equals(
        SessionLifecycleStatus.cancelledByTeacher,
      );
      check(QuranSessionStatus.noShow.toLifecycleStatus()).equals(
        SessionLifecycleStatus.bothNoShow,
      );
    });
  });

  group('effectiveLifecycleStatus fallback', () {
    test('prefers explicit lifecycle status on booking', () {
      final booking = QuranBooking(
        id: 'b1',
        teacherId: 't1',
        studentId: 's1',
        slotId: 'slot',
        requestedCallType: SessionCallType.voiceCall,
        pricingType: SessionPricingType.free,
        status: BookingStatus.pending,
        lifecycleStatus: SessionLifecycleStatus.cancelledByAdmin,
        createdAt: DateTime.utc(2026, 1, 1),
      );
      check(booking.effectiveLifecycleStatus).equals(
        SessionLifecycleStatus.cancelledByAdmin,
      );
    });

    test('falls back to legacy status mapping on session', () {
      final session = QuranSession(
        id: 's1',
        bookingId: 'b1',
        teacherId: 't1',
        studentId: 's2',
        startsAt: DateTime.utc(2026, 1, 1, 10),
        endsAt: DateTime.utc(2026, 1, 1, 11),
        callType: SessionCallType.externalMeeting,
        status: QuranSessionStatus.inProgress,
      );
      check(session.effectiveLifecycleStatus).equals(
        SessionLifecycleStatus.inProgress,
      );
    });
  });
}
