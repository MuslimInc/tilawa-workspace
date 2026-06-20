import 'package:dartz_plus/dartz_plus.dart';

import '../entities/session_review.dart';
import '../repositories/booking_repository.dart';
import '../failures/quran_sessions_failure.dart';

class SubmitReviewUseCase {
  const SubmitReviewUseCase(this._repository);

  final BookingRepository _repository;

  Future<Either<QuranSessionsFailure, SessionReview>> call({
    required String sessionId,
    required int rating,
    String? comment,
  }) => _repository.submitReview(
    sessionId: sessionId,
    rating: rating,
    comment: comment,
  );
}
