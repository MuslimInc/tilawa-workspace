import 'package:dartz_plus/dartz_plus.dart';

import 'package:quran_sessions/src/domain/entities/generated_slot.dart';
import 'package:quran_sessions/src/domain/failures/quran_sessions_failure.dart';
import 'package:quran_sessions/src/domain/repositories/booked_slot_lock_repository.dart';
import 'package:quran_sessions/src/domain/services/booked_slot_starts.dart';
import 'package:quran_sessions/src/data/dtos/slot_lock_dto.dart';

class FakeBookedSlotLockRepository implements BookedSlotLockRepository {
  final List<SlotLockDto> locks = [];
  QuranSessionsFailure? failWith;

  void seedHardLock({
    required String teacherId,
    required DateTime startUtc,
  }) {
    locks.add(
      SlotLockDto(
        slotId: GeneratedSlot.deterministicId(teacherId, startUtc),
        teacherId: teacherId,
        lockType: 'hard',
      ),
    );
  }

  @override
  Future<Either<QuranSessionsFailure, Set<DateTime>>> getActiveBookedStarts(
    String teacherProfileId, {
    required DateTime windowStart,
    required DateTime windowEnd,
    DateTime? now,
  }) async {
    if (failWith != null) return Left(failWith!);
    return Right(
      collectBookedStartsFromSlotLocks(
        locks.map((dto) => dto.toSnapshot()),
        teacherProfileId: teacherProfileId,
        windowStart: windowStart,
        windowEnd: windowEnd,
        now: now ?? DateTime.now(),
      ),
    );
  }
}
