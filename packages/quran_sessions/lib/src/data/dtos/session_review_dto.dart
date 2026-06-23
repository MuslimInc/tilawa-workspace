class SessionReviewDto {
  const SessionReviewDto({
    required this.id,
    required this.sessionId,
    required this.teacherId,
    required this.studentId,
    required this.rating,
    required this.createdAt,
    this.comment,
  });

  final String id;
  final String sessionId;
  final String teacherId;
  final String studentId;
  final int rating;
  final String? comment;
  final String createdAt;

  factory SessionReviewDto.fromJson(Map<String, dynamic> json) =>
      SessionReviewDto(
        id: json['id'] as String,
        sessionId: json['session_id'] as String,
        teacherId: json['teacher_id'] as String,
        studentId: json['student_id'] as String,
        rating: json['rating'] as int,
        comment: json['comment'] as String?,
        createdAt: json['created_at'] as String,
      );

  Map<String, dynamic> toJson() => {
    'id': id,
    'session_id': sessionId,
    'teacher_id': teacherId,
    'student_id': studentId,
    'rating': rating,
    'comment': comment,
    'created_at': createdAt,
  };
}
