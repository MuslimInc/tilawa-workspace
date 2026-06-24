import 'package:dartz_plus/dartz_plus.dart';

import '../failures/quran_sessions_failure.dart';

/// Persists guardian consent for a child student's bookings.
abstract interface class GuardianApprovalRepository {
  Future<Either<QuranSessionsFailure, void>> approveChildBooking({
    required String studentId,
  });
}
