import 'package:dartz_plus/dartz_plus.dart';

import '../entities/pending_reschedule_request.dart';
import '../failures/quran_sessions_failure.dart';
import '../repositories/reschedule_request_repository.dart';

/// Loads the latest pending reschedule request for a booking, if any.
class GetPendingRescheduleRequestUseCase {
  const GetPendingRescheduleRequestUseCase({
    required this._repository,
  });

  final RescheduleRequestRepository _repository;

  Future<Either<QuranSessionsFailure, PendingRescheduleRequest?>> call(
    String bookingId,
  ) {
    return _repository.getPendingByBookingId(bookingId);
  }
}
