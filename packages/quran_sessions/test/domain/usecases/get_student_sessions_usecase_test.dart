import 'package:checks/checks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_sessions/quran_sessions.dart';

import '../../helpers/fakes/fake_session_repository.dart';
import '../../helpers/fixtures.dart';

void main() {
  group('GetStudentSessionsUseCase', () {
    late FakeSessionRepository sessions;
    late GetStudentSessionsUseCase useCase;

    setUp(() {
      sessions = FakeSessionRepository();
      useCase = GetStudentSessionsUseCase(sessions);
    });

    test('reclassifies terminal active sessions into past', () async {
      final futureEnd = DateTime.now().add(const Duration(hours: 2));
      sessions.sessions = [
        makeSession(
          id: 'active',
          lifecycleStatus: SessionLifecycleStatus.scheduled,
          startsAt: DateTime.now().add(const Duration(hours: 1)),
          endsAt: futureEnd,
        ),
        makeSession(
          id: 'completed_early',
          lifecycleStatus: SessionLifecycleStatus.completed,
          startsAt: DateTime.now().subtract(const Duration(hours: 1)),
          endsAt: futureEnd,
        ),
      ];

      final result = await useCase('student_1');

      final page = result.fold((_) => null, (v) => v)!;
      check(page.upcoming.length).equals(1);
      check(page.upcoming.single.id).equals('active');
      check(page.past.length).equals(1);
      check(page.past.single.id).equals('completed_early');
    });

    test('routes pending tutor approval into pending bucket', () async {
      sessions.sessions = [
        makeSession(
          id: 'pending',
          lifecycleStatus: SessionLifecycleStatus.pendingTutorApproval,
          startsAt: DateTime.now().add(const Duration(hours: 1)),
          endsAt: DateTime.now().add(const Duration(hours: 2)),
        ),
      ];

      final page = (await useCase('student_1')).fold((_) => null, (v) => v)!;
      check(page.pending.length).equals(1);
      check(page.pending.single.id).equals('pending');
      check(page.upcoming).isEmpty();
    });

    test('routes cancelled sessions into cancelled bucket', () async {
      sessions.sessions = [
        makeSession(
          id: 'cancelled',
          lifecycleStatus: SessionLifecycleStatus.cancelledByTeacher,
          startsAt: DateTime.now().add(const Duration(hours: 1)),
          endsAt: DateTime.now().add(const Duration(hours: 2)),
        ),
      ];

      final page = (await useCase('student_1')).fold((_) => null, (v) => v)!;
      check(page.cancelled.length).equals(1);
      check(page.cancelled.single.id).equals('cancelled');
      check(page.upcoming).isEmpty();
    });
  });
}
