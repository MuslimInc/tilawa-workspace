class QuranSessionDto {
  const QuranSessionDto({
    required this.id,
    required this.bookingId,
    required this.teacherId,
    required this.studentId,
    required this.startsAt,
    required this.endsAt,
    required this.callType,
    required this.status,
    this.meetingLink,
    this.callRoomId,
    this.notes,
  });

  final String id;
  final String bookingId;
  final String teacherId;
  final String studentId;
  final String startsAt;
  final String endsAt;
  final String callType;
  final String status;
  final String? meetingLink;
  final String? callRoomId;
  final String? notes;

  factory QuranSessionDto.fromJson(Map<String, dynamic> json) =>
      QuranSessionDto(
        id: json['id'] as String,
        bookingId: json['booking_id'] as String,
        teacherId: json['teacher_id'] as String,
        studentId: json['student_id'] as String,
        startsAt: json['starts_at'] as String,
        endsAt: json['ends_at'] as String,
        callType: json['call_type'] as String,
        status: json['status'] as String,
        meetingLink: json['meeting_link'] as String?,
        callRoomId: json['call_room_id'] as String?,
        notes: json['notes'] as String?,
      );

  Map<String, dynamic> toJson() => {
    'id': id,
    'booking_id': bookingId,
    'teacher_id': teacherId,
    'student_id': studentId,
    'starts_at': startsAt,
    'ends_at': endsAt,
    'call_type': callType,
    'status': status,
    'meeting_link': meetingLink,
    'call_room_id': callRoomId,
    'notes': notes,
  };
}
