import 'package:checks/checks.dart';
import 'package:quran_sessions/quran_sessions.dart';
import 'package:test/test.dart';

import '../../helpers/fixtures.dart';
import '../../helpers/fixtures/session_aggregate_fixtures.dart';

void main() {
  test('student can cancel confirmed session outside notice block', () {
    final aggregate = makeAggregate(
      status: SessionLifecycleStatus.confirmed,
      startsAt: DateTime.now().toUtc().add(const Duration(days: 2)),
    );
    check(canStudentCancelSession(aggregate)).isTrue();
  });

  test('student can cancel pending tutor approval anytime', () {
    final aggregate = makeAggregate(
      status: SessionLifecycleStatus.pendingTutorApproval,
      startsAt: DateTime.now().toUtc().add(const Duration(minutes: 30)),
    );
    check(canStudentCancelSession(aggregate)).isTrue();
  });

  test('student cannot cancel inside min notice window', () {
    final aggregate = makeAggregate(
      status: SessionLifecycleStatus.confirmed,
      startsAt: DateTime.now().toUtc().add(const Duration(minutes: 30)),
    );
    check(canStudentCancelSession(aggregate)).isFalse();
  });

  test('student list card respects min notice window', () {
    final session = makeSession(
      lifecycleStatus: SessionLifecycleStatus.confirmed,
      startsAt: DateTime.now().toUtc().add(const Duration(minutes: 30)),
    );
    check(canStudentCancelQuranSession(session)).isFalse();
  });

  test('teacher can cancel scheduled accepted session', () {
    final aggregate = makeAggregate(status: SessionLifecycleStatus.scheduled);
    check(canTeacherCancelSession(aggregate)).isTrue();
  });

  test('teacher can cancel confirmed accepted session', () {
    final aggregate = makeAggregate(status: SessionLifecycleStatus.confirmed);
    check(canTeacherCancelSession(aggregate)).isTrue();
  });

  test('teacher cannot cancel pending tutor approval', () {
    final aggregate = makeAggregate(
      status: SessionLifecycleStatus.pendingTutorApproval,
    );
    check(canTeacherCancelSession(aggregate)).isFalse();
  });

  test('teacher cannot cancel rejected or completed sessions', () {
    check(
      canTeacherCancelSession(
        makeAggregate(status: SessionLifecycleStatus.rejectedByTutor),
      ),
    ).isFalse();
    check(
      canTeacherCancelSession(
        makeAggregate(status: SessionLifecycleStatus.completed),
      ),
    ).isFalse();
    check(
      canTeacherCancelSession(
        makeAggregate(status: SessionLifecycleStatus.cancelledByTeacher),
      ),
    ).isFalse();
  });

  test('dashboard card cancel visibility mirrors aggregate policy', () {
    check(
      canTeacherCancelQuranSession(
        makeSession(lifecycleStatus: SessionLifecycleStatus.scheduled),
      ),
    ).isTrue();
    check(
      canTeacherCancelQuranSession(
        makeSession(
          lifecycleStatus: SessionLifecycleStatus.pendingTutorApproval,
        ),
      ),
    ).isFalse();
    check(
      canTeacherCancelQuranSession(
        makeSession(lifecycleStatus: SessionLifecycleStatus.rejectedByTutor),
      ),
    ).isFalse();
  });

  test('viewer cancel respects role', () {
    final confirmed = makeAggregate(
      status: SessionLifecycleStatus.confirmed,
      startsAt: DateTime.now().toUtc().add(const Duration(days: 2)),
    );
    check(
      canViewerCancelSession(confirmed, ActorRole.teacher),
    ).isTrue();
    check(
      canViewerCancelSession(confirmed, ActorRole.student),
    ).isTrue();
    check(canViewerCancelSession(confirmed, null)).isFalse();
  });
}
