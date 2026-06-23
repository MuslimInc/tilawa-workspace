import 'package:dartz_plus/dartz_plus.dart';

import '../failures/quran_sessions_failure.dart';

/// Active booking locks for a teacher — used to hide taken generated slots.
abstract interface class BookedSlotLockRepository {
  Future<Either<QuranSessionsFailure, Set<DateTime>>> getActiveBookedStarts(
    String teacherProfileId, {
    required DateTime windowStart,
    required DateTime windowEnd,
    DateTime? now,
  });
}
