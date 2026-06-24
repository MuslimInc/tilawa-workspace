import 'package:dartz_plus/dartz_plus.dart';
import 'package:quran_sessions/quran_sessions.dart';

/// MVP / test adapter: derives booked starts from in-memory sessions.
class SessionBackedBookedSlotLockRepository
    implements BookedSlotLockRepository {
  const SessionBackedBookedSlotLockRepository(this._sessions);

  final SessionRepository _sessions;

  @override
  Future<Either<QuranSessionsFailure, Set<DateTime>>> getActiveBookedStarts(
    String teacherProfileId, {
    required DateTime windowStart,
    required DateTime windowEnd,
    DateTime? now,
  }) async {
    final sessionsResult = await _sessions.getTeacherUpcomingSessions(
      teacherProfileId,
    );
    return sessionsResult.map(
      (sessions) => collectBookedSlotStarts(
        sessions,
        windowStart: windowStart,
        windowEnd: windowEnd,
      ),
    );
  }

  @override
  Future<Either<QuranSessionsFailure, bool>> isSlotBooked(
    String slotId, {
    DateTime? now,
  }) async {
    final start = GeneratedSlot.parseEncodedStartUtc(slotId);
    if (start == null) return const Right(false);
    final sessionsResult = await _sessions.getTeacherUpcomingSessions(
      _teacherIdFromSlotId(slotId) ?? '',
    );
    return sessionsResult.map((sessions) {
      final booked = collectBookedSlotStarts(
        sessions,
        windowStart: start,
        windowEnd: start.add(const Duration(seconds: 1)),
      );
      return booked.contains(start.toUtc());
    });
  }

  static final RegExp _slotIdRegex = RegExp(r'^(.+)_\d{8}T');

  String? _teacherIdFromSlotId(String slotId) {
    final match = _slotIdRegex.firstMatch(slotId);
    return match?.group(1);
  }
}
