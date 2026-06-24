import 'package:dartz_plus/dartz_plus.dart';

import '../entities/pending_reschedule_request.dart';
import '../failures/quran_sessions_failure.dart';

/// Reads pending reschedule requests for participant UI.
abstract interface class RescheduleRequestRepository {
  Future<Either<QuranSessionsFailure, PendingRescheduleRequest?>>
  getPendingByBookingId(String bookingId);
}
