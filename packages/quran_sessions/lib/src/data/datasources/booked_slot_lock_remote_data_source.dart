import '../dtos/slot_lock_dto.dart';

/// Reads `quran_slot_locks` for public availability exclusion (no session PII).
abstract interface class BookedSlotLockRemoteDataSource {
  Future<List<SlotLockDto>> getLocksForTeacher(String teacherProfileId);
}
