import 'package:equatable/equatable.dart';

import '../../../domain/entities/teacher_availability.dart';

sealed class RescheduleEvent extends Equatable {
  const RescheduleEvent();

  @override
  List<Object?> get props => [];
}

final class RescheduleLoadRequested extends RescheduleEvent {
  const RescheduleLoadRequested({
    required this.bookingId,
    required this.teacherId,
    required this.from,
    required this.to,
  });

  final String bookingId;
  final String teacherId;
  final DateTime from;
  final DateTime to;

  @override
  List<Object?> get props => [bookingId, teacherId, from, to];
}

final class RescheduleSlotSelected extends RescheduleEvent {
  const RescheduleSlotSelected(this.slot);

  final TeacherAvailability slot;

  @override
  List<Object?> get props => [slot];
}

final class RescheduleReasonChanged extends RescheduleEvent {
  const RescheduleReasonChanged(this.reason);

  final String reason;

  @override
  List<Object?> get props => [reason];
}

final class RescheduleSubmitted extends RescheduleEvent {
  const RescheduleSubmitted({
    required this.bookingId,
    required this.actorId,
  });

  final String bookingId;
  final String actorId;

  @override
  List<Object?> get props => [bookingId, actorId];
}
