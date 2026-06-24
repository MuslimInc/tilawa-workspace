import 'package:dartz_plus/dartz_plus.dart';

import '../../domain/failures/quran_sessions_failure.dart';
import '../../domain/repositories/booked_slot_lock_repository.dart';

/// O(1) slot occupancy check via `quran_slot_locks/{slotId}`.
class IsSlotBookedUseCase {
  const IsSlotBookedUseCase(this._locks);

  final BookedSlotLockRepository _locks;

  Future<Either<QuranSessionsFailure, bool>> call(
    String slotId, {
    DateTime? now,
  }) => _locks.isSlotBooked(slotId, now: now);
}
