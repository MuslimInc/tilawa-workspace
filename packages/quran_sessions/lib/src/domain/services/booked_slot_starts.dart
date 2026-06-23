import '../entities/quran_session.dart';

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
