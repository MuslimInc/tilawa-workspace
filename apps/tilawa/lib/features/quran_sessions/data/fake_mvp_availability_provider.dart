import 'package:dartz_plus/dartz_plus.dart';
import 'package:quran_sessions/quran_sessions.dart';

import 'quran_sessions_mvp_store.dart';

/// MVP implementation of [AvailabilityProvider] that mutates [QuranSessionsMvpStore].
///
/// [publishSlot] appends to the store; [withdrawSlot] removes the slot
/// provided it has no confirmed booking.
class FakeMvpAvailabilityProvider implements AvailabilityProvider {
  FakeMvpAvailabilityProvider(this._store);

  final QuranSessionsMvpStore _store;

  @override
  Future<Either<QuranSessionsFailure, List<TeacherAvailability>>> getSlots(
    String teacherId, {
    required DateTime from,
    required DateTime to,
  }) async {
    return Right(
      _store.slots
          .where(
            (s) =>
                s.teacherId == teacherId &&
                s.startsAt.isAfter(from) &&
                s.startsAt.isBefore(to),
          )
          .toList(),
    );
  }

  @override
  Future<Either<QuranSessionsFailure, void>> publishSlot(
    TeacherAvailability slot,
  ) async {
    // Prevent duplicate slots at the same time for the same teacher.
    final clash = _store.slots.any(
      (s) =>
          s.teacherId == slot.teacherId &&
          s.startsAt == slot.startsAt,
    );
    if (clash) {
      return const Left(
        ValidationFailure(field: 'startsAt', code: 'duplicate_slot'),
      );
    }
    _store.slots.add(slot);
    return const Right(null);
  }

  @override
  Future<Either<QuranSessionsFailure, void>> withdrawSlot(
    String slotId,
  ) async {
    final idx = _store.slots.indexWhere((s) => s.slotId == slotId);
    if (idx == -1) return const Left(NotFoundFailure('TeacherAvailability'));
    if (_store.slots[idx].isBooked) {
      return const Left(
        ValidationFailure(field: 'slotId', code: 'slot_already_booked'),
      );
    }
    _store.slots.removeAt(idx);
    return const Right(null);
  }
}
