import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';

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
    required this.upcomingSessions,
    required this.availability,
    this.isUpdatingAvailability = false,
    this.pendingDeletes = const {},
    this.undoableSlotId,
    this.slotFailure,
  });

  final List<QuranSession> upcomingSessions;
  final List<TeacherAvailability> availability;

  /// True while a slot add/edit is in flight — disables the availability editor.
  final bool isUpdatingAvailability;

  /// Slots removed from UI awaiting deferred network commit.
  final Map<String, PendingSlotDelete> pendingDeletes;

  /// Latest removed slot eligible for SnackBar undo.
  final String? undoableSlotId;

  /// Set when a publishSlot or withdrawSlot call fails; cleared on next success.
  /// UI should show a transient error (snackbar) and leave the list intact.
  final QuranSessionsFailure? slotFailure;

  @override
  List<Object?> get props => [
    upcomingSessions,
    availability,
    isUpdatingAvailability,
    pendingDeletes,
    undoableSlotId,
    slotFailure,
  ];

  TeacherDashboardSuccess copyWith({
    List<QuranSession>? upcomingSessions,
    List<TeacherAvailability>? availability,
    bool? isUpdatingAvailability,
    Map<String, PendingSlotDelete>? pendingDeletes,
    String? undoableSlotId,
    QuranSessionsFailure? slotFailure,
    bool clearSlotFailure = false,
    bool clearUndoableSlotId = false,
  }) => TeacherDashboardSuccess(
    upcomingSessions: upcomingSessions ?? this.upcomingSessions,
    availability: availability ?? this.availability,
    isUpdatingAvailability:
        isUpdatingAvailability ?? this.isUpdatingAvailability,
    pendingDeletes: pendingDeletes ?? this.pendingDeletes,
    undoableSlotId: clearUndoableSlotId
        ? null
        : (undoableSlotId ?? this.undoableSlotId),
    slotFailure: clearSlotFailure ? null : (slotFailure ?? this.slotFailure),
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
