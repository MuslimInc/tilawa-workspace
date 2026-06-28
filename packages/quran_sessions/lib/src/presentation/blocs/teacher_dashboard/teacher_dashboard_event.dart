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

/// Teacher removes an open slot — UI updates immediately; network commit
/// is deferred until the commit timer fires.
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

/// Restores a slot removed optimistically before its deferred commit fires.
final class AvailabilitySlotDeleteUndone extends TeacherDashboardEvent {
  const AvailabilitySlotDeleteUndone({required this.slotId});

  final String slotId;

  @override
  List<Object?> get props => [slotId];
}

/// Internal: deferred-commit timer fired for [slotId].
final class CommitPendingSlotDelete extends TeacherDashboardEvent {
  const CommitPendingSlotDelete({required this.slotId});

  final String slotId;

  @override
  List<Object?> get props => [slotId];
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

/// Teacher dismissed the Friday review in-app banner for the current cycle.
final class FridayReviewBannerDismissed extends TeacherDashboardEvent {
  const FridayReviewBannerDismissed({required this.teacherId});

  final String teacherId;

  @override
  List<Object?> get props => [teacherId];
}

/// Teacher cancels an upcoming session.
final class TeacherSessionCancelled extends TeacherDashboardEvent {
  const TeacherSessionCancelled({
    required this.bookingId,
    required this.reason,
  });

  final String bookingId;
  final String reason;

  @override
  List<Object?> get props => [bookingId, reason];
}

/// Teacher marks session complete after it ends.
final class TeacherSessionCompleted extends TeacherDashboardEvent {
  const TeacherSessionCompleted({required this.sessionId});

  final String sessionId;

  @override
  List<Object?> get props => [sessionId];
}

/// Teacher accepts a pending booking request.
final class TeacherBookingRequestAccepted extends TeacherDashboardEvent {
  const TeacherBookingRequestAccepted({required this.bookingId});

  final String bookingId;

  @override
  List<Object?> get props => [bookingId];
}

/// Teacher rejects a pending booking request.
final class TeacherBookingRequestRejected extends TeacherDashboardEvent {
  const TeacherBookingRequestRejected({
    required this.bookingId,
    this.reason,
  });

  final String bookingId;
  final String? reason;

  @override
  List<Object?> get props => [bookingId, reason];
}
