import '../entities/generated_slot.dart';
import '../entities/quran_session.dart';
import '../entities/slot_lock_snapshot.dart';

/// UTC start instants from public slot locks that block generated availability.
Set<DateTime> collectBookedStartsFromSlotLocks(
  Iterable<SlotLockSnapshot> locks, {
  required String teacherProfileId,
  Iterable<String> alternateTeacherIds = const [],
  required DateTime windowStart,
  required DateTime windowEnd,
  required DateTime now,
}) {
  final ownerIds = {teacherProfileId, ...alternateTeacherIds};
  final fromUtc = windowStart.toUtc();
  final toUtc = windowEnd.toUtc();
  final nowUtc = now.toUtc();
  return locks
      .where(
        (lock) =>
            ownerIds.contains(lock.teacherId) ||
            ownerIds.any((id) => lock.slotId.startsWith('${id}_')),
      )
      .where((lock) => slotLockBlocksGeneration(lock, nowUtc: nowUtc))
      .map((lock) => GeneratedSlot.parseEncodedStartUtc(lock.slotId))
      .whereType<DateTime>()
      .where((start) => !start.isBefore(fromUtc) && start.isBefore(toUtc))
      .map((start) => start.toUtc())
      .toSet();
}

/// Whether a lock doc blocks generated availability for [nowUtc].
bool slotLockBlocksGeneration(
  SlotLockSnapshot lock, {
  required DateTime nowUtc,
}) {
  if (lock.lockType == 'hard') return true;
  if (lock.lockType != 'soft') return false;
  final expiresAt = lock.expiresAt?.toUtc();
  return expiresAt != null && expiresAt.isAfter(nowUtc);
}

/// UTC start instants for sessions that block generated availability.
Set<DateTime> collectBookedSlotStarts(
  Iterable<QuranSession> sessions, {
  required DateTime windowStart,
  required DateTime windowEnd,
}) {
  final fromUtc = windowStart.toUtc();
  final toUtc = windowEnd.toUtc();
  return sessions
      .where(_blocksSlotGeneration)
      .where((session) {
        final start = session.startsAt.toUtc();
        return !start.isBefore(fromUtc) && start.isBefore(toUtc);
      })
      .map((session) => session.startsAt.toUtc())
      .toSet();
}

bool _blocksSlotGeneration(QuranSession session) => switch (session.status) {
  QuranSessionStatus.scheduled || QuranSessionStatus.inProgress => true,
  _ => false,
};
