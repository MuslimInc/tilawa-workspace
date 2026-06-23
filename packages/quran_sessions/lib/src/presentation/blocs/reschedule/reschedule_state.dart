import 'package:equatable/equatable.dart';

import '../../../domain/entities/teacher_availability.dart';
import '../../../domain/failures/quran_sessions_failure.dart';

sealed class RescheduleState extends Equatable {
  const RescheduleState();

  @override
  List<Object?> get props => [];
}

final class RescheduleInitial extends RescheduleState {
  const RescheduleInitial();
}

final class RescheduleLoading extends RescheduleState {
  const RescheduleLoading();
}

final class RescheduleSelecting extends RescheduleState {
  const RescheduleSelecting({
    required this.bookingId,
    required this.teacherId,
    required this.availableSlots,
    this.selectedSlot,
    this.reason = '',
  });

  final String bookingId;
  final String teacherId;
  final List<TeacherAvailability> availableSlots;
  final TeacherAvailability? selectedSlot;
  final String reason;

  bool get canSubmit => selectedSlot != null && reason.trim().length >= 3;

  @override
  List<Object?> get props => [
    bookingId,
    teacherId,
    availableSlots,
    selectedSlot,
    reason,
  ];

  RescheduleSelecting copyWith({
    List<TeacherAvailability>? availableSlots,
    TeacherAvailability? selectedSlot,
    String? reason,
  }) => RescheduleSelecting(
    bookingId: bookingId,
    teacherId: teacherId,
    availableSlots: availableSlots ?? this.availableSlots,
    selectedSlot: selectedSlot ?? this.selectedSlot,
    reason: reason ?? this.reason,
  );
}

final class RescheduleSubmitting extends RescheduleState {
  const RescheduleSubmitting();
}

final class RescheduleSuccess extends RescheduleState {
  const RescheduleSuccess({required this.requestId});

  final String requestId;

  @override
  List<Object?> get props => [requestId];
}

final class RescheduleFailure extends RescheduleState {
  const RescheduleFailure(this.failure);

  final QuranSessionsFailure failure;

  @override
  List<Object?> get props => [failure];
}
