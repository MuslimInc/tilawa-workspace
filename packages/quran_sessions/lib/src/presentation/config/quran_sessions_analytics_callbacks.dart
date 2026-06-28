import 'package:flutter/foundation.dart';

/// Optional analytics hooks wired by the host app (Firebase Analytics, etc.).
///
/// Presentation invokes these; the package never imports analytics SDKs.
@immutable
class QuranSessionsAnalyticsCallbacks {
  const QuranSessionsAnalyticsCallbacks({
    this.onTeacherApplyEntrySeen,
    this.onTeacherApplyStarted,
    this.onTeacherApplicationSubmitted,
    this.onTeacherApplicationStatusViewed,
    this.onTeacherApplicationApproved,
    this.onTeacherApplicationRejected,
    this.onTeacherDashboardOpened,
    this.onQuranSessionsEmptyStateSeen,
    this.onQuranSessionsNotifyInterestSubmitted,
    this.onTeacherListViewed,
    this.onTeacherProfileViewed,
    this.onBookingStarted,
    this.onBookingCompleted,
    this.onMySessionsOpened,
    this.onSessionJoined,
    this.onReviewSubmitted,
  });

  final VoidCallback? onTeacherApplyEntrySeen;
  final VoidCallback? onTeacherApplyStarted;
  final VoidCallback? onTeacherApplicationSubmitted;
  final VoidCallback? onTeacherApplicationStatusViewed;
  final VoidCallback? onTeacherApplicationApproved;
  final VoidCallback? onTeacherApplicationRejected;
  final VoidCallback? onTeacherDashboardOpened;
  final VoidCallback? onQuranSessionsEmptyStateSeen;
  final VoidCallback? onQuranSessionsNotifyInterestSubmitted;

  // ── Student funnel (screen views + success actions) ──────────────────────
  // Hosts log safe IDs/enums only; the package never passes names or notes.

  final VoidCallback? onTeacherListViewed;
  final void Function(String teacherId)? onTeacherProfileViewed;
  final void Function(String teacherId)? onBookingStarted;
  final void Function({
    required String teacherId,
    required String bookingId,
    required bool isPaid,
    String? pricingType,
    String? callType,
  })?
  onBookingCompleted;
  final VoidCallback? onMySessionsOpened;
  final void Function({String? bookingId, String? sessionId})? onSessionJoined;
  final void Function({String? bookingId, String? sessionId, int? rating})?
  onReviewSubmitted;
}
