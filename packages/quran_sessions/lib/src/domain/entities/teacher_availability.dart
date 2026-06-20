import 'package:equatable/equatable.dart';

/// A single available time slot for a teacher.
class TeacherAvailability extends Equatable {
  const TeacherAvailability({
    required this.slotId,
    required this.teacherId,
    required this.startsAt,
    required this.endsAt,
    required this.isBooked,
  });

  final String slotId;
  final String teacherId;
  final DateTime startsAt;
  final DateTime endsAt;
  final bool isBooked;

  Duration get duration => endsAt.difference(startsAt);

  @override
  List<Object?> get props => [slotId, teacherId, startsAt, endsAt, isBooked];
}
