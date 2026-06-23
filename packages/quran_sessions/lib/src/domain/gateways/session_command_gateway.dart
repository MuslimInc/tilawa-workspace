import 'package:dartz_plus/dartz_plus.dart';

import '../failures/quran_sessions_failure.dart';

abstract interface class SessionCommandGateway {
  Future<Either<QuranSessionsFailure, void>> holdSlotSoft({
    required String slotId,
    required Duration ttl,
  });

  Future<Either<QuranSessionsFailure, void>> lockSlotHard({
    required String slotId,
  });

  Future<Either<QuranSessionsFailure, void>> releaseSlot({
    required String slotId,
  });

  Future<Either<QuranSessionsFailure, void>> swapSlot({
    required String oldSlotId,
    required String newSlotId,
  });

  Future<Either<QuranSessionsFailure, void>> capturePayment({
    required String sessionId,
    required String paymentReference,
  });

  Future<Either<QuranSessionsFailure, void>> refundPayment({
    required String sessionId,
    required double fraction,
    required String reason,
  });

  Future<Either<QuranSessionsFailure, void>> voidPayment({
    required String sessionId,
    required String paymentReference,
  });
}
