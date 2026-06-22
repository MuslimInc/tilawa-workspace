import '../value_objects/actor_role.dart';
import 'quran_booking.dart';
import 'quran_session.dart';
import 'session_lifecycle_status.dart';

/// Compatibility mapper for legacy booking/session status enums.
///
/// During migration, callers should prefer explicit `lifecycleStatus` from
/// storage. These mappings are only fallback behavior for legacy rows.
extension BookingStatusLifecycleMapper on BookingStatus {
  SessionLifecycleStatus toLifecycleStatus({
    ActorRole cancelledBy = ActorRole.student,
  }) {
    return switch (this) {
      BookingStatus.pending => SessionLifecycleStatus.pendingPayment,
      BookingStatus.confirmed => SessionLifecycleStatus.scheduled,
      BookingStatus.rejected => SessionLifecycleStatus.expired,
      BookingStatus.cancelled => switch (cancelledBy) {
        ActorRole.teacher => SessionLifecycleStatus.cancelledByTeacher,
        ActorRole.admin => SessionLifecycleStatus.cancelledByAdmin,
        _ => SessionLifecycleStatus.cancelledByStudent,
      },
      BookingStatus.completed => SessionLifecycleStatus.completed,
      BookingStatus.refunded => SessionLifecycleStatus.refunded,
    };
  }
}

/// Compatibility mapper for legacy session status enum.
extension QuranSessionStatusLifecycleMapper on QuranSessionStatus {
  SessionLifecycleStatus toLifecycleStatus() {
    return switch (this) {
      QuranSessionStatus.scheduled => SessionLifecycleStatus.scheduled,
      QuranSessionStatus.inProgress => SessionLifecycleStatus.inProgress,
      QuranSessionStatus.completed => SessionLifecycleStatus.completed,
      QuranSessionStatus.cancelledByStudent =>
        SessionLifecycleStatus.cancelledByStudent,
      QuranSessionStatus.cancelledByTeacher =>
        SessionLifecycleStatus.cancelledByTeacher,
      QuranSessionStatus.noShow => SessionLifecycleStatus.bothNoShow,
    };
  }
}
