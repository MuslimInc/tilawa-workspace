import '../../domain/entities/slot_lock_snapshot.dart';

/// Firestore `quran_slot_locks` document — booking occupancy only.
class SlotLockDto {
  const SlotLockDto({
    required this.slotId,
    required this.teacherId,
    required this.lockType,
    this.expiresAt,
  });

  final String slotId;
  final String teacherId;
  final String lockType;
  final DateTime? expiresAt;

  SlotLockSnapshot toSnapshot() => SlotLockSnapshot(
    slotId: slotId,
    teacherId: teacherId,
    lockType: lockType,
    expiresAt: expiresAt,
  );
}
