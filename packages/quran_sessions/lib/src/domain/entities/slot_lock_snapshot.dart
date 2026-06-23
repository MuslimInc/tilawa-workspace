/// Minimal slot-lock fields needed to exclude booked instants from availability.
///
/// Backed by `quran_slot_locks` documents (no student PII). [slotId] encodes the
/// UTC start via [GeneratedSlot.parseStartUtc].
class SlotLockSnapshot {
  const SlotLockSnapshot({
    required this.slotId,
    required this.teacherId,
    required this.lockType,
    this.expiresAt,
  });

  final String slotId;
  final String teacherId;

  /// `hard` for confirmed bookings; `soft` for pending payment holds.
  final String lockType;
  final DateTime? expiresAt;
}
