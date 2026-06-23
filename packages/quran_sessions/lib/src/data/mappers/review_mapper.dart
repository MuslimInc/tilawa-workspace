import '../../domain/entities/session_review.dart';
import '../dtos/session_review_dto.dart';

extension SessionReviewDtoMapper on SessionReviewDto {
  SessionReview toDomain() => SessionReview(
    id: id,
    sessionId: sessionId,
    teacherId: teacherId,
    studentId: studentId,
    rating: rating,
    comment: comment,
    createdAt: DateTime.parse(createdAt),
  );
}
