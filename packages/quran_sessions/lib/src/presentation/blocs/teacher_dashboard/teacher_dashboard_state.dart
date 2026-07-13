import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';

import '../../../domain/entities/market_scheduling_config.dart';
import '../../../domain/entities/quran_session.dart';
import '../../../domain/entities/teacher_availability.dart';
import '../../../domain/failures/quran_sessions_failure.dart';

sealed class TeacherDashboardState extends Equatable {
  const TeacherDashboardState();

  @override
  List<Object?> get props => [];
}

final class TeacherDashboardInitial extends TeacherDashboardState {
  const TeacherDashboardInitial();
}

final class TeacherDashboardLoading extends TeacherDashboardState {
  const TeacherDashboardLoading();
}

/// Deferred commit for a slot removed from the UI but not yet written.
final class PendingSlotDelete extends Equatable {
  const PendingSlotDelete({
    required this.snapshot,
    required this.isGenerated,
    required this.teacherId,
    required this.cancelTimer,
  });

  final TeacherAvailability snapshot;
  final bool isGenerated;
  final String teacherId;

  /// Cancels the deferred-commit timer (undo or bloc close).
  final VoidCallback cancelTimer;

  String get slotId => snapshot.slotId;

  @override
  List<Object?> get props => [snapshot, isGenerated, teacherId];
}

final class TeacherDashboardSuccess extends TeacherDashboardState {
  const TeacherDashboardSuccess({
    required this.pendingBookingRequests,
    required this.upcomingSessions,
    required this.availability,
    required this.schedulingConfig,
    required this.thisWeekAvailability,
    required this.nextWeekAvailability,
    required this.showFridayReviewBanner,
    required this.teacherTimezone,
    this.fridayReviewNextWeekKey,
    this.dismissedFridayReminderWeekKey,
    this.marketCountryCode,
    this.isUpdatingAvailability = false,
    this.isRefreshing = false,
    this.pendingDeletes = const {},
    this.undoableSlotId,
    this.slotFailure,
    this.refreshDiscardedPendingCount,
    this.bookingRequestActionInProgress,
    this.bookingRequestFailure,
    this.sessionCancelInProgress,
    this.sessionCancelFailure,
    this.sessionCancelSucceeded = false,
    this.joinInProgress,
    this.joinFailure,
    this.joinCompletedSessionId,
  });

  final List<QuranSession> pendingBookingRequests;
  final List<QuranSession> upcomingSessions;
  final List<TeacherAvailability> availability;

  /// Resolved admin scheduling policy for this teacher's market.
  final MarketSchedulingConfig schedulingConfig;

  /// Bookable slots in the current Sat→Fri week (when week-scoped UX on).
  final List<TeacherAvailability> thisWeekAvailability;

  /// Bookable slots in the following week.
  final List<TeacherAvailability> nextWeekAvailability;

  /// In-app Friday review nudge when next week has zero projected slots.
  final bool showFridayReviewBanner;
  final String? fridayReviewNextWeekKey;
  final String? dismissedFridayReminderWeekKey;
  final String teacherTimezone;
  final String? marketCountryCode;

  /// True while a slot add/edit is in flight — disables the availability editor.
  final bool isUpdatingAvailability;

  /// Pull-to-refresh in flight — keeps list visible (no full-screen loader).
  final bool isRefreshing;

  /// Slots removed from UI awaiting deferred network commit.
  final Map<String, PendingSlotDelete> pendingDeletes;

  /// Latest removed slot eligible for SnackBar undo.
  final String? undoableSlotId;

  /// Set when a publishSlot or withdrawSlot call fails; cleared on next success.
  /// UI should show a transient error (snackbar) and leave the list intact.
  final QuranSessionsFailure? slotFailure;

  /// One-shot: pending optimistic deletes discarded on refresh (for UI toast).
  final int? refreshDiscardedPendingCount;

  /// Booking id while accept/reject callable is in flight.
  final String? bookingRequestActionInProgress;

  /// Last accept/reject failure for snackbar.
  final QuranSessionsFailure? bookingRequestFailure;

  /// Booking id while tutor cancel is in flight.
  final String? sessionCancelInProgress;

  /// Last tutor cancel failure for snackbar.
  final QuranSessionsFailure? sessionCancelFailure;

  /// One-shot success signal after tutor cancel completes.
  final bool sessionCancelSucceeded;

  /// Session id currently launching the call.
  final String? joinInProgress;

  /// Set when join fails so UI can show feedback.
  final QuranSessionsFailure? joinFailure;

  /// Set after a successful join so UI can navigate to the call shell.
  final String? joinCompletedSessionId;

  bool get weekScopedDashboard => schedulingConfig.weekScopedDashboardEnabled;

  @override
  List<Object?> get props => [
    pendingBookingRequests,
    upcomingSessions,
    availability,
    schedulingConfig,
    thisWeekAvailability,
    nextWeekAvailability,
    showFridayReviewBanner,
    fridayReviewNextWeekKey,
    dismissedFridayReminderWeekKey,
    teacherTimezone,
    marketCountryCode,
    isUpdatingAvailability,
    isRefreshing,
    pendingDeletes,
    undoableSlotId,
    slotFailure,
    refreshDiscardedPendingCount,
    bookingRequestActionInProgress,
    bookingRequestFailure,
    sessionCancelInProgress,
    sessionCancelFailure,
    sessionCancelSucceeded,
    joinInProgress,
    joinFailure,
    joinCompletedSessionId,
  ];

  TeacherDashboardSuccess copyWith({
    List<QuranSession>? pendingBookingRequests,
    List<QuranSession>? upcomingSessions,
    List<TeacherAvailability>? availability,
    MarketSchedulingConfig? schedulingConfig,
    List<TeacherAvailability>? thisWeekAvailability,
    List<TeacherAvailability>? nextWeekAvailability,
    bool? showFridayReviewBanner,
    String? fridayReviewNextWeekKey,
    String? dismissedFridayReminderWeekKey,
    String? teacherTimezone,
    String? marketCountryCode,
    bool? isUpdatingAvailability,
    bool? isRefreshing,
    Map<String, PendingSlotDelete>? pendingDeletes,
    String? undoableSlotId,
    QuranSessionsFailure? slotFailure,
    int? refreshDiscardedPendingCount,
    String? bookingRequestActionInProgress,
    QuranSessionsFailure? bookingRequestFailure,
    String? sessionCancelInProgress,
    QuranSessionsFailure? sessionCancelFailure,
    bool? sessionCancelSucceeded,
    String? joinInProgress,
    QuranSessionsFailure? joinFailure,
    String? joinCompletedSessionId,
    bool clearSlotFailure = false,
    bool clearUndoableSlotId = false,
    bool clearRefreshDiscardedPendingCount = false,
    bool clearFridayReviewNextWeekKey = false,
    bool clearDismissedFridayReminderWeekKey = false,
    bool clearBookingRequestActionInProgress = false,
    bool clearBookingRequestFailure = false,
    bool clearSessionCancelInProgress = false,
    bool clearSessionCancelFailure = false,
    bool clearSessionCancelSucceeded = false,
    bool clearJoinInProgress = false,
    bool clearJoinFailure = false,
    bool clearJoinCompletedSessionId = false,
  }) => TeacherDashboardSuccess(
    pendingBookingRequests:
        pendingBookingRequests ?? this.pendingBookingRequests,
    upcomingSessions: upcomingSessions ?? this.upcomingSessions,
    availability: availability ?? this.availability,
    schedulingConfig: schedulingConfig ?? this.schedulingConfig,
    thisWeekAvailability: thisWeekAvailability ?? this.thisWeekAvailability,
    nextWeekAvailability: nextWeekAvailability ?? this.nextWeekAvailability,
    showFridayReviewBanner:
        showFridayReviewBanner ?? this.showFridayReviewBanner,
    fridayReviewNextWeekKey: clearFridayReviewNextWeekKey
        ? null
        : (fridayReviewNextWeekKey ?? this.fridayReviewNextWeekKey),
    dismissedFridayReminderWeekKey: clearDismissedFridayReminderWeekKey
        ? null
        : (dismissedFridayReminderWeekKey ??
              this.dismissedFridayReminderWeekKey),
    teacherTimezone: teacherTimezone ?? this.teacherTimezone,
    marketCountryCode: marketCountryCode ?? this.marketCountryCode,
    isUpdatingAvailability:
        isUpdatingAvailability ?? this.isUpdatingAvailability,
    isRefreshing: isRefreshing ?? this.isRefreshing,
    pendingDeletes: pendingDeletes ?? this.pendingDeletes,
    undoableSlotId: clearUndoableSlotId
        ? null
        : (undoableSlotId ?? this.undoableSlotId),
    slotFailure: clearSlotFailure ? null : (slotFailure ?? this.slotFailure),
    refreshDiscardedPendingCount: clearRefreshDiscardedPendingCount
        ? null
        : (refreshDiscardedPendingCount ?? this.refreshDiscardedPendingCount),
    bookingRequestActionInProgress: clearBookingRequestActionInProgress
        ? null
        : (bookingRequestActionInProgress ??
              this.bookingRequestActionInProgress),
    bookingRequestFailure: clearBookingRequestFailure
        ? null
        : (bookingRequestFailure ?? this.bookingRequestFailure),
    sessionCancelInProgress: clearSessionCancelInProgress
        ? null
        : (sessionCancelInProgress ?? this.sessionCancelInProgress),
    sessionCancelFailure: clearSessionCancelFailure
        ? null
        : (sessionCancelFailure ?? this.sessionCancelFailure),
    sessionCancelSucceeded:
        !clearSessionCancelSucceeded &&
        (sessionCancelSucceeded ?? this.sessionCancelSucceeded),
    joinInProgress: clearJoinInProgress
        ? null
        : (joinInProgress ?? this.joinInProgress),
    joinFailure: clearJoinFailure ? null : (joinFailure ?? this.joinFailure),
    joinCompletedSessionId: clearJoinCompletedSessionId
        ? null
        : (joinCompletedSessionId ?? this.joinCompletedSessionId),
  );
}

final class TeacherDashboardEmpty extends TeacherDashboardState {
  const TeacherDashboardEmpty();
}

final class TeacherDashboardFailure extends TeacherDashboardState {
  const TeacherDashboardFailure(this.failure);

  final QuranSessionsFailure failure;

  @override
  List<Object?> get props => [failure];
}
