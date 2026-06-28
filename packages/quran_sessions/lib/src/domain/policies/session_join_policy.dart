import '../entities/quran_session.dart';
import '../entities/session_lifecycle_status.dart';
import 'session_join_window_policy.dart';

class SessionJoinPolicy {
  const SessionJoinPolicy({
    this.windowPolicy = const SessionJoinWindowPolicy(),
  });

  final SessionJoinWindowPolicy windowPolicy;

  bool canJoin({
    required QuranSession session,
    required String userId,
    required DateTime now,
  }) {
    final isStudent = session.studentId == userId;
    final isTeacher = session.teacherId == userId;
    if (!isStudent && !isTeacher) return false;

    if (!session.effectiveLifecycleStatus.canJoinSession) return false;

    return windowPolicy.isWithinJoinWindow(
      startsAt: session.startsAt,
      now: now,
    );
  }
}
