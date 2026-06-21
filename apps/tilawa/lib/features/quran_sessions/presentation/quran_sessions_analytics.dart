import 'package:quran_sessions/quran_sessions.dart';
import 'package:tilawa_core/constants/analytics_constants.dart';
import 'package:tilawa_core/services/analytics_service.dart';

import 'package:tilawa/core/di/injection.dart';

/// Host wiring for Quran Sessions analytics events.
QuranSessionsAnalyticsCallbacks quranSessionsAnalyticsCallbacks() {
  if (!getIt.isRegistered<AnalyticsService>()) {
    return const QuranSessionsAnalyticsCallbacks();
  }
  final AnalyticsService analytics = getIt<AnalyticsService>();
  return QuranSessionsAnalyticsCallbacks(
    onTeacherApplyEntrySeen: () =>
        analytics.logEvent(AnalyticsEvents.teacherApplyEntrySeen),
    onTeacherApplyStarted: () =>
        analytics.logEvent(AnalyticsEvents.teacherApplyStarted),
    onTeacherApplicationSubmitted: () =>
        analytics.logEvent(AnalyticsEvents.teacherApplicationSubmitted),
    onTeacherApplicationStatusViewed: () =>
        analytics.logEvent(AnalyticsEvents.teacherApplicationStatusViewed),
    onTeacherApplicationApproved: () =>
        analytics.logEvent(AnalyticsEvents.teacherApplicationApproved),
    onTeacherApplicationRejected: () =>
        analytics.logEvent(AnalyticsEvents.teacherApplicationRejected),
    onTeacherDashboardOpened: () =>
        analytics.logEvent(AnalyticsEvents.teacherDashboardOpened),
    onQuranSessionsEmptyStateSeen: () =>
        analytics.logEvent(AnalyticsEvents.quranSessionsEmptyStateSeen),
    onQuranSessionsNotifyInterestSubmitted: () => analytics.logEvent(
      AnalyticsEvents.quranSessionsNotifyInterestSubmitted,
    ),
  );
}
