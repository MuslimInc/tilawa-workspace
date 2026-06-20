import 'package:equatable/equatable.dart';

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

final class TeacherDashboardSuccess extends TeacherDashboardState {
  const TeacherDashboardSuccess({
    required this.upcomingSessions,
    required this.availability,
    this.isUpdatingAvailability = false,
    this.slotFailure,
  });

  final List<QuranSession> upcomingSessions;
  final List<TeacherAvailability> availability;

  /// True while a slot add/remove is in flight — disables the availability editor.
  final bool isUpdatingAvailability;

  /// Set when a publishSlot or withdrawSlot call fails; cleared on next success.
  /// UI should show a transient error (snackbar) and leave the list intact.
  final QuranSessionsFailure? slotFailure;

  @override
  List<Object?> get props => [
    upcomingSessions,
    availability,
    isUpdatingAvailability,
    slotFailure,
  ];

  TeacherDashboardSuccess copyWith({
    List<QuranSession>? upcomingSessions,
    List<TeacherAvailability>? availability,
    bool? isUpdatingAvailability,
    QuranSessionsFailure? slotFailure,
    bool clearSlotFailure = false,
  }) => TeacherDashboardSuccess(
    upcomingSessions: upcomingSessions ?? this.upcomingSessions,
    availability: availability ?? this.availability,
    isUpdatingAvailability:
        isUpdatingAvailability ?? this.isUpdatingAvailability,
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
