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
}
