class TeacherAvailabilityDto {
  const TeacherAvailabilityDto({
    required this.slotId,
    required this.teacherId,
    required this.startsAt,
    required this.endsAt,
    required this.isBooked,
  });

  final String slotId;
  final String teacherId;
  final String startsAt;
  final String endsAt;
  final bool isBooked;

  factory TeacherAvailabilityDto.fromJson(Map<String, dynamic> json) =>
      TeacherAvailabilityDto(
        slotId: json['slot_id'] as String,
        teacherId: json['teacher_id'] as String,
        startsAt: json['starts_at'] as String,
        endsAt: json['ends_at'] as String,
        isBooked: json['is_booked'] as bool,
      );

  Map<String, dynamic> toJson() => {
    'slot_id': slotId,
    'teacher_id': teacherId,
    'starts_at': startsAt,
    'ends_at': endsAt,
    'is_booked': isBooked,
  };
}
