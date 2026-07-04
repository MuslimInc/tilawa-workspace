import 'package:checks/checks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_sessions/quran_sessions.dart';

void main() {
  group('SessionJoinWindowPolicy', () {
    const policy = SessionJoinWindowPolicy();
    final startsAt = DateTime.utc(2026, 7, 1, 12);
    final endsAt = DateTime.utc(2026, 7, 1, 13);

    test('rejects join more than 15 minutes before start', () {
      final now = startsAt.subtract(const Duration(minutes: 16));
      check(
        policy.isWithinJoinWindow(startsAt: startsAt, endsAt: endsAt, now: now),
      ).isFalse();
    });

    test('allows join 15 minutes before start through endsAt', () {
      final atWindowOpen = startsAt.subtract(const Duration(minutes: 15));
      final atEnd = endsAt;
      check(
        policy.isWithinJoinWindow(
          startsAt: startsAt,
          endsAt: endsAt,
          now: atWindowOpen,
        ),
      ).isTrue();
      check(
        policy.isWithinJoinWindow(
          startsAt: startsAt,
          endsAt: endsAt,
          now: atEnd,
        ),
      ).isTrue();
    });

    test('rejects join after endsAt', () {
      final now = endsAt.add(const Duration(seconds: 1));
      check(
        policy.isWithinJoinWindow(startsAt: startsAt, endsAt: endsAt, now: now),
      ).isFalse();
    });

    test('QA staging uid bypasses window before lead time', () {
      const stagingPolicy = SessionJoinWindowPolicy(distribution: 'staging');
      final now = startsAt.subtract(const Duration(hours: 2));
      check(
        stagingPolicy.isWithinJoinWindow(
          startsAt: startsAt,
          endsAt: endsAt,
          now: now,
          qaBypassUserId: stagingQaStudentUid,
        ),
      ).isTrue();
    });

    test('non-QA uid still blocked before lead time on staging', () {
      const stagingPolicy = SessionJoinWindowPolicy(distribution: 'staging');
      final now = startsAt.subtract(const Duration(hours: 2));
      check(
        stagingPolicy.isWithinJoinWindow(
          startsAt: startsAt,
          endsAt: endsAt,
          now: now,
          qaBypassUserId: 'student_random',
        ),
      ).isFalse();
    });
  });

  group('SessionJoinPolicy QA bypass', () {
    const stagingPolicy = SessionJoinWindowPolicy(distribution: 'staging');
    const joinPolicy = SessionJoinPolicy(windowPolicy: stagingPolicy);

    test('allows QA student outside join window when lifecycle joinable', () {
      final startsAt = DateTime.utc(2099, 6, 1, 12);
      final session = QuranSession(
        id: 'session_qa',
        bookingId: 'booking_qa',
        teacherId: 'teacher_profile',
        studentId: stagingQaStudentUid,
        startsAt: startsAt,
        endsAt: startsAt.add(const Duration(hours: 1)),
        callType: SessionCallType.videoCall,
        status: QuranSessionStatus.scheduled,
        lifecycleStatus: SessionLifecycleStatus.confirmed,
      );

      check(
        joinPolicy.canJoin(
          session: session,
          userId: stagingQaStudentUid,
          now: startsAt.subtract(const Duration(hours: 3)),
        ),
      ).isTrue();
    });

    test('blocks completed session even for QA uid', () {
      final startsAt = DateTime.utc(2099, 6, 1, 12);
      final session = QuranSession(
        id: 'session_done',
        bookingId: 'booking_done',
        teacherId: 'teacher_profile',
        studentId: stagingQaStudentUid,
        startsAt: startsAt,
        endsAt: startsAt.add(const Duration(hours: 1)),
        callType: SessionCallType.videoCall,
        status: QuranSessionStatus.completed,
        lifecycleStatus: SessionLifecycleStatus.completed,
      );

      check(
        joinPolicy.canJoin(
          session: session,
          userId: stagingQaStudentUid,
          now: startsAt,
        ),
      ).isFalse();
    });
  });
}
