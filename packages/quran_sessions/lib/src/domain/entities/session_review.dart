import 'package:equatable/equatable.dart';

/// A student-submitted review for a completed session.
class SessionReview extends Equatable {
  const SessionReview({
    required this.id,
    required this.sessionId,
    required this.teacherId,
    required this.studentId,
    required this.rating,
    required this.createdAt,
    this.comment,
  }) : assert(rating >= 1 && rating <= 5, 'rating must be 1–5');

  final String id;
  final String sessionId;
  final String teacherId;
  final String studentId;

  /// Integer 1–5.
  final int rating;

  final String? comment;
  final DateTime createdAt;

  @override
  List<Object?> get props => [
    id,
    sessionId,
    teacherId,
    studentId,
    rating,
    comment,
    createdAt,
  ];
}
