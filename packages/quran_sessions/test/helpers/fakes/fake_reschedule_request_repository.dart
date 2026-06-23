import 'package:dartz_plus/dartz_plus.dart';
import 'package:quran_sessions/quran_sessions.dart';

class FakeRescheduleRequestRepository implements RescheduleRequestRepository {
  final Map<String, PendingRescheduleRequest> pendingByBooking = {};
  QuranSessionsFailure? failWith;

  @override
  Future<Either<QuranSessionsFailure, PendingRescheduleRequest?>>
  getPendingByBookingId(String bookingId) async {
    if (failWith != null) return Left(failWith!);
    return Right(pendingByBooking[bookingId]);
  }
}
