import '../../domain/entities/quran_session.dart';
import '../../domain/entities/session_lifecycle_status.dart';

/// Whether a student can submit a post-session review for [session].
bool isSessionEligibleForStudentReview(QuranSession session) {
  if (session.effectiveLifecycleStatus == SessionLifecycleStatus.completed) {
    return true;
  }
  return session.isPast && session.status == QuranSessionStatus.completed;
}
