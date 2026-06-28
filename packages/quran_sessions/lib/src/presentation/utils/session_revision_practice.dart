import '../../domain/entities/session_lifecycle_status.dart';

/// Whether session detail may offer Tilawa Quran reader practice for revision.
bool sessionShowsRevisionPractice(SessionLifecycleStatus status) {
  return switch (status) {
    SessionLifecycleStatus.scheduled ||
    SessionLifecycleStatus.confirmed ||
    SessionLifecycleStatus.inProgress ||
    SessionLifecycleStatus.rescheduled ||
    SessionLifecycleStatus.completed => true,
    _ => false,
  };
}
