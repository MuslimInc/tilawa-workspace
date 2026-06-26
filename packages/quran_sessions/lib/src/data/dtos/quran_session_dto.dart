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
    this.lifecycleStatus,
    this.meetingLink,
    this.callRoomId,
    this.bookingType,
    this.callProvider,
    this.providerSessionId,
    this.joinToken,
    this.participants,
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
  final String? lifecycleStatus;
  final String? meetingLink;
  final String? callRoomId;
  final String? bookingType;
  final String? callProvider;
  final String? providerSessionId;
  final String? joinToken;
  final Object? participants;
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
        lifecycleStatus: json['lifecycle_status'] as String?,
        meetingLink: json['meeting_link'] as String?,
        callRoomId: json['call_room_id'] as String?,
        bookingType: json['booking_type'] as String?,
        callProvider: json['call_provider'] as String?,
        providerSessionId: json['provider_session_id'] as String?,
        joinToken: json['join_token'] as String?,
        participants: json['participants'],
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
    'lifecycle_status': lifecycleStatus,
    'meeting_link': meetingLink,
    'call_room_id': callRoomId,
    'booking_type': bookingType,
    'call_provider': callProvider,
    'provider_session_id': providerSessionId,
    'join_token': joinToken,
    'participants': participants,
    'notes': notes,
  };
}
