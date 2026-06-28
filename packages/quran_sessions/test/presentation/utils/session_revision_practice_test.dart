import 'package:checks/checks.dart';
import 'package:quran_sessions/src/domain/entities/session_lifecycle_status.dart';
import 'package:quran_sessions/src/presentation/utils/session_revision_practice.dart';
import 'package:test/test.dart';

void main() {
  group('sessionShowsRevisionPractice', () {
    test('returns true for active and completed statuses', () {
      for (final status in [
        SessionLifecycleStatus.scheduled,
        SessionLifecycleStatus.confirmed,
        SessionLifecycleStatus.inProgress,
        SessionLifecycleStatus.rescheduled,
        SessionLifecycleStatus.completed,
      ]) {
        check(sessionShowsRevisionPractice(status)).isTrue();
      }
    });

    test('returns false for terminal non-completed statuses', () {
      for (final status in [
        SessionLifecycleStatus.cancelledByStudent,
        SessionLifecycleStatus.rejectedByTutor,
        SessionLifecycleStatus.pendingTutorApproval,
      ]) {
        check(sessionShowsRevisionPractice(status)).isFalse();
      }
    });
  });
}
