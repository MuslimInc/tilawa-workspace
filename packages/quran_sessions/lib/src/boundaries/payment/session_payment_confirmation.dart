import 'package:dartz_plus/dartz_plus.dart';

import '../../domain/failures/quran_sessions_failure.dart';

/// Confirms a server-created pending payment (sandbox or PSP webhook client path).
abstract interface class SessionPaymentConfirmation {
  Future<Either<QuranSessionsFailure, void>> confirm({
    required String bookingId,
    required String paymentReference,
    required String clientConfirmToken,
  });
}
