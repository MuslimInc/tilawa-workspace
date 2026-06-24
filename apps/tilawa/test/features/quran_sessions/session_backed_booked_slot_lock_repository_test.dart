import 'package:checks/checks.dart';
import 'package:dartz_plus/dartz_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_sessions/quran_sessions.dart';
import 'package:tilawa/features/quran_sessions/data/session_backed_booked_slot_lock_repository.dart';

class _FakeSessionRepository implements SessionRepository {
  _FakeSessionRepository({Map<String, List<QuranSession>>? upcomingByTeacher})
    : upcomingByTeacher = upcomingByTeacher ?? {};

  final Map<String, List<QuranSession>> upcomingByTeacher;

  @override
  Future<Either<QuranSessionsFailure, QuranSession>> getSessionById(
    String sessionId,
  ) async => throw UnimplementedError();

  @override
  Future<Either<QuranSessionsFailure, SessionPage>> getStudentPastSessions(
    String studentId, {
    String? cursor,
    int limit = kDefaultSessionPageSize,
  }) async => throw UnimplementedError();

  @override
  Future<Either<QuranSessionsFailure, SessionPage>> getStudentUpcomingSessions(
    String studentId, {
    String? cursor,
    int limit = kDefaultSessionPageSize,
  }) async => throw UnimplementedError();

  @override
  Future<Either<QuranSessionsFailure, List<QuranSession>>>
  getTeacherUpcomingSessions(
    String teacherId, {
    int limit = kDefaultSessionPageSize,
  }) async => Right(upcomingByTeacher[teacherId] ?? const []);

  @override
  Future<Either<QuranSessionsFailure, QuranSession>> updateNotes(
    String sessionId, {
    required String notes,
  }) async => throw UnimplementedError();
}

QuranSession _scheduledSession({
  required String teacherId,
  required DateTime startsAt,
}) {
  return QuranSession(
    id: 'session_${startsAt.millisecondsSinceEpoch}',
    bookingId: 'booking_${startsAt.millisecondsSinceEpoch}',
    teacherId: teacherId,
    studentId: 'student_1',
    startsAt: startsAt,
    endsAt: startsAt.add(const Duration(minutes: 30)),
    callType: SessionCallType.externalMeeting,
    status: QuranSessionStatus.scheduled,
  );
}

void main() {
  late _FakeSessionRepository sessions;
  late SessionBackedBookedSlotLockRepository repository;

  setUp(() {
    sessions = _FakeSessionRepository();
    repository = SessionBackedBookedSlotLockRepository(sessions);
  });

  group('isSlotBooked', () {
    test('returns false for malformed slot id', () async {
      final result = await repository.isSlotBooked('not-a-slot-id');
      check(result).equals(const Right(false));
    });

    test(
      'returns true when teacher has scheduled session at slot start',
      () async {
        const teacherId = 'teacher_with_underscore';
        final start = DateTime.utc(2026, 6, 24, 10);
        final slotId = GeneratedSlot.deterministicId(teacherId, start);
        sessions.upcomingByTeacher[teacherId] = [
          _scheduledSession(teacherId: teacherId, startsAt: start),
        ];

        final result = await repository.isSlotBooked(slotId);

        check(result).equals(const Right(true));
      },
    );

    test('returns false when teacher has no session at slot start', () async {
      const teacherId = 'teacher_1';
      final start = DateTime.utc(2026, 6, 24, 10);
      final slotId = GeneratedSlot.deterministicId(teacherId, start);
      sessions.upcomingByTeacher[teacherId] = [
        _scheduledSession(
          teacherId: teacherId,
          startsAt: start.add(const Duration(hours: 1)),
        ),
      ];

      final result = await repository.isSlotBooked(slotId);

      check(result).equals(const Right(false));
    });
  });
}
