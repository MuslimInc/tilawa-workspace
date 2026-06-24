import '../dtos/slot_lock_dto.dart';

abstract interface class BookedSlotLockRemoteDataSource {
  /// Locks for [teacherProfileId] whose encoded slot start falls in
  /// [[windowStart], [windowEnd]) — scoped to the availability window.
  Future<List<SlotLockDto>> getLocksForTeacher(
    String teacherProfileId, {
    required DateTime windowStart,
    required DateTime windowEnd,
  });

  /// O(1) occupancy check by deterministic slot id (lock doc id == slotId).
  Future<SlotLockDto?> getLockBySlotId(String slotId);
}
