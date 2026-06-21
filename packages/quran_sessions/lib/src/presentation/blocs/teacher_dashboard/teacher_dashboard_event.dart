import 'package:equatable/equatable.dart';

import '../../../domain/entities/teacher_availability.dart';

sealed class TeacherDashboardEvent extends Equatable {
  const TeacherDashboardEvent();

  @override
  List<Object?> get props => [];
}

/// Screen mounted or pull-to-refresh.
final class TeacherDashboardLoadRequested extends TeacherDashboardEvent {
  const TeacherDashboardLoadRequested({required this.teacherId});

  final String teacherId;

  @override
  List<Object?> get props => [teacherId];
}

/// Teacher publishes a new open slot from the availability editor.
final class AvailabilitySlotAdded extends TeacherDashboardEvent {
  const AvailabilitySlotAdded({required this.slot});

  final TeacherAvailability slot;

  @override
  List<Object?> get props => [slot];
}

/// Teacher removes an open slot that has no confirmed booking.
final class AvailabilitySlotRemoved extends TeacherDashboardEvent {
  const AvailabilitySlotRemoved({
    required this.teacherId,
    required this.slot,
  });

  final String teacherId;
  final TeacherAvailability slot;

  @override
  List<Object?> get props => [teacherId, slot];
}

/// Teacher replaces an existing open slot with new time data.
final class AvailabilitySlotEdited extends TeacherDashboardEvent {
  const AvailabilitySlotEdited({required this.original, required this.updated});

  final TeacherAvailability original;
  final TeacherAvailability updated;

  @override
  List<Object?> get props => [original, updated];
}

/// Teacher updates availability window shown in the editor.
final class AvailabilityUpdated extends TeacherDashboardEvent {
  const AvailabilityUpdated({
    required this.teacherId,
    required this.from,
    required this.to,
  });

  final String teacherId;
  final DateTime from;
  final DateTime to;

  @override
  List<Object?> get props => [teacherId, from, to];
}
